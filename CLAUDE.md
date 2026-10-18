# CLAUDE.md – Grappling Cave

Diese Datei ist der Einstiegspunkt für Claude Code. Lies sie vollständig, bevor du
Änderungen machst. Projektsprache: Doku und Commits auf Deutsch, Code, Kommentare
und Bezeichner auf Englisch.

## Was das Spiel ist

Ein Geschicklichkeitsspiel für iOS im Hochformat (Godot 4): Der Spieler hängt in einer 3D-Höhle,
kann nicht laufen und bewegt sich ausschließlich mit einem Grappling Hook vorwärts
durch einen Tunnel. Ziel ist, das Level so schnell wie möglich zu schaffen.
Ausführliches Design: `docs/design.md`. Meilensteine: `docs/roadmap.md`.
Priorisierte nächste Schritte und offene Entscheidungen: `docs/next-steps.md`.

Die drei Säulen, an denen jede Entscheidung gemessen wird:
1. **Schwunggefühl** – Pendeln muss sich schwer, schnell und kontrollierbar anfühlen
   (Vorbild: moderne Spider-Man-Spiele). Das ist das Spiel. Alles andere ist Beiwerk.
2. **Ein Finger** – Wischen zielt, Loslassen wirft den Haken; das Wischtempo kurz
   vor dem Loslassen bestimmt die Wurfstärke (wie ein Pokéball-Wurf in Pokémon GO).
   Tippen löst das Seil. Keine Buttons, kein Joystick (außer dem Debug-Button TUNE).
3. **Speedrun** – Timer, Bestzeit, Wiederspielbarkeit statt vieler Level.

## Stack und Konventionen

- Godot **4.7.2** (identisch mit `GODOT_VERSION` in `.github/workflows/pages.yml` und `ci.yml`),
  Renderer "Mobile" (nativ) bzw. "Compatibility" (Web-Build), GDScript mit statischer Typisierung
  (`var x := …`, Typhinweise bei Parametern und Rückgaben).
- Pixel-Look: Die 3D-Welt rendert in `World/PixelView` (SubViewportContainer,
  `stretch_shrink` = Pixelgröße, Nearest-Filter). Die Kamera darin kopiert die
  Kamera von `CameraRig`; der Root-Viewport zeichnet nur das HUD
  (`disable_3d`). Nicht in Scripts hartkodieren.
- Vorwärts in der Höhle ist **-Z**. Der Spieler startet bei z=0 auf einem Felsvorsprung
  (Oberkante y=0); darunter Abgrund, `kill_y` −30.
- **Level** sind Kavernen: `scenes/levels/*.tscn` ist nur ein `Level`-Knoten mit
  `segments` (eine Halle pro Dictionary: Länge, Breite, Deckenhöhe, Boden
  abyss/ground/lava, Stalaktiten, Säulen, Inseln, Kristalle, Lichtkegel, Eis, Tor,
  Mover, Checkpoint – Schlüssel und Standardwerte in
  `CavernBuilder.SEGMENT_DEFAULTS`) und `layout_seed`. `CavernBuilder` baut daraus beim
  Laden die Geometrie (Felsblöcke als MultiMesh je Halle und Material, Kollision je
  Halle in einem StaticBody). Gleicher Seed, gleiche Höhle. Reihenfolge in
  `scripts/levels.gd`. Hallen nutzen meist eine **Vorlage** (`"template"`:
  start, sprint, slalom, cathedral, narrows, skyway, lava_lake, ice_vault in
  `CavernBuilder.TEMPLATES`, nach dem Vorbild der Wide Cave breit und hoch),
  eigene Schlüssel gehen vor; `CavernBuilder.full_segment()` liefert die
  vollständige Halle. Medaillenzeiten aus der Bot-Zeit (`BOT_FULL=1 TEST_FILTER=test_levels`
  spielt alle fünf Startvarianten und gibt die beste aus; Gold 0,85×, Silber 1,2×,
  Bronze 2×; ohne `BOT_FULL` hört der Test beim ersten Lauf innerhalb Bronze auf).
  Der Bot ist chaotisch, aber reproduzierbar: `Bot.reset()` setzt den globalen
  Zufall (brüchige Stalaktiten wackeln mit `randf` am Kollisionskörper) und
  `TimeScale` zurück – gleicher Start, gleiche Zeit.
