@tool
extends StaticBody3D

const OBJ = "door"
var interact = false

@export var locked: bool
@export var open: bool = false
var visual_state = "open" if open else "close"


func _physics_process(_delta):
	$Lock.visible = locked
	if !Engine.is_editor_hint():
		var player = get_parent_node_3d().get_parent_node_3d().player
		var monster = get_parent_node_3d().get_parent_node_3d().monster
		var playerPos = player.position
		var monsterPos = monster.position
		
		if interact:
			interact = false
			if !locked:
				if open:
					if !monsterPos.distance_to(global_position) < 1.4:
						open = false
						$AnimationPlayer.play("close")
				else:
					$AnimationPlayer.play("open")
					open = true
			else:
				if player.inventory.keys.keys > 0:
					locked = false
		
		if monsterPos.distance_to(global_position) < 1.4 && !open && !locked:
			monster.time = 3
			open = true
			$AnimationPlayer.play("open")
	else:
		if locked && open:
			open = 0
			if visual_state == "open":
				$AnimationPlayer.current_animation = "close"
			
		if open && visual_state == "close":
			$AnimationPlayer.current_animation = "open"
		elif !open && visual_state == "open":
			$AnimationPlayer.current_animation = "close"


func _on_animation_player_animation_finished(anim_name: StringName):
	visual_state = anim_name
