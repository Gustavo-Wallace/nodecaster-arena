class_name SlashVisualGeometry
extends RefCounted


static func get_slash_polygon(shape_id: String, center: Vector2, length: float, width: float) -> PackedVector2Array:
	match shape_id:
		"triangle":
			return PackedVector2Array([
				center + Vector2(-length * 0.46, -width * 1.32),
				center + Vector2(length * 0.12, -width * 0.68),
				center + Vector2(length * 0.82, 0.0),
				center + Vector2(length * 0.12, width * 0.68),
				center + Vector2(-length * 0.46, width * 1.32),
			])
		"square":
			return PackedVector2Array([
				center + Vector2(-length * 0.46, -width * 1.52),
				center + Vector2(length * 0.56, -width * 1.52),
				center + Vector2(length * 0.56, width * 1.52),
				center + Vector2(-length * 0.46, width * 1.52),
			])
		"diamond":
			return PackedVector2Array([
				center + Vector2(-length * 0.54, 0.0),
				center + Vector2(-length * 0.18, -width * 1.36),
				center + Vector2(length * 0.38, -width * 0.76),
				center + Vector2(length * 0.84, 0.0),
				center + Vector2(length * 0.38, width * 0.76),
				center + Vector2(-length * 0.18, width * 1.36),
			])
		"star":
			var points := PackedVector2Array()
			var burst_center := center + Vector2(length * 0.26, 0.0)
			var burst_radius := minf(length * 0.36, width * 3.25)
			for point_index in 10:
				var angle: float = -PI * 0.5 + float(point_index) * TAU / 10.0
				var radial_scale: float = 1.0 if point_index % 2 == 0 else 0.42
				points.append(burst_center + Vector2(cos(angle), sin(angle)) * burst_radius * radial_scale)
			return points
		_:
			return PackedVector2Array()


static func get_impact_polygon(shape_id: String, center: Vector2, size: float) -> PackedVector2Array:
	match shape_id:
		"triangle":
			return PackedVector2Array([
				center + Vector2(size * 0.92, 0.0),
				center + Vector2(-size * 0.68, -size * 0.62),
				center + Vector2(-size * 0.68, size * 0.62),
			])
		"square":
			return PackedVector2Array([
				center + Vector2(-size, -size),
				center + Vector2(size, -size),
				center + Vector2(size, size),
				center + Vector2(-size, size),
			])
		"diamond":
			return PackedVector2Array([
				center + Vector2(0.0, -size),
				center + Vector2(size, 0.0),
				center + Vector2(0.0, size),
				center + Vector2(-size, 0.0),
			])
		"star":
			var points := PackedVector2Array()
			for point_index in 10:
				var angle: float = -PI * 0.5 + float(point_index) * TAU / 10.0
				var radial_scale: float = 1.0 if point_index % 2 == 0 else 0.42
				points.append(center + Vector2(cos(angle), sin(angle)) * size * radial_scale)
			return points
		_:
			return PackedVector2Array()


static func close_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed
