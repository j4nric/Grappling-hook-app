# Design: Grappling Cave

## Elevator Pitch

Du hängst an einem Haken in einer dunklen Höhle. Du kannst nicht laufen. Mit einem
Wisch wirfst du den Haken an die Wand, schwingst dich vorwärts, lässt im richtigen
Moment los und fliegst. Wer den Tunnel am schnellsten durchquert, gewinnt – gegen
die eigene Bestzeit.

## Perspektive

Dritte Person, Kamera hinter und leicht über der Figur, Blick nach vorn in den
Tunnel (-Z). Der Tunnel ist ein Schlauch: breit genug zum Schwingen, eng genug,
dass Zielen nur "wohin im Querschnitt" bedeutet. Die Vorwärtsrichtung ist immer
klar – das macht die Ein-Finger-Steuerung überhaupt möglich.

## Steuerung

| Geste | Wirkung | Status |
|---|---|---|
| Wisch | Haken fliegt in Richtung des Wisch-Endpunkts; Ankerpunkt = erster Wandtreffer | M0: Endpunkt wird genutzt, Wischtempo noch nicht |
| Tippen | Seil loslassen, Figur fliegt mit Schwung weiter | fertig |
| Wisch während Haken aktiv | Neuer Haken (alter löst sich) | fertig |

Geplantes "Wurf"-Gefühl (M2): Wie beim Pokéball in Pokémon GO soll das Tempo des
Wischs eine Rolle spielen. Vorschlag: Wischgeschwindigkeit skaliert die maximale
Hakenreichweite; ein kurzer, langsamer Wisch erreicht nur nahe Wände. Der Haken
könnte sichtbar fliegen (kurze Flugzeit statt Sofort-Raycast), damit sich der
Wurf körperlich anfühlt. Zu prüfen: Fühlt sich Flugzeit gut an oder frustriert sie
im Speedrun?

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

Das Testlevel in `scenes/test_tunnel.tscn` hat je einen Baustein davon.

## Optik

Pixel-3D: Die 3D-Szene wird in niedriger Auflösung gerendert
(`scaling_3d/scale`), Texturen ohne Filterung. Dunkle Höhle, wenig Licht,
warme Lichtquellen (Fackeln, Kristalle) als Orientierung. Farbpalette bewusst
klein halten (z. B. 16–32 Farben).

## Offene Fragen

- Hochkant oder Querformat? Querformat passt zum Spider-Man-Gefühl, Hochkant
  ist bequemer für einhändiges Spielen. Mit dem Prototyp beides ausprobieren.
- Soll man mehrfach hintereinander Haken werfen können (Ketten), ohne loszulassen?
- Soll es Items geben (Boost, Doppelhaken) oder bleibt es pur?
