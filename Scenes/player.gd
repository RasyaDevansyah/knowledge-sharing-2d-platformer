extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

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
