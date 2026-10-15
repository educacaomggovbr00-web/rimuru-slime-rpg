extends Node2D

signal fallen(where: Vector2)

var target: Node2D
var hp := 2
var _cooldown := 0.0
var _time := 0.0
var _spawn := Vector2.ZERO

func _ready() -> void:
	_spawn = global_position
	add_to_group("enemies")

func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(0, _cooldown - delta)
	if is_instance_valid(target):
		var gap := target.global_position - global_position
		if gap.length() < 350 and gap.length() > 42:
			global_position += gap.normalized() * 85 * delta
		elif gap.length() > 350:
			global_position += (_spawn - global_position).limit_length(1) * 20 * delta
		if gap.length() < 44 and _cooldown <= 0:
			_cooldown = 1.2
			target.take_damage(1)
	queue_redraw()

func hit(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		fallen.emit(global_position)
		queue_free()

func _draw() -> void:
	var bob := sin(_time * 4) * 2
	draw_circle(Vector2(0, 20), 25, Color(0, 0, 0, 0.22))
	draw_circle(Vector2(0, bob - 2), 25, Color("#513666"))
	draw_circle(Vector2(0, bob - 5), 21, Color("#a575bf"))
	draw_circle(Vector2(-17, bob - 23), 11, Color("#8a58ae"))
	draw_circle(Vector2(17, bob - 23), 11, Color("#8a58ae"))
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(s * 9, bob - 6), 5, Color.WHITE)
		draw_circle(Vector2(s * 9, bob - 5), 2.5, Color("#30263f"))
	draw_rect(Rect2(-19, -38, 38, 4), Color("#21342e"))
	draw_rect(Rect2(-18, -37, 36.0 * float(hp) / 2.0, 2), Color("#b6ffa1"))
