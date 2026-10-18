class_name TuningIllustration
extends Control
## Animated sketch for the TUNE panel: shows what the selected slider does,
## drawn live with the current values (side view of the cave unless noted).
## Purely explanatory: a simplified model of the real physics in player.gd
## and camera_rig.gd, not the physics itself.

const ROCK := Color(0.42, 0.39, 0.37)
const ICE := Color(0.55, 0.82, 0.95)
const PLAYER := Color(0.88, 0.3, 0.24)
const ROPE := Color(0.91, 0.77, 0.28)
const HOOK := Color(0.92, 0.92, 0.96)
const MISS := Color(1.0, 0.4, 0.35)
const FAINT := Color(1, 1, 1, 0.25)
const TEXT := Color(1, 1, 1, 0.85)
const FONT_SIZE := 18
## Every kind of sketch this draws (TuningInfo picks one per slider).
const KINDS := ["throw", "reach", "reach_min", "reach_assist", "yaw", "timeline", "slowmo", "assist",
		"pull", "zip", "zip_boost", "zip_min", "flyby", "rope_pluck", "rope_slack", "fall", "speed_cap",
		"ground", "landing", "deflect", "wallkick", "camera_follow", "camera_offset", "camera_anchor",
		"camera_wall", "camera_ceiling", "fov", "fov_kick", "roll", "shake", "pixels", "volume", "toggle",
		"fps", "streaks"]

## Key of the slider shown ("Player/hook_gravity").
var key := ""
## Kind of sketch (TuningInfo).
var kind := ""
var value := 0.0
## Current values of all sliders (key -> value): the sketch uses the real tuning.
var values := {}
var _time := 0.0
## Sketches drawn so far (for tests).
var draw_count := 0
## World to screen: meters per view width, world point at the bottom left.
var _view_origin := Vector2.ZERO
var _scale := 1.0
var _view_offset := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	clip_contents = true


func show_param(param_key: String, sketch_kind: String, current: float, all_values: Dictionary) -> void:
	if param_key != key:
		_time = 0.0
	key = param_key
	kind = sketch_kind
	value = current
	values = all_values
	queue_redraw()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _v(param_key: String, default: float) -> float:
	return float(values.get(param_key, default))


# --- Drawing helpers --------------------------------------------------------

## Fits the world rectangle from `origin` (bottom left), `wide` x `high`
## meters, into the sketch, centered.
func _view(origin: Vector2, wide: float, high: float) -> void:
	_view_origin = origin
	_scale = minf(size.x / wide, size.y / high)
	_view_offset = (size - Vector2(wide, high) * _scale) / 2.0


func _to(p: Vector2) -> Vector2:
	return Vector2(_view_offset.x + (p.x - _view_origin.x) * _scale, size.y - _view_offset.y - (p.y - _view_origin.y) * _scale)


func _text(pos: Vector2, text: String, color := TEXT, font_size := FONT_SIZE) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _caption(text: String) -> void:
	_text(Vector2(10, size.y - 10), text)


func _player(p: Vector2, color := PLAYER) -> void:
	var s := _to(p)
	draw_circle(s, 7.0, color)
	draw_circle(s + Vector2(0, -10), 4.0, Color(0.93, 0.74, 0.58))


func _hook(p: Vector2, color := HOOK) -> void:
	var s := _to(p)
	draw_colored_polygon(PackedVector2Array([s + Vector2(-5, 4), s + Vector2(5, 4), s + Vector2(0, -6)]), color)


