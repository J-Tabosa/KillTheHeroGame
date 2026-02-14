extends Node2D

var enemies := []
var current_enemy
@export var cost = 100
@onready var scope: AnimatedSprite2D = $Sprite
var bullet = preload("res://Scenes/bala_2.tscn")
var is_attacking := false  # controla se a torre está atacando

func _ready() -> void:
	scope.play("Idle")

func _physics_process(delta: float) -> void:
	if enemies != []:
		current_enemy = enemies[0]
		scope.flip_h = current_enemy.global_position.x > global_position.x
		# Só dispara ataque se não estiver atacando
		if not is_attacking:
			_start_attack()
	else:
		# Se não há inimigos, garante que está em Idle
		if scope.animation != "Idle":
			scope.play("Idle")
			is_attacking = false

func _on_range_area_entered(area):
	if area.is_in_group("Enemy"):
		enemies.append(area)

func _on_range_area_exited(area):
	if area.is_in_group("Enemy"):
		enemies.erase(area)
		if current_enemy == area:
			current_enemy = null

func _start_attack():
	if current_enemy:
		is_attacking = true
		scope.play("Attack")

func _on_sprite_frame_changed() -> void:
	if scope.animation == "Attack" and scope.frame == scope.sprite_frames.get_frame_count("Attack") - 1:
		if current_enemy:
			var b = bullet.instantiate()
			b.global_position = global_position
			b.target = current_enemy
			get_parent().add_child(b)
			$atkSound.play()

func _on_sprite_animation_finished() -> void:
	if scope.animation == "Attack":
		is_attacking = false
		if enemies != []:
			_start_attack()  # só reinicia ataque se ainda houver inimigos
		else:
			scope.play("Idle")
