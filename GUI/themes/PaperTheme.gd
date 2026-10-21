class_name PaperTheme

static func build(dark: bool = false) -> Theme:
	var paper := Color(0.12, 0.11, 0.17) if dark else Color(0.979, 0.969, 0.941, 1.0)
	var paper_dim := Color(0.17, 0.16, 0.24) if dark else Color(0.933, 0.912, 0.857, 1.0)
	var ink := Color(0.93, 0.91, 1.0) if dark else Color(0.11, 0.10, 0.15)
	var accent := Color(0.87, 0.63, 0.94)

	var th := Theme.new()

	# panels
	th.set_stylebox("panel", "Panel", _box(paper, ink, accent, 2, 0, Vector2(4, 4), 0.35, 4))
	th.set_stylebox("panel", "PanelContainer", _box(paper, ink, accent, 2, 0, Vector2(4, 4), 0.35, 4))

	# buttons
	th.set_stylebox("normal", "Button", _box(paper_dim, ink, accent, 2, 3, Vector2(3, 3), 0.35, 4))
	th.set_stylebox("hover", "Button", _box(paper, ink, accent, 2, 4, Vector2(3, 3), 0.35, 4))
	var pressed := _box(paper_dim, ink, accent, 2, 2, Vector2(0, 0), 0.0, 4)
	pressed.content_margin_top += 2.0           # looks pushed in
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", _box(paper_dim.darkened(0.1), ink.lerp(paper, 0.6), ink.lerp(paper, 0.6), 2, 0, Vector2.ZERO, 0.0, 4))
	th.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), accent, accent, 2, 0, Vector2.ZERO, 0.0, 4))

	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		th.set_color(c, "Button", ink)
	th.set_color("font_disabled_color", "Button", ink.lerp(paper, 0.6))
	th.set_color("font_color", "Label", ink)
	th.set_font_size("font_size", "Button", 22)
	return th

static func _box(fill: Color, border: Color, underline: Color, bw: int, underline_extra: int,
		shadow_off: Vector2, shadow_a: float, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.border_width_bottom = bw + underline_extra     # thick marker underline
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10 + underline_extra
	if shadow_a > 0.0:
		sb.shadow_color = Color(0, 0, 0, shadow_a)
		sb.shadow_size = 1                              # near-hard "sticker" shadow
		sb.shadow_offset = shadow_off
	return sb
