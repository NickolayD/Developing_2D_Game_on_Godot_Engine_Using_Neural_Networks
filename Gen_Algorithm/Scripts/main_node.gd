extends Node

# ПАРАМЕТРЫ ДЛЯ УПРАВЛЕНИЯ СЦЕНАМИ
var current_scene: Node = null # переменная текущей сцены
var level_manager: PackedScene = preload("res://Scenes/main_scene.tscn") # менеджер обучающих сцен
var main_menu: PackedScene = preload("res://Scenes/menu.tscn") # главное меню
var end_menu: PackedScene = preload("res://Scenes/end_menu.tscn") # меню завершения
var param_menu: PackedScene = preload("res://Scenes/parameters_menu.tscn")
var end_scene: bool = false # флаг перехода к меню завершения
var prm_scene: bool = false # флаг перехода к меню параметров
# ПАРАМЕТРЫ, СВЯЗАННЫЕ С ОБУЧЕНИЕМ МОДЕЛИ И ЕЕ ХАРАКТЕРИСТИКАМИ
var level_amount: int = 10 # число уровней обучения
var pop_size: int = 100 # размер популяции
var population: Array = [] # список весов всех моделей
var hid_layer: int = 5 # число нейронов в скрытом слое
var n_in: int = 5 # число входных параметров нейронной сети
var n_out: int = 1 # число выходных параметров нейронной сети
var mut_size: int = 20 # % от числа весов объекта, который будет изменен
var mut_amount: int = 20 # макс. размер, на который будет изменен вес объекта, в %
var max_finishers: int = 1 # число финалистов, при котором происходит смена сцены
var mob_speed: int = 400 # скорость
var zone_radius: int = 100 # радиус зоны мониторинга
var max_num_of_collisions: int = 0 # макс. число допустимых столкновений
var simulation_time: int = 14 # время существования одной сцены 


func _ready() -> void:
	'''Процессы, выполняемые единожды при загрузке сцены'''
	#Инициализирует главное меню при запуске
	current_scene = main_menu.instantiate()
	var button1 = current_scene.find_child("Button", true, false)
	var button2 = current_scene.find_child("Button2", true, false)
	var button3 = current_scene.find_child("Button3", true, false)
	button1.connect("pressed", _on_start_button_pressed)
	button2.connect("pressed", _on_prm_button_pressed)
	button3.connect("pressed", _on_exit_button_pressed)
	$'.'.add_child(current_scene) 


func _process(delta: float) -> void:
	'''Основной процесс сцены'''
	# отслеживание флага переключения на меню завершения
	if end_scene:
		end_scene = false
		current_scene.queue_free()
		current_scene = end_menu.instantiate()
		var button1 = current_scene.find_child("Button", true, false)
		button1.connect("pressed", _on_end_back_button_pressed)
		var button2 = current_scene.find_child("Button2", true, false)
		button2.connect("pressed", _on_exit_button_pressed)
		$'.'.add_child(current_scene)


func _on_start_button_pressed() -> void:
	'''Переключение на главную сцену для проведения симуляции'''
	current_scene.queue_free()
	current_scene = level_manager.instantiate()
	$'.'.add_child(current_scene) 


func _on_prm_button_pressed() -> void:
	'''Инициализация меню параметров при нажатии соотвующей клавиши'''
	current_scene.queue_free()
	current_scene = param_menu.instantiate()
	_define_defaul_prm_values(current_scene)
	var button1 = current_scene.find_child("Button", true, false)
	button1.connect("pressed", _on_prm_back_button_pressed)
	$'.'.add_child(current_scene)


func _on_prm_back_button_pressed() -> void:
	'''Инициализация главного меню при закрытии меню параметров'''
	_redefine_prm_values(current_scene)
	current_scene.queue_free()
	current_scene = main_menu.instantiate()
	var button1 = current_scene.find_child("Button", true, false)
	var button2 = current_scene.find_child("Button2", true, false)
	var button3 = current_scene.find_child("Button3", true, false)
	button1.connect("pressed", _on_start_button_pressed)
	button2.connect("pressed", _on_prm_button_pressed)
	button3.connect("pressed", _on_exit_button_pressed)
	$'.'.add_child(current_scene) 


func _on_end_back_button_pressed() -> void:
	'''инициализация главного меню при возвращении из меню заверщения'''
	current_scene.queue_free()
	current_scene = main_menu.instantiate()
	var button1 = current_scene.find_child("Button", true, false)
	var button2 = current_scene.find_child("Button2", true, false)
	var button3 = current_scene.find_child("Button3", true, false)
	button1.connect("pressed", _on_start_button_pressed)
	button2.connect("pressed", _on_prm_button_pressed)
	button3.connect("pressed", _on_exit_button_pressed)
	$'.'.add_child(current_scene) 


func _on_exit_button_pressed() -> void:
	'''Завершение рабочего процесса'''
	get_tree().quit()


func _define_defaul_prm_values(scene: Control) -> void:
	'''Запись дефолтных значения параметров симуляции для меню параметров'''
	scene.find_child("LE1", true, false).text = str(level_amount)
	scene.find_child("LE2", true, false).text = str(pop_size)
	scene.find_child("LE3", true, false).text = str(n_in)
	scene.find_child("LE4", true, false).text = str(hid_layer)
	scene.find_child("LE5", true, false).text = str(mut_size)
	scene.find_child("LE6", true, false).text = str(mut_amount)
	scene.find_child("LE7", true, false).text = str(mob_speed)
	scene.find_child("LE8", true, false).text = str(zone_radius)
	scene.find_child("LE9", true, false).text = str(simulation_time)


func _redefine_prm_values(scene: Control) -> void:
	'''Запись значений параметров симуляции при закрытии меню параметров'''
	level_amount = int(scene.find_child("LE1", true, false).text)
	pop_size = int(scene.find_child("LE2", true, false).text)
	n_in = int(scene.find_child("LE3", true, false).text)
	hid_layer = int(scene.find_child("LE4", true, false).text)
	mut_size = int(scene.find_child("LE5", true, false).text)
	mut_amount = int(scene.find_child("LE6", true, false).text)
	mob_speed = int(scene.find_child("LE7", true, false).text)
	zone_radius = int(scene.find_child("LE8", true, false).text)
	simulation_time = int(scene.find_child("LE9", true, false).text)
