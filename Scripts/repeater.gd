extends Receiver
class_name Repeater

var outputSignal : bool
@export var Receivers : Array[Receiver]
@onready var InLightSprite : Sprite2D = $InputLightSprite
@onready var OutLightSprite : Sprite2D = $OutputLightSprite
var pendingWire : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputSignal = false
	outputSignal = false
	pendingWire = false
	EventBus.connect("Tick_Non_Altering", updateOutput)
	EventBus.connect("Tick_Signal_Input", sendSignal)
	connect("InputSignalUpdated", updateInput)
	EventBus.connect("Wire_Receiver_Selected",addReceiver)

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

func updateInput() -> void:
	var newSprite : String
	if InputSignal:
		newSprite = "res://Sprites/Green4x4.png"
	else:
		newSprite = "res://Sprites/Red4x4.png"
	var newTexture = load(newSprite)
	InLightSprite.texture = newTexture

func updateOutput() -> void:
	outputSignal = InputSignal
	var newSprite : String
	if outputSignal:
		newSprite = "res://Sprites/Green4x4.png"
	else:
		newSprite = "res://Sprites/Red4x4.png"
	var newTexture = load(newSprite)
	OutLightSprite.texture = newTexture

func sendSignal() -> void:
	for rec in Receivers:
		rec.InputSignal = outputSignal
		rec.emit_signal("InputSignalUpdated")

func addReceiver(rec):
	if pendingWire && rec is Receiver:
		if rec == self:
			print("Not wiring repeater to self")
			return
		Receivers.append(rec)
		Globals.InteractMode = Globals.InteractionModes.WIRING_SENDER
		rec.InputSender = self

func disconnectReceiver(rec) -> void:
	Receivers.erase(rec)

func disconnectAllReceivers():
	while Receivers.size() > 0:
		Receivers[0].DisconnectWire()

func DisconnectWire() -> void: # Override
	InputSignal = false
	if InputSender != null:
		InputSender.disconnectReceiver(self)
	InputSender = null
	emit_signal("InputSignalUpdated")

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Select"):
		pendingWire = true
		Globals.InteractMode = Globals.InteractionModes.WIRING_RECEIVER
	elif Globals.InteractMode == Globals.InteractionModes.WIRING_RECEIVER && event.is_action_pressed("Select") && InputSender == null:
		EventBus.emit_signal("Wire_Receiver_Selected",self)
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER && event.is_action_pressed("Alt Action"):
		disconnectAllReceivers()
		DisconnectWire()

func AttemptDelete() -> bool:
	if Locked:
		return false
	disconnectAllReceivers()
	DisconnectWire()
	queue_free()
	return true
