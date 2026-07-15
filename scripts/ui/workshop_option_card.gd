class_name WorkshopOptionCard
extends Button

const NEUTRAL_SHAPE_COLOR := Color(0.72, 0.82, 0.92, 1.0)
const NEON_STYLE := preload("res://scripts/ui/neon_style.gd")

var _option_kind: String = "shape"
var _option_id: String = "circle"
var _title: String = ""
var _description: String = ""
var _details: Array[String] = []
var _accent_color: Color = Color(0.4, 0.86, 1.0)
var _is_locked: bool = false
var _is_future: bool = false
var _is_selected: bool = false
var _availability_state: String = "available"
var _status_message: String = "Available"


func _ready() -> void:
	resized.connect(queue_redraw)


func configure(option_kind: String, data: Dictionary, description: String, details: Array[String]) -> void:
	_option_kind = option_kind
	_option_id = str(data.get("id", ""))
	_title = str(data.get("display_name", "Unknown"))
	_description = description
	_details = details
	_availability_state = str(data.get("availability_state", "available"))
	_is_locked = _availability_state != "available"
	_is_future = _availability_state == "coming_soon"
	_status_message = str(data.get("status_message", "Coming Soon" if _is_future else "Unlock in Echo Tree"))
	if _option_kind == "shape":
		_accent_color = NEUTRAL_SHAPE_COLOR
	else:
		var color_value: Variant = data.get("primary_color", data.get("base_color", Color(0.4, 0.86, 1.0)))
		if color_value is Color:
			_accent_color = color_value

	disabled = _is_locked
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if _is_locked else Control.CURSOR_POINTING_HAND
	tooltip_text = _get_tooltip_text()
	custom_minimum_size = Vector2(0.0, 70.0 if _is_locked else _get_card_height())
	_update_style()
	queue_redraw()


func set_selected(value: bool) -> void:
	_is_selected = value and not _is_locked
	_update_style()
	queue_redraw()


func _get_card_height() -> float:
	return 144.0 if _option_kind == "cast_type" else 94.0


func _get_tooltip_text() -> String:
	if not _is_locked:
		return _title
	return "%s: %s" % [_title, _status_message]


func _update_style() -> void:
	var border_color: Color = _accent_color if _is_selected else Color(NEON_STYLE.CYAN.r, NEON_STYLE.CYAN.g, NEON_STYLE.CYAN.b, 0.28)
	var normal_color: Color = Color(0.018, 0.043, 0.08, 0.98)
	if _is_selected:
		normal_color = Color(_accent_color.r * 0.13, _accent_color.g * 0.13, _accent_color.b * 0.13, 1.0)
	if _is_locked:
		normal_color = Color(0.035, 0.045, 0.06, 0.88)
		border_color = Color(0.14, 0.17, 0.21, 0.8)

	add_theme_stylebox_override("normal", _create_style(normal_color, border_color, 1.5 if _is_selected else 1.0))
	add_theme_stylebox_override("hover", _create_style(normal_color.lightened(0.05), _accent_color.lightened(0.12), 1.8))
	add_theme_stylebox_override("pressed", _create_style(normal_color.darkened(0.03), Color(1.0, 0.94, 0.72, 1.0), 2.0))
	add_theme_stylebox_override("disabled", _create_style(normal_color, border_color, 1.0))


func _create_style(background_color: Color, border_color: Color, border_width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(int(round(border_width)))
	style.set_corner_radius_all(6)
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.16)
	style.shadow_size = 6
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var title_color: Color = _accent_color if not _is_locked else Color(0.42, 0.47, 0.54, 1.0)
	var body_color: Color = Color(0.78, 0.85, 0.92, 1.0) if not _is_locked else Color(0.37, 0.42, 0.48, 1.0)
	var icon_center := Vector2(size.x - 27.0, 27.0)
	if _is_selected:
		draw_circle(icon_center, 29.0, Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.08))
	_draw_icon(icon_center, title_color)

	draw_string(font, Vector2(12.0, 23.0), _title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 54.0, 15, title_color)
	if _is_locked:
		draw_string(font, Vector2(12.0, 47.0), _status_message.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 12, body_color)
		return

	draw_string(font, Vector2(12.0, 45.0), _description, HORIZONTAL_ALIGNMENT_LEFT, size.x - 54.0, 12, body_color)
	var y: float = 68.0
	for detail in _details:
		draw_string(font, Vector2(12.0, y), detail, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 11, body_color)
		y += 18.0

	if _is_selected:
		draw_string(font, Vector2(size.x - 74.0, size.y - 11.0), "SELECTED", HORIZONTAL_ALIGNMENT_RIGHT, 64.0, 10, _accent_color.lightened(0.15))


func _draw_icon(center: Vector2, color: Color) -> void:
	var glow: Color = color
	glow.a = 0.16
	draw_circle(center, 22.0, glow)
	match _option_kind:
		"shape":
			_draw_shape_icon(center, 13.0, color)
		"element":
			_draw_element_icon(center, color)
		_:
			_draw_cast_icon(center, color)


