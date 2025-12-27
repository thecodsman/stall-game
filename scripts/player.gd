class_name Player extends CharacterBody2D

@export_category("movement")
@export var WALK_SPEED      : float = 65.0
@export var RUN_SPEED       : float = 100.0
@export var SUPER_RUN_SPEED : float = 150.0
@export var DASH_SPEED      : float = 200.0
@export var ACCEL           : float = 20.0
@export var AIR_ACCEL       : float = 8.0
@export var AIR_FRICTION    : float = 2.0
@export var AIR_SPEED       : float = 100.0
@export var BASE_GRAVITY    : float = 700.0
@export var FRICTION        : float = 20
@export var COYOTE_TIME     : float = 0.05
@export var MAX_JUMPS       : int   = 2
@export var FAST_FALL_SPEED : float = 150
@export_category("water")
@export var WATER_GRAVITY         : float = 20.0
@export var WATER_ACCEL           : float = 10.0
@export var WATER_FRICTION        : float = 7.0
@export var WATER_SPEED           : float = 100.0
@export var WATER_GROUND_FRICTION : float
@export_subgroup("jumps")
@export var FULL_JUMP_VELOCITY  : float
@export var SUPER_JUMP_VELOCITY : float
@export var HYPER_JUMP_VELOCITY : float
@export var ULTRA_JUMP_VELOCITY : float
@export var SHORT_HOP_VELOCITY  : float
@export var SUPER_HOP_VELOCITY  : float
@export var HYPER_HOP_VELOCITY  : float
@export var ULTRA_HOP_VELOCITY  : float
@export var SHORT_FLIP_VELOCITY : float
@export var BACKFLIP_VELOCITY   : float
@export_category("misc")
@export var player_index     : int = 0
@export var controller_index : int = 0
@export var id               : int = 1
@export_category("dependencies")
@export var input         : PlayerInput        
@export var anim          : AnimationPlayer    
@export var sprite        : Sprite2D           
@export var trail         : TrailFX            
@export var kick_collider : CollisionShape2D   
@export var kick_box      : KickBox            
@export var jump_sfx      : AudioStreamPlayer  
@onready var gravity : float = BASE_GRAVITY
@onready var air_accel : float = AIR_ACCEL
@onready var air_friction : float = AIR_FRICTION
@onready var air_speed : float = AIR_SPEED
var in_water : bool = false
var jumps : int = MAX_JUMPS
var direction : float = 0
var dir_prev_frame : float = 0
var fast_falling : bool = false
var time_scale : float = 1
var stage_size : Vector2 = Vector2(96,96)
var process_state : bool = false
var wall_jump_dir : float = 0
var dashes : int = 1
var on_wall_prev_frame : bool = false
var run_dash_timer : Timer = Timer.new()
