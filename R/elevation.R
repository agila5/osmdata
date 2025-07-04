#' osm_elevation
#'
#' Add elevation data to a previously-extracted OSM data set, using a
#' pre-downloaded global elevation file from
#' \url{https://srtm.csi.cgiar.org/srtmdata/}. Currently only works for
#' `SC`-class objects returned from \link{osmdata_sc}.
#'
#' @param dat An `SC` object produced by \link{osmdata_sc}.
#' @param elev_file A vector of one or more character strings specifying paths
#' to `.tif` files containing global elevation data.
#'
#' @return A modified version of the input `dat` with an additional `z_` column
#' appended to the vertices.
#' @family transform
#'
#' @examples
#' \dontrun{
#' query <- opq ("omaha nebraska") |>
#'     add_osm_feature (key = "highway")
#' # Elevation can only be applied to \pkg{silicate} 'SC'-class data:
#' dat <- osmdata_sc (query)
#' dat$vertex
#' # The vertex table will have columns ("x_", "y_", "vertex_"). Then
#' # download elevation data from \url{https://srtm.csi.cgiar.org/srtmdata/}
#' # (or elsewhere), and add elevation column, "z_" with:
#' dat <- osm_elevation (dat, elev_file = "/path/to/elevation/data.tiff")
#' }
#' @export
osm_elevation <- function (dat, elev_file) {

    requireNamespace ("raster", quietly = TRUE)
    requireNamespace ("sp", quietly = TRUE)

    message (
        "Elevation data from Consortium for Spatial Information; ",
        "see http://srtm.csi.cgiar.org/srtmdata/"
    )

    elev_file <- check_elev_file (elev_file)
    if (length (elev_file) > 1) {
        stop ("not yet")
    }
    r <- raster::raster (elev_file)
    check_bbox (dat, r)

    z <- raster::extract (r, dat$vertex [, 1:2])
    dat$vertex$z_ <- as.double (z)
    dat$vertex <- dat$vertex [, c ("x_", "y_", "z_", "vertex_")]

    return (dat)
}

check_elev_file <- function (elev_file) {

    if (!methods::is (elev_file, "character")) {
        stop ("elev_file must be one of more character strings")
    }

    base_dir <- dirname (elev_file [1])
    lf <- list.files (base_dir, full.names = TRUE)
    ret <- NULL

    for (f in elev_file) {

        if (!file.exists (f)) {
            stop ("file ", f, " does not exist")
        }

        fe <- tools::file_ext (f)
        if (!fe %in% c ("tif", "zip")) {
            stop ("Unrecognised file format [.", fe, "]; must be .zip or .tif")
        }

        if (fe == "zip") {

            ftif <- paste0 (basename (tools::file_path_sans_ext (f)), ".tif")
            index <- grepl (ftif, lf, ignore.case = TRUE)
            if (!any (index)) {
                message (
                    "File ", f, " has not been unzipped; ",
                    "this may take a while ... ",
                    appendLF = FALSE
                )
                utils::unzip (f, exdir = base_dir)
                message ("done.")
                lf <- list.files (base_dir, full.names = TRUE)
                index <- grepl (ftif, lf, ignore.case = TRUE)
            }

            ret <- c (ret, lf [which (index)])
        } else {
            ret <- c (ret, f)
        }
    }

    return (unique (ret))
}

check_bbox <- function (dat, r) {

    bb <- as.numeric (strsplit (dat$meta$bbox, ",") [[1]])
    bb <- matrix (bb [c (2, 1, 4, 3)], ncol = 2)
    bbr <- sp::bbox (r)

    if (bb [1, 1] < bbr [1, 1] |
        bb [1, 2] > bbr [1, 2] |
        bb [2, 1] < bbr [2, 1] |
        bb [2, 2] > bbr [2, 2]) {
        message ("Elevation file does not cover OSM data file")
    }
}

# elevation tiles from http://srtm.csi.cgiar.org/srtmdata
# names are srtm_XX_YY.zip
# XX is 01 for (-180, -175) and 72 for (175, 180)
# so xx <- 36 + floor (-175:180 / 5)
# YY is 01 for (50, 55) and 25 for (-75, -70)
# so yy <- 14 + floor (-65:55 / 5)
get_tile_index <- function (bb) {

    bb <- as.numeric (strsplit (bb, ",") [[1]])
    xi_min <- 36 + floor (bb [2] / 5)
    xi_max <- 36 + floor (bb [4] / 5)
    yi_min <- 14 + floor (bb [1] / 5)
    yi_max <- 14 + floor (bb [3] / 5)

    xi <- as.integer (unique (c (xi_min, xi_max)))
    yi <- as.integer (unique (c (yi_min, yi_max)))

    data.frame (
        "xi" = rep (xi, each = length (yi)),
        "yi" = rep (yi, times = length (xi))
    )
}
