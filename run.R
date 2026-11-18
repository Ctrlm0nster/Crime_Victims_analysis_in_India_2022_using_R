#!/usr/bin/env Rscript
# Run from any directory: Rscript /path/to/project/run.R [--restore] [--live] [--report] [--site]
args <- commandArgs(trailingOnly = TRUE)
usage <- "Usage: Rscript run.R [--restore] [--live] [--report] [--site]\n  --restore  Restore package versions from renv.lock before running\n  --live     Fetch XML data and compare it with the local CSV\n  --report   Also render the Quarto HTML report (requires Quarto CLI)\n  --site     Build the report and browser-based Shiny site for hosting\n"
if ("--help" %in% args) {
    cat(usage)
    quit(status = 0)
}
if (any(!args %in% c("--restore", "--live", "--report", "--site"))) stop(usage, call. = FALSE)
script <- grep("^--file=", commandArgs(), value = TRUE)
if (length(script)) setwd(dirname(normalizePath(sub("^--file=", "", script[[1]]))))
if (file.exists(".Renviron")) readRenviron(".Renviron")
live <- "--live" %in% args
if (live && !nzchar(Sys.getenv("GOV_API_KEY")))
    stop("Live check needs GOV_API_KEY. Set it in your environment or local .Renviron, then rerun with --live.", call. = FALSE)

project_library <- file.path(getwd(), "renv", "library")
if (dir.exists(project_library)) .libPaths(c(project_library, .libPaths()))
if (!requireNamespace("renv", quietly = TRUE))
    stop('Install renv first: install.packages("renv")', call. = FALSE)
if ("--restore" %in% args) {
    renv::restore(project = getwd(), library = project_library, prompt = FALSE)
    .libPaths(c(project_library, .libPaths()))
}
lock <- renv::lockfile_read("renv.lock")
mismatched <- names(lock$Packages)[!vapply(lock$Packages, \(package) {
    tryCatch(isTRUE(utils::packageVersion(package$Package) == package_version(package$Version)),
             error = \(e) FALSE)
}, logical(1))]
if (length(mismatched))
    stop("Packages differ from renv.lock: ", paste(mismatched, collapse = ", "),
         ". Run Rscript run.R --restore.", call. = FALSE)

options(warn = 2) # Warnings fail the reproducible pipeline rather than being overlooked.
source("Scripts/Common.R")
# Isolate test variables from the analysis workflow.
check <- \(path) sys.source(path, envir = new.env(parent = globalenv()))
check("Tests/validation.R")
check("Tests/api.R")
check("Tests/runner.R")
check("Tests/shiny.R")
csv <- read_source_csv()
xml <- NULL
if (live) {
    cat("Fetching live XML data...\n")
    xml <- fetch_records() |> clean_records()
    comparison <- all.equal(csv, xml, check.attributes = FALSE)
    if (!isTRUE(comparison)) stop("Live XML and local CSV differ: ", paste(comparison, collapse = "; "))
    cat("Live API check passed: all 36 jurisdiction records match the local CSV.\n")
}
run_analysis(csv, "Result/CSV")
directories <- "Result/CSV"
if (live) {
    run_analysis(xml, "Result/XML")
    directories <- c(directories, "Result/XML")
}
source("Tests/outputs.R")
verify_outputs(directories)
source("Scripts/Render_README.R")
render_readme()
if (any(c("--report", "--site") %in% args)) {
    source("Scripts/Render_Report.R")
    render_report()
    check("Tests/report.R")
}
if ("--site" %in% args) {
    source("Scripts/Build_Site.R")
    build_site()
    check("Tests/site.R")
}
cat(if (live) "Complete: CSV and live XML results generated; all checks passed.\n"
    else "Complete: CSV results generated; all offline checks passed. Live API check not requested.\n")
