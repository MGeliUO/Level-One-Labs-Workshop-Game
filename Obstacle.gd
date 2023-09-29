extends Area2D

@export var fall_speed : float = 150

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# move downwards every frame
	global_position.y += fall_speed * delta
	
	pass
