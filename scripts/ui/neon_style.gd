class_name NeonStyle
extends RefCounted

## Shared visual language for the in-run UI and native CanvasItem drawings.
const BACKGROUND := Color(0.006, 0.012, 0.028, 1.0)
const ARENA_FILL := Color(0.018, 0.035, 0.07, 1.0)
const ARENA_GRID := Color(0.12, 0.56, 0.82, 0.1)
const ARENA_BORDER := Color(0.2, 0.88, 1.0, 0.94)
const ARENA_BORDER_GLOW := Color(0.18, 0.76, 1.0, 0.16)
const PANEL := Color(0.018, 0.037, 0.072, 0.94)
const PANEL_HOVER := Color(0.032, 0.068, 0.12, 0.98)
const PANEL_BORDER := Color(0.22, 0.7, 0.98, 0.72)
const TEXT_PRIMARY := Color(0.86, 0.96, 1.0, 1.0)
const TEXT_MUTED := Color(0.5, 0.68, 0.82, 1.0)
const CYAN := Color(0.26, 0.92, 1.0, 1.0)
const MAGENTA := Color(0.88, 0.28, 1.0, 1.0)
const HEALTH := Color(0.28, 1.0, 0.64, 1.0)
const WARNING := Color(1.0, 0.78, 0.22, 1.0)
const DANGER := Color(1.0, 0.3, 0.42, 1.0)


static func alpha(color: Color, value: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(value, 0.0, 1.0))


static func panel_style(background: Color = PANEL, border: Color = PANEL_BORDER, border_width: int = 1, radius: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(border.r, border.g, border.b, 0.16)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 2.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


static func button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := panel_style(background, border, 1, 5)
	style.shadow_color = Color(border.r, border.g, border.b, 0.2)
	style.shadow_size = 6
	return style
