# Shared validation, transformations, and reports. Run scripts from the project root.
age_columns <- c("child_below_6", "child_6_to_12", "child_12_to_16", "child_16_to_18",
                 "women_18_to_30", "women_30_to_45", "women_45_to_60", "women_above_60")
data_columns <- c("sl_no", "state_ut", "cases_reported", age_columns[1:4],
                  "total_child_victims", age_columns[5:8], "total_women_victims", "total_victims")
age_labels <- c("<6", "6-<12", "12-<16", "16-<18", "18-<30", "30-<45", "45-<60", "60+")

api_columns <- c(
    "sl__no_",
    "state_ut",
    "cases_reported___col__3_",
    "child_victims_of_rape__below_18_yrs____below_6_years___col__4_",
    "child_victims_of_rape__below_18_yrs____6_years_and_above___below_12_years___col__5_",
    "child_victims_of_rape__below_18_yrs____12_years_and_above___below_16_years___col__6_",
    "child_victims_of_rape__below_18_yrs____16_years_and_above___below_18_years___col__7_",
    "child_victims_of_rape__below_18_yrs____total_girl___child_victims___col__8_",
    "women_victims_of_rape__above_18_years____18_years_and_above___below_30_years___col__9_",
    "women_victims_of_rape__above_18_years____30_years_and_above___below_45_years___col__10_",
    "women_victims_of_rape__above_18_years____45_years_and_above___below_60_years___col__11_",
    "women_victims_of_rape__above_18_years____60_years_and_above___col__12_",
    "women_victims_of_rape__above_18_years____total_women___adult_victims___col__13_",
    "total_victims__col_8_col_13____col__14_"
)

csv_columns <- c(
    "Sl. No.",
    "State/UT",
    "Cases Reported - Col.(3)",
    "Child Victims of Rape (Below 18 Yrs) - Below 6 Years - Col.(4)",
    "Child Victims of Rape (Below 18 Yrs) - 6 Years and Above - Below 12 Years - Col.(5)",
    "Child Victims of Rape (Below 18 Yrs) - 12 Years and Above - Below 16 Years - Col.(6)",
    "Child Victims of Rape (Below 18 Yrs) - 16 Years and Above - Below 18 Years - Col.(7)",
    "Child Victims of Rape (Below 18 Yrs) - Total Girl / Child Victims - Col.(8)",
    "Women Victims of Rape (Above 18 Years) - 18 Years and Above - Below 30 Years - Col.(9)",
    "Women Victims of Rape (Above 18 Years) - 30 Years and Above - Below 45 Years - Col.(10)",
    "Women Victims of Rape (Above 18 Years) - 45 Years and Above - Below 60 Years - Col.(11)",
    "Women Victims of Rape (Above 18 Years) - 60 Years and Above - Col.(12)",
    "Women Victims of Rape (Above 18 Years) - Total Women / Adult Victims - Col.(13)",
    "Total Victims (Col.8+Col.13) - Col.(14)"
)
