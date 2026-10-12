test_that(".julia_project finds the bundled Julia project", {
  project <- .julia_project()
  expect_true(file.exists(file.path(project, "Project.toml")))
  expect_true(file.exists(file.path(project, "Manifest.toml")))
  expect_match(
    juliabridge::manifest_julia_version(project), "^[0-9]+\\.[0-9]+$"
  )
})

test_that("a fit loaded from disk says so rather than blaming Julia", {
  reloaded <- structure(
    list(
      generated = list(predicted_y_t = matrix(1:4, nrow = 2)),
      julia = list(handle = 1L, session = "session-token",
                   owner = new.env())
    ),
    class = "cidm_fit"
  )
  expect_error(predict(reloaded, horizon = 2), "loaded from disk")
  expect_identical(dim(predict(reloaded)), c(2L, 2L))
})

test_that("a fit says its Julia session has gone before setting Julia up", {
  fitted <- structure(
    list(
      generated = list(predicted_y_t = matrix(1:4, nrow = 2)),
      julia = list(handle = 1L, session = "session-token",
                   owner = .cidm_env, setup = .cidm_env$setup)
    ),
    class = "cidm_fit"
  )
  # A session that has gone leaves its token behind, so the handle still looks
  # owned. Without the probe this costs a full setup before Julia refuses.
  local_mocked_bindings(cidm_available = function() FALSE)
  expect_error(predict(fitted, horizon = 2), "has gone")
})

test_that("cidm_available() asks whether the Julia package is loaded", {
  # juliabridge decides whether the session is usable and clears the flag when
  # it is not; what belongs here is the question it is asked.
  asked <- NULL
  local_mocked_bindings(
    julia_alive = function(state_env, probe = NULL) {
      asked <<- probe
      FALSE
    },
    .package = "juliabridge"
  )
  expect_false(cidm_available())
  expect_identical(asked, "isdefined(Main, :composableIDModelR)")
})
