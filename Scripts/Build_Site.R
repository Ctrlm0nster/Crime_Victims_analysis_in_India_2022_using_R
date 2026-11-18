# Bundle only public app files, then export ShinyLive for GitHub Pages.
prepare_app_bundle <- function(directory = "Result/app-bundle") {
    source("Scripts/Common.R")
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
    for (file in c("logic.R", "dashboard.R"))
        file.copy(file.path("App", file), file.path(directory, file), overwrite = TRUE)
    file.copy("Scripts/Schema.R", file.path(directory, "Schema.R"), overwrite = TRUE)
    file.copy("App/www", directory, recursive = TRUE, overwrite = TRUE)
    saveRDS(read_source_csv(), file.path(directory, "app-data.rds"))
    writeLines(c('source("Schema.R")', 'source("logic.R")',
                 'data <- readRDS("app-data.rds")', 'source("dashboard.R", local = TRUE)$value'),
               file.path(directory, "app.R"))
    invisible(directory)
}

build_site <- function(directory = "Result/site") {
    if (dir.exists("renv/library")) .libPaths(c(normalizePath("renv/library"), .libPaths()))
    if (!requireNamespace("shinylive", quietly = TRUE)) stop("Restore project dependencies before building the site")
    report <- "Result/report/report.html"
    if (!file.exists(report)) stop("Render the Quarto report first with Rscript run.R --report")
    bundle <- prepare_app_bundle()
    shinylive::export(bundle, directory, subdir = "app", assets_version = "0.10.12")
    app_index <- file.path(directory, "app", "index.html")
    html <- readLines(app_index, warn = FALSE)
    writeLines(sub("<title>Shiny App</title>", "<title>NCRB 2022 | Interactive explorer</title>", html, fixed = TRUE), app_index)
    file.copy(report, file.path(directory, "index.html"), overwrite = TRUE)
    writeLines("", file.path(directory, ".nojekyll"))
    jsonlite::write_json(list(commit = Sys.getenv("GITHUB_SHA", "local"),
                             records = 36L, assets_version = "0.10.12"),
                         file.path(directory, "build-info.json"), auto_unbox = TRUE, pretty = TRUE)
    cat("Static report and browser-based Shiny app built in", directory, "\n")
    invisible(directory)
}
if (sys.nframe() == 0L) build_site()
