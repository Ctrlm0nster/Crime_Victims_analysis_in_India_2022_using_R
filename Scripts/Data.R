# Normalize source schemas once, then express transformations as a single pipeline.
clean_records <- function(raw) {
    schemas <- list(csv_columns, api_columns, data_columns)
    schema <- purrr::detect(schemas, \(columns) setequal(names(raw), columns))
    if (ncol(raw) != 14L || anyDuplicated(names(raw)) || is.null(schema))
        stop("Expected the 14 unique NCRB source columns")
    raw <- raw |>
        dplyr::select(dplyr::all_of(schema)) |>
        stats::setNames(data_columns) |>
        dplyr::filter(grepl("^[0-9]+$", trimws(as.character(sl_no)))) |>
        dplyr::mutate(
            state_ut = trimws(state_ut),
            dplyr::across(-state_ut, \(x) suppressWarnings(as.numeric(as.character(x))))
        )
    validate_records(raw)
    raw |>
        dplyr::mutate(
            child_percentage = dplyr::if_else(total_victims > 0, 100 * total_child_victims / total_victims, NA_real_),
            women_percentage = dplyr::if_else(total_victims > 0, 100 * total_women_victims / total_victims, NA_real_),
            case_category = cut(cases_reported, c(-Inf, 100, 500, 1000, Inf), right = FALSE,
                                labels = c("Low (<100)", "Medium (100-<500)", "High (500-<1000)", "Very high (1000+)"))
        ) |>
        dplyr::arrange(dplyr::desc(cases_reported), state_ut) |>
        as.data.frame() |>
        `rownames<-`(NULL)
}

validate_records <- function(df) {
    if (anyNA(df$state_ut) || any(!nzchar(df$state_ut))) stop("Missing state/UT name")
    counts <- dplyr::select(df, -state_ut)
    if (anyNA(counts) || any(!is.finite(as.matrix(counts))) ||
        any(counts < 0) || any(counts != floor(as.matrix(counts)))) stop("Invalid count")
    if (nrow(df) != 36L || anyDuplicated(df$state_ut) || !setequal(df$sl_no, 1:36))
        stop("Expected 36 unique states/UTs, numbered 1-36")
    if (any(rowSums(df[age_columns[1:4]]) != df$total_child_victims) ||
        any(rowSums(df[age_columns[5:8]]) != df$total_women_victims) ||
        any(df$total_child_victims + df$total_women_victims != df$total_victims))
        stop("Victim subtotals do not reconcile")
    invisible(df)
}

read_source_csv <- function(path = "Data/raw/NCRB_DATA.3.csv") {
    readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                    name_repair = "minimal", show_col_types = FALSE) |>
        clean_records()
}

parse_xml_page <- function(text) {
    doc <- xml2::read_xml(text)
    total <- doc |> xml2::xml_find_first("//total") |> xml2::xml_text() |> as.integer() |> suppressWarnings()
    items <- xml2::xml_find_all(doc, "//records/item")
    if (is.na(total) || total <= 0 || !length(items)) stop("Invalid or incomplete API response")
    records <- purrr::map(items, \(item) {
        fields <- xml2::xml_children(item)
        names <- xml2::xml_name(fields)
        if (anyDuplicated(names) || !setequal(names, api_columns)) stop("Unexpected API fields")
        dplyr::as_tibble(as.list(stats::setNames(xml2::xml_text(fields), names)))
    }) |> purrr::list_rbind()
    list(total = total, records = dplyr::select(records, dplyr::all_of(api_columns)))
}

fetch_api_page <- function(offset, key) {
    httr2::request("https://api.data.gov.in/resource/0a096e81-5a1b-4e23-9f28-1abd1db76d16") |>
        httr2::req_url_query(`api-key` = key, format = "xml", limit = 10, offset = offset) |>
        httr2::req_timeout(60) |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        parse_xml_page()
}

# Injectable page fetching keeps pagination testable without a key or network access.
fetch_records <- function(fetch_page = fetch_api_page, key = Sys.getenv("GOV_API_KEY"), pause = Sys.sleep) {
    if (!nzchar(key)) stop("Set GOV_API_KEY before fetching API data")
    offset <- 0L
    pages <- list()
    expected_total <- NULL
    repeat {
        page <- fetch_page(offset, key)
        if (is.null(expected_total)) expected_total <- page$total
        if (length(page$total) != 1L || is.na(page$total) || page$total <= 0 ||
            page$total != expected_total || !nrow(page$records)) stop("Invalid or inconsistent API page")
        pages[[length(pages) + 1L]] <- page$records
        offset <- offset + nrow(page$records)
        if (offset >= expected_total) break
        pause(2)
    }
    raw <- purrr::list_rbind(pages)
    if (nrow(raw) != expected_total) stop("API record count mismatch")
    clean_records(raw) # Reject partial or duplicate data before saving.
    raw
}
