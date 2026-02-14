extends CanvasLayer

# Referências às labels da UI
@onready var life: Label = $"UI Label/Vida"
@onready var cash: Label = $"UI Label/Cash"
@onready var wave_count: Label = $"UI Label/WaveCount"
@onready var enemies_left: Label = $"UI Label/EnemiesLeft"

# Torre selecionada para construção
var selected_tower = null

# Conecta a UI ao nível para receber sinais de mudança de estatísticas
func connect_to_level(level: Node):
	level.stats_changed.connect(_on_stats_changed)

func _on_ready() -> void:
	var level = get_tree().current_scene
	connect_to_level(level)
# Atualiza os textos das labels quando o nível emite stats_changed
func _on_stats_changed(vida:int, money: int, wave: int, mobs_left: int) -> void:
	life.text = "Life: " + str(vida)
	cash.text = "Gold: " + str(money)
	wave_count.text = "Wave: " + str(wave+1)
	enemies_left.text = "Enemies: " + str(mobs_left)
	
# Botão da torre clicado, seleciona torre para construção
func _on_torre_1_pressed() -> void:
	selected_tower = preload("res://Scenes/torre_1.tscn")
	get_parent().building = true

func _on_torre_2_pressed() -> void:
	selected_tower = preload("res://Scenes/torre_2.tscn")
	get_parent().building = true
