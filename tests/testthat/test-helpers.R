# Tests per funcions helper

test_that("ollama_disponible retorna TRUE o FALSE", {
  result <- ollama_disponible()
  expect_type(result, "logical")
  expect_length(result, 1)
})

test_that("ollama_llistar_models retorna character o NULL", {
  if (ollama_disponible()) {
    models <- ollama_llistar_models()
    expect_true(is.character(models) || is.null(models))
  } else {
    expect_null(ollama_llistar_models())
  }
})

test_that("ollama_model_recomanat retorna string vàlid", {
  model <- ollama_model_recomanat()
  expect_type(model, "character")
  expect_length(model, 1)
  expect_true(nchar(model) > 0)
})

test_that("gemini_disponible retorna TRUE o FALSE", {
  result <- gemini_disponible()
  expect_type(result, "logical")
  expect_length(result, 1)
})
