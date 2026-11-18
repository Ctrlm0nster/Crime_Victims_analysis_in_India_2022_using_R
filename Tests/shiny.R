# Test actual server reactivity, including empty selections and literal table searches.
local({
    app <- new.env(parent = globalenv())
    sys.source("App/app.R", envir = app)
    shiny::testServer(app$server, {
        session$setInputs(states = sort(app$data$state_ut), region = "All jurisdictions",
                           metric = "cases_reported", top_n = 5, proportions = FALSE, search = "")
        stopifnot(nrow(selected()) == 36, metrics()$cases == 31516,
                  metrics()$victims == 31982, metrics()$children == 1017,
                  nrow(ranking()) == 5, ranking()$state_ut[1] == "Rajasthan",
                  sum(ages()$count) == 31982)
        session$setInputs(region = "Union territories")
        stopifnot(nrow(selected()) == 8, metrics()$cases == 1616)
        session$setInputs(region = "All jurisdictions", states = "Goa", proportions = TRUE)
        stopifnot(metrics()$victims == 75, metrics()$child_share == 76,
                  abs(sum(ages()$value) - 100) < 1e-8, nrow(table_data()) == 1)
        session$setInputs(search = "[")
        stopifnot(nrow(table_data()) == 0)
        session$setInputs(search = "gOa")
        stopifnot(nrow(table_data()) == 1)
        session$setInputs(region = "Union territories")
        stopifnot(nrow(selected()) == 0, metrics()$cases == 0, is.na(metrics()$child_share))
        session$setInputs(region = "All jurisdictions", states = character())
        stopifnot(nrow(selected()) == 0, nrow(ranking()) == 0)
        session$setInputs(states = sort(app$data$state_ut), metric = "child_percentage", top_n = 10)
        stopifnot(nrow(ranking()) == 10, ranking()$state_ut[1] == "Goa",
                  nrow(app$app_export(selected())) == 36,
                  sum(app$app_export(selected())$total_child_victims) == 1017)
    })
    cat("Shiny filters, totals, ranking, age shares, search, and empty-selection checks passed.\n")
})
