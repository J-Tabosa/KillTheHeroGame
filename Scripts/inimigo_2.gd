extends PathFollow2D

# Sinal emitido quando inimigo morre
signal died

# Vida do inimigo
var health := 25
# Velocidade do inimigo no caminho
var speed := 50
# Referência ao sprite animado
@onready var sprite: AnimatedSprite2D = $Area2D/Sprite
# Guarda último estado de flip horizontal para não ficar piscando
var last_flip_h := false  

# Inicialização do inimigo
func _ready() -> void:
	sprite.play("Walk")
	sprite.flip_h = last_flip_h

# Atualiza posição e animação do inimigo a cada frame
func _physics_process(delta: float) -> void:
	var previous_x := global_position.x
	progress += speed * delta

	# Ajusta flip horizontal apenas se o movimento for relevante
	var delta_x := global_position.x - previous_x
	if abs(delta_x) > 0.1:
		last_flip_h = delta_x < 0
	sprite.flip_h = last_flip_h

	# Se inimigo chega no final do caminho -> morreu por escapar
	if progress_ratio >= 1.0:
		deal_damage(health)
		print("chegou no final") # false = morreu por escapar, não por dano

# --- Sistema de vida ---
# Aplica dano ao inimigo
func take_damage(dmg: int):
	health -= dmg
	if health <= 0:
		die(true)
		
func deal_damage(dmg: int):
	var level = get_tree().get_current_scene()
	if level.has_method("tk_damage"):
		level.tk_damage(dmg)
		die(true)
	
# Executa morte do inimigo
func die(killed: bool = true):
	# Se morreu por dano, adiciona dinheiro ao player
	if killed:
		var level = get_tree().get_current_scene()
		if level.has_method("add_money"):
			level.add_money(5)  # adiciona 5 de dinheiro ao matar
	# Dispara sinal para o level atualizar estatísticas
	emit_signal("died")
	# Remove inimigo da cena
	queue_free()
