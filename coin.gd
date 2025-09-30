extends Area2D

#подбор монеты: Счетчик очков + 1 и уничтожение монетки
func _on_body_entered(body: Node2D) -> void:
	GlobalScript.add_score(1)
	queue_free()

#сохранение монетки
func save() -> Dictionary:
	return {
		"type": "Coin", # Важно для идентификации при загрузке
		"pos_x": global_position.x,
		"pos_y": global_position.y,
	}