func _line(a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	draw_line(_to(a), _to(b), color, width, true)


func _dashed(a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	draw_dashed_line(_to(a), _to(b), color, width, 8.0, true)


func _arrow(a: Vector2, b: Vector2, color: Color) -> void:
	var sa := _to(a)
	var sb := _to(b)
	if sa.distance_to(sb) < 2.0:
		return
	draw_line(sa, sb, color, 3.0, true)
	var d := (sb - sa).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([sb + d * 4.0, sb - d * 10.0 + n * 6.0, sb - d * 10.0 - n * 6.0]), color)


func _ceiling(y: float, color := ROCK) -> void:
	var a := _to(Vector2(_view_origin.x, y))
	draw_rect(Rect2(0, 0, size.x, a.y), color.darkened(0.35))
	draw_line(Vector2(0, a.y), Vector2(size.x, a.y), color, 3.0)


func _floor(y: float) -> void:
	var a := _to(Vector2(_view_origin.x, y))
	draw_rect(Rect2(0, a.y, size.x, size.y - a.y), ROCK.darkened(0.35))
	draw_line(Vector2(0, a.y), Vector2(size.x, a.y), ROCK, 3.0)


func _circle(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 65:
		var a := TAU * i / 64.0
		points.append(_to(center + Vector2(cos(a), sin(a)) * radius))
	for i in 64:
		if i % 2 == 0:
			draw_line(points[i], points[i + 1], color, 2.0, true)


## 0..1 through a loop of `period` seconds.
func _phase(period: float) -> float:
	return fmod(_time, period) / period


# --- Sketches ------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.07, 0.1))
	draw_count += 1
	match kind:
		"throw": _draw_throw()
		"reach": _draw_reach()
		"reach_min": _draw_reach_min()
		"reach_assist": _draw_reach_assist()
		"yaw": _draw_yaw()
		"timeline": _draw_timeline()
		"slowmo": _draw_slowmo()
		"assist": _draw_assist()
		"pull": _draw_pull()
		"zip", "zip_boost", "zip_min": _draw_zip()
		"flyby": _draw_flyby()
		"rope_pluck": _draw_rope_pluck()
		"rope_slack": _draw_rope_slack()
		"fall": _draw_fall()
		"speed_cap": _draw_speed_cap()
		"ground": _draw_ground()
		"landing": _draw_landing()
		"deflect": _draw_deflect()
		"wallkick": _draw_wallkick()
		"camera_follow": _draw_camera_follow()
		"camera_offset": _draw_camera_offset()
		"camera_anchor": _draw_camera_anchor()
		"camera_wall": _draw_camera_wall()
		"camera_ceiling": _draw_camera_ceiling()
		"fov", "fov_kick": _draw_fov()
		"roll": _draw_roll()
		"shake": _draw_shake()
		"pixels": _draw_pixels()
		"volume": _draw_volume()
		"toggle": _draw_toggle()
		"fps": _draw_fps()
		"streaks": _draw_streaks()


## Hook flight with the current throw values; it bites the ceiling or falls.
func _draw_throw() -> void:
	_view(Vector2(-4, -4), 80.0, 27.0)
	var ceiling := 20.0
	_ceiling(ceiling)
	var lo := _v("Player/hook_min_speed", 8.0)
	var hi := _v("Player/hook_max_speed", 90.0)
	var speed := clampf(_v("Player/throw_speed_per_px", 0.015) * 3000.0, lo, hi)
	match key:
		"Player/hook_min_speed", "Player/hook_max_speed", "Player/aim_preview_speed":
			speed = value
	var pitch := deg_to_rad(_v("Player/throw_pitch", 50.0))
	var g := _v("Player/hook_gravity", 25.0)
	var reach := _v("Player/max_rope_length", 70.0)
	var start := Vector2(0, 1)
	var path := PackedVector2Array([start])
	var vel := Vector2(cos(pitch), sin(pitch)) * speed
	var p := start
	var result := "falls"
	for i in 300:
		vel.y -= g * 0.02
		p += vel * 0.02
		path.append(p)
		if p.y >= ceiling:
			p.y = ceiling
			path[-1] = p
			result = "bites %.0f m ahead" % p.x
			break
		if p.distance_to(start) > reach or p.y < -8.0:
			result = "too far: falls" if p.distance_to(start) > reach else "falls short"
			break
	for i in path.size() - 1:
		if i % 2 == 0:
			_line(path[i], path[i + 1], FAINT)
	var t := _phase(path.size() * 0.02 + 0.8)
	var index := mini(int(t * (path.size() * 0.02 + 0.8) / 0.02), path.size() - 1)
	var hook_at := path[index]
	_line(start + Vector2(0, 0.8), hook_at, ROPE)
	_hook(hook_at, ROPE if result.begins_with("bites") or index < path.size() - 1 else MISS)
	_player(start)
	_caption("hook %.0f m/s, %.0f° -> %s" % [speed, rad_to_deg(pitch), result])


## Rope length as a circle: hits inside it hold, beyond it the hook gives up.
func _draw_reach() -> void:
	_view(Vector2(-6, -4), 110.0, 32.0)
	var ceiling := 26.0
	_ceiling(ceiling)
	var start := Vector2(0, 0)
	_circle(start, value, FAINT)
	var t := _phase(3.0)
	for i in 6:
		var angle := deg_to_rad(15.0 + i * 12.0)
		var dir := Vector2(cos(angle), sin(angle))
		var hit := start + dir * (ceiling / dir.y)
		var holds := hit.distance_to(start) <= value
		var end := hit if holds else start + dir * value
		var reached := start.lerp(end, minf(t * 1.6, 1.0))
		_line(start, reached, ROPE if holds else MISS, 1.5)
		if t * 1.6 >= 1.0:
			_hook(end, ROPE if holds else MISS)
	_player(start)
	_caption("rope %.0f m: gold holds, red gives up" % value)


## Hits closer than min_hook_distance do not hold.
func _draw_reach_min() -> void:
	_view(Vector2(-12, -2), 30.0, 8.0)
	var ceiling := 4.0
	_ceiling(ceiling)
	var start := Vector2(0, 0)
	_circle(start, value, MISS)
	var angle := deg_to_rad(lerpf(90.0, 15.0, _phase(3.0)))
	var hit := start + Vector2(cos(angle), sin(angle)) * (ceiling / sin(angle))
	var holds := hit.distance_to(start) >= value
	_line(start, hit, ROPE if holds else MISS)
	_hook(hit, ROPE if holds else MISS)
	_player(start)
	_caption("hit %.1f m away: %s" % [hit.distance_to(start), "holds" if holds else "too close"])


## Right under the ceiling the throw goes flatter until it bites far enough.
func _draw_reach_assist() -> void:
	_view(Vector2(-4, -2), 50.0, 7.0)
	var ceiling := 3.0
	_ceiling(ceiling)
	var start := Vector2(0, 0)
	var pitch := _v("Player/throw_pitch", 50.0)
	var steps := []
	var p := pitch
	while true:
		var a := deg_to_rad(maxf(p, 5.0))
		var d := ceiling / sin(a)
		steps.append([a, d])
		if d >= value or p <= 5.0:
			break
		p -= 10.0
	var total := 0.6 * steps.size() + 1.0
	var shown := mini(int(_phase(total) * total / 0.6), steps.size() - 1)
	for i in shown + 1:
		var a: float = steps[i][0]
		var d: float = steps[i][1]
		var hit := start + Vector2(cos(a), sin(a)) * d
		var last := i == steps.size() - 1
		_line(start, hit, ROPE if last else MISS, 2.0 if last else 1.0)
		_hook(hit, ROPE if last else MISS)
	_player(start)
	_caption("rock closer than %.0f m: throw flatter in 10° steps" % value)


## Seen from above: the sideways swipe turns the throw.
func _draw_yaw() -> void:
	var center := Vector2(size.x * 0.62, size.y - 20.0)
	var swipe := sin(_time * 1.4) * 0.6
	var throw := clampf(swipe * value, -1.4, 1.4)
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(center.x + side * 150.0 - 6.0, 0, 12, size.y), ROCK)
	var dir := Vector2(sin(throw), -cos(throw))
	draw_line(center, center + dir * 180.0, ROPE, 3.0, true)
	draw_circle(center, 8.0, PLAYER)
	# The finger on the screen.
	var finger := Vector2(80, size.y - 40)
	draw_line(finger, finger + Vector2(sin(swipe), -cos(swipe)) * 110.0, HOOK, 4.0, true)
	draw_circle(finger + Vector2(sin(swipe), -cos(swipe)) * 110.0, 9.0, HOOK)
	_text(Vector2(20, 24), "swipe %+.0f°" % rad_to_deg(swipe))
	_text(Vector2(center.x - 60, 24), "throw %+.0f° (top view)" % rad_to_deg(throw))


## A time window after an event.
func _draw_timeline() -> void:
	var labels := {
		"Player/throw_buffer_time": ["swipe while the hook flies", "kept, thrown when it lands"],
		"Player/swing_time": ["hook bites", "swing without pulling"],
		"Player/contact_release_grace": ["hook bites", "touching rock does not let go"],
		"Effects/hit_stop_time": ["hook bites", "game nearly frozen"],
	}
	var text: Array = labels.get(key, ["event", "window"])
	var span := 0.25 if key == "Effects/hit_stop_time" else 1.0
	var left := 40.0
	var width := size.x - 80.0
	var y := size.y * 0.55
	draw_line(Vector2(left, y), Vector2(left + width, y), FAINT, 2.0)
	for i in 5:
		var x := left + width * i / 4.0
		draw_line(Vector2(x, y - 6), Vector2(x, y + 6), FAINT, 2.0)
		_text(Vector2(x - 12, y + 30), "%ss" % str(snappedf(span * i / 4.0, 0.01)), FAINT)
	var bar := width * clampf(value / span, 0.0, 1.0)
	draw_rect(Rect2(left, y - 18, bar, 14), ROPE)
	draw_line(Vector2(left, y - 40), Vector2(left, y + 6), HOOK, 3.0)
	_text(Vector2(left + 6, y - 46), text[0])
	var cursor := left + width * _phase(1.6)
	draw_line(Vector2(cursor, y - 22), Vector2(cursor, y + 8), PLAYER, 3.0)
	_caption("%s: %.2f s" % [text[1], value])


func _draw_slowmo() -> void:
	var t := _phase(3.0)
	for row in 2:
		var y := size.y * (0.33 + row * 0.33)
		var speed := 1.0 if row == 0 else value
		var x := fmod(t * speed * 3.0, 1.0) * (size.x - 80.0) + 40.0
		draw_line(Vector2(40, y), Vector2(size.x - 40, y), FAINT, 1.0)
		draw_circle(Vector2(x, y), 9.0, PLAYER if row == 1 else HOOK)
		_text(Vector2(40, y - 16), "normal" if row == 0 else "while aiming (x%.2f)" % value)


## The throw would hit ice; the assist finds rock within the cone.
func _draw_assist() -> void:
	_view(Vector2(-6, -2), 70.0, 25.0)
	var ceiling := 20.0
	var ice_from := 8.0
	var ice_to := 30.0
	_ceiling(ceiling)
	draw_rect(Rect2(_to(Vector2(ice_from, ceiling + 10)), _to(Vector2(ice_to, ceiling)) - _to(Vector2(ice_from, ceiling + 10))), ICE)
	var start := Vector2(0, 0)
	var aim := deg_to_rad(lerpf(70.0, 40.0, 0.5 + 0.5 * sin(_time)))
	var cone := deg_to_rad(value)
	for side: float in [-1.0, 1.0]:
		var a := aim + side * cone
		_line(start, start + Vector2(cos(a), sin(a)) * (ceiling / maxf(sin(a), 0.2)), FAINT, 1.0)
	var hit_x := ceiling / tan(aim)
	var on_ice := hit_x > ice_from and hit_x < ice_to
	var target := Vector2(hit_x, ceiling)
	var assisted := false
	if on_ice:
		# Closest rock inside the cone: the ice edges.
		for edge: float in [ice_from - 0.5, ice_to + 0.5]:
			var a := atan2(ceiling, edge)
			if absf(a - aim) <= cone:
				target = Vector2(edge, ceiling)
				assisted = true
				break
	_dashed(start, Vector2(hit_x, ceiling), ICE if on_ice else FAINT)
	_line(start, target, ROPE if not on_ice or assisted else MISS)
	_hook(target, ROPE if not on_ice or assisted else MISS)
	_player(start)
	var state := "hits rock" if not on_ice else ("assist finds rock" if assisted else "ice, nothing in the cone")
	_caption("cone ±%.0f°: %s" % [value, state])


## The pull toward the anchor and its speed over time.
func _pull_speed(t: float) -> float:
	var reel := minf(_v("Player/reel_speed", 8.0) + _v("Player/reel_acceleration", 30.0) * t, _v("Player/reel_max_speed", 30.0))
	var speed := reel + _v("Player/tension_boost", 6.0) * t + _v("Player/pull_impulse", 6.0) * exp(-3.0 * t)
	return minf(speed, _v("Player/max_speed", 50.0))


func _draw_pull() -> void:
	_view(Vector2(-4, -4), 90.0, 31.0)
	var anchor := Vector2(46, 24)
	var start := Vector2(0, 0)
	var distance := start.distance_to(anchor)
	_ceiling(25.0)
	# Time to cover the distance.
	var total := 0.0
	var covered := 0.0
	var speeds := PackedFloat32Array()
	while covered < distance - 2.5 and total < 4.0:
		speeds.append(_pull_speed(total))
		covered += _pull_speed(total) * 0.02
		total += 0.02
	var t := minf(_phase(total + 0.5) * (total + 0.5), total)
	var s := 0.0
	var k := 0.0
	while k < t:
		s += _pull_speed(k) * 0.02
		k += 0.02
	var p := start.lerp(anchor, clampf(s / distance, 0.0, 1.0))
	_line(p + Vector2(0, 0.8), anchor, ROPE)
	_hook(anchor)
	_player(p)
	# Speed graph at the bottom right.
	var graph := Rect2(size.x * 0.58, size.y * 0.5, size.x * 0.38, size.y * 0.38)
	draw_rect(graph, Color(0, 0, 0, 0.4))
	var top := 50.0
	for i in speeds.size() - 1:
		var a := graph.position + Vector2(graph.size.x * i / speeds.size(), graph.size.y * (1.0 - speeds[i] / top))
		var b := graph.position + Vector2(graph.size.x * (i + 1) / speeds.size(), graph.size.y * (1.0 - speeds[i + 1] / top))
		draw_line(a, b, ROPE, 2.0, true)
	var cursor := graph.position.x + graph.size.x * t / maxf(total, 0.01)
	draw_line(Vector2(cursor, graph.position.y), Vector2(cursor, graph.end.y), FAINT, 1.0)
	_text(graph.position + Vector2(6, 18), "speed", FAINT, 14)
	_caption("%.0f m in %.2f s, up to %.0f m/s" % [distance, total, _pull_speed(total)])


## Pulled to the anchor: released inside the zip circle (or held at the
## shortest rope), flying on with the boost.
func _draw_zip() -> void:
	_view(Vector2(-4, -6), 70.0, 25.0)
	var anchor := Vector2(40, 16)
	var start := Vector2(0, 0)
	_ceiling(17.0)
	var zip := _v("Player/zip_release_distance", 2.5)
	var boost := _v("Player/zip_boost", 3.0)
	var min_rope := _v("Player/min_rope_length", 0.5)
	var dir := (anchor - start).normalized()
	var release := anchor - dir * zip
	var t := _phase(2.2)
	if kind == "zip_min":
		# Pulled in until the rope is at its shortest: hang there, or (rope end
		# release on) let go and fly on.
		var stop := anchor - dir * maxf(min_rope, 0.6)
		var lets_go := _v("Player/rope_end_release", 1.0) >= 0.5
		_circle(anchor, maxf(min_rope, 0.3), FAINT)
		var p := start.lerp(stop, minf(t * 1.5, 1.0))
		if lets_go and t * 1.5 > 1.0:
			p = stop + dir * 30.0 * (t - 1.0 / 1.5)
			_arrow(p, p + dir * 6.0, ROPE)
		else:
			_line(p, anchor, ROPE)
		_hook(anchor)
		_player(p)
		_caption("shortest rope %.1f m: %s" % [min_rope, "lets go, flies on" if lets_go else "hangs there"])
		return
	_circle(anchor, zip, ROPE if kind == "zip" else FAINT)
	var p: Vector2
	if t < 0.6:
		p = start.lerp(release, t / 0.6)
		_line(p, anchor, ROPE)
	else:
		var speed := 30.0 + boost
		p = release + dir * speed * (t - 0.6) * 0.9
	_hook(anchor)
	_player(p)
	if t >= 0.6:
		_arrow(p, p + dir * (6.0 + boost * 1.5), ROPE)
	if kind == "zip_boost":
		_caption("released with +%.1f m/s" % boost)
	else:
		_caption("lets go %.1f m before the anchor%s" % [zip, " (off: pulled into the rock)" if zip <= 0.0 else ""])


## Swinging past the anchor: released inside the circle instead of swinging back.
func _draw_flyby() -> void:
	_view(Vector2(-30, -8), 70.0, 29.0)
	var anchor := Vector2(0, 18)
	_ceiling(19.0)
	_circle(anchor, value, ROPE)
	var t := _phase(2.4)
	# After a pull the player passes close under the anchor.
	var radius := 4.0
	var p: Vector2
	if value >= radius:
		# Released at the lowest point: flies on to the right.
		var angle := lerpf(-PI * 0.95, -PI / 2.0, minf(t / 0.35, 1.0))
		p = anchor + Vector2(cos(angle), sin(angle)) * radius
		if t < 0.35:
			_line(p, anchor, ROPE)
		else:
			var since := t - 0.35
			p = anchor + Vector2(0, -radius) + Vector2(since * 40.0, -since * since * 20.0)
	else:
		# Not released: the rope swings the player back and forth.
		var angle := lerpf(-PI * 0.95, -PI * 0.05, pingpong(t * 2.0, 1.0))
		p = anchor + Vector2(cos(angle), sin(angle)) * radius
		_line(p, anchor, ROPE)
	_hook(anchor)
	_player(p)
	_caption("passing within %.1f m: fly on" % value if value >= radius else "circle too small: the rope swings you back")


func _draw_rope_pluck() -> void:
	_view(Vector2(-2, -6), 50.0, 12.0)
	var a := Vector2(0, 0)
	var b := Vector2(44, 0)
	var since := fmod(_time, 1.6)
	var height := value * exp(-9.0 * since)
	var points := PackedVector2Array()
	for i in 41:
		var t := i / 40.0
		points.append(_to(a.lerp(b, t) + Vector2(0, sin(PI * t) * height * 4.0 * sin(since * 55.0))))
	draw_polyline(points, ROPE, 2.0, true)
	_hook(b)
	_player(a)
	_caption("wobble %.2f m when the hook bites" % value)


func _draw_rope_slack() -> void:
	_view(Vector2(-2, -12), 50.0, 22.0)
	var a := Vector2(0, 0)
	var t := minf(_phase(1.8) * 1.4, 1.0)
	var b := Vector2(44, 6) * t
	var length := a.distance_to(b)
	var sag := length * sqrt(maxf(3.0 * (value - 1.0) / 8.0, 0.0))
	var points := PackedVector2Array()
	for i in 41:
		var u := i / 40.0
		points.append(_to(a.lerp(b, u) + Vector2(0, -4.0 * sag * u * (1.0 - u))))
	draw_polyline(points, ROPE, 2.0, true)
	_hook(b)
	_player(a)
	_caption("sags %.1f m on a %.0f m flight" % [sag, length])


func _draw_fall() -> void:
	_view(Vector2(-10, -2), 60.0, 30.0)
	var top := 26.0
	_floor(0.0)
	var t := _phase(2.0) * 2.0
	for row in 2:
		var g := value if row == 0 else 22.0
		var x := 10.0 if row == 0 else 30.0
		var y := maxf(top - 0.5 * g * t * t, 0.5)
		_player(Vector2(x, y), PLAYER if row == 0 else FAINT)
	_text(_to(Vector2(14, top)), "%.0f m/s²" % value)
	_text(_to(Vector2(34, top)), "default 22", FAINT)
	_caption("falls %.0f m in 1 s" % (0.5 * value))


func _draw_speed_cap() -> void:
	var t := _phase(3.0)
	var speed := minf(t * 120.0, value)
	var left := 40.0
	var width := size.x - 80.0
	var y := size.y * 0.5
	draw_rect(Rect2(left, y - 14, width, 28), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(left, y - 14, width * speed / 120.0, 28), ROPE)
	var cap := left + width * value / 120.0
	draw_line(Vector2(cap, y - 30), Vector2(cap, y + 30), MISS, 3.0)
	_text(Vector2(cap - 30, y - 36), "limit")
	_caption("%.0f m/s (max %.0f)" % [speed, value])


## Sliding to a stop: slide braking above the slide speed, floor braking below.
func _draw_ground() -> void:
	_view(Vector2(-4, -3), 90.0, 20.0)
	_floor(0.0)
	var floor_brake := _v("Player/floor_friction", 25.0)
	var slide_brake := _v("Player/slide_friction", 6.0)
	var slide_speed := 8.0
	var v0 := 30.0
	# Stop distance and time of the two phases.
	var t1 := (v0 - slide_speed) / maxf(slide_brake, 0.01)
	var d1 := (v0 + slide_speed) / 2.0 * t1
	var t2 := slide_speed / maxf(floor_brake, 0.01)
	var d2 := slide_speed / 2.0 * t2
	var t := minf(_phase(minf(t1 + t2, 8.0) + 1.0) * (minf(t1 + t2, 8.0) + 1.0), t1 + t2)
	var x: float
	if t < t1:
		x = v0 * t - 0.5 * slide_brake * t * t
	else:
		var u := t - t1
		x = d1 + slide_speed * u - 0.5 * floor_brake * u * u
	_player(Vector2(minf(x, 85.0), 0.8))
	_caption("from 30 m/s: stops after %.0f m" % (d1 + d2))


func _draw_landing() -> void:
	_view(Vector2(-4, -3), 80.0, 26.0)
	_floor(0.0)
	var t := _phase(2.4)
	var fall_speed := 20.0
	var roll := value * fall_speed
	var p: Vector2
	if t < 0.4:
		var u := t / 0.4
		p = Vector2(10.0 + u * 10.0, 20.0 * (1.0 - u * u) + 0.8)
	else:
		var u := (t - 0.4) * 2.4
		p = Vector2(20.0 + (5.0 + roll) * u, 0.8)
		_arrow(p + Vector2(0, 3), p + Vector2(3.0 + roll * 0.6, 3), ROPE)
	_player(p)
	_caption("falling at 20 m/s: rolls on at +%.0f m/s" % roll)


func _draw_deflect() -> void:
	_view(Vector2(-4, -4), 70.0, 24.0)
	var ceiling := 18.0
	_ceiling(ceiling)
	var t := _phase(2.0)
	var speed := 30.0
	var angle := deg_to_rad(30.0)
	var hit := Vector2(ceiling / tan(angle), ceiling - 1.0)
	var start := hit - Vector2(cos(angle), sin(angle)) * 30.0
	var into := sin(angle) * speed
	var along := cos(angle) * speed + into * value * cos(angle)
	along = minf(along, speed)
	var p: Vector2
	if t < 0.5:
		p = start.lerp(hit, t / 0.5)
	else:
		p = hit + Vector2(along * (t - 0.5) * 1.2, 0)
	_dashed(start, hit, FAINT)
	_player(p)
	_caption("30 m/s at 30° into the ceiling: glides on at %.0f m/s" % along)


func _draw_wallkick() -> void:
	# Top view: wall on the right.
	var wall_x := size.x * 0.75
	draw_rect(Rect2(wall_x, 0, 14, size.y), ROCK)
	var t := _phase(2.0)
	var hit := Vector2(wall_x - 8.0, size.y * 0.45)
	var speed := 140.0
	var into := Vector2(1, -0.6).normalized()
	var bounce := _v("Player/wall_bounce", 0.2)
	var out := Vector2(-bounce * into.x, into.y).normalized() if bounce > 0.0 else Vector2(0, -1)
	var p: Vector2
	if t < 0.5:
		p = hit - into * speed * (1.0 - t / 0.5)
	else:
		p = hit + out * speed * (t - 0.5) * (0.6 + bounce)
	draw_circle(p, 8.0, PLAYER)
	draw_line(hit - into * speed, hit, FAINT, 1.0)
	_text(Vector2(20, 26), "top view")
	_caption("bounce %.0f%% off the wall, kick up %.1f m/s" % [bounce * 100.0, _v("Player/wall_kick_up", 4.0)])


func _camera_icon(at: Vector2, look: Vector2) -> void:
	var s := _to(at)
	var d := (_to(look) - s).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([s - d * 10 + n * 7, s - d * 10 - n * 7, s + d * 6 - n * 7, s + d * 6 + n * 7]), HOOK)
	draw_colored_polygon(PackedVector2Array([s + d * 6, s + d * 14 + n * 6, s + d * 14 - n * 6]), HOOK)
	draw_line(s, _to(look), Color(1, 1, 1, 0.2), 1.0)


