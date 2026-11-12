# This dashboard was created entirely using Claude's 5.2 Fable on 11/11/2026. There are many errors!
# Which New Jersey public college should a future math major pick?

A decision dashboard for the STA 220 final project.
Data for Everyday Life: Data Ethics, Management, and Visualization.
The College of New Jersey.

- **Audience:** a New Jersey high school junior who wants to major in math, and the family
  helping with the decision.
- **Decision:** which of New Jersey's 13 public four-year colleges to put at the top of the list.
- **Place:** the project prompt asks for a town. This dashboard compares New Jersey's public
  four-year colleges instead.
- **Dashboard link:** not published yet. Publish the `app` folder (see below), then paste the
  link here.
- **Built on:** November 11, 2026, with Claude (an AI tool). The research log in `docs/` has the
  record of the chat and every coding decision.


## Steps to run everything

1. Clone or download this repository and open `math_college_dashboard.Rproj` in RStudio.
2. Install the packages once: `install.packages(c("tidyverse", "sf", "shiny"))`
3. Restart R (Session > Restart R), then run `source("scripts/master.R")`.
   It rebuilds the tables in `data/` and the three files in `app/data/` from `data/raw/`.
4. Open `app/app.R` and click **Run App**.

Steps 3 and 4 do not need the internet.

To publish: open `app/app.R` in RStudio and click the Publish button (shinyapps.io). Posit
Connect Cloud publishes from a public GitHub repository instead, and it needs a `manifest.json`
next to `app.R` (make one with `rsconnect::writeManifest("app")`). Both are free. Check each
site's own instructions when you publish.


## What is in the repository

```
math_college_dashboard/
  math_college_dashboard.Rproj
  README.md
  app/
    app.R                          the dashboard
    data/                          the three files the app reads (made by 02)
  scripts/
    00_cut_raw_files.R             how data/raw/ was cut from the official files (you do not need to run it)
    01_import.R                    data/raw/ into clean tables in data/
    02_build_dashboard_data.R      the clean tables joined into app/data/
    master.R                       runs 01 and 02
  data/
    raw/                           the official files, cut down to New Jersey (see below)
    boundaries/nj_counties.gpkg    the 21 counties
    colleges.csv, math_degrees.csv, admissions.csv, net_price.csv, math_earnings.csv
  opra/opra_log.md                 the OPRA request (drafted, not sent) and the log
  docs/
    executive_summary.docx         one page
    research_log.docx              coding decisions, new commands, and the AI record
  output/figures/                  screenshots of the dashboard
```


## Versions

Built and tested with R 4.3.3 on Linux, with these packages:

| Package | Version |
| --- | --- |
| shiny | 1.8.0 |
| tidyverse | 2.0.0 (ggplot2 3.4.4, dplyr 1.1.4, readr 2.1.5, tidyr 1.3.1, stringr 1.5.1, forcats 1.0.0) |
| sf | 1.0-15 |
| scales | 1.3.0 (installed with tidyverse) |

It has not been run on Windows or a Mac yet, or with newer versions of these packages.


## The sources

**Source 1. IPEDS Complete Data Files**, National Center for Education Statistics (NCES), U.S.
Department of Education. Downloaded November 11, 2026.
- Where to download: https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx
- The key is `UNITID`, IPEDS's six-digit code for a college, kept as text.

| File | What it is | Year of the data | Direct link | NCES last changed the zip |
| --- | --- | --- | --- | --- |
| HD2025 | Directory information (name, city, sector, latitude, longitude) | 2025-26 | https://nces.ed.gov/ipeds/complete-data-files/HD2025.zip | July 21, 2026 |
| C2023_A | Degrees awarded by field (CIP code) | July 1, 2022 to June 30, 2023 (final) | https://nces.ed.gov/ipeds/complete-data-files/C2023_A.zip | December 11, 2025 |
| C2024_A | Degrees awarded by field | July 1, 2023 to June 30, 2024 (revised) | https://nces.ed.gov/ipeds/complete-data-files/C2024_A.zip | August 31, 2026 |
| C2025_A | Degrees awarded by field | July 1, 2024 to June 30, 2025 (provisional) | https://nces.ed.gov/ipeds/complete-data-files/C2025_A.zip | July 21, 2026 |
| ADM2024 | Applications, admissions, and test scores | Students who started in fall 2024 | https://nces.ed.gov/ipeds/complete-data-files/ADM2024.zip | December 11, 2025 |

- The C2023_A and C2024_A zips each hold two CSVs. This project uses the revised one
  (`c2023_a_RV.csv` and `c2024_a_rv.csv`). For these colleges the math rows are the same in both;
  five all-fields totals differ by 1 to 13 degrees (Rutgers-Camden, Rutgers-New Brunswick, and
  Rutgers-Newark in 2023; Rutgers-New Brunswick and Stockton in 2024).
- `SECTOR` 1 is public, four-year or above. `AWLEVEL` 5 is a bachelor's degree. `MAJORNUM` 1 is a
  first major. `CIPCODE` 99 is every field added together, and codes that start with 27 are
  mathematics and statistics. `CTOTALT` is the count for all students.
- `APPLCN` is applicants, `ADMSSN` is admitted, `SATPCT` is the percent of new students who sent
  SAT scores, and `SATMT25`, `SATMT50`, `SATMT75` are the 25th, 50th, and 75th percentile SAT
  math scores.

**Source 2. College Scorecard**, U.S. Department of Education. Downloaded November 11, 2026. The
page said "last updated November 2, 2026."
- Where to download: https://collegescorecard.ed.gov/data/
- Most Recent Institution-Level Data:
  https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Institution_11022026.zip
  (a 24 MB zip; the CSV inside is 102 MB and has 3,379 columns).
  `NPT4_PUB` is the average net price at a public college and `NPT41_PUB` to `NPT45_PUB` are the
  same thing for five family income groups. `NUM4_PUB` and `NUM41_PUB` to `NUM45_PUB` are the
  number of students behind each one. **Academic year 2024-25.**
