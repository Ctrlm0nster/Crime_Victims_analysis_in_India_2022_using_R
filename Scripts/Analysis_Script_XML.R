source("Scripts/Common.R")
# Fetch independently; validate completeness before producing any analysis.
fetch_records() |>
    clean_records() |>
    run_analysis(output_dir = "Result/XML")
