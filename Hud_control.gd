extends Control

@onready var ScoreLabel = $Score
@onready var Fuel_Bar = $Fuel_Bar
@onready var Panel_GameOver = $"../GameOverPanel"
@onready var GameOver_Label = $"../GameOverPanel/GameOverLabel"
@onready var Win_Label = $"../GameOverPanel/Win_Label"

func _ready() -> void:
	GlobalScript.connect("ScoreUpdated", Callable(self, "set_scoreLabel"))
	GlobalScript.connect("GameOver", Callable(self, "GameOverScreen"))
	GlobalScript.connect("GameWinned", Callable(self, "GameWinScreen"))
	Panel_GameOver.visible = false
	set_scoreLabel(0)

#вывод экрана проигрыша
func GameOverScreen():
	Panel_GameOver.visible = true
	GameOver_Label.visible = true
#вывод экрана победы
func GameWinScreen():
	Panel_GameOver.visible = true
	Win_Label.visible = true
	
#обновление счетчика на экране
func set_scoreLabel(new_score):
	ScoreLabel.text = str("Score: "+ str(new_score))

#обновление полоски топлива
func update_fuel(fuel):
	Fuel_Bar.value = fuel

#привязка функции загрузки к кнопке
func _on_load_button_pressed() -> void:
	GlobalScript.load_game()

#привязка функции сохранения к кнопке сохранения
func _on_save_button_pressed() -> void:
	GlobalScript.save_game()



func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
	#GlobalScript._ready()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
