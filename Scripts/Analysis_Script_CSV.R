source("Scripts/Common.R")
# Independent analysis of the checked-in source CSV; no API or XML output needed.
read_source_csv() |>
    run_analysis(output_dir = "Result/CSV")
