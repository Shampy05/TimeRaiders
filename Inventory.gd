extends CanvasLayer

var Entry = preload("res://InventoryEntry.tscn")

var number_sprites = 4
var entries = []
var complete = false

func _ready():
	for i in range(number_sprites):
		entries.append(Entry.instance())
		add_child(entries[i])
		entries[i].add_entry(i)

func register_parts(parts):
	for part in parts:
		entries[part.part_type-1].total_count += 1
	update_count()

func update_count():
	complete = true
	for entry in entries:
		entry.update_count()
		complete = complete and entry.complete
	$Background.color = Color(0.5 if complete else 1.0, 1.0 if complete else 0.5, 0.5, 0.5)
	$Header.text = "All Parts!" if complete else "Machine Parts"

func _on_MachinePart_part_collected(part_type):
	entries[part_type-1].current_count += 1
	update_count()
