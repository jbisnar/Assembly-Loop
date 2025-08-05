extends Receiver
class_name Adder

@export var part : int
@onready var lightSprite : Sprite2D = $LightSprite
@onready var addAreaNode : Area2D = $AddArea2D
@onready var spawnPos : Vector2
@onready var ConfigPopup = $CanvasLayer/ConfigWindow
@export var productScene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("Tick_Adders",add)
	InputSignal = true
	part = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add() -> void:
	var newSprite : String
	if !InputSignal:
		newSprite = "res://Sprites/Red4x4.png"
	else:
		newSprite = "res://Sprites/Green4x4.png"
		var overlaps = addAreaNode.get_overlapping_areas()
		var productsHit = 0
		var beltInFront = false
		for area in overlaps:
			var possibleProduct = area.get_parent()
			if possibleProduct is Product:
				productsHit += 1
				possibleProduct.addPart(part)
			elif possibleProduct is Belt:
				beltInFront = true
		if productsHit == 0 && beltInFront:
			var newProduct = productScene.instantiate()
			get_parent().add_child(newProduct)
			spawnPos = $SpawnPos.global_position
			newProduct.position = spawnPos
			if newProduct is Product:
				newProduct.addPart(part)
				newProduct.targetPos = spawnPos
	var newTexture = load(newSprite)
	lightSprite.texture = newTexture

func _on_material_option_button_item_selected(index: int) -> void:
	match index:
		0:
			part = 1
		1:
			part = 2
		_:
			part = 3

func _on_click_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("Select") && !Globals.PopupLocked && Globals.InteractMode == Globals.InteractionModes.INSPECTION:
		ConfigPopup.visible = true
		Globals.PopupLocked = true
	if Globals.InteractMode == Globals.InteractionModes.WIRING_RECEIVER && event.is_action_pressed("Select") && InputSender == null:
		EventBus.emit_signal("Wire_Receiver_Selected",self)
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Alt Action") && InputSender != null:
		DisconnectWire()

func _on_config_window_close_requested() -> void:
	ConfigPopup.visible = false
	Globals.PopupLocked = false

func AttemptDelete() -> bool:
	if Locked:
		return false
	DisconnectWire()
	EventBus.emit_signal("Machine_Deleted",0)
	queue_free()
	return true
