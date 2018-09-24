#' add polygons/polygons to a leaflet map using Leaflet.glify
#'
#' @details
#'   Multipolygons are currently not supported! Make sure you cast your data
#'   to polygons first (e.g. using \code{sf::st_cast(data, "POLYGON")}.
#'
#' @examples
#' \dontrun{
#' library(mapview)
#' library(leaflet)
#' library(leaflet.glify)
#' library(sf)
#' library(colourvalues)
#'
#' fran = st_cast(franconia, "POLYGON")
#'
#' cols = colour_values_rgb(fran$NUTS_ID, include_alpha = FALSE) / 255
#'
#' options(viewer = NULL)
#'
#' leaflet() %>%
#'   addProviderTiles(provider = providers$CartoDB.DarkMatter) %>%
#'   addGlifyPolygons(data = fran, color = cols) %>%
#'   addMouseCoordinates() %>%
#'   setView(lng = 10.5, lat = 49.5, zoom = 8)
#' }
#'
#' @describeIn addGlifyPoints add polygons to a leaflet map using Leaflet.glify
#' @aliases addGlifyPolygons
#' @export addGlifyPolygons
addGlifyPolygons = function(map,
                            data,
                            color = cbind(0, 0.2, 1),
                            opacity = 0.6,
                            weight = 10,
                            group = "glpolygons",
                            popup = NULL,
                            ...) {

  if (is.null(group)) group = deparse(substitute(data))
  if (inherits(data, "Spatial")) data <- sf::st_as_sf(data)
  stopifnot(inherits(sf::st_geometry(data), c("sfc_POLYGON", "sfc_MULTIPOLYGON")))
  if (inherits(sf::st_geometry(data), "sfc_MULTIPOLYGON"))
    stop("Can only handle POLYGONs, please cast your MULTIPOLYGON to POLYGON using sf::st_cast")

  # temp directories
  dir_data = tempfile(pattern = "glify_polygons_dt")
  dir.create(dir_data)
  dir_color = tempfile(pattern = "glify_polygons_cl")
  dir.create(dir_color)
  # dir_popup = tempfile(pattern = "glify_polygons_pop")
  # dir.create(dir_popup)

  # data
  data = sf::st_transform(data, 4326)
  # crds = sf::st_coordinates(data)[, c(2, 1)]

  fl_data = paste0(dir_data, "/", group, "_data.json")
  cat(geojsonsf::sf_geojson(data), file = fl_data, append = FALSE)
  data_var = paste0(group, "dt")

  # color
  if (ncol(color) != 3) stop("only 3 column color matrix supported so far")
  color = as.data.frame(color, stringsAsFactors = FALSE)
  colnames(color) = c("r", "g", "b")

  jsn = jsonlite::toJSON(color)
  fl_color = paste0(dir_color, "/", group, "_color.json")
  color_var = paste0(group, "cl")
  cat(jsn, file = fl_color, append = FALSE)

  # popup
  # if (!is.null(popup)) {
  #   pop = jsonlite::toJSON(data[[popup]])
  #   fl_popup = paste0(dir_popup, "/", group, "_popup.json")
  #   popup_var = paste0(group, "pop")
  #   cat(pop, file = fl_popup, append = FALSE)
  # } else {
  #   popup_var = NULL
  # }

  # dependencies
  map$dependencies = c(
    map$dependencies,
    glifyDependencies(),
    glifyDataAttachment(fl_data, group),
    glifyColorAttachment(fl_color, group)
  )

  # if (!is.null(popup)) {
  #   map$dependencies = c(
  #     map$dependencies,
  #     glifyPopupAttachment(fl_popup, group)
  #   )
  # }

  leaflet::invokeMethod(map, leaflet::getMapData(map), 'addGlifyPolygons',
                        data_var, color_var, popup, opacity, weight)

}