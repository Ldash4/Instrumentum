tool
extends RigidBody

# Constants

# Variables

var prop_name

# Slave variables

slave var slave_translation = Vector3()
slave var slave_linear_velocity = Vector3()
slave var slave_angular_velocity = Vector3()
slave var slave_rotation = Vector3()

# Glue

func _update_prop():
	if not sleeping:
		if get_tree().is_network_server():
			rset_unreliable("slave_translation", translation)
			rset_unreliable("slave_linear_velocity", linear_velocity)
			rset_unreliable("slave_angular_velocity", angular_velocity)
			rset_unreliable("slave_rotation", rotation)
		else:
			translation = slave_translation
			linear_velocity = slave_linear_velocity
			angular_velocity = slave_angular_velocity
			rotation = slave_rotation

func _ready():
	Gamestate.connect("prop_tick", self, "_update_prop")