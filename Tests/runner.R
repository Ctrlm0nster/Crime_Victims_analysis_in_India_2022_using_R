# Check CLI behavior without generating plots or making network requests.
local({
    project <- normalizePath(".")
    script <- file.path(project, "run.R")
    run <- function(args) {
        previous <- setwd(tempdir())
        on.exit(setwd(previous), add = TRUE)
        suppressWarnings(system2(file.path(R.home("bin"), "Rscript"),
            c("--vanilla", shQuote(script), args), stdout = TRUE, stderr = TRUE))
    }
    status <- \(output) if (is.null(attr(output, "status"))) 0L else attr(output, "status")
    help <- run("--help")
    stopifnot(status(help) == 0L, any(grepl("Usage:", help)))
    invalid <- run("--unknown-option")
    stopifnot(status(invalid) != 0L, any(grepl("Usage:", invalid)))
    if (!nzchar(Sys.getenv("GOV_API_KEY")) && !file.exists(file.path(project, ".Renviron"))) {
        files <- list.files("Result", recursive = TRUE, full.names = TRUE)
        before <- tools::md5sum(files)
        missing_key <- run("--live")
        stopifnot(status(missing_key) != 0L, any(grepl("Live check needs GOV_API_KEY", missing_key)),
                  identical(before, tools::md5sum(files)))
    }
    cat("Runner help, argument validation, and applicable missing-key checks passed.\n")
})
