extends Node2D

class_name PlayerController

@onready var game_manager : Node2D = get_parent().get_node("GameManager")
@onready var sprite : Sprite2D = get_node("Sprite2D")
@onready var jump_sound : AudioStreamPlayer = get_node("JumpSound")
@onready var death_sound : AudioStreamPlayer = get_node("DeathSound")

var y_velocity : float = 0

@export var jump_velocity : float = -750

@export var x_speed : float = 200
@export var gravity : float = 750

@onready var screen_middle : Node2D = get_parent().get_node("ScreenMiddle");
@onready var screen_top : Node2D = get_parent().get_node("ScreenMiddle/ScreenTop");
@onready var screen_bottom : Node2D = get_parent().get_node("ScreenMiddle/ScreenBottom");
@onready var screen_left : Node2D = get_parent().get_node("ScreenMiddle/ScreenLeft");
@onready var screen_right : Node2D = get_parent().get_node("ScreenMiddle/ScreenRight");

var dead : bool = false
var death_sprite = preload("res://Sprites/mac_dead.png")


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# freeze the player if the game hasn't started yet
	if (!game_manager.game_started):
		pass
		
	else:
		
		var x_movement = 0
		
		y_velocity += gravity * delta
		
		# if the player is dead, don't let them move horizontally
		if (!dead):
			# track horizontal movement
			if (Input.is_action_pressed("left")):
				x_movement = -x_speed
				
			if (Input.is_action_pressed("right")):
				x_movement = x_speed
		
		# make our sprite face the direction that we're moving
		if (x_movement != 0):
			if (x_movement > 0):
				sprite.flip_h = false
			else: 
				sprite.flip_h = true
		
		# restrict horizontal movement between the two sides of the screen
		var x_pos = clamp(position.x + x_movement * delta, screen_left.position.x, screen_right.position.x)
		
		# apply x and y movement to our position value
		position = Vector2(x_pos, position.y + y_velocity * delta)
	
func bounce():
	# set our vertical velocity to the jump velocity
	y_velocity = jump_velocity
	
	#play the jump sound - sourced from https://freesound.org/people/MATRIXXX_/sounds/503461/
	jump_sound.play()
	
func _on_area_entered(area):
	if (area.is_in_group("platform") and not dead):
		# only bounce off of a platform if we hit it while falling down
		# also, destroy the platform after we bounce on it
		if (y_velocity >= 0 and game_manager.game_started):
			bounce()
			game_manager.remove_object(area)
	
	elif (area.is_in_group("obstacle") and not dead):
		dead = true
		sprite.texture = death_sprite
		
		# play the death sound - sourced from https://freesound.org/people/leviclaassen/sounds/107788/
		death_sound.play()
		
