 # app/app.R
# Which New Jersey public college should a future math major pick? Generated using Claude's Fable 5.2 on 11/11/2026 for instructional purposes. Many mistakes are present.
#
# Audience: a New Jersey high school junior who wants to major in math.
# Decision: which of New Jersey's 13 public four-year colleges to put at the top of the list.
#
# Test with the Run App button (not Ctrl+Enter). The app reads the three files in app/data/,
# which scripts/02_build_dashboard_data.R makes. Inside the app the folder is "data/", because
# the app runs from the app/ folder.

library(shiny)
library(tidyverse)
library(sf)


# The Data ---------------------------------------------------------------------------------------

# One row is one college (13 rows)
colleges <- read_csv(
  "data/colleges.csv",
  col_types = cols(
    unitid = col_character(),    # keep the codes as text
    opeid6 = col_character()
  )
)

# One row is one college and one income group (78 rows)
net_price <- read_csv(
  "data/net_price.csv",
  col_types = cols(unitid = col_character())
)

# One row is one county (21 rows), for the map
nj_counties <- read_sf("data/nj_counties.gpkg")

# The income groups in order (sort() would put "$110,001 or more" second)
income_choices <- c(
  "Any income (average)",
  "$0 to $30,000",
  "$30,001 to $48,000",
  "$48,001 to $75,000",
  "$75,001 to $110,000",
  "$110,001 or more"
)

# The picked college is blue and the rest are gray in every figure
pick_colours <- c("TRUE" = "steelblue", "FALSE" = "grey70")

# The benchmarks that do not change with a control
median_math <- median(colleges$math_per_100)

median_admit <- median(colleges$admit_per_100)

national_earn <- max(colleges$earn_national, na.rm = TRUE)   # the same number in every row

# NOTE: the bar charts have fixed axes, so the numbers on the right line up and Figure 2 keeps
# the same axis for every income group. A bar longer than its axis would not be drawn! The
# longest bars now: 2.9 (Figure 1, axis to 4.4), 34,232 (Figure 2, axis to 42,000), and 94,840
# (Figure 4, axis to 118,000). 02_build_dashboard_data.R prints these three numbers.


# What the Reader Sees ---------------------------------------------------------------------------

