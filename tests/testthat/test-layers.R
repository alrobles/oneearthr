test_that("all four layers load as SpatVectors", {
  for (l in c("realms", "subrealms", "bioregions", "ecoregions")) {
    v <- oe_layer(l)
    expect_s4_class(v, "SpatVector")
    expect_equal(terra::geomtype(v), "polygons")
  }
})

test_that("layer sizes match the framework", {
  expect_equal(nrow(oe_layer("realms")), 14)
  expect_equal(nrow(oe_layer("subrealms")), 53)
  expect_equal(nrow(oe_layer("bioregions")), 185)
  expect_equal(nrow(oe_layer("ecoregions")), 847)
})

test_that("crs is EPSG:4326", {
  v <- oe_layer("realms")
  expect_equal(terra::crs(v, describe = TRUE)$code, "4326")
})

test_that("scale accepts small/medium/large and numeric aliases", {
  expect_s4_class(oe_layer("realms", scale = "small"), "SpatVector")
  expect_s4_class(oe_layer("realms", scale = 110), "SpatVector")
  expect_error(oe_layer("realms", scale = 999))
  expect_error(oe_layer("realms", scale = "huge"))
})

test_that("returnclass = 'sf' returns a simple feature", {
  skip_if_not_installed("sf")
  v <- oe_layer("realms", returnclass = "sf")
  expect_s3_class(v, "sf")
  expect_equal(nrow(v), 14)
})

test_that("realm/subrealm/bioregion/name filters work", {
  nt <- oe_layer("ecoregions", realm = "Neotropic")
  expect_gt(nrow(nt), 0)
  expect_true(all(nt$realm == "Neotropic"))

  one <- oe_layer("ecoregions", name = "Adelie Land tundra")
  expect_equal(nrow(one), 1)

  amz <- oe_layer("bioregions", bioregion = "Amazon River Estuary")
  expect_equal(nrow(amz), 1)

  amz2 <- oe_layer("bioregions", bioregion = "NT16")
  expect_equal(amz$bioregions, amz2$bioregions)

  sub <- oe_layer("subrealms", subrealm = "Amazonia")
  expect_equal(nrow(sub), 1)

  expect_error(oe_layer("ecoregions", realm = "Noplace"),
               "not found")
})

test_that("full-resolution download works (online only)", {
  skip_on_cran()
  skip_if_not_installed("curl")
  skip_if_offline()
  v <- oe_layer("realms", scale = "large")
  expect_s4_class(v, "SpatVector")
  expect_equal(nrow(v), 14)
})

test_that("oe_layers() lists the four layers", {
  expect_equal(oe_layers()$layer,
               c("realms", "subrealms", "bioregions", "ecoregions"))
})

test_that("bioregion names table covers all 185 codes", {
  expect_equal(nrow(oe_bioregion_names), 185)
  codes <- oe_layer("bioregions")$bioregions
  expect_true(all(codes %in% oe_bioregion_names$code))
  expect_true(all(c("code", "name", "biogeographic_realm", "realm",
                    "subrealm") %in% names(oe_bioregion_names)))
})
