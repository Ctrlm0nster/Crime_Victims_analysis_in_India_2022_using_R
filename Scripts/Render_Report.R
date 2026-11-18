# Render using a system Quarto installation or the ignored project-local tool.
render_report <- function() {
    if (dir.exists("renv/library")) .libPaths(c(normalizePath("renv/library"), .libPaths()))
    if (!requireNamespace("rmarkdown", quietly = TRUE)) stop("Restore R packages with Rscript run.R --restore")
    quarto <- Sys.getenv("QUARTO_BIN", unset = Sys.which("quarto"))
    if (!nzchar(quarto) && file.exists(".tools/quarto/bin/quarto"))
        quarto <- normalizePath(".tools/quarto/bin/quarto")
    if (!nzchar(quarto)) stop("Install Quarto CLI from https://quarto.org/docs/get-started/ or set QUARTO_BIN")
    libraries <- paste(.libPaths(), collapse = .Platform$path.sep)
    status <- system2(quarto, c("render", "report.qmd"), env = paste0("R_LIBS=", shQuote(libraries)))
    if (status != 0L) stop("Quarto report rendering failed")
    output <- "Result/report/report.html"
    if (!file.exists(output)) stop("Quarto did not produce the expected report")
    cat("Quarto report saved:", output, "\n")
    invisible(output)
}
if (sys.nframe() == 0L) render_report()
