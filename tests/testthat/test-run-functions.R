# Tests per funcions run_*()

test_that("run_colab és una funció exportada", {
  expect_true("run_colab" %in% getNamespaceExports("Comenta"))
  expect_type(run_colab, "closure")
})

test_that("run_pdf és una funció exportada", {
  expect_true("run_pdf" %in% getNamespaceExports("Comenta"))
  expect_type(run_pdf, "closure")
})

test_that("run_grafics és una funció exportada", {
  expect_true("run_grafics" %in% getNamespaceExports("Comenta"))
  expect_type(run_grafics, "closure")
})

test_that("run_public és una funció exportada", {
  expect_true("run_public" %in% getNamespaceExports("Comenta"))
  expect_type(run_public, "closure")
})

test_that("run_colab accepta paràmetres port i launch.browser", {
  args <- names(formals(run_colab))
  expect_true("port" %in% args)
  expect_true("launch.browser" %in% args)
})

test_that("run_pdf accepta paràmetres port i launch.browser", {
  args <- names(formals(run_pdf))
  expect_true("port" %in% args)
  expect_true("launch.browser" %in% args)
})