- **Prozedurale Höhlen** (`CaveGenerator`) nutzen denselben Baukasten; Rekorde gelten
  pro Art und Seed (`Records.key()`). `tests/test_procedural.gd` lässt den Bot mehrere
  Seeds spielen und gibt Bot-Zeit und Schätzung aus (Kalibrierung von `RUN_SPEED`).
- Level-Design-Regeln (gelernt beim Bauen): Übergänge zu niedrigeren/schmaleren
  Hallen sind schräg (sonst prallt man ab); Decken haben einen Deckel (keine Taschen
  zum Steckenbleiben); Boden-Hallen sind massiv bis in die Tiefe; Tore sind Eis mit
  senkrechtem Schlitz bis zur Decke und Felsinsel dahinter; wird die nächste
  Halle breiter oder höher, schließt ein Rahmen die Lücke um die kleinere
  Öffnung (sonst fliegt man hinter die Wände ins Leere); in Eis-Hallen garantiert
  `anchor_spacing` greifbare Stalaktiten. Neue Elemente im Baukasten dürfen den
  Zufallsstrom nur dort nutzen, wo sie vorkommen – sonst ändern sich alle
  bestehenden Höhlen (Rekorde, Medaillen). Decke und Wände sind nur optisch
  rau (`_shape`), ihre Kollision ist flach (`_solid`, `CEILING_ROUGHNESS`),
  damit man an keiner Kante hängen bleibt (`tests/test_flow.gd`). Wenig
  Hindernisse = besserer Flow: Stalaktiten sind kurz (`STALACTITE_MAX`), die
  ganze Decke hält den Haken. Arbeitslevel für das Grund-Design ist
  „Wide Cave“ (`level_07`, erster Eintrag in `Levels.LIST`). Offene Hallen
  (`open`) haben statt Decke ein fernes Gewölbe ohne Halt; man hangelt sich an
  schwebenden Steinen (`floater_spacing`) entlang, `slick_walls` macht die Wände
  glatt. Optik: Kollision als Quader (`_collider`/`_solid`), gezeichnet werden
  `RockMesh`-Modelle (`_model`); Deko (Wurzeln, Pilze, Deckenkristalle,
  Bernstein-Marke am Hallenausgang) würfelt mit eigenem Zufall (`_deco_rng`).
- Emission in Materialien: Godot **addiert** Emissionsfarbe und -textur –
  die Farbe bleibt schwarz, die Textur bestimmt das Leuchten (`tools/gen_textures.py`).
- Tuning-Werte sind `@export`-Variablen und werden im Inspector verändert, nicht
  im Code verstreut. Neue Stellschrauben ebenfalls als `@export` anlegen.
- Gameplay-Input läuft **ausschließlich** über das Autoload `InputRouter`
  (`scripts/input_router.gd`). Kein anderes Script liest `InputEvent` direkt.
  Ausnahme: GUI-Controls (Tuning-Panel) verarbeiten ihre eigenen Eingaben;
  Controls in der Gruppe `blocks_gameplay_input` schlucken Touches, damit sie
  keinen Haken auslösen.
- Szenen sind handgeschriebene `.tscn`-Textdateien; bleibe bei diesem Format und
  halte sie klein. UIDs fehlen absichtlich, Godot ergänzt sie beim ersten Öffnen.
  Die von Godot erzeugten `*.gd.uid`- und `*.import`-Dateien werden mit committet.
- Keine externen Addons ohne Rücksprache.
- Grafik ist prozedural: Texturen und Materialien kommen aus `tools/gen_textures.py`,
  Level-Geometrie nutzt nur Materialien aus `assets/materials/` (Welt-Triplanar,
  nahtlos). Texturen klein halten und verlustfrei importieren (kein VRAM-Format:
  iPhone-Browser können S3TC nicht).
- Leistung: Lichter im Level schaltet `LightLod` (nie selbst `visible`/`light_energy`
  von Level-Lichtern im Spiel setzen); Deko und Hallen haben eine Sichtweite
  (`visibility_range_end`, im Nebel unsichtbar). `tests/test_performance.gd` wacht
  darüber und über die Aufbauzeit.

## Dateiüberblick

