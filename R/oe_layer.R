#' Access a One Earth Bioregions Framework layer
#'
#' Returns one layer of the One Earth Bioregions Framework, in the spirit of
#' [rnaturalearth::ne_countries()]: pick the layer, the `scale` of the
#' geometries, optionally filter by framework names, and choose the spatial
#' class of the result.
#'
#' All layers ship with the package as lightweight simplified geometries
#' (`scale = "small"`) so they work offline. `scale = "large"` (or
#' `"medium"`, currently equivalent) downloads the original geometries: the
#' ecoregions (~150 MB) come from the public RESOLVE cloud bucket, the other
#' layers from the One Earth shared folders. Downloaded files are cached in
#' `tools::R_user_dir("oneearthr", "cache")`.
#'
#' @param layer One of `"realms"`, `"subrealms"`, `"bioregions"`,
#'   `"ecoregions"`. Partial matching is allowed.
#' @param scale Scale of the geometries: `"small"`, `"medium"` or `"large"`
#'   (numeric equivalents `110`, `50`, `10` as in Natural Earth are accepted).
#'   `"small"` returns the packaged simplified layer; `"medium"`/`"large"`
#'   download the full-resolution geometries.
#' @param returnclass Spatial class of the returned object: `"sv"` for a
#'   `terra` `SpatVector` (default) or `"sf"` for a simple feature object
#'   (requires the `sf` package).
#' @param realm,subrealm,bioregion Optional character vectors of framework
#'   names to filter the result (e.g. `realm = "Neotropic"`,
#'   `subrealm = "Amazonia"`, `bioregion = "Amazon River Estuary"` or a code
#'   such as `"NT04"`).
#' @param name Optional character vector of feature names to keep
#'   (`eco_name` for ecoregions, `subrealm_n` for subrealms, realm or
#'   bioregion names for the other layers).
#' @return A `terra::SpatVector` (or `sf` object) of polygons in EPSG:4326.
#' @export
#' @source One Earth Bioregions Framework (2023), <https://www.oneearth.org>,
#'   licensed CC BY-NC 4.0 (non-commercial use, cite One Earth);
#'   Ecoregions: Dinerstein et al. (2017) \doi{10.1093/biosci/bix014},
#'   licensed CC-BY 4.0.
#' @details The packaged geometries (`scale = "small"`) are simplified with
#'   [terra::simplifyGeom()] (`preserveTopology = TRUE`): vertex positions may
#'   deviate from the originals by up to ~0.02 degree (realms, subrealms,
#'   bioregions) or ~0.15 degree (ecoregions). They are suitable for
#'   overview maps and quick exploration, but not for precise area
#'   calculations or boundary-exact spatial joins — use `scale = "large"`
#'   for that.
#' @examples
#' realms <- oe_layer("realms")
#' terra::plot(realms, col = as.factor(realms$biogeorelm))
#'
#' # only the Neotropic ecoregions
#' nt <- oe_layer("ecoregions", realm = "Neotropic")
oe_layer <- function(layer = c("realms", "subrealms", "bioregions",
                               "ecoregions"),
                     scale = c("small", "medium", "large"),
                     returnclass = c("sv", "sf"),
                     realm = NULL, subrealm = NULL, bioregion = NULL,
                     name = NULL) {
  layer <- match.arg(layer)
  scale <- .oe_scale(scale)
  returnclass <- match.arg(returnclass)

  v <- if (scale == "small") {
    terra::unwrap(get(paste0("oe_", layer)))
  } else {
    .oe_layer_full(layer)
  }

  v <- .oe_filter(v, layer, realm, subrealm, bioregion, name)

  if (returnclass == "sf") {
    if (!requireNamespace("sf", quietly = TRUE))
      stop("Package 'sf' is required for returnclass = \"sf\".")
    return(sf::st_as_sf(v))
  }
  v
}

#' @rdname oe_layer
#' @export
get_oe <- oe_layer

#' List the available One Earth layers
#'
#' @return A `data.frame` describing the four framework layers.
#' @export
#' @examples
#' oe_layers()
oe_layers <- function() {
  data.frame(
    layer      = c("realms", "subrealms", "bioregions", "ecoregions"),
    n          = c(nrow(oe_layer("realms")), nrow(oe_layer("subrealms")),
                   nrow(oe_layer("bioregions")), nrow(oe_layer("ecoregions"))),
    scale_small = c("~0.02 deg tolerance", "~0.02 deg tolerance",
                    "~0.02 deg tolerance", "~0.15 deg tolerance"),
    source     = c("One Earth Bioregions Framework 2023",
                   "One Earth Bioregions Framework 2023",
                   "One Earth Bioregions Framework 2023",
                   "RESOLVE Ecoregions 2017 (Dinerstein et al., CC-BY 4.0)"),
    stringsAsFactors = FALSE
  )
}

