class_name HurtBox extends Area2D

signal hurt(hit : HitBox)
@export var apply_knockback : bool = true
@export var active : bool = true
@export var hit_fx : bool = true
@export var knockback_mult : float = 1.0


func _ready() -> void:
	hurt.connect(_on_hurt)


func _on_hurt(hit : HitBox) -> void:
	if not apply_knockback: return
	var knockback : Vector2 = hit.knockback * knockback_mult
	if not knockback: return
	if owner is CharacterBody2D:
		owner.velocity += knockback

