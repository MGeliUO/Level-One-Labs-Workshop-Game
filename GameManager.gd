extends Node2D

class_name GameManager

# scene object references
@onready var player : Node2D = get_parent().get_node("Player")
@onready var start_text : RichTextLabel = get_parent().get_node("ScreenMiddle/StartText")
@onready var game_over_text : RichTextLabel = get_parent().get_node("ScreenMiddle/GameOverText")
@onready var score_text : RichTextLabel = get_parent().get_node("ScreenMiddle/ScoreText")

var game_started : bool = false
var game_over : bool = false

@onready var game_over_sound : AudioStreamPlayer = get_node("GameOverSound")

# screen edge references
@onready var screen_middle : Node2D = get_parent().get_node("ScreenMiddle");
@onready var screen_top : Node2D = get_parent().get_node("ScreenMiddle/ScreenTop");
@onready var screen_bottom : Node2D = get_parent().get_node("ScreenMiddle/ScreenBottom");
@onready var screen_left : Node2D = get_parent().get_node("ScreenMiddle/ScreenLeft");
@onready var screen_right : Node2D = get_parent().get_node("ScreenMiddle/ScreenRight");

# platform generation variables
@export var last_generation_y : float = 275
@export var start_generation_gap : float = 30
var generation_gap : float = 50
@export var gen_gap_increase_per_y : float = 0.006
var screen_objects_list : Array[Node2D]

# obstacle variables
@export var min_obstacle_time : float = 7
@export var max_obstacle_time : float = 12

var timer : Timer

@onready var falling_sound : AudioStreamPlayer = get_node("FallingSound")

# looping background variables
@onready var looping_background_1 : Node2D = get_parent().get_node("LoopingBackground1")
@onready var looping_background_2 : Node2D = get_parent().get_node("LoopingBackground2")

@export var background_loop_interval : float = 648
var next_background_loop_y : float

# prefabs
var platform : PackedScene = preload("res://Prefabs/platform.tscn");
var falling_obstacle : PackedScene = preload("res://Prefabs/obstacle.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# set starting platform generation gap
	generation_gap = start_generation_gap
	
	# generate starting platforms once scene tree has loaded in
	generate_platforms.call_deferred()
	
	next_background_loop_y = -background_loop_interval

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# start the game when the player hits the "jump" action key (space bar)
	if (Input.is_action_just_pressed("jump")):
		if (!game_started):
			
			# hide the starting text
			start_text.hide()
			game_started = true
			
			# make the player jump
			player.bounce()
			
			# create the obstacle timer and hook its timeout output up to the obstacle generation method
			timer = Timer.new()
			get_parent().add_child(timer)
			timer.timeout.connect(on_timer_completed)
			timer.set_wait_time(randf_range(min_obstacle_time, max_obstacle_time))
			timer.start()
		
		if (game_over):
			get_tree().change_scene_to_file("res://main.tscn")
	
	
	if (game_started and not game_over):
		if (player.global_position.y < screen_middle.global_position.y):
			
			# update screenMiddle's position to follow the player's highest reached point
			screen_middle.global_position.y = player.global_position.y
			
			# update score text
			score_text.text = "Score: " + str(int(-screen_middle.global_position.y))
			
			# call the platform generation function if the top of the screen passes the last generated platform
			if (screen_top.global_position.y < last_generation_y):
				generate_platforms()
				
			# loop backgrounds
			if (screen_middle.global_position.y < next_background_loop_y):
				
				next_background_loop_y -= background_loop_interval
				
				# bring the bottom-most looping background up to the top
				if (looping_background_1.global_position.y > looping_background_2.global_position.y):
					looping_background_1.global_position.y -= background_loop_interval * 2
				else:
					looping_background_2.global_position.y -= background_loop_interval * 2
			
		if (player.position.y > screen_bottom.global_position.y):
			#when the player falls off the screen, it's game over!
			game_over = true
			game_over_text.show()
			
			# play the game over sound - sourced from https://freesound.org/people/Fupicat/sounds/475347/
			game_over_sound.play()
			
			
		
		# use a separate array to keep track of objects that should be destroyed
		# otherwise, removing objects from an array WHILE iterating through it with
		# a for each loop could lead to some problems
		var to_destroy : Array[Node2D]
		
		# loop through screen objects list and delete objects that are off the bottom of the screen
		# this keeps the game from slowing down as objects accumulate below the screen
		for p in screen_objects_list:
			if (p.global_position.y > screen_bottom.global_position.y + 100):
				to_destroy.push_front(p)
				
		for p in to_destroy:
			remove_object(p)
	pass
	
func remove_object(object):
	# remove a platform from the platform list, then destroy it
	screen_objects_list.erase(object)
	object.queue_free()
	

func on_timer_completed():
	
	#spawn an obstacle
	var o : Node2D = falling_obstacle.instantiate()
	
	# play the obstacle generation sound - sourced from https://freesound.org/people/MATRIXXX_/sounds/415990/
	falling_sound.play()
	
	# add the obstacle to the scene parent node
	get_parent().add_child(o)
	
	o.position = Vector2(randf_range(screen_left.global_position.x, screen_right.global_position.x), screen_top.global_position.y - 200)
	screen_objects_list.push_front(o)
	
	# reset the timer
	timer.set_wait_time(randf_range(min_obstacle_time, max_obstacle_time))
	timer.start()



func generate_platforms():

	# until we reach the top of the screen
	while (last_generation_y >= screen_top.global_position.y):
		
		# move one generation step upwards
		last_generation_y -= generation_gap
		
		# increase the generation gap as we get higher up
		generation_gap = start_generation_gap + gen_gap_increase_per_y * -last_generation_y
		
		# instantiate a platform
		var p = platform.instantiate()

		# add the platform to the scene parent node
		get_parent().add_child(p)
		
		#set the platform's position
		p.position = Vector2(randf_range(screen_left.position.x, screen_right.position.x), last_generation_y)
		
		# add the platform to the platforms list
		screen_objects_list.push_front(p)


	
	
