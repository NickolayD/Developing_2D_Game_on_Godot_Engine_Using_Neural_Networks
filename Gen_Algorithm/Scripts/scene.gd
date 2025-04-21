extends Node2D


var mob_scene: PackedScene = preload("res://Scenes/mob.tscn") # сцена "моба"
var levels = MyLevels.new() # объект, хранящий все доступные карты уровней
var parent: Node # переменная для обращения к родительской сцене
var start_pos: Array # массив для хранения координат стартовой области
var finish_pos: Array # массив для хранения координат финишной области
var start_directory: Vector2 # переменная для записи направления стартовой области
var finish_directory: Vector2 # переменная для записи направления финишной области
var mobs: Array = [] # массив для храниния активных мобов
var cur_finishers: Array = [] # массив для записи победителей текущей сцены
@onready var main = get_node("/root/MainNode") # для доступа к главной сцене


func _ready() -> void:
	'''Процессы, выполняемые единожды при загрузке сцены'''
	parent = get_parent() # получаем доступ к параметрам родительской сцены
	# загрузка текущей карты уровня
	var cur_lvl = levels.get_level(parent.level_id).split_floats(' ')
	# создание стен карты уровня
	_create_walls(cur_lvl)
	# определяем стартовую область и ее ориентацию
	start_pos =_define_zone(cur_lvl, 2.0)
	start_directory = _get_vector_dir(start_pos, cur_lvl)
	# определяем ориентацию финишной области
	finish_pos =_define_zone(cur_lvl, 3.0)
	finish_directory = _get_vector_dir(finish_pos, cur_lvl)
	# создание сцен мобов
	_create_mobs()


func _process(delta: float) -> void:
	'''Основной процесс сцены'''
	# смена сцены, если все мобы погибли
	if len(mobs) < 1:
		# запись в словарь номера мобов, которые прошли текущую сцену
		parent.finishers[parent.level_id + 1] = cur_finishers
		queue_free()


func _create_walls(cur_lvl: Array) -> void:
	'''Метод для инициализации карты уровня (блоков - задающих границы)'''
	var block # переменная для хранения ссылки на активнцю сцену
	for j in range(28):
		for i in range(40):
			if cur_lvl[40 * j + i] == 0.0:
				block = preload("res://Scenes/block.tscn").instantiate()
				block.position = Vector2(15 + 30 * i, 15 + 30 * j)
				$'.'.add_child(block)


func _define_zone(cur_lvl: Array, value: float) ->  Array:
	'''Метод определяет границы области с кодовым параметров value'''
	var tmp = []
	var pos = [[], []]
	for j in range(28):
		for i in range(40):
			if cur_lvl[40 * j + i] == value:
				tmp.append([i, j])
	tmp.sort_custom(func(a, b): return a[0] < b[0])
	pos[0] = [tmp[0][0], tmp[-1][0] + 1]
	tmp.sort_custom(func(a, b): return a[1] < b[1])
	pos[1] = [tmp[0][1], tmp[-1][1] + 1]
	return pos


func _get_vector_dir(pos: Array, cur_lvl: Array) -> Vector2:
	'''Метод определяет вектор ориентации для переданной области'''
	if cur_lvl[40 * pos[1][0] + pos[0][0] - 1] == 1.0:
		return Vector2(-1, 0)
	elif cur_lvl[40 * (pos[1][0] - 1) + (pos[0][0] + 1) - 1] == 1.0:
		return Vector2(0, -1)
	elif cur_lvl[40 * (pos[1][1] -0) + (pos[0][1] + 0) - 1] == 1.0:
		return Vector2(0,1)
	else:
		return Vector2(1,0)


func _create_mobs() -> void:
	'''Метод для объявления мобов/задания их позиции/направления движения'''
	var mob
	for i in range(len(main.population)):
		mobs.append(i)
		mob = mob_scene.instantiate()
		mob.position = Vector2(
			30 * (start_pos[0][1] - (start_pos[0][1] - start_pos[0][0]) * 0.5),
			30 * (start_pos[1][1] - (start_pos[1][1] - start_pos[1][0]) * 0.5)
		)
		mob.velocity = start_directory * main.mob_speed
		$'.'.add_child(mob)
