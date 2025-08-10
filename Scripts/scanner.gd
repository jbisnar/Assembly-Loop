extends Machine
class_name Scanner

@onready var areaNode : Area2D = $ScanArea2D
@onready var lightSprite : Sprite2D = $LightSprite
@onready var ConfigPopup = $CanvasLayer/ConfigWindow
@onready var MatchUI = $CanvasLayer/ConfigWindow/MatchOptions
@onready var CompareUI = $CanvasLayer/ConfigWindow/CompareOptions

var outputSignal : bool
@export var Receivers : Array[Receiver]
var pendingWire : bool
enum Scanner_Modes {MATCH, COMPARE}
var mode : Scanner_Modes
var matchProduct : Globals.Products
var comparePart : int
enum Compare_Operators {EQUALS, GREATER, LESS}
var compareOperator : Compare_Operators
var compareQuantity : int
var outputSignalOnConditionTrue : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("Tick_Non_Altering", updateOutput)
	EventBus.connect("Tick_Signal_Input", sendSignal)
	EventBus.connect("Wire_Receiver_Selected",addReceiver)
	mode = Scanner_Modes.MATCH
	matchProduct = Globals.Products.EMPTY
	comparePart = 1
	compareOperator = Compare_Operators.EQUALS
	compareQuantity = 0
	outputSignalOnConditionTrue = true
	outputSignal = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Globals.InteractMode != Globals.InteractionModes.WIRING_RECEIVER:
		pendingWire = false
	queue_redraw()

func _draw() -> void:
	for rec in Receivers:
		draw_dashed_line(Vector2(0,0),(rec.position - position).rotated(-rotation),Color.ORANGE, 3, 9)
	if pendingWire:
		draw_dashed_line(Vector2(0,0), get_local_mouse_position(),Color.ORANGE, 3, 9)

func updateOutput() -> void:
	var overlaps = areaNode.get_overlapping_areas()
	var scannedProduct : Product
	var conditionTrue
	for area in overlaps:
		var possibleProduct = area.get_parent()
		if possibleProduct is Product:
			scannedProduct = possibleProduct
	if mode == Scanner_Modes.MATCH:
		if scannedProduct == null:
			conditionTrue = (matchProduct == Globals.Products.EMPTY)
		else:
			conditionTrue = (scannedProduct.current_Product == matchProduct)
	else:
		var effectiveMetalCount : int
		var effectiveWheelCount : int
		var effectiveEngineCount : int
		if scannedProduct == null:
			effectiveMetalCount = 0
			effectiveWheelCount = 0
			effectiveEngineCount = 0
		else:
			effectiveMetalCount = scannedProduct.metalCount
			effectiveWheelCount = scannedProduct.wheelCount
			effectiveEngineCount = scannedProduct.engineCount
		var partCount : int
		match comparePart:
			1:
				partCount = effectiveMetalCount
			2:
				partCount = effectiveWheelCount
			_:
				partCount = effectiveEngineCount
		match compareOperator:
			Compare_Operators.EQUALS:
				conditionTrue = (partCount == compareQuantity)
			Compare_Operators.GREATER:
				conditionTrue = (partCount > compareQuantity)
			_:
				conditionTrue = (partCount < compareQuantity)
	if conditionTrue:
		outputSignal = outputSignalOnConditionTrue
	else:
		outputSignal = !outputSignalOnConditionTrue
	var newSprite : String
	if outputSignal:
		newSprite = "res://Sprites/DetectorBeamT.png"
	else:
		newSprite = "res://Sprites/DetectorBeamF.png"
	var newTexture = load(newSprite)
	lightSprite.texture = newTexture

func sendSignal() -> void:
	for rec in Receivers:
		rec.InputSignal = outputSignal
		rec.emit_signal("InputSignalUpdated")

func addReceiver(rec):
	if pendingWire && rec is Receiver:
		Receivers.append(rec)
		Globals.InteractMode = Globals.InteractionModes.WIRING_SENDER
		rec.InputSender = self

func disconnectReceiver(rec) -> void:
	Receivers.erase(rec)

func disconnectAllReceivers():
	while Receivers.size() > 0:
		Receivers[0].DisconnectWire()

func _on_is_contains_option_button_item_selected(index: int) -> void:
	match index:
		0: # is
			mode = Scanner_Modes.MATCH
			MatchUI.visible = true
			CompareUI.visible = false
		_: # contains
			mode = Scanner_Modes.COMPARE
			MatchUI.visible = false
			CompareUI.visible = true

func _on_product_option_button_item_selected(index: int) -> void:
	match index:
		1:
			matchProduct = Globals.Products.METAL
		2:
			matchProduct = Globals.Products.WHEEL
		3:
			matchProduct = Globals.Products.ENGINE
		4:
			matchProduct = Globals.Products.UNICYCLE
		5:
			matchProduct = Globals.Products.BICYCLE
		6:
			matchProduct = Globals.Products.TRICYCLE
		7:
			matchProduct = Globals.Products.MOTORCYCLE
		8:
			matchProduct = Globals.Products.CAR
		9:
			matchProduct = Globals.Products.SNOWMOBILE
		10:
			matchProduct = Globals.Products.SCRAP
		_:
			matchProduct = Globals.Products.ABOMINATION

func _on_material_option_button_item_selected(index: int) -> void:
	match index:
		0:
			comparePart = 1
		1:
			comparePart = 2
		_:
			comparePart = 3

func _on_operator_option_button_item_selected(index: int) -> void:
	match index:
		0:
			compareOperator = Compare_Operators.EQUALS
		1:
			compareOperator = Compare_Operators.GREATER
		_:
			compareOperator = Compare_Operators.LESS

func _on_spin_box_value_changed(value: float) -> void:
	compareQuantity = int(value)

func _on_output_signal_option_button_item_selected(index: int) -> void:
	match index:
		0:
			outputSignalOnConditionTrue = true
		_:
			outputSignalOnConditionTrue = false

func _on_click_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("Select") && !Globals.PopupLocked && Globals.InteractMode == Globals.InteractionModes.INSPECTION:
		ConfigPopup.visible = true
		Globals.PopupLocked = true
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Select"):
		pendingWire = true
		Globals.InteractMode = Globals.InteractionModes.WIRING_RECEIVER
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Alt Action"):
		disconnectAllReceivers()

func _on_config_window_close_requested() -> void:
	ConfigPopup.visible = false
	Globals.PopupLocked = false

func AttemptDelete() -> bool:
	if Locked:
		return false
	disconnectAllReceivers()
	queue_free()
	return true
