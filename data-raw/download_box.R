## Download all files from a Box shared folder link (no auth).
## The shared page embeds a JSON manifest ("items": [{typedID, name, ...}]);
## each file is fetched via index.php?rm=box_download_shared_file.
box_download_shared <- function(shared_name, dest_dir) {
  page_url <- sprintf("https://oneearth.box.com/s/%s", shared_name)
  html <- paste(readLines(page_url, warn = FALSE), collapse = "\n")

  items <- .box_items_json(html)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  for (i in seq_len(nrow(items))) {
    dl <- sprintf(
      "https://oneearth.box.com/index.php?rm=box_download_shared_file&shared_name=%s&file_id=%s",
      shared_name, items$typedID[i])
    utils::download.file(dl, file.path(dest_dir, items$name[i]),
                         mode = "wb", quiet = TRUE)
  }
  invisible(items)
}

## Extract the "items" JSON array embedded in a Box shared-folder page.
.box_items_json <- function(html) {
  i <- regexpr('"items"\\s*:', html)
  stopifnot(i > 0)
  txt <- substring(html, i + attr(i, "match.length"))
  start <- regexpr("\\[", txt)
  stopifnot(start > 0)
  txt <- substring(txt, start)
  ## bracket-match, string-aware
  chars <- strsplit(txt, "", fixed = TRUE)[[1]]
  depth <- 0L; in_str <- FALSE; esc <- FALSE; end <- NA_integer_
  for (j in seq_along(chars)) {
    c <- chars[j]
    if (in_str) {
      if (esc) esc <- FALSE
      else if (c == "\\") esc <- TRUE
      else if (c == "\"") in_str <- FALSE
    } else {
      if (c == "\"") in_str <- TRUE
      else if (c == "[") depth <- depth + 1L
      else if (c == "]") {
        depth <- depth - 1L
        if (depth == 0L) { end <- j; break }
      }
    }
  }
  stopifnot(!is.na(end))
  jsonlite::fromJSON(substr(txt, 1, end))
}
