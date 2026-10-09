class_name Hud
extends CanvasLayer

const FONT_SIZE := 24
const MARGIN := 16

var _stats: Label
var _prompt: Label
var _player: Player


# Built in code: a stats line in the top-left and a prompt at the bottom centre.
# A CanvasLayer draws in screen space, so camera zoom and the black mask don't affect it.
func _ready() -> void:
	# Lets other nodes (doors, weak walls, ...) find the HUD without a fixed path.
	add_to_group("hud")

	_stats = Label.new()
	_stats.add_theme_font_size_override("font_size", FONT_SIZE)
	_stats.position = Vector2(MARGIN, MARGIN)
	add_child(_stats)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.position.y -= MARGIN + FONT_SIZE
	_prompt.hide()
	add_child(_prompt)


func track(player: Player) -> void:
	# The loader may call this before the HUD's own _ready() has built the labels.
	if not is_node_ready():
		await ready
	_player = player
	player.stats_changed.connect(_refresh)
	_refresh()


func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.show()


func hide_prompt() -> void:
	_prompt.hide()


func _refresh() -> void:
	_stats.text = "HP %d/%d    Ammo %d    Keys %d    Buffs %s" % [
		_player.health, _player.max_health, _player.ammo, _player.keys.size(),
		", ".join(_player.buffs) if not _player.buffs.is_empty() else "-"]
