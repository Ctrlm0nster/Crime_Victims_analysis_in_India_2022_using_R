# Small, testable transformations used by the Shiny server.
app_filter <- function(data, states, region = "All jurisdictions") {
    selected <- dplyr::filter(data, state_ut %in% states)
    if (identical(region, "States")) selected <- dplyr::filter(selected, sl_no <= 28)
    if (identical(region, "Union territories")) selected <- dplyr::filter(selected, sl_no > 28)
    selected
}

app_metrics <- function(data) {
    cases <- sum(data$cases_reported)
    victims <- sum(data$total_victims)
    children <- sum(data$total_child_victims)
    list(jurisdictions = nrow(data), cases = cases, victims = victims, children = children,
         child_share = if (victims > 0) 100 * children / victims else NA_real_)
}

app_ranking <- function(data, metric, top_n) {
    stopifnot(metric %in% c("cases_reported", "total_victims", "child_percentage"))
    data |>
        dplyr::filter(!is.na(.data[[metric]])) |>
        dplyr::arrange(dplyr::desc(.data[[metric]]), state_ut) |>
        dplyr::slice_head(n = top_n)
}

app_age_profile <- function(data, proportions = FALSE) {
    data |>
        dplyr::select(state_ut, total_victims, dplyr::all_of(age_columns)) |>
        tidyr::pivot_longer(dplyr::all_of(age_columns), names_to = "age_group", values_to = "count") |>
        dplyr::mutate(age_group = factor(age_group, levels = age_columns, labels = age_labels)) |>
        dplyr::summarise(count = sum(count), .by = age_group) |>
        dplyr::mutate(value = if (proportions) 100 * count / sum(count) else count)
}

app_export <- function(data) {
    data |>
        dplyr::select(state_ut, cases_reported, total_victims, total_child_victims,
                      total_women_victims, child_percentage, dplyr::all_of(age_columns))
}
