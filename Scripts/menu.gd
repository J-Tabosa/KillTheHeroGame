extends Control

@onready var music: AudioStreamPlayer2D = $music
@onready var fade_rect: ColorRect = $Fade  # Adicione um ColorRect na cena

func _ready() -> void:
	# Começa com tela preta e faz fade in
	fade_rect.color = Color(0, 0, 0, 1)  # Preto opaco
	fade_in()

func _on_button_pressed() -> void:
	fade_out()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/info.tscn")

func fade_in() -> void:
	var tween = create_tween()
	tween.set_parallel(true)  # Executa ambas animações ao mesmo tempo
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)  # Transparente
	tween.tween_property(music, "volume_db", 0, 1.0)  # Volume normal
	music.play()

func fade_out() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)  # Opaco
	tween.tween_property(music, "volume_db", -80, 1.0)  # Silêncio

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn") # Replace with function body.


func _on_quit_pressed() -> void:
	queue_free()
	get_tree().quit() # Replace with function body.
