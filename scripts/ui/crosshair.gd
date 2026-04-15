extends Control
class_name Crosshair

@export var gap: float = 10.0
@export var line_length: float = 8.0
@export var line_width: float = 1
@export var crosshair_color: Color = Color.GRAY

var _base_gap: float = 10.0
var _tween: Tween = null

func update_gap(new_gap: float) -> void:
	gap = new_gap
	_base_gap = new_gap
	queue_redraw()

func animate_spread(spread_amount: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	var peak := _base_gap + spread_amount
	_tween = create_tween()
	_tween.tween_method(_set_gap, _base_gap, peak, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_gap, peak, _base_gap, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _set_gap(value: float) -> void:
	gap = value
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	# Arriba
	draw_rect(Rect2(center.x - line_width / 2.0, center.y - gap - line_length, line_width, line_length), crosshair_color)
	# Abajo
	draw_rect(Rect2(center.x - line_width / 2.0, center.y + gap, line_width, line_length), crosshair_color)
	# Izquierda
	draw_rect(Rect2(center.x - gap - line_length, center.y - line_width / 2.0, line_length, line_width), crosshair_color)
	# Derecha
	draw_rect(Rect2(center.x + gap, center.y - line_width / 2.0, line_length, line_width), crosshair_color)
