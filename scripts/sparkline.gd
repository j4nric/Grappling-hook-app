class_name Sparkline
extends Control
## Small curve of finish times (oldest left): each finish a dot, faster runs
## higher; the gold line is the best time so far.

const DOT := 4.0
const LINE_COLOR := Color(1, 1, 1, 0.35)
const TEXT_COLOR := Color(1, 1, 1, 0.7)
const BEST_COLOR := Color(0.91, 0.77, 0.28)
const FONT_SIZE := 20

var times: Array = []:
	set(value):
		times = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(0, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if times.size() < 2:
		return
	var font := get_theme_default_font()
	var label_height := float(FONT_SIZE) + 6.0
	var area := Rect2(DOT, DOT, size.x - 2.0 * DOT, size.y - label_height - 2.0 * DOT)
	var slowest: float = times.max()
	var fastest: float = times.min()
	var span := maxf(slowest - fastest, 0.01)
	var points := PackedVector2Array()
	var best_line := PackedVector2Array()
	var best := INF
	for i in times.size():
		var t := float(times[i])
		var x := area.position.x + area.size.x * i / (times.size() - 1)
		var y := area.position.y + area.size.y * (t - fastest) / span
		points.append(Vector2(x, y))
		if t < best:
			if not best_line.is_empty():
				best_line.append(Vector2(x, best_line[-1].y))
			best = t
		best_line.append(Vector2(x, area.position.y + area.size.y * (best - fastest) / span))
	draw_polyline(points, LINE_COLOR, 2.0, true)
	draw_polyline(best_line, BEST_COLOR, 3.0, true)
	for p in points:
		draw_circle(p, DOT, Color.WHITE)
	var bottom := size.y - 4.0
	draw_string(font, Vector2(0, bottom), "first %.2f s" % float(times[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	draw_string(font, Vector2(0, bottom), "best %.2f s   %d finishes" % [fastest, times.size()],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x, FONT_SIZE, BEST_COLOR)
