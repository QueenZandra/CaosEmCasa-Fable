class_name InputPoller
## Polls raw input per "controller": device -1 = keyboard, >= 0 = joypad index.
## Produces InputFrame dictionaries used both locally and over the network.

const BTN_INTERACT := 1
const BTN_ABILITY := 2
const BTN_DASH := 4
const BTN_START := 8

const DEADZONE := 0.25


static func empty_frame() -> Dictionary:
	return {"mv": Vector2.ZERO, "b": 0}


## Sample the current state of a controller into a frame dict.
static func sample(device: int) -> Dictionary:
	var mv := Vector2.ZERO
	var buttons := 0
	if device < 0:
		# Keyboard (player 1 fallback): WASD + arrows.
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			mv.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			mv.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			mv.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			mv.y += 1.0
		mv = mv.limit_length(1.0)
		if Input.is_physical_key_pressed(KEY_SPACE):
			buttons |= BTN_INTERACT
		if Input.is_physical_key_pressed(KEY_E):
			buttons |= BTN_ABILITY
		if Input.is_physical_key_pressed(KEY_SHIFT):
			buttons |= BTN_DASH
		if Input.is_physical_key_pressed(KEY_ENTER):
			buttons |= BTN_START
	else:
		mv.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		mv.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		if mv.length() < DEADZONE:
			mv = Vector2.ZERO
		else:
			mv = mv.limit_length(1.0)
		# D-pad as alternative movement.
		if mv == Vector2.ZERO:
			if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
				mv.x -= 1.0
			if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
				mv.x += 1.0
			if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
				mv.y -= 1.0
			if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
				mv.y += 1.0
		if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			buttons |= BTN_INTERACT
		if Input.is_joy_button_pressed(device, JOY_BUTTON_X):
			buttons |= BTN_ABILITY
		if Input.is_joy_button_pressed(device, JOY_BUTTON_B):
			buttons |= BTN_DASH
		if Input.is_joy_button_pressed(device, JOY_BUTTON_START):
			buttons |= BTN_START
	return {"mv": mv, "b": buttons}


static func pressed(frame: Dictionary, mask: int) -> bool:
	return (frame.get("b", 0) & mask) != 0


## Edge detection helper: returns buttons pressed this frame but not last frame.
static func just_pressed_mask(frame: Dictionary, prev: Dictionary) -> int:
	return frame.get("b", 0) & ~prev.get("b", 0)


## List of controllers currently pressing a button (for lobby "press A to join").
static func devices_pressing(mask: int) -> Array[int]:
	var out: Array[int] = []
	var kb := sample(-1)
	if pressed(kb, mask):
		out.append(-1)
	for device in Input.get_connected_joypads():
		var fr := sample(device)
		if pressed(fr, mask):
			out.append(device)
	return out