func _draw_camera_follow() -> void:
	_view(Vector2(-10, -12), 60.0, 24.0)
	var p := Vector2(20.0 + sin(_time * 2.2) * 14.0, sin(_time * 3.1) * 6.0)
	# Camera position with the same smoothing as camera_rig.gd.
	var lag := 1.0 - exp(-value / 60.0)
	var cam := p + Vector2(-10, 3.5)
	# Replay the last 2 s at 60 Hz to get the smoothed position now.
	var smoothed := Vector2.ZERO
	for i in 121:
		var past := (120 - i) / 60.0
		var spot := Vector2(20.0 + sin((_time - past) * 2.2) * 14.0, sin((_time - past) * 3.1) * 6.0) + Vector2(-10, 3.5)
		smoothed = spot if i == 0 else smoothed.lerp(spot, lag)
	_player(p)
	_camera_icon(smoothed, p)
	_caption("camera lags %.1f m behind its spot" % smoothed.distance_to(cam))


func _draw_camera_offset() -> void:
	_view(Vector2(-16, -8), 45.0, 20.0)
	var p := Vector2(0, 0)
	var cam := p + Vector2(-_v("CameraRig/offset:z", 10.0), _v("CameraRig/offset:y", 3.5))
	var look := p + Vector2(12.0, _v("CameraRig/look_ahead:y", 3.0))
	_player(p)
	_camera_icon(cam, look)
	draw_circle(_to(look), 4.0, ROPE)
	_caption("camera %.1f m back, %.1f m up, aims %.1f m above" % [cam.x * -1.0, cam.y, look.y])


