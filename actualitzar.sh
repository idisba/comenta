#!/bin/bash
# Script per actualitzar el paquet Comenta i reiniciar les apps del servidor

set -e

echo "🔄 Actualitzant paquet Comenta..."
echo ""

# Directori del paquet
PAQUET_DIR="/opt/shiny-server/samples/sample-apps/Comenta"
SERVIDOR_DIR="/opt/shiny-server/samples/sample-apps/comenta-server"

# Reinstal·lar paquet
cd "$PAQUET_DIR"
R --vanilla --quiet << 'EOF'
cat("📦 Reinstal·lant Comenta...\n")
devtools::install(".", quiet = TRUE, dependencies = FALSE)
cat("✅ Paquet reinstal·lat!\n")
EOF

echo ""
echo "🔄 Reiniciant apps del servidor Shiny..."

# Tocar restart.txt de cada app per forçar reinici
for app in colab pdf grafics public; do
  if [ -d "$SERVIDOR_DIR/$app" ]; then
    # Provar sense sudo primer
    if touch "$SERVIDOR_DIR/$app/restart.txt" 2>/dev/null; then
      echo "  ✅ $app reiniciat"
    else
      # Si falla, intentar amb sudo
      echo "  ⚠️  Cal sudo per reiniciar $app"
      sudo touch "$SERVIDOR_DIR/$app/restart.txt" 2>/dev/null && echo "  ✅ $app reiniciat amb sudo" || echo "  ❌ No s'ha pogut reiniciar $app"
    fi
  fi
done

echo ""
echo "✅ Tot actualitzat!"
echo ""
echo "Les apps estan disponibles a:"
echo "  • library(Comenta); run_colab() / run_pdf() / run_grafics() / run_public()"
echo "  • http://localhost:3838/shiny/sample-apps/comenta-server/colab/"
echo "  • http://localhost:3838/shiny/sample-apps/comenta-server/pdf/"
echo "  • http://localhost:3838/shiny/sample-apps/comenta-server/grafics/"
echo "  • http://localhost:3838/shiny/sample-apps/comenta-server/public/"