| Pfad | Zweck |
|---|---|
| `project.godot` | Projekteinstellungen, Autoload, Render-Scale für Pixel-Look |
| `export_presets.cfg` | Export-Preset "Web" (ohne Threads, läuft auf GitHub Pages/iOS Safari) |
| `.github/workflows/pages.yml` | Web-Export + Deploy nach GitHub Pages: `main` unter `/`, jeder offene PR unter `/preview/pr-N/` |
| `.github/workflows/ci.yml` | Pull Requests: Tests + Probe-Export |
| `.github/workflows/test.yml` | Wiederverwendbarer Test-Job (von `ci.yml` und `pages.yml` genutzt) |
| `tools/export_web.sh` | Web-Export mit Versionsstempel und eindeutigem Paketnamen (Cache-Busting); kopiert `web/` dazu |
| `web/` | Installierbare Web-App: `manifest.webmanifest`, `sw.js` (Service Worker: Netz zuerst, offline aus dem Cache), Icons von `tools/gen_icon.py`; `.gdignore`, nicht im Godot-Paket |
| `scenes/main.tscn` | Hauptszene: Player + CameraRig + HUD + LevelMenu + Tuning; das Level lädt `game.gd` |
| `scenes/levels/level_*.tscn` | Level als Layout (`segments`, `layout_seed`, Medaillen, Tutorial-`hints`); gebaut von `CavernBuilder` |
| `scripts/cave_generator.gd` | `CaveGenerator`: prozedurale Höhle aus einem Seed (faire Hallenfolge, Medaillen aus Zeitschätzung); „Daily Cave“ (Seed = Datum) und „Random Cave“ |
| `scripts/levels.gd` | `Levels`: feste Level (`LIST`) plus prozedurale Pfade `cave://daily/<seed>`, `cave://random/<seed>`; `Levels.instantiate(path)` |
| `scripts/level_menu.gd` | Level-Auswahl (pausiert das Spiel) |
| `scripts/pause_menu.gd` | Pause-Knopf und -Menü (Medaillenziele, Weiter/Neustart/Level, Geist/Ton, „Share run“/„Load run“), öffnet bei Fokusverlust |
| `scripts/run_code.gd` | `RunCode`: Lauf als Text-Code `GC1:<Level>@<Version>:<ms>:<Daten>` (5-cm-Raster, Deflate, Base64; ~1–2 KB); ein geladener Code wird zum orangen Rivalen-Geist (`Rival` in `main.tscn`, `Records.save_rival()`) |
| `scripts/clipboard.gd` | `Clipboard`: Kopieren/Einfügen; im Browser auf `button_down` scharf gestellt und im `touchend` ausgeführt (iOS), Einfügen per Browser-Dialog, Ergebnis per `take_paste()` |
| `scripts/sparkline.gd` | `Sparkline`: Kurve der Zielzeiten eines Levels (Statistik), Gold = Bestzeit bis dahin |
| `scripts/records.gd` | `Records`: Bestzeit, Zwischenzeiten, TUNE*-Markierung und Ghost pro Level-Version (`Records.id()` = Schlüssel + Layout-Hash) in `user://` |
| `scripts/settings.gd` | `Settings`: Geist und Ton an/aus (Pause-Menü), in `user://settings.cfg` |
| `scripts/effects.gd` | Partikel: Funken beim Einhaken, Staub bei harter Landung, Zip-Burst, Tempo-Spur |
| `scripts/music.gd` | Musik: drei synchrone Spuren (`AudioStreamSynchronized`), Puls und Arpeggio nach Tempo und Flow; Spuren von `tools/gen_music.py` (QOA-komprimiert, nahtlos) |
| `scripts/sfx.gd` | Soundeffekte aus Player-/Game-/Level-Signalen, Wind nach Tempo; Bus „Cave“ mit Reverb nach Größe der Halle (`Level.hall_at()`) |
| `assets/sounds/*.wav` | Synthetisierte Sounds mit eingebackenem Höhlen-Hall, erzeugt von `tools/gen_sounds.py` (numpy); `amb_*` sind Schleifen |
| `scripts/ambient_sound.gd` | `AmbientSound`: 3D-Geräusch im Level (Lava, Aufwind, Kristall als Schleife, Tropfen in Abständen), spielt nur in Hörweite; platziert von `CavernBuilder` |
| `scripts/debug_overlay.gd` | Debug-Anzeige (FPS, Tempo, Haken, letzter Wurf) und Auto-Qualität |
| `tools/gen_splash.py` | Erzeugt `assets/splash.png` (Ladebildschirm) |
| `scripts/ghost.gd` | `Ghost`: zeichnet den Lauf auf (Position + Seil-Anker alle 0,05 s), spielt den besten Lauf als Geist ab, `time_at_z()` für das Geist-Delta im HUD |
| `scripts/replay.gd` | `Replay`: spielt den besten Lauf im Ziel ab („Replay“): setzt den Spieler (`player.replaying`, `replay_step()`), Kamera, Figur und Seil folgen; Tippen beendet |
| `scripts/stats.gd` | `Stats`: Läufe, Ziele, Meter, Haken, längster Flow, Spielzeit – gesamt und pro Level in `user://stats.cfg`; Zielzeiten-Verlauf (50 je Level-Version) in `user://history.cfg`; Anzeige im Level-Menü („Stats“) |
| `scripts/mover.gd` | Bewegliches Hindernis (AnimatableBody3D, Haken fährt mit) |
| `scripts/cavern_builder.gd` | `CavernBuilder`: baut Hallen, Decke, Wände, Stalaktiten, Säulen, Inseln, Tore, Lava, Aufwind, brüchige Stalaktiten, Tempo-Ringe, dunkle Hallen, Checkpoints, Ziel aus `segments` |
| `scripts/rock_mesh.gd` | `RockMesh`: prozedurale Felsmodelle (Brocken, Stalaktit-Kegel, Säule, Wurzel; je 4 Varianten, flach schattiert, Einheitsgröße) für die MultiMeshes des Baukastens |
| `scripts/floater.gd` | `Floater`: schwebender Stein in offenen Hallen (AnimatableBody3D, wippt; der Haken fährt mit) |
| `scripts/updraft.gd` | `Updraft`: Luftsäule, hebt Körper bis `max_rise` |
| `scripts/brittle.gd` | `Brittle`: Stalaktit hält den Haken `hold_time`, bricht dann (Seil löst sich mit `broke`), `restore()` beim Neustart |
| `scripts/speed_ring.gd` | `SpeedRing`: Ring, Durchfliegen gibt mindestens `boost_speed` nach vorn |
| `scripts/level.gd` | `Level`: Name, Medaillen, `segments`, `layout_seed`, `kill_y`, `hints` (Tutorial-Hinweise nach Position); Signale `finished`, `checkpoint_reached`, `killed` |
| `scenes/player.tscn` | CharacterBody3D (Kapsel) mit Figur, Seil, Haken und Ziellinie |
| `scripts/player_figure.gd` | `PlayerFigure`: Gelenkfigur (Meshes an Gelenk-Pivots), Posen aus dem Zustand (Seilarm zum Anker, Beine im Fahrtwind, Salto beim Zip, Hocke bei Landung), schlaffer Sturz (`go_limp()`), Kopflampe, Schal; `player.gd` ruft `update_pose()` |
| `scripts/verlet_band.gd` | `VerletBand`: Schal als Verlet-Kette, als Band gezeichnet |
| `scripts/input_router.gd` | Autoload: Maus/Touch → Signale `aim_changed`, `aim_cancelled`, `throw_requested` (Swipe + Flick-Tempo), `release_requested`, `restart_requested` |
| `scripts/player.gd` | Schwerkraft, Hakenwurf (Flugbahn), Seilzug als Geschwindigkeit, Ziel-Vorschau |
| `scripts/grapple_rope.gd` | Zeichnet eine Linie (Seil, Ziellinie) per ImmediateMesh |
| `scripts/camera_rig.gd` | Verfolgerkamera: Lag, Look-Ahead (beim Zug Richtung Anker), Tempo-FOV (horizontal), Roll, Shake, Wand-Kollision; unter der Decke tiefer und nach oben blickend (`ceiling_near`), Ziel-Umkreisung (`start_orbit`) |
| `scripts/game.gd` | Level laden, Timer, Ziel, Checkpoints (Lava/Absturz → Figur fällt `fall_show_time` schlaff, Timer steht so lange, dann letzter Checkpoint, Timer läuft weiter), Neustart, HUD, Lauf-Codes teilen/laden |
| `scripts/safe_area.gd` | `SafeArea.margins()`: Ränder für Notch/Home-Indikator in Viewport-Einheiten |
| `tools/gen_textures.py` | Malt die Texturen (`assets/textures/`) und schreibt die Materialbibliothek (`assets/materials/`) |
| `scenes/props/` | Wiederverwendbare Deko: Lichtkegel, leuchtender Kristall |
| `scripts/flicker.gd` | Flackerndes Licht (Fackeln, Lava); `fade` setzt `LightLod` |
| `scripts/light_lod.gd` | `LightLod`: nur die nächsten `max_lights` Lichter an (Compatibility-Renderer: max. 8 pro Objekt), weich ein-/ausblenden |
| `scripts/time_scale.gd` | `TimeScale`: Zeitlupe beim Zielen und Hit-Stop teilen sich `Engine.time_scale` |
| `scripts/speed_lines.gd` | Speed-Lines (Shader `shaders/speed_lines.gdshader`) ab hohem Tempo |
| `scripts/tuning_panel.gd` | Debug-Overlay „TUNE“: Regler in Tabs, pausiert das Spiel, speichert in `user://tuning_v3.cfg`, „Copy“ kopiert getunte Werte als Text, „Paste“ liest sie (auch Listen wie „Player gravity 30, …“) wieder ein; Wertesätze A/B/C (`user://tuning_presets.cfg`) mit einem Tipp wechseln; oben Erklärung und Skizze des gewählten Reglers |
| `scripts/cave_editor.gd` | `CaveEditor`: Höhlen-Editor (TUNE-Tab „Cave“): Hallen des geladenen Levels ändern, Neubau nach 0,35 s, Spieler am Anfang der gewählten Halle; Edits pro Level in `user://cave_edits.cfg` (eigene Rekorde „edit_…“), „Copy layout“ im Level-Dateiformat, „Reset cave“ |
| `scripts/tuning_info.gd` | `TuningInfo`: Klarname, Einheit, Skizzen-Art und Erklärung je Regler |
| `scripts/tuning_illustration.gd` | `TuningIllustration`: animierte Skizze je Regler (vereinfachtes Modell mit den aktuellen Werten) |
| `tests/` | Headless-Tests (`run_tests.gd` führt alle `test_*.gd` aus), laufen in CI vor jedem Merge/Deploy |
| `.github/actions/setup-godot/` | Lädt Godot + Web-Vorlagen in CI (gecacht) |
| `docs/` | Design, Roadmap, nächste Schritte, iOS-Export |

