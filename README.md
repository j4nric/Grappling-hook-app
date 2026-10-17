# Grappling Cave

Geschicklichkeitsspiel in Godot 4 für iOS: nur ein Grappling Hook, eine Höhle,
eine Stoppuhr.

## Auf dem Handy testen

Jeder Push auf `main` baut automatisch eine Web-Version (GitHub Actions,
`.github/workflows/web.yml`) und veröffentlicht sie auf GitHub Pages:

**https://j4nric.github.io/Grappling-hook-app/**

- Link in Safari öffnen, Handy quer halten. Für Vollbild: Teilen →
  „Zum Home-Bildschirm“, dann über das Icon starten.
- Rechts oben steht `build <commit>`. Daran erkennst du, welche Version läuft.
  Ein neuer Build ist ca. 3–5 Minuten nach dem Push online (Status im Tab
  „Actions“). Zeigt das Spiel noch den alten Hash: Seite neu laden.
- Steuerung: Wischen = Haken, Tippen = loslassen, Zwei-Finger-Tipp = Neustart.

Einmalige Einrichtung: Repo → Settings → Pages → „Build and deployment“ →
Source: **GitHub Actions**.

## Lokal starten

1. Godot 4.7.2 installieren (gleiche Version wie im Web-Build): https://godotengine.org/download
2. Godot öffnen → "Importieren" → `project.godot` dieses Ordners wählen.
3. F5 (Projekt ausführen).

Steuerung am Desktop: Linksklick = Haken werfen, Rechtsklick = loslassen,
R = neu starten. Auf dem Handy: Wischen = Haken, Tippen = loslassen,
Zwei-Finger-Tipp = neu starten.

## Struktur

Siehe `CLAUDE.md` (Überblick und Konventionen) sowie `docs/`.
