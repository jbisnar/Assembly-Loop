extends Receiver
class_name Trasher

@onready var areaNode : Area2D = $Area2D
@onready var lightSprite : Sprite2D = $LightSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("Tick_Trash",trash)
	InputSignal = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func trash() -> void:
	var newSprite : String
	if !InputSignal:
		newSprite = "res://Sprites/Red2x2.png"
	else:
		newSprite = "res://Sprites/Green2x2.png"
		var overlaps = areaNode.get_overlapping_areas()
		for area in overlaps:
			var possibleProduct = area.get_parent()
			if possibleProduct is Product:
				possibleProduct.targetPos = position
				possibleProduct.trash()
	var newTexture = load(newSprite)
	lightSprite.texture = newTexture

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Globals.InteractMode == Globals.InteractionModes.WIRING_RECEIVER && event.is_action_pressed("Select") && InputSender == null:
		EventBus.emit_signal("Wire_Receiver_Selected",self)
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Alt Action") && InputSender != null:
		DisconnectWire()

func AttemptDelete() -> bool:
	if Locked:
		return false
	DisconnectWire()
	EventBus.emit_signal("Machine_Deleted",1)
	queue_free()
	return true
