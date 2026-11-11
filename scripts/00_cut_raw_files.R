# scripts/00_cut_raw_files.R
# Cuts the seven official downloads down to the seven small files in data/raw/.
#
# NOTE: You do NOT need to run this. Everything it writes is already in data/raw/. Run it only to
# start over from the official files. Two of them are over GitHub's 100 MB limit, so the full
# downloads are not in the repository. The README has the link for each one. Unzip them into
# data/raw/full/ first (that folder is in .gitignore).
#
#   In (data/raw/full/)                            Out (data/raw/)
#   hd2025.csv                                     hd2025_nj.csv
#   c2023_a_RV.csv   (the revised file in the zip) c2023_a_nj.csv
#   c2024_a_rv.csv   (the revised file in the zip) c2024_a_nj.csv
#   c2025_a.csv                                    c2025_a_nj.csv
#   adm2024.csv                                    adm2024_nj.csv
#   Most-Recent-Cohorts-Institution.csv            scorecard_institution_nj.csv
#   Most-Recent-Cohorts-Field-of-Study.csv         scorecard_field_of_study_nj.csv
#
# The cut keeps rows and columns and changes no values. Every column is read as text, and
# na = character() tells R not to turn anything into NA, so "PS", "NA", and blanks are written
# back out exactly as they came in.


# Packages ---------------------------------------------------------------------------------------

library(tidyverse)


# IPEDS: The Colleges (HD2025) -------------------------------------------------------------------

hd_full <- read_csv(
  "data/raw/full/hd2025.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

# New Jersey's public four-year colleges (SECTOR 1 = public, four-year or above)
hd_nj <- hd_full |>
  filter(STABBR == "NJ") |>
  filter(SECTOR == "1") |>
  select(UNITID, INSTNM, CITY, STABBR, SECTOR, COUNTYNM, LONGITUD, LATITUDE)

# Expect 14 rows and 8 columns
dim(hd_nj)

write_csv(hd_nj, "data/raw/hd2025_nj.csv")

# The 14 codes. Every other file is cut down to these colleges.
nj_ids <- hd_nj$UNITID


# IPEDS: Completions (C2023_A, C2024_A, C2025_A) -------------------------------------------------

# Keep bachelor's degrees (AWLEVEL 5) in mathematics and statistics (CIPCODE starts with 27) and
# the row for every field added together (CIPCODE 99)
c2023_full <- read_csv(
  "data/raw/full/c2023_a_RV.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

c2023_nj <- c2023_full |>
  filter(UNITID %in% nj_ids) |>
  filter(AWLEVEL == "5") |>
  filter(CIPCODE == "99" | str_detect(CIPCODE, "^27")) |>
  select(UNITID, CIPCODE, MAJORNUM, AWLEVEL, CTOTALT)

c2024_full <- read_csv(
  "data/raw/full/c2024_a_rv.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

c2024_nj <- c2024_full |>
  filter(UNITID %in% nj_ids) |>
  filter(AWLEVEL == "5") |>
  filter(CIPCODE == "99" | str_detect(CIPCODE, "^27")) |>
  select(UNITID, CIPCODE, MAJORNUM, AWLEVEL, CTOTALT)

c2025_full <- read_csv(
  "data/raw/full/c2025_a.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

c2025_nj <- c2025_full |>
  filter(UNITID %in% nj_ids) |>
  filter(AWLEVEL == "5") |>
  filter(CIPCODE == "99" | str_detect(CIPCODE, "^27")) |>
  select(UNITID, CIPCODE, MAJORNUM, AWLEVEL, CTOTALT)

# Expect 34, 36, and 35 rows, and 5 columns each
dim(c2023_nj)
dim(c2024_nj)
dim(c2025_nj)

write_csv(c2023_nj, "data/raw/c2023_a_nj.csv")

write_csv(c2024_nj, "data/raw/c2024_a_nj.csv")

write_csv(c2025_nj, "data/raw/c2025_a_nj.csv")


# IPEDS: Admissions (ADM2024) --------------------------------------------------------------------

adm_full <- read_csv(
  "data/raw/full/adm2024.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

adm_nj <- adm_full |>
  filter(UNITID %in% nj_ids) |>
  select(UNITID, APPLCN, ADMSSN, ENRLT, SATNUM, SATPCT, SATMT25, SATMT50, SATMT75)

# Expect 13 rows and 9 columns (Thomas Edison State University has no admissions row)
dim(adm_nj)

write_csv(adm_nj, "data/raw/adm2024_nj.csv")


# College Scorecard: Institution-Level File (Net Price) ------------------------------------------

# This file is about 100 MB and has 3,379 columns, so it takes a minute to read
scorecard_full <- read_csv(
  "data/raw/full/Most-Recent-Cohorts-Institution.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

scorecard_nj <- scorecard_full |>
  filter(UNITID %in% nj_ids) |>
  select(UNITID, OPEID6, INSTNM, STABBR, CONTROL,
         NPT4_PUB, NPT41_PUB, NPT42_PUB, NPT43_PUB, NPT44_PUB, NPT45_PUB,
         NUM4_PUB, NUM41_PUB, NUM42_PUB, NUM43_PUB, NUM44_PUB, NUM45_PUB)

# Expect 14 rows and 17 columns
dim(scorecard_nj)

write_csv(scorecard_nj, "data/raw/scorecard_institution_nj.csv")


# College Scorecard: Field of Study File (Earnings) ----------------------------------------------

# This file is about 200 MB
fos_full <- read_csv(
  "data/raw/full/Most-Recent-Cohorts-Field-of-Study.csv",
  col_types = cols(.default = col_character()),
  na = character()
)

# Keep bachelor's degrees (CREDLEV 3) in mathematics and statistics (CIPCODE starts with 27)
fos_nj <- fos_full |>
  filter(UNITID %in% nj_ids) |>
  filter(CREDLEV == "3") |>
  filter(str_detect(CIPCODE, "^27")) |>
  select(UNITID, OPEID6, INSTNM, MAIN, CIPCODE, CIPDESC, CREDLEV, CREDDESC,
         EARN_COUNT_WNE_4YR, EARN_MDN_4YR, EARN_COUNT_WNE_4YR_NAT, EARN_MDN_4YR_NAT)

# Expect 19 rows and 12 columns
dim(fos_nj)

write_csv(fos_nj, "data/raw/scorecard_field_of_study_nj.csv")
