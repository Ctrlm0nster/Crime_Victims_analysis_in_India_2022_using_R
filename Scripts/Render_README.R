# Render executable R chunks directly to GitHub Markdown; no Pandoc required.
render_readme <- function(check = FALSE) {
    if (dir.exists("renv/library")) .libPaths(c(normalizePath("renv/library"), .libPaths()))
    if (!requireNamespace("knitr", quietly = TRUE))
        stop("Install the pinned README dependencies with Rscript run.R --restore")
    if (!file.exists("Result/CSV/data/dashboard_summary.rds"))
        stop("Generate analysis results with Rscript run.R before rendering the README")
    output <- if (check) tempfile(fileext = ".md") else "README.md"
    if (check) on.exit(unlink(output), add = TRUE)
    knitr::knit("README.Rmd", output = output, quiet = TRUE,
                envir = new.env(parent = globalenv()))
    if (check && (!file.exists("README.md") ||
                  !identical(readLines(output, warn = FALSE), readLines("README.md", warn = FALSE))))
        stop("README.md is outdated. Run Rscript Scripts/Render_README.R and commit both README files.")
    cat(if (check) "README.md matches README.Rmd.\n" else "Rendered README.Rmd to README.md.\n")
    invisible(output)
}

if (sys.nframe() == 0L) {
    args <- commandArgs(trailingOnly = TRUE)
    if (any(!args %in% "--check")) stop("Usage: Rscript Scripts/Render_README.R [--check]")
    render_readme(check = "--check" %in% args)
}
