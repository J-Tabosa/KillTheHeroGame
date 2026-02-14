extends Control
@onready var label = $Label
@onready var Fade = $FadeRect
@onready var timer = $Timer

func _ready():
	# Configura o ColorRect para começar transparente
	Fade.color = Color(0, 0, 0, 0)
	Fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Fade in do ColorRect
	var tween = create_tween()
	
	# Fade in do texto
	label.modulate.a = 0
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5)
	
	# Inicia o timer (configure para 15 segundos no Inspector)
	timer.start()

func _on_timer_timeout() -> void:
	# Fade out
	var tween_out = create_tween()
	tween_out.tween_property(label, "modulate:a", 0.0, 0.5)
	tween_out.parallel().tween_property(Fade, "color:a", 0.0, 0.5)
	
	await tween_out.finished
	
	# Troca para a cena do jogo
	get_tree().change_scene_to_file("res://Scenes/level.tscn")
