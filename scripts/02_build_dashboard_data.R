# scripts/02_build_dashboard_data.R
# Joins the clean tables in data/ (made by 01_import.R) into the three files the app reads.
#
#   In:  data/colleges.csv, data/math_degrees.csv, data/admissions.csv, data/math_earnings.csv,
#        data/net_price.csv, data/boundaries/nj_counties.gpkg
#   Out: app/data/colleges.csv       one row per college (13 rows)
#        app/data/net_price.csv      one row per college per income group (78 rows)
#        app/data/nj_counties.gpkg   the 21 counties, for the map
#
# The app lives in app/, so everything it reads has to be in app/data/.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)
library(sf)

colleges <- read_csv(
  "data/colleges.csv",
  col_types = cols(unitid = col_character())   # keep the code as text
)

# One row is one college. Expect 13 rows and 6 columns.
dim(colleges)
names(colleges)
summary(colleges)

math_degrees <- read_csv(
  "data/math_degrees.csv",
  col_types = cols(unitid = col_character())
)

# One row is one college. Expect 14 rows and 7 columns.
dim(math_degrees)
names(math_degrees)
summary(math_degrees)

admissions <- read_csv(
  "data/admissions.csv",
  col_types = cols(unitid = col_character())
)

# One row is one college. Expect 13 rows and 8 columns.
dim(admissions)
names(admissions)
summary(admissions)

math_earnings <- read_csv(
  "data/math_earnings.csv",
  col_types = cols(
    unitid = col_character(),
    opeid6 = col_character()
  )
)

# One row is one college. Expect 12 rows and 6 columns.
dim(math_earnings)
names(math_earnings)
summary(math_earnings)

net_price <- read_csv(
  "data/net_price.csv",
  col_types = cols(unitid = col_character())
)

# One row is one college and one income group. Expect 84 rows and 4 columns.
dim(net_price)
names(net_price)
summary(net_price)

nj_counties <- read_sf("data/boundaries/nj_counties.gpkg")

# One row is one county. Expect 21 rows and 13 columns.
dim(nj_counties)
names(nj_counties)


# Can These Be Merged? ---------------------------------------------------------------------------

# Unit:     one row is one college in colleges, math_degrees, admissions, and math_earnings.
#           net_price is one row per college per income group, so it stays its own table.
# Time:     the years differ by source (degrees 2022 to 2025, admissions fall 2024, net price
#           2024-25, earnings measured in 2022 and 2023). They are not mixed into one number, and
#           the dashboard prints the year with each figure.
# Key:      unitid, IPEDS's six-digit code for a college. The Scorecard uses the same code.
# Format:   text in every table.
# Coverage: colleges has the 13 colleges in the dashboard. The anti-joins below show who is
#           missing from each table.

# Before the merge, what I expect:
# 1) Rows: colleges is the left table, so 13 rows in and 13 rows out.
# 2) Columns: 6 + 6 + 7 + 5 = 24 (the key is counted once), then 1 new one.
# 3) Drops: Thomas Edison is in math_degrees but not in colleges (left out on purpose).
#    Bloomfield College has no Mathematics row in the Scorecard, so its earnings will be NA.
anti_join(colleges, math_degrees, by = "unitid")    # expect 0 rows

anti_join(colleges, admissions, by = "unitid")      # expect 0 rows

anti_join(colleges, math_earnings, by = "unitid")   # expect 1 row: Bloomfield College

anti_join(math_degrees, colleges, by = "unitid")    # expect 1 row: 187046 (Thomas Edison)


# The Merge --------------------------------------------------------------------------------------

# Say: "Start with colleges, add the columns of math_degrees, then admissions, then
# math_earnings, matching rows by unitid, and save it as dashboard."
dashboard <- colleges |>
  left_join(math_degrees, by = "unitid") |>
  left_join(admissions, by = "unitid") |>
  left_join(math_earnings, by = "unitid") |>
  mutate(
    earn_note = if_else(is.na(earn_note), "no Mathematics row", earn_note),
    # The three Rutgers campuses share one earnings number, so they share one name in Figure 4
    earn_name = if_else(str_detect(college, "Rutgers"), "Rutgers (all 3 campuses)", college)
  )

# Three checks after the merge: expect 13 rows and 25 columns
dim(dashboard)
names(dashboard)
summary(dashboard)

# key check: 0 rows
dashboard |>
  count(unitid) |>
  filter(n > 1)

# What is still missing after the merge, and why:
#   SAT math: 4 colleges reported no range (Bloomfield College, Kean Jersey City, Rutgers-Newark,
#             William Paterson)
#   Earnings: 2 colleges (Ramapo: hidden for privacy; Bloomfield College: no Mathematics row)
dashboard |>
  filter(is.na(sat_math_25)) |>
  select(college, sat_sent_per_100, sat_math_25)

dashboard |>
  filter(is.na(earn_4yr)) |>
  select(college, earn_note, earn_4yr)

write_csv(dashboard, "app/data/colleges.csv")


# Net Price, With the College Names --------------------------------------------------------------

# colleges is the left table, so Thomas Edison's 6 rows drop out.
# Expect 78 rows (13 colleges x 6 income groups), 5 columns, and no NAs.
net_price_app <- colleges |>
  select(unitid, college) |>
  left_join(net_price, by = "unitid")

dim(net_price_app)
names(net_price_app)
summary(net_price_app)

write_csv(net_price_app, "app/data/net_price.csv")


# The Counties, for the Map ----------------------------------------------------------------------

st_write(nj_counties, "app/data/nj_counties.gpkg", delete_dsn = TRUE, quiet = TRUE)


# The Benchmarks ---------------------------------------------------------------------------------

# The benchmark is the median college: half of the 13 are above it and half are below. Each
# college counts once, because the reader is choosing among colleges. (The app computes these
# again; they are printed here so they can be checked.)
median(dashboard$math_per_100)       # 1.1 math majors per 100 graduates

median(dashboard$admit_per_100)      # 71 admitted per 100 applicants

net_price_app |>
  group_by(income) |>
  summarize(median_net_price = median(net_price))

# For earnings, the benchmark is the national median for Mathematics bachelor's graduates,
# which comes with the Scorecard file
max(dashboard$earn_national, na.rm = TRUE)   # 69,562


# The Longest Bars -------------------------------------------------------------------------------

# The bar charts in the app have fixed axes (4.4, 42,000, and 118,000). A bar longer than its
# axis would not be drawn, so check these three if the data ever change.
max(dashboard$math_per_100)                  # 2.9

max(net_price_app$net_price)                 # 34,232

max(dashboard$earn_4yr, na.rm = TRUE)        # 94,840
