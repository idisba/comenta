#!/usr/bin/env Rscript

#' Quick Start Script per desenvolupadors
#'
#' Ejecuta aquest script per provar el paquet localment
#' sense haver-lo d'instal·lar cada vegada

# Carregar funcions del paquet (dev mode)
devtools::load_all(".")

cat("\n")
cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║              COMENTA - QUICK START (DEV)                  ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("📦 Paquet carregat en mode desenvolupament\n")
cat("\n")
cat("🚀 Funcions disponibles:\n")
cat("   run_colab()      # App col·laborativa\n")
cat("   run_pdf()        # App PDFs\n")
cat("   run_grafics()    # App gràfics\n")
cat("   run_public()     # App HTMLs\n")
cat("\n")
cat("🔧 Comandes útils:\n")
cat("   devtools::document()  # Generar documentació\n")
cat("   devtools::check()     # Verificar paquet\n")
cat("   devtools::test()      # Executar tests\n")
cat("\n")

# Preguntar quina app executar
cat("❓ Quina app vols executar?\n")
cat("   1 - Colab (col·laborativa)\n")
cat("   2 - PDF (anotació PDFs)\n")
cat("   3 - Gràfics (anotació PNG)\n")
cat("   4 - Public (anotació HTMLs)\n")
cat("   0 - Sortir\n")
cat("\n")

opcio <- readline("Tria (1-4, 0 per sortir): ")

switch(opcio,
  "1" = {
    cat("\n🚀 Llançant run_colab()...\n\n")
    run_colab()
  },
  "2" = {
    cat("\n🚀 Llançant run_pdf()...\n\n")
    run_pdf()
  },
  "3" = {
    cat("\n🚀 Llançant run_grafics()...\n\n")
    run_grafics()
  },
  "4" = {
    cat("\n🚀 Llançant run_public()...\n\n")
    run_public()
  },
  "0" = {
    cat("\n👋 Fins aviat!\n\n")
  },
  {
    cat("\n❌ Opció no vàlida\n\n")
  }
)
