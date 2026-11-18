#!/usr/bin/env Rscript
# Launch locally. Set PORT to choose a port; the default is 3838.
script <- grep("^--file=", commandArgs(), value = TRUE)
if (length(script)) setwd(dirname(dirname(normalizePath(sub("^--file=", "", script[[1]])))))
if (dir.exists("renv/library")) .libPaths(c(normalizePath("renv/library"), .libPaths()))
if (!requireNamespace("shiny", quietly = TRUE)) stop("Restore dependencies with Rscript run.R --restore")
port <- suppressWarnings(as.integer(Sys.getenv("PORT", "3838")))
if (is.na(port) || port < 1L || port > 65535L) stop("PORT must be an integer from 1 to 65535")
shiny::runApp("App", host = "127.0.0.1", port = port, launch.browser = interactive())
