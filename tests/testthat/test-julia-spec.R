test_that("a distspec distribution renders as the prior it stands for", {
  expect_identical(as_julia(Normal(0, 1)), "Normal(0.0, 1.0)")
  expect_identical(
    as_julia(list(Normal(0, 1), HalfNormal(2))),
    "[Normal(0.0, 1.0), HalfNormal(2.0)]"
  )
  # A prior with a maximum is truncated, which is how Julia bounds support
  expect_identical(
    as_julia(Gamma(shape = 2, rate = 1, max = 10)),
    "truncated(Gamma(2.0, 1.0), -Inf, 10.0)"
  )
  expect_error(
    as_julia(LogNormal(meanlog = Normal(1, 0.2), sdlog = 0.4, max = 15)),
    "must be fixed"
  )
})

test_that("innovation slots are written with the Julia name they have", {
  ar <- AR(epsilon_t = HierarchicalNormal())
  expect_identical(as_julia(ar), "AR(; \u03f5_t = HierarchicalNormal())")
  expect_identical(
    as_julia(ar, ascii = TRUE),
    "AR(; (Symbol(\"\\u03f5_t\") => HierarchicalNormal(),)...)"
  )
})

test_that("printing breaks a long model over lines", {
  model <- IDModel(
    Renewal(generation_time = Gamma(shape = 6.5, scale = 0.62), rt = AR()),
    NegativeBinomialError(cluster_factor = HalfNormal(0.1))
  )
  lines <- format(model)
  expect_gt(length(lines), 1)
  expect_true(all(nchar(lines) <= 78))
  expect_output(print(model), "<julia model spec>")
  expect_output(print(HalfNormal(0.1)), "HalfNormal\\(0.1\\)")
})
