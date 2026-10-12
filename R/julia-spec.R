# Models are held in R as lazy specifications and rendered to Julia source
# only when they are simulated from or fitted. Both the specification and the
# rendering come from juliabridge; this package supplies the roles its
# specifications carry and renders distspec distributions.

# Descriptions of the roles used in error messages. juliabridge names the role
# itself where the package gives no description.
.role_labels <- c(
  distribution = "a distribution (e.g. `Normal()`)",
  latent = "a latent model (e.g. `RandomWalk()`)",
  infection = "an infection model (e.g. `Renewal()`)",
  observation = "an observation model (e.g. `PoissonError()`)",
  model = "a composed model (from `IDModel()`)",
  code = "Julia code from `julia()`"
)

#' @importFrom juliabridge julia_spec
#' @export
juliabridge::julia_spec

#' @importFrom juliabridge julia
#' @export
juliabridge::julia

#' @importFrom juliabridge as_julia
#' @export
juliabridge::as_julia

#' Check that an argument is a specification of the given role(s)
#'
#' @param x Object to check.
#' @param roles Character vector of accepted roles.
#' @param null_ok Logical. Whether `NULL` is accepted.
#' @param arg_name Name used in error messages.
#' @return Invisibly `TRUE`.
#' @keywords internal
.assert_role <- function(x, roles, null_ok = FALSE,
                         arg_name = deparse(substitute(x))) {
  juliabridge::assert_role(
    x, roles,
    null_ok = null_ok, arg_name = arg_name, labels = .role_labels
  )
}

#' Render a distspec distribution as Julia code
#'
#' A distribution outside a model slot, as in [as_julia()], is read as a
#' prior, which is what a distribution written on its own is in a model.
#'
#' @param x A distspec distribution.
#' @param ... Unused.
#' @return A specification of the Julia distribution.
#' @importFrom juliabridge as_julia_value
#' @export
as_julia_value.dist_spec <- function(x, ...) {
  .as_prior(x)
}
