# Tests per verificar que les apps existeixen i es poden carregar

test_that("App colab existeix i té app.R", {
  app_dir <- system.file("colab", package = "Comenta")
  expect_true(dir.exists(app_dir))
  expect_true(file.exists(file.path(app_dir, "app.R")))
})

test_that("App pdf existeix i té app.R", {
  app_dir <- system.file("pdf", package = "Comenta")
  expect_true(dir.exists(app_dir))
  expect_true(file.exists(file.path(app_dir, "app.R")))
})

test_that("App grafics existeix i té app.R", {
  app_dir <- system.file("grafics", package = "Comenta")
  expect_true(dir.exists(app_dir))
  expect_true(file.exists(file.path(app_dir, "app.R")))
})

test_that("App public existeix i té app.R", {
  app_dir <- system.file("public", package = "Comenta")
  expect_true(dir.exists(app_dir))
  expect_true(file.exists(file.path(app_dir, "app.R")))
})

test_that("Logo compartit existeix", {
  logo_path <- system.file("www", "comenta_logo.png", package = "Comenta")
  expect_true(file.exists(logo_path))
  expect_gt(file.size(logo_path), 1000) # Almenys 1KB
})

test_that("Script Python anotar_pdf.py existeix", {
  py_path <- system.file("python", "anotar_pdf.py", package = "Comenta")
  expect_true(file.exists(py_path))
  expect_gt(file.size(py_path), 100) # Almenys 100 bytes
})

test_that("Totes les apps tenen www/comenta_logo.png", {
  for (app in c("colab", "pdf", "grafics", "public")) {
    logo_path <- system.file(app, "www", "comenta_logo.png", package = "Comenta")
    expect_true(file.exists(logo_path), 
                info = paste("Logo no trobat a", app))
  }
})
