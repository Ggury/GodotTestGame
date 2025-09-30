extends TileMapLayer
#основной скрипт карты

@export var tilemap_width = 100
@export var tilemap_height = 100
@export var fill_percent = 0.5
@export var iterations = 5
@export var wall_tile_id = 1
@export var smooth_threshold:int = 4
@export var WallAtlasCoords: Vector2i = Vector2i(0,0)
@export var air_tile_id = 0
@export var layer_index = 0
@export var min_cave_size: int = 20 
@export var corridor_width: int = 1

@onready var RootNode = $".."
var regions: Dictionary = {}
var caves:Array

var tilemap_array:Array
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

#заполнение массива карты единицами по краям и случайно генерироем содержимое внутри коробки
func generate_previous_map():
	tilemap_array.resize(tilemap_width)
	for x in range (tilemap_width):
		tilemap_array[x] = []
		tilemap_array[x].resize(tilemap_height)
		for y in range (tilemap_height):
			if x == 0 or x == tilemap_width-1 or y ==0 or y == tilemap_height-1:
				tilemap_array[x][y] = 1
			elif rng.randf_range(0.0,1.0) < fill_percent:
				tilemap_array[x][y] = 1
			else:
				tilemap_array[x][y] = 0


#генерация границ карты (необходимо далее)
func generate_borders():
	for x in range (tilemap_width):
		for y in range (tilemap_height):
			if x == 0 or x == tilemap_width-1 or y ==0 or y == tilemap_height-1:
				tilemap_array[x][y] = 1

#Применение клеточного аппарата к сгенерированной карте для создания правдоподобных пещер
func smooth_map():
	var new_map_array:Array = tilemap_array.duplicate()
	for x in range (1 , tilemap_width-1):
		for y in range  (1,tilemap_height-1):
			var neighbour_walls_count = get_count_of_alive_neighbours(x,y)
			if tilemap_array[x][y] ==1:
				if neighbour_walls_count < smooth_threshold:
					new_map_array[x][y] = 0
				else:
					new_map_array[x][y] = 1
			else:
				if neighbour_walls_count > smooth_threshold:
					new_map_array[x][y] = 1
				else:
					new_map_array[x][y] = 0
	#print(new_map_array)
	tilemap_array = new_map_array
#получение количества соседей клетки, которые являются единицей
func get_count_of_alive_neighbours(grid_x:int , grid_y:int):
	var count = 0
	for x in range(grid_x-1, grid_x+2):
		for y in range(grid_y-1, grid_y+2):
			if x == grid_x and y == grid_y:
				continue
			if x>=0 and x < tilemap_width and y>=0 and y<=tilemap_height:
				count += tilemap_array[x][y]
			else:
				count +=1
	return count

#отрисовка массива карты в tilemapLayer
func draw_tilemap():
	clear()
	for x in range (tilemap_width):
		for y in range(tilemap_height):
			if tilemap_array[x][y] == 1:
				set_cell(Vector2i(x,y),1,WallAtlasCoords)

#получение массива существующих пещер с помощью функции flood_fill
func get_caves(min_cave_sz:int):
	caves = []
	caves.resize(tilemap_width)
	for x in range(tilemap_width):
		caves[x] =[]
		caves[x].resize(tilemap_height)
		for y in range (tilemap_height):
			caves[x][y] = 0
	var cur_id = 1
	for x in range (tilemap_width):
		for y in range(tilemap_height):
			if tilemap_array[x][y] == 0 and caves[x][y] ==0:
				var new_region = []
				flood_fill(Vector2i(x,y),cur_id, new_region)
				if new_region.size() >= min_cave_sz:
					regions[cur_id] = new_region
					cur_id += 1
				else:
					for p in new_region:
						tilemap_array[p.x][p.y] = 1
						

#функция flood_fill, осуществяет поиск в ширину
func flood_fill(start_coords: Vector2i, region_id:int, region_list: Array):
	var queue: Array = [start_coords]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		var x:int = p.x
		var y:int = p.y
		if x < 0 or x>=tilemap_width or y<0 or y>= tilemap_height:
			continue
		if tilemap_array[x][y] == 1 or caves[x][y] !=0:
			continue
		caves[x][y] = region_id
		region_list.append(p)
		queue.append(Vector2i(x+1,y))
		queue.append(Vector2i(x-1,y))
		queue.append(Vector2i(x,y+1))
		queue.append(Vector2i(x,y-1))

#нахождение корневого индетификатора пещеры
var union_find: Dictionary = {}
func find_root(id: int):
	if union_find[id] == id:
		return id
	union_find[id] = find_root(union_find[id])
	return union_find[id]

