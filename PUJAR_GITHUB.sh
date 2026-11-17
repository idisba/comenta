#!/bin/bash
# Script per pujar Comenta a GitHub
# Executa pas a pas seguint les instruccions

set -e

echo "🚀 ============================================="
echo "   PUJAR COMENTA A GITHUB"
echo "   ============================================="
echo ""

# Verificar que estem al directori correcte
if [ ! -f "DESCRIPTION" ]; then
  echo "❌ Error: No estàs al directori de Comenta"
  exit 1
fi

echo "📋 Pas 1: Crear repositori a GitHub"
echo "   1. Ves a: https://github.com/organizations/idisba/repositories/new"
echo "   2. Repository name: Comenta"
echo "   3. Description: Collaborative Scientific Document Annotation with AI"
echo "   4. Visibility: Public ✅"
echo "   5. Initialize: ❌ NO (ja tens README)"
echo "   6. Click 'Create repository'"
echo ""
read -p "Has creat el repositori? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Crea el repositori primer i torna a executar aquest script"
  exit 1
fi

echo ""
echo "📤 Pas 2: Afegir remote i pujar"

# Verificar si ja té remote
if git remote | grep -q "origin"; then
  echo "⚠️  Remote 'origin' ja existeix. Eliminant..."
  git remote remove origin
fi

# Afegir remote
git remote add origin https://github.com/idisba/Comenta.git
echo "✅ Remote afegit"

# Push
echo ""
echo "🔐 Si et demana credencials:"
echo "   Username: el teu username de GitHub"
echo "   Password: usa un Personal Access Token, NO la password"
echo "   (Crea'l a: https://github.com/settings/tokens)"
echo ""
read -p "Prem Enter per continuar amb el push..."

git push -u origin main

echo ""
echo "✅ Codi pujat a GitHub!"
echo ""

echo "📦 Pas 3: Crear tag de versió"
git tag -a v0.1.0 -m "Comenta v0.1.0 - Initial release

Features:
- 4 Shiny apps (colab, pdf, grafics, public)
- AI integration (Gemini + Ollama)
- 36 automated tests
- Complete documentation
"
git push origin v0.1.0
echo "✅ Tag v0.1.0 creat i pujat"

echo ""
echo "🎉 ============================================="
echo "   GITHUB CONFIGURAT!"
echo "   ============================================="
echo ""
echo "📍 Repositori: https://github.com/idisba/Comenta"
echo ""
echo "🏷️  Següents passos per obtenir DOI:"
echo "   1. Ves a https://zenodo.org (login amb GitHub)"
echo "   2. Click 'GitHub' a la barra superior"
echo "   3. Activa el toggle per 'idisba/Comenta'"
echo "   4. Ves a https://github.com/idisba/Comenta/releases"
echo "   5. Click 'Draft a new release'"
echo "   6. Choose tag: v0.1.0"
echo "   7. Title: Comenta v0.1.0 - Initial Release"
echo "   8. Description: (copia de STATUS_PUBLICACIO.md)"
echo "   9. Click 'Publish release'"
echo "   10. Zenodo crearà automàticament el DOI!"
echo ""
echo "📖 Veure GITHUB_SETUP.md per més detalls"
