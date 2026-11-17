source("Scripts/Common.R")

# Reconcile names and the merged UT before a checked many-to-one population join.
population <- readr::read_csv("Data/raw/India_State_population_2011_census.csv", show_col_types = FALSE) |>
    dplyr::transmute(population_key = toupper(trimws(State)), population_2011 = `Total Population Person`)
merged_ut <- population |>
    dplyr::filter(population_key %in% c("DADRA AND NAGAR HAVELI", "DAMAN AND DIU")) |>
    dplyr::summarise(population_key = "DADRA AND NAGAR HAVELI AND DAMAN AND DIU",
                     population_2011 = sum(population_2011))
population <- dplyr::bind_rows(population, merged_ut)
incompatible <- c("Andhra Pradesh", "Telangana", "Jammu and Kashmir", "Ladakh")
clean <- read_source_csv() |>
    dplyr::mutate(population_key = dplyr::if_else(state_ut == "Delhi", "NCT OF DELHI", toupper(state_ut))) |>
    dplyr::left_join(population, by = dplyr::join_by(population_key), relationship = "many-to-one") |>
    dplyr::mutate(
        population_2011 = dplyr::if_else(state_ut %in% incompatible, NA_real_, population_2011),
        population_note = dplyr::if_else(is.na(population_2011), "Unavailable for 2022 boundaries",
                                         "2011 census; not a 2022 population estimate"),
        cases_per_100k_2011_population = 100000 * cases_reported / population_2011
    ) |>
    dplyr::select(-population_key)
state_data <- dplyr::filter(clean, sl_no <= 28)
UT_data <- dplyr::filter(clean, sl_no >= 29)
dir.create("Result/CSV/data", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(clean, "Result/CSV/data/ncrb_population_context_2022.csv", na = "")
cat("Population context saved; incompatible boundaries have no calculated rate.\n")
