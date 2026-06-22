library(httr)
library(xml2)
library(tidyverse)

# Loading data --------------------------------------------------------------------------------

# Fetch data from API
url <- "https://api.data.gov.in/resource/0a096e81-5a1b-4e23-9f28-1abd1db76d16"
api_key <- Sys.getenv("GOV_API_KEY")

# Fetch function
fetch_page <- function(offset) {
    # Get request for the given offset
    response <- GET(
        url = url,
        query = list(
            `api-key` = api_key,
            format = "xml",
            limit = 10,
            offset = offset
        )
    )

    # reading XML
    xml.doc <- read_xml(content(response, "text", encoding = "UTF-8"))
    # parsing XML
    items <- xml_find_all(xml.doc, ".//records/item")

    lapply(items, function(item) {
        children <- xml_children(item)
        vals <- xml_text(children)
        names(vals) <- xml_name(children)
        vals
    })
}

# Fetch all 36 records with delay to avoid Rate limit (4 pages of 10)
all_records <- c(
    fetch_page(0),
    {Sys.sleep(2); fetch_page(10)},
    {Sys.sleep(2); fetch_page(20)},
    {Sys.sleep(2); fetch_page(30)}
)
cat("Content fetched successfully!\n")

#  Building data frame
all_records_df <- bind_rows(all_records)
cat("Total rows:", nrow(all_records_df), "\n")

# Saving records
saveRDS(all_records_df, "Data/full_xml_content.rds")
cat("XML Content Saved!\n")


# Data Cleaning -------------------------------------------------------------------------------

# The last 3 rows contain totals and percentage contributions — move them to a separate df
# Remove last 3 rows from df and put them in a separate df
df_last3        <- tail(all_records_df, 3)
all_records_df  <- head(all_records_df, -3)


cat("Main all_records_df rows:", nrow(all_records_df), "\n")    # should be 37
cat("Last 3 df rows:", nrow(df_last3), "\n")  # should be 3

saveRDS(df_last3,       "Data/totals_and_percentages.rds")
saveRDS(all_records_df, "Data/main_records.rds")
cat("Data Saved!\n")

# Separating the data State and UT data -------------------------------------------------------

State_data  <- all_records_df[1:28, ]   # Rows 1–28:  State data
state_total <- all_records_df[29, ]     # Row 29:     State totals
UT_data     <- all_records_df[30:37, ]  # Rows 30–37: UT data

saveRDS(State_data,  "Data/state_data.rds")
saveRDS(state_total, "Data/state_total.rds")
saveRDS(UT_data,     "Data/ut_data.rds")

# Verify dimensions
dim(State_data)
dim(state_total)
dim(UT_data)

# Preview
head(State_data)
state_total
head(UT_data)
