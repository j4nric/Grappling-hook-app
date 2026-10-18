# Roadmap

Detaillierte, priorisierte Aufgabenliste: `docs/next-steps.md` (Runde 3).
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

## M8 – Lebendige Höhle (Runde 3)
- [x] Licht-LOD und Sichtweiten (Leistung im Browser)
- [x] Gelenkfigur mit Posen, Schal, Seil als Verlet-Kette
- [x] Aufwind, brüchige Stalaktiten, Tempo-Ringe, dunkle Hallen, Level „Updraft“
- [x] Kamera-Regie (Decke, Ziel-Einstellung, Respawn-Blende)
- [x] Raumklang (Höhlen-Hall, 3D-Geräusche)
- [x] Replay der Bestzeit, Statistik
- [x] Installierbare Web-App, offline spielbar

## M9 – Fluss und Tuning (Runde 4)
- [x] Glatte Decke und Wände, weniger Hindernisse, Arbeitslevel „Wide Cave“
- [x] TUNE-Regler mit Klarname, Erklärung und animierter Skizze
- [x] Am Handy getunte Werte als Standard, höhere Regler-Grenzen

## M10 – Grund-Design der Level (Runde 5)
- [x] Seilende löst wie ein Zip, festes Test-Tuning für Mechanik-Tests
- [x] Neue Optik: Felsmodelle, Texturen (Moos, Adern, Wurzeln, Pilze, Bernstein), Deckenkristalle, Ausgangsmarken
- [x] Offene Decke mit schwebenden Steinen, Höhlen-Editor im TUNE-Panel mit Skizzen
- [x] Alle Level breiter und höher nach Hallen-Vorlagen, neues Level „Skyway“
- [x] Tuning-Sätze A/B/C und Einfügen, Läufe als Code teilen (Rivalen-Geist), Zielzeiten-Kurve
- [x] Sturz als Ragdoll, Nachhall je Halle, Leistungsmessung breiter Hallen

