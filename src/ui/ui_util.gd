class_name UiUtil
## Small helpers to build menu screens in code with a consistent look.

const BG_COLOR := Color(0.13, 0.1, 0.16)
const ACCENT := Color(1.0, 0.75, 0.35)


static func screen_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	return root


static func title_label(parent: Node, text: String, size := 56) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


static func label(parent: Node, text: String, size := 22, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, callback: Callable, size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(340, 54)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


static func line_edit(parent: Node, placeholder: String, initial := "") -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = initial
	e.custom_minimum_size = Vector2(340, 44)
	e.add_theme_font_size_override("font_size", 20)
	parent.add_child(e)
	return e


static func center_box(root: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	return box
