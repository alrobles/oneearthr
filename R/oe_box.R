## Box shared-folder download (One Earth hosts the framework shapefiles on
## Box, which has no stable direct-download URL). The shared page embeds a
## JSON manifest ("items": [{"typedID": "f_...", "name": "..."}, ...]);
## each file is fetched via index.php?rm=box_download_shared_file.

## Shared-link ids for the framework layers.
.oe_box_shares <- c(
  bioregions = "li9271lkjn0cy109pvhvqzxmy25yysjr",
  subrealms  = "s03jkmka8aifgxvu8nxllmua8yx6ys2q",
  realms     = "9mp4m5tmmtbqh9mnxzeifjz8me63xdcq"
)

## Download every file in a One Earth Box shared folder into `dest_dir`.
.oe_box_download <- function(layer, dest_dir) {
  shared_name <- .oe_box_shares[[layer]]
  page_url <- sprintf("https://oneearth.box.com/s/%s", shared_name)
  html <- paste(readLines(page_url, warn = FALSE), collapse = "\n")

  items <- .oe_box_items(html)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  for (i in seq_len(nrow(items))) {
    dl <- sprintf(
      "https://oneearth.box.com/index.php?rm=box_download_shared_file&shared_name=%s&file_id=%s",
      shared_name, items$typedID[i])
    utils::download.file(dl, file.path(dest_dir, items$name[i]),
                         mode = "wb", quiet = TRUE)
  }
  invisible(dest_dir)
}

## Extract the "items" array embedded in a Box shared-folder page.
## Returns a data.frame with columns typedID and name. Uses a minimal
## bracket-matcher + regex to avoid a JSON dependency.
.oe_box_items <- function(html) {
  i <- regexpr('"items"\\s*:', html)
  if (i < 0) stop("Box shared page has no items manifest.")
  txt <- substring(html, i + attr(i, "match.length"))
  txt <- substring(txt, regexpr("\\[", txt))

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
  if (is.na(end)) stop("Could not parse Box items manifest.")
  arr <- substr(txt, 1, end)

  ids   <- regmatches(arr, gregexpr('"typedID":"f_[0-9]+"', arr))[[1]]
  names <- regmatches(arr, gregexpr('"name":"[^"]*"', arr))[[1]]
  ids   <- sub('.*"(f_[0-9]+)".*', "\\1", ids)
  names <- sub('.*"name":"([^"]*)".*', "\\1", names)
  keep  <- names != ""
  data.frame(typedID = ids[keep], name = names[keep],
             stringsAsFactors = FALSE)
}