## Wie die Physik funktioniert (Kern des Spiels)

**Wurf** (`player.gd::throw_hook()`): `InputRouter` misst beim Loslassen den
Swipe-Vektor und das Fingertempo der letzten 0,1 s (`FLICK_WINDOW`).
- Richtung: Swipe gerade nach oben = nach vorn (-Z) und um `throw_pitch` nach
  oben; seitliche Swipes drehen den Wurf Richtung Wand (`throw_yaw_gain`).
  Swipes nach unten werden verworfen. **Wurfwinkel-Hilfe:** Würde der Wurf nicht
  halten (Eis, nichts in Reichweite, Fels näher als `min_throw_reach` – etwa direkt
  unter der Decke), wird in 10°-Schritten flacher geworfen (bis `min_throw_pitch`);
  die Ziellinie zeigt das vorher an.
- Tempo: Fingertempo × `throw_speed_per_px`, begrenzt auf
  `hook_min_speed`..`hook_max_speed`. Der Haken erbt die Spielergeschwindigkeit.
- Flug: Der Haken fliegt mit `hook_gravity` auf einer Bahn, Raycast pro Frame.
  Trifft er Wand oder Decke, haftet er (`can_stick()`); Böden (Normale nach oben),
  Flächen in der Gruppe `no_hook` (Eis), Treffer näher als `min_hook_distance` und
  Flüge über `max_rope_length` hinaus lassen ihn fallen. Auf beweglichen Körpern
  fährt der Anker mit.