func _draw_camera_anchor() -> void:
	_view(Vector2(-14, -6), 55.0, 28.0)
	var anchor := Vector2(30, 18)
	var t := _phase(2.0)
	var p := Vector2(0, 0).lerp(anchor - Vector2(4, 3), t)
	var ahead := p + Vector2(12, 3)
	var look := ahead.lerp(anchor, value)
	var cam := p + Vector2(-10, 3.5)
	_line(p, anchor, ROPE)
	_hook(anchor)
	_player(p)
	_camera_icon(cam, look)
	draw_circle(_to(look), 4.0, ROPE)
	_caption("looks %.0f%% toward the anchor" % (value * 100.0))


func _draw_camera_wall() -> void:
	_view(Vector2(-22, -8), 50.0, 18.0)
	var wall := -12.0
	draw_rect(Rect2(Vector2.ZERO, Vector2(_to(Vector2(wall, 0)).x, size.y)), ROCK.darkened(0.3))
	var p := Vector2(-6.0 + sin(_time) * 4.0, 0)
	var wanted := p + Vector2(-10, 3.5)
	var cam := wanted
	if wanted.x < wall + value:
		cam = Vector2(wall + value, wanted.y)
		_dashed(wanted, cam, FAINT)
	_player(p)
	_camera_icon(cam, p + Vector2(10, 3))
	_caption("stays %.1f m in front of the rock" % value)


