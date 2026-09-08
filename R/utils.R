#' Package cache directory
#'
#' Returns (and creates) the per-user cache directory used by `oneearthr`
#' for downloaded layers.
#'
#' @return A path (character).
#' @keywords internal
.oe_cache_dir <- function() {
  d <- tools::R_user_dir("oneearthr", "cache")
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  d
}

#' Check that a URL is reachable
#'
#' @param x A string with the url to check.
#' @param quiet Logical; suppress the error message.
#' @param ... Passed to [utils::download.file] internals.
#' @return Logical, `TRUE` if the url responds.
#' @keywords internal
url_exists <- function(x, quiet = FALSE, ...) {
  capture_error <- function(code, otherwise = NULL, quiet = TRUE) {
    tryCatch(
      list(result = code, error = NULL),
      error = function(e) {
        if (!quiet) message("Error: ", e$message)
        list(result = otherwise, error = e)
      }
    )
  }
  res <- capture_error(utils::download.file(x, tempfile(), quiet = TRUE,
                                            mode = "wb"), otherwise = FALSE)
  is.null(res$error)
}