- **Kettenwürfe:** Ein Wurf während eines Zugs lässt das Seil weiter ziehen, bis
  der neue Haken greift (Übergabe, `rope_released("chain")`). Ein Wisch, während
  ein Haken fliegt, wird gepuffert (`throw_buffer_time`); ein zweiter Wisch innerhalb
  `throw_cooldown` gilt als versehentlich. Seil-Grafik: `RopeVisual` – Verlet-Kette
  von der Hand der Figur zum Haken (gestrafft beim Zug, `flight_rope_slack` Durchhang
  im Flug, schlängelt beim Zurückholen); rein optisch, die Physik zieht vom Körper.
- Zielen: gestrichelter Bogen = `predict_hook_path()` für `aim_preview_speed`
  (gleiche Physik wie der echte Flug), Kugel = Treffpunkt. `aim_assist_angle`
  sucht im Kegel nach einer greifbaren Fläche (0 = aus). `aim_time_scale`
  verlangsamt das Spiel beim Zielen (1 = aus); der Timer zählt Echtzeit.
- Fehlwurf/Lösen: Der Haken fliegt in `hook_retract_time` sichtbar zurück.

**Zug** (`_apply_rope_constraint()`): Beim Einhaken gibt es einen Ruck
(`pull_impulse`). Das Seil wird ab `reel_speed` eingeholt, beschleunigt mit
`reel_acceleration` bis `reel_max_speed`; `tension_boost` zieht zusätzlich zum
Anker. Alles wird als Geschwindigkeit angewandt (nicht als Positionssprung),
deshalb bleibt der Schwung beim Loslassen erhalten und `move_and_slide`
verhindert Clipping. Liegt der Spieler außerhalb der Seillänge, bekommt er genau
die nötige Geschwindigkeit nach innen → Pendeln.

