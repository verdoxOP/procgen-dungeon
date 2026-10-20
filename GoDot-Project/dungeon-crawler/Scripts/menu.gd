extends Control

const GAME_SCENE := "res://Scenes/dungeon_loader.tscn"
const FONT_SIZE := 24

var _generator: OptionButton
var _seed: LineEdit


# Built in code: pick a generator and a seed, then start.
# Also shows the last dungeon's info and, if loading failed, the error.
func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#14141a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size.x = 600
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := label("Dungeon Crawler", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(label("Generator"))
	_generator = OptionButton.new()
	_generator.add_theme_font_size_override("font_size", FONT_SIZE)
	var names := PackedStringArray([GameSettings.TEST_GENERATOR])
	names.append_array(GeneratorRunner.available())
	for generator_name in names:
		_generator.add_item(generator_name)
	# Keep the last choice selected when coming back from a run.
	var last := names.find(GameSettings.generator)
	_generator.select(last if last != -1 else 0)
	box.add_child(_generator)
	if names.size() == 1:
		var hint := label("No generators found in %s" % GeneratorRunner.generators_dir(), 14)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.modulate = Color(1, 1, 1, 0.6)
		box.add_child(hint)

	box.add_child(label("Seed"))
	_seed = LineEdit.new()
	_seed.add_theme_font_size_override("font_size", FONT_SIZE)
	_seed.placeholder_text = "empty = random"
	_seed.text_submitted.connect(func(_text): start())
	box.add_child(_seed)

	var start_button := Button.new()
	start_button.text = "Start"
	start_button.add_theme_font_size_override("font_size", FONT_SIZE)
	start_button.pressed.connect(start)
	box.add_child(start_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.add_theme_font_size_override("font_size", FONT_SIZE)
	quit_button.pressed.connect(get_tree().quit)
	box.add_child(quit_button)

	var controls := label("WASD move  ·  mouse + left click shoot  ·  E interact  ·  Esc menu", 16)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.modulate = Color(1, 1, 1, 0.6)
	box.add_child(controls)

	if GameSettings.last_info != "":
		var info := label("Last dungeon: " + GameSettings.last_info, 16)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.modulate = Color(1, 1, 1, 0.6)
		box.add_child(info)

	if GameSettings.last_error != "":
		var error := label(GameSettings.last_error, 16)
		error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error.modulate = Color("#ff6b6b")
		box.add_child(error)

	start_button.grab_focus()


func label(text: String, size := FONT_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func start() -> void:
	var text := _seed.text.strip_edges()
	var seed_value := text.to_int() if text.is_valid_int() else GameSettings.random_seed()
	GameSettings.new_run(_generator.get_item_text(_generator.selected), seed_value)
	get_tree().change_scene_to_file(GAME_SCENE)
