# scripts/master.R
# Reruns everything the dashboard needs: the clean tables in data/ and the three files in
# app/data/. Restart R first (Session > Restart R), then source this file from the project
# (math_college_dashboard.Rproj).
#
# Not included: 00_cut_raw_files.R. You do not need it (everything it writes is already in
# data/raw/), and it needs the full official downloads, which are too big for GitHub.

source("scripts/01_import.R")                  # the raw files into clean tables in data/

source("scripts/02_build_dashboard_data.R")    # the clean tables joined into app/data/

list.files("app/data")

# Then open app/app.R and click Run App.
