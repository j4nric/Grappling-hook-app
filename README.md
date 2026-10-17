# Grappling Cave

Geschicklichkeitsspiel in Godot 4 für iOS: nur ein Grappling Hook, eine Höhle,
eine Stoppuhr.

## Auf dem Handy testen

Jeder Push auf `main` baut automatisch eine Web-Version (GitHub Actions,
`.github/workflows/web.yml`) und veröffentlicht sie auf GitHub Pages:

**https://j4nric.github.io/Grappling-hook-app/**

- Link in Safari öffnen, Handy hochkant halten. Für Vollbild: Teilen →
  „Zum Home-Bildschirm“, dann über das Icon starten.
- Rechts oben steht `build <commit>`. Daran erkennst du, welche Version läuft.
  Ein neuer Build ist ca. 3–5 Minuten nach dem Push online (Status im Tab
  „Actions“). Zeigt das Spiel noch den alten Hash: Seite neu laden.
- Steuerung: Vom Spieler aus nach oben wischen = zielen (weiße Linie), loslassen =
  Haken werfen. Wie beim Pokéball zählt das Tempo kurz vor dem Loslassen:
  schnell schnippen = weiter, gerader Wurf; Finger stehen lassen = schwacher Wurf,
  der Haken fällt herunter. Der Haken zieht dich zum Treffpunkt; berührst du
  Wand oder Decke, löst sich das Seil von selbst.
  Tippen = Seil lösen, Zwei-Finger-Tipp = Neustart.
- **TUNE** (rechts oben) öffnet Regler für Physik und Kamera. Das Spiel pausiert,
  „Play“ macht weiter. Die Werte bleiben im Browser gespeichert (pro Browser
  getrennt: Safari und Chrome haben eigene Werte), „Reset“ stellt die
  Standardwerte wieder her. **TUNE\*** mit Stern = Werte weichen vom Standard ab. Gute Werte per Screenshot an Claude geben, dann
  werden sie als neue Standardwerte übernommen.

Einmalige Einrichtung: Repo → Settings → Pages → „Build and deployment“ →
Source: **GitHub Actions**.

## Lokal starten

1. Godot 4.7.2 installieren (gleiche Version wie im Web-Build): https://godotengine.org/download
2. Godot öffnen → "Importieren" → `project.godot` dieses Ordners wählen.
3. F5 (Projekt ausführen).

Steuerung am Desktop: Maus gedrückt ziehen = zielen, loslassen = Haken werfen,
Rechtsklick = Seil lösen, R = neu starten.

## Struktur

Siehe `CLAUDE.md` (Überblick und Konventionen) sowie `docs/`.
