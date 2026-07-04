class_name MainMenu
extends Control
## Menu principal.

signal local_pressed
signal online_pressed


func _ready() -> void:
	var root := UiUtil.screen_root()
	add_child(root)
	var box := UiUtil.center_box(root)
	UiUtil.title_label(box, Strings.GAME_TITLE)
	UiUtil.label(box, Strings.SUBTITLE, 20, Color(0.9, 0.85, 0.95))
	UiUtil.label(box, "", 10)
	var local_btn := UiUtil.button(box, Strings.MENU_LOCAL, func() -> void: local_pressed.emit())
	UiUtil.button(box, Strings.MENU_ONLINE, func() -> void: online_pressed.emit())
	UiUtil.button(box, Strings.MENU_QUIT, func() -> void: get_tree().quit())
	local_btn.grab_focus()
