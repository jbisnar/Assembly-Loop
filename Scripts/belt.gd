extends Node2D
class_name Belt

@onready var areaNode : Area2D = $Area2D
@onready var nextPos : Vector2 = $NextPoint.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("Tick_Move",set_product_tgt_pos)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_product_tgt_pos() -> void:
	nextPos = $NextPoint.global_position
	var overlaps = areaNode.get_overlapping_areas()
	for area in overlaps:
		var possibleProduct = area.get_parent()
		if possibleProduct is Product:
			possibleProduct.targetPos = nextPos
