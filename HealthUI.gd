extends Control

# warning-ignore-all:return_value_discarded

onready var bloodUIFull = $BloodUIFull
onready var bloodUIEmpty = $BloodUIEmpty

var unit = 15 # Each unit of blood is 15 pixels long
var blood = 4 setget set_blood
var max_blood = 4 setget set_max_blood

func set_blood(value):
	blood = clamp(value,0,max_blood)
	if bloodUIFull != null:
		bloodUIFull.rect_size.x = blood*unit

func set_max_blood(value):
	max_blood = max(value,1)
	self.blood = min(blood,max_blood)
	if bloodUIEmpty != null:
		bloodUIEmpty.rect_size.x = blood*unit

func _ready():
	self.max_blood = PlayerStats.max_health
	PlayerStats.connect("health_changed",self,"set_blood")
	PlayerStats.connect("max_health_changed",self,"set_max_blood")
