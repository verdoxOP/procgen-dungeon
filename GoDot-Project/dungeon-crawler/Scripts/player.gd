class_name Player
extends CharacterBody2D

# Emitted whenever health, ammo, keys or buffs change (the HUD listens to this).
signal stats_changed
# Emitted once when health reaches 0. The loader decides what happens next.
signal died

@export var speed := 80.0
@export var max_health := 6
# Seconds between two shots.
@export var shoot_cooldown := 0.3
# Seconds the player can't be hurt again after taking damage.
@export var invulnerable_time := 1.0

var health := 3
var ammo := 10
var keys: Array[String] = []
var buffs: Array[String] = []

var _cooldown_left := 0.0
var _invulnerable_left := 0.0


func _ready() -> void:
	# Top-down: no floor or gravity, just slide along walls.
	motion_mode = MOTION_MODE_FLOATING
	# Draw above pickups, the exit and other things lying on the floor.
	z_index = 1


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	_cooldown_left -= delta
	if Input.is_action_pressed("shoot") and _cooldown_left <= 0.0 and ammo > 0:
		shoot()

	_invulnerable_left -= delta


# Called by enemies on contact.
func take_damage(amount: int) -> void:
	if _invulnerable_left > 0.0 or health <= 0:
		return
	_invulnerable_left = invulnerable_time
	health = maxi(health - amount, 0)
	stats_changed.emit()
	# Blink while invulnerable.
	var blink := create_tween().set_loops(5)
	blink.tween_property(self, "modulate:a", 0.3, 0.1)
	blink.tween_property(self, "modulate:a", 1.0, 0.1)
	if health == 0:
		died.emit()


# Fire an arrow towards the mouse.
func shoot() -> void:
	_cooldown_left = shoot_cooldown
	ammo -= 1
	stats_changed.emit()

	var arrow := Arrow.new()
	arrow.direction = global_position.direction_to(get_global_mouse_position())
	arrow.damage = 2 if buffs.has("damage_up") else 1
	arrow.global_position = global_position
	get_parent().add_child(arrow)


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
