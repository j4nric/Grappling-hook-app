# Roadmap

Detaillierte, priorisierte Aufgabenliste: `docs/next-steps.md`.

## M0 – Grauer Tunnel (erledigt mit diesem Gerüst)
- [x] Projekt, Autoload, Hauptszene
- [x] Spieler mit Schwerkraft, Raycast-Haken, Pendel-Constraint
- [x] Verfolgerkamera mit Lag und Tempo-FOV
- [x] Timer, Ziel, Absturz-Reset, Bestzeit (nur in der Session)
- [x] Maus und Touch über InputRouter
- [x] Web-Build per GitHub Actions → GitHub Pages zum Testen auf dem Handy
- [x] Zwei-Finger-Tipp = Neustart, Touch-Hinweise im HUD, Build-Version im HUD
- [x] Hochformat (720×1280)
- [x] Tuning-Panel mit Reglern zum Einstellen auf dem Handy

## M1 – Schwunggefühl (Ziel: 1–2 Wochen nur hier bleiben)
- [ ] Projekt in Godot öffnen, Script-Fehler beheben, erster Durchlauf
- [ ] Tuning-Werte in `player.gd` und `camera_rig.gd` so lange drehen, bis ein
      Durchlauf durch den Testtunnel Spaß macht
- [x] Wand-Clipping durch das direkte Setzen der Position beheben (Zug als Geschwindigkeit)
- [x] Haken ablehnen, wenn der Anker hinter der Figur liegt (Swipes nach unten werden verworfen)
- [ ] Kamera-Roll beim seitlichen Schwingen testen

## M2 – Wurf-Gefühl und Touch
- [x] Wischtempo → Wurfstärke (Pokéball-Wurf, siehe `docs/design.md`)
- [x] Sichtbar fliegender Haken mit Flugbahn statt Sofort-Raycast
- [x] Ziel-Vorschau während des Wischens
- [ ] Tap/Swipe-Schwellen auf echtem Gerät testen
- [x] Hoch-/Querformat entscheiden → Hochformat

## M3 – Optik
- [ ] Pixel-Look feinjustieren (Render-Scale, Palette, Dithering-Shader?)
- [ ] Einfaches Spielermodell und Seil mit Textur
- [ ] Licht: Fackeln/Kristalle, Nebel, Partikel-Trail

## M4 – Level und Speedrun
- [ ] 3–5 Level als eigene Szenen, Level-Auswahl
- [ ] Bestzeiten persistent speichern (`user://`)
- [ ] Medaillen-Zeiten pro Level
- [x] Sofort-Neustart-Geste (Zwei-Finger-Tipp)

## M5 – iOS
- [ ] Export nach `docs/ios-export.md`
- [ ] Performance auf dem Gerät (Ziel: 60 fps)
- [ ] TestFlight

## M6 – Juice
- [ ] Sound (Haken, Loslassen, Wind, Aufprall)
- [ ] Screenshake, Hit-Stop beim Einhaken
- [ ] Ghost der Bestzeit

## Tuning-Log

| Datum | Wert | vorher → nachher | Grund |
|---|---|---|---|
| 2026-10-17 | alle | Startwerte | noch ungetestet |
| 2026-10-17 | `reel_speed` | 4 → 10 | Haken soll spürbar zum Treffpunkt ziehen |
| 2026-10-17 | `tension_boost` | 2 → 6 | dito |
| 2026-10-17 | `min_rope_length` | 3 → 2,5 | näher an den Treffpunkt |
| 2026-10-17 | `min_rope_length` | 2,5 → 0,5 | Seil zieht bis an die Fläche; Lösen bei Wand-/Deckenkontakt statt Hängenbleiben |
| 2026-10-17 | Wurf-Werte | neu | `throw_speed_per_px` 0,015, Haken 8–70 m/s, `hook_gravity` 25, `throw_pitch` 50° |