**Ende des Zugs**, in dieser Reihenfolge (Pendelphase `swing_time` vorher, Standard 0):
- **Zip-Launch:** näher als `zip_release_distance` am Anker und in Bewegung auf ihn
  zu → Seil löst sich, der Spieler fliegt mit vollem Tempo + `zip_boost` weiter.
- **Seilende:** Hat die Rolle das Seil bis `min_rope_length` eingeholt
  (`rope_end_release` an), löst es wie ein Zip-Launch – kein Hängenbleiben.
- **Vorbeiflug:** am Anker vorbei (näher als `flyby_release_distance`, Bewegung
  weg vom Anker) → wie Zip-Launch, statt zurückzuschwingen.
- Nach `contact_release_grace`: Berührung von Wand oder Decke (`release_on_contact`) → Seil löst sich.
- Hindernis zwischen Spieler und Anker (`release_when_blocked`) → Seil löst sich.
Böden lösen das Seil nie. Am Boden bremst `floor_friction`, solange kein Seil zieht;
über `slide_speed` nur `slide_friction` (Rutschen). Landungen geben `landing_roll`
der Fallgeschwindigkeit als Vorwärtstempo dazu.

**Aufprall** (`_handle_impacts()`, nur ohne Seil): Wand oder Decke mit mehr als
`deflect_min_speed` → das Tempo wird entlang der Fläche umgelenkt, skaliert mit dem
Streifwinkel (streifend ≈ voll, frontal ≈ nichts; nie schneller als vorher).
Streifende Wandtreffer (< 60°) geben einen Wall-Kick (`wall_bounce`, `wall_kick_up`),
frontale Crashs nicht. Boden + bewegtes Hindernis von oben = `crushed` → Checkpoint.

**Signale** von `player.gd` für Kamera, Sound und Effekte: `hook_thrown`,
`hook_attached(point, normal)`, `hook_missed`, `rope_released(reason)`
(`zip`, `contact`, `blocked`, `tap`, `chain`, `broke`, `reset`), `landed(impact_speed)`,
`deflected(impact_speed)`, `crushed`.
**Sturz:** Lava, Absturz unter `kill_y` oder Zerquetschen → `game.gd` ruft
`player.fall()`: keine Physik, kein Input, die Figur fliegt schlaff weiter
(`PlayerFigure.go_limp()`), nach `fall_show_time` Respawn per `reset_to()`.
Tests setzen `fall_show_time` 0 (`test_case.gd`), damit Bot-Zeiten gleich bleiben.

**Zeit:** `Engine.time_scale` nie direkt setzen, sondern über `TimeScale`
(`scripts/time_scale.gd`): Zielen-Zeitlupe (`set_aim`), Hit-Stop (`hit_stop`) und
Zeitlupe der Ziel-Einstellung (`set_cinema`) multiplizieren sich. Der Lauf-Timer zählt beim Zielen Echtzeit, beim Hit-Stop
Spielzeit (`TimeScale.timer_delta()`); `game.gd` ruft `TimeScale.update()`.