## M11 – Können, Abwechslung, Fortschritt (Runde 6)
- [x] Bot reproduzierbar, Bot sieht Tor-Schlitze, Medaillen neu gemessen
- [x] Perfekter Kettenwurf, Sprungpilze
- [x] Kurvige Höhlen, Abkürzungen, Level „Winding Rift“, Generator mit Kurven
- [x] Wasserfälle, Teilchen in der Luft je Halle, fließende Lava, Ausgang ins Tageslicht
- [x] Medaillen und Daily-Serie im Menü, Zwischenzeiten, Outfits, Backup/Restore
- [x] Shader aufwärmen, Engine aus dem Cache, game.gd aufgeteilt

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
| 2026-10-18 | `LightLod.max_lights` / `max_distance` | neu: 10 / 90 m | bis zu 42 Lichter pro Level; Software-Rendering 1,7× schneller |
| 2026-10-18 | `flight_rope_slack` | neu: 1,03 | Seil hängt beim fliegenden Haken leicht durch (1,1 hing bei 30 m fast 6 m durch) |
| 2026-10-18 | Eis-Emission | 0,8 → 0,3 | große Eisdecken überstrahlten zu weißen Flächen |
| 2026-10-18 | `wall_bounce` / `wall_kick_up` | neu: 0,2 / 4 m/s | Wall-Kick nur bei streifenden Treffern; 0,35 und frontaler Abprall warfen den Bot zurück |
| 2026-10-18 | Kamera `ceiling_near` / `ceiling_look_up` | neu: 7 m / 4 m | unter der Decke senkt sich die Kamera und blickt nach oben |
| 2026-10-18 | Aufwind `lift` / `max_rise` | neu: 46 / 20 m/s | trägt aus dem Stand nach oben, ohne den Haken zu ersetzen |
| 2026-10-18 | Brüchig `hold_time` | neu: 0,8 s | hält einen Zug, zwingt zur Kette |
| 2026-10-18 | Tempo-Ring `boost_speed` | neu: 44 m/s | knapp unter `max_speed` (50) |
| 2026-10-18 | Hindernisse | Stalaktiten ×0,5 und ≤ 8 m (vorher 13 m), Vorsprünge ×0,5, Säulen −1 | Feedback: zu viele Hindernisse, Flow leidet |
| 2026-10-18 | Decke/Wände | Kollision flach, Optik ±0,4 m rau | Feedback: Hängenbleiben an Deckenkanten |
| 2026-10-18 | Medaillen | neu kalibriert | Bot-Zeiten nach glatter Decke und weniger Hindernissen (Gold 0,85×, Silber 1,2×, Bronze 2×) |
| 2026-10-18 | Wurf | `throw_speed_per_px` 0,015 → 0,03, Haken 8–90 → 40–122 m/s, `hook_gravity` 25 → 3, `throw_pitch` 50 → 56°, `throw_yaw_gain` 1 → 1,3, `aim_preview_speed` 50 → 96 | vom Handy getunt: schnelle, fast gerade Würfe |
| 2026-10-18 | Wurf-Hilfen | `min_throw_reach` 14 → 28 m, `aim_assist_angle` 0 → 11°, `aim_time_scale` 1 → 0,3, `throw_buffer_time` 0,3 → 0,65 s, `max_rope_length` 70 → 68 m, `min_hook_distance` 3 → 5,25 m | vom Handy getunt |
| 2026-10-18 | Zug | `pull_impulse` 6 → 2, `reel_speed` 8 → 25,5, `reel_acceleration` 30 → 4, `reel_max_speed` 30 → 40, `tension_boost` 6 → 31,5, `min_rope_length` 0,5 → 9,25 m | vom Handy getunt: sofort kräftiger, gleichmäßiger Zug |
| 2026-10-18 | Lösen | `zip_release_distance` 2,5 → 5,5 m, `zip_boost` 3 → 0, `flyby_release_distance` 6 → 11,5 m, `contact_release_grace` 0,15 → 0 s | vom Handy getunt |
| 2026-10-18 | Bewegung | `gravity` 22 → 43, `floor_friction` 25 → 76, `slide_friction` 6 → 34,5, `landing_roll` 0,3 → 0,4, `deflect_keep` 1 → 0, `wall_bounce` 0,2 → 0,4, `wall_kick_up` 4 → 8 | vom Handy getunt: schwer und direkt |
| 2026-10-18 | Kamera/Effekte | FOV 65 → 61°, `fov_per_speed` 0,4 → 0,8, `max_fov` 90 → 113°, Abstand 10 → 10,5 m, `anchor_look_weight` 0,3 → 0,4, Neigung 1,2 → 1,0 (max 12 → 6°), Shake 0,35 → 0,8, Seil-Zittern 0,5 → 2, Durchhang 1,03 → 1,23, Wind-Streifen ab 34, Speed-Lines ab 45 m/s | vom Handy getunt |
| 2026-10-18 | Aufwind `lift` | 46 → 24 m/s² netto über der Schwerkraft | bei Schwerkraft 43 hob er kaum noch; jetzt unabhängig von der Schwerkraft |
| 2026-10-18 | Regler-Grenzen | höher, wo Werte am Anschlag waren (u. a. Wurfstärke 0,06, schwächster Wurf 80, Seil-Zittern 4) | Wunsch: mehr Spielraum nach oben |
| 2026-10-18 | Medaillen, `RUN_SPEED` 16 → 25 | neu kalibriert | Bot-Zeiten mit den neuen Werten |
| 2026-10-18 | `rope_end_release` | neu: 1 (an) | Seilende: am kürzesten Seil löst es wie ein Zip, statt hängen zu lassen (Kegelpendel); Medaillen neu kalibriert |
| 2026-10-18 | Emission | Farbe weiß → schwarz; Eis 0,3 → 0,8, Kristall 0,9 → 1,6 | Godot addiert Farbe und Textur: alles Leuchtende war fast weiß |
| 2026-10-18 | Level | alle nach Hallen-Vorlagen: 50–90 m breit (vorher 30–46), Decke 28–46 m (vorher 20–34), neues Level „Skyway“ | Entscheidung: Wide Cave als Vorlage für alle Level |
| 2026-10-18 | Medaillen, Zufallshöhlen-Bronze 1,65 → 2,1× | neu kalibriert (beste von 5 Bot-Starts) | breitere Level, Bot in sehr großen Hallen langsamer |
| 2026-10-18 | `perfect_chain_boost` / `_window` / `perfect_after_zip` | neu: 5 m/s, 6 m, 0,2 s | Perfekter Kettenwurf: Timing belohnen (Runde 6) |
| 2026-10-18 | Medaillen | Tutorial 8,2/11,6/19,4, First Swing 5,8/8,2/13,7, Ice Ceiling 8,6/12,1/20,2, Movers 7,0/9,9/16,6, Wide Cave 13,0/18,3/30,5, Gates 19,5/27,5/45,8, Skyway 11,4/16,0/26,7 | neu gemessen: Bot reproduzierbar, sieht Tor-Schlitze, bekommt den Perfekt-Schub |
| 2026-10-18 | Medaillen Winding Rift | neu: 25,9 / 36,6 / 61,0 | neues Level (beste Bot-Zeit 30,5 s) |
| 2026-10-18 | Medaillen Winding Rift | 25,9/36,6/61,0 → 23,2/32,8/54,6 | Bot in frischer Szene fand einen schnelleren Lauf (27,3 s) |
| 2026-10-18 | Medaillen Mushroom Grotto, Shortcut Run | neu: 18,8/26,5/44,2 und 26,1/36,8/61,3 | neue Level (Bot 22,1 s und 30,7 s) |
