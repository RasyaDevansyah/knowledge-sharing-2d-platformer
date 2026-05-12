extends Node

enum levelState{
	
	Lose,
	Win,
	Progress
	
}

signal state_changed

var points : int = 0
var totalPoints : int = 0
var currentState : levelState = levelState.Progress


func _physics_process(_delta: float) -> void:
	if points >= totalPoints and points != 0:
		currentState = levelState.Win
		state_changed.emit()


func reset():
	points = 0
	totalPoints = 0
	currentState = levelState.Progress


func lose():
	currentState = levelState.Lose
	state_changed.emit()

	
