# Environment tracking Julia initialisation and fitted-model handles.
.cidm_env <- new.env(parent = emptyenv())

#' Locate the bundled Julia project
#'
#' @return Path to the directory holding `Project.toml`, `Manifest.toml` and
#'   the `composableIDModelR` Julia package.
#' @keywords internal
.julia_project <- function() {
  project <- system.file("julia", package = "composableIDModelR")
  if (!nzchar(project) || !file.exists(file.path(project, "Project.toml"))) {
    # Development load (pkgload::load_all) from the source tree.
    project <- file.path(getwd(), "inst", "julia")
  }
  project
}

#' Set up Julia for composableIDModelR
#'
#' Installs the pinned Julia dependencies of composableIDModelR
#' (ComposableTuringIDModels.jl, Turing.jl and their dependencies) and starts
#' a Julia session with them loaded. This happens automatically on first use,
#' so it only needs calling directly to see progress or to troubleshoot.
#'
#' If [juliaup](https://github.com/JuliaLang/juliaup) is available, the Julia
#' version the dependencies were resolved with is installed and used.
#' Otherwise the Julia on the `PATH` (or in `JULIA_BINDIR`) is used, which
#' must be new enough for the bundled `Manifest.toml`. Set the
#' environment variable `JULIA_NUM_THREADS` before Julia starts to sample MCMC
#' chains in parallel.
#'
#' The first call can take several minutes while Julia packages are installed
#' and precompiled.
#'
#' @param verbose Logical. If `TRUE`, prints progress messages.
#' @return Invisibly `TRUE` on success.
#'
#' @examples
#' \dontrun{
#' cidm_setup_julia()
#' }
#' @export
cidm_setup_julia <- function(verbose = TRUE) {
  if (cidm_available()) {
    return(invisible(TRUE))
  }
  project <- .julia_project()
  version <- juliabridge::manifest_julia_version(project)
  if (!is.null(version) && !nzchar(Sys.getenv("JULIACONNECTOR_JULIABIN"))) {
    bin <- juliabridge::juliaup_julia(version, verbose)
    if (!is.null(bin)) Sys.setenv(JULIACONNECTOR_JULIABIN = bin)
  }

  juliabridge::julia_ready(
    packages = c("ComposableTuringIDModels", "Distributions",
                 "composableIDModelR"),
    state_env = .cidm_env,
    project = project,
    verbose = verbose
  )

  if (verbose) message("composableIDModelR Julia backend ready")
  invisible(TRUE)
}

#' Check whether the Julia backend is running
#'
#' @return Logical. `TRUE` if Julia has been set up in this R session and the
#'   session still holds the Julia package.
#'
#' @examples
#' cidm_available()
#' @export
cidm_available <- function() {
  juliabridge::julia_alive(
    .cidm_env, "isdefined(Main, :composableIDModelR)"
  )
}

#' Call a bridge function, starting Julia if needed
#'
#' Releases the Julia objects of fits that R has garbage collected before
#' making the call. Releasing waits until here because finalisers may run
#' while another Julia call is in progress.
#'
#' @param fn Name of a function in the `composableIDModelR` Julia module.
#' @param ... Arguments passed to the function.
#' @return The translated result of the call.
#' @keywords internal
.bridge <- function(fn, ...) {
  if (!cidm_available()) cidm_setup_julia(verbose = FALSE)
  juliabridge::julia_release_pending(
    .cidm_env, "composableIDModelR.release!"
  )
  juliabridge::call_julia(paste0("composableIDModelR.", fn), ...)
}
