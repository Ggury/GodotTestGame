extends Node2D
#скрипт основной ноды сцены 
@export var PonitsFreeToSpawn:Array
@onready var Enemy_to_Spawn = load("res://FlyingEnemy.tscn")
@onready var Coin_to_Spawn = load("res://coin.tscn")
@onready var MainTimer = $MainTimer
@onready var CoinTimer = $CoinTimer
@onready var MainPlayer = $Player
@onready var rng = RandomNumberGenerator.new()
@export var dificulty = 1

func spawn_Enemy(Position:Vector2):
	var coords = Position
	var enemy_instance = Enemy_to_Spawn.instantiate()
	enemy_instance.global_position = coords
	get_parent().add_child(enemy_instance)

func SpawnCoins(Position:Vector2):
	var coords = Position
	var coin_instance = Coin_to_Spawn.instantiate()
	coin_instance.global_position = coords
	get_parent().add_child(coin_instance)

func _ready() -> void:
	GlobalScript.Load_Config()
	#запуск таймеров
	CoinTimer.start()
	MainTimer.start()
	MainPlayer.global_position = PonitsFreeToSpawn[randi() % PonitsFreeToSpawn.size()]
	
	GlobalScript.load_vars()
	MainPlayer._ready()

#при истечении времени таймера спавнятся новые враги
func _on_main_timer_timeout() -> void:
	var num_enemies = rng.randi_range(int(pow(2,dificulty)/2), pow(2,dificulty))
	for i in range(num_enemies):
		spawn_Enemy(PonitsFreeToSpawn[randi() % PonitsFreeToSpawn.size()])
	MainTimer.wait_time = rng.randf_range(20.0, 40.0)
	MainTimer.start()





#Отложенный спавн монет
func _on_coin_timer_timeout() -> void:
	var num_coins = rng.randi_range(int(pow(2,dificulty)/2), pow(2,dificulty))
	for i in range(20):
		SpawnCoins(PonitsFreeToSpawn[randi() % PonitsFreeToSpawn.size()])
#Спавн монет и врагов при загрузке сохранения
func load_coins_enemies(type, pos_x, pos_y):
	if type == "Enemy":
		spawn_Enemy(Vector2(pos_x, pos_y))
	if type == "Coin":
		SpawnCoins(Vector2(pos_x, pos_y))

	
	