func _draw_camera_ceiling() -> void:
	_view(Vector2(-16, -8), 45.0, 20.0)
	var ceiling := 10.0
	_ceiling(ceiling)
	var near := _v("CameraRig/ceiling_near", 7.0)
	var look_up := _v("CameraRig/ceiling_look_up", 4.0)
	var p := Vector2(0, lerpf(-6.0, ceiling - 1.0, 0.5 + 0.5 * sin(_time * 1.2)))
	var gap := ceiling - p.y
	var factor := clampf(1.0 - gap / maxf(near, 0.01), 0.0, 1.0)
	_dashed(Vector2(-30, ceiling - near), Vector2(30, ceiling - near), FAINT)
	var cam := p + Vector2(-10, 3.5 - 4.5 * factor)
	var look := p + Vector2(12, 3 + look_up * factor)
	_player(p)
	_camera_icon(cam, look)
	_caption("ceiling %.1f m above: camera %s" % [gap, "drops and looks up" if factor > 0.0 else "normal"])


func _draw_fov() -> void:
	var base := _v("CameraRig/base_fov", 65.0)
	var per := _v("CameraRig/fov_per_speed", 0.4)
	var top := _v("CameraRig/max_fov", 90.0)
	var kick := _v("CameraRig/zip_fov_kick", 12.0)
	var speed := 25.0 + 25.0 * sin(_time * 1.3)
	var fov := clampf(base + speed * per, base, top)
	if kind == "fov_kick":
		fov += kick * exp(-6.0 * fmod(_time, 1.5))
	var cam := Vector2(size.x * 0.5, size.y - 14.0)
	var half := deg_to_rad(fov) / 2.0
	var reach := size.y * 0.9
	draw_colored_polygon(PackedVector2Array([cam, cam + Vector2(sin(-half), -cos(half)) * reach / cos(half),
			cam + Vector2(sin(half), -cos(half)) * reach / cos(half)]), Color(1, 1, 1, 0.12))
	draw_circle(cam, 8.0, HOOK)
	_text(Vector2(20, 26), "top view")
	_caption("speed %.0f m/s -> view %.0f°" % [speed, fov])


