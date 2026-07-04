class_name LocalLobby
extends Control
## Lobby local: até 4 controles (ou teclado) entram apertando A,
## escolhem o pet com ◀ ▶ e confirmam. Start começa a campanha.

signal start_requested(players: Array)
signal back_requested

var slots: Array = []        # [{device, pet, confirmed}] ou vazio {}
var _prev := {}              # device -> frame anterior
var _panels: Array = []
var _hint: Label


func _ready() -> void:
	for i in 4:
		slots.append({})
	var root := UiUtil.screen_root()
	add_child(root)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	root.add_child(box)
	UiUtil.title_label(box, Strings.MENU_LOCAL, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for i in 4:
		_panels.append(_build_panel(row, i))
	_hint = UiUtil.label(box, Strings.PRESS_TO_JOIN, 20, Color(0.8, 0.8, 0.9))
	var back := UiUtil.button(box, Strings.BACK, func() -> void: back_requested.emit(), 20)
	back.custom_minimum_size = Vector2(200, 40)


func _build_panel(parent: Node, _index: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 300)
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var device_label := UiUtil.label(v, Strings.PRESS_TO_JOIN, 16, Color(0.7, 0.7, 0.8))
	device_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	device_label.custom_minimum_size = Vector2(220, 0)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(90, 90)
	swatch.color = Color(0.2, 0.2, 0.25)
	var swatch_center := CenterContainer.new()
	swatch_center.add_child(swatch)
	v.add_child(swatch_center)
	var pet_label := UiUtil.label(v, "—", 26, UiUtil.ACCENT)
	var tagline := UiUtil.label(v, "", 14, Color(0.85, 0.85, 0.9))
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size = Vector2(220, 0)
	var status := UiUtil.label(v, "", 18, Color(0.6, 1.0, 0.6))
	return {
		"device": device_label, "swatch": swatch, "pet": pet_label,
		"tagline": tagline, "status": status,
	}


func _process(_delta: float) -> void:
	_handle_joins()
	_handle_slots()
	_render()


func _joined_devices() -> Array:
	var out := []
	for s in slots:
		if not s.is_empty():
			out.append(s.device)
	return out


func _handle_joins() -> void:
	for device in InputPoller.devices_pressing(InputPoller.BTN_INTERACT):
		if _joined_devices().has(device):
			continue
		# Edge: só entra se não estava pressionando antes.
		var prev: Dictionary = _prev.get(device, InputPoller.empty_frame())
		if InputPoller.pressed(prev, InputPoller.BTN_INTERACT):
			continue
		for i in 4:
			if slots[i].is_empty():
				slots[i] = {"device": device, "pet": _free_pet(), "confirmed": false}
				AudioMan.play_sfx("pop")
				break


func _free_pet(exclude_slot := -1) -> String:
	var taken := []
	for i in slots.size():
		if i != exclude_slot and not slots[i].is_empty():
			taken.append(slots[i].pet)
	for pet_id in PetDefs.ORDER:
		if not taken.has(pet_id):
			return pet_id
	return "sirius"


func _handle_slots() -> void:
	var frames := {}
	var kb := InputPoller.sample(-1)
	frames[-1] = kb
	for device in Input.get_connected_joypads():
		frames[device] = InputPoller.sample(device)

	var start_pressed := false
	for i in 4:
		var s: Dictionary = slots[i]
		if s.is_empty():
			continue
		var frame: Dictionary = frames.get(s.device, InputPoller.empty_frame())
		var prev: Dictionary = _prev.get(s.device, InputPoller.empty_frame())
		var just := InputPoller.just_pressed_mask(frame, prev)
		var mv: Vector2 = frame.mv
		var prev_mv: Vector2 = prev.mv
		if not s.confirmed:
			if mv.x < -0.6 and prev_mv.x >= -0.6:
				s.pet = _cycle_pet(i, -1)
				AudioMan.play_sfx("pop", -8.0)
			elif mv.x > 0.6 and prev_mv.x <= 0.6:
				s.pet = _cycle_pet(i, 1)
				AudioMan.play_sfx("pop", -8.0)
			if just & InputPoller.BTN_INTERACT and _pet_available(i, s.pet):
				s.confirmed = true
				AudioMan.play_sfx("ding")
			if just & InputPoller.BTN_DASH:
				slots[i] = {}
				continue
		else:
			if just & InputPoller.BTN_DASH:
				s.confirmed = false
			if just & InputPoller.BTN_START:
				start_pressed = true
	for device in frames:
		_prev[device] = frames[device]

	if start_pressed and _all_confirmed():
		var players := []
		var slot_index := 0
		for i in 4:
			if not slots[i].is_empty() and slots[i].confirmed:
				players.append({
					"slot": slot_index, "pet": slots[i].pet,
					"device": slots[i].device, "peer": 0,
				})
				slot_index += 1
		if not players.is_empty():
			start_requested.emit(players)


func _cycle_pet(slot_index: int, direction: int) -> String:
	var current: String = slots[slot_index].pet
	var pet_id := current
	for i in PetDefs.ORDER.size():
		pet_id = PetDefs.next_pet(pet_id, direction)
		if _pet_available(slot_index, pet_id):
			return pet_id
	return current


func _pet_available(slot_index: int, pet_id: String) -> bool:
	for i in slots.size():
		if i == slot_index or slots[i].is_empty():
			continue
		if slots[i].confirmed and slots[i].pet == pet_id:
			return false
	return true


func _all_confirmed() -> bool:
	var any := false
	for s in slots:
		if s.is_empty():
			continue
		if not s.confirmed:
			return false
		any = true
	return any


func _render() -> void:
	for i in 4:
		var widgets: Dictionary = _panels[i]
		var s: Dictionary = slots[i]
		if s.is_empty():
			widgets.device.text = Strings.PRESS_TO_JOIN
			widgets.pet.text = "—"
			widgets.tagline.text = ""
			widgets.status.text = ""
			widgets.swatch.color = Color(0.2, 0.2, 0.25)
			continue
		var device: int = s.device
		widgets.device.text = Strings.SLOT_KEYBOARD if device < 0 else Strings.SLOT_GAMEPAD % (device + 1)
		widgets.pet.text = Strings.pet_name(s.pet)
		widgets.tagline.text = Strings.PET_TAGLINES.get(s.pet, "")
		var def := PetDefs.get_def(s.pet)
		widgets.swatch.color = def.body_color if s.confirmed else def.body_color.lightened(0.25)
		widgets.status.text = Strings.READY if s.confirmed else Strings.PICK_PET
	var confirmed_ready := _all_confirmed()
	_hint.text = Strings.PRESS_START if confirmed_ready else Strings.PRESS_TO_JOIN
