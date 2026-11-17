# Guia d'instal·lació de Comenta

## Mètode 1: Des de GitHub (Recomanat)

### Pas 1: Instal·lar devtools

```r
install.packages("devtools")
```

### Pas 2: Instal·lar Comenta

```r
devtools::install_github("idisba/Comenta")
```

### Pas 3: Verificar instal·lació

```r
library(Comenta)

# Executar script de verificació
source(system.file("setup.R", package = "Comenta"))
```

### Pas 4: Provar una aplicació

```r
# Aplicació més simple (sense dependencies Python)
run_grafics()

# O qualsevol altra
run_colab()
run_pdf()      # Requereix Python + PyMuPDF
run_public()
```

---

## Mètode 2: Des de fitxers locals

Si tens el codi font localment:

```r
# Des del directori pare
devtools::install("Comenta")

# O amb dependències actualitzades
devtools::install("Comenta", dependencies = TRUE)
```

---

## Configuració Python (per run_pdf)

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install python3 python3-pip
pip3 install PyMuPDF
```

### macOS

```bash
brew install python3
pip3 install PyMuPDF
```

### Windows

1. Descarrega Python de https://www.python.org/downloads/
2. Marca "Add Python to PATH"
3. Obre CMD:

```cmd
pip install PyMuPDF
```

### Verificar

```r
reticulate::py_module_available("fitz")  # Ha de retornar TRUE
```

---

## Configuració IA

### Gemini (API Cloud)

1. Obté API Key: https://makersuite.google.com/app/apikey
2. Configura al .Renviron:

```bash
# Obrir fitxer
usethis::edit_r_environ()

# Afegir línia
GEMINI_API_KEY=la_teva_clau_aqui
```

3. Reinicia R

### Ollama (Local, privat)

1. Instal·la Ollama: https://ollama.ai
2. Descarrega un model:

```bash
ollama pull qwen2.5:7b    # Recomanat
# o
ollama pull llama3.2      # Alternativa
```

3. Verifica:

```bash
ollama list
```

---

## Solució de problemes

### "No s'ha trobat l'aplicació"

```r
# Verificar que el paquet està instal·lat
library(Comenta)

# Verificar ubicació
system.file("colab", package = "Comenta")
```

### "PyMuPDF no trobat"

```r
# Verificar Python
reticulate::py_config()

# Instal·lar PyMuPDF
system("pip3 install PyMuPDF")

# Forçar Python específic
reticulate::use_python("/usr/bin/python3", required = TRUE)
```

### "Gemini API error"

```r
# Verificar clau
Sys.getenv("GEMINI_API_KEY")  # No ha de ser ""

# Configurar manualment
Sys.setenv(GEMINI_API_KEY = "la_teva_clau")
```

### "Ollama no disponible"

```bash
# Verificar servei
curl http://localhost:11434/api/tags

# Si no funciona, iniciar Ollama
ollama serve
```

---

## Desinstal·lar

```r
remove.packages("Comenta")
```

---

## Actualitzar

```r
# Des de GitHub
devtools::install_github("idisba/Comenta", force = TRUE)

# Des de fitxers locals
devtools::install("Comenta", force = TRUE)
```

---

## Suport

- 📧 Email: bioinformatica@idisba.es
- 🐛 Issues: https://github.com/idisba/Comenta/issues
- 📚 Documentació: `?Comenta`