func _draw_roll() -> void:
	var per := _v("CameraRig/roll_per_speed", 1.2)
	var most := _v("CameraRig/max_roll", 12.0)
	var sideways := sin(_time * 1.2) * 30.0
	var roll := deg_to_rad(clampf(sideways * per, -most, most))
	var c := size / 2.0
	var d := Vector2(cos(roll), sin(roll)) * size.x
	draw_line(c - d, c + d, ROCK, 4.0)
	draw_rect(Rect2(c - Vector2(110, 70), Vector2(220, 140)), FAINT, false, 2.0)
	draw_circle(c + Vector2(sideways * 2.0, 30), 8.0, PLAYER)
	_caption("sideways %.0f m/s -> lean %.0f°" % [sideways, rad_to_deg(roll)])


func _draw_shake() -> void:
	var since := fmod(_time, 1.4)
	var amount := value * exp(-6.0 * since) * 40.0
	var offset := Vector2(sin(_time * 70.0), cos(_time * 53.0)) * amount
	var frame := Rect2(size / 2.0 - Vector2(120, 70) + offset, Vector2(240, 140))
	draw_rect(frame, ROCK.darkened(0.4))
	draw_rect(frame, HOOK, false, 2.0)
	draw_circle(frame.get_center(), 8.0, PLAYER)
	_caption("shake up to %.2f m when the hook bites" % value)


