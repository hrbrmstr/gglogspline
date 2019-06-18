#' Base ggproto classes for gglogspline
#'
#' @section Computed variables:
#'
#' - `density` : the density estimate
#' - `count`: computed counts (similar to [ggplot2::stat_density()])
#' - `probs`: distribution function
#' - `survival`: survival function
#' - `hazard` : hazard function
#'
#' By default the `y` aesthetic is mapped to `stat(density)`
#'
#' @rdname gglogspline-ggproto
#' @export
StatLogspline <- ggproto(

  "StatLogspline", Stat,

  compute_group = function(data, scales,
                           n = 100, max_knots = 0, n_knots = 0,
                           min_d = -1, error_action = 2) {

    logspline(
      data$x,
      maxknots = max_knots,
      nknots = n_knots,
      mind = min_d,
      error.action = error_action
    ) -> lsp

    # computed upper and lower bounds for simplicity

    u1 <- qlogspline(0.01, lsp)
    u2 <- qlogspline(0.99, lsp)

    # we need these to compute the new x-axis values

    u3 <- 1.1 * u1 - 0.1 * u2
    u4 <- 1.1 * u2 - 0.1 * u1

    # compute the new X-axis values and the log-density

    xx <- (0:(n - 1))/(n - 1) * (u4 - u3) + u3
    den <- dlogspline(xx, lsp)
    prb <- plogspline(xx, lsp)

    # our new data frame with an extra computed stat for the count

    data.frame(
      x = xx,
      density = den,
      probs = prb,
      survival = 1 - prb,
      hazard = den / (1 - prb),
      count = den * nrow(data),
      stringsAsFactors = FALSE
    )

  },

  required_aes = c("x"), # we only accept one parameter

  default_aes = aes(
    y = stat(density) # by default we use the computed stat
  )

)

#' Computes logspline density (+ counts estimate), probability, survival & hazard
#'
#'
#' @section Computed variables:
#'
#' - `density` : the density estimate
#' - `count`: computed counts (similar to [ggplot2::stat_density()])
#' - `probs`: distribution function
#' - `survival`: survival function
#' - `hazard` : hazard function
#'
#' By default the `y` aesthetic is mapped to `stat(density)`
#'
#' @inheritParams ggplot2::stat_density
#' @param n numbe of points for the density estimation (larger == smoother)
#' @param max_knots the maximum number of knots. The routine stops adding knots when
#'        this number of knots is reached. The method has an automatic rule for selecting
#'        maxknots if this parameter is not specified.
#' @param n_knots forces the method to start with nknots knots. The method has an automatic
#'        rule for selecting nknots if this parameter is not specified.
#' @param min_d minimum distance, in order statistics, between knots.
#' @param error_action see `error.action` in [logspline::plot.logspline()]
#' @export
#' @examples
#' library(ggplot2)
#'
#' set.seed(1)
#' data.frame(
#'   val = rnorm(100)
#' ) -> xdf
#'
#' ggplot(xdf) + stat_logspline(aes(val))
stat_logspline <- function(mapping = NULL, data = NULL, geom = "area",
                           position = "identity", na.rm = FALSE, show.legend = NA,
                           inherit.aes = TRUE,
                           # our custom params
                           n = 100, max_knots = 0, n_knots = 0, min_d = -1, error_action = 2,
                           ...) {

  layer(
    stat = StatLogspline,
    data = data,
    mapping = mapping,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      # pass on our fancy custom params
      n = n,
      max_knots = max_knots,
      n_knots = n_knots,
      error_action = error_action,
      ...
    )
  )

}