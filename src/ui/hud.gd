class_name Hud
extends CanvasLayer
## In-game HUD: timer, objective, mess counter, extra line, rage bar
## (fase 6) and center banners. Fed by LevelBase.update_state dicts.

var _title: Label
var _objective: Label
var _timer: Label
var _mess: Label
var _line: Label
var _rage_bar: ProgressBar
var _rage_label: Label
var _banner: Label
var _banner_queue: Array = []
var _banner_left := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.anchor_left = 0.2
	top.anchor_right = 0.8
	top.offset_top = 8
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(top)

	_title = _label(top, 20, Color(1, 1, 1, 0.85))
	_objective = _label(top, 26, Color(1.0, 0.95, 0.7))

	_timer = _label(root, 40, Color.WHITE)
	_timer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_timer.position = Vector2(24, 12)

	_mess = _label(root, 24, Color(1.0, 0.8, 0.6))
	_mess.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mess.anchor_left = 1.0
	_mess.offset_left = -320
	_mess.offset_right = -24
	_mess.offset_top = 12
	_mess.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_line = _label(root, 20, Color(0.85, 0.95, 1.0))
	_line.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_line.anchor_left = 1.0
	_line.offset_left = -430
	_line.offset_right = -24
	_line.offset_top = 46
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_rage_bar = ProgressBar.new()
	_rage_bar.min_value = 0
	_rage_bar.max_value = 100
	_rage_bar.show_percentage = false
	_rage_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rage_bar.anchor_left = 0.3
	_rage_bar.anchor_right = 0.7
	_rage_bar.offset_top = 74
	_rage_bar.offset_bottom = 96
	_rage_bar.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.2, 0.15)
	_rage_bar.add_theme_stylebox_override("fill", style)
	root.add_child(_rage_bar)
	_rage_label = _label(root, 16, Color(1.0, 0.6, 0.55))
	_rage_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rage_label.anchor_left = 0.3
	_rage_label.anchor_right = 0.7
	_rage_label.offset_top = 96
	_rage_label.text = Strings.HUD_RAGE
	_rage_label.visible = false

	_banner = _label(root, 52, Color.WHITE)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.anchor_top = 0.35
	_banner.anchor_bottom = 0.45
	_banner.visible = false
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1))
	_banner.add_theme_constant_override("outline_size", 10)


func _label(parent: Node, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func update_state(state: Dictionary, _force: bool) -> void:
	if state.has("title"):
		_title.text = String(state["title"])
	if state.has("objective"):
		_objective.text = String(state["objective"])
	if state.has("time"):
		var t := int(state["time"])
		_timer.text = "%d:%02d" % [t / 60, t % 60]
	if state.has("mess"):
		_mess.text = "%s: %d" % [Strings.HUD_MESS, int(state["mess"])]
	_line.text = String(state.get("line", ""))
	if state.has("rage"):
		_rage_bar.visible = true
		_rage_label.visible = true
		_rage_bar.value = float(state["rage"])
	else:
		_rage_bar.visible = false
		_rage_label.visible = false


func show_banner(text: String, seconds := 1.5) -> void:
	_banner_queue.append([text, seconds])


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
	if _banner_left <= 0.0 and not _banner_queue.is_empty():
		var entry: Array = _banner_queue.pop_front()
		_banner.text = String(entry[0])
		_banner_left = float(entry[1])
		_banner.visible = true
		_banner.scale = Vector2.ONE * 0.7
		var tween := create_tween()
		tween.tween_property(_banner, "scale", Vector2.ONE, 0.15)