func _draw_pixels() -> void:
	var px := maxf(value, 1.0) * 4.0
	var center := size / 2.0
	var radius := 70.0
	var x := center.x - radius
	while x < center.x + radius:
		var y := center.y - radius
		while y < center.y + radius:
			var cell := Vector2(x + px / 2.0, y + px / 2.0)
			if cell.distance_to(center) < radius:
				var light := 1.0 - cell.distance_to(center - Vector2(25, 25)) / (radius * 1.8)
				draw_rect(Rect2(x, y, px, px), ICE * clampf(light, 0.2, 1.0))
			y += px
		x += px
	_caption("one game pixel = %d screen pixels" % int(value))


func _draw_volume() -> void:
	var c := Vector2(size.x * 0.35, size.y * 0.5)
	draw_rect(Rect2(c - Vector2(30, 16), Vector2(20, 32)), HOOK)
	draw_colored_polygon(PackedVector2Array([c - Vector2(10, 16), c + Vector2(20, -40), c + Vector2(20, 40), c + Vector2(-10, 16)]), HOOK)
	for i in 3:
		var strength := clampf(value * 3.0 - i, 0.0, 1.0)
		var r := 50.0 + i * 26.0 + fmod(_time * 30.0, 26.0)
		draw_arc(c + Vector2(20, 0), r, -0.7, 0.7, 16, Color(1, 1, 1, 0.8 * strength), 4.0)
	_caption("volume %d %%" % roundi(value * 100.0))


