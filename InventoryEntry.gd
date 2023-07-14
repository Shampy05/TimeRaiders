extends CanvasLayer

var current_count = 0
var total_count = 0
var complete = false

func add_entry(index):
	offset = Vector2(0, 32+32*index)
	$Sprite.set_type(index, true)

func update_count():
	$Count.text = str(current_count)+" / "+str(total_count)+" "
	complete = current_count == total_count
	$Background.color = Color(0.5 if complete else 1.0, 1.0 if complete else 0.5, 0.5, 0.5)
