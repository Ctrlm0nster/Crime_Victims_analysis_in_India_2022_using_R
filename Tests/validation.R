source("Scripts/Common.R")
raw <- read.csv("Data/raw/NCRB_DATA.3.csv", check.names = FALSE)
clean <- clean_records(raw)
stopifnot(nrow(clean) == 36, sum(clean$cases_reported) == 31516,
          sum(clean$total_child_victims) == 1017,
          sum(clean$total_women_victims) == 30965,
          sum(clean$total_victims) == 31982,
          clean$state_ut[1] == "Rajasthan")
rejects <- function(x) inherits(try(clean_records(x), silent = TRUE), "try-error")
stopifnot(rejects(raw[1:10, ]))
bad <- raw
bad[2, ] <- bad[1, ]
stopifnot(rejects(bad))
bad <- raw
bad[1, 8] <- bad[1, 8] + 1
stopifnot(rejects(bad))
bad <- raw
bad[1, 3] <- NA
stopifnot(rejects(bad))
source("Scripts/Cleaning_data.R")
stopifnot(all(is.na(clean$cases_per_100k_2011_population[clean$state_ut %in%
    c("Andhra Pradesh", "Telangana", "Jammu and Kashmir", "Ladakh")])),
    !anyNA(clean$population_2011[!clean$state_ut %in%
    c("Andhra Pradesh", "Telangana", "Jammu and Kashmir", "Ladakh")]))
cat("Validation checks passed.\n")
# Source field ordering must not change numeric meanings.
reordered <- raw[rev(names(raw))]
stopifnot(identical(clean_records(raw), clean_records(reordered)))
bad <- raw
names(bad)[3] <- "unexpected_field"
stopifnot(rejects(bad))
bad <- raw
bad[1, 2] <- ""
stopifnot(rejects(bad))
# The plotting entry point must also reject incomplete data.
stopifnot(inherits(try(run_analysis(clean_records(raw)[1:10, ], tempfile()), silent = TRUE), "try-error"))
cat("Schema and analysis-entry validation checks passed.\n")
# Heatmap labels maintain at least 4.5:1 contrast throughout the gradient.
shares <- seq(0, 100, by = 0.1)
colours <- scales::seq_gradient_pal("#F0F5FA", "#00446B", space = "Lab")(shares / 100)
rgb <- grDevices::col2rgb(colours) / 255
linear <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
luminance <- colSums(linear * c(0.2126, 0.7152, 0.0722))
contrast <- ifelse(heatmap_text(shares) == "white", 1.05 / (luminance + 0.05),
                   (luminance + 0.05) / 0.05)
stopifnot(all(contrast >= 4.5))
cat("Heatmap text contrast checks passed (minimum 4.5:1).\n")