func _draw_shape_icon(center: Vector2, radius: float, color: Color) -> void:
	match _option_id:
		"triangle":
			var triangle := PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius, radius * 0.78), center + Vector2(-radius, radius * 0.78)])
			draw_colored_polygon(triangle, color)
			draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), Color.WHITE, 1.2)
		"square":
			var rect := Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
			draw_rect(rect, color, true)
			draw_rect(rect, Color.WHITE, false, 1.2)
		"diamond":
			var diamond := PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius, 0.0), center + Vector2(0.0, radius), center + Vector2(-radius, 0.0)])
			draw_colored_polygon(diamond, color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color.WHITE, 1.2)
		"star":
			var star := PackedVector2Array()
			for index in 10:
				var angle: float = -PI * 0.5 + float(index) * PI / 5.0
				var point_radius: float = radius if index % 2 == 0 else radius * 0.48
				star.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
			draw_colored_polygon(star, color)
			draw_polyline(PackedVector2Array([star[0], star[1], star[2], star[3], star[4], star[5], star[6], star[7], star[8], star[9], star[0]]), Color.WHITE, 1.2)
		"pentagon":
			var pentagon := PackedVector2Array()
			for index in 5:
				var angle: float = -PI * 0.5 + float(index) * TAU / 5.0
				pentagon.append(center + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(pentagon, color)
		_:
			draw_circle(center, radius, color)
			draw_arc(center, radius, 0.0, TAU, 20, Color.WHITE, 1.2, true)


func _draw_element_icon(center: Vector2, color: Color) -> void:
	match _option_id:
		"fire":
			var flame := PackedVector2Array([center + Vector2(0.0, -14.0), center + Vector2(9.0, 8.0), center + Vector2(2.0, 14.0), center + Vector2(-8.0, 8.0)])
			draw_colored_polygon(flame, color)
		"ice":
			draw_line(center + Vector2(-13.0, 0.0), center + Vector2(13.0, 0.0), color, 2.0)
			draw_line(center + Vector2(0.0, -13.0), center + Vector2(0.0, 13.0), color, 2.0)
			draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), color, 2.0)
			draw_line(center + Vector2(9.0, -9.0), center + Vector2(-9.0, 9.0), color, 2.0)
		"electric":
			var bolt := PackedVector2Array([center + Vector2(-3.0, -14.0), center + Vector2(9.0, -3.0), center + Vector2(2.0, -3.0), center + Vector2(7.0, 14.0), center + Vector2(-10.0, 1.0), center + Vector2(-2.0, 1.0)])
			draw_colored_polygon(bolt, color)
		"shadow":
			draw_circle(center, 12.0, color)
			draw_circle(center + Vector2(5.0, -4.0), 10.0, Color(0.025, 0.035, 0.075, 1.0))
			draw_arc(center, 15.0, PI * 0.35, PI * 1.5, 16, Color.WHITE, 1.1, true)
		"poison":	
			draw_circle(center, 11.0, color)
			draw_circle(center + Vector2(-10.0, 8.0), 3.2, color.lightened(0.18))
			draw_circle(center + Vector2(10.0, 7.0), 2.4, color.lightened(0.18))
			draw_arc(center, 14.0, -PI * 0.72, PI * 0.18, 16, Color.WHITE, 1.1, true)
		_:
			draw_circle(center, 12.0, color)
			draw_arc(center, 15.0, 0.0, TAU, 20, Color.WHITE, 1.1, true)


func _draw_cast_icon(center: Vector2, color: Color) -> void:
	match _option_id:
		"chain_lightning":
			draw_polyline(PackedVector2Array([center + Vector2(-14.0, 7.0), center + Vector2(-5.0, -6.0), center + Vector2(2.0, 5.0), center + Vector2(13.0, -9.0)]), color, 2.4)
		"area":
			var field_color: Color = color
			field_color.a = 0.24
			draw_circle(center, 12.0, field_color)
			draw_arc(center, 12.0, 0.0, TAU, 20, color, 2.0, true)
			draw_arc(center, 7.0, 0.0, TAU, 20, color, 1.2, true)
		"slash":
			draw_arc(center, 14.0, -2.4, 0.5, 16, color, 3.2, true)
		"persistent_waves":
			for offset in [-7.0, 0.0, 7.0]:
				draw_line(center + Vector2(-14.0, offset), center + Vector2(14.0, offset - 4.0), color, 1.6)
		"summon":
			draw_circle(center, 5.0, color)
			draw_circle(center + Vector2(-11.0, 7.0), 3.0, color)
			draw_circle(center + Vector2(11.0, 7.0), 3.0, color)
		_:
			draw_circle(center + Vector2(6.0, 0.0), 7.0, color)
			draw_line(center + Vector2(-14.0, 0.0), center + Vector2(2.0, 0.0), color, 2.0)
