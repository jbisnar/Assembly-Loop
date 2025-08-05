extends Node

@onready var PlayButton : Button = $CanvasLayer/ColorRect/PlayButton
@onready var PauseButton : Button = $CanvasLayer/ColorRect/PauseButton
@onready var StopButton : Button = $CanvasLayer/ColorRect/StopButton
@onready var NextLevelButton : Button = $CanvasLayer/ColorRect/NextLevelButton
@export var nextLevel : String
@export var ObjectiveArray : Array
@onready var PrimaryScoreLabel : Label = $CanvasLayer/ColorRect/PrimaryScore
@onready var SecondaryScoreLabel : Label = $CanvasLayer/ColorRect/SecondaryScore
@onready var DefectLabel : Label = $CanvasLayer/ColorRect/DefectCount
var defects : int
var struckOut : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("Start_Playing",playFactory)
	EventBus.connect("Product_Packaged",updateScore)
	defects = 0
	struckOut = false
	enableDisablePlayButtons()
	updateScoreLabels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func playFactory() -> void:
	EventBus.emit_signal("Tick_Move")
	await get_tree().create_timer(.5).timeout
	EventBus.emit_signal("Tick_Non_Altering")
	EventBus.emit_signal("Tick_Signal_Input")
	EventBus.emit_signal("Tick_Adders")
	EventBus.emit_signal("Tick_Trash")
	EventBus.emit_signal("Tick_Packagers")
	await get_tree().create_timer(.5).timeout
	if Globals.Playing:
		playFactory()

func _on_play_button_pressed() -> void:
	Globals.Playing = true
	Globals.FactoryStarted = true
	enableDisablePlayButtons()
	EventBus.emit_signal("Start_Playing")

func _on_pause_button_pressed() -> void:
	Globals.Playing = false
	enableDisablePlayButtons()

func _on_stop_button_pressed() -> void:
	Globals.Playing = false
	defects = 0
	struckOut = false
	Globals.FactoryStarted = false
	EventBus.emit_signal("Reset_Factory")
	enableDisablePlayButtons()
	ObjectiveArray[0][1] = 0
	if ObjectiveArray.size() == 2:
		ObjectiveArray[1][1] = 0
	updateScoreLabels()

func enableDisablePlayButtons() -> void:
	PlayButton.disabled = Globals.Playing || struckOut
	PauseButton.disabled = !Globals.Playing

func updateScore(product : Globals.Products) -> void:
	if ObjectiveArray.size() < 1:
		print("What da hell")
		return
	elif product == ObjectiveArray[0][0]:
		ObjectiveArray[0][1] += 1
	elif ObjectiveArray.size() == 2 && product == ObjectiveArray[1][0]:
		ObjectiveArray[1][1] += 1
	else:
		defects += 1
	updateScoreLabels()
	var levelComplete = false
	if ObjectiveArray.size() == 1:
		levelComplete = ObjectiveArray[0][1] >= ObjectiveArray[0][2]
	elif ObjectiveArray.size() == 2:
		levelComplete = ObjectiveArray[0][1] >= ObjectiveArray[0][2] && ObjectiveArray[1][1] >= ObjectiveArray[1][2]
	NextLevelButton.disabled = !levelComplete
	if defects >= 3:
		struckOut = true
		_on_pause_button_pressed()

func updateScoreLabels() -> void:
	PrimaryScoreLabel.text = str(ObjectiveArray[0][1]) + "/" + str(ObjectiveArray[0][2])
	if ObjectiveArray.size() == 2:
		SecondaryScoreLabel.text = str(ObjectiveArray[1][1]) + "/" + str(ObjectiveArray[1][2])
	DefectLabel.text = str(defects) + "/3"

func _on_next_level_button_pressed() -> void:
	_on_stop_button_pressed()
	get_tree().change_scene_to_file(nextLevel)
