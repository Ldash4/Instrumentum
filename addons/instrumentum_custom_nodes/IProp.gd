tool
extends RigidBody

# Constants

const INTERP_RATE = 0.5

# Variables

var prop_name

# Slave variables

slave var slave_translation = Vector3()
#slave var slave_linear_velocity = Vector3()
# Testing not using velocity interpolation
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
			translation = translation.linear_interpolate(slave_translation, INTERP_RATE)
#			linear_velocity = slave_linear_velocity # see slave var declaration
			angular_velocity = slave_angular_velocity
			rotation = rotation.linear_interpolate(slave_rotation, INTERP_RATE)

func _ready():
	Gamestate.connect("prop_tick", self, "_update_prop")