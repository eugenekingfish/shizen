extends Spatial

var crop: Resource = load("res://Scenes/Crop.tscn")

var crop_timer: float = 0.0
var death_time: float = 0.5

#CROP PROPERTIES
var max_growth_rate: float = 0.5
var crop_color: Color = Color(0, 0, 0)
var ideal_temperature: float = 15
var ideal_humidity: float = 0.0

var mutation_chance: float = 0.01

#Holds the index of the triangle the crop is on.
var tri_idx: int = 0
var tri_normal: Vector3 = Vector3.ZERO

var adj_tri_positions: Array = []
var neighbour_indices: Array = []

func _ready() -> void:
	death_time = rand_range(2, 3)
	get_parent().crop_arr.append(self)


func init_crop() -> void:
	var ico: Spatial = get_node("/root/Universe/Icosphere")  
	self.neighbour_indices = ico.get_adj_tri_indices(self.tri_idx)

	for i in range(self.neighbour_indices.size()):
		self.adj_tri_positions.append(ico.get_tri_center(self.neighbour_indices[i]))


func set_tri_idx(idx: int) -> void:
	self.tri_idx = idx
	self.tri_normal = get_node("/root/Universe/Icosphere").get_surface_normal(idx)

func set_random_weightings(prop_arr):
	var remaining_prob: float = 1.0
	var result = []
	for i in range(prop_arr.size()):
		if i == prop_arr.size() - 1:
			result.append(remaining_prob)
			break
		else:
			var prob: float = rand_range(0.0, remaining_prob)
			result.append(prob)
			remaining_prob -= prob
	return result	
		

func set_mesh() -> void:
	var leaves: SpatialMaterial = SpatialMaterial.new()
	var bark: SpatialMaterial = SpatialMaterial.new()
	bark.albedo_color = Color(1, 1, 1)
	if crop_color == Color(0, 0, 0):
		crop_color = Color(randf(), randf(), randf())
	leaves.albedo_color = crop_color
	$MeshInstance.set_surface_material(0, leaves)
	$MeshInstance.set_surface_material(1, bark)
	

func set_traits(s: Spatial) -> void:
	s.crop_color = Color(crop_color.r + rand_range(-0.01, 0.01), crop_color.g + rand_range(-0.01, 0.01), crop_color.b + rand_range(-0.01, 0.01))
	if randf() < mutation_chance:
		s.ideal_temperature *= (1.0 + rand_range(-0.5, 0.5))
		s.ideal_humidity *= (1.0 + rand_range(-10, 10))
	else:
		s.ideal_temperature *= (1.0 + rand_range(-0.05, 0.05))
		s.ideal_humidity *= (1.0 + rand_range(-1, 1))


#Handles behaviour when a crop is set to die.
func reproduce(max_angle: float, max_seeds: int) -> void:
	if can_reproduce() == true:
		for i in range(max_seeds):
			create_crop()
	kill()


func create_crop() -> void:
	var foo: Spatial = crop.instance()
	get_parent().add_child(foo)
	var r: int = randi() % 3
	foo.set_tri_idx(self.neighbour_indices[r])
	foo.init_crop()
	foo.translate(self.adj_tri_positions[r])
	##Create an axis to rotate foo's position vector around.
	var look_dir: Vector3 = foo.tri_normal.cross(Vector3.ONE)
	foo.look_at(foo.translation + look_dir * 100, foo.tri_normal)
	set_traits(foo)
	foo.set_mesh()

func can_reproduce() -> bool:
	var temp_delta: float = ideal_temperature - get_parent().temperature
	var prob: float = 1 - (temp_delta / ideal_temperature)
	if randf() > prob:
		return false
	return true


#To be called when wanting to destroy a crop.
func kill() -> void:
	get_child(0).queue_free() #Delete child (timer).
	var i: int = get_parent().crop_arr.find(self)
	get_parent().crop_arr.remove(i)
	queue_free() #Queue for deletion.


func get_growth_rate(mgr: float) -> void:
	pass


func grow_crop(timer: float, delta: float) -> void:
	#If there are future stages available
	if timer < death_time:
		scale += Vector3.ONE * max_growth_rate * delta
	else:
		if randf() < 0.1:
			reproduce(30, 2)
		else:
			reproduce(30, 1)
	
			
func _physics_process(delta: float) -> void:
	crop_timer += delta
	grow_crop(crop_timer, delta)
	
	
	
	
	
	
	