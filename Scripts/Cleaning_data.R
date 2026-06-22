library(dplyr)
library(tidyr)
library(tidyverse)
# Analysis Script -----------------------------------------------------------------------------

state_data <- readRDS(file = "Data/state_data.rds")
UT_data <- readRDS(file = "Data/ut_data.rds")
total_and_percentage <- readRDS(file = "Data/totals_and_percentages.rds")
full <- readRDS(file = "Data/full_xml_content.rds")
total_state_crime <- readRDS(file = "Data/state_total.rds")


# State Population included -------------------------------------------------------------------

state_population <- read.csv("Data/India_State_population_2011_census.csv")
setdiff(state_data$state_ut, state_population$State)
setdiff(state_population$State, state_data$state_ut)


state_data <- state_data |>
    mutate(state_ut = str_to_upper(str_trim(state_ut)))

state_population <- state_population |>
    mutate(State = str_to_upper(str_trim(State)))

# TELENGANA is an exception because it was not formed in 2011
state_data <- left_join(state_data, state_population, by = c("state_ut" = "State"))
state_data <- relocate(state_data, Total.Population.Person , .after = 2)

# Changing all the values to numeric
state_data <- state_data |>
  mutate(across(
.cols = -state_ut,
.fns =as.numeric
  ))


# Renaming the cols to a proper name

state_data <- state_data |>
  rename(
    state = state_ut,
    population = Total.Population.Person,
    cases_reported = cases_reported___col__3_,
    child_victims_u18_below_6 = child_victims_of_rape__below_18_yrs____below_6_years___col__4_,
    child_victims_u18_6_to_12 = child_victims_of_rape__below_18_yrs____6_years_and_above___below_12_years___col__5_,
    child_victims_u18_12_to_16 = child_victims_of_rape__below_18_yrs____12_years_and_above___below_16_years___col__6_,
    child_victims_u18_16_to_18 = child_victims_of_rape__below_18_yrs____16_years_and_above___below_18_years___col__7_,
    child_victims_total_girls = child_victims_of_rape__below_18_yrs____total_girl___child_victims___col__8_,
    women_victims_18_to_30 = women_victims_of_rape__above_18_years____18_years_and_above___below_30_years___col__9_,
    women_victims_30_to_45 = women_victims_of_rape__above_18_years____30_years_and_above___below_45_years___col__10_,
    women_victims_45_to_60 = women_victims_of_rape__above_18_years____45_years_and_above___below_60_years___col__11_,
    women_victims_60_plus = women_victims_of_rape__above_18_years____60_years_and_above___col__12_,
    women_victims_total_adults = women_victims_of_rape__above_18_years____total_women___adult_victims___col__13_,
    total_victims = total_victims__col_8_col_13____col__14_
  ) |> mutate(
rape_per_100k = (cases_reported / population) * 100000
  )



# UT_data -------------------------------------------------------------------------------------


setdiff(UT_data$state_ut, state_population$State)
setdiff(state_population$State, UT_data$state_ut)

UT_data <- UT_data |>
    mutate(state_ut = str_to_upper(str_trim(state_ut)))

state_population <- state_population |>
    mutate(State = str_to_upper(str_trim(State)))

UT_data <- left_join(UT_data, state_population, by = c("state_ut" = "State"))
UT_data <- relocate(UT_data, Total.Population.Person , .after = 2)


# Total_State_Crime_df ------------------------------------------------------------------------

# deleting 2 rows from total_state_crime initial
total_state_crime <- total_state_crime |> select(-sl__no_, -state_ut)
str(total_state_crime)

total_state_crime <- total_state_crime |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "count"
  ) |>
  mutate(
    count = as.numeric(count),
    variable = case_when(
      str_detect(variable, "^cases_reported___col__3_$") ~ "Cases reported",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____below_6_years___col__4_$"
      ) ~ "Child rape victims (<18), <6 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____6_years_and_above___below_12_years___col__5_$"
      ) ~ "Child rape victims (<18), 6–<12 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____12_years_and_above___below_16_years___col__6_$"
      ) ~ "Child rape victims (<18), 12–<16 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____16_years_and_above___below_18_years___col__7_$"
      ) ~ "Child rape victims (<18), 16–<18 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____total_girl___child_victims___col__8_$"
      ) ~ "Child rape victims total (girls)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____18_years_and_above___below_30_years___col__9_$"
      ) ~ "Women rape victims (18–<30 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____30_years_and_above___below_45_years___col__10_$"
      ) ~ "Women rape victims (30–<45 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____45_years_and_above___below_60_years___col__11_$"
      ) ~ "Women rape victims (45–<60 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____60_years_and_above___col__12_$"
      ) ~ "Women rape victims (60+)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____total_women___adult_victims___col__13_$"
      ) ~ "Women rape victims total (adult)",
      str_detect(
        variable,
        "^total_victims__col_8_col_13____col__14_$"
      ) ~ "Total victims",
      TRUE ~ variable
    )
  ) |>
  select(variable, count)


# Total_UT_crime_df ---------------------------------------------------------------------------

total_ut_crime <- total_and_percentage[1, ]
total_ut_crime <- total_ut_crime |> select(-sl__no_, -state_ut)


total_ut_crime <- total_ut_crime |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "count"
  ) |>
  mutate(
    count = as.numeric(count),
    variable = case_when(
      str_detect(variable, "^cases_reported___col__3_$") ~ "Cases reported",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____below_6_years___col__4_$"
      ) ~ "Child rape victims (<18), <6 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____6_years_and_above___below_12_years___col__5_$"
      ) ~ "Child rape victims (<18), 6–<12 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____12_years_and_above___below_16_years___col__6_$"
      ) ~ "Child rape victims (<18), 12–<16 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____16_years_and_above___below_18_years___col__7_$"
      ) ~ "Child rape victims (<18), 16–<18 years",
      str_detect(
        variable,
        "^child_victims_of_rape__below_18_yrs____total_girl___child_victims___col__8_$"
      ) ~ "Child rape victims total (girls)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____18_years_and_above___below_30_years___col__9_$"
      ) ~ "Women rape victims (18–<30 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____30_years_and_above___below_45_years___col__10_$"
      ) ~ "Women rape victims (30–<45 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____45_years_and_above___below_60_years___col__11_$"
      ) ~ "Women rape victims (45–<60 years)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____60_years_and_above___col__12_$"
      ) ~ "Women rape victims (60+)",
      str_detect(
        variable,
        "^women_victims_of_rape__above_18_years____total_women___adult_victims___col__13_$"
      ) ~ "Women rape victims total (adult)",
      str_detect(
        variable,
        "^total_victims__col_8_col_13____col__14_$"
      ) ~ "Total victims",
      TRUE ~ variable
    )
  ) |>
  select(variable, count)


# state_data ----------------------------------------------------------------------------------


