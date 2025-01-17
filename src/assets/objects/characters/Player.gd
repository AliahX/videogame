extends CharacterBody3D

var speed
const WALK_SPEED = 2
const SPRINT_SPEED = 3.5
const JUMP_VEL = 4.5

const ITEM_RAY_LENGTH = 3.0

#view bobbing
const BOB_FREQUENCY = 2.0
const BOB_AMP = 0.07
var bob_time = 0.0

var alive = true
var inventory = {
	"keys": {
		"keys": 0,
		"bronzeKey": false,
		"silverKey": false,
		"goldKey": false
	},
	"items": {
		"shovel": false
	}
}
var stamina = 1
var ray_from = Vector3(0, 0, 0)
var ray_to = Vector3(0, 0, 0)

var save_path = "user://inventory.save"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var head := $Head
@onready var camera := $Head/Camera3D


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		inventory = file.get_var()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion && alive:
			head.rotate_y(-event.relative.x * 0.001)
			camera.rotate_x(-event.relative.y * 0.001)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	ray_from = camera.project_ray_origin(get_viewport().get_mouse_position())
	ray_to = ray_from + camera.project_ray_normal(get_viewport().get_mouse_position()) * ITEM_RAY_LENGTH


func _physics_process(delta):
	# Add the gravity.
	if !is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") && is_on_floor() && alive:
		velocity.y = JUMP_VEL
	
	# Handle sprint.
	if Input.is_action_pressed("sprint") && alive:
		speed = SPRINT_SPEED
		
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if !alive:
		input_dir = Vector2.ZERO
		
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
			
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	bob_time += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(bob_time)
	
	move_and_slide()
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 4294967295, [get_rid()])
	var result = space_state.intersect_ray(query)
	if result != {  }:
		var object = result.collider;
		if Input.is_action_just_pressed("interact"):	
			print(object)
			if "ITEM" in object:
				match object.ITEM:
					"key":
						inventory.keys.keys += 1
					"shovel":
						inventory.shovel = true
				object.picked_up = true
				var file = FileAccess.open(save_path, FileAccess.WRITE)
				file.store_var(inventory)
				
			elif "OBJ" in object:
				match object.OBJ:
					"door":
						object.interact = true
					"ring":
						object.interact = true


func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMP
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMP
	return pos


func _on_monster_player_collide() -> void:
	alive = false
