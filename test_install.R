# Script per instal·lar i provar Comenta
cat("\n🔧 INSTAL·LANT COMENTA...\n\n")

# Instal·lar
devtools::install(".", quiet = TRUE, upgrade = "never")

cat("✅ Comenta instal·lat!\n\n")

# Verificar
library(Comenta)
cat("📦 Paquet carregat\n\n")

# Mostrar funcions
cat("🚀 Funcions disponibles:\n")
cat("   run_colab()      # App col·laborativa\n")
cat("   run_pdf()        # App PDFs\n") 
cat("   run_grafics()    # App gràfics\n")
cat("   run_public()     # App HTMLs\n\n")

cat("💡 Per executar: run_grafics()\n\n")
