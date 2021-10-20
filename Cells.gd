extends MultiMeshInstance


# Represents a single cell of the cellular automata
class Cell:
	var neighbors = Array()
	var value = 0
	var x = 0
	var y = 0
	
	func _init(_x: int, _y: int):
		self.x = _x
		self.y = _y
	
	# Adds the sum of the values of neighboring cells.
	func get_neighboring():
		var sum = 0
		for other_cell in neighbors:
			sum += other_cell.value
		return sum

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
				cells.append(Cell.new(x, y))
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
				multimesh.set_instance_color(i, Color(255, 255, 255, 0.1))
				i += 1
		return i

	
var previous = null
var used_instances = 0
var l = 0
func _ready():
	print("here")
	var g = Grid.new(30, 30)
	g.populate_empty()
	
	# Glider
	g.get_cell(4, 4).value = 1
	g.get_cell(6, 4).value = 1
	g.get_cell(5, 5).value = 1
	g.get_cell(6, 5).value = 1
	g.get_cell(5, 6).value = 1
	
	
	for e in 30*30:
		g.cells[e].value = min(randi() % 2, randi() % 2)
	
	multimesh.set_instance_count(10000)
	used_instances = g.render_grid(self.multimesh, l, used_instances)
	l += 1	
	previous = g


	
	
	
	pass


func _input(event):
		# Receives key input
	if event is InputEventKey:
		match event.scancode:
			KEY_F:
				var next = previous.next_step()
				used_instances = next.render_grid(self.multimesh, l, used_instances)
				previous = next
				l += 1