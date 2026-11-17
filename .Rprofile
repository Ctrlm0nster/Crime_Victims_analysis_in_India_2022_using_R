# Use the project library after an explicit `Rscript run.R --restore`.
# Starting R does not download or install dependencies.
if (dir.exists("renv/library")) .libPaths(c(normalizePath("renv/library"), .libPaths()))
