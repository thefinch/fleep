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

# Called when the node enters the scene tree for the first time.
func _ready():	
	# create the tile sides
	top = create_tile_side()
	bottom = create_tile_side()
	
	# show the arrows based on what we made
	show_arrows(top, 'Front')
	show_arrows(bottom, 'Back')
		
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

func get_current_side():
	return current_side

func set_current_side(new_side):
	current_side = new_side

# check if we need to rotate
# if so, do so
func check_rotate(event):
	var keys_and_actions = [
		{
			'key': KEY_KP_9,
			'axis': 'z',
			'degrees': -90
		},
		{
			'key': KEY_KP_7,
			'axis': 'z',
			'degrees': 90
		},
		{
			'key': KEY_KP_8,
			'axis': 'x',
			'degrees': -180
		},
		{
			'key': KEY_KP_2,
			'axis': 'x',
			'degrees': 180
		},
		{
			'key': KEY_KP_4,
			'axis': 'y',
			'degrees': -180
		},
		{
			'key': KEY_KP_6,
			'axis': 'y',
			'degrees': 180
		}
	]
	for set in keys_and_actions:
		if event is InputEventKey  \
			and event.pressed \
			and event.keycode == set.key:
				rotate_tile(set.axis, set.degrees)
var flip_factor = 1

# rotates a tile a certain amount of degrees on the given axis
func rotate_tile(axis, degrees):
	# don't try to rotate if we're already rotating
	if not can_rotate:
		return 
	can_rotate = false
	
	# flip rotations if needed
	match axis:
		'x', 'y':
			flip_factor = flip_factor * -1
	
	# figure out how much to rotate and how long the rotation should last
	var start_rotation
	match axis:
		'x':
			start_rotation = self.rotation.x
		'y':
			start_rotation = self.rotation.y
		'z':
			degrees = degrees * flip_factor
			start_rotation = self.rotation.z
	var radians = start_rotation + deg_to_rad(degrees)
	var duration = 0.3
			
	# make it pretty
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation:" + axis, radians, duration)

	# allow rotation after this one is done
	await(tween.finished)
	can_rotate = true

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

#func _input(event):
#	# only process input if needed
#	if not draggable \
#		or not mouse_over:
#		return
#
#	# check if we need to stop dragging
#	var stopped = being_dragged \
#		and event is InputEventMouseButton \
#		and not event.is_pressed()
#	if stopped:
#		print('stopping drag')
#		end_drag()
#		return
#
#	# check if we need to start dragging
#	var started = event is InputEventMouseButton \
#		and event.is_pressed() \
#		and event.button_index == MOUSE_BUTTON_LEFT 
#	if started:
#		print('picked up')
#		pick_up()
#		return
#
#	# check if we need to rotate
#	var rotate = event is InputEventMouseButton \
#		and event.is_pressed() \
#		and event.button_index == MOUSE_BUTTON_RIGHT 
#	if rotate:
#		print('spinning clockwise')
#		spin('clockwise')
#		return
#
#	# check if we need to flip the tile
#	var flip = event is InputEventMouseButton \
#		and event.is_pressed() \
#		and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN)
#	if flip:
#		var direction = 'forward' if event.button_index == MOUSE_BUTTON_WHEEL_UP else 'backward'
#		print('spinning ' + direction)
#		spin(direction)
#		return
#
#	# check if we need to continue dragging
#	var continued = event is InputEventMouseMotion \
#					and being_dragged
#	if continued:
#		print('dragging')
#		drag(event)
#		return
	
# begin dragging the tile
func pick_up():
	original_position = self.global_position
	being_dragged = true
	
func drag(event):	
	# @todo this part isn't working right now
	# make the top face of the tile always look at the camera
	var distance_from_camera = 7
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * distance_from_camera
	global_transform.origin = to

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
		tween.tween_property(self, "global_position", original_position, duration)

# set this tile as being hovered over when the mouse enters its Area3D
func _on_area_3d_mouse_entered():
	mouse_over = true

# set this tile as not being hovered over when the mouse leaves its Area3D
func _on_area_3d_mouse_exited():
	mouse_over = false
