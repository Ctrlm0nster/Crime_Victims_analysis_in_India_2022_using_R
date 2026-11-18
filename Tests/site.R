# Verify the portable bundle and the public website's relative paths.
local({
    bundle <- "Result/app-bundle"
    files <- sort(list.files(bundle, recursive = TRUE, all.files = TRUE, no.. = TRUE))
    allowed <- sort(c("app.R", "app-data.rds", "Schema.R", "logic.R", "dashboard.R",
                      "www/style.css", "www/download.js"))
    stopifnot(identical(files, allowed), nrow(readRDS(file.path(bundle, "app-data.rds"))) == 36,
              file.exists("Result/site/app/app.json"),
              file.exists("Result/site/shinylive-sw.js"),
              file.exists("Result/site/shinylive/shinylive.js"),
              identical(readBin("Result/site/index.html", "raw", file.info("Result/site/index.html")$size),
                        readBin("Result/report/report.html", "raw", file.info("Result/report/report.html")$size)))
    app_index <- paste(readLines("Result/site/app/index.html"), collapse = "\n")
    stopifnot(grepl("../shinylive/shinylive.js", app_index, fixed = TRUE))
    cat("Portable bundle allowlist, public data, and website paths verified.\n")
})
