# bala.gd
extends Area2D

@export var speed: float = 300.0   # pixels por segundo
@export var damage: int = 10
var target: Node = null

func _ready() -> void:
	monitoring = true  # garante que a Area2D monitora
	if target and target.is_inside_tree():
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	# se não tem alvo -> some
	if not target or not target.is_inside_tree():
		queue_free()
		return

	# mover em direção ao alvo (sempre recalcula)
	var dir_vec = target.global_position - global_position
	var dist = dir_vec.length()
	# pequeno alcance pra considerar "acertou" sem depender de overlap
	if dist <= 6:
		_apply_hit_to(target)
		return

	var dir = dir_vec.normalized()
	rotation = dir.angle()  # faz a sprite apontar pra frente do movimento
	global_position += dir * speed * delta

	# checa colisões por overlaps (abrange Area2D e PhysicsBody)
	_check_overlaps()

func _check_overlaps() -> void:
	# 1) corpos físicos (se houver)
	for body in get_overlapping_bodies():
		if not body: continue
		# se o body for parte do inimigo, tenta aplicar dano no próprio body ou no pai
		if body.is_in_group("Enemy") or (body.get_parent() and body.get_parent().is_in_group("Enemy")):
			var enemy_node = body if body.is_in_group("Enemy") else body.get_parent()
			_apply_hit_to(enemy_node)
			return

	# 2) áreas (caso o inimigo tenha Area2D como filho)
	for area in get_overlapping_areas():
		if not area: continue
		# area pode estar marcada como "Enemy" ou ser filha do nó inimigo
		if area.is_in_group("Enemy"):
			_apply_hit_to(area)
			return
		if area.get_parent() and area.get_parent().is_in_group("Enemy"):
			_apply_hit_to(area.get_parent())
			return

func _apply_hit_to(enemy_node: Node) -> void:
	if not enemy_node:
		queue_free()
		return

	# tenta chamar take_damage direto no node detectado
	if enemy_node.has_method("take_damage"):
		enemy_node.take_damage(damage)
	else:
		# sobe na árvore procurando um ancestor com take_damage (PathFollow2D geralmente)
		var curr = enemy_node
		while curr and not curr.has_method("take_damage"):
			curr = curr.get_parent()
		if curr and curr.has_method("take_damage"):
			curr.take_damage(damage)

	# garante que a bala morre ao acertar
	queue_free()

func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()
