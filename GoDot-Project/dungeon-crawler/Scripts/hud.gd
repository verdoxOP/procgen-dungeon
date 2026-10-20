class_name Hud
extends CanvasLayer

# Buttons on the game-over screen. The loader decides what they do.
signal retry_pressed
signal new_seed_pressed
signal menu_pressed

const FONT_SIZE := 24
const SMALL_FONT_SIZE := 16
const MARGIN := 16

var _stats: Label
var _info: Label
var _prompt: Label
var _game_over: Control
var _game_over_text: Label
var _player: Player


# Built in code: stats in the top-left, dungeon info in the top-right, a prompt at
# the bottom centre and a hidden game-over screen.
# A CanvasLayer draws in screen space, so camera zoom and the black mask don't affect it.
func _ready() -> void:
	# Lets other nodes (doors, weak walls, ...) find the HUD without a fixed path.
	add_to_group("hud")
	# The game is paused on the game-over screen, but its buttons must still work.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_stats = Label.new()
	_stats.add_theme_font_size_override("font_size", FONT_SIZE)
	_stats.position = Vector2(MARGIN, MARGIN)
	add_child(_stats)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	_info.modulate = Color(1, 1, 1, 0.6)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_info.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_info.position += Vector2(-MARGIN, MARGIN)
	add_child(_info)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.position.y -= MARGIN + FONT_SIZE
	_prompt.hide()
	add_child(_prompt)

	build_game_over()


func build_game_over() -> void:
	_game_over = ColorRect.new()
	_game_over.color = Color(0, 0, 0, 0.75)
	_game_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over.hide()
	add_child(_game_over)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	_game_over.add_child(box)

	var title := Label.new()
	title.text = "Game over"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_game_over_text = Label.new()
	_game_over_text.add_theme_font_size_override("font_size", FONT_SIZE)
	_game_over_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_game_over_text)

	box.add_child(make_button("Retry this dungeon", retry_pressed))
	box.add_child(make_button("New dungeon", new_seed_pressed))
	box.add_child(make_button("Main menu", menu_pressed))


func make_button(text: String, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(pressed_signal.emit)
	return button


func track(player: Player) -> void:
	# The loader may call this before the HUD's own _ready() has built the labels.
	if not is_node_ready():
		await ready
	_player = player
	player.stats_changed.connect(_refresh)
	_refresh()


func show_info(text: String) -> void:
	if not is_node_ready():
		await ready
	_info.text = text


func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.show()


func hide_prompt() -> void:
	_prompt.hide()


func show_game_over(floor_number: int) -> void:
	hide_prompt()
	_game_over_text.text = "You reached floor %d" % floor_number
	_game_over.show()


func _refresh() -> void:
	_stats.text = "HP %d/%d    Ammo %d    Keys %d    Buffs %s" % [
		_player.health, _player.max_health, _player.ammo, _player.keys.size(),
		", ".join(_player.buffs) if not _player.buffs.is_empty() else "-"]
