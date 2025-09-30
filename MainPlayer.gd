extends CharacterBody2D
#скрипт игрока

#основные параметры игрока
@export var character_Speed:float = 200.0
@export var JumpVelocity: float = -200.0
@export var Jumps_InAir = 1
@export var fuel = 30.0
@export var fuel_gain = 10.0
@export var fuel_loss = 7.0
@export var throttle = 200.0
@export var max_fuel = fuel 
@onready var Hud = $CanvasLayer/Control
var block_control = false

var flying = false

var gravitation:float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	character_Speed = GlobalScript.player_speed
	print(GlobalScript.player_speed)
	JumpVelocity = GlobalScript.player_jump_velocity
	max_fuel = GlobalScript.player_max_fuel
	GlobalScript.connect("GameOver", Callable(self, "_game_over"))
	Hud.update_fuel(fuel)
func _game_over():
	block_control = true
	#queue_free()

func _physics_process(delta: float) -> void:
	#блокируем управление и останавливаем основной процесс игрока при смерти или победе
	if block_control:
		return
	
	var on_floor = is_on_floor()
	
	#если игрок на полу то обновляем количество прыжков в воздухе иначе применяем гравитацию
	
	if not on_floor and not flying:
		velocity.y += gravitation * delta
	elif on_floor:
		Jumps_InAir = 1
	
	#топливо тратится при полете и восполняется в ином случае
	if flying:
		fuel = max(fuel - delta * fuel_loss, 0.0)
		if fuel == 0.0:
		#делаем показатель топлива отрицательным, чтобы игрок не мог постоянно летать
			fuel = -5.0
	else:
		fuel = min(fuel + delta * fuel_gain, max_fuel)
	#fuel_bar.value = fuel
	#обновление индикатора топлива на экране
	Hud.update_fuel(fuel)
	
	#чтобы не проверять каждый раз какое действие нажато применим
	var fly_active = Input.is_action_pressed("ui_accept")
	var fly_inactive = Input.is_action_just_released("ui_accept")
	var jump_pressed := Input.is_action_just_pressed("ui_up")
	var dash_pressed := Input.is_action_just_pressed("Dash")

#обновление состояния полета
	if fly_active and fuel>0.0:
		flying = true
	elif fly_inactive or fuel <= 0.0:
		flying = false
	if flying:
		velocity.y = throttle
	
	#print(fuel)
	#velocity.y += gravitation * delta
	#управление персонажем, передвижение вправо влево
	var direction = Input.get_axis("ui_left","ui_right")
	velocity.x = direction * character_Speed
	#проигрываем анимацию и отражаем спрайт при передвижении в разные стороны
	if velocity.x>0.1:
		$Player_Sprite.scale.x = 1.0
		$AnimationPlayer.play("Walk_Anim")
	elif velocity.x < -0.1:
		$Player_Sprite.scale.x = -1.0
		$AnimationPlayer.play("Walk_Anim")
	else:
		$AnimationPlayer.play("Idle_Anim")
	
	#прыжок
	if not flying:
		if jump_pressed:
			if on_floor or (not on_floor and Jumps_InAir>0):
				velocity.y=JumpVelocity
				Jumps_InAir-= int(not is_on_floor())
	move_and_slide()

#сохранение игрока (позиция и топливо)
func save() -> Dictionary:
	return {
		"type": "Player", # Важно для идентификации при загрузке
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"fuel": fuel,
	}
