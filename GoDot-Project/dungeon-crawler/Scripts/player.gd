class_name Player
extends CharacterBody2D

# Emitted whenever health, ammo, keys or buffs change (the HUD listens to this).
signal stats_changed

@export var speed := 80.0
@export var max_health := 6

var health := 3
var ammo := 0
var keys: Array[String] = []
var buffs: Array[String] = []


func _ready() -> void:
	# Top-down: no floor or gravity, just slide along walls.
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()


func collect(s: Spawnable) -> void:
	match s.type:
		"health":
			health = mini(health + s.amount, max_health)
		"ammo":
			ammo += s.amount
		"key":
			keys.append(s.key_id)
		"buff":
			buffs.append(s.buff)
	stats_changed.emit()


func has_key(key_id: String) -> bool:
	return keys.has(key_id)


func use_key(key_id: String) -> void:
	keys.erase(key_id)
	stats_changed.emit()
