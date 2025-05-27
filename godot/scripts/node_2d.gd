extends Node2D

var noise = FastNoiseLite.new()
var img_size = 256
var island_radius = img_size / 2.5
var color_ramp: GradientTexture1D

@onready var water_layer = $water
@onready var ground_layer = $ground

const WATER_SOURCE_ID = 20  # Assuming 20 is the correct tile ID for water
const WATER_ATLAS_COORDS = Vector2i(0, 0)
const TERRAIN_SET = 0

# Biome indices for terrain
const FOREST_TERRAIN_INT = 0
const DESERT_TERRAIN_INT = 1
const CAVE_TERRAIN_INT = 3
const SNOW_TERRAIN_INT = 4

enum BIOME { FOREST, DESERT, SNOW, CAVE }
var biome_map = {}

# Arrays to store terrain data
var water_tiles = []
var land_tiles = []
var forest_tiles = []
var desert_tiles = []
var cave_tiles = []
var snow_tiles = []

var offset = Vector2i(img_size / 2, img_size / 2)

# Define decorations for each biome
const BIOME_DECORATIONS = {
	BIOME.FOREST: [
		{ "source_id": 7, "atlas_coords": Vector2i(5, 0) }, 
		{ "source_id": 7, "atlas_coords": Vector2i(6, 0) }, 
		{ "source_id": 7, "atlas_coords": Vector2i(8, 1) }  
	],
	BIOME.DESERT: [
		{ "source_id": 39, "atlas_coords": Vector2i(0, 0) }, 
		{ "source_id": 39, "atlas_coords": Vector2i(2, 0) },  
		{ "source_id": 39, "atlas_coords": Vector2i(4, 0) }
	],
	BIOME.SNOW: [
		{ "source_id": 48, "atlas_coords": Vector2i(3, 1) }, # Snow Tree
		{ "source_id": 48, "atlas_coords": Vector2i(3, 2) },  # Ice Rock
		{ "source_id": 49, "atlas_coords": Vector2i(0, 0) }
	],
	BIOME.CAVE: [
		{ "source_id": 36, "atlas_coords": Vector2i(0, 0) }, # Stalagmite
		{ "source_id": 36, "atlas_coords": Vector2i(0, 1) },
		{ "source_id": 36, "atlas_coords": Vector2i(0, 2) },
		{ "source_id": 36, "atlas_coords": Vector2i(1, 0) },
		{ "source_id": 36, "atlas_coords": Vector2i(1, 1) },
		{ "source_id": 36, "atlas_coords": Vector2i(1, 2) },
		{ "source_id": 37, "atlas_coords": Vector2i(0, 0) },
		{ "source_id": 37, "atlas_coords": Vector2i(0, 1) },
		{ "source_id": 37, "atlas_coords": Vector2i(0, 2) },
		{ "source_id": 37, "atlas_coords": Vector2i(1, 0) },
		{ "source_id": 37, "atlas_coords": Vector2i(1, 1) },
		{ "source_id": 37, "atlas_coords": Vector2i(1, 2) },
		{ "source_id": 37, "atlas_coords": Vector2i(2, 0) },
		{ "source_id": 37, "atlas_coords": Vector2i(2, 1) } # Rock Formation
	]
}

var tree_scene = preload("res://scenes/tree.tscn")


func _ready():
	setup_noise()
	setup_color_ramp()
	place_biomes()         # Place biomes first
	generate_biome_map()   # Expand biomes across the map
	generate_terrain()     # Generate and render terrain
	place_decorations()

func setup_noise():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.03

func setup_color_ramp():
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.0, 0.3, 1.0))  # Deep water
	gradient.add_point(0.3, Color(0.0, 0.6, 1.0))  # Shallow water
	gradient.add_point(0.4, Color(0.9, 0.8, 0.6))  # Beach
	gradient.add_point(0.6, Color(0.0, 0.5, 0.0))  # Grassland
	gradient.add_point(0.8, Color(0.1, 0.4, 0.1))  # Dark forest
	gradient.add_point(1.0, Color(0.5, 0.5, 0.5))  # Mountain

	color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient

