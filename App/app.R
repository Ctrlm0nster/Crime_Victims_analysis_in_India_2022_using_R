# Run from the project root with shiny::runApp("App"). Also supports RStudio's Run App.
root <- if (file.exists("Scripts/Common.R")) normalizePath(".") else normalizePath("..")
if (dir.exists(file.path(root, "renv/library")))
    .libPaths(c(file.path(root, "renv/library"), .libPaths()))
# Source into this app's environment without changing the process working directory.
app_env <- environment()
old_wd <- getwd()
setwd(root)
source("Scripts/Common.R", local = app_env)
source("App/logic.R", local = app_env)
setwd(old_wd)

data <- read_source_csv(file.path(root, "Data/raw/NCRB_DATA.3.csv"))
source(file.path(root, "App/dashboard.R"), local = environment())$value
