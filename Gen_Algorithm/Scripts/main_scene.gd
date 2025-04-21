extends Node2D


var scene_instance: Node # переменная для хранения текущей сцены
var rng = RandomNumberGenerator.new() # генератор случайных чисел
var time_to_stop: bool = false # флаг заверщения обучения
var end_cur_simulation: bool = false # флаг окончания текущей эпохи моделирования
var level_id: int = 0 # номер текущей загруженной карты уровня
var finishers: Dictionary = {} # словарь для записи победителей на каждом уровне
@onready var main = get_node("/root/MainNode") # для доступа к главной сцене


func _ready() -> void:
	'''Процессы, выполняемые единожды при загрузке сцены'''
	# инициализируем первой популяции
	_init_population()
	# загрузка и создание сцены первого уровня обучения
	scene_instance = load("res://Scenes/scene.tscn").instantiate()
	add_child(scene_instance)


func _process(delta: float) -> void:
	'''Основной процесс сцены'''
	# проверка на флаг завершения процесса обучения
	if time_to_stop:
		var parent = get_parent()
		parent.end_scene = true
		return
	# проверка условия для переключения на след. уровень обучения
	if not is_instance_valid(scene_instance) and not end_cur_simulation:
		# проверка на завершение текущей эпохи моделирования
		if level_id == (main.level_amount - 1):
			end_cur_simulation = true
			return
		level_id = level_id + 1 # смена индекса уровня обучения
		# загружаем новую сцену и добавляем ее в дерево сцен
		scene_instance = load("res://Scenes/scene.tscn").instantiate()
		$'.'.add_child(scene_instance)
	# условие окончания текущей эпохи моделирования
	if end_cur_simulation:
		# ищем пересечения списков среди победителей на каждом уровне
		var tmp = finishers[1]
		for i in range(2, main.level_amount + 1):
			tmp = _find_intersection(tmp, finishers[i])
			if tmp == []:
				break
		# если найден победитель на всех уровнях -> переход на меню завершения
		if tmp != []:
			time_to_stop = true
			_write_arr_in_file(main.population[tmp[0]])
		else: # формируем след. популяцию на основе локальных победителей
			var candidates = MySet.new()
			while candidates.get_length() < 10:
				var empty_lst_amount = 0
				for i in range(1, main.level_amount + 1):
					var el = finishers[i].pop_front()
					if el:
						candidates.add(el)
					else:
						empty_lst_amount += 1
				if empty_lst_amount == main.level_amount:
					break
			# если вообще ничего нет, то заново рандомим популяцию
			if candidates.get_length() == 0:
				_init_population()
			else: # иначе проводим процесс кроссинговера и мутации
				# индексы мас. population, веса которых показали лучшие рез-ты
				candidates = candidates.to_array().slice(0, 10)
				var best = []
				# формируем список с весами лучших объектов прошлой популяции
				for ind in candidates:
					best.append(main.population[ind])
				# операция кроссинговера
				var crossover = _crossover_process(candidates)
				# операция мутации
				var mutation = _mutation_process(crossover)
				# обновляем новый массив с весами следующей популяции
				main.population = best + crossover + mutation
			# коррект. пар-ры управления сценами для их повторного проигрывания
			level_id = -1
			end_cur_simulation = false


func _find_intersection(arr1: Array, arr2: Array) -> Array:
	'''Метод для поиска общих элеметов двух массивов'''
	var tmp = []
	for el in arr1:
		if el in arr2:
			tmp.append(el)
	return tmp


func _init_population() -> void:
	'''Объявление массива весов популяции (из нормального распределения)'''
	main.population = []
	for i in range(main.pop_size):
		main.population.append([])
		for j in range(main.hid_layer * (main.n_in + main.n_out)):
			main.population[-1].append(rng.randfn())


func _crossover_process(arr: Array) -> Array:
	'''Метод для проведения кроссинговера'''
	var length = main.hid_layer * (main.n_in + main.n_out) # длина "хромосомы"
	var crossover = []
	var slice1 # Переменные для временного хранения частей массивов исходных 
	var slice2 # объектов популяции для из перестанок в процесс кроссинговера
	for i in range(len(arr)):
		for j in range(len(arr)):
			if j > i:
				var rnd_ind = rng.randi_range(1, length - 1)
				# Первая часть первого + вторая часть второго
				slice1 = main.population[arr[i]].slice(0, rnd_ind)
				slice2 = main.population[arr[j]].slice(rnd_ind, length)
				crossover.append(slice1 + slice2)
				# Вторая часть первого + первая часть второго
				slice1 = main.population[arr[i]].slice(rnd_ind, length)
				slice2 = main.population[arr[j]].slice(0, rnd_ind)
				crossover.append(slice1 + slice2)
	return crossover


func _mutation_process(arr: Array) -> Array:
	'''Метод длч проведения процесса мутации'''
	var mutation = []
	for el in arr:
		# добавляем в список новую мутацию
		mutation.append(el.slice(0, len(el)))
		# получаем индексы списка, значения в которых "митуруют"
		var index_lst = Array(range(len(el)))
		index_lst.shuffle()
		# для каждого выбранного индекса изменяем значение на малую величину
		for ind in index_lst.slice(0, int(len(el) * main.mut_size/100)):
			var tmp = mutation[-1][ind]*rng.randi_range(1, main.mut_amount)/ 100
			if rng.randi_range(0, 1):
				mutation[-1][ind] = mutation[-1][ind] + tmp
			else:
				mutation[-1][ind] = mutation[-1][ind] - tmp
	return mutation


func _write_arr_in_file(arr: Array) -> void:
	var file = FileAccess.open('res://result.txt', FileAccess.WRITE)
	if file:
		var srt = ''
		for el in arr:
			srt += str(el) + ' '
		file.store_string(srt)
		file.close()
