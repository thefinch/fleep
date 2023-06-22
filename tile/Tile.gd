extends Node3D

var top
var bottom
var current_side = 'top'
var mouse_over = false

# keep track of how this tile can move
var draggable = true
var being_dragged = false
var original_position = null
var can_rotate = true
var flip_factor = 1

# Called when the node enters the scene tree for the first time.
func _ready():	
	# create the tile sides
#	top = create_tile_side()
#	bottom = create_tile_side()
	top = ['UL', 'R']
	bottom = ['UL', 'R']
	
	print('top', top, 'bottom', bottom)
	
	# show the arrows based on what we made
	show_arrows(top, 'Front')
	show_arrows(bottom, 'Back')

# shows all visible arrows on the given side
func show_arrows(directions, side):
	for direction in directions:
		get_node(side + '/' + direction).visible = true

# generates a random list of arrows for a side
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

# returns which side is currently visible
func get_current_side():
	return current_side

# spin the tile in 3D and rotate the matrixes appropriately
func spin(list):
	rotate_tile(list)

	top = rotate_matrix(top, list)
	bottom = rotate_matrix(bottom, list)

# rotates a tile a certain amount of degrees on the given axis
func rotate_tile(list):
	# don't try to rotate if we're already rotating
	if not can_rotate:
		return 
	can_rotate = false
	
	# create the tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# do all our work at once
	var duration = 0.3
	var radians
	var start_rotation
	var degrees
	for axis in list:
		degrees = list[axis]
		
		# flip rotations if needed
		if axis == 'x' or axis == 'y':
			flip_factor = flip_factor * -1
			current_side = 'top' if current_side == 'bottom' else 'bottom'
		
		# figure out how much to rotate and how long the rotation should last
		match axis:
			'x':
				start_rotation = self.rotation.x
			'y':
				start_rotation = self.rotation.y
			'z':
				degrees = degrees * flip_factor
				start_rotation = self.rotation.z
		radians = start_rotation + deg_to_rad(degrees)
				
		tween.tween_property(self, "rotation:" + axis, radians, duration)

	# allow rotation after this one is done
	await(tween.finished)
	can_rotate = true
	
	print('current side', current_side)

func test():
	var matrix = ['UL', 'R']
	
	var rotated_right = turn(matrix, 'right')
	print('rotate right ', 'works' if rotated_right == ['UR', 'D'] else 'does not work')
	
	var rotated_left = turn(matrix, 'left')
	print('rotate left ', 'works' if rotated_left == ['DL', 'U'] else 'does not work')
	
	var reflect_horizontal = reflect(matrix, 'horizontal')
	print('reflect horizontal ', 'works' if reflect_horizontal == ['UR', 'L'] else 'does not work', reflect_horizontal)
	
	var reflect_vertical = reflect(matrix, 'vertical')
	print('reflect vertical ', 'works' if reflect_vertical == ['DL', 'R'] else 'does not work', reflect_vertical)
	
	var transposed_down_right = transpose(matrix, 'down-right')
	print('transposed_down_right ', 'works' if transposed_down_right == ['U', 'DR'] else 'does not work', transposed_down_right)

func rotate_matrix(matrix, list):
	var degrees
	
	print('matrix before', matrix)
	print('list of moves', list)
	
	# one axis makes for simple moves
#	var axis
#	if list.size() == 1:
#		axis = list.keys()[0]
#		degrees = list[axis]
#
#		if axis == 'x':
#			matrix = reflect(matrix, 'vertical')
#		elif axis == 'y':
#			matrix = reflect(matrix, 'horizontal')
#		elif axis == 'z':
#			if degrees == -90:
#				matrix = turn(matrix, 'right')
#			elif degrees == -90:
#				matrix = turn(matrix, 'left')
		
	for axis in list:
		degrees = list[axis]

		if axis == 'z':
			if degrees == 90:
				matrix = change_matrix(matrix, 'right')
			elif degrees == -90:
				matrix = change_matrix(matrix, 'left')
		elif axis == 'y':
			matrix = change_matrix(matrix, 'horizontal')
		elif axis == 'x':
			matrix = change_matrix(matrix, 'vertical')

#		if abs(degrees) == 90:
#			if axis == 'x':
#				matrix = reflect(matrix, 'right')
#			elif axis == 'y':
#				matrix = turn(matrix, 'left')
#		elif abs(degrees) == 180:
#			if axis == 'x':
#				matrix = reflect(matrix, 'vertical')
#			elif axis == 'y':
#				matrix = reflect(matrix, 'horizontal')
		
	print('matrix after', matrix)
	return matrix
		
#	for axis in list:
#		degrees = list[axis]
		
#	return matrix

func change_matrix(arrows, change):
	var swap = {
		'horizontal': {
			'UL': 'UR',
			'UR': 'UL',
			'L': 'R',
			'R': 'L',
			'DL': 'DR',
			'DR': 'DL',
		},
		'vertical': {
			'UL': 'DL',
			'U': 'D',
			'UR': 'DL',
			'DL': 'UL',
			'D': 'U',
			'DR': 'UR',
		},
		'left': {
			'UR': 'UL',
			'R': 'U',
			'DR': 'UR',
			'D': 'R',
			'DL': 'DR',
			'L': 'D',
			'UL': 'DL',
			'U': 'L',
		},
		'right': {
			'UL': 'UR',
			'U': 'R',
			'UR': 'DR',
			'R': 'D',
			'DR': 'DL',
			'D': 'L',
			'DL': 'UL',
			'L': 'U',
		},
		'down-left': {
			'R': 'D',
			'L': 'U',
			'U': 'L',
			'D': 'R',
			'DL': 'UR',
			'UR': 'DL',
		},
		'up-left': {
			'UL': 'DR',
			'DR': 'UL',
			'L': 'D',
			'D': 'L',
			'R': 'U',
			'U': 'R'
		}
	}
	
	var new_arrows = []
	for arrow in arrows:
		new_arrows.append(
			swap[change][arrow] if arrow in swap[change] else arrow
		)

	return new_arrows

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
	
func turn(arrows, direction):
	var new_arrows = []

	var swap_right = {
		'UL': 'UR',
		'U': 'R',
		'UR': 'DR',
		'R': 'D',
		'DR': 'DL',
		'D': 'L',
		'DL': 'UL',
		'L': 'U',
	}
	var swap_left = {
		'UR': 'UL',
		'R': 'U',
		'DR': 'UR',
		'D': 'R',
		'DL': 'DR',
		'L': 'D',
		'UL': 'DL',
		'U': 'L',
	}

	var swap = swap_right if direction == 'right' else swap_left
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
	
# begin dragging the tile
func pick_up():
	original_position = self.global_position
	being_dragged = true

# moves the tile to wherever the mouse is
func drag(event):	
	# make the top face of the tile always look at the camera
	var distance_from_camera = 7
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * distance_from_camera
	global_transform.origin = to

# send back to original location
func revert_position():
	var duration = 0.2
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", original_position, duration)

# set this tile as being hovered over when the mouse enters its Area3D
func _on_area_3d_mouse_entered():
	mouse_over = true

# set this tile as not being hovered over when the mouse leaves its Area3D
func _on_area_3d_mouse_exited():
	mouse_over = false

# puts the tile in the box
func place_in_box(box):
	var duration = 0.05
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", box.global_position, duration)
