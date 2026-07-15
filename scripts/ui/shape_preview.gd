extends Control

const SLASH_GEOMETRY := preload("res://scripts/spells/slash_visual_geometry.gd")
const TARGET_FILL := Color(0.38, 0.44, 0.53, 0.28)
const TARGET_OUTLINE := Color(0.6, 0.68, 0.78, 0.74)
const SUPPORTED_SHAPES := ["circle", "triangle", "square", "diamond", "star", "pentagon"]
const SUPPORTED_CAST_TYPES := ["simple_projectile", "chain_lightning", "area", "slash", "persistent_waves", "summon"]

@export var visual_shape: String = "circle"
@export var fill_color: Color = Color(0.18, 0.78, 1.0)
@export var outline_color: Color = Color(0.82, 0.98, 1.0)
@export var cast_type_id: String = ""
@export var caster_shape_id: String = "circle"

var _preview_time: float = 0.0


func setup(shape: String, fill: Color, outline: Color, cast_type: String = "", caster_shape: String = "circle") -> void:
	visual_shape = _resolve_shape(shape)
	fill_color = fill
	outline_color = outline
	cast_type_id = _resolve_cast_type(cast_type)
	caster_shape_id = _resolve_shape(caster_shape)
	queue_redraw()


func _resolve_shape(shape_id: String) -> String:
	return shape_id if shape_id in SUPPORTED_SHAPES else "circle"


func _resolve_cast_type(cast_type: String) -> String:
	if cast_type.is_empty() or cast_type in SUPPORTED_CAST_TYPES:
		return cast_type
	return "simple_projectile"


func _process(delta: float) -> void:
	_preview_time += delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	if cast_type_id.is_empty():
		_draw_spell_shape(center, minf(size.x, size.y) * 0.32, fill_color, outline_color)
		return

	var caster_position: Vector2 = center + Vector2(-size.x * 0.28, 0.0)
	var target_position: Vector2 = center + Vector2(size.x * 0.25, 0.0)
	var phase: float = fposmod(_preview_time, 1.55) / 1.55
	if cast_type_id != "chain_lightning":
		_draw_target(target_position, 16.0)

	match cast_type_id:
		"chain_lightning":
			_draw_chain_preview(caster_position, target_position, phase)
		"area":
			_draw_area_preview(target_position, phase)
		"slash":
			_draw_slash_preview(target_position, phase)
		"persistent_waves":
			_draw_waves_preview(caster_position, target_position, phase)
		"summon":
			_draw_summon_preview(caster_position, target_position, phase)
		_:
			_draw_projectile_preview(caster_position, target_position, phase)

	_draw_caster(caster_position)


func _draw_caster(position: Vector2) -> void:
	var caster_fill: Color = fill_color.darkened(0.24)
	_draw_geometric_shape(position, 19.0, caster_fill, outline_color, caster_shape_id, false)
	draw_circle(position, 5.0, outline_color)
	draw_line(position + Vector2(12.0, 0.0), position + Vector2(18.0, 0.0), outline_color, 1.4)


func _draw_target(position: Vector2, radius: float) -> void:
	draw_circle(position, radius, TARGET_FILL)
	draw_arc(position, radius, 0.0, TAU, 24, TARGET_OUTLINE, 1.2, true)


