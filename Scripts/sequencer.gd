extends Machine
class_name Sequencer

@onready var lightSprite : Sprite2D = $LightSprite
@onready var ConfigPopup = $CanvasLayer/ConfigWindow
@onready var SequenceParent = $CanvasLayer/ConfigWindow/Sequence
@onready var AddGoButton = $CanvasLayer/ConfigWindow/AddGoButton
@onready var AddStopButton = $CanvasLayer/ConfigWindow/AddStopButton
@onready var DeleteLastButton = $CanvasLayer/ConfigWindow/DeleteButton

var outputSignal : bool
@export var Receivers : Array[Receiver]
var pendingWire : bool
var sequenceIndex : int
var maxSequenceLength : int = 8
var SignalSequence : Array[bool]

var stepColorDefault = Color(46.0/255,46.0/255,46.0/255)
var stepColorHighlight = Color(48.0/255,119.0/255,192.0/255)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sequenceIndex = -1
	EventBus.connect("Tick_Non_Altering", advanceSequence)
	EventBus.connect("Tick_Signal_Input", sendSignal)
	EventBus.connect("Wire_Receiver_Selected", addReceiver)
	EventBus.connect("Start_Playing", enableDisableButtons)
	EventBus.connect("Reset_Factory", reset)
	outputSignal = false
	enableDisableButtons()

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

func advanceSequence() -> void:
	sequenceIndex += 1
	if SignalSequence.size() == 0:
		outputSignal = false
		sequenceIndex = 0
	elif sequenceIndex >= SignalSequence.size():
		sequenceIndex = sequenceIndex % SignalSequence.size()
	if SignalSequence.size() > 0:
		outputSignal = SignalSequence[sequenceIndex]
	var newSprite : String
	if outputSignal:
		newSprite = "res://Sprites/Green4x4.png"
	else:
		newSprite = "res://Sprites/Red4x4.png"
	var newTexture = load(newSprite)
	lightSprite.texture = newTexture
	updateSequenceHighlight()

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

func updateSequenceVisual() -> void:
	var seqLength = SignalSequence.size()
	for i in 8:
		if i < seqLength:
			SequenceParent.get_child(i).visible = true
			var stepLabel : Label = SequenceParent.get_child(i).get_child(0)
			if SignalSequence[i]:
				stepLabel.text = "Go"
			else:
				stepLabel.text = "Stop"
		else:
			SequenceParent.get_child(i).visible = false

func updateSequenceHighlight() -> void:
	for i in SignalSequence.size():
		var stepPanel : Panel = SequenceParent.get_child(i)
		if i == sequenceIndex:
			var highlightedBox : StyleBoxFlat = stepPanel.get_theme_stylebox("panel").duplicate()
			highlightedBox.bg_color = stepColorHighlight
			stepPanel.add_theme_stylebox_override("panel",highlightedBox)
		else:
			var defaultBox : StyleBoxFlat = stepPanel.get_theme_stylebox("panel").duplicate()
			defaultBox.bg_color = stepColorDefault
			stepPanel.add_theme_stylebox_override("panel",defaultBox)

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

func _add_sequence_step(newSignal : bool) -> void:
	if SignalSequence.size() < maxSequenceLength:
		SignalSequence.append(newSignal)
	enableDisableButtons()
	updateSequenceVisual()

func _delete_last_step() -> void:
	SignalSequence.pop_back()
	enableDisableButtons()
	updateSequenceVisual()

func enableDisableButtons() -> void:
	# Check if we're playing, then lock all buttons
	if Locked:
		AddGoButton.disabled = true
		AddStopButton.disabled = true
		DeleteLastButton.disabled = true
	elif Globals.FactoryStarted:
		AddGoButton.disabled = true
		AddStopButton.disabled = true
		DeleteLastButton.disabled = true
	elif SignalSequence.size() == 0:
		AddGoButton.disabled = false
		AddStopButton.disabled = false
		DeleteLastButton.disabled = true
	elif SignalSequence.size() == maxSequenceLength:
		AddGoButton.disabled = true
		AddStopButton.disabled = true
		DeleteLastButton.disabled = false
	else:
		AddGoButton.disabled = false
		AddStopButton.disabled = false
		DeleteLastButton.disabled = false

func reset() -> void:
	sequenceIndex = -1
	outputSignal = false
	updateSequenceVisual()
	enableDisableButtons()

func AttemptDelete() -> bool:
	if Locked:
		return false
	disconnectAllReceivers()
	queue_free()
	return true
