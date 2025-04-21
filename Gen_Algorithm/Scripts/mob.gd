extends CharacterBody2D


var id: int # переменная для записи уникального индекса моба
var parent: Node # переменная для обращения к родительской сцене
var w1: Array = [] # массив для записи весов: входной слой - скртый слой
var w2 = [] # массив для записи весов: скрытый слой - выходной слой
var time = 0.0 # переменная для отслеживания времени 
var angle # переменная для записи результата нейронной сети (угла поворота)
var num_of_collisions = 0 # макс. число разрешенных столкновений
@onready var main = get_node("/root/MainNode") # для доступа к главной сцене


func _ready() -> void:
	'''Процессы, выполняемые единожды при загрузке сцены'''
	parent = get_parent() # получаем доступ к параметрам родительской сцены
	id = len(parent.mobs) - 1 # присыоение мобу уникального номера
	# присвоение мобу весов в соответствии с полученным индексом
	_get_mob_weights()


func _physics_process(delta: float) -> void:
	'''Основной процесс сцены'''
	# удаляем моба, если вышло время симуляции
	time += delta
	if time > main.simulation_time:
		_delete_mob()
	# проверяем, прошел ли моб зону финиша
	if _check_zone(parent.finish_pos, parent.finish_directory):
		parent.cur_finishers.append(id)
		_delete_mob()
	# получаем угол повора от нейронной сети и поворачиваем вектор скорости
	angle = _calc_vector_rotation()
	velocity = velocity.rotated(angle[0][0])
	# отслеживание коллизий со стенами
	_collision_detection(delta)


func _get_mob_weights() -> void:
	'''Метод заполняет массивы весовых коэффициентов моба'''
	var lst = main.population[id]
	for i in range(main.hid_layer):
		w1.append(lst.slice(main.n_in * i, main.n_in * (i+1)))
	w2.append(lst.slice(
		main.n_in * main.hid_layer,
		(main.n_in + 1) * main.hid_layer)
	)


func _calc_vector_rotation() -> Array:
	'''Пропускает сигнал через нейронную сеть моба'''
	var answer
	# рассчитываем расстояние до стен
	answer = _distance_to_walls()
	# прохождение сигнала через первый слой (входной - скрытый)
	answer = _mult(w1, answer)
	# применение нелинейности
	_tanh(answer)
	# прохождение сигнала через второй слой (скрытый - выходной)
	answer = _mult(w2, answer)
	# применение нелинейности / нормировка
	_tanh(answer)
	return answer


func _mult(a: Array, b: Array) -> Array:
	'''Операция перемножения двух матриц'''
	var c = []
	for i in range(len(a)):
		c.append([])
		for j in range(len(b[0])):
			c[-1].append(0)
	for i in range(len(a)):
		for j in range(len(b[0])):
			var tmp = 0
			for k in range(len(a[0])):
				tmp = tmp + a[i][k] * b[k][j]
			c[i][j] = tmp
	return c


func _sigmoid(x: Array) -> void:
	'''Применяет сигмоиду ко всем эл-там массива'''
	for i in range(len(x)):
		for j in range(len(x[1])):
			x[i][j] = 1.0 / (1.0 + exp(-x[i][j]))


func _tanh(x: Array) -> void:
	'''применяет гиперболический тангенс ко всем эл-там массива'''
	for i in range(len(x)):
		for j in range(len(x[0])):
			x[i][j] = (exp(2 * x[i][j]) - 1) / (exp(2 * x[i][j]) + 1)


func _user_input():
	'''Остлеживание пользовательского ввода'''
	if Input.is_anything_pressed():
		pass


func _collision_detection(delta):
	'''Отслеживает коллизии мобов со стенами'''
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		# случай с допущением некоторого числа столкновений
		if num_of_collisions < main.max_num_of_collisions:
			num_of_collisions = num_of_collisions + 1
			var reflect = collision.get_remainder().bounce(collision.get_normal())
			velocity = velocity.bounce(collision.get_normal())
			move_and_collide(reflect)
		else:
			_delete_mob()


func _delete_mob():
	'''Удаляет моба и стирает все эл-ты из памяти'''
	parent.mobs.erase(id)
	var this_scene = $'.'
	this_scene.queue_free()
	this_scene = null


func _check_zone(pos: Array, dir: Vector2) -> bool:
	'''Проверка на пересечение мобов определенной области'''
	if dir == Vector2(-1, 0):
		if position.y > pos[1][0] * 30 and position.y < pos[1][1] * 30:
			if abs(position.x - pos[0][0] * 30) < 2 * $Shape.shape.radius:
				return true
		return false
	if dir == Vector2(1, 0):
		if position.y > pos[1][0] * 30 and position.y < pos[1][1] * 30:
			if abs(position.x - pos[0][1] * 30) < 2 * $Shape.shape.radius:
				return true
		return false
	if dir == Vector2(0, -1):
		if position.x > pos[0][0] * 30 and position.x < pos[0][1] * 30:
			if abs(position.y - pos[1][0] * 30) < 2 * $Shape.shape.radius:
				return true
		return false
	if dir == Vector2(0, 1):
		if position.x > pos[0][0] * 30 and position.x < pos[0][1] * 30:
			if abs(position.y - pos[1][1] * 30) < 2 * $Shape.shape.radius:
				return true
		return false
	return false


func _distance_to_walls() -> Array:
	'''Метод вычисляет расстояние от моба до стен по заданным направлениям'''
	var n = main.zone_radius # радиус зоны мониторинга
	var r = 10 # радиус моба
	var answer = [] # массив ответов
	var cur_pos = $".".global_position # текущая позиция моба в глоб. коорд.
	var space_state = get_world_2d().direct_space_state # для отслеж. коллизий
	# формируем массив с векторами, задающими направления отслеживания столкновений
	var vectors = []
	var v_norm = velocity.normalized()
	for i in range(main.n_in):
		vectors.append(n * v_norm.rotated(-PI / 2 + i * PI / (main.n_in - 1)))
	# задаем и испускаем лучи по заданным направлениям
	var rays = []
	for i in range(main.n_in):
		rays.append(
			PhysicsRayQueryParameters2D.create(
				cur_pos, 
				Vector2(cur_pos.x+vectors[i].x, cur_pos.y + vectors[i].y)
			)
		)
		# корректируем маску, для остлеживания пересечений с опред. объектами
		rays[-1].collision_mask = 0b11111111111111111111111111111101
		# испускаем луч и заполняем массив ответов
		var res = space_state.intersect_ray(rays[-1])
		if not res.is_empty():
			answer.append(
				[1 - ((res["position"] - cur_pos).length() - r) / (n - r)]
			)
		else:
			answer.append([0.0])
	return answer
