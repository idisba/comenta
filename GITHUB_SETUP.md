# Configuració GitHub i DOI per Comenta

## ✅ Completat Localment

1. ✅ **Tests automàtics** amb testthat
   - 36 tests passant
   - Cobertura: funcions helper, apps, run_*()
   
2. ✅ **CI/CD** amb GitHub Actions
   - Workflow R-CMD-check configurat
   - Prova en Ubuntu, Windows, macOS
   
3. ✅ **Git repository** inicialitzat
   - Commit inicial fet
   - Branca: main
   - 60 fitxers versionats
   
4. ✅ **CITATION.cff** creat
   - Format estàndard per citacions acadèmiques
   - Compatible amb GitHub i Zenodo
   
5. ✅ **.gitignore** configurat
   - Exclou fitxers temporals, logs, builds

## 📤 Següents Passos: Pujar a GitHub

### 1. Crear repositori a GitHub

Ves a: https://github.com/organizations/idisba/repositories/new

**Configuració:**
- **Repository name**: `Comenta`
- **Description**: `Collaborative Scientific Document Annotation with AI`
- **Visibility**: Public ✅
- **Initialize**: ❌ NO inicialitzis amb README/license (ja els tens)

### 2. Connectar repositori local amb GitHub

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta

# Afegir remote
git remote add origin https://github.com/idisba/Comenta.git

# Push inicial
git push -u origin main
```

Si et demana credencials, usa **Personal Access Token** (no password):
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Selecciona scopes: `repo` (tots)
4. Copia el token i usa'l com a password

### 3. Verificar que tot funciona

Després del push:
- ✅ Codi visible a https://github.com/idisba/Comenta
- ✅ GitHub Actions s'executarà automàticament
- ✅ Badge de CI/CD disponible

## 🏷️ Obtenir DOI amb Zenodo

### 1. Connectar GitHub amb Zenodo

1. Ves a https://zenodo.org (login amb GitHub)
2. Click "Upload" → "GitHub" a la barra superior
3. Troba "idisba/Comenta" i activa el toggle
4. Torna a GitHub

### 2. Crear release a GitHub

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta

# Crear tag de versió
git tag -a v0.1.0 -m "Comenta v0.1.0 - Initial release

Features:
- 4 Shiny apps (colab, pdf, grafics, public)
- AI integration (Gemini + Ollama)
- 36 automated tests
- Complete documentation
"

# Push del tag
git push origin v0.1.0
```

### 3. Publicar release a GitHub

1. Ves a https://github.com/idisba/Comenta/releases
2. Click "Draft a new release"
3. Choose tag: `v0.1.0`
4. Release title: `Comenta v0.1.0 - Initial Release`
5. Description:
   ```markdown
   ## Comenta v0.1.0 🎉
   
   Primera versió pública de Comenta: eina per anotació col·laborativa de documents científics amb IA.
   
   ### Funcionalitats
   
   - 📄 Anotació de PDFs amb PyMuPDF
   - 🌐 Anotació d'HTMLs amb auto-interpretació
   - 📊 Anotació de gràfics PNG
   - 👥 Mode col·laboratiu amb SQLite
   - 🤖 IA integrada: Gemini Flash + Ollama local
   
   ### Instal·lació
   
   ```r
   devtools::install_github("idisba/Comenta")
   library(Comenta)
   run_pdf()  # O run_colab(), run_grafics(), run_public()
   ```
   
   ### Documentació
   
   - README.md - Guia d'instal·lació i ús
   - DESENVOLUPAMENT.md - Guia per contribuïdors
   - 36 tests automàtics amb testthat
   ```
6. Click "Publish release"

### 4. Obtenir DOI de Zenodo

Després de publicar el release:
1. Zenodo detectarà automàticament el release
2. Crearà un arxiu permanent amb DOI
3. Veure el DOI a: https://zenodo.org/account/settings/github/
4. Format típic: `10.5281/zenodo.XXXXXXX`

### 5. Afegir DOI badge al README

Edita README.md i afegeix després de la línia de llicència:

```markdown
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)
```

Després:
```bash
git add README.md
git commit -m "Add Zenodo DOI badge"
git push
```

## 📝 Preparar Article JOSS

Després d'obtenir el DOI, pots preparar l'article per JOSS:

1. Crea `paper.md` a l'arrel del repositori
2. Inclou el DOI de Zenodo
3. Segueix plantilla JOSS: https://joss.readthedocs.io/en/latest/submitting.html
4. Envia a: https://joss.theoj.org/papers/new

## 🎯 Checklist Final

- [ ] Repositori creat a GitHub (idisba/Comenta)
- [ ] Codi pujat (`git push -u origin main`)
- [ ] GitHub Actions executant-se correctament
- [ ] Zenodo activat per al repositori
- [ ] Tag v0.1.0 creat i pujat
- [ ] Release v0.1.0 publicat a GitHub
- [ ] DOI obtingut de Zenodo
- [ ] DOI badge afegit al README
- [ ] README actualitzat amb link de instal·lació

## 📞 Suport

Per problemes o preguntes:
- Issues: https://github.com/idisba/Comenta/issues
- Email: bioinformatica@idisba.es
