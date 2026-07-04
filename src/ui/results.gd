class_name Results
extends Control
## Tela de resultado da fase: estrelas, pontos e continuar/repetir.

signal continue_pressed

var result := {}
var campaign_complete := false


func _ready() -> void:
	var root := UiUtil.screen_root()
	add_child(root)
	var box := UiUtil.center_box(root)
	var won: bool = result.get("won", false)
	var lvl := int(result.get("level", 1))
	UiUtil.title_label(box, Strings.LEVEL_TITLES.get(lvl, ""), 34)
	UiUtil.label(box, Strings.LEVEL_CLEAR if won else Strings.LEVEL_FAILED, 26,
		Color(0.6, 1.0, 0.6) if won else Color(1.0, 0.6, 0.55))

	var star_count := int(result.get("stars", 0))
	var stars_text := ""
	for i in 3:
		stars_text += "★" if i < star_count else "☆"
	var stars_label := UiUtil.label(box, stars_text, 64, UiUtil.ACCENT)
	stars_label.add_theme_color_override("font_color", UiUtil.ACCENT if won else Color(0.4, 0.4, 0.45))

	UiUtil.label(box, Strings.SCORE % int(result.get("score", 0)), 24)
	if lvl >= 2 and lvl <= 5 and won:
		UiUtil.label(box, Strings.MESS_MADE % int(result.get("mess_left", 0)), 20, Color(1.0, 0.8, 0.6))
	if campaign_complete:
		UiUtil.label(box, Strings.CAMPAIGN_DONE, 24, Color(1.0, 0.85, 0.5))

	UiUtil.label(box, "", 10)
	var is_host := Net.is_host()
	if is_host:
		var btn := UiUtil.button(
			box, Strings.CONTINUE if won else Strings.RETRY,
			func() -> void: continue_pressed.emit()
		)
		btn.grab_focus()
	else:
		UiUtil.label(box, Strings.WAITING_HOST, 20, Color(0.8, 0.8, 0.9))
	AudioMan.play_sfx("ding" if won else "angry")
