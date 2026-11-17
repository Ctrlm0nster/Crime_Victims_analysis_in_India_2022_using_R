summarise_records <- function(df) {
    total_stats <- df |>
        dplyr::summarise(
            total_cases = sum(cases_reported),
            total_child_victims = sum(total_child_victims),
            total_women_victims = sum(total_women_victims),
            total_all_victims = sum(total_victims),
            avg_cases_per_state = mean(cases_reported),
            child_victim_percentage = 100 * total_child_victims / total_all_victims,
            women_victim_percentage = 100 * total_women_victims / total_all_victims
        ) |>
        as.data.frame()
    age_distribution <- colSums(df[age_columns])
    category_summary <- df |>
        dplyr::count(case_category, .drop = FALSE) |>
        dplyr::mutate(percentage = 100 * n / sum(n)) |>
        as.data.frame()
    top_10_states <- head(df, 10)
    bottom_10_states <- df |> dplyr::arrange(cases_reported, state_ut) |> dplyr::slice_head(n = 10)
    top_child <- df |> dplyr::filter(!is.na(child_percentage)) |> dplyr::arrange(dplyr::desc(child_percentage), state_ut) |> dplyr::slice_head(n = 10)
    list(total_stats = total_stats, age_distribution = age_distribution,
         category_summary = category_summary, top_10_states = top_10_states,
         bottom_10_states = bottom_10_states, top_child = top_child)
}

format_report <- function(summary) {
    total_stats <- summary$total_stats
    age_distribution <- summary$age_distribution
    category_summary <- summary$category_summary
    top_10_states <- summary$top_10_states
    bottom_10_states <- summary$bottom_10_states
    top_child <- summary$top_child
    report <- capture.output({
        cat("NCRB rape victims analysis - 2022\n36 states/UTs; aggregate rows excluded\n\n")
        print(total_stats, row.names = FALSE)
        cat("\nTop 10 states/UTs by reported cases\n")
        print(top_10_states[c("state_ut", "cases_reported")], row.names = FALSE)
        cat("\nBottom 10 states/UTs by reported cases\n")
        print(bottom_10_states[c("state_ut", "cases_reported")], row.names = FALSE)
        cat("\nTop 10 child victim percentages\n")
        print(top_child[c("state_ut", "child_percentage")], row.names = FALSE)
        cat("\nAge distribution\n")
        print(data.frame(age_group = age_labels, count = unname(age_distribution),
                         percentage = 100 * unname(age_distribution) / sum(age_distribution)), row.names = FALSE)
        cat("\nCase volume categories\n")
        print(category_summary, row.names = FALSE)
    })
    report
}

save_analysis <- function(df, summary, output_dir) {
    readr::write_lines(format_report(summary), file.path(output_dir, "reports", "ncrb_analysis_report_2022.txt"))
    readr::write_csv(df, file.path(output_dir, "data", "ncrb_rape_data_2022_cleaned.csv"))
    readr::write_rds(list(
        key_metrics = summary$total_stats, top_5_states = head(df, 5),
        age_distribution = summary$age_distribution, category_summary = summary$category_summary
    ), file.path(output_dir, "data", "dashboard_summary.rds"))
}
