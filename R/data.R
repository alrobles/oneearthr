#' One Earth Bioregions Framework layers (packaged)
#'
#' Packaged spatial layers of the One Earth Bioregions Framework, stored as
#' wrapped `terra::SpatVector` objects (see [terra::wrap]). Use [oe_layer()]
#' or [terra::unwrap()] to materialise them.
#'
#' @format Wrapped `SpatVector` polygon layers in EPSG:4326, simplified to
#' keep the package lightweight (use `oe_layer(layer, full = TRUE)` for the
#' original geometries):
#' \describe{
#'   \item{oe_realms}{14 biogeographical realms (~0.02 deg tolerance).}
#'   \item{oe_subrealms}{53 subrealms (~0.02 deg).}
#'   \item{oe_bioregions}{185 bioregions, coded by realm prefix + number
#'     (~0.02 deg).}
#'   \item{oe_ecoregions}{847 ecoregions from RESOLVE Ecoregions 2017
#'     (~0.15 deg).}
#' }
#' @source One Earth Bioregions Framework (2023), <https://www.oneearth.org>,
#'   licensed CC BY-NC 4.0 (non-commercial use, cite One Earth);
#'   Ecoregions: Dinerstein et al. (2017) \doi{10.1093/biosci/bix014},
#'   licensed CC-BY 4.0.
#' @name oe_data
NULL

#' @rdname oe_data
#' @format NULL
"oe_realms"

#' @rdname oe_data
#' @format NULL
"oe_subrealms"

#' @rdname oe_data
#' @format NULL
"oe_bioregions"

#' @rdname oe_data
#' @format NULL
"oe_ecoregions"

#' Bioregion names and framework hierarchy
#'
#' Lookup table mapping the 185 bioregion codes (e.g. `"NA01"`) to their
#' names and their position in the One Earth hierarchy.
#'
#' @format A `data.frame` with 185 rows and 5 columns:
#' \describe{
#'   \item{code}{Bioregion code; joins to `oe_layer("bioregions")$bioregions`.}
#'   \item{name}{Bioregion name (e.g. `"Amazon River Estuary"`).}
#'   \item{biogeographic_realm}{One of the 8 traditional realms.}
#'   \item{realm}{One Earth realm (14 divisions).}
#'   \item{subrealm}{One Earth subrealm (52 groupings).}
#' }
#' @source One Earth Bioregions Framework 2023 (CC BY-NC 4.0),
#'   <https://www.oneearth.org/datasets/>; table mirrored at
#'   <https://datahub.io/climate-and-environment/bioregions-2023>.
"oe_bioregion_names"
