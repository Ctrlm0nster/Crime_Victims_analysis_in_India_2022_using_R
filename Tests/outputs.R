# Verify regenerated artifacts after running the analysis workflows.
source("Scripts/Common.R")
verify_outputs <- function(directories = c("Result/CSV", "Result/XML")) {
    expected <- read_source_csv()
    for (directory in directories) {
        actual <- read.csv(file.path(directory, "data", "ncrb_rape_data_2022_cleaned.csv"))
        stopifnot(nrow(actual) == 36, identical(actual$state_ut, expected$state_ut),
                  sum(actual$cases_reported) == 31516,
                  sum(actual$total_victims) == 31982)
        summary <- readRDS(file.path(directory, "data", "dashboard_summary.rds"))
        stopifnot(summary$key_metrics$total_cases == 31516,
                  sum(summary$age_distribution) == 31982,
                  sum(summary$category_summary$n) == 36)
        images <- list.files(file.path(directory, "plots"), pattern = "^plot[1-6]_.*[.]png$", full.names = TRUE)
        stopifnot(length(images) == 6)
        for (path in images) {
            signature <- readBin(path, "raw", n = 24)
            stopifnot(identical(signature[1:8], as.raw(c(137,80,78,71,13,10,26,10))),
                      file.info(path)$size > 10000)
        }
        pdf <- file.path(directory, "plots", paste0(basename(directory), "_Generated_Plots.pdf"))
        stopifnot(file.info(pdf)$size > 1000,
                  rawToChar(readBin(pdf, "raw", n = 4)) == "%PDF")
    }
    cat("Verified data, summaries, six PNG charts, and PDFs in:", paste(directories, collapse = ", "), "\n")
    invisible(TRUE)
}

if (sys.nframe() == 0L) verify_outputs()
