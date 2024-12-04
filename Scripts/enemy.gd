extends CharacterBody3D

#@export var player_path : NodePath
@onready var player = get_node_or_null(player_path)
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

var player_path = "/root/World/Map/NavigationRegion3D/Player"
var state_mchn
const SPEED = 4.0
const ATTACK_RANGE = 2.5
var health = 6

func _ready():
	player = get_node(player_path)
	state_mchn = anim_tree.get("parameters/playback")

func _process(delta):
	if not player:
		return  # Выходим, если Player не найден
	
	velocity = Vector3.ZERO
	match state_mchn.get_current_node():
		"Running":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			
	
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	anim_tree.get("parameters/playback")
	
	move_and_slide()
	
func _target_in_range():
	if anim_tree.get("parameters/conditions/attack"):
		return global_position.distance_to(player.global_position) < 2 * ATTACK_RANGE
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func _hit_finished():
	if (global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0):
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)


func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	if health <= 0:
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(4.0).timeout
		queue_free()
