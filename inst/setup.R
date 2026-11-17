#!/usr/bin/env Rscript

#' Script de configuració inicial per Comenta
#'
#' Verifica dependencies i configura l'entorn

cat("\n")
cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                   COMENTA - SETUP                         ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n")
cat("\n")

# Verificar R packages
cat("📦 Verificant paquets R...\n")
required_packages <- c("shiny", "bs4Dash", "DT", "jsonlite", "httr",
                       "shinyjs", "RSQLite", "DBI", "reticulate")

missing <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing) > 0) {
  cat("   ❌ Falten paquets:", paste(missing, collapse = ", "), "\n")
  cat("   Instal·lant...\n")
  install.packages(missing)
} else {
  cat("   ✅ Tots els paquets R instal·lats\n")
}

# Verificar Python
cat("\n🐍 Verificant Python...\n")
python_ok <- tryCatch({
  reticulate::py_config()
  TRUE
}, error = function(e) {
  cat("   ❌ Python no trobat\n")
  FALSE
})

if (python_ok) {
  cat("   ✅ Python trobat\n")

  # Verificar PyMuPDF
  pymupdf_ok <- tryCatch({
    reticulate::py_module_available("fitz") || reticulate::py_module_available("pymupdf")
  }, error = function(e) FALSE)

  if (pymupdf_ok) {
    cat("   ✅ PyMuPDF instal·lat\n")
  } else {
    cat("   ⚠️  PyMuPDF no trobat (necessari per run_pdf())\n")
    cat("      Instal·la amb: pip3 install PyMuPDF\n")
  }
}

# Verificar Ollama (opcional)
cat("\n🤖 Verificant Ollama (opcional)...\n")
ollama_ok <- tryCatch({
  response <- httr::GET("http://localhost:11434/api/tags", timeout = 2)
  httr::status_code(response) == 200
}, error = function(e) FALSE)

if (ollama_ok) {
  cat("   ✅ Ollama disponible\n")

  # Llistar models
  tryCatch({
    response <- httr::GET("http://localhost:11434/api/tags")
    models_data <- httr::content(response, "parsed")
    if (length(models_data$models) > 0) {
      cat("   📋 Models instal·lats:\n")
      for (model in models_data$models) {
        cat("      -", model$name, "\n")
      }
    } else {
      cat("   ⚠️  Cap model instal·lat. Instal·la amb:\n")
      cat("      ollama pull qwen2.5:7b\n")
    }
  }, error = function(e) {})
} else {
  cat("   ℹ️  Ollama no disponible (opcional)\n")
  cat("      Instal·la des de: https://ollama.ai\n")
}

# Verificar Gemini API Key (opcional)
cat("\n🔑 Verificant Gemini API Key (opcional)...\n")
gemini_key <- Sys.getenv("GEMINI_API_KEY")

if (gemini_key != "" && nchar(gemini_key) > 10) {
  cat("   ✅ GEMINI_API_KEY configurada\n")
} else {
  cat("   ℹ️  GEMINI_API_KEY no configurada (opcional)\n")
  cat("      Afegeix al .Renviron:\n")
  cat("      GEMINI_API_KEY=la_teva_clau\n")
}

# Resum final
cat("\n")
cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                   CONFIGURACIÓ COMPLETA                   ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("🚀 Per començar:\n")
cat("\n")
cat("   library(Comenta)\n")
cat("   run_colab()    # App col·laborativa\n")
cat("   run_pdf()      # App PDFs\n")
cat("   run_grafics()  # App gràfics\n")
cat("   run_public()   # App HTMLs\n")
cat("\n")
cat("📚 Documentació: ?Comenta\n")
cat("🐛 Issues: https://github.com/idisba/Comenta/issues\n")
cat("\n")
