## Data pipeline for oneearthr
##
## Downloads the One Earth Bioregions Framework layers and builds the
## packaged datasets in data/. Sources:
##   - Ecoregions 2017 (RESOLVE / Dinerstein et al. 2017, CC-BY 4.0):
##       https://storage.googleapis.com/teow2016/Ecoregions2017.zip
##   - Bioregions, Subrealms, Realms (One Earth Bioregions Framework 2023):
##       Box shared folders provided by One Earth (see email, E. Bell).
##       Box exposes no stable direct-download URL, so data-raw/download_box.R
##       scrapes the shared-page manifest and fetches each file via
##       index.php?rm=box_download_shared_file.
##
## Packaged datasets are wrapped terra SpatVectors (see ?terra::wrap).
## Unwrap with oe_layer() or terra::unwrap().
##
## All layers are embedded as simplified geometries to keep the package
## under CRAN's 5 MB data limit (total ~4.4 MB):
##   realms/subrealms/bioregions: tolerance 0.02 deg
##   ecoregions:                  tolerance 0.15 deg
## Full-resolution access is provided by oe_layer(..., full = TRUE).

library(terra)
library(usethis)

dl_dir <- "data-raw/downloads"

## -- download sources --------------------------------------------------------
source("data-raw/download_box.R") # provides box_download_shared()

if (!file.exists(file.path(dl_dir, "Ecoregions2017/Ecoregions2017.shp"))) {
  zip <- file.path(dl_dir, "Ecoregions2017.zip")
  options(timeout = max(600, getOption("timeout")))
  download.file("https://storage.googleapis.com/teow2016/Ecoregions2017.zip",
                zip, mode = "wb")
  unzip(zip, exdir = file.path(dl_dir, "Ecoregions2017"))
}
box_download_shared("li9271lkjn0cy109pvhvqzxmy25yysjr",
                    file.path(dl_dir, "bioregions"))
box_download_shared("s03jkmka8aifgxvu8nxllmua8yx6ys2q",
                    file.path(dl_dir, "subrealms"))
box_download_shared("9mp4m5tmmtbqh9mnxzeifjz8me63xdcq",
                    file.path(dl_dir, "realms"))

## -- normalise ---------------------------------------------------------------
read_layer <- function(path, tol) {
  v <- vect(path)
  v <- makeValid(v)
  v <- project(v, "EPSG:4326")
  names(v) <- tolower(names(v))
  ## drop redundant bookkeeping columns to keep the package light
  for (nm in c("objectid", "shape_leng", "shape_area"))
    if (nm %in% names(v)) v[[nm]] <- NULL
  v <- simplifyGeom(v, tolerance = tol, preserveTopology = TRUE)
  makeValid(v)
}

oe_realms     <- read_layer(file.path(dl_dir, "realms/Realm2023.shp"), 0.02)
oe_subrealms  <- read_layer(file.path(dl_dir, "subrealms/Subrealm2023Rev_wgs84.shp"), 0.02)
oe_bioregions <- read_layer(file.path(dl_dir, "bioregions/Bioregions2023Rev_wgs84.shp"), 0.02)
oe_ecoregions <- read_layer(file.path(dl_dir, "Ecoregions2017/Ecoregions2017.shp"), 0.15)

## -- bioregion names lookup ---------------------------------------------------
## One Earth publishes the framework hierarchy as a table (mirrored at
## datahub.io/climate-and-environment/bioregions-2023). Codes there are
## unpadded ("NA1"); the shapefile uses zero-padded codes ("NA01").
if (!file.exists(file.path(dl_dir, "bioregion_names.csv"))) {
  download.file(
    "https://datahub.io/climate-and-environment/bioregions-2023/_r/-/data/bioregions.csv",
    file.path(dl_dir, "bioregion_names.csv"), quiet = TRUE)
}
oe_bioregion_names <- read.csv(file.path(dl_dir, "bioregion_names.csv"),
                               stringsAsFactors = FALSE)
oe_bioregion_names$code <- sprintf(
  "%s%02d",
  sub("[0-9]+$", "", oe_bioregion_names$code),
  as.integer(sub("^[A-Z]+", "", oe_bioregion_names$code)))
oe_bioregion_names <- oe_bioregion_names[
  order(oe_bioregion_names$code),
  c("code", "name", "biogeographic_realm", "realm", "subrealm")]
stopifnot(all(oe_bioregion_names$code %in% sort(oe_bioregions$bioregions)))

## -- export ------------------------------------------------------------------
## Stored wrapped; see R/data.R for accessors.
use_data(oe_bioregion_names, overwrite = TRUE)

oe_realms     <- wrap(oe_realms)
oe_subrealms  <- wrap(oe_subrealms)
oe_bioregions <- wrap(oe_bioregions)
oe_ecoregions <- wrap(oe_ecoregions)

use_data(oe_realms,     overwrite = TRUE, compress = "xz")
use_data(oe_subrealms,  overwrite = TRUE, compress = "xz")
use_data(oe_bioregions, overwrite = TRUE, compress = "xz")
use_data(oe_ecoregions, overwrite = TRUE, compress = "xz")
