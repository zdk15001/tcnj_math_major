# scripts/01_import.R
# Reads the seven raw files in data/raw/ and writes five clean tables in data/.
#
#   Source 1: National Center for Education Statistics (NCES), IPEDS Complete Data Files
#             https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx
#
#             Directory information, 2025-26 (HD2025)
#               In:  data/raw/hd2025_nj.csv
#               Out: data/colleges.csv
#
#             Completions (degrees awarded), July 2022 to June 2025 (C2023_A, C2024_A, C2025_A)
#               In:  data/raw/c2023_a_nj.csv, data/raw/c2024_a_nj.csv, data/raw/c2025_a_nj.csv
#               Out: data/math_degrees.csv
#
#             Admissions and test scores, fall 2024 (ADM2024)
#               In:  data/raw/adm2024_nj.csv
#               Out: data/admissions.csv
#
#   Source 2: U.S. Department of Education, College Scorecard
#             https://collegescorecard.ed.gov/data/
#
#             Most Recent Institution-Level Data (the file dated November 2, 2026):
#             average net price, academic year 2024-25
#               In:  data/raw/scorecard_institution_nj.csv
#               Out: data/net_price.csv
#
#             Most Recent Data by Field of Study (the file dated October 15, 2026):
#             earnings of 2017-18 and 2018-19 graduates, measured in 2022 and 2023, in 2024 dollars
#               In:  data/raw/scorecard_field_of_study_nj.csv
#               Out: data/math_earnings.csv
#
#   Source 3: U.S. Census Bureau, cartographic boundary files, 2022 (the 21 counties)
#             https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
#             Copied from the class repository (STA220/3.3/data/boundaries/nj_counties.gpkg).
#             It is not changed here. 02_build_dashboard_data.R copies it into app/data/.
#
# NOTE: the files in data/raw/ are the official downloads cut down to New Jersey's public
# four-year colleges and the columns used here. The README and 00_cut_raw_files.R say exactly
# how they were cut.


# Packages ---------------------------------------------------------------------------------------

library(tidyverse)


# Source 1: The Colleges (IPEDS Directory, 2025-26) ----------------------------------------------

hd_raw <- read_csv(
  "data/raw/hd2025_nj.csv",
  col_types = cols(.default = col_character())     # every column as text!
)

# One row is one college. Expect 14 rows and 8 columns.
dim(hd_raw)
names(hd_raw)
summary(hd_raw)

# The names a high school junior would use, typed by hand. The key is UNITID, IPEDS's code.
# NOTE: New Jersey City University (185129) became Kean Jersey City on July 1, 2026. Every number
# for it in this project is from before the merger.
short_names <- tribble(
  ~unitid,   ~college,
  "183822",  "Bloomfield College",
  "184782",  "Rowan",
  "185129",  "Kean Jersey City (was NJCU)",
  "185262",  "Kean",
  "185590",  "Montclair State",
  "185828",  "NJIT",
  "186201",  "Ramapo",
  "186371",  "Rutgers-Camden",
  "186380",  "Rutgers-New Brunswick",
  "186399",  "Rutgers-Newark",
  "186876",  "Stockton",
  "187134",  "TCNJ",
  "187444",  "William Paterson"
)

# NOTE: Thomas Edison State University (187046) is left out. It is built for adults, and it
# enrolled no first-time freshmen, so IPEDS has no admissions row and the Scorecard has no net
# price for it. A high school junior cannot use it the way they would use the other 13.
colleges <- hd_raw |>
  filter(SECTOR == "1") |>                 # 1 = public, four-year or above
  filter(UNITID != "187046") |>            # Thomas Edison State University
  mutate(
    unitid = UNITID,
    full_name = INSTNM,
    city = CITY,
    lon = as.numeric(LONGITUD),
    lat = as.numeric(LATITUDE)
  ) |>
  left_join(short_names, by = "unitid") |>
  select(unitid, college, full_name, city, lon, lat) |>
  arrange(college)

# Expect 13 rows, 6 columns, and no NAs (every college found its short name)
dim(colleges)
names(colleges)
summary(colleges)

# key checks: 0 rows each
colleges |>
  count(unitid) |>
  filter(n > 1)

colleges |>
  count(college) |>
  filter(n > 1)

write_csv(colleges, "data/colleges.csv")


# Source 1: Math Degrees (IPEDS Completions, July 2022 to June 2025) -----------------------------

