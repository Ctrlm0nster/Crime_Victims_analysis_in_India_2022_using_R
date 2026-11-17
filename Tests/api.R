# Exercise XML parsing and pagination with local fixtures, without API credentials.
source("Scripts/Common.R")
if (!requireNamespace("xml2", quietly = TRUE)) stop("Install xml2 to run API fixture tests")
records <- readr::read_csv("Data/raw/NCRB_DATA.3.csv",
    col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE) |>
    stats::setNames(api_columns)

calls <- integer()
fixture_page <- function(offset, key) {
    calls <<- c(calls, offset)
    list(total = nrow(records), records = records[seq.int(offset + 1, min(offset + 10, nrow(records))), ])
}
actual <- fetch_records(fixture_page, key = "fixture", pause = \(seconds) invisible(NULL))
stopifnot(identical(calls, c(0L, 10L, 20L, 30L)),
          isTRUE(all.equal(clean_records(actual), read_source_csv())))

fails <- \(expr) inherits(try(force(expr), silent = TRUE), "try-error")
stopifnot(fails(fetch_records(key = "")))
stopifnot(fails(fetch_records(\(offset, key) list(total = 40, records = records[FALSE, ]), key = "fixture")))
stopifnot(fails(fetch_records(\(offset, key) list(total = 10, records = records[1:10, ]), key = "fixture")))
stopifnot(fails(fetch_records(\(offset, key) list(total = 1, records = records[1:2, ]), key = "fixture")))
stopifnot(fails(fetch_records(\(offset, key) list(total = if (offset == 0) 40 else 39,
    records = records[1:10, ]), key = "fixture", pause = \(seconds) NULL)))
stopifnot(fails(fetch_records(\(offset, key) list(total = 40, records = records[1:10, ]),
    key = "fixture", pause = \(seconds) NULL)))

# Round-trip field values through actual XML, including reordered fields.
doc <- xml2::xml_new_root("result")
xml2::xml_add_child(doc, "total", "40")
items <- xml2::xml_add_child(doc, "records")
for (row in 1:10) {
    item <- xml2::xml_add_child(items, "item")
    for (column in rev(api_columns)) xml2::xml_add_child(item, column, records[[column]][row])
}
page <- parse_xml_page(as.character(doc))
stopifnot(page$total == 40, identical(page$records, records[1:10, ]))
xml2::xml_add_child(item, api_columns[1], "duplicate")
stopifnot(fails(parse_xml_page(as.character(doc))),
          fails(parse_xml_page("<result><total>40</total><records/></result>")))
# Remove the duplicated field and one required field to verify schema rejection.
xml2::xml_remove(tail(xml2::xml_children(item), 1))
xml2::xml_remove(xml2::xml_children(item)[1])
stopifnot(fails(parse_xml_page(as.character(doc))))
cat("XML parsing and pagination fixture checks passed.\n")