func _draw_projectile_preview(source: Vector2, target: Vector2, phase: float) -> void:
	var projectile_position: Vector2 = source.lerp(target, phase)
	var projectile_direction: Vector2 = source.direction_to(target)
	var trail_color: Color = fill_color
	trail_color.a = 0.22
	draw_line(source + Vector2(18.0, 0.0), projectile_position, trail_color, 4.0)
	draw_set_transform(projectile_position, projectile_direction.angle() + PI * 0.5, Vector2.ONE)
	_draw_spell_shape(Vector2.ZERO, 10.0, fill_color, outline_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_chain_preview(source: Vector2, target: Vector2, phase: float) -> void:
	var first_impact: Vector2 = target + Vector2(-26.0, -24.0)
	var second_impact: Vector2 = target + Vector2(22.0, -4.0)
	var third_impact: Vector2 = target + Vector2(-4.0, 28.0)
	var impact_points := PackedVector2Array([source + Vector2(18.0, 0.0), first_impact, second_impact, third_impact])
	var chain_points := _build_preview_chain_line(impact_points)
	var chain_color: Color = fill_color
	chain_color.a = 0.34 + phase * 0.66
	draw_polyline(chain_points, chain_color, 3.0)
	var core_color: Color = outline_color
	core_color.a = 0.92
	draw_polyline(chain_points, core_color, 1.25)
	for target_index in range(1, impact_points.size()):
		_draw_target(impact_points[target_index], 10.0)
	for impact_index in range(impact_points.size()):
		var impact_radius: float = 6.5 if impact_index == 0 else 8.0
		_draw_geometric_shape(impact_points[impact_index], impact_radius, Color(fill_color.r, fill_color.g, fill_color.b, 0.34), outline_color, visual_shape, false)
	for segment_index in range(impact_points.size() - 1):
		var pulse_progress: float = fposmod(phase * 1.8 + float(segment_index) * 0.24, 1.0)
		var pulse_position: Vector2 = impact_points[segment_index].lerp(impact_points[segment_index + 1], pulse_progress)
		_draw_geometric_shape(pulse_position, 3.0, Color(fill_color.r, fill_color.g, fill_color.b, 0.58), outline_color, visual_shape, false)


func _build_preview_chain_line(impact_points: PackedVector2Array) -> PackedVector2Array:
	var chain_points := PackedVector2Array()
	for segment_index in range(impact_points.size() - 1):
		var start: Vector2 = impact_points[segment_index]
		var end: Vector2 = impact_points[segment_index + 1]
		if segment_index == 0:
			chain_points.append(start)
		if visual_shape == "square":
			chain_points.append(Vector2(end.x, start.y))
			chain_points.append(end)
			continue

		var direction: Vector2 = start.direction_to(end)
		var perpendicular := Vector2(-direction.y, direction.x)
		var segment_count: int = 3 if visual_shape == "triangle" else 2
		if visual_shape == "star":
			segment_count = 4
		for point_index in range(1, segment_count):
			var progress: float = float(point_index) / float(segment_count)
			var jitter_amount: float = 10.0 if visual_shape == "triangle" else 6.0
			if visual_shape == "star":
				jitter_amount = 16.0
			var jitter: float = sin(_preview_time * 10.0 + float(segment_index * 3 + point_index)) * jitter_amount
			chain_points.append(start.lerp(end, progress) + perpendicular * jitter)
		chain_points.append(end)
	return chain_points


func _draw_area_preview(field_center: Vector2, phase: float) -> void:
	var field_radius: float = lerpf(size.y * 0.13, size.y * 0.27, phase)
	var field_color: Color = fill_color
	field_color.a = 0.08 + (1.0 - phase) * 0.14
	_draw_geometric_shape(field_center, field_radius, field_color, fill_color, visual_shape, false)
	var inner_field_color: Color = field_color
	inner_field_color.a = 0.04
	_draw_geometric_shape(field_center, field_radius * (0.46 + phase * 0.1), inner_field_color, outline_color, visual_shape, false)
	var pulse_color: Color = fill_color
	pulse_color.a = 0.3 + sin(phase * PI) * 0.22
	if visual_shape in ["diamond", "star"]:
		_draw_geometric_shape(field_center, field_radius * (0.55 + phase * 0.25), Color(pulse_color.r, pulse_color.g, pulse_color.b, 0.0), pulse_color, visual_shape, false)
	else:
		draw_arc(field_center, field_radius * (0.55 + phase * 0.25), 0.0, TAU, 28, pulse_color, 1.4, true)


func _draw_slash_preview(target: Vector2, phase: float) -> void:
	var alpha: float = 1.0 - phase
	var glow_color: Color = Color(fill_color.r, fill_color.g, fill_color.b, alpha * 0.32)
	var core_color: Color = Color(outline_color.r, outline_color.g, outline_color.b, alpha)
	var slash_length: float = size.x * 0.23
	var slash_width: float = 4.0 * (1.0 - phase * 0.22)
	match visual_shape:
		"triangle":
			_draw_precision_slash_preview(target, slash_length, slash_width, glow_color, core_color)
		"square":
			_draw_heavy_slash_preview(target, slash_length, slash_width, glow_color, core_color)
		"diamond":
			_draw_diamond_slash_preview(target, slash_length, slash_width, glow_color, core_color)
		"star":
			_draw_star_slash_preview(target, slash_length, slash_width, glow_color, core_color)
		_:
			_draw_arc_slash_preview(target, slash_length, slash_width, glow_color, core_color)
	if visual_shape == "circle":
		_draw_slash_sparks_preview(target, slash_length, phase)


func _draw_arc_slash_preview(target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	var arc_radius: float = slash_length * 0.54
	draw_arc(target, arc_radius, -PI * 0.76, PI * 0.24, 24, glow_color, slash_width * 2.5, true)
	draw_arc(target, arc_radius, -PI * 0.76, PI * 0.24, 24, core_color, slash_width, true)
	var impact_center := target + Vector2(slash_length * 0.42, 0.0)
	draw_circle(impact_center, slash_width * 1.45, Color(fill_color.r, fill_color.g, fill_color.b, glow_color.a * 1.6))
	draw_arc(impact_center, slash_width * 1.65, 0.0, TAU, 16, core_color, maxf(1.0, slash_width * 0.18), true)


func _draw_precision_slash_preview(target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	_draw_polygon_slash_preview("triangle", target, slash_length, slash_width, glow_color, core_color)


func _draw_heavy_slash_preview(target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	_draw_polygon_slash_preview("square", target, slash_length, slash_width, glow_color, core_color)


func _draw_diamond_slash_preview(target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	_draw_polygon_slash_preview("diamond", target, slash_length, slash_width, glow_color, core_color)


func _draw_star_slash_preview(target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	_draw_polygon_slash_preview("star", target, slash_length, slash_width, glow_color, core_color)


func _draw_polygon_slash_preview(shape_id: String, target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	var polygon := SLASH_GEOMETRY.get_slash_polygon(shape_id, target, slash_length, slash_width)
	if polygon.is_empty():
		_draw_arc_slash_preview(target, slash_length, slash_width, glow_color, core_color)
		return

	draw_colored_polygon(polygon, Color(fill_color.r, fill_color.g, fill_color.b, glow_color.a * 2.25))
	draw_polyline(SLASH_GEOMETRY.close_polygon(polygon), core_color, maxf(1.35, slash_width * 0.4))
	_draw_shape_impact_preview(shape_id, target, slash_length, slash_width, glow_color, core_color)


func _draw_shape_impact_preview(shape_id: String, target: Vector2, slash_length: float, slash_width: float, glow_color: Color, core_color: Color) -> void:
	var impact_center := target + Vector2(slash_length * 0.62, 0.0)
	var impact_size := maxf(3.0, slash_width * 0.95)
	var impact := SLASH_GEOMETRY.get_impact_polygon(shape_id, impact_center, impact_size)
	if impact.is_empty():
		return

	draw_colored_polygon(impact, Color(fill_color.r, fill_color.g, fill_color.b, glow_color.a * 2.6))
	draw_polyline(SLASH_GEOMETRY.close_polygon(impact), core_color, maxf(1.0, slash_width * 0.22))
	var fragment_offsets: Array[Vector2] = [Vector2(-impact_size * 1.2, -impact_size * 0.82), Vector2(impact_size * 0.52, impact_size * 0.94)]
	for offset: Vector2 in fragment_offsets:
		var fragment := SLASH_GEOMETRY.get_impact_polygon(shape_id, impact_center + offset, impact_size * 0.36)
		draw_colored_polygon(fragment, Color(fill_color.r, fill_color.g, fill_color.b, glow_color.a * 1.7))


func _draw_slash_sparks_preview(target: Vector2, slash_length: float, phase: float) -> void:
	for spark_index in range(4):
		var angle: float = -PI * 0.78 + float(spark_index) * PI * 0.26
		var direction := Vector2.RIGHT.rotated(angle)
		var distance: float = lerpf(slash_length * 0.24, slash_length * (0.46 + float(spark_index) * 0.06), phase)
		draw_line(target + direction * distance, target + direction * (distance + 6.0), Color(fill_color.r, fill_color.g, fill_color.b, (1.0 - phase) * 0.68), 1.4)


func _draw_waves_preview(source: Vector2, target: Vector2, phase: float) -> void:
	for wave_index in 3:
		var local_phase: float = fposmod(phase + float(wave_index) * 0.24, 1.0)
		var wave_center: Vector2 = source.lerp(target, local_phase)
		var wave_size: float = lerpf(9.0, 23.0, local_phase)
		_draw_wave_shape(wave_center, wave_size)


func _draw_wave_shape(wave_center: Vector2, wave_size: float) -> void:
	match visual_shape:
		"circle":
			draw_arc(wave_center, wave_size, -PI * 0.5, PI * 0.5, 18, fill_color, 2.8, true)
			draw_arc(wave_center + Vector2(-4.0, 0.0), wave_size * 0.72, -PI * 0.5, PI * 0.5, 16, outline_color, 1.1, true)
		"triangle":
			var wedge := PackedVector2Array([wave_center + Vector2(12.0, 0.0), wave_center + Vector2(-10.0, -wave_size), wave_center + Vector2(-10.0, wave_size)])
			draw_colored_polygon(wedge, fill_color)
			draw_polyline(PackedVector2Array([wedge[0], wedge[1], wedge[2], wedge[0]]), outline_color, 1.1)
		"square":
			var block := Rect2(wave_center - Vector2(6.0, wave_size), Vector2(12.0, wave_size * 2.0))
			draw_rect(block, fill_color, true)
			draw_rect(block, outline_color, false, 1.1)
		"diamond":
			var diamond := PackedVector2Array([
				wave_center + Vector2(wave_size * 0.72, 0.0),
				wave_center + Vector2(0.0, -wave_size),
				wave_center + Vector2(-wave_size * 0.72, 0.0),
				wave_center + Vector2(0.0, wave_size),
			])
			draw_colored_polygon(diamond, fill_color)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline_color, 1.1)
		"star":
			_draw_star_wave_preview(wave_center, wave_size)
		_:
			_draw_spell_shape(wave_center, wave_size * 0.46, fill_color, outline_color)


func _draw_star_wave_preview(center: Vector2, wave_size: float) -> void:
	var star := PackedVector2Array()
	for point_index in 10:
		var angle: float = float(point_index) * TAU / 10.0
		var radial_scale: float = 1.0 if point_index % 2 == 0 else 0.42
		star.append(center + Vector2(cos(angle) * wave_size * 0.78 * radial_scale, sin(angle) * wave_size * radial_scale))
	draw_colored_polygon(star, fill_color)
	draw_polyline(PackedVector2Array([star[0], star[1], star[2], star[3], star[4], star[5], star[6], star[7], star[8], star[9], star[0]]), outline_color, 1.1)


func _draw_summon_preview(source: Vector2, target: Vector2, phase: float) -> void:
	for reflection_index in 2:
		var anchor_angle: float = -PI * 0.46 + float(reflection_index) * PI * 0.92
		var reflection_position: Vector2 = source + Vector2.from_angle(anchor_angle) * (30.0 + sin(_preview_time * 2.0 + float(reflection_index)) * 5.0)
		var reflection_fill: Color = Color(fill_color.r, fill_color.g, fill_color.b, 0.38)
		var reflection_outline: Color = Color(outline_color.r, outline_color.g, outline_color.b, 0.9)
		_draw_geometric_shape(reflection_position, 8.0, reflection_fill, reflection_outline, visual_shape, false)
		if reflection_index == int(phase * 2.0):
			var bolt_alpha: float = sin(fposmod(phase * 2.0, 1.0) * PI)
			draw_line(reflection_position, target, Color(fill_color.r, fill_color.g, fill_color.b, bolt_alpha * 0.42), 4.4)
			draw_line(reflection_position, target, Color(outline_color.r, outline_color.g, outline_color.b, bolt_alpha), 1.3)


func _draw_spell_shape(position: Vector2, radius: float, fill: Color, outline: Color) -> void:
	_draw_geometric_shape(position, radius, fill, outline, visual_shape, true)


func _draw_geometric_shape(position: Vector2, radius: float, fill: Color, outline: Color, shape_id: String, draw_glow: bool) -> void:
	if draw_glow:
		var glow: Color = fill
		glow.a = 0.16
		draw_circle(position, radius * 1.5, glow)

	match shape_id:
		"triangle":
			var triangle := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius * 0.92, radius * 0.78),
				position + Vector2(-radius * 0.92, radius * 0.78),
			])
			draw_colored_polygon(triangle, fill)
			draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), outline, 2.0)
		"diamond":
			var diamond := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius * 0.82, 0.0),
				position + Vector2(0.0, radius),
				position + Vector2(-radius * 0.82, 0.0),
			])
			draw_colored_polygon(diamond, fill)
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 2.0)
		"square":
			var side: float = radius * 1.55
			var square := Rect2(position - Vector2(side, side) * 0.5, Vector2(side, side))
			draw_rect(square, fill, true)
			draw_rect(square, outline, false, 2.0)
		"star":
			var star := PackedVector2Array()
			for point_index in 10:
				var angle: float = -PI * 0.5 + float(point_index) * PI / 5.0
				var point_radius: float = radius if point_index % 2 == 0 else radius * 0.48
				star.append(position + Vector2(cos(angle), sin(angle)) * point_radius)
			draw_colored_polygon(star, fill)
			draw_polyline(PackedVector2Array([star[0], star[1], star[2], star[3], star[4], star[5], star[6], star[7], star[8], star[9], star[0]]), outline, 2.0)
		"pentagon":
			var pentagon := PackedVector2Array()
			for point_index in 5:
				var angle: float = -PI * 0.5 + float(point_index) * TAU / 5.0
				pentagon.append(position + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(pentagon, fill)
		_:
			draw_circle(position, radius, fill)
			draw_arc(position, radius, 0.0, TAU, 32, outline, 2.0, true)
