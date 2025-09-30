extends CharacterBody2D

@export var enemy_speed:float
@onready var _timer: Timer = $Enemy_Timer
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var target_position: Vector2
var time_since_direction_change: float = 0.0

var direction: Vector2


#основная функция physics_process
func _physics_process(delta: float) -> void:
	move_and_slide()

	

func _ready() -> void:
	enemy_speed = GlobalScript.enemy_speed
	#стартуем таймер
	_timer.start()
	$AnimationPlayer.play("DefaultAnim")

func chose_random_dir():
	var random_angle = rng.randf_range(0,2*PI)
	velocity = Vector2(cos(random_angle), sin(random_angle))*enemy_speed

func _on_enemy_timer_timeout() -> void:
	chose_random_dir()
	_timer.wait_time = rng.randf_range(0.4,2.6)
	_timer.start()

#при столкновении со стеной выбираем новое направление
func _on_check_area_area_entered(area: Area2D) -> void:
	chose_random_dir()

#при столкновении с игроком вызываем геймовер
func _on_kill_area_body_entered(body: Node2D) -> void:
	GlobalScript.gameOver()

#сохранение позиции противника (остальные параметры сохранять не нужно)
func save() -> Dictionary:
	return {
		"type": "Enemy", # Важно для идентификации при загрузке
		"pos_x": global_position.x,
		"pos_y": global_position.y,
	}
