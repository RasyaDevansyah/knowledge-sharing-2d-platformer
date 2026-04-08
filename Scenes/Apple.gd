extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_body_entered(_body: Node2D) -> void:
	animated_sprite_2d.play("collected")
	GlobalPoints.points += 1
	
	set_deferred("monitoring", false)



func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
	
