# oneearthr 1.0.1

* Add inst/COPYRIGHTS with the licenses of the bundled spatial data
  (RESOLVE Ecoregions 2017 CC-BY 4.0; One Earth Bioregions Framework
  CC BY-NC 4.0) and a note in the DESCRIPTION.

# oneearthr 1.0.0

* Initial CRAN release.
* Packaged spatial layers of the One Earth Bioregions Framework (realms, subrealms, bioregions) and RESOLVE Ecoregions 2017, simplified for lightweight offline use.
* `oe_layer()`: access any layer at `small`/`medium`/`large` scale, with optional filtering by framework names (`realm`, `subrealm`, `bioregion`, `name`) and `terra::SpatVector` or `sf` return class.
* `oe_layers()`: list the available layers and their sources.
* `oe_bioregion_names`: lookup table joining the 185 bioregion codes to names and hierarchy position.
* Full-resolution geometries download on demand (RESOLVE cloud bucket and One Earth shared folders) and are cached per user.
