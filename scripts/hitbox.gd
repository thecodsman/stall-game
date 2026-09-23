class_name HitBox extends Area2D

signal hit(hurt : HurtBox)

@export var data : Dictionary
@export var input : PlayerInput
@export var player : Player
@export var damage : float = 0.05
@export var ownership_damage : float = 0.25
@export var no_direction : bool = false
@export var knockback : Vector2
@export var hit_stun : int = 4 ## in frames
@export_group("hit fx")
@export var use_hit_fx : bool = true
@export var hit_fx_scene : PackedScene
@export_group("")
@export var active : bool = true
@onready var collider : CollisionShape2D = $CollisionShape2D
var can_cancel : bool = false
var ball_damage : float :
	get():
		var value : float
		if Globals.camera.ball != null:
			value = Globals.camera.ball.damage
		else:
			value = 1
		return value


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurtbox : Area2D) -> void:
	if not hurtbox is HurtBox: return
	if not active or not hurtbox.active: return
	if hurtbox.owner == owner: return
	can_cancel = true
	if no_direction:
		var distance : Vector2 = hurtbox.global_position - global_position
		knockback = Vector2(knockback.length(), 0).rotated(distance.angle())
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
	if not hurtbox.hit_fx or not hit_fx_scene: return
	var hit_fx : Node2D = hit_fx_scene.instantiate()
	hit_fx.global_position = hurtbox.owner.global_position
	$"/root/stage/SubViewportContainer/game".add_child(hit_fx)
