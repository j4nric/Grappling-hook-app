# Design: Grappling Cave

## Elevator Pitch

Du hängst an einem Haken in einer dunklen Höhle. Du kannst nicht laufen. Mit einem
Wisch wirfst du den Haken an die Wand, schwingst dich vorwärts, lässt im richtigen
Moment los und fliegst. Wer den Tunnel am schnellsten durchquert, gewinnt – gegen
die eigene Bestzeit.

## Perspektive

Hochformat (entschieden am 2026-10-17): einhändig spielbar, Daumen wischt nach oben.

Dritte Person, Kamera hinter und leicht über der Figur, Blick nach vorn in den
Tunnel (-Z). Der Tunnel ist ein Schlauch: breit genug zum Schwingen, eng genug,
dass Zielen nur "wohin im Querschnitt" bedeutet. Die Vorwärtsrichtung ist immer
klar – das macht die Ein-Finger-Steuerung überhaupt möglich.

## Steuerung

| Geste | Wirkung | Status |
|---|---|---|
| Wischen (gedrückt halten) | Zielen: weiße Linie zeigt die Wurfrichtung | fertig |
| Loslassen | Haken wird geworfen; Wischtempo der letzten 0,1 s = Wurfstärke, Haken fliegt auf einer Bahn und haftet an Wand/Decke, Seil zieht zum Treffpunkt | fertig |
| Wand/Decke berühren | Seil löst sich automatisch, Schwung bleibt | fertig |
| Tippen | Seil lösen, Figur fliegt mit Schwung weiter | fertig |
| Neuer Wurf während Haken aktiv | Altes Seil löst sich beim Wurf | fertig |
| Zwei-Finger-Tipp | Level neu starten | fertig |

"Wurf"-Gefühl: Wie beim Pokéball in Pokémon GO zählt das Tempo des Fingers
kurz vor dem Loslassen. Schnell schnippen = schneller, gerader Wurf; Finger
stehen lassen und dann loslassen = schwacher Wurf, der Haken fällt herunter.
Der Haken fliegt sichtbar (Flugzeit bei starkem Wurf ca. 0,2–0,3 s).
Zu prüfen: Fühlt sich die Flugzeit gut an oder frustriert sie im Speedrun?
Falls gezieltes langsames Loslassen trotzdem treffen soll: `hook_min_speed` erhöhen.

## Spielgefühl ("Spider-Man-Faktor")

Drei Zutaten, alle schon im Prototyp angelegt:
1. **Seil-Einholen** (`reel_speed`): Das Seil wird beim Schwingen kürzer, dadurch
   wird man nach oben/vorn gezogen und gewinnt Tempo.
2. **Kamera-Lag** (`follow_speed`): Die Kamera hängt der Figur leicht nach;
   Beschleunigung wird spürbar.
3. **Tempo-FOV** (`fov_per_speed`): Das Sichtfeld weitet sich mit der
   Geschwindigkeit.

Später: Kamera-Roll beim seitlichen Schwingen, leichter Screenshake beim
Einhaken, Trail-Partikel hinter der Figur, Wind-Sound der Geschwindigkeit.

## Speedrun-Schleife

- Timer startet beim ersten Input, stoppt an der Ziellinie.
- Bestzeit pro Level (M4: persistent speichern).
- Medaillen-Zeiten pro Level (Bronze/Silber/Gold) als Ziele.
- Sofortiger Neustart ohne Ladezeit. Absturz = sofortiger Reset.
- Später: Ghost der Bestzeit, Freunde-Bestenliste (Game Center).

## Level-Aufbau

Jedes Level ist ein Tunnel-Abschnitt von 30–90 Sekunden Spielzeit. Bausteine:
- **Ankerflächen**: Wände, Decke, hängende Blöcke
- **Lücken**: Boden fehlt, man muss in der Luft bleiben
- **Engstellen**: Säulen, die den Schwungweg einschränken
- **Abzweigungen**: kürzere, aber riskantere Route für Speedrunner

Umgesetzt (`tools/gen_levels.py`, 5 Level):
1. **First Swing** – Grundlagen, eine Lava-Lücke, hängende Blöcke, Säulen
2. **Lava Gaps** – viele Bodenlücken, Checkpoints
3. **Ice Ceiling** – Eis-Abschnitte an Decke und Wänden (Haken hält nicht), Zickzack
4. **Movers** – seitlich und vertikal fahrende Blöcke
5. **Shortcut** – eine Zwischendecke teilt den Tunnel: oben schnell, aber schwer zu erreichen

Lava/Abgrund setzt auf den letzten Checkpoint zurück, der Timer läuft weiter.

## Optik

Pixel-3D: Die 3D-Szene wird in niedriger Auflösung gerendert
(`scaling_3d/scale`), Texturen ohne Filterung. Dunkle Höhle, wenig Licht,
warme Lichtquellen (Fackeln, Kristalle) als Orientierung. Farbpalette bewusst
klein halten (z. B. 16–32 Farben).

## Offene Fragen

- Soll man mehrfach hintereinander Haken werfen können (Ketten), ohne loszulassen?
- Soll es Items geben (Boost, Doppelhaken) oder bleibt es pur?
