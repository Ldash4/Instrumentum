extends KinematicBody

# Constants

const SENSITIVITY = 0.001
const MAX_SPEED = 20
const ACCELERATION = 0.5
const DECELERATION = 0.9
const INTERP_RATE = 0.3
const GRAVITY = -9.8
const UP = Vector3(0, 1, 0)

# Variables

var velocity = Vector3()
var angle = Vector2()
var local = true

# Slave variables

slave var slave_translation = Vector3()
#slave var slave_velocity = Vector3() # This isn't really needed, the translation
# interpolation seems to be good enough

func _input(event):
	if local:
		if event is InputEventMouseMotion:
			angle -= event.relative * SENSITIVITY
			
			angle.y = clamp(angle.y, -PI / 2, PI / 2)
			
			rotation.y = angle.x
			$Camera.rotation.x = angle.y
		elif event is InputEventKey:
			if event.scancode == KEY_H:
				
				IPropManager.request_prop("box", translation + Vector3(0, 3, 0))
			elif event.scancode == KEY_U:
				Gamestate.print_debug(str("spawned props: ", IProp.props.keys()))


func _physics_process(delta):
	var movement = Vector3()
	
	if local:
		var forward = transform.basis.x
		var up = transform.basis.y
		var right = transform.basis.z
		
		var got_input = false
		
		if Input.is_action_pressed("move_forward"):
			movement += forward
			got_input = true
		elif Input.is_action_pressed("move_backward"):
			movement -= forward
			got_input = true
		if Input.is_action_pressed("move_right"):
			movement += right
			got_input = true
		elif Input.is_action_pressed("move_left"):
			movement -= right
			got_input = true
			
		var temp_velocity = velocity
		temp_velocity.y = 0
		
		if got_input:
			movement = movement.normalized()
			temp_velocity = temp_velocity.linear_interpolate(movement * MAX_SPEED, ACCELERATION)
		else:
			temp_velocity = temp_velocity.linear_interpolate(Vector3(), DECELERATION)
		
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
		
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = clamp(velocity.y, -1000, 0)
		
		rset_unreliable("slave_translation", translation)
		rset_unreliable("slave_velocity", velocity)
	else:
		translation = translation.linear_interpolate(slave_translation, INTERP_RATE)
		#velocity = slave_velocity
	
	move_and_slide(velocity, UP)

