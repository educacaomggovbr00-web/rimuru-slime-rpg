extends CharacterBody2D

signal attack_pressed
signal absorb_pressed
signal stats_changed

const SLIME_IDLE = preload("res://assets/characters/slime_idle.svg")
const SLIME_BLINK = preload("res://assets/characters/slime_blink.svg")
var _slime_sprite: Sprite2D

const SPEED := 230.0
const DASH_SPEED := 500.0
var touch_direction := Vector2.ZERO
var facing := Vector2.RIGHT
var hp := 5
var max_hp := 5
var level := 1
var essence := 0
var power := 1
var _time := 0.0
var _attack_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown := 0.0
var _invulnerable := 0.0

func _ready() -> void:
	var hitbox := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 23.0
	hitbox.shape = circle
	add_child(hitbox)
	_slime_sprite = Sprite2D.new()
	_slime_sprite.texture = SLIME_IDLE
	_slime_sprite.position = Vector2(0, -9)
	_slime_sprite.scale = Vector2.ONE * 0.52
	_slime_sprite.z_index = 1
	add_child(_slime_sprite)
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.12, 1.12)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = -1100
	camera.limit_right = 1100
	camera.limit_top = -720
	camera.limit_bottom = 720
	add_child(camera)

func _physics_process(delta: float) -> void:
	_time += delta
	_attack_timer = maxf(0, _attack_timer - delta)
	_dash_timer = maxf(0, _dash_timer - delta)
	_dash_cooldown = maxf(0, _dash_cooldown - delta)
	_invulnerable = maxf(0, _invulnerable - delta)
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	direction = (direction + touch_direction).limit_length(1)
	if direction.length() > 0.01:
		facing = direction.normalized()
	velocity = direction * (DASH_SPEED if _dash_timer > 0 else SPEED)
	move_and_slide()
	# Gentle squash-and-stretch makes the imported character art feel alive.
	var moving := direction.length_squared() > 0.02
	var motion_rate := 11.0 if moving else 3.8
	var bounce := sin(_time * motion_rate)
	var stretch := bounce * (0.042 if moving else 0.018)
	_slime_sprite.scale = Vector2(0.52 * (1.0 + stretch), 0.52 * (1.0 - stretch))
	_slime_sprite.position.y = -9.0 + bounce * (2.8 if moving else 1.5)
	_slime_sprite.rotation = sin(_time * 8.0) * 0.045 if moving else 0.0
	_slime_sprite.texture = SLIME_BLINK if fmod(_time, 3.75) > 3.60 else SLIME_IDLE
	_slime_sprite.modulate = Color(1, 1, 1, 0.55) if _invulnerable > 0.0 and int(_time * 12.0) % 2 == 0 else Color.WHITE
	global_position = global_position.clamp(Vector2(-1020, -655), Vector2(1020, 655))
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_J:
				attack()
			KEY_E, KEY_K:
				absorb()
			KEY_SHIFT:
				dash()

func attack() -> void:
	if _attack_timer > 0:
		return
	_attack_timer = 0.30
	attack_pressed.emit()

func absorb() -> void:
	absorb_pressed.emit()

func dash() -> void:
	if _dash_cooldown > 0:
		return
	_dash_cooldown = 1.1
	_dash_timer = 0.2
	_invulnerable = maxf(_invulnerable, 0.25)

func take_damage(amount: int) -> void:
	if _invulnerable > 0:
		return
	hp -= amount
	_invulnerable = 1.0
	if hp <= 0:
		hp = max_hp
		global_position = Vector2(-610, 100)
	stats_changed.emit()

func collect() -> bool:
	essence += 1
	var upgrade := essence % 3 == 0
	if upgrade:
		level += 1
		power += 1
		max_hp += 1
		hp = max_hp
	stats_changed.emit()
	return upgrade

func _draw() -> void:
	# Soft ground shadow is drawn behind the imported slime sprite.
	draw_circle(Vector2(0, 23), 35, Color(0.0, 0.06, 0.12, 0.12))
	draw_circle(Vector2(0, 23), 26, Color(0.0, 0.05, 0.10, 0.18))
	if _dash_timer > 0.0:
		draw_arc(Vector2(0, -3), 44, 0.0, TAU, 40, Color("#b8ffff"), 3.5)
	if _attack_timer > 0.0:
		draw_arc(Vector2(0, -3), 59, facing.angle() - 0.85, facing.angle() + 0.85, 30, Color("#e9ffff"), 9.0)