# NOTE: the 2023 and 2024 files are the revised ("_rv") files inside each zip. The 2025 file is
# the provisional release (there is no revised file yet).
c2023 <- read_csv(
  "data/raw/c2023_a_nj.csv",
  col_types = cols(.default = col_character())     # CIPCODE is a code: "27.0101", "03.0103"
)

c2024 <- read_csv(
  "data/raw/c2024_a_nj.csv",
  col_types = cols(.default = col_character())
)

c2025 <- read_csv(
  "data/raw/c2025_a_nj.csv",
  col_types = cols(.default = col_character())
)

# One row is one college, one field (CIPCODE), and one major number. Expect 34, 36, and 35 rows,
# and 5 columns each.
dim(c2023)
dim(c2024)
dim(c2025)
names(c2025)
summary(c2025)

# Stack the three years. grad_year is the year the graduating class finished.
completions <- bind_rows(
  mutate(c2023, grad_year = "2023"),
  mutate(c2024, grad_year = "2024"),
  mutate(c2025, grad_year = "2025")
) |>
  mutate(
    unitid = UNITID,
    degrees = as.numeric(CTOTALT)          # CTOTALT is the grand total (all students)
  ) |>
  filter(AWLEVEL == "5") |>                # 5 = bachelor's degree
  filter(MAJORNUM == "1")                  # first majors only (see the NOTE below)

# NOTE: MAJORNUM 2 is a second major. Only Kean, Stockton, and William Paterson report any, so
# counting them would not be a fair comparison. They are dropped (12 rows, 9 math second majors).

# Expect 93 rows and 8 columns (105 rows in the three files, minus the 12 second-major rows)
dim(completions)
names(completions)
summary(completions)

# CIPCODE 99 is IPEDS's row for every field added together
all_degrees <- completions |>
  filter(CIPCODE == "99") |>
  group_by(unitid) |>
  summarize(all_degrees = sum(degrees))

# CIPCODEs that start with 27 are mathematics and statistics. In these files: 27.0101
# (mathematics), 27.0301 (applied mathematics), and 27.0501 (statistics).
math_by_year <- completions |>
  filter(str_detect(CIPCODE, "^27")) |>
  group_by(unitid, grad_year) |>
  summarize(math = sum(degrees), .groups = "drop") |>
  pivot_wider(
    names_from = grad_year,
    values_from = math,
    names_prefix = "math_",
    values_fill = 0                        # no row that year means no math degrees that year
  )

# Before the merge, what I expect:
# 1) Rows: 14 in and 14 out (Thomas Edison is still here; it drops out in 02).
# 2) Columns: 4 + 2 - 1 = 5, then 2 new ones.
anti_join(math_by_year, all_degrees, by = "unitid")   # expect 0 rows

anti_join(all_degrees, math_by_year, by = "unitid")   # expect 0 rows

# The three years are added together because the yearly counts are small and bounce around
# (TCNJ: 57, then 54, then 34).
math_degrees <- math_by_year |>
  left_join(all_degrees, by = "unitid") |>
  mutate(
    math_degrees = math_2023 + math_2024 + math_2025,
    math_per_100 = round(math_degrees / all_degrees * 100, 1)
  )

# Expect 14 rows, 7 columns, and no NAs
dim(math_degrees)
names(math_degrees)
summary(math_degrees)

write_csv(math_degrees, "data/math_degrees.csv")


# Source 1: Admissions and SAT Math (IPEDS Admissions, Fall 2024) --------------------------------

adm_raw <- read_csv(
  "data/raw/adm2024_nj.csv",
  col_types = cols(UNITID = col_character())
)

# One row is one college. Expect 13 rows and 9 columns (Thomas Edison has no row).
# The three SAT math columns are blank for four colleges, so expect 4 NAs in each.
dim(adm_raw)
names(adm_raw)
summary(adm_raw)

admissions <- adm_raw |>
  mutate(
    unitid = UNITID,
    applicants = APPLCN,
    admitted = ADMSSN,
    admit_per_100 = round(ADMSSN / APPLCN * 100),
    sat_sent_per_100 = SATPCT,             # percent of new students who sent SAT scores
    sat_math_25 = SATMT25,                 # a quarter of them scored below this
    sat_math_50 = SATMT50,                 # the median
    sat_math_75 = SATMT75                  # a quarter of them scored above this
  ) |>
  select(unitid, applicants, admitted, admit_per_100, sat_sent_per_100,
         sat_math_25, sat_math_50, sat_math_75)