- Most Recent Data by Field of Study:
  https://ed-public-download.scorecard.network/downloads/Most-Recent-Cohorts-Field-of-Study_10152026.zip
  (a 34 MB zip; the CSV inside is 198 MB).
  `EARN_MDN_4YR` is the median earnings of graduates four years after finishing, `EARN_COUNT_WNE_4YR`
  is how many graduates that is, and `EARN_MDN_4YR_NAT` is the same median for the whole country.
  **Graduates of 2017-18 and 2018-19, earnings measured in 2022 and 2023, in 2024 dollars.** Only
  graduates who received federal financial aid and were working and not enrolled are counted.
- The years come from the Scorecard's data dictionary (the `Most_Recent_Inst_Cohort_Map` and
  `FieldOfStudy_Cohort_Map` sheets): https://collegescorecard.ed.gov/files/CollegeScorecardDataDictionary.xlsx
- `PS` means privacy suppressed (too few people to show the number).
- The three Rutgers campuses share one `OPEID6` (002629), and the field of study file gives all
  three the same earnings. It is one number for Rutgers, not three.

**Source 3. Cartographic boundary files**, U.S. Census Bureau, 2022 (counties, 1:500,000).
- Where to download: https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
- The file: https://www2.census.gov/geo/tiger/GENZ2022/shp/cb_2022_us_county_500k.zip
- `data/boundaries/nj_counties.gpkg` is copied from the class repository
  (`STA220/3.3/data/boundaries/nj_counties.gpkg`), where 3.3's `02_import.R` made it with `tigris`.

**The OPRA request** (class sizes in TCNJ's math and statistics courses) is drafted but has
**not been sent**, so there are no OPRA records in this project. See `opra/opra_log.md`.


## How the files in data/raw/ were made

Two of the official files are over GitHub's 100 MB limit, so the full downloads are not in the
repository. `data/raw/` has each official file cut down to New Jersey's public four-year colleges
and the columns this project uses. Rows and columns were dropped. No value was changed.

On November 11, 2026, Claude downloaded each zip from the links above in a browser, read the CSV
inside, and kept these rows and columns:

| File in data/raw/ | Cut from | Rows kept | Columns kept | Rows |
| --- | --- | --- | --- | --- |
| hd2025_nj.csv | hd2025.csv | `STABBR` is NJ and `SECTOR` is 1 | UNITID, INSTNM, CITY, STABBR, SECTOR, COUNTYNM, LONGITUD, LATITUDE | 14 |
| c2023_a_nj.csv | c2023_a_RV.csv | the 14 colleges, `AWLEVEL` 5, `CIPCODE` 99 or starting with 27 | UNITID, CIPCODE, MAJORNUM, AWLEVEL, CTOTALT | 34 |
| c2024_a_nj.csv | c2024_a_rv.csv | the same | the same | 36 |
| c2025_a_nj.csv | c2025_a.csv | the same | the same | 35 |
| adm2024_nj.csv | adm2024.csv | the 14 colleges (13 have a row) | UNITID, APPLCN, ADMSSN, ENRLT, SATNUM, SATPCT, SATMT25, SATMT50, SATMT75 | 13 |
| scorecard_institution_nj.csv | Most-Recent-Cohorts-Institution.csv | the 14 colleges | UNITID, OPEID6, INSTNM, STABBR, CONTROL, the six NPT4 columns, the six NUM4 columns | 14 |
| scorecard_field_of_study_nj.csv | Most-Recent-Cohorts-Field-of-Study.csv | the 14 colleges, `CREDLEV` 3, `CIPCODE` starting with 27 | UNITID, OPEID6, INSTNM, MAIN, CIPCODE, CIPDESC, CREDLEV, CREDDESC, EARN_COUNT_WNE_4YR, EARN_MDN_4YR, EARN_COUNT_WNE_4YR_NAT, EARN_MDN_4YR_NAT | 19 |

`scripts/00_cut_raw_files.R` does the same cut in R. It was tested on copies of the cut files and
wrote back the same seven files, byte for byte. **It has not been run on the full downloads.** To
check it, download the seven files, unzip them into `data/raw/full/`, and run the script. GitHub
Desktop should then show no changes in `data/raw/`.

Nothing was changed by hand in Excel.


## Decisions to know about

The research log has every decision and the reason. The big ones:

- **13 colleges, not 14.** IPEDS lists 14 public four-year colleges in New Jersey. Thomas Edison
  State University is left out because it is built for adults and enrolled no first-time freshmen.
- **Kean Jersey City.** New Jersey City University became part of Kean University on July 1,
  2026. All of its numbers here are from before the merger.
- **"Math" is CIP code 27** (mathematics and statistics), bachelor's degrees, first majors only,
  three graduating classes added together.
- **A rate, not a total.** Figure 1 is math majors per 100 graduates. The count is printed next
  to each bar.
- **The benchmark is the median college** (half of the 13 are above and half below), so each
  college counts once. For earnings it is the national median for math graduates, which comes in
  the Scorecard file.
- **Missing numbers stay missing.** Four colleges reported no SAT math range, Ramapo's earnings
  are hidden for privacy, and Bloomfield College has no Mathematics row in the Scorecard. The
  dashboard says so instead of dropping the colleges.


## Still to do

- Send the OPRA request and fill in `opra/opra_log.md`.
- Publish the app and paste the link at the top of this file.
- Download the repository into a new folder on a computer that has not run it before and run it
  from this README.
