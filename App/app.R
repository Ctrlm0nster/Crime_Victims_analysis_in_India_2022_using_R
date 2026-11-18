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

library(shiny)
library(bslib)
library(ggplot2)
data <- read_source_csv(file.path(root, "Data/raw/NCRB_DATA.3.csv"))
metric_labels <- c(cases_reported = "Reported cases", total_victims = "Victims",
                   child_percentage = "Child victim share (%)")
app_theme <- theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
          plot.title = element_text(face = "bold", size = 16),
          axis.title.y = element_blank(), plot.margin = margin(12, 25, 12, 12))

ui <- page_sidebar(
    title = div(class = "app-brand", span(class = "brand-kicker", "NCRB / INDIA / 2022"),
                h1("Reported cases & victim profiles")),
    window_title = "NCRB 2022 | Explore the data", lang = "en", fillable = FALSE,
    theme = bs_theme(version = 5, primary = "#0072B2", secondary = "#536574",
                     base_font = "system-ui"),
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "style.css")),
    sidebar = sidebar(
        title = "Choose your view", width = 310,
        selectInput("region", "Jurisdiction type", c("All jurisdictions", "States", "Union territories")),
        selectizeInput("states", "States and union territories", choices = sort(data$state_ut),
                       selected = sort(data$state_ut), multiple = TRUE,
                       options = list(plugins = list("remove_button"), maxItems = 36,
                                      placeholder = "Search a state or UT")),
        layout_columns(actionButton("select_all", "Select all", class = "btn-sm"),
                       actionButton("clear", "Clear", class = "btn-sm")),
        selectInput("metric", "Rank by", choices = stats::setNames(names(metric_labels), metric_labels)),
        sliderInput("top_n", "Jurisdictions in the ranking", min = 1, max = 36, value = 15, step = 1),
        hr(),
        p(class = "small text-muted", "Filters apply to every tab and download. The ranking limit changes only the ranking chart."),
        downloadButton("download", "Download selected data", class = "btn-primary")
    ),
    div(class = "intro-strip", p("Explore the recorded data, with the context alongside it."),
        p(class = "small mb-0", "Cases and victims are different measures. These figures describe reporting, and should not be read as safety rankings.")),
    uiOutput("selection_note"),
    uiOutput("metrics"),
    navset_card_tab(
        nav_panel("Compare jurisdictions", uiOutput("ranking_ui"),
                  p(class = "chart-note", "Each label shows the value plotted. Child victim shares use all victims as the denominator.")),
        nav_panel("Age profile", checkboxInput("proportions", "Show percentage of selected victims", FALSE),
                  plotOutput("ages", height = "470px"),
                  p(class = "chart-note", "Age intervals include the lower bound and exclude the upper bound; 60+ includes everyone aged 60 or older.")),
        nav_panel("Data table", textInput("search", "Find a jurisdiction in the table", placeholder = "e.g. Rajasthan"),
                  div(class = "table-responsive", tableOutput("table")),
                  p(class = "chart-note", "Table search narrows this table only. The download includes all jurisdictions selected in the sidebar.")),
        nav_panel("Read the data", h3("What the numbers mean"),
                  tags$ul(tags$li("Reported cases and victims can differ because a case can involve multiple victims."),
                          tags$li("Children are victims under 18; adults are 18 and older."),
                          tags$li("Child share = child victims / all victims in the selection. It is not a population rate."),
                          tags$li("State, UT, and national summary rows are excluded to avoid double counting.")),
                  h3("Interpretation"),
                  p("Population size, reporting practices, and administrative differences affect counts. Small totals can produce large percentages. Reported records do not measure the full incidence of sexual violence."),
                  p("Population-based rates are intentionally absent from this app: the supplied census table uses 2011 populations and cannot resolve several 2022 boundaries."),
                  p("Source: NCRB, State/UT-wise Number of Women and Girls Victims of Rape during 2022, distributed through data.gov.in. Clarifications from Nagaland were pending in the source notes."))
    ),
    tags$footer(class = "app-footer", "Source: NCRB 2022 · 36 validated jurisdiction records · Local data; no API key required")
)

