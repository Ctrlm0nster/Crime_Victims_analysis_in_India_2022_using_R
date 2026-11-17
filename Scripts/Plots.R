# Match the heatmap's Lab gradient and choose black/white text by WCAG contrast.
heatmap_text <- function(share) {
    colours <- scales::seq_gradient_pal("#F0F5FA", "#00446B", space = "Lab")(share / 100)
    rgb <- grDevices::col2rgb(colours) / 255
    linear <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
    luminance <- colSums(linear * c(0.2126, 0.7152, 0.0722))
    ifelse(1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05, "white", "black")
}

build_plots <- function(df, summary) {
    library(ggplot2)
    age_distribution <- summary$age_distribution
    category_summary <- summary$category_summary
    top_10_states <- head(df, 10)
    ink <- "#172B3A"
    blue <- "#0072B2" # Okabe-Ito blue
    orange <- "#B34F00" # Dark orange for legible text on white
    muted <- "#536574"
    plot_theme <- theme_minimal(base_size = 13, base_family = "sans") +
        theme(plot.background = element_rect(fill = "#FFFFFF", colour = NA),
              panel.background = element_rect(fill = "#FFFFFF", colour = NA),
              text = element_text(colour = ink),
              plot.title = element_text(face = "bold", size = 21, margin = margin(b = 9)),
              plot.subtitle = element_text(size = 12, colour = muted, margin = margin(b = 20)),
              plot.title.position = "plot", plot.caption.position = "plot",
              plot.caption = element_text(size = 9, colour = muted, hjust = 0, margin = margin(t = 18)),
              axis.title = element_text(size = 11, colour = muted),
              axis.text = element_text(size = 11, colour = ink),
              panel.grid.minor = element_blank(),
              panel.grid.major.y = element_blank(),
              panel.grid.major.x = element_line(colour = "#E4EAF0", linewidth = 0.4),
              strip.text = element_text(face = "bold", size = 12, hjust = 0),
              strip.background = element_rect(fill = "#EDF3F7", colour = NA),
              panel.spacing = grid::unit(2, "lines"),
              legend.position = "bottom", legend.title = element_text(size = 10),
              plot.margin = margin(24, 32, 20, 24))
    source_caption <- "SOURCE  NCRB, 2022 | 36 states/UTs; aggregate rows excluded. Counts reflect reported cases and victims."
    ranked <- \(x) factor(x, levels = x |> as.character() |> unique() |> rev())
    top_cases <- df |> head(15)
    top_cases$state_ut <- ranked(top_cases$state_ut)
    p1 <- ggplot(top_cases, aes(cases_reported, state_ut)) +
        geom_col(fill = blue, width = 0.65) +
        geom_text(aes(label = scales::comma(cases_reported)), hjust = -0.18,
                  size = 3.7, colour = ink, fontface = "bold") +
        scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.16))) +
        labs(title = "Reported cases: Rajasthan leads the count",
             subtitle = "15 states/UTs with the most reported cases | India, 2022",
             x = "Reported cases", y = NULL) + plot_theme

    top <- df |> dplyr::arrange(dplyr::desc(total_victims), state_ut) |> dplyr::slice_head(n = 15)
    demographics <- top |>
        dplyr::select(state_ut, total_women_victims, total_child_victims) |>
        tidyr::pivot_longer(-state_ut, names_to = "type", values_to = "count") |>
        dplyr::mutate(
            state_ut = factor(state_ut, levels = rev(top$state_ut)),
            type = factor(type, levels = c("total_women_victims", "total_child_victims"),
                          labels = c("Adults (18+)", "Children (under 18)"))
        )
    p2 <- ggplot(demographics, aes(count, state_ut, fill = type)) +
        geom_col(width = 0.65, show.legend = FALSE) +
        geom_text(aes(label = scales::comma(count)), hjust = -0.18, size = 3.3, colour = ink) +
        facet_wrap(~type, scales = "free_x", nrow = 1) +
        scale_fill_manual(values = c("Adults (18+)" = blue, "Children (under 18)" = orange)) +
        scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.26))) +
        labs(title = "Adult and child victims, shown separately",
             subtitle = "Top 15 states/UTs by total victims | Each panel has its own count scale",
             x = "Victims", y = NULL) + plot_theme

    ages <- data.frame(age_group = factor(age_labels, levels = rev(age_labels)),
                       count = unname(age_distribution))
    ages$group <- ifelse(seq_len(nrow(ages)) <= 4, "Children", "Adults")
    ages$label <- paste0(scales::comma(ages$count), "  |  ",
                        sprintf("%.1f%%", 100 * ages$count / sum(ages$count)))
    adult_share <- 100 * sum(df$total_women_victims) / sum(df$total_victims)
    p3 <- ggplot(ages, aes(count, age_group, fill = group)) +
        geom_col(width = 0.65, show.legend = FALSE) +
        geom_text(aes(label = label), hjust = -0.12, size = 3.8, colour = ink) +
        scale_fill_manual(values = c("Children" = orange, "Adults" = blue)) +
        scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.30))) +
        labs(title = "Most victims were aged 18 to under 30",
             subtitle = paste0(scales::comma(sum(ages$count)), " victims nationally | ",
                               sprintf("%.1f%%", adult_share), " were adults | Labels show count and share"),
             x = "Victims", y = "Age in years") + plot_theme

    shares <- df |>
        dplyr::filter(total_child_victims > 0) |>
        dplyr::arrange(dplyr::desc(child_percentage), state_ut)
    shares$state_ut <- ranked(shares$state_ut)
    shares$label <- paste0(sprintf("%.1f%%", shares$child_percentage), "   (",
                            shares$total_child_victims, "/", scales::comma(shares$total_victims), ")")
    p4 <- ggplot(shares, aes(child_percentage, state_ut)) +
        geom_segment(aes(x = 0, xend = child_percentage, yend = state_ut), colour = "#CFDDE6", linewidth = 1.5) +
        geom_point(colour = blue, size = 3.5) +
        geom_text(aes(label = label), hjust = -0.14, size = 3.3, colour = ink) +
        scale_x_continuous(limits = c(0, 108), breaks = seq(0, 100, 20),
                           labels = \(x) paste0(x, "%"), expand = expansion(mult = c(0.01, 0))) +
        labs(title = "Child victims as a share of all victims",
             subtitle = "States/UTs with reported child victims | Labels: % (children / all victims)\nSmall victim totals can produce large percentages.",
             x = "Share of victims under 18", y = NULL) + plot_theme

    category_summary$display <- factor(c("Under 100", "100 to 499", "500 to 999", "1,000 or more"),
                                      levels = rev(c("Under 100", "100 to 499", "500 to 999", "1,000 or more")))
    p5 <- ggplot(category_summary, aes(n, display)) +
        geom_col(fill = blue, width = 0.55) +
        geom_text(aes(label = paste0(n, " states/UTs  |  ", sprintf("%.1f%%", percentage))),
                  hjust = -0.12, size = 4, colour = ink) +
        scale_x_continuous(breaks = seq(0, 16, 4), limits = c(0, 20), expand = expansion(mult = c(0, 0))) +
        labs(title = "How reported cases are distributed",
             subtitle = "Each state/UT belongs to one group | 36 states/UTs in total",
             x = "Number of states/UTs", y = "Reported cases in 2022") + plot_theme

    breakdown <- top_10_states |>
        dplyr::select(state_ut, total_victims, dplyr::all_of(age_columns)) |>
        tidyr::pivot_longer(dplyr::all_of(age_columns), names_to = "age_group", values_to = "count") |>
        dplyr::mutate(
            state_ut = factor(state_ut, levels = rev(top_10_states$state_ut)),
            age_group = factor(age_group, levels = age_columns, labels = age_labels),
            share = 100 * count / total_victims
        )
    p6 <- ggplot(breakdown, aes(age_group, state_ut, fill = share)) +
        geom_tile(colour = "white", linewidth = 1.2) +
        geom_text(aes(label = sprintf("%.1f%%", share), colour = heatmap_text(share)), size = 3.4) +
        scale_colour_identity() +
        scale_fill_gradient(low = "#F0F5FA", high = "#00446B", limits = c(0, 100),
                            breaks = c(0, 25, 50, 75, 100), labels = \(x) paste0(x, "%"),
                            guide = guide_colourbar(barwidth = grid::unit(7, "cm"), barheight = grid::unit(0.35, "cm"))) +
        scale_x_discrete(expand = c(0, 0)) + scale_y_discrete(expand = c(0, 0)) +
        labs(title = "Victim age profiles at a glance",
             subtitle = "Top 10 states/UTs by reported cases | Each row totals 100% before rounding\nDarker cells mean a larger share of that state's victims.",
             x = "Victim age in years", y = NULL, fill = "Share of victims") + plot_theme +
        theme(panel.grid = element_blank(), axis.text.x = element_text(size = 10))
    list(p1, p2, p3, p4, p5, p6) |>
        purrr::map(\(plot) plot + labs(caption = source_caption))
}


save_plots <- function(plots, output_dir) {
    filenames <- c("plot1_top15_states_cases", "plot2_child_vs_adult_victims", "plot3_age_distribution_india",
                   "plot4_child_victim_percentage", "plot5_case_volume_categories", "plot6_age_breakdown_top10")
    purrr::walk2(plots, filenames, \(plot, name)
        ggplot2::ggsave(file.path(output_dir, "plots", paste0(name, ".png")), plot,
                        width = 12, height = 8, dpi = 300))
    grDevices::pdf(file.path(output_dir, "plots", paste0(basename(output_dir), "_Generated_Plots.pdf")),
                   width = 12, height = 8)
    on.exit(grDevices::dev.off(), add = TRUE)
    purrr::walk(plots, print)
}