#объединение двух пещер в один регион
func combine_sets(id_a: int, id_b: int):
	var root_a = find_root(id_a)
	var root_b = find_root(id_b)
	if root_a != root_b:
		union_find[root_b] = root_a


#получение центра пещеры
func get_region_center(region_id:int):
	var region_points:Array = regions[region_id]
	if region_points.is_empty():
		return Vector2i.ZERO
	var sumx = 0
	var sumy = 0
	for p in region_points:
		sumx+= p.x
		sumy += p.y
	return Vector2i(sumx/ region_points.size(), sumy / region_points.size())

#круглая кисть для соединения корридоров. Вырезает вокруг ячейки окружность определенного радиуса
func carve_circle(center_x: int, center_y:int, radius: int):
	var radius_sq = int(radius * radius)
	for x in range(center_x - radius, center_x+radius):
		for y in range(center_y - radius, center_y+radius):
			var dx:int = x - center_x
			var dy:int = y - center_y
			if dx*dx + dy*dy <= radius_sq:
				if is_inside_bounds(x,y):
					tilemap_array[x][y] = 0
#создание корридора. Прохождение между двумя точками кистью описанной выше со случайным отклонением
func creating_corridor(start_p: Vector2i, end_p: Vector2i, width  : int):
	var current_p = Vector2(float(start_p.x), float(start_p.y))
	var target_p = Vector2(float(end_p.x), float(end_p.y))
	
	while current_p.distance_to(target_p) >1.5:
		var dir = (target_p - current_p).normalized()
		var wander_x = rng.randf_range(-0.5, 0.5)
		var wander_y = rng.randf_range(-0.5, 0.5)
		var final_dir = dir * 0.9 + Vector2(wander_x, wander_y) * 0.1
		final_dir = final_dir.normalized()
		current_p += final_dir * rng.randf_range(0.8, 1.2)
		
		carve_circle(int(round(current_p.x)), int(round(current_p.y)), width)
		
		if current_p.distance_to(Vector2(float(start_p.x), float(start_p.y))) > tilemap_width * 2:
			break


#алгоритм Краскала для соединения всех пещер наикратчайшими корридорами, избегая при этом повторного соединения одних и тех же пещер
func connect_all_regions(corrdr_wdth:int):
	var region_ids: Array = regions.keys()
	
	if region_ids.size() < 2:
		return
	union_find.clear()
	for region_id in region_ids:
		union_find[region_id] = region_id
	var all_connections: Array = []
	for i in range(region_ids.size()):
		var id_a = region_ids[i]
		var center_a = get_region_center(id_a)
		for j in range(i + 1, region_ids.size()):
			var id_b = region_ids[j]
			var center_b = get_region_center(id_b)
			all_connections.append({
				"id_a": id_a,
				"id_b": id_b,
				"dist": center_a.distance_to(center_b), # Расстояние между центрами
				"center_a": center_a,
				"center_b": center_b})
	all_connections.sort_custom(func(a, b): return a.dist < b.dist)
	for conn in all_connections:
		var id_a = conn.id_a
		var id_b = conn.id_b
		if find_root(id_a) != find_root(id_b):
			creating_corridor(conn.center_a, conn.center_b, corrdr_wdth)
			combine_sets(id_a,id_b)
			
			
#проверка, находятся ли координаты внутри карты
func is_inside_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < tilemap_width and y >= 0 and y < tilemap_height

#генерация карты
func generate_cave_map():
	rng.randomize()
	generate_previous_map()
	for i in range(iterations):
		smooth_map()
	get_caves(min_cave_size)
	connect_all_regions(corridor_width)
	generate_borders()
	generate_points_to_main_node()
	draw_tilemap()
 
#передача точек карты, где отсутствуют стены. Необходимо для корретного спавна монет и врагов
func generate_points_to_main_node():
	var SpawnPoints = []
	var tile_size: Vector2 = tile_set.tile_size
	for x in range(tilemap_width):
		for y in range(tilemap_height):
			if tilemap_array[x][y] == 0:
				var global_pos_top_left = map_to_local(Vector2i(x, y))
				var center_position: Vector2 = global_pos_top_left + (tile_size / 2.0)
				SpawnPoints.append(center_position)
	RootNode.PonitsFreeToSpawn = SpawnPoints
func _ready() -> void:
	generate_cave_map()

#сохранение карты (сохранение массива tilemap_array
func save() -> Dictionary:
	return {
		"type": "TileMap", # Важно для идентификации при загрузке
		"MapData": tilemap_array
	}
#загрузка карты (загрузка массива карты и повторная отрисовка)
func load_map(TileArr:Array):
	tilemap_array = TileArr
	draw_tilemap()
