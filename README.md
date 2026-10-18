# Grappling Cave

Geschicklichkeitsspiel in Godot 4 für iOS: nur ein Grappling Hook, eine Höhle,
eine Stoppuhr.

## Auf dem Handy testen

Jeder Push auf `main` baut automatisch eine Web-Version (GitHub Actions,
`.github/workflows/pages.yml`) und veröffentlicht sie auf GitHub Pages:

**https://j4nric.github.io/Grappling-hook-app/**

- Link in Safari öffnen, Handy hochkant halten. Für Vollbild: Teilen →
  „Zum Home-Bildschirm“, dann über das Icon starten. Installiert läuft das
  Spiel auch offline (eigener Service Worker, `web/sw.js`); online kommt jeder
  neue Build sofort an. Achtung: Die installierte App hat eigene Bestzeiten,
  getrennt von Safari.
- Rechts oben steht `build <commit>`. Daran erkennst du, welche Version läuft.
  Ein neuer Build ist ca. 3–5 Minuten nach dem Push online (Status im Tab
  „Actions“). Zeigt das Spiel noch den alten Hash: Seite neu laden.
- Steuerung: Vom Spieler aus nach oben wischen = zielen (weiße Linie), loslassen =
  Haken werfen. Wie beim Pokéball zählt das Tempo kurz vor dem Loslassen:
  schnell schnippen = weiter, gerader Wurf; Finger stehen lassen = schwacher Wurf,
  der Haken fällt herunter. Der Haken zieht dich zum Treffpunkt; berührst du
  Wand oder Decke, löst sich das Seil von selbst. Seitlich wischen = seitlich
  werfen. Würde ein Wurf nicht halten (Eis, zu nah unter der Decke), wirft das
  Spiel automatisch flacher – die Ziellinie zeigt es vorher. Wirfst du, während
  dich ein Seil zieht, hält das alte Seil, bis der neue Haken greift (Kette).
  Greift der neue Haken kurz bevor das alte Seil loslässt, ist das ein
  **perfekter Kettenwurf**: Extra-Tempo, goldene Funken, „PERFECT“.
  Tippen = Seil lösen, zwei Finger halten (0,3 s) = Neustart, **II** = Pause.
- **TUNE** (rechts oben) öffnet Regler für Physik und Kamera. Das Spiel pausiert,
  „Play“ macht weiter. Die Werte bleiben im Browser gespeichert (pro Browser
  getrennt: Safari und Chrome haben eigene Werte), „Reset“ stellt die
  Standardwerte wieder her. **TUNE\*** mit Stern = Werte weichen vom Standard ab. Gute Werte per Screenshot an Claude geben, dann
  werden sie als neue Standardwerte übernommen. Noch einfacher: **Copy** kopiert
  alle veränderten Werte als Text, den du mir in den Chat einfügst.

Vorschau: Jeder offene Pull Request ist zusätzlich unter
`https://j4nric.github.io/Grappling-hook-app/preview/pr-<Nummer>/` spielbar
(Übersicht: `/preview/`). So lassen sich Experimente testen, ohne `main` zu ändern.

Inhalt: Tutorial und 8 Höhlen-Level (weite, hohe Hallen über einem Abgrund: Lava,
Eis-Decken, fahrende Blöcke, Eis-Tore, Aufwinde, brüchige Stalaktiten,
Tempo-Ringe, dunkle Hallen, offene Decken mit schwebenden Steinen in „Skyway“;
Arbeitslevel „Wide Cave“), dazu **Daily Cave** (jeden Tag eine neue, für alle
gleiche Höhle) und **Random Cave** (bei jeder Wahl neu). Medaillen, Bestzeiten,
Zwischenzeiten an Checkpoints, Geist der Bestzeit mit Abstand im HUD, **Replay**
der Bestzeit im Ziel, **Stats** im Level-Menü (Läufe, Meter, Haken, Flow,
Spielzeit, Kurve der Zielzeiten je Level), Flow-Zähler für Haken in Folge, Musik, die mit dem Tempo anzieht,
Höhlen-Hall, der sich nach der Hallengröße richtet, und Geräusche an ihren Orten
(Lava, Aufwind, Kristalle, Tropfen).
Gespielt wird mit einer Gelenkfigur mit Schal; das Seil hängt durch und
schlängelt sich zurück, bei einem Sturz fällt die Figur schlaff.
Pause (**II**): Medaillenziele, Geist und Ton an/aus, **Share run** (beste Zeit
als Text-Code kopieren und an Freunde schicken), **Load run** (Code einfügen:
der Lauf fährt als oranger Rivalen-Geist mit).
TUNE-Tabs: Throw, Rope, Move, Camera, Misc (Lautstärken, Debug-Anzeige mit FPS,
Auto-Qualität, Vibration, Hit-Stop, Speed-Lines) und **Cave** (Höhlen-Editor:
jede Halle des Levels ändern – Länge, Breite, Höhe, offene Decke, schwebende
Steine, Hindernisse – mit Skizzen; „Copy layout“ schickt das Ergebnis als Text).
Wertesätze **A/B/C** zum schnellen Vergleichen, **Paste** fügt kopierte Werte
wieder ein. Rekorde mit veränderten Werten werden mit * markiert.

Grafik, Sound und Musik sind komplett prozedural erzeugt (`tools/gen_*.py`).

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