## Normalise the scale argument: accepts small/medium/large or the Natural
## Earth numeric equivalents 110/50/10.
.oe_scale <- function(scale) {
  if (is.numeric(scale)) {
    scale <- switch(as.character(scale),
                    "110" = "small", "50" = "medium", "10" = "large",
                    stop("`scale` must be one of 110, 50, 10 or 'small', ",
                         "'medium', 'large'."))
  }
  match.arg(scale, c("small", "medium", "large"))
}

## Attribute filtering across framework names. Bioregion names are resolved
## through oe_bioregion_names (the geometry only carries codes).
.oe_filter <- function(v, layer, realm, subrealm, bioregion, name) {
  keep <- rep(TRUE, nrow(v))

  ## `vals` match if they occur in ANY of the given columns; error if none
  ## do, listing the offending values.
  match_any <- function(vals, cols) {
    df <- as.data.frame(v)
    hit <- rep(FALSE, nrow(v))
    for (cl in cols) {
      if (!is.null(df[[cl]])) hit <- hit | (df[[cl]] %in% vals)
    }
    if (!any(hit)) {
      stop("Value(s) not found (searched ", paste(cols, collapse = ", "),
           "): ", paste(vals, collapse = ", "))
    }
    hit
  }

  if (layer == "ecoregions") {
    if (!is.null(realm))  keep <- keep & match_any(realm, "realm")
    if (!is.null(name))   keep <- keep & match_any(name, "eco_name")
    if (!is.null(subrealm))
      warning("Ecoregions carry realm only; ignoring `subrealm`.")
    if (!is.null(bioregion))
      warning("Ecoregions do not carry bioregion codes; ignoring `bioregion`.")
  } else if (layer == "bioregions") {
    meta <- oe_bioregion_names[match(v$bioregions, oe_bioregion_names$code), ]
    if (!is.null(bioregion)) {
      codes <- .oe_name_to_code(bioregion)
      keep <- keep & match_any(codes, "bioregions")
    }
    if (!is.null(name))   keep <- keep & .oe_check(meta$name %in% name,
                                                   name, "bioregion name")
    if (!is.null(realm))  keep <- keep & .oe_check(meta$realm %in% realm,
                                                  realm, "realm")
    if (!is.null(subrealm)) keep <- keep & .oe_check(
      meta$subrealm %in% subrealm, subrealm, "subrealm")
  } else if (layer == "subrealms") {
    if (!is.null(realm))    keep <- keep & match_any(realm, "biogeorelm")
    if (!is.null(subrealm)) keep <- keep & match_any(subrealm, "subrealm_n")
    if (!is.null(name))     keep <- keep & match_any(name, "subrealm_n")
  } else { # realms
    if (!is.null(realm)) keep <- keep & match_any(realm, c("realm",
                                                         "biogeorelm"))
    if (!is.null(name))  keep <- keep & match_any(name, c("realm",
                                                        "biogeorelm"))
  }

  v[keep, ]
}

## Error if a filter hit nothing.
.oe_check <- function(hit, vals, what) {
  if (!any(hit)) stop("Value(s) not found in ", what, ": ",
                      paste(vals, collapse = ", "))
  hit
}

## Map bioregion names to codes; returns the input unchanged if it already
## looks like codes.
.oe_name_to_code <- function(x) {
  if (is.null(x)) return(NULL)
  i <- match(x, oe_bioregion_names$name)
  ifelse(is.na(i), x, oe_bioregion_names$code[i])
}

## Full-resolution access: ecoregions from the RESOLVE bucket, the three
## framework layers from the One Earth Box shared folders. Results are cached.
.oe_layer_full <- function(layer) {
  cache <- .oe_cache_dir()

  if (layer == "ecoregions") {
    shp <- file.path(cache, "Ecoregions2017", "Ecoregions2017.shp")
    if (!file.exists(shp)) {
      zip <- file.path(cache, "Ecoregions2017.zip")
      url <- "https://storage.googleapis.com/teow2016/Ecoregions2017.zip"
      message("Downloading Ecoregions 2017 (~150 MB) ...")
      old <- options(timeout = max(600, getOption("timeout")))
      on.exit(options(old), add = TRUE)
      utils::download.file(url, zip, mode = "wb", quiet = FALSE)
      utils::unzip(zip, exdir = file.path(cache, "Ecoregions2017"))
    }
  } else {
    dest <- file.path(cache, layer)
    shp <- list.files(dest, pattern = "\\.shp$", full.names = TRUE)[1]
    if (is.na(shp)) {
      message("Downloading full-resolution ", layer, " from One Earth ...")
      .oe_box_download(layer, dest)
      shp <- list.files(dest, pattern = "\\.shp$", full.names = TRUE)[1]
    }
  }

  v <- terra::vect(shp)
  v <- terra::makeValid(v)
  names(v) <- tolower(names(v))
  v
}
