# Instal·lació de Python i PyMuPDF

## Per l'aplicació de PDFs

L'aplicació `run_pdf()` requereix Python 3 amb PyMuPDF instal·lat.

### Ubuntu/Debian

```bash
# Instal·lar Python 3
sudo apt-get update
sudo apt-get install python3 python3-pip

# Instal·lar PyMuPDF
pip3 install PyMuPDF
```

### macOS

```bash
# Amb Homebrew
brew install python3

# Instal·lar PyMuPDF
pip3 install PyMuPDF
```

### Windows

1. Descarrega Python 3 de https://www.python.org/downloads/
2. Assegura't de marcar "Add Python to PATH" durant la instal·lació
3. Obre CMD i executa:

```cmd
pip install PyMuPDF
```

## Verificar instal·lació

```r
# A R
reticulate::py_module_available("fitz")  # TRUE si està instal·lat

# O des de terminal
python3 -c "import fitz; print('PyMuPDF OK')"
```

## Solució de problemes

### "No module named 'fitz'"

```bash
# Reinstal·lar PyMuPDF
pip3 uninstall PyMuPDF
pip3 install PyMuPDF
```

### Python no trobat per reticulate

```r
# Especificar manualment el path de Python
reticulate::use_python("/usr/bin/python3", required = TRUE)
```

### Versions recomanades

- Python: >= 3.8
- PyMuPDF: >= 1.23.0

```bash
python3 --version
pip3 show PyMuPDF
```
