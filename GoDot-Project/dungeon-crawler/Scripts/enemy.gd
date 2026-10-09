class_name Enemy
extends CharacterBody2D

const SHEETS := "res://Assets/Enemy_Animations_Set/enemies-"
const FRAME_SIZE := 32

# Enemy names from the JSON. Unknown names fall back to DEFAULT_KIND.
const KINDS := {
	"skeleton": {"health": 3, "speed": 40.0,
		"idle": "skeleton1_idle", "move": "skeleton1_movement", "death": "skeleton1_death"},
	"skeleton2": {"health": 4, "speed": 35.0,
		"idle": "skeleton2_idle", "move": "skeleton2_movemen", "death": "skeleton2_death"},
	"vampire": {"health": 5, "speed": 50.0,
		"idle": "vampire_idle", "move": "vampire_movement", "death": "vampire_death"},
}
const DEFAULT_KIND := "skeleton"

# Set before adding the enemy to the scene.
var spawnable: Spawnable
var target: Player
# The Room or Corridor the enemy was spawned in.
var home: RefCounted
# Only moves while the camera shows the enemy's home area.
var active := false

var _health: int
var _speed: float
var _aggressive: bool
var _dead := false
var _sprite: AnimatedSprite2D
var _hurtbox: Area2D
var _wander_direction := Vector2.ZERO
var _wander_time_left := 0.0


# Built in code like Pickup: an animated sprite, a body shape, and a slightly
# bigger hurtbox that damages the player on contact.
func _ready() -> void:
	var kind_name := spawnable.enemy
	if not KINDS.has(kind_name):
		push_warning("Unknown enemy '%s', using '%s'" % [kind_name, DEFAULT_KIND])
		kind_name = DEFAULT_KIND
	var kind: Dictionary = KINDS[kind_name]
	_health = kind["health"]
	_speed = kind["speed"]
	_aggressive = spawnable.behaviour == "aggressive"
	motion_mode = MOTION_MODE_FLOATING
	z_index = 1

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = build_frames(kind)
	# The character sits low-left in its 32x32 frame; centre it on the node.
	_sprite.offset = Vector2(2, -5)
	_sprite.play("idle")
	add_child(_sprite)

	var body := RectangleShape2D.new()
	body.size = Vector2(10, 8)
	var body_shape := CollisionShape2D.new()
	body_shape.shape = body
	body_shape.position = Vector2(0, 4)
	add_child(body_shape)

	_hurtbox = Area2D.new()
	var reach := RectangleShape2D.new()
	reach.size = Vector2(14, 14)
	var reach_shape := CollisionShape2D.new()
	reach_shape.shape = reach
	_hurtbox.add_child(reach_shape)
	add_child(_hurtbox)


# Cuts each horizontal strip into 32x32 frames.
func build_frames(kind: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for anim in ["idle", "move", "death"]:
		var sheet: Texture2D = load(SHEETS + kind[anim] + ".png")
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 10)
		frames.set_animation_loop(anim, anim != "death")
		for i in range(sheet.get_width() / FRAME_SIZE):
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim, frame)
	return frames


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not active:
		velocity = Vector2.ZERO
		_sprite.play("idle")
		return

	if _aggressive:
		velocity = global_position.direction_to(target.global_position) * _speed
	else:
		wander(delta)
	move_and_slide()

	_sprite.play("move" if velocity.length() > 1.0 else "idle")
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0

	for body in _hurtbox.get_overlapping_bodies():
		if body is Player:
			body.take_damage(1)


# Passive enemies walk in a random direction for a bit, or stand still.
func wander(delta: float) -> void:
	_wander_time_left -= delta
	if _wander_time_left <= 0.0:
		_wander_time_left = randf_range(1.0, 2.5)
		_wander_direction = Vector2.ZERO if randf() < 0.3 else Vector2.from_angle(randf() * TAU)
	velocity = _wander_direction * _speed * 0.5


# Called by Arrow.
func take_hit(damage: int) -> void:
	if _dead:
		return
	_health -= damage
	_aggressive = true  # Passive enemies fight back once hit.
	modulate = Color(1.5, 0.6, 0.6)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)
	if _health <= 0:
		die()


func die() -> void:
	_dead = true
	# Stop blocking the player and arrows while the death animation plays.
	# Deferred, because this runs inside the arrow's collision callback.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_hurtbox.set_deferred("monitoring", false)
	_sprite.play("death")
	await _sprite.animation_finished
	queue_free()