ui <- fluidPage(

  style = "max-width: 950px;",

  titlePanel("Which New Jersey public college should a future math major pick? Generated using Claude's Fable 5.2 on 11/11/2026 for instructional purposes. Many mistakes are present."),

  p(strong("Who this is for:"), "a New Jersey high school junior who wants to major in math,
    and the family helping with the decision."),

  p(strong("The decision:"), "which of New Jersey's 13 public four-year colleges belongs at the
    top of your list."),

  p("Pick a college. It turns blue in every figure, and the sentence in bold under each figure
    changes to describe it. The dashed line in a figure is the benchmark. In Figures 1 and 2 it
    is the median college: half of the 13 colleges are above it and half are below. Each college
    counts once, no matter how big it is. In Figure 3 it is your own score, and in Figure 4 it is
    the median for math graduates across the country."),

  selectInput(
    inputId = "pick",
    label = "Pick a college:",
    choices = sort(colleges$college),
    selected = "TCNJ"
  ),

  h3("Figure 1. How big a part of the college is math?"),

  plotOutput(outputId = "fig_1", height = "430px"),

  p(strong(textOutput(outputId = "text_1", inline = TRUE))),

  p("A longer bar means a bigger share of the graduates majored in math or statistics. The
    numbers on the right are the rate and then the count, because a big college can have many
    math majors and still have a short bar. Three graduating classes are added together because
    the yearly counts are small and bounce around."),

  p(em("Source: National Center for Education Statistics, IPEDS Completions. Bachelor's
    degrees awarded July 2022 to June 2025 (the 2024-25 year is a provisional release).")),

  h3("Figure 2. What would a year cost my family?"),

  selectInput(
    inputId = "income",
    label = "Your family's income (a rough guess is fine):",
    choices = income_choices,
    selected = "Any income (average)"
  ),

  plotOutput(outputId = "fig_2", height = "430px"),

  p(strong(textOutput(outputId = "text_2", inline = TRUE))),

  p("Net price is the average cost of one year (tuition, fees, books, housing, and food) minus
    grants and scholarships. It counts first-year, full-time, in-state students who received
    federal financial aid. It is an average, so your own price will depend on your aid offer and
    on whether you live at home."),

  p(em("Source: U.S. Department of Education, College Scorecard, institution-level file of
    November 2, 2026. Academic year 2024-25.")),

  h3("Figure 3. Would my math score fit in?"),

  sliderInput(
    inputId = "score",
    label = "Your SAT math score (a PSAT math score is a rough stand-in):",
    min = 200,
    max = 800,
    value = 550,
    step = 10,
    width = "450px"
  ),

  plotOutput(outputId = "fig_3", height = "380px"),

  p(strong(textOutput(outputId = "text_3", inline = TRUE))),

  p("Each line is the middle half of the new students who sent an SAT score: a quarter of them
    scored below the left end and a quarter scored above the right end. The dot is the median.
    Most of these colleges do not require the SAT, so the students who send a score are often
    the ones with higher scores! The label next to each college says how many of every 100 new
    students sent one. Four colleges reported no range: Bloomfield College, Kean Jersey City,
    Rutgers-Newark, and William Paterson."),

  p(em("Source: National Center for Education Statistics, IPEDS Admissions. Students who
    started in fall 2024.")),

  h3("Figure 4. What do math graduates earn?"),

  plotOutput(outputId = "fig_4", height = "380px"),

  p(strong(textOutput(outputId = "text_4", inline = TRUE))),

  p("Each bar is the median yearly earnings of people with a bachelor's degree in mathematics,
    four years after they graduated. It counts graduates who received federal financial aid and
    were working and not in school. The dashed line is the median for math graduates of every
    college in the country. The three Rutgers campuses share one bar because the Scorecard
    reports them together. Ramapo's number is hidden to protect privacy, and Bloomfield College
    has no number. These groups are small (25 to 142 graduates), so treat a gap of a few thousand
    dollars as a tie."),

  p(em("Source: U.S. Department of Education, College Scorecard, field of study file of
    October 15, 2026. Graduates of 2017-18 and 2018-19, earnings in 2022 and 2023, in 2024
    dollars.")),

  h3("Figure 5. Where is it?"),

  plotOutput(outputId = "fig_5", height = "520px"),

  p(strong(textOutput(outputId = "text_5", inline = TRUE))),

  p(em("Sources: National Center for Education Statistics, IPEDS Directory Information,
    2025-26 (where each college is). U.S. Census Bureau, cartographic boundary file, 2022 (the
    county lines).")),

  h3("What this dashboard cannot tell you"),

  p(strong("How big the math classes are, or who teaches them."), "No public data set has this.
    An Open Public Records Act (OPRA) request for TCNJ's math and statistics class sizes is
    drafted but has not been sent, so there are no records to show yet."),

  p(strong("Everything that counts as math."), "Figure 1 counts degrees that colleges report as
    mathematics or statistics. Data science, actuarial science, and math teaching degrees that
    a college reports under another field are not counted. Double majors are counted only when
    math is the first major."),

  p(strong("What happens to a small group next year."), "At most of these colleges fewer than
    30 students finish a math degree in a year, so the numbers can move a lot from one year to
    the next."),

  p(strong("Kean Jersey City."), "New Jersey City University became part of Kean University
    on July 1, 2026. Every number for it here is from before the merger."),

  p(strong("Thomas Edison State University"), "is left out. It is a public university built
    for adults, and it enrolled no first-time freshmen."),

  p(strong("Whether you would like it there!"), "Visit, sit in on a math class, and talk to
    students."),

  h3("Where the data came from"),

  p("IPEDS Complete Data Files, National Center for Education Statistics:",
    a("nces.ed.gov/ipeds/datacenter/DataFiles.aspx",
      href = "https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx")),

  p("College Scorecard data, U.S. Department of Education:",
    a("collegescorecard.ed.gov/data", href = "https://collegescorecard.ed.gov/data/")),

  p("Cartographic boundary files, U.S. Census Bureau:",
    a("census.gov cartographic boundary files",
      href = "https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html")),

  p("The IPEDS and College Scorecard files were downloaded on November 11, 2026. The county
    lines are the 2022 file used in STA 220 (workbook 3.3). The scripts and the data are in the
    reproduction package for this dashboard.")

)


# What the App Does ------------------------------------------------------------------------------

server <- function(input, output) {

  # Figure 1: math majors per 100 graduates -------------------------------------------------------

  output$fig_1 <- renderPlot({

    picked <- colleges |>
      filter(college == input$pick)

    ggplot(
      colleges,
      aes(x = math_per_100, y = fct_reorder(college, math_per_100), fill = college == input$pick)
    ) +
      geom_col() +
      geom_vline(xintercept = median_math, linetype = "dashed") +
      # the rate and the count, lined up on the right so the dashed line does not cross them
      geom_text(
        aes(
          x = 4.4,
          label = paste0(format(math_per_100, nsmall = 1), " (", math_degrees, " of ",
                         scales::comma(all_degrees), ")")
        ),
        hjust = 1,
        size = 4.5
      ) +
      scale_fill_manual(values = pick_colours) +
      scale_x_continuous(limits = c(0, 4.4), breaks = 0:3, expand = expansion(mult = c(0, 0.02))) +
      labs(
        title = paste0(input$pick, ": ", format(picked$math_per_100, nsmall = 1),
                       " of every 100 graduates majored in math"),
        subtitle = paste0("Each bar is one college. Dashed line: the median college (",
                          format(median_math, nsmall = 1), ")."),
        x = "Math and statistics majors per 100 bachelor's degrees, July 2022 to June 2025",
        y = NULL,
        caption = "Source: NCES, IPEDS Completions, July 2022 to June 2025",
        alt = paste0(
          "Bar chart with one bar for each of 13 New Jersey public colleges, sorted from the ",
          "most math majors per 100 graduates at the top to the fewest at the bottom. ",
          input$pick, " is highlighted at ", format(picked$math_per_100, nsmall = 1),
          " per 100. The median college is ", format(median_math, nsmall = 1),
          " per 100. The highest is TCNJ at 2.9 and the lowest is Rutgers-Camden at 0.4."
        )
      ) +
      theme_minimal(base_size = 15) +
      theme(
        legend.position = "none",
        plot.title.position = "plot",
        panel.grid.major.y = element_blank()     # no lines running through the numbers
      )

  })

  output$text_1 <- renderText({

    picked <- colleges |>
      filter(college == input$pick)

    paste0(
      "At ", input$pick, ", ", picked$math_degrees, " of the ", scales::comma(picked$all_degrees),
      " bachelor's degrees awarded from July 2022 to June 2025 were in math or statistics (",
      picked$math_2023, ", then ", picked$math_2024, ", then ", picked$math_2025,
      " by year). That is ", format(picked$math_per_100, nsmall = 1),
      " of every 100 graduates. The median college had ", format(median_math, nsmall = 1), "."
    )

  })


  # Figure 2: net price, for the income group the reader picks -----------------------------------

  output$fig_2 <- renderPlot({

    # keep one income group
    plot_data <- net_price |>
      filter(income == input$income)

    picked <- plot_data |>
      filter(college == input$pick)

    median_price <- median(plot_data$net_price)

    ggplot(
      plot_data,
      aes(x = net_price, y = fct_reorder(college, net_price), fill = college == input$pick)
    ) +
      geom_col() +
      geom_vline(xintercept = median_price, linetype = "dashed") +
      geom_text(aes(x = 42000, label = scales::dollar(net_price)), hjust = 1, size = 4.5) +
      scale_fill_manual(values = pick_colours) +
      scale_x_continuous(
        labels = scales::dollar,
        limits = c(0, 42000),                   # the same axis for every income group
        breaks = c(0, 10000, 20000, 30000),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(
        title = paste0(input$pick, ": about ", scales::dollar(picked$net_price), " for one year"),
        subtitle = paste0("Family income: ", input$income, ". Dashed line: the median college (",
                          scales::dollar(median_price), ")."),
        x = "Average net price for one year, 2024-25",
        y = NULL,
        caption = "Source: U.S. Department of Education, College Scorecard, academic year 2024-25",
        alt = paste0(
          "Bar chart with one bar for each of 13 New Jersey public colleges, sorted from the ",
          "highest average net price at the top to the lowest at the bottom, for family income ",
          input$income, ". ", input$pick, " is highlighted at ", scales::dollar(picked$net_price),
          ". The median college is ", scales::dollar(median_price), "."
        )
      ) +
      theme_minimal(base_size = 15) +
      theme(
        legend.position = "none",
        plot.title.position = "plot",
        panel.grid.major.y = element_blank()     # no lines running through the numbers
      )

  })

  output$text_2 <- renderText({

    plot_data <- net_price |>
      filter(income == input$income)

    picked <- plot_data |>
      filter(college == input$pick)

    income_words <- if_else(
      input$income == "Any income (average)",
      "across all family incomes",
      paste("for families with an income of", input$income)
    )

    paste0(
      "At ", input$pick, ", the average net price in 2024-25 ", income_words, " was ",
      scales::dollar(picked$net_price), " (", scales::comma(picked$students),
      " students). The median college was ", scales::dollar(median(plot_data$net_price)), "."
    )

  })


  # Figure 3: SAT math, against the reader's own score --------------------------------------------

  output$fig_3 <- renderPlot({

    picked <- colleges |>
      filter(college == input$pick)

    # only the colleges that reported a range, in order of their median. The label also says
    # how many of every 100 new students sent a score.
    sat_data <- colleges |>
      filter(!is.na(sat_math_25)) |>
      mutate(
        label = paste0(college, " (", sat_sent_per_100, " in 100 sent a score)"),
        label = fct_reorder(label, sat_math_50)
      )

    where <- case_when(
      input$score < picked$sat_math_25 ~ "below",
      input$score > picked$sat_math_75 ~ "above",
      TRUE ~ "inside"
    )

    fig_3_title <- if_else(
      is.na(picked$sat_math_25),
      paste(input$pick, "reported no SAT math range. Nine colleges did."),
      paste0("Your ", input$score, " is ", where, " ", input$pick, "'s middle half (",
             picked$sat_math_25, " to ", picked$sat_math_75, ")")
    )

    ggplot(sat_data, aes(y = label, colour = college == input$pick)) +
      geom_segment(
        aes(x = sat_math_25, xend = sat_math_75, yend = label),
        linewidth = 4
      ) +
      geom_point(aes(x = sat_math_50), colour = "black", size = 3) +
      geom_vline(xintercept = input$score, linetype = "dashed") +
      scale_colour_manual(values = pick_colours) +
      scale_x_continuous(limits = c(200, 800), breaks = seq(200, 800, 100)) +
      labs(
        title = fig_3_title,
        subtitle = paste0("Each line is one college's middle half. Dashed line: your score (",
                          input$score, ")."),
        x = "SAT math score of students who started in fall 2024 (scale: 200 to 800)",
        y = NULL,
        caption = "Source: NCES, IPEDS Admissions, fall 2024",
        alt = paste0(
          "Chart with one horizontal line for each of 9 New Jersey public colleges, running from ",
          "the 25th to the 75th percentile SAT math score of new students, with a dot at the ",
          "median. The colleges are sorted from the highest median at the top (Rutgers-New ",
          "Brunswick, 660 to 770) to the lowest at the bottom (Kean, 470 to 585). ",
          "A dashed vertical line marks the reader's score of ", input$score, "."
        )
      ) +
      theme_minimal(base_size = 15) +
      theme(
        legend.position = "none",
        plot.title.position = "plot",
        panel.grid.major.y = element_blank()     # no lines running through the numbers
      )

  })

  output$text_3 <- renderText({

    picked <- colleges |>
      filter(college == input$pick)

    where <- case_when(
      input$score < picked$sat_math_25 ~ "below",
      input$score > picked$sat_math_75 ~ "above",
      TRUE ~ "inside"
    )

    # one sentence if the college reported a range, another if it did not
    range_sentence <- if_else(
      is.na(picked$sat_math_25),
      paste(input$pick, "did not report an SAT math range for fall 2024."),
      paste0("At ", input$pick, ", the middle half of the new students who sent a score had ",
             picked$sat_math_25, " to ", picked$sat_math_75, " in math. Your score of ",
             input$score, " is ", where, " that range.")
    )

    paste0(
      range_sentence, " ", input$pick, " admitted ", picked$admit_per_100,
      " of every 100 applicants (the median college admitted ", median_admit, ")."
    )

  })


  # Figure 4: what math graduates earn, against the national median ------------------------------

  output$fig_4 <- renderPlot({

    picked <- colleges |>
      filter(college == input$pick)

    # one bar per earnings number (the three Rutgers campuses share one)
    earn_data <- colleges |>
      filter(!is.na(earn_4yr)) |>
      distinct(earn_name, earn_4yr, earn_n)

    ggplot(
      earn_data,
      aes(x = earn_4yr, y = fct_reorder(earn_name, earn_4yr), fill = earn_name == picked$earn_name)
    ) +
      geom_col() +
      geom_vline(xintercept = national_earn, linetype = "dashed") +
      geom_text(aes(x = 118000, label = scales::dollar(earn_4yr)), hjust = 1, size = 4.5) +
      scale_fill_manual(values = pick_colours) +
      scale_x_continuous(
        labels = scales::dollar,
        limits = c(0, 118000),
        breaks = c(0, 25000, 50000, 75000, 100000),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(
        title = "Math graduates of NJIT, TCNJ, and Rutgers earned the most",
        subtitle = paste0("Each bar is one college's math graduates. Dashed line: math graduates ",
                          "nationwide (", scales::dollar(national_earn), ")."),
        x = "Median yearly earnings, four years after a math degree (2024 dollars)",
        y = NULL,
        caption = paste("Source: U.S. Department of Education, College Scorecard.",
                        "Graduates of 2017-18 and 2018-19, earnings in 2022 and 2023"),
        alt = paste0(
          "Bar chart with 9 bars, one for each New Jersey public college (Rutgers's three ",
          "campuses share one bar), sorted from the highest median earnings of mathematics ",
          "graduates at the top (NJIT, $94,840) to the lowest at the bottom (Kean Jersey City, ",
          "$58,323). The national median for mathematics graduates is ",
          scales::dollar(national_earn), ". The bar that includes ", input$pick, " is highlighted, ",
          "if it has one."
        )
      ) +
      theme_minimal(base_size = 15) +
      theme(
        legend.position = "none",
        plot.title.position = "plot",
        panel.grid.major.y = element_blank()     # no lines running through the numbers
      )

  })

  output$text_4 <- renderText({

    picked <- colleges |>
      filter(college == input$pick)

    # one sentence if the college has a number, another if it does not
    if_else(
      is.na(picked$earn_4yr),
      paste0("There is no earnings number for ", input$pick, " (", picked$earn_note, ")."),
      paste0("For ", picked$earn_name, ", the median was ", scales::dollar(picked$earn_4yr), " (",
             picked$earn_n, " graduates). The national median for math graduates was ",
             scales::dollar(national_earn), ".")
    )

  })


  # Figure 5: the map ----------------------------------------------------------------------------

  output$fig_5 <- renderPlot({

    picked <- colleges |>
      filter(college == input$pick)

    ggplot() +
      geom_sf(data = nj_counties, fill = "grey95", colour = "grey60") +
      geom_point(data = colleges, aes(x = lon, y = lat), colour = "grey40", size = 3) +
      geom_point(data = picked, aes(x = lon, y = lat), colour = "steelblue", size = 6) +
      geom_text(
        data = picked,
        aes(x = lon, y = lat, label = college),
        hjust = 0,                           # the label starts to the right of the dot,
        nudge_x = 0.07,                      # where there are fewer dots to cover
        size = 5.5,
        fontface = "bold"
      ) +
      coord_sf(clip = "off") +             # the label may run past the edge of the map
      labs(
        title = paste0(input$pick, " is in ", picked$city),
        subtitle = "Each dot is one of the 13 colleges. The lines are New Jersey's 21 counties.",
        caption = "Sources: NCES, IPEDS Directory Information, 2025-26; U.S. Census Bureau, 2022",
        alt = paste0(
          "Map of New Jersey's 21 counties with a dot for each of the 13 public four-year colleges. ",
          "Eight of the dots are in the northeast of the state. ", input$pick,
          " is highlighted, in ", picked$city, "."
        )
      ) +
      theme_void(base_size = 15) +
      theme(
        plot.title = element_text(hjust = 0.5),      # centered over the map
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(hjust = 0.5)
      )

  })

  output$text_5 <- renderText({

    picked <- colleges |>
      filter(college == input$pick)

    paste0(
      input$pick, " is in ", picked$city, ". Find your own town on the map to judge how far ",
      "away it is, and whether you would live at home or on campus."
    )

  })

}

shinyApp(ui = ui, server = server)
