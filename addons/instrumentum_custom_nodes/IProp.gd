tool
extends Spatial

var velocity = Vector3()

func _update_prop(delta):
	pass

func _ready():
	Gamestate.connect("prop_tick", self, "_update_prop")
