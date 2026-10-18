# Roadmap

Detaillierte, priorisierte Aufgabenliste: `docs/next-steps.md` (Runde 2).
Runde 1 (2026-10-17, PRs #1–#12): Tests/CI, Vorschau-Builds, Zip-Launch, Wurf-Feedback,
Kamera, HUD, 5 Level, Speedrun, Optik, Sound, Debug/Auto-Qualität.
Runde 2 (2026-10-18, PRs #13–#24): Eingabe-/Timer-Bugs, Physik-Interpolation,
Kettenwürfe, Decken-Umlenkung/Landungen/Wall-Kick/Zerquetschen, Juice (Hit-Stop,
FOV-Kick, Speed-Lines, Flow), prozedurale Texturen und Materialbibliothek,
Kamera-Kollision, Kavernen-Baukasten mit neuen Leveln, Wurfwinkel-Hilfe,
prozedurale Daily/Random Caves, Zwischenzeiten/Geist-Delta/versionierte Rekorde,
Musik nach Tempo, Tutorial.

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
- [x] Pixel-Look feinjustieren (SubViewport mit Nearest-Filter)
- [x] Einfaches Spielermodell und Seil (Röhre)
- [x] Licht: Fackeln, Lava-Licht, Nebel, Partikel-Trail

## M4 – Level und Speedrun
- [x] 3–5 Level als eigene Szenen, Level-Auswahl
- [x] Bestzeiten persistent speichern (`user://`)
- [x] Medaillen-Zeiten pro Level
- [x] Sofort-Neustart-Geste (Zwei-Finger-Tipp)

## M5 – iOS
- [ ] Export nach `docs/ios-export.md`
- [ ] Performance auf dem Gerät (Ziel: 60 fps)
- [ ] TestFlight

## M6 – Juice
- [x] Sound (Haken, Loslassen, Wind, Aufprall)
- [x] Screenshake, Hit-Stop beim Einhaken
- [x] Musik, die mit dem Tempo intensiver wird
- [x] Speed-Lines, FOV-Kick, Flow-Zähler

## M7 – Höhle (Runde 2)
- [x] Prozedurale Texturen und Materialbibliothek
- [x] Kavernen-Baukasten, Level 1–5 als Hallen über dem Abgrund, Tutorial
- [x] Prozedurale Höhlen (Daily Cave, Random Cave)
- [x] Ghost der Bestzeit

## Tuning-Log

| Datum | Wert | vorher → nachher | Grund |
|---|---|---|---|
| 2026-10-17 | alle | Startwerte | noch ungetestet |
| 2026-10-17 | `reel_speed` | 4 → 10 | Haken soll spürbar zum Treffpunkt ziehen |
| 2026-10-17 | `tension_boost` | 2 → 6 | dito |
| 2026-10-17 | `min_rope_length` | 3 → 2,5 | näher an den Treffpunkt |
| 2026-10-17 | `min_rope_length` | 2,5 → 0,5 | Seil zieht bis an die Fläche; Lösen bei Wand-/Deckenkontakt statt Hängenbleiben |
| 2026-10-17 | Wurf-Werte | neu | `throw_speed_per_px` 0,015, Haken 8–70 m/s, `hook_gravity` 25, `throw_pitch` 50° |
| 2026-10-17 | `reel_speed` | 10 → 8 (Start) | Zug baut sich jetzt auf: `reel_acceleration` 30, `reel_max_speed` 30, `pull_impulse` 6 |
| 2026-10-17 | `zip_release_distance` | neu: 2,5 | Zip-Launch statt Aufprall; `zip_boost` 3 |
| 2026-10-17 | `floor_friction` | neu: 25 | kein endloses Rutschen am Boden |
| 2026-10-17 | Kamera-FOV | 75° vertikal → 65° horizontal (`max_fov` 105 → 90, `fov_per_speed` 0,5 → 0,4) | Hochformat zeigte seitlich zu wenig |
| 2026-10-17 | `look_ahead.y` | 1 → 2,5 | mehr Decke im Bild, man wirft nach oben |
| 2026-10-17 | `min_hook_distance` | neu: 3 | Haken direkt über dem Kopf schleuderte rückwärts (Bot-Test) |
| 2026-10-18 | `throw_cooldown` / `throw_buffer_time` | neu: 0,12 / 0,3 s | Doppel-Wisch fallen lassen, späteren Wisch puffern |
| 2026-10-18 | `flyby_release_distance` | neu: 6 m | am Anker vorbei = Zip statt Zurückschwingen |
| 2026-10-18 | `swing_time` | neu: 0 | Pendelphase kostet in Gängen 2–3× Zeit |
| 2026-10-18 | Medaillen | ~45 % schneller | Bot-Zeiten nach Ketten-/Vorbeiflug-Fixes |
| 2026-10-18 | `slide_friction` / `slide_speed` | neu: 6 / 8 m/s | Landungen rutschen weiter statt hart zu bremsen |
| 2026-10-18 | `landing_roll` | neu: 0,3 | 30 % der Fallgeschwindigkeit werden Vorwärtstempo |
| 2026-10-18 | `deflect_keep` / `deflect_min_speed` | neu: 1,0 / 8 m/s | Zip in die Decke: 38 → 24 m/s vorher, jetzt bleibt das Tempo entlang der Decke |
| 2026-10-18 | Juice | neu | `hit_stop_time` 0,05 s bei 0,05× ab 12 m/s, `zip_fov_kick` 12°, `rope_pluck` 0,5 m, Speed-Lines ab 28 m/s, Wind-Streifen ab 22 m/s |
| 2026-10-18 | `max_rope_length` | 45 → 70 m | Kavernen: Anker liegen weiter weg |
| 2026-10-18 | `hook_max_speed` / `aim_preview_speed` | 70 → 90 / 35 → 50 m/s | Decke 22–32 m hoch erreichbar |
| 2026-10-18 | Kamera `offset` / `look_ahead` | (0; 2,5; 7) → (0; 3,5; 10) / (0; 2,5; −8) → (0; 3; −12) | Spieler kleiner im Bild, Maßstab spürbar |
| 2026-10-18 | `min_throw_reach` / `min_throw_pitch` | neu: 14 m / 5° | Wurfwinkel-Hilfe unter der Decke und bei Eis |
| 2026-10-18 | Medaillen | neu kalibriert | Kavernen, beste von 3 Bot-Starts, Gold ≈ 0,85×, Silber ≈ 1,2×, Bronze ≈ 2× (Bot-Streuung) |
| 2026-10-18 | `wall_bounce` / `wall_kick_up` | neu: 0,2 / 4 m/s | Wall-Kick nur bei streifenden Treffern; 0,35 und frontaler Abprall warfen den Bot zurück |
