# Shared entry point. Run scripts from the project root.
required <- c("dplyr", "tidyr", "readr", "purrr", "ggplot2", "scales")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: ", paste(missing, collapse = ", "))

purrr::walk(c("Schema", "Data", "Analysis", "Plots"),
            \(module) source(file.path("Scripts", paste0(module, ".R"))))

run_analysis <- function(df, output_dir) {
    df <- df |> dplyr::select(dplyr::all_of(data_columns)) |> clean_records()
    purrr::walk(c("data", "plots", "reports"),
                \(folder) dir.create(file.path(output_dir, folder), recursive = TRUE, showWarnings = FALSE))
    summary <- summarise_records(df)
    save_analysis(df, summary, output_dir)
    build_plots(df, summary) |> save_plots(output_dir)
    cat("Analysis complete:", output_dir, "\n")
    invisible(summary$total_stats)
}