func generate_terrain():
	for x in range(img_size):
		for y in range(img_size):
			var pos = Vector2i(x, y)
			var nx = (x - img_size / 2) / island_radius
			var ny = (y - img_size / 2) / island_radius
			var distance = sqrt(nx * nx + ny * ny)

			var falloff = clamp(1.0 - pow(distance, 2.0), 0.0, 1.0)
			var noise_value = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var height = (noise_value * 0.6) + (falloff * 0.7)

			if distance > 1.0:
				height = 0.0  # Force deep water outside island

			# Categorize tile type
			if height < 0.4:
				water_tiles.append(pos)
			else:
				land_tiles.append(pos)
			water_layer.set_cell(pos - offset, WATER_SOURCE_ID, WATER_ATLAS_COORDS)

	# Assign biome-specific tiles
	for pos in land_tiles:
		if pos in biome_map:
			match biome_map[pos]:
				BIOME.FOREST:
					forest_tiles.append(pos)
				BIOME.DESERT:
					desert_tiles.append(pos)
				BIOME.SNOW:
					snow_tiles.append(pos)
				BIOME.CAVE:
					cave_tiles.append(pos)
	for pos in land_tiles:
		if pos not in desert_tiles and pos not in snow_tiles and pos not in cave_tiles:
			forest_tiles.append(pos)

	# Apply biomes using set_cells_terrain_connect
	ground_layer.set_cells_terrain_connect(land_tiles.map(func(p): return p - offset), TERRAIN_SET, FOREST_TERRAIN_INT)
	ground_layer.set_cells_terrain_connect(desert_tiles.map(func(p): return p - offset), TERRAIN_SET, DESERT_TERRAIN_INT)
	ground_layer.set_cells_terrain_connect(snow_tiles.map(func(p): return p - offset), TERRAIN_SET, SNOW_TERRAIN_INT)
	ground_layer.set_cells_terrain_connect(cave_tiles.map(func(p): return p - offset), TERRAIN_SET, CAVE_TERRAIN_INT)

func place_biomes():
	var angles = [0, 120, 240]
	var biome_types = [BIOME.DESERT, BIOME.SNOW, BIOME.CAVE]

	for i in range(3):
		var angle = deg_to_rad(angles[i])
		var x = img_size / 2 + cos(angle) * (island_radius * 0.7)
		var y = img_size / 2 + sin(angle) * (island_radius * 0.7)

		var biome_pos = find_nearest_land(Vector2(x, y))
		if biome_pos != null:
			biome_map[biome_pos] = biome_types[i]

func find_nearest_land(pos: Vector2):
	for r in range(10):
		for a in range(0, 360, 30):
			var rad = deg_to_rad(a)
			var test_x = pos.x + cos(rad) * r
			var test_y = pos.y + sin(rad) * r

			if is_land(Vector2(test_x, test_y)):
				return Vector2i(test_x, test_y)
	return null

func is_land(pos: Vector2):
	if pos.x < 0 or pos.x >= img_size or pos.y < 0 or pos.y >= img_size:
		return false

	var nx = (pos.x - img_size / 2) / island_radius
	var ny = (pos.y - img_size / 2) / island_radius
	var distance = sqrt(nx * nx + ny * ny)

	return distance <= 1.0

func generate_biome_map():
	var max_spread = img_size / 5
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	for biome_pos in biome_map.keys():
		var biome_type = biome_map[biome_pos]
		var queue = [biome_pos]

		while not queue.is_empty():
			var current = queue.pop_front()
			for dir in directions:
				var neighbor = current + dir  
				
				if neighbor in biome_map:
					continue

				var noise_factor = noise.get_noise_2d(neighbor.x * 1.5, neighbor.y * 1.5) * 0.5 + 0.5 
				var edge_variation = max_spread * (0.7 + noise_factor * 0.3) 
				
				if is_land(neighbor) and (current - biome_pos).length() < edge_variation:
					biome_map[neighbor] = biome_type
					queue.append(neighbor)

	print("Biomes placed successfully!")

func place_decorations():
	var decorations_layer = $environment
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	
	const BIOME_EDGE_BUFFER = 4  # Adjust to control how far from edges we block decorations

	for pos in land_tiles:
		var biome = biome_map.get(pos, BIOME.FOREST)  # Default to FOREST if not explicitly in biome_map
		var decorations = BIOME_DECORATIONS.get(biome, [])

		# Check a square area around the tile
		var near_biome_edge = false
		for dx in range(-BIOME_EDGE_BUFFER, BIOME_EDGE_BUFFER + 1):
			for dy in range(-BIOME_EDGE_BUFFER, BIOME_EDGE_BUFFER + 1):
				var neighbor = pos + Vector2i(dx, dy)
				if neighbor in biome_map and biome_map[neighbor] != biome:
					near_biome_edge = true
					break
				elif pos in biome_map and neighbor not in biome_map:
					near_biome_edge = true
					break
			if near_biome_edge:
				break

		if near_biome_edge:
			continue  # Skip placing decorations at this position
		
		if biome == BIOME.FOREST and rng.randf() < 0.05:  # 20% chance to spawn a tree
			var tree_instance = tree_scene.instantiate()
			tree_instance.position = (pos - offset) * 16  # Adjust scaling if needed
			$".".add_child(tree_instance)
			continue  # Skip placing tile decorations if tree is placed
		# Randomly place decorations (with a 10% chance)
		if decorations.size() > 0 and rng.randf() < 0.1:
			var chosen_decoration = decorations[rng.randi_range(0, decorations.size() - 1)]
			decorations_layer.set_cell(pos - offset, chosen_decoration["source_id"], chosen_decoration["atlas_coords"])
