# iOS-Export (M5)

## Voraussetzungen
- Mac mit aktuellem Xcode (App Store)
- Apple-ID. Zum Testen auf dem eigenen Gerät reicht ein kostenloser Account
  (App läuft 7 Tage, dann neu signieren). Für TestFlight/App Store: Apple
  Developer Program, 99 $/Jahr.
- In Godot: Editor → Exportvorlagen verwalten → passende Vorlagen herunterladen

## Schritte
1. Projekt → Exportieren → Hinzufügen → iOS
2. Bundle Identifier setzen, z. B. `de.<name>.grapplingcave`
3. Team-ID aus dem Apple Developer Account eintragen (bei kostenlosem Account
   die ID, die Xcode unter Accounts anzeigt)
4. Icons/Launch Screen können zunächst leer bleiben (Godot generiert Platzhalter)
5. "Projekt exportieren" → erzeugt ein Xcode-Projekt in `build/ios/`
6. Xcode-Projekt öffnen, Signing & Capabilities → Team wählen, iPhone anschließen,
   Run

## Projekt-Einstellungen, die für iOS relevant sind
- `display/window/handheld/orientation` in `project.godot`
  (0 = Querformat, 1 = Hochkant)
- Renderer bleibt "Mobile"
- `scaling_3d/scale` kann auf dem Gerät weiter reduziert werden, falls die
  Bildrate einbricht; das verstärkt zugleich den Pixel-Look

## Stolpersteine
- Touch-Events kommen als `InputEventScreenTouch`, nicht als Mausereignisse.
  `emulate_mouse_from_touch` ist absichtlich aus, damit InputRouter die Fälle
  sauber trennt.
- Die Safe Area (Notch) beachten: HUD-Elemente mit
  `DisplayServer.get_display_safe_area()` positionieren.
- Beim ersten Export fehlen oft Export-Vorlagen genau für die installierte
  Godot-Version; Version im Editor und beim Vorlagen-Download müssen übereinstimmen.
