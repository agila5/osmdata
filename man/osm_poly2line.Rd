% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/poly2line.R
\name{osm_poly2line}
\alias{osm_poly2line}
\title{Convert osmdata polygons into lines}
\usage{
osm_poly2line(osmdat)
}
\arguments{
\item{osmdat}{An \link{osmdata} object.}
}
\value{
Modified version of same object with all \code{osm_polygons}
objects merged into \code{osm_lines}.
}
\description{
Street networks downloaded with \code{add_osm_object(key = "highway")} will
store any circular highways in \code{osm_polygons}. this function combines
those with the \code{osm_lines} component to yield a single \pkg{sf}
\code{data.frame} of all highways, whether polygonal or not.
}
\note{
The \code{osm_polygons} field is retained, with those features also
repeated as \code{LINESTRING} objects in \code{osm_lines}.
}
\examples{
\dontrun{
query <- opq ("colchester uk") |>
    add_osm_feature (key = "highway")
# Then extract data from 'Overpass' API
dat <- osmdata_sf (query)
# colchester has lots of roundabouts, and these are stored in 'osm_polygons'
# rather than 'osm_lines'. The former can be merged with the latter by:
dat2 <- osm_poly2line (dat)
}
# 'dat2' will have more lines than 'dat', but the same number of polygons
# (they are left unchanged.)
}
\seealso{
Other transform: 
\code{\link{osm_elevation}()},
\code{\link{trim_osmdata}()},
\code{\link{unique_osmdata}()},
\code{\link{unname_osmdata_sf}()}
}
\concept{transform}
