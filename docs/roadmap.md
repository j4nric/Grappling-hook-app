# Roadmap

## M0 – Grauer Tunnel (erledigt mit diesem Gerüst)
- [x] Projekt, Autoload, Hauptszene
- [x] Spieler mit Schwerkraft, Raycast-Haken, Pendel-Constraint
- [x] Verfolgerkamera mit Lag und Tempo-FOV
- [x] Timer, Ziel, Absturz-Reset, Bestzeit (nur in der Session)
- [x] Maus und Touch über InputRouter
- [x] Web-Build per GitHub Actions → GitHub Pages zum Testen auf dem Handy
- [x] Zwei-Finger-Tipp = Neustart, Touch-Hinweise im HUD, Build-Version im HUD

## M1 – Schwunggefühl (Ziel: 1–2 Wochen nur hier bleiben)
- [ ] Projekt in Godot öffnen, Script-Fehler beheben, erster Durchlauf
- [ ] Tuning-Werte in `player.gd` und `camera_rig.gd` so lange drehen, bis ein
      Durchlauf durch den Testtunnel Spaß macht
- [ ] Wand-Clipping durch das direkte Setzen der Position beheben
- [ ] Haken ablehnen, wenn der Anker hinter der Figur liegt (verhindert Rückwärts-Schwünge)
- [ ] Kamera-Roll beim seitlichen Schwingen testen

## M2 – Wurf-Gefühl und Touch
- [ ] Wischtempo → Reichweite (siehe `docs/design.md`)
- [ ] Optional: sichtbar fliegender Haken statt Sofort-Raycast
- [ ] Tap/Swipe-Schwellen auf echtem Gerät testen
- [ ] Hoch-/Querformat entscheiden

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
