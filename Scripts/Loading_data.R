source("Scripts/Common.R")
raw <- fetch_records()
ids <- suppressWarnings(as.integer(raw$sl__no_))
records <- list(
    full_xml_content = raw,
    main_records = dplyr::filter(raw, !is.na(ids)),
    state_data = dplyr::filter(raw, ids <= 28),
    ut_data = dplyr::filter(raw, ids >= 29),
    state_total = dplyr::filter(raw, state_ut == "Total State (S)"),
    totals_and_percentages = dplyr::filter(raw, is.na(ids), state_ut != "Total State (S)")
)
dir.create("Data/intermediate", recursive = TRUE, showWarnings = FALSE)
purrr::iwalk(records, \(data, name) readr::write_rds(data, file.path("Data/intermediate", paste0(name, ".rds"))))
cat("Fetched and validated 36 states/UTs.\n")
