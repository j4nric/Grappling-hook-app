# Nächste Schritte

Stand: 2026-10-17, Build `e61bbcc`. Sortiert nach Priorität. Maßstab bleiben die
drei Säulen aus `CLAUDE.md`: Schwunggefühl, ein Finger, Speedrun.
Status-Häkchen setzen, wenn erledigt; Erledigtes wandert nach `roadmap.md`.

## Offene Entscheidungen (vor allem anderen klären)

- [ ] **Level-Richtung im Hochformat:** Der Tunnel läuft waagerecht (-Z), das
      Bild ist hochkant und man wirft nach oben. Variante A: waagerechter
      Tunnel bleibt, Kamera stärker von oben/hinten. Variante B: senkrechte
      Höhle, man klettert nach oben (passt zu Hochformat und „Haken an die
      Decke werfen“). Beeinflusst Kamera, Level-Bau und Wurf-Mapping.
- [ ] **Ende eines Zugs:** Jetzt zieht das Seil bis an die Fläche und löst
      sich bei Kontakt, der Aufprall frisst aber den Großteil des Tempos
      (gemessen: 25 → 4 m/s). Alternative „Zip-Launch“: Seil löst sich kurz
      vor dem Treffpunkt automatisch, man fliegt mit vollem Tempo weiter
      (Spider-Man-Gefühl). Beides als Option bauen und am Handy vergleichen?
- [ ] **Swipe-Start:** Muss der Wisch auf dem Spieler beginnen (wie beim
      Pokéball) oder überall (jetzt)? Überall ist toleranter, auf dem Spieler
      ist eindeutiger.
- [ ] **Tippen = Seil lösen:** Mit Auto-Lösen bei Kontakt noch nötig? Ohne
      Tippen-Geste gäbe es weniger Fehlbedienung.

## 1. Spielgefühl (höchste Priorität)

- [ ] **Bodenreibung:** Landet man nach dem Lösen auf dem Boden, rutscht man
      endlos weiter (keine Reibung). `floor_friction` als `@export` + Regler.
- [ ] **Tempo-Verlust beim Aufprall** verringern (siehe Entscheidung oben):
      z. B. Release-Abstand `auto_release_distance`, oder beim Kontakt den
      Geschwindigkeitsanteil entlang der Fläche verstärken.
- [ ] **Zug-Kurve:** Statt konstantem `reel_speed` ein Zug, der anfangs
      ruckartig startet und dann beschleunigt (Ease-In), plus Höchsttempo
      des Zugs. Macht den Treffer spürbarer.
- [ ] **Seil durch Hindernisse:** Das Seil ist eine Linie ohne Kollision.
      Wenn ein Hindernis zwischen Spieler und Anker kommt: Seil lösen (einfach)
      oder um die Kante wickeln (aufwendig, später).
- [ ] **Flugbahn-Vorschau:** Die Ziellinie ist gerade, der Haken fliegt aber
      im Bogen. Optionen: Bogen für ein „mittleres“ Wurftempo anzeigen, oder
      Linie nur als Richtungspfeil (kurz) statt bis zur Wand.
- [ ] **Zielhilfe (optional):** Leichtes Einrasten auf die nächste Wand-/
      Deckenfläche in einem kleinen Kegel um die Wurfrichtung. Erst testen,
      ob es nötig ist.
- [ ] **Fehlwurf-Feedback:** Fällt der Haken ins Leere, sichtbar einholen
      (zurückfliegen) statt verschwinden.
- [ ] **Wurfstärke kalibrieren:** Im TUNE-Panel die Werte des letzten Wurfs
      anzeigen (Fingertempo px/s, Hakentempo m/s). Damit lassen sich
      `throw_speed_per_px`, `hook_min_speed`, `hook_max_speed` am echten Gerät
      sauber einstellen.
- [ ] **Zeitlupe beim Zielen (Idee):** Solange der Finger zielt, läuft das
      Spiel z. B. mit 30 % Tempo. Erleichtert Zielen im Flug; für Speedrun
      ggf. abschaltbar.

## 2. Kamera

- [ ] **Sichtfeld im Hochformat:** Seitlich sieht man wenig. `base_fov`
      höher setzen oder Kamera auf „Breite halten“ (`keep_aspect`) umstellen,
      am Handy vergleichen.
- [ ] **Look-Ahead zum Haken:** Kamera schaut leicht Richtung Anker, solange
      man gezogen wird.
- [ ] **Kamera-Roll** beim seitlichen Schwingen (aus M1).
- [ ] **Kurzer Kamera-Ruck / Screenshake** beim Einhaken und beim Aufprall.

