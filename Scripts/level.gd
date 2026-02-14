extends Node2D

var vida = 10
var money := 25
var wave := 0
var to_spawn := 0
var alive_enemies := 0

@onready var fundo = $Background
@onready var fade_rect: ColorRect = $FadeOut  # Adicione na cena
@onready var enemy_timer: Timer = $EnemyTimer
@onready var music: AudioStreamPlayer2D = $music

# Cenas dos 5 tipos de inimigos
var enemy_scenes = {
	1: preload("res://Scenes/inimigo_1.tscn"),  # Soldado
	2: preload("res://Scenes/inimigo_2.tscn"),  # Clérigo
	3: preload("res://Scenes/inimigo_3.tscn"),  # Paladino
	4: preload("res://Scenes/inimigo_4.tscn"),  # Herói
	5: preload("res://Scenes/inimigo_5.tscn")   # Herói Poderoso
}

# Composição de cada wave (tipo: quantidade)
var wave_composition = {
	0: {1: 16},
	1: {1: 24},
	2: {1: 20, 2: 10},
	3: {1: 25, 2: 15},
	4: {1: 30, 2: 20},
	5: {1: 35, 2: 25},
	6: {1: 40, 2: 30},
	7: {1: 45, 2: 25, 3: 10},
	8: {1: 45, 2: 30, 3: 15},
	9: {1: 40, 2: 30, 3: 20, 4: 10},
	10: {1: 45, 2: 35, 3: 20, 4: 10},
	11: {1: 50, 2: 35, 3: 25, 4: 10},
	12: {1: 50, 2: 40, 3: 30, 4: 10},
	13: {1: 55, 2: 40, 3: 30, 4: 15},
	14: {1: 50, 2: 35, 3: 35, 4: 30},
	15: {1: 45, 2: 40, 3: 40, 4: 35},
	16: {1: 40, 2: 40, 3: 45, 4: 45},
	17: {1: 35, 2: 40, 3: 50, 4: 55},
	18: {1: 30, 2: 40, 3: 60, 4: 70},
	19: {1: 20, 2: 30, 3: 50, 4: 70, 5: 30}  # Boss wave
}

# Velocidade de spawn (metade = 2.0s entre cada inimigo)
var wave_speed := [
	0.5, 0.5, 0.45, 0.45, 0.4, 0.4, 0.35, 0.35, 0.3, 0.3,
	0.25, 0.25, 0.22, 0.22, 0.2, 0.2, 0.17, 0.17, 0.15, 0.12
]

# Fila de inimigos para spawnar na wave atual
var enemy_queue: Array = []

# Flag se o player está construindo torre
var building = false
var selected_tower

signal stats_changed(vida, money, wave, alive_enemies)

func _ready() -> void:
	fade_in()
	$WaveTimer.one_shot = true
	$WaveTimer.start()
	fundo.play("default")
	emit_signal("stats_changed", vida, money, wave, alive_enemies)

func fade_in() -> void:
	var tween = create_tween()
	tween.set_parallel(true)  # Executa ambas animações ao mesmo tempo
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)  # Transparente
	tween.tween_property(music, "volume_db", -30, 1.0)  # Volume normal
	music.play()

func add_money(amount: int):
	money += amount
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
func tk_damage(amount: int):
	vida -= amount
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	if vida <= 0:
		game_over()

func game_over():
	$WaveTimer.stop()
	$EnemyTimer.stop()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func tower_build(pos: Vector2, tower_scene: PackedScene, cost: int):
	if money >= cost:
		var tower = tower_scene.instantiate()
		tower.global_position = pos
		add_child(tower)
		money -= cost
		building = false
		emit_signal("stats_changed", vida, money, wave, alive_enemies)

func _input(event):
	if building and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ui = $UI
		if ui.selected_tower:
			var tower_instance = ui.selected_tower.instantiate()
			var price = tower_instance.cost
			tower_instance.queue_free()
			tower_build(get_global_mouse_position(), ui.selected_tower, price)
			ui.selected_tower = null

# --- Waves ---
func _on_wave_timer_timeout() -> void:
	if wave >= 20:
		# Vitória!
		print("Vitória! Todas as 20 waves completadas!")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")
		return
	
	_prepare_enemy_queue()
	$EnemyTimer.wait_time = wave_speed[wave]
	$EnemyTimer.start()
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	print("Wave ", wave + 1, "/20 iniciada. Inimigos:", enemy_queue.size())

func _prepare_enemy_queue() -> void:
	enemy_queue.clear()
	
	var composition = wave_composition.get(wave, {1: 10})  # Fallback
	
	# Criar fila com todos os inimigos da wave
	for enemy_type in composition.keys():
		var count = composition[enemy_type]
		for i in range(count):
			enemy_queue.append(enemy_type)
	
	# Embaralhar para variar a ordem
	enemy_queue.shuffle()
	
	to_spawn = enemy_queue.size()

func _on_enemy_timer_timeout() -> void:
	if enemy_queue.is_empty():
		$EnemyTimer.stop()
		return
	
	# Pega o próximo tipo de inimigo da fila
	var enemy_type = enemy_queue.pop_front()
	_spawn_enemy(enemy_type)
	
	to_spawn -= 1
	alive_enemies += 1
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	if enemy_queue.is_empty():
		$EnemyTimer.stop()

func _spawn_enemy(type: int) -> void:
	if not enemy_scenes.has(type):
		print("Tipo de inimigo inválido: ", type)
		return
	
	var e = enemy_scenes[type].instantiate()
	$EnemyPath.add_child(e)
	e.died.connect(_on_enemy_died)

func _on_enemy_died():
	alive_enemies -= 1
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	# Se acabou o spawn e não sobrou inimigos vivos -> próxima wave
	if to_spawn <= 0 and alive_enemies <= 0:
		wave += 1
		if wave < 20:
			$WaveTimer.start()
		else:
			# Completou todas as waves - vitória!
			print("Vitória! Todas as 20 waves completadas!")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://Scenes/menu.tscn")
