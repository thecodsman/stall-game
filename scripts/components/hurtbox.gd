class_name HurtBox extends Area2D

signal hurt(hit : HitBox)
@export var apply_knockback : bool = true
@export var active : bool = true :
	set(_active):
		active = _active
		if not collider: return
		collider.set_deferred("disabled", !active)
@export var hit_fx : bool = true
@export var knockback_mult : float = 1.0
@onready var collider : CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hurt.connect(_on_hurt)


func _on_hurt(hit : HitBox) -> void:
	if not apply_knockback: return
	var knockback : Vector2 = hit.knockback * knockback_mult
	if not knockback: return
	if owner is CharacterBody2D:
		owner.velocity += knockback