## 3. Steuerung und Bedienung

- [ ] **Hinweistext ausblenden** nach dem ersten erfolgreichen Wurf; im Ziel
      wieder einblenden.
- [ ] **Neustart nach dem Ziel:** Großer „Nochmal“-Hinweis statt nur
      Zwei-Finger-Tipp.
- [ ] **Tuning-Werte teilen:** Button „Werte kopieren“ im TUNE-Panel (Text in
      die Zwischenablage), damit getunte Werte ohne Screenshot zu mir kommen.
      Prüfen, ob iOS Safari das aus Godot heraus erlaubt; sonst Werte als
      Text im Panel anzeigen.
- [ ] **Safe Area prüfen:** Als Home-Bildschirm-App (`black-translucent`)
      liegt der Inhalt unter Uhr/Dynamic Island. Timer und TUNE ggf. nach
      unten versetzen bzw. `DisplayServer.get_display_safe_area()` nutzen.

## 4. Level und Speedrun

- [ ] **Testlevel fürs Hochformat umbauen** (abhängig von der
      Level-Richtungs-Entscheidung).
- [ ] **Bestzeit dauerhaft speichern** (`user://`, IndexedDB im Browser).
- [ ] **Medaillen-Zeiten** (Bronze/Silber/Gold) pro Level, Anzeige im Ziel.
- [ ] **Countdown bzw. Startsignal** und klarer Start-Moment für den Timer.
- [ ] **Neue Level-Bausteine:** nicht greifbare Flächen (z. B. Eis, anders
      gefärbt), bewegliche Hindernisse, Abgründe/Lava als Reset-Zonen,
      Abkürzungen für Speedrunner.
- [ ] **Checkpoints** für längere Level.
- [ ] **3–5 Level + Level-Auswahl** (M4).
- [ ] **Ghost der Bestzeit** (M6).

## 5. Optik und Lesbarkeit

- [ ] **Licht:** Die Höhle ist zu dunkel, Wände sind schwer zu erkennen.
      Fackeln/Kristalle als Punktlichter, Umgebungslicht anheben, Nebel
      anpassen. Wichtig fürs Zielen, deshalb früh angehen.
- [ ] **Greifbare Flächen erkennbar machen** (Farbe/Textur), sobald es
      nicht greifbare Flächen gibt.
- [ ] **Pixel-Look feinjustieren:** prüfen, ob das Hochskalieren im Web
      unscharf (bilinear) oder pixelig (nearest) ist; ggf. SubViewport mit
      Nearest-Filter.
- [ ] **Einfaches Spielermodell, Haken-Modell, Seil mit Textur.**
- [ ] **Partikel:** Funken beim Einhaken, Staub beim Aufprall, Speed-Trail.

## 6. Sound (M6)

- [ ] Wurf, Einhaken, Seil-Zug, Aufprall, Wind abhängig vom Tempo.
- [ ] iOS: Audio startet erst nach der ersten Berührung (Browser-Regel),
      beim ersten Touch aktivieren.

## 7. Technik und Arbeitsablauf

- [ ] **Debug-Anzeige** (im TUNE-Panel ein-/ausschaltbar): FPS, Tempo,
      Zustand des Hakens, letztes Fingertempo.
- [ ] **Performance am Gerät messen:** Ziel 60 fps auf dem iPhone. Bei
      Einbruch `scaling_3d/scale` senken, Schatten aus.
- [ ] **Ladezeit:** Die Engine (`index.wasm`) ist ~39 MB (komprimiert ca.
      10 MB). Eigener Ladebildschirm mit Fortschritt; prüfen, ob GitHub Pages
      komprimiert ausliefert.
- [x] **Automatische Tests in CI:** Die Headless-Simulationen (Wurf trifft
      Decke, Flick-Messung bei 60 fps, Tuning speichern/laden) ins Repo
      (`tests/`) und vor dem Deploy laufen lassen. Ein kaputter Build kommt
      dann nicht mehr aufs Handy.
- [ ] **Vorschau-Builds für Branches:** Experimente (z. B. Zip-Launch vs.
      Aufprall) parallel unter eigener URL testen, ohne `main` zu ändern.
- [x] **Godot-Version** bei Updates an drei Stellen gleich halten
      (`web.yml`, `CLAUDE.md`, README) – CI prüft das.

## 8. Später: iOS-App (M5)

- [ ] Export nach `docs/ios-export.md` (braucht Mac + Xcode).
- [ ] Haptisches Feedback beim Einhaken (geht nur nativ, nicht im Browser).
- [ ] TestFlight, Game Center (Bestenliste).
