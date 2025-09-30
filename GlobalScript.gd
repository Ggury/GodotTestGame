extends Node

#сигнал обновления счетчикап очков, проигрыша и победы
signal ScoreUpdated(new_score)
signal GameOver()
signal GameWinned()

var score:int = 0

@onready var Player = get_tree().get_current_scene().get_node("Player")
@onready var Tilemap = get_tree().get_current_scene().get_node("TileMapLayer")
@onready var MainSceneNode = get_tree().get_current_scene()

@export var enemy_speed = 200.0
@export var player_speed = 200.0
@export var player_jump_velocity = -500.0
@export var player_max_fuel = 30.0


#загрузка настроек персонажа и врагов
func Load_Config():
	var config = ConfigFile.new()
	var err = config.load("res://config.ini")
	if err:
		return
	enemy_speed = config.get_value("Enemy", "speed", 200)
	player_speed = config.get_value("Player", "speed", 200)
	player_jump_velocity = config.get_value("Player", "jump", 200)
	player_max_fuel = config.get_value("Player", "max_fuel", 200)

#загрузка переменных, необходимо для корректной загрузки сохранений после рестарта
func load_vars() -> void:
	Player = get_tree().get_current_scene().get_node("Player")
	Tilemap = get_tree().get_current_scene().get_node("TileMapLayer")
	MainSceneNode = get_tree().get_current_scene()

#Сохранение и загрузка через F5 F6
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Save"):
		GlobalScript.save_game()
	if event.is_action_pressed("Load"):
		GlobalScript.load_game()
#функция добавления очков к счетчику
func add_score(amount:int):
	score = score + amount
	emit_signal("ScoreUpdated", score)
	MainSceneNode.dificulty = int(score / 4)
	if score >=20:
		#сигнал выигрыша, если собраны все 20 монет
		emit_signal("GameWinned")
#функция проигрыша
func gameOver():
	score = 0
	emit_signal("GameOver")


#сохранение игры
func save_game():
	var save_file = FileAccess.open("res://savegame.save", FileAccess.WRITE)
	#сохранение очков
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	var globalscriptdata = {"type":"global", "score":score}
	save_file.store_line(JSON.stringify(globalscriptdata))
	for node in save_nodes:
		#для каждой сохраняемой ноды вызываем метод save
		if !node.has_method("save"):
			continue
		var node_data = node.call("save")
		#запись в save файл в формате JSON
		var json_string = JSON.stringify(node_data)
		save_file.store_line(json_string)
		
#загрузка сохранения
func load_game():
	if not FileAccess.file_exists("res://savegame.save"):
		return # Error! We don't have a save to load.
	#удаляем существующие монеты и врагов
	for i in get_tree().get_nodes_in_group("Persist_To_Delete"):
		i.queue_free()
	var save_file = FileAccess.open("res://savegame.save", FileAccess.READ)
	#парсинг сейв файла
	while not save_file.eof_reached():
		#выписываем JSON строку в словарь для удобного парсинга
		var dict = JSON.parse_string(save_file.get_line())
		if dict != null:
			match dict["type"]:
			#загрузка игрока. Не удаляем прежнего игрока, лишь меняем его параметры
				"Player":
					Player.global_position = Vector2(dict["pos_x"],dict["pos_y"])
					Player.fuel = dict["fuel"]
			#загрузка карты
				"TileMap":
				#print(dict["MapData"])
					Tilemap.load_map(dict["MapData"])
			#загрузка очков
				"global":
					score = 0
					add_score(dict["score"])
			#загрузка врагов и монет
				_:
					MainSceneNode.load_coins_enemies(dict["type"],dict["pos_x"], dict["pos_y"])
				
	
