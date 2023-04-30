extends Node

var top
var bottom
var current_side = 'top'
var mouse_over = false

# related to dragging and dropping
var draggable = false
var being_dragged = false
var original_position = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	top = create_tile_side()
	bottom = create_tile_side()	
		
func create_tile_side():
	# set all the possible places an arrow can go
	var possible_directions = [
		'UL', 'U', 'UR',
		'L', 'R',
		'DL', 'D', 'DR',
	]
	
	# set which directions should be removed when a particular direction is added
	var removals = {
		'UL': ['L', 'U'],
		'U': ['UL', 'UR'],
		'UR': ['U', 'R'],
		'L': ['UL', 'DL'],
		'R': ['UR', 'DR'],
		'DL': ['L', 'D'],
		'D': ['DL', 'DR'],
		'DR': ['R', 'D'],
	}
	
	# add an arrow
	var arrows = []
	arrows.append(
		possible_directions[randi() % possible_directions.size()]
	)

	# randomly add a second arrow
	#if randi() % 100 > 50:
	
	# remove impossible adjacent arrows
	for removal in removals[arrows[0]]:
		possible_directions.erase(removal)

	# remove the currently used arrow
	possible_directions.erase(arrows[0])

	# add a new arrow
	arrows.append(
		possible_directions[randi() % possible_directions.size()]
	)

	return arrows

func get_current_side():
	return current_side

func set_current_side(new_side):
	current_side = new_side

func spin(direction):
	match(direction):
		'forward':
			print('spinning forward')
			spin_x(180)
			
		'backward':
			print('spinning backward')
			spin_x(-180)
			
		'clockwise':
			print('spinning clockwise')
			spin_z(90)
			
		'counterclockwise':
			print('spinning clockwise')
			spin_z(-90)
			
func spin_x(degrees):
	var duration = 0.5
	var tween = create_tween().set_parallel(true)
	#var new_rotation = global_transform
	#new_rotation.basis = new_rotation.basis.rotated(Vector3(1, 0, 0), degrees)
#	new_rotation.basis = new_rotation.basis.rotated(Vector3(0, 1, 0), degrees)
	#tween.tween_property(self, "transform", new_rotation, duration)
	
func spin_z(degrees):
	pass

func reflect(arrows, direction):
	var new_arrows = []

	var swap = {
		'UL': 'UR',
		'UR': 'UL',
		'L': 'R',
		'R': 'L',
		'DL': 'DR',
		'DR': 'DL',
	}
	if direction == 'vertical':
		swap = {
			'UL': 'DL',
			'U': 'D',
			'UR': 'DL',
			'DL': 'UL',
			'D': 'U',
			'DR': 'UR',
		}

	for arrow in arrows:
		new_arrows.append(
			swap[arrow] if arrow in swap else arrow
		)

	return new_arrows

func flip_diagonally(mat):
	var n = 3
	var tmp
	for i in range(0, 3):
		for j in range(0, 3 - i):
			tmp = mat[i][j]
			mat[i][j] = mat[(n - 1) - j][(n - 1) - i]
			mat[(n - 1) - j][(n - 1) - i] = tmp
			
	return mat
	
func transpose(arrows, direction):
	var possible = [
		['UL', 'U', 'UR'],
		['L', '', 'R'],
		['DL', 'D', 'DR']
	]

	if direction == 'down-left' or direction == 'up-right':
		arrows = reflect(reflect(arrows, 'vertical'), 'horizontal')

	# build array of arrows that are in the right position for us to rotate them
	var new_possible = []
	var keep
	var row
	var column
	for row_key in len(possible):
		row = possible[row_key]
		for col_key in len(row):
			# see if we need to keep this key
			column = row[col_key]
			keep = false
			for arrow in arrows:
				if column == arrow:
					keep = true

			# remove if necessary
			if not new_possible.has(row_key):
				new_possible.append([])
			if not new_possible[row_key].has(row_key):
				new_possible[row_key].append(
					column if keep else ''
				)

	var flipped = flip_diagonally(new_possible)

	# translate the flipped positions to the new arrows list
	var new_arrows = []
	for row_key in len(flipped):
		row = flipped[row_key]
		for col_key in len(row):
			column = row[col_key]
			if column != '':
				new_arrows.append(possible[row_key][col_key])

	return new_arrows

func _input(event):
	if draggable and mouse_over:
		# check if we need to stop dragging
		var stopped = being_dragged \
			and event is InputEventMouseButton \
			and not event.is_pressed()
		if stopped:
			print('stopping')
			end_drag()
			return
		
		# check if we need to start dragging
		var started = event is InputEventMouseButton \
			and event.is_pressed() \
			and event.button_index == MOUSE_BUTTON_LEFT 
		if started:
			pick_up()
			return
			
		# check if we need to rotate
		var rotate = event is InputEventMouseButton \
			and event.is_pressed() \
			and event.button_index == MOUSE_BUTTON_RIGHT 
		if rotate:
			spin('clockwise')
			return
			
		# check if we need to flip the tile
		var flip = event is InputEventMouseButton \
			and event.is_pressed() \
			and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
		if flip:
			var direction = 'forward' if event.button_index == MOUSE_BUTTON_WHEEL_UP else 'backward'
			spin(direction)
			return
			
		# check if we need to continue dragging
		var continued = event is InputEventMouseMotion and being_dragged
		if continued:
			drag(event)
			return
	
func pick_up():
	original_position = self.translation
	being_dragged = true
	
func drag(event):
	var distance_from_camera = 7
	var camera = get_parent().get_node('Camera')
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * distance_from_camera
	#global_transform.origin = to

func end_drag():	
	# stop allowing this to be dragged around
	being_dragged = false
	#translation.z = original_position.z
	
	# check if this is a valid drop location
	var valid_drop_location = false
	if valid_drop_location:
		# drop here
		pass
	else:
		# send back to original location
		var duration = 0.3
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "translation", original_position, duration)

func _on_Area_mouse_entered():
	mouse_over = true

func _on_Area_mouse_exited():
	mouse_over = false
