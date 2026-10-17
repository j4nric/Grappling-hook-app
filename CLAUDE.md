# CLAUDE.md – Grappling Cave

Diese Datei ist der Einstiegspunkt für Claude Code. Lies sie vollständig, bevor du
Änderungen machst. Projektsprache: Doku und Commits auf Deutsch, Code, Kommentare
und Bezeichner auf Englisch.

## Was das Spiel ist

Ein Geschicklichkeitsspiel für iOS (Godot 4): Der Spieler hängt in einer 3D-Höhle,
kann nicht laufen und bewegt sich ausschließlich mit einem Grappling Hook vorwärts
durch einen Tunnel. Ziel ist, das Level so schnell wie möglich zu schaffen.
Ausführliches Design: `docs/design.md`. Meilensteine: `docs/roadmap.md`.

Die drei Säulen, an denen jede Entscheidung gemessen wird:
1. **Schwunggefühl** – Pendeln muss sich schwer, schnell und kontrollierbar anfühlen
   (Vorbild: moderne Spider-Man-Spiele). Das ist das Spiel. Alles andere ist Beiwerk.
2. **Ein Finger** – Wischen wirft den Haken (wie ein Pokéball-Wurf in Pokémon GO),
   Tippen lässt los. Keine Buttons, kein Joystick.
3. **Speedrun** – Timer, Bestzeit, Wiederspielbarkeit statt vieler Level.

## Stack und Konventionen

- Godot **4.4 oder neuer**, Renderer "Mobile", GDScript mit statischer Typisierung
  (`var x := …`, Typhinweise bei Parametern und Rückgaben).
- Pixel-Look kommt aktuell nur aus `rendering/scaling_3d/scale=0.35` in
  `project.godot`. Nicht in Scripts hartkodieren.
- Vorwärts im Tunnel ist **-Z**. Der Spieler startet bei z=0, das Ziel liegt bei z=-200.
- Tuning-Werte sind `@export`-Variablen und werden im Inspector verändert, nicht
  im Code verstreut. Neue Stellschrauben ebenfalls als `@export` anlegen.
- Input läuft **ausschließlich** über das Autoload `InputRouter`
  (`scripts/input_router.gd`). Kein anderes Script liest `InputEvent` direkt.
- Szenen sind handgeschriebene `.tscn`-Textdateien; bleibe bei diesem Format und
  halte sie klein. UIDs fehlen absichtlich, Godot ergänzt sie beim ersten Öffnen.
- Keine externen Addons ohne Rücksprache.

## Dateiüberblick

| Pfad | Zweck |
|---|---|
| `project.godot` | Projekteinstellungen, Autoload, Render-Scale für Pixel-Look |
| `scenes/main.tscn` | Hauptszene: Tunnel + Player + CameraRig + HUD, Script `game.gd` |
| `scenes/player.tscn` | CharacterBody3D (Kapsel) mit Seil-Node |
| `scenes/test_tunnel.tscn` | Grauer Testtunnel aus CSG-Boxen, Hindernisse, Ziel-Area |
| `scripts/input_router.gd` | Autoload: Maus/Touch → Signale `grapple_requested`, `release_requested`, `restart_requested` |
| `scripts/player.gd` | Schwerkraft, Raycast-Haken, Pendel-Constraint, Seil-Einholen |
| `scripts/grapple_rope.gd` | Zeichnet das Seil als Linie (ImmediateMesh) |
| `scripts/camera_rig.gd` | Verfolgerkamera mit Nachzieh-Lag, Look-Ahead, Tempo-FOV |
| `scripts/game.gd` | Timer, Ziel-Erkennung, Absturz-Reset, Bestzeit, HUD |
| `docs/` | Design, Roadmap, iOS-Export |

## Wie die Physik funktioniert (Kern des Spiels)

`player.gd::_apply_rope_constraint()`:
- Der Spieler fällt frei (Schwerkraft).
- Ist ein Haken gesetzt, darf der Abstand zum Anker nie größer als `rope_length`
  sein. Liegt er darüber, wird die Position auf die Seilkugel zurückgezogen und der
  vom Anker wegzeigende Geschwindigkeitsanteil entfernt. Übrig bleibt die
  Tangentialgeschwindigkeit → Pendeln.
- `reel_speed` verkürzt das Seil kontinuierlich (Zug nach oben/vorn),
  `tension_boost` zieht zusätzlich leicht zum Anker. Beides macht den Schwung
  "schwerer". Die Werte sind erste Schätzungen und müssen im Spiel getunt werden.

Der Haken selbst: Raycast von der Kamera durch den Bildschirmpunkt des Klicks/
Wischendes. Erster Treffer auf Geometrie = Anker, sofern innerhalb
`max_rope_length`.

## Bekannte Schwächen des Prototyps (bewusst offen gelassen)

- `global_position` wird im Constraint direkt gesetzt → kann in Wände clippen.
  Falls das stört: stattdessen Korrektur als Geschwindigkeit anwenden oder
  `move_and_collide` für den Rückzug nutzen.
- Wisch-Geschwindigkeit und -Richtung werden an `grapple_requested` übergeben,
  aber noch nicht genutzt. Der "Wurf" (Reichweite aus Wischtempo, Flugbahn des
  Hakens) ist Meilenstein M2.
- Das Seil ist eine gerade Linie ohne Kollision; es kann durch Hindernisse gehen.
- Kein Modell, keine Animation, kein Sound. Bewusst – erst das Gefühl.
- Finish-Erkennung nur per Area3D, kein Checkpoint-System.

## Arbeitsweise

- Starte mit dem Spielgefühl. Bevor Features dazukommen: Läuft der Testtunnel,
  fühlt sich das Pendeln richtig an? Erst dann weiter in `docs/roadmap.md`.
- Jede Änderung an Physik-Tuning-Werten kurz in `docs/roadmap.md` unter
  "Tuning-Log" notieren (Wert vorher → nachher, warum).
- Zum Testen ohne Editor: `godot --path . --headless --quit` prüft, ob das Projekt
  ohne Script-Fehler lädt. Zum Spielen: `godot --path .` oder im Editor F5.
- Commit-Nachrichten: kurzer Imperativ auf Deutsch, z. B. "Seil-Einholen verlangsamt".