func _draw_toggle() -> void:
	var on := value >= 0.5
	var c := Vector2(size.x * 0.5, size.y * 0.45)
	draw_rect(Rect2(c - Vector2(60, 26), Vector2(120, 52)), ROPE if on else FAINT)
	draw_circle(c + Vector2(30 if on else -30, 0), 22.0, HOOK)
	if key == "Effects/haptics" and on:
		var buzz := sin(_time * 60.0) * 4.0 if fmod(_time, 1.2) < 0.15 else 0.0
		draw_rect(Rect2(c + Vector2(120 + buzz, -40), Vector2(44, 80)), HOOK, false, 3.0)
	_caption("on" if on else "off")


func _draw_fps() -> void:
	var target := _v("Debug/min_fps", 45.0)
	var auto := _v("Debug/auto_quality", 1.0) >= 0.5
	var graph := Rect2(30, 20, size.x - 60, size.y - 60)
	draw_rect(graph, Color(0, 0, 0, 0.4))
	var points := PackedVector2Array()
	var low := 0
	for i in 60:
		var t := _time - (59 - i) * 0.1
		var fps := 50.0 + 12.0 * sin(t * 0.9) + 4.0 * sin(t * 3.7)
		if fps < target:
			low += 1
		points.append(graph.position + Vector2(graph.size.x * i / 59.0, graph.size.y * (1.0 - (fps - 20.0) / 45.0)))
	draw_polyline(points, ROPE, 2.0, true)
	var line_y := graph.position.y + graph.size.y * (1.0 - (target - 20.0) / 45.0)
	draw_line(Vector2(graph.position.x, line_y), Vector2(graph.end.x, line_y), MISS, 2.0)
	_caption("below %.0f fps for a while: %s" % [target, "pixels get bigger" if auto else "auto quality off"])


func _draw_streaks() -> void:
	var speed := 25.0 + 25.0 * sin(_time * 0.9)
	var on := speed >= value
	if on:
		var density := clampf((speed - value) / 15.0, 0.1, 1.0)
		for i in 14:
			var y := fmod(i * 37.0 + _time * 400.0 * (0.6 + 0.04 * i), size.y + 60.0) - 30.0
			var x := fmod(i * 97.0, size.x)
			draw_line(Vector2(x, y), Vector2(x, y + 30.0), Color(1, 1, 1, 0.6 * density), 2.0)
	var bar := Rect2(30, size.y - 50, size.x - 60, 12)
	draw_rect(bar, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * speed / 60.0, bar.size.y)), ROPE)
	var mark := bar.position.x + bar.size.x * value / 60.0
	draw_line(Vector2(mark, bar.position.y - 10), Vector2(mark, bar.end.y + 4), MISS, 3.0)
	_text(Vector2(20, 26), "speed %.0f m/s %s" % [speed, "-> lines" if on else ""])
