extends CharacterBody2D

signal attack_pressed
signal absorb_pressed
signal stats_changed

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
	var bob := sin(_time * 6.0) * 2.5
	var fill := Color("#bcfaff") if _invulnerable > 0.0 and int(_time * 12) % 2 == 0 else Color("#44d4ee")
	draw_circle(Vector2(0, 20), 32, Color(0, 0.04, 0.08, 0.24))
	draw_circle(Vector2(0, bob), 32, Color("#15669b"))
	draw_circle(Vector2(0, bob - 3), 28, fill)
	draw_circle(Vector2(-13, bob - 15), 11, Color("#b5fcff"))
	for sign in [-1.0, 1.0]:
		draw_circle(Vector2(sign * 11, bob - 2), 6, Color.WHITE)
		draw_circle(Vector2(sign * 11, bob - 1), 3, Color("#125b92"))
	draw_arc(Vector2(0, bob + 3), 10, 0.18, PI - 0.18, 14, Color("#18578b"), 2.0)
	if _attack_timer > 0:
		draw_arc(Vector2.ZERO, 58, facing.angle() - 0.8, facing.angle() + 0.8, 24, Color("#bcffff"), 10.0)
