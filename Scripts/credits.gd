extends Control
@onready var fade_rect: ColorRect = $FadeRect
@onready var music: AudioStreamPlayer2D = $music

func _ready() -> void:
	fade_in()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	fade_out()
 # Replace with function body.

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
	tween.tween_property(music, "volume_db", -80, 1.0) 