# Expect 13 rows and 8 columns
dim(admissions)
names(admissions)
summary(admissions)

write_csv(admissions, "data/admissions.csv")


# Source 2: Net Price (College Scorecard, 2024-25) -----------------------------------------------

scorecard_raw <- read_csv(
  "data/raw/scorecard_institution_nj.csv",
  col_types = cols(
    UNITID = col_character(),
    OPEID6 = col_character()               # keep the code as text: "002617", not 2617
  )
)

# One row is one college. Expect 14 rows and 17 columns. Thomas Edison's row is all NA.
dim(scorecard_raw)
names(scorecard_raw)
summary(scorecard_raw)

# The Scorecard's column names, and the words for a reader
income_groups <- tribble(
  ~column,      ~income,
  "NPT4_PUB",   "Any income (average)",
  "NPT41_PUB",  "$0 to $30,000",
  "NPT42_PUB",  "$30,001 to $48,000",
  "NPT43_PUB",  "$48,001 to $75,000",
  "NPT44_PUB",  "$75,001 to $110,000",
  "NPT45_PUB",  "$110,001 or more"
)

# One row per college per income group: the net price, then the number of students behind it
price_long <- scorecard_raw |>
  select(UNITID, NPT4_PUB, NPT41_PUB, NPT42_PUB, NPT43_PUB, NPT44_PUB, NPT45_PUB) |>
  pivot_longer(-UNITID, names_to = "column", values_to = "net_price")

count_long <- scorecard_raw |>
  select(UNITID, NUM4_PUB, NUM41_PUB, NUM42_PUB, NUM43_PUB, NUM44_PUB, NUM45_PUB) |>
  pivot_longer(-UNITID, names_to = "column", values_to = "students") |>
  mutate(column = str_replace(column, "NUM", "NPT"))     # so both tables have the same key

# Expect 84 rows each (14 colleges x 6 income groups)
dim(price_long)
dim(count_long)

anti_join(price_long, count_long, by = c("UNITID", "column"))   # expect 0 rows

net_price <- price_long |>
  left_join(count_long, by = c("UNITID", "column")) |>
  left_join(income_groups, by = "column") |>
  mutate(unitid = UNITID) |>
  select(unitid, income, net_price, students)

# Expect 84 rows, 4 columns, and 6 NAs in net_price and students (Thomas Edison)
dim(net_price)
names(net_price)
summary(net_price)

write_csv(net_price, "data/net_price.csv")


# Source 2: What Math Graduates Earn (College Scorecard, Field of Study) -------------------------

fos_raw <- read_csv(
  "data/raw/scorecard_field_of_study_nj.csv",
  col_types = cols(.default = col_character())     # "PS" (privacy suppressed) is in the numbers
)

# One row is one college, one field (a four-digit CIPCODE), and one degree level. Expect 19 rows
# and 12 columns.
dim(fos_raw)
names(fos_raw)
summary(fos_raw)

# NOTE: the Scorecard reports earnings for each four-digit field separately, and medians cannot
# be added together. So this uses 2701 (Mathematics) only. Applied mathematics (2703) and
# statistics (2705) are left out, which is narrower than the degree counts above.
math_earnings <- fos_raw |>
  filter(CIPCODE == "2701") |>             # Mathematics
  filter(CREDLEV == "3") |>                # 3 = bachelor's degree
  mutate(
    unitid = UNITID,
    opeid6 = OPEID6,
    earn_note = if_else(EARN_MDN_4YR == "PS", "hidden for privacy", "reported"),
    earn_4yr = parse_number(EARN_MDN_4YR, na = "PS"),            # median earnings, 4 years out
    earn_n = parse_number(EARN_COUNT_WNE_4YR, na = "PS"),        # the graduates behind it
    earn_national = parse_number(EARN_MDN_4YR_NAT, na = "PS")    # the same median for the nation
  ) |>
  select(unitid, opeid6, earn_note, earn_4yr, earn_n, earn_national)

# Expect 12 rows and 6 columns (Bloomfield and Thomas Edison have no Mathematics row), with
# 1 NA in earn_4yr and earn_n (Ramapo, hidden for privacy)
dim(math_earnings)
names(math_earnings)
summary(math_earnings)

# NOTE: the three Rutgers campuses share one OPEID6 (002629), and the Scorecard gives all three
# the same earnings (81,845 for 142 graduates). It is one number for Rutgers, not three.
math_earnings |>
  filter(opeid6 == "002629")

write_csv(math_earnings, "data/math_earnings.csv")
