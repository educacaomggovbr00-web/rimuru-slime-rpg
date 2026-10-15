extends Node2D

const Player = preload("res://scripts/player.gd")
const Monster = preload("res://scripts/enemy.gd")
var player: CharacterBody2D
var drops: Array[Vector2] = []
var defeated := 0
var interface: CanvasLayer
var stats: Label
var tip: Label
var _touch_dirs := {"left": false, "right": false, "up": false, "down": false}
var _world_area := Rect2(-1100, -720, 2200, 1440)

func _ready() -> void:
	player = Player.new()
	player.global_position = Vector2(-610, 100)
	add_child(player)
	player.attack_pressed.connect(_attack)
	player.absorb_pressed.connect(_absorb)
	player.stats_changed.connect(_update_stats)
	var positions := [
		Vector2(-380, 120), Vector2(-300, -260), Vector2(-180, 300),
		Vector2(0, 60), Vector2(180, -320), Vector2(340, 190),
		Vector2(530, -100), Vector2(620, 420), Vector2(-680, -400)
	]
	for at in positions:
		var mob := Monster.new()
		mob.global_position = at
		mob.target = player
		add_child(mob)
		mob.fallen.connect(_on_fallen)
	_build_ui()
	_update_stats()
	_show_tip("Explore a floresta e enfrente os espíritos!")

func _process(_delta: float) -> void:
	_update_stats()

func _attack() -> void:
	var hits := 0
	for mob in get_tree().get_nodes_in_group("enemies"):
		var gap: Vector2 = mob.global_position - player.global_position
		if gap.length() <= 105 and (gap.length() < 1 or gap.normalized().dot(player.facing) > -0.05):
			mob.hit(player.power)
			hits += 1
	if hits > 0:
		_show_tip("Ataque mágico! %d alvo(s)" % hits)

func _on_fallen(at: Vector2) -> void:
	defeated += 1
	drops.append(at)
	queue_redraw()
	_show_tip("Espírito derrotado! Absorva a esfera azul.")

func _absorb() -> void:
	for i in range(drops.size()):
		if player.global_position.distance_to(drops[i]) <= 96:
			drops.remove_at(i)
			queue_redraw()
			var evolved: bool = player.collect()
			if player.essence == 9:
				_show_tip("MISSÃO CONCLUÍDA! 9 essências absorvidas!")
			elif evolved:
				_show_tip("EVOLUÇÃO! Nível %d!" % player.level)
			else:
				_show_tip("Predador: essência absorvida!")
			return
	_show_tip("Aproxime-se de uma esfera azul para absorvê-la.")

func _update_stats() -> void:
	if is_instance_valid(stats):
		stats.text = "💙 VIDA %d/%d     NIVEL %d     ESSENCIAS %d/9     INIMIGOS %d/9" % [
			player.hp, player.max_hp, player.level, player.essence, 9 - defeated
		]

func _show_tip(message: String) -> void:
	if is_instance_valid(tip):
		tip.text = message

func _make_button(parent: Control, title: String, x: float, y: float, w: float, h: float) -> Button:
	var button := Button.new()
	button.text = title
	button.anchor_left = 0.0 if x >= 0 else 1.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = x
	button.offset_right = x + w
	button.offset_top = y
	button.offset_bottom = y + h
	button.add_theme_font_size_override("font_size", 19)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	interface = CanvasLayer.new()
	add_child(interface)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(root)
	stats = Label.new()
	stats.position = Vector2(26, 18)
	stats.add_theme_font_size_override("font_size", 23)
	stats.add_theme_color_override("font_color", Color("#d4ffff"))
	root.add_child(stats)
	tip = Label.new()
	tip.position = Vector2(28, 54)
	tip.add_theme_font_size_override("font_size", 20)
	tip.add_theme_color_override("font_color", Color("#fff7b7"))
	root.add_child(tip)

	# Left D-pad for Android and browser touchscreens.
	var controls := [
		["up", "▲", 84.0, -210.0],
		["left", "◀", 20.0, -144.0],
		["down", "▼", 84.0, -144.0],
		["right", "▶", 148.0, -144.0]
	]
	for entry in controls:
		var key: String = entry[0]
		var b := _make_button(root, entry[1], entry[2], entry[3], 59, 59)
		b.button_down.connect(_set_direction.bind(key, true))
		b.button_up.connect(_set_direction.bind(key, false))

	_make_button(root, "ATACAR", -160, -96, 140, 69).pressed.connect(player.attack)
	_make_button(root, "ABSORVER", -308, -96, 140, 69).pressed.connect(player.absorb)
	_make_button(root, "DASH", -160, -176, 140, 69).pressed.connect(player.dash)

func _set_direction(key: String, down: bool) -> void:
	_touch_dirs[key] = down
	var d := Vector2(
		int(_touch_dirs["right"]) - int(_touch_dirs["left"]),
		int(_touch_dirs["down"]) - int(_touch_dirs["up"])
	)
	player.touch_direction = d.normalized()

func _draw() -> void:
	draw_rect(_world_area, Color("#1d594c"))
	# Forest trail.
	draw_line(Vector2(-1050, 130), Vector2(1050, -100), Color("#789d76"), 160, true)
	draw_line(Vector2(-1050, 130), Vector2(1050, -100), Color("#9cb785"), 128, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 34566
	for i in range(270):
		var grass := Vector2(rng.randf_range(-1070, 1070), rng.randf_range(-695, 695))
		draw_line(grass, grass + Vector2(-4, -8), Color("#69ab78"), 2.0)
		draw_line(grass, grass + Vector2(4, -8), Color("#368a66"), 2.0)
	for i in range(95):
		var p := Vector2(rng.randf_range(-1050, 1050), rng.randf_range(-685, 685))
		if absf(p.y - (14.0 - p.x * 0.11)) < 140:
			continue
		draw_circle(p + Vector2(0, 14), 36, Color(0, 0.1, 0.05, 0.2))
		draw_circle(p + Vector2(-13, -13), 32, Color("#1c7958"))
		draw_circle(p + Vector2(12, -22), 35, Color("#26774e"))
		draw_circle(p + Vector2(-3, -35), 29, Color("#329e6b"))
	for i in range(45):
		var p := Vector2(rng.randf_range(-1000, 1000), rng.randf_range(-650, 650))
		draw_circle(p, 3, Color("#e9e4a5"))
	# Shrine.
	draw_arc(Vector2(470, -40), 76, 0, TAU, 48, Color("#d2d6a0"), 7)
	draw_rect(Rect2(453, -74, 34, 68), Color("#567e71"))
	draw_circle(Vector2(470, -65), 17, Color("#86fff1"))
	for at in drops:
		draw_circle(at, 21, Color(0.28, 0.9, 1, 0.18))
		draw_circle(at, 12, Color("#71fff8"))
		draw_circle(at + Vector2(-3, -4), 4, Color.WHITE)
