extends Node2D

var vida = 10
# Dinheiro atual do player
var money := 25
# Wave atual
var wave := 0
# Quantidade de inimigos que ainda vão nascer na wave
var to_spawn := 0
# Quantidade de inimigos vivos na cena
var alive_enemies := 0
@onready var fundo = $Background

# CORREÇÃO: Expandido para 20 waves com progressão balanceada
var wave_mobs := [
	5,   # Wave 0
	8,   # Wave 1
	12,  # Wave 2
	15,  # Wave 3
	20,  # Wave 4
	25,  # Wave 5
	30,  # Wave 6
	35,  # Wave 7
	40,  # Wave 8
	45,  # Wave 9
	50,  # Wave 10
	55,  # Wave 11
	60,  # Wave 12
	65,  # Wave 13
	70,  # Wave 14
	75,  # Wave 15
	80,  # Wave 16
	85,  # Wave 17
	90,  # Wave 18
	100  # Wave 19 (última wave)
]

# CORREÇÃO: Velocidade de spawn ajustada para 20 waves
var wave_speed := [
	1.0,   # Wave 0
	1.0,   # Wave 1
	0.9,   # Wave 2
	0.9,   # Wave 3
	0.8,   # Wave 4
	0.8,   # Wave 5
	0.7,   # Wave 6
	0.7,   # Wave 7
	0.6,   # Wave 8
	0.6,   # Wave 9
	0.5,   # Wave 10
	0.5,   # Wave 11
	0.45,  # Wave 12
	0.45,  # Wave 13
	0.4,   # Wave 14
	0.4,   # Wave 15
	0.35,  # Wave 16
	0.35,  # Wave 17
	0.3,   # Wave 18
	0.25   # Wave 19
]

# Flag se o player está construindo torre
var building = false
# Torre selecionada para construção
var selected_tower
# Cena do inimigo
var enemy := preload("res://Scenes/inimigo_1.tscn")

# Sinal emitido para a UI atualizar estatísticas
signal stats_changed(vida, money, wave, alive_enemies)

# Inicialização
func _ready() -> void:
	$WaveTimer.one_shot = true
	$WaveTimer.start()
	fundo.play("default")
	emit_signal("stats_changed", vida, money, wave, alive_enemies)

# Função para adicionar dinheiro (chamada pelo inimigo ao morrer)
func add_money(amount: int):
	money += amount
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
func tk_damage(amount: int):
	vida -= amount
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	# CORREÇÃO: Verifica game over quando vida chega a zero ou menos
	if vida <= 0:
		game_over()

# CORREÇÃO: Nova função de game over
func game_over():
	# Para todos os timers
	$WaveTimer.stop()
	$EnemyTimer.stop()
	
	# Opcional: Aguarda um pouco antes de voltar ao menu
	await get_tree().create_timer(1.0).timeout
	
	# Volta para o menu
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

# Constrói torre na posição especificada, desconta dinheiro
# CORREÇÃO: Agora pega o custo da própria torre
func tower_build(pos: Vector2, tower_scene: PackedScene):
	# Instancia temporariamente para pegar o custo
	var temp_tower = tower_scene.instantiate()
	var cost = temp_tower.tower_cost if "tower_cost" in temp_tower else 25
	temp_tower.queue_free()
	
	if money >= cost:
		var tower = tower_scene.instantiate()
		tower.global_position = pos
		add_child(tower)
		money -= cost
		building = false
		emit_signal("stats_changed", vida, money, wave, alive_enemies)
	else:
		print("Dinheiro insuficiente! Necessário: ", cost, " Atual: ", money)

# Entrada do mouse para construir torre
func _input(event):
	if building and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ui = $UI
		if ui.selected_tower:
			tower_build(get_global_mouse_position(), ui.selected_tower)
			ui.selected_tower = null

# --- Waves ---
# Timer da wave disparou -> inicia wave
func _on_wave_timer_timeout() -> void:
	# CORREÇÃO: Verifica se completou todas as 20 waves
	if wave >= len(wave_mobs):
		# Vitória! Completou todas as waves
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")
		return
	
	to_spawn = wave_mobs[wave]
	$EnemyTimer.wait_time = wave_speed[wave]
	$EnemyTimer.start()
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	print("Wave ", wave + 1, "/", len(wave_mobs), " iniciada. Inimigos:", to_spawn)

# Timer de spawn de inimigos disparou
func _on_enemy_timer_timeout() -> void:
	if to_spawn <= 0:
		$EnemyTimer.stop()
		return
	
	var e = enemy.instantiate()
	$EnemyPath.add_child(e)
	# Conecta sinal de morte do inimigo
	e.died.connect(_on_enemy_died)
	to_spawn -= 1
	alive_enemies += 1
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	# Para de spawnar se terminou
	if to_spawn <= 0:
		$EnemyTimer.stop()

# Chamado quando inimigo morre
func _on_enemy_died():
	alive_enemies -= 1
	emit_signal("stats_changed", vida, money, wave, alive_enemies)
	
	# Se acabou o spawn e não sobrou inimigos vivos -> próxima wave
	if to_spawn <= 0 and alive_enemies <= 0:
		wave += 1
		if wave < len(wave_mobs):
			$WaveTimer.start()
		else:
			# Completou todas as waves - vitória!
			print("Vitória! Todas as 20 waves completadas!")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://Scenes/menu.tscn")
