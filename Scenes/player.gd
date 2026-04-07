extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -350.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
	if is_on_floor():
		if direction > 0: #jika positif
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play("run")
		elif direction < 0: #jika negatif
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
	else:
		if velocity.y > 0: # jika positif
			animated_sprite_2d.play("fall")
		elif velocity.y < 0 :#jika negatif
			animated_sprite_2d.play("jump")
		

	move_and_slide()
	



#func _ready() -> void:
	#print("Hello World!")
	#
	#var nomor : int = 6
	#var kalimat : String = "welcome to Apple Academy cohort ke "
	#var boolean : bool = true
	#
	#
	#print(kalimat, nomor, boolean)
	#
	#if nomor == 9:
		#print("The best cohort")
	#else:
		#print("One of the best cohort")
	#
	#self.position = Vector2(100, 0)
	#self.position = Vector2(-100, 0)
	#self.position = Vector2(0, 100)
	#self.position = Vector2(0, -100)
	#
#func _physics_process(_delta: float) -> void:
	#print("Hellooooo")
