extends MultiMeshInstance


# Represents a single cell of the cellular automata
class Cell:
	var neighbors = Array()
	var value = 0
	var x = 0
	var y = 0
	var hue = 0
	var saturation = 0
	var cvalue = 0
	
	func _init(_x: int, _y: int):
		self.x = _x
		self.y = _y
	
	# Adds the sum of the values of neighboring cells.
	func get_neighboring():
		var sum = 0
		for other_cell in neighbors:
			sum += other_cell.value
		return sum
	
	# Sets the color based on another cell's color calculation
	func set_color(other):
		var hue_sin_sum = 0
		var hue_cos_sum = 0
		var saturation_sum = 0
		var cvalue_sum = 0
		var n = 0
		
		for other_cell in other.neighbors:
			if other_cell.value == 1:
				hue_sin_sum += sin(other_cell.hue * 2 * PI)
				hue_cos_sum += cos(other_cell.hue * 2 * PI)
				saturation_sum += other_cell.saturation
				cvalue_sum += other_cell.cvalue
				n += 1
				
		if n == 0:
			return 0
		
		hue = atan2(hue_sin_sum/n, hue_cos_sum/n)/(PI * 2)
		saturation = saturation_sum/n
		cvalue = cvalue_sum/n

			

class Grid:
	var cells = Array()
	var _width = 0
	var _height = 0
	var _size = 0
	var _null_cell = Cell.new(0, 0)
	
	func _init(width: int, height: int):
		_width = width
		_height= height
		_size = width * height
		

	# Create the grid's adjacency map
	func set_adjacency():
		for y in _height:
			for x in _width:
				var this_cell = get_cell(x, y)
				this_cell.neighbors = [
					get_cell(x - 1, y - 1), get_cell(x, y - 1), get_cell(x + 1, y - 1),
					get_cell(x - 1, y),							get_cell(x + 1, y),
					get_cell(x - 1, y + 1), get_cell(x, y + 1), get_cell(x + 1, y + 1)
				]		


	# Populate the grid with empty cells
	func populate_empty():
		# Populate the grid
		for y in _width:
			for x in _height:
				var this_cell = Cell.new(x, y)
				this_cell.hue = rand_range(0, 1)
				this_cell.saturation = rand_range(0.6, 1)
				this_cell.cvalue = rand_range(0.4, 1)
				cells.append(this_cell)
		set_adjacency()


	# Returns the cells at a specific (x, y) coordinate
	func get_cell(x: int, y: int) -> Cell:
		# Check out of bounds
		if x < 0 || x >= self._width || y < 0 || y >= self._height:
			return _null_cell
		return cells[x + y*self._width]
	
	
	# Debug function for printing the values of the grid
	func print_grid(info):
		if info == "n":
			for y in _height:
				var s = ""
				for x in _width:
					s += str(get_cell(x, y).get_neighboring())
				print(s)
		else:
			for y in _height:
				var s = ""
				for x in _width:
					s += str(get_cell(x, y).value)
				print(s)
	
	
	# One step in the cellular automata
	func next_step():
		var new_cells = Array()
		
		for y in _height:
			for x in _width:
				var this_cell = get_cell(x, y)
				var this_value = this_cell.get_neighboring()
				var new_cell = Cell.new(x, y) 
				
				if this_cell.value == 0:
					new_cell.value = int(this_value == 3)
				elif this_cell.value == 1:
					new_cell.value = int(this_value == 2 || this_value == 3)
				
				new_cell.set_color(this_cell)
				new_cells.append(new_cell)
		
		var new_grid = Grid.new(_width, _height)
		new_grid.cells = new_cells
		new_grid.set_adjacency()
		return new_grid
	
	
	func render_grid(multimesh, depth, start) -> int:
		var i = start
		for c in self.cells:
			if c.value == 1:
				multimesh.set_instance_transform(i, Transform(Basis(), Vector3(c.x, depth, c.y)))
				multimesh.set_instance_color(i, Color.from_hsv(c.hue, c.saturation, c.cvalue, 0.2))
				i += 1
		return i

	
var previous = null
var used_instances = 0
var l = 0
var max_instances = 1
var MAX_MAX = 200000
func _ready():
	print("here")
	var s = 100
	var g = Grid.new(s, s)
	g.populate_empty()
	
	# Glider
	g.get_cell(4, 4).value = 1
	g.get_cell(6, 4).value = 1
	g.get_cell(5, 5).value = 1
	g.get_cell(6, 5).value = 1
	g.get_cell(5, 6).value = 1
	
	
	for e in s*s:
		g.cells[e].value = max((randi() % 6) - 4, 0)
	
	max_instances = MAX_MAX - (s*s)
	multimesh.set_instance_count(MAX_MAX)
	used_instances = g.render_grid(self.multimesh, l, used_instances)
	l += 1	
	previous = g


	
	
	
	pass

func _process(delta):
	
	if used_instances < max_instances:
		var next = previous.next_step()
		used_instances = next.render_grid(self.multimesh, l, used_instances)
		previous = next
		l += 1		

func _input(event):
		# Receives key input
	if event is InputEventKey:
		match event.scancode:
			KEY_F:
				if event.is_pressed() and not event.is_echo():
					var next = previous.next_step()
					used_instances = next.render_grid(self.multimesh, l, used_instances)
					previous = next
					l += 1
