# Build HTML with lwarp (isolated, clean workspace)

```bash
cd /home/gull/Schreibtisch/Latex-notes
chmod +x build_html.sh
./build_html.sh dirac   # or omit 'dirac' to auto-pick the first .tex
```

What it does
- Copies the project into a temporary `.lwarp_build` directory and runs `lwarpmk html` there.
- Collects outputs into `dist/` (HTML, lwarp CSS themes, and any images), then removes the temp build dir.

Open the result
- Open `dist/dirac.html` in your browser (or the chosen basename).