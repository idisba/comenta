# Guia per enviar a JOSS

## ✅ Fitxers creats:

1. **paper.md** - Article principal (ja creat)
2. **paper.bib** - Referències (ja creat)

---

## 📝 ABANS D'ENVIAR - Personalitzar:

### 1. Afegir el teu ORCID

Edita `paper.md` línia 11:

```yaml
    orcid: 0000-0000-0000-0000  # ← Canvia això!
```

**Obtenir ORCID:**
- Si no tens: https://orcid.org/register
- Si ja el tens: https://orcid.org/signin

**Format**: `0000-0002-1234-5678` (4 grups de 4 dígits)

### 2. Afegir co-autors (opcional)

Si hi ha més autors, afegeix més blocs:

```yaml
authors:
  - name: Josep Muncunill
    orcid: 0000-0002-XXXX-XXXX
    affiliation: 1
  - name: Altre Autor
    orcid: 0000-0003-XXXX-XXXX
    affiliation: 1
```

### 3. Afegir figura (opcional però recomanat)

Crea una captura de pantalla de l'app:

```bash
# Exemple: captura de l'app PDF
# Desa-la com: paper_screenshot.png
```

Després afegeix al `paper.md`:

```markdown
# Summary

[text actual...]

![Comenta PDF annotation interface showing sticky notes and AI interpretation.\label{fig:screenshot}](paper_screenshot.png)

The PDF annotation interface (Figure \ref{fig:screenshot}) demonstrates...
```

---

## 🚀 ENVIAR A JOSS:

### Pas 1: Commit els fitxers

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta

# Afegir fitxers JOSS
git add paper.md paper.bib
git commit -m "Add JOSS paper"
git push origin main
```

### Pas 2: Crear issue a JOSS

1. Ves a: **https://joss.theoj.org/papers/new**

2. Omple el formulari:
   - **Repository**: `https://github.com/idisba/comenta`
   - **Version**: `v0.1.0`
   - **Archive**: El DOI de Zenodo: `10.5281/zenodo.24310215`
   - **Editor**: (deixa en blanc, t'assignaran un)

3. Click **"Submit"**

### Pas 3: El procés de review

1. **Pre-review (~1 setmana)**:
   - Editor verifica requisits bàsics
   - Pot demanar canvis menors

2. **Review (~4-8 setmanes)**:
   - 2 reviewers assignats
   - Revisaran: codi, tests, documentació, paper
   - Et demanaran canvis via GitHub issues

3. **Revisions**:
   - Fas els canvis que et demanin
   - Fas commit i push
   - Comentes als issues

4. **Acceptació**:
   - Quan reviewers aproven → acceptat!
   - JOSS publica l'article
   - Tens DOI de l'article + citació oficial

---

## ✅ Checklist abans d'enviar:

- [ ] **ORCID actualitzat** al paper.md
- [ ] **Co-autors afegits** (si n'hi ha)
- [ ] **Figura/captura** afegida (opcional)
- [ ] **Tests passant**: `devtools::test()` → 36/36 ✅
- [ ] **README complet**: Ja fet ✅
- [ ] **Llicència OSI**: MIT ✅
- [ ] **DOI Zenodo**: 10.5281/zenodo.24310215 ✅
- [ ] **Commit i push**: paper.md + paper.bib
- [ ] **Release v0.1.0**: Ja publicat ✅

---

## 📋 Què revisaran:

### Codi:
- ✅ Funcionalitat (4 apps funcionen)
- ✅ Tests (36 tests passant)
- ✅ Documentació (README, man/)
- ✅ Instal·lació fàcil

### Paper:
- ✅ Summary clar
- ✅ Statement of need (per què cal)
- ✅ Referències correctes
- ✅ Cita a software usat

### Comunitat:
- ✅ CONTRIBUTING.md (opcional)
- ✅ CODE_OF_CONDUCT.md (opcional)
- ✅ Respon a issues/PRs

---

## 💡 Consells:

1. **Sigues responsive**: Respon ràpid als reviewers
2. **Documenta bé**: README clar = menys preguntes
3. **Tests són clau**: 36 tests et donen molta credibilitat
4. **Cita correctament**: Menciona PyMuPDF, Shiny, etc.

---

## ⏱️ Timeline estimat:

- **Setmana 1-2**: Pre-review, assignació d'editor
- **Setmana 3-10**: Review (2 reviewers)
- **Setmana 11-12**: Revisions finals
- **Setmana 12-14**: Acceptació i publicació

**Total: ~3 mesos** ⏳

---

## 📞 Suport:

Si tens dubtes durant el procés:
- **JOSS docs**: https://joss.readthedocs.io/
- **JOSS Slack**: https://joss.slack.com/
- **Email**: joss@theoj.org

---

## 🎉 Després de l'acceptació:

JOSS et donarà:
- **DOI de l'article**: `10.21105/joss.XXXXX`
- **Citació BibTeX**
- **Badge per README**:
  ```markdown
  [![JOSS](https://joss.theoj.org/papers/10.21105/joss.XXXXX/status.svg)](https://joss.theoj.org/papers/10.21105/joss.XXXXX)
  ```

---

**Ara edita el teu ORCID al paper.md i enviem-ho! 🚀**