server <- function(input, output, session) {
    observeEvent(input$select_all, updateSelectizeInput(session, "states", selected = sort(data$state_ut)))
    observeEvent(input$clear, updateSelectizeInput(session, "states", selected = character()))
    selected <- reactive(app_filter(data, input$states, input$region))
    metrics <- reactive(app_metrics(selected()))
    ranking <- reactive({ req(input$metric, input$top_n); app_ranking(selected(), input$metric, input$top_n) })
    ages <- reactive(app_age_profile(selected(), isTRUE(input$proportions)))
    table_data <- reactive({
        current <- app_export(selected())
        search <- if (is.null(input$search)) "" else trimws(input$search)
        if (nzchar(search))
            current <- dplyr::filter(current, grepl(tolower(search), tolower(state_ut), fixed = TRUE))
        current
    })
    output$selection_note <- renderUI({
        n <- nrow(selected())
        div(class = "selection-note", role = "status",
            if (n == 0) "No matching jurisdictions. Select at least one state/UT, or change the jurisdiction type."
            else sprintf("Showing %d of 36 jurisdictions. Totals below apply to this selection.", n))
    })
    output$metrics <- renderUI({
        m <- metrics()
        layout_column_wrap(width = 1/4,
            value_box("Reported cases", scales::comma(m$cases), theme = "primary", showcase = NULL),
            value_box("All victims", scales::comma(m$victims), theme = "light", showcase = NULL),
            value_box("Child victims", scales::comma(m$children), theme = "light", showcase = NULL),
            value_box("Child victim share", if (is.na(m$child_share)) "Unavailable" else sprintf("%.2f%%", m$child_share),
                      theme = "light", showcase = NULL))
    })
    output$ranking_ui <- renderUI(plotOutput("ranking", height = paste0(max(500, 28 * nrow(ranking()) + 130), "px")))
    output$ranking <- renderPlot({
        validate(need(nrow(ranking()) > 0, "Choose at least one jurisdiction to see a ranking."))
        metric <- input$metric
        ranking() |>
            dplyr::mutate(state_ut = factor(state_ut, levels = rev(state_ut))) |>
            ggplot(aes(.data[[metric]], state_ut)) +
            geom_col(fill = "#0072B2", width = 0.65) +
            geom_text(aes(label = if (metric == "child_percentage") sprintf("%.1f%%", .data[[metric]]) else scales::comma(.data[[metric]])),
                      hjust = -0.15, size = 3.6, colour = "#172B3A") +
            scale_x_continuous(expand = expansion(mult = c(0, 0.22)), labels = scales::comma) +
            labs(title = metric_labels[[metric]], subtitle = sprintf("Top %d of %d selected jurisdictions", nrow(ranking()), nrow(selected())),
                 x = metric_labels[[metric]]) + app_theme
    }, res = 110, alt = reactive(paste("Ranking of selected states and union territories by", metric_labels[[input$metric]])))
    output$ages <- renderPlot({
        validate(need(sum(selected()$total_victims) > 0, "Choose a selection with recorded victims to see the age profile."))
        ages() |>
            dplyr::mutate(age_group = factor(age_group, levels = rev(age_labels)),
                          group = ifelse(as.character(age_group) %in% age_labels[1:4], "Children", "Adults")) |>
            ggplot(aes(value, age_group, fill = group)) + geom_col(width = 0.65, show.legend = FALSE) +
            geom_text(aes(label = if (isTRUE(input$proportions)) sprintf("%.1f%%", value) else scales::comma(value)),
                      hjust = -0.15, size = 3.7) +
            scale_fill_manual(values = c("Children" = "#B34F00", "Adults" = "#0072B2")) +
            scale_x_continuous(expand = expansion(mult = c(0, 0.18)), labels = scales::comma) +
            labs(title = "Victim ages in your selection", x = if (isTRUE(input$proportions)) "Percentage of selected victims" else "Victims") + app_theme
    }, res = 110, alt = "Age distribution of victims in the selected jurisdictions, with direct count or percentage labels.")
    output$table <- renderTable({
        validate(need(nrow(table_data()) > 0, "No jurisdictions match the current selection and table search."))
        table_data() |>
            dplyr::transmute(`State / UT` = state_ut, Cases = cases_reported, Victims = total_victims,
                              Children = total_child_victims, Adults = total_women_victims,
                              `Child share (%)` = round(child_percentage, 2))
    }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "s", digits = 2)
    output$download <- downloadHandler(
        filename = function() "ncrb-2022-selected-jurisdictions.csv",
        content = function(file) readr::write_csv(app_export(selected()), file)
    )
}

shinyApp(ui, server)
