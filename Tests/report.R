# Validate the standalone HTML, including its data table and embedded figures.
source("Scripts/Common.R")
path <- "Result/report/report.html"
if (!file.exists(path)) stop("Render the report before running Tests/report.R")
doc <- xml2::read_html(path)
metrics <- xml2::xml_text(xml2::xml_find_all(doc, "//*[contains(@class, 'metric-card')]/strong"))
stopifnot(identical(metrics, c("31,516", "31,982", "1,017", "3.18%")),
          length(xml2::xml_find_all(doc, "//table/tbody/tr")) == 36,
          length(xml2::xml_find_all(doc, "//img[@alt]")) >= 6,
          length(xml2::xml_find_all(doc, "//img[not(starts-with(@src, 'data:'))]")) == 0,
          length(xml2::xml_find_all(doc, "//script[@src and not(starts-with(@src, 'data:'))]")) == 0,
          length(xml2::xml_find_all(doc, "//link[@rel='stylesheet' and not(starts-with(@href, 'data:'))]")) == 0)
cat("Quarto report metrics, 36-row table, image descriptions, and embedded assets verified.\n")
