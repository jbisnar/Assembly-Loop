extends Node2D

var fadeRate : float = 1
var riseSpeed : float = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	modulate.a -= fadeRate * delta
	position.y -= riseSpeed * delta