**Juice:** `effects.gd` (Funken, Staub, Hit-Stop, Wind-Streifen), `camera_rig.gd`
(Shake, Roll, Tempo-FOV, Zip-FOV-Kick), `RopeVisual.pluck()` (Seil zittert beim
Einhaken), `speed_lines.gd` + `shaders/speed_lines.gdshader` (Speed-Lines über
der 3D-Ansicht), Flow-Zähler in `game.gd` (Haken in Folge ohne Bodenkontakt),
`sfx.gd` (Wind-Tonhöhe nach Tempo, Haken-Ton steigt mit dem Flow).

**Flüssige Darstellung:** Physik-Interpolation ist an (60-Hz-Physik, Darstellung
in jeder Bildrate). Alles, was per Hand jedes Frame platziert wird (Kamera-Rig,
Seil, Haken, Ziellinie, Geist), läuft in `_process`, nutzt
`get_global_transform_interpolated()` und hat `physics_interpolation_mode = OFF`.
Teleports (`reset_to`) rufen `reset_physics_interpolation()`.

## Arbeitsweise

- Starte mit dem Spielgefühl. Bevor Features dazukommen: Läuft der Testtunnel,
  fühlt sich das Pendeln richtig an? Erst dann weiter in `docs/roadmap.md`.
- Neue Stellschrauben, die man auf dem Handy drehen können soll, in
  `PARAMS` in `tuning_panel.gd` eintragen, dazu Name, Einheit, Skizze und
  Erklärung in `TuningInfo.PARAMS` (`tests/test_tuning.gd` prüft das). Gespeichert werden nur Werte, die
  vom Code-Standard abweichen; ändert sich ein Standard im Code, verfällt der
  gespeicherte Wert dafür automatisch.
- Jede Änderung an Physik-Tuning-Werten kurz in `docs/roadmap.md` unter
  "Tuning-Log" notieren (Wert vorher → nachher, warum).
- Testen auf dem Handy: Push auf `main` → Web-Build → https://j4nric.github.io/Grappling-hook-app/
  Die Build-Version (Commit-Hash) steht rechts oben im HUD. Der Workflow
  schreibt sie vor dem Export in `application/config/version`.
- Web-Export lokal: `godot --headless --path . --export-release "Web" build/web/index.html`
  (braucht die Web-Exportvorlagen `web_nothreads_*`).
- **Tests:** `godot --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd`
  (Exit-Code 1 bei Fehlern, auch wenn ein Testskript nicht lädt oder ein Skriptfehler
  auftritt; `TEST_FILTER=chain` führt nur passende Dateien aus). Neue Mechaniken
  bekommen einen Test in `tests/test_*.gd` (erbt von `test_case.gd`, Helfer für
  Touch/Swipe und Warten). Mechanik-Tests spielen in festen Tunneln
  (`tests/levels/tunnel_*.tscn`: Decke y=9, Ziel z=−200, Lava/Checkpoint in Tunnel 2),
  Tests der echten Level setzen `levels = Levels.LIST`. Mechanik-Tests in den
  Tunneln laufen mit einem festen Tuning (`TEST_TUNING` in `test_case.gd`), damit
  neue Standardwerte vom Handy sie nicht brechen; Level- und Bot-Tests nutzen die
  Standardwerte. Der Bot (`tests/bot.gd`) wirft
  auch während eines Zugs (Kette) und variiert nach jedem Tod die Richtung.
  `--fixed-fps 60` ist wichtig: `InputRouter` misst das Fingertempo über die
  Frame-Zeit.
- Änderungen laufen als PR pro Themengebiet; CI (Tests + Export) muss grün sein.
  Jeder offene PR ist am Handy spielbar unter
  https://j4nric.github.io/Grappling-hook-app/preview/pr-N/ (Übersicht: `/preview/`).
- Zum Testen ohne Editor: `godot --path . --headless --quit` prüft, ob das Projekt
  ohne Script-Fehler lädt. Zum Spielen: `godot --path .` oder im Editor F5.
- Commit-Nachrichten: kurzer Imperativ auf Deutsch, z. B. "Seil-Einholen verlangsamt".
