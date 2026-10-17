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
- Pixel-Look kommt aktuell nur aus `rendering/scaling_3d/scale=0.35` in
  `project.godot`. Nicht in Scripts hartkodieren.
- Vorwärts im Tunnel ist **-Z**. Der Spieler startet bei z=0. Tunnel: 12 m breit
  (x −6..6), Boden y=−5, Decke y=9.
- **Level** entstehen aus `tools/gen_levels.py` (Beschreibungen dort ändern, dann
  `python3 tools/gen_levels.py`); die erzeugten `scenes/levels/*.tscn` nicht von Hand
  ändern. Reihenfolge in `scripts/levels.gd`. Medaillenzeiten aus der Bot-Zeit
  (`tests/test_levels.gd` gibt sie aus).
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

## Dateiüberblick

| Pfad | Zweck |
|---|---|
| `project.godot` | Projekteinstellungen, Autoload, Render-Scale für Pixel-Look |
| `export_presets.cfg` | Export-Preset "Web" (ohne Threads, läuft auf GitHub Pages/iOS Safari) |
| `.github/workflows/pages.yml` | Web-Export + Deploy nach GitHub Pages: `main` unter `/`, jeder offene PR unter `/preview/pr-N/` |
| `.github/workflows/ci.yml` | Pull Requests: Tests + Probe-Export |
| `.github/workflows/test.yml` | Wiederverwendbarer Test-Job (von `ci.yml` und `pages.yml` genutzt) |
| `tools/export_web.sh` | Web-Export mit Versionsstempel und eindeutigem Paketnamen (Cache-Busting) |
| `scenes/main.tscn` | Hauptszene: Player + CameraRig + HUD + LevelMenu + Tuning; das Level lädt `game.gd` |
| `scenes/levels/level_*.tscn` | Generierte Level (Start, Finish, Checkpoints, KillZones, Movers) |
| `scripts/level.gd` | `Level`: Signale `finished`, `checkpoint_reached`, `killed`, Medaillenzeiten |
| `scripts/levels.gd` | `Levels.LIST`: Level-Reihenfolge |
| `scripts/level_menu.gd` | Level-Auswahl (pausiert das Spiel) |
| `scripts/mover.gd` | Bewegliches Hindernis (AnimatableBody3D, Haken fährt mit) |
| `tools/gen_levels.py` | Level-Generator |
| `scenes/player.tscn` | CharacterBody3D (Kapsel) mit Seil, Haken-Kugel und Ziellinie |
| `scripts/input_router.gd` | Autoload: Maus/Touch → Signale `aim_changed`, `aim_cancelled`, `throw_requested` (Swipe + Flick-Tempo), `release_requested`, `restart_requested` |
| `scripts/player.gd` | Schwerkraft, Hakenwurf (Flugbahn), Seilzug als Geschwindigkeit, Ziel-Vorschau |
| `scripts/grapple_rope.gd` | Zeichnet eine Linie (Seil, Ziellinie) per ImmediateMesh |
| `scripts/camera_rig.gd` | Verfolgerkamera: Lag, Look-Ahead (beim Zug Richtung Anker), Tempo-FOV (horizontal), Roll, Shake bei `hook_attached`/`landed` |
| `scripts/game.gd` | Level laden, Timer, Ziel, Checkpoints (Lava/Absturz → letzter Checkpoint, Timer läuft weiter), Neustart, HUD |
| `scripts/safe_area.gd` | `SafeArea.margins()`: Ränder für Notch/Home-Indikator in Viewport-Einheiten |
| `scripts/tuning_panel.gd` | Debug-Overlay „TUNE“: Regler in Tabs, pausiert das Spiel, speichert in `user://tuning_v3.cfg`, „Copy“ kopiert getunte Werte als Text |
| `tests/` | Headless-Tests (`run_tests.gd` führt alle `test_*.gd` aus), laufen in CI vor jedem Merge/Deploy |
| `.github/actions/setup-godot/` | Lädt Godot + Web-Vorlagen in CI (gecacht) |
| `docs/` | Design, Roadmap, nächste Schritte, iOS-Export |

## Wie die Physik funktioniert (Kern des Spiels)

**Wurf** (`player.gd::throw_hook()`): `InputRouter` misst beim Loslassen den
Swipe-Vektor und das Fingertempo der letzten 0,1 s (`FLICK_WINDOW`).
- Richtung: Swipe gerade nach oben = nach vorn (-Z) und um `throw_pitch` nach
  oben; seitliche Swipes drehen den Wurf Richtung Wand (`throw_yaw_gain`).
  Swipes nach unten werden verworfen.
- Tempo: Fingertempo × `throw_speed_per_px`, begrenzt auf
  `hook_min_speed`..`hook_max_speed`. Der Haken erbt die Spielergeschwindigkeit.
- Flug: Der Haken fliegt mit `hook_gravity` auf einer Bahn, Raycast pro Frame.
  Trifft er Wand oder Decke, haftet er (`can_stick()`); Böden (Normale nach oben),
  Flächen in der Gruppe `no_hook` (Eis), Treffer näher als `min_hook_distance` und
  Flüge über `max_rope_length` hinaus lassen ihn fallen. Auf beweglichen Körpern
  fährt der Anker mit.
- Beim Wurf löst sich das alte Seil sofort: Man fliegt mit Schwung weiter,
  während der neue Haken unterwegs ist.
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

**Ende des Zugs** (nach `contact_release_grace`), in dieser Reihenfolge:
- **Zip-Launch:** näher als `zip_release_distance` am Anker und in Bewegung auf ihn
  zu → Seil löst sich, der Spieler fliegt mit vollem Tempo + `zip_boost` weiter.
- Berührung von Wand oder Decke (`release_on_contact`) → Seil löst sich.
- Hindernis zwischen Spieler und Anker (`release_when_blocked`) → Seil löst sich.
Böden lösen das Seil nie. Am Boden bremst `floor_friction`, solange kein Seil zieht.

**Signale** von `player.gd` für Kamera, Sound und Effekte: `hook_thrown`,
`hook_attached(point, normal)`, `hook_missed`, `rope_released(reason)`
(`zip`, `contact`, `blocked`, `tap`, `throw`, `reset`), `landed(impact_speed)`.

## Arbeitsweise

- Starte mit dem Spielgefühl. Bevor Features dazukommen: Läuft der Testtunnel,
  fühlt sich das Pendeln richtig an? Erst dann weiter in `docs/roadmap.md`.
- Neue Stellschrauben, die man auf dem Handy drehen können soll, in
  `PARAMS` in `tuning_panel.gd` eintragen. Gespeichert werden nur Werte, die
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
  (Exit-Code 1 bei Fehlern). Neue Mechaniken bekommen einen Test in
  `tests/test_*.gd` (erbt von `test_case.gd`, Helfer für Touch/Swipe und Warten).
  `--fixed-fps 60` ist wichtig: `InputRouter` misst das Fingertempo über die
  Frame-Zeit.
- Änderungen laufen als PR pro Themengebiet; CI (Tests + Export) muss grün sein.
  Jeder offene PR ist am Handy spielbar unter
  https://j4nric.github.io/Grappling-hook-app/preview/pr-N/ (Übersicht: `/preview/`).
- Zum Testen ohne Editor: `godot --path . --headless --quit` prüft, ob das Projekt
  ohne Script-Fehler lädt. Zum Spielen: `godot --path .` oder im Editor F5.
- Commit-Nachrichten: kurzer Imperativ auf Deutsch, z. B. "Seil-Einholen verlangsamt".
