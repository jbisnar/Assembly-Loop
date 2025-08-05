extends Node2D

var tileWidth = 15
var tileHeight = 9
var tileSize = 50
var tileOccupiedData = [[]]
var hoverTile
@onready var GenTileMap : TileMapLayer = $GenerationTileMap
@onready var HiLiteTileMap : TileMapLayer = $HighlightTileMap
@onready var PlacementGhost : Node2D = $PlacementGhost
@onready var DeletionGhost : Node2D = $DeletionGhost

@export var StraightBeltScene : PackedScene
@export var CWBeltScene : PackedScene
@export var CCWBeltScene : PackedScene
@export var AssemblerScene : PackedScene
@export var TrashScene : PackedScene
@export var PackagerScene : PackedScene
@export var ScannerScene : PackedScene
@export var SequencerScene : PackedScene
@export var RepeaterScene : PackedScene

enum Machines {ASSEMBLER, TRASHER, PACKAGER, SCANNER, SEQUENCER, REPEATER}
var placingMachine : Machines
var placingMachineRotatable : bool
var validPlacement : bool
var validRotation : bool
@export var AssemblerInventory : int
@export var TrasherInventory : int
@export var PackagerInventory : int
@export var ScannerInventory : int
@export var SequencerInventory : int
@export var RepeaterInventory : int
@export var AssemblerButton : Button
@export var TrasherButton : Button
@export var PackagerButton : Button
@export var ScannerButton : Button
@export var SequencerButton : Button
@export var RepeaterButton : Button
@export var WireButton : Button
@export var DeleteButton : Button
@export var InspectionButton : Button
@onready var HelpText : Label = $CanvasLayer/Toolbar/ControlHintBar/HintText

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.InteractMode = Globals.InteractionModes.INSPECTION
	setPlacingMachine(Machines.SCANNER)
	for x in tileWidth:
		tileOccupiedData.append([])
		for y in tileHeight:
			tileOccupiedData[x].append(null)
	call_deferred("spawnBelts")
	updatePlacementButtons()
	EventBus.connect("Start_Playing",updatePlacementButtons)
	EventBus.connect("Reset_Factory",updatePlacementButtons)

func spawnBelts() -> void:
	for x in tileWidth:
		for y in tileHeight:
			var curCoord = Vector2i(x,y)
			var tileKey = GenTileMap.get_cell_atlas_coords(curCoord)
			if tileKey.x in [1,2,3]:
				var newBelt
				if tileKey.x == 1: # Straight belt
					newBelt = StraightBeltScene.instantiate()
				elif tileKey.x == 2: # CW
					newBelt = CWBeltScene.instantiate()
				elif tileKey.x ==3: # CCW
					newBelt = CCWBeltScene.instantiate()
				get_parent().add_child(newBelt)
				newBelt.position = GenTileMap.map_to_local(curCoord)
				newBelt.rotation_degrees = tileKey.y * 90
				tileOccupiedData[x][y] = newBelt
			else:
				tileOccupiedData[x][y] = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hoverTile = GenTileMap.local_to_map(get_global_mouse_position())
	if Globals.InteractMode == Globals.InteractionModes.PLACEMENT:
		PlacementGhost.visible = true
	else:
		PlacementGhost.visible = false
	PlacementGhost.position = GenTileMap.map_to_local(hoverTile)
	validPlacement = isMachinePlacementValid()
	validRotation = isMachineRotationValid()
	if validPlacement || validRotation:
		PlacementGhost.modulate.g = 1
		PlacementGhost.modulate.b = 1
	else: 
		PlacementGhost.modulate.g = 0
		PlacementGhost.modulate.b = 0
	if Globals.InteractMode == Globals.InteractionModes.DELETION:
		DeletionGhost.visible = true
	else:
		DeletionGhost.visible = false
	DeletionGhost.position = GenTileMap.map_to_local(hoverTile)
	HiLiteTileMap.clear()
	if Globals.InteractMode == Globals.InteractionModes.WIRING_SENDER:
		highlightWireSenders()
		HelpText.text = "Click on a machine to send an output signal. Right-click to disconnect a machine."
	elif Globals.InteractMode == Globals.InteractionModes.WIRING_RECEIVER:
		highlightWireReceivers()
		HelpText.text = "Click on a machine to receive the output signal."
	elif Globals.InteractMode == Globals.InteractionModes.PLACEMENT:
		HelpText.text = "Click to place a machine. Press R to rotate. Right-click to cancel."
	elif Globals.InteractMode == Globals.InteractionModes.DELETION:
		HelpText.text = "Click on a machine to delete it. Right-click to cancel."
	elif Globals.InteractMode == Globals.InteractionModes.INSPECTION:
		highlightConfigurableMachines()
		HelpText.text = "Click on a machine to configure its settings."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Select"):
		if Globals.InteractMode == Globals.InteractionModes.PLACEMENT:
			if validPlacement:
				placeMachine()
			elif validRotation:
				rotateMachine()
		if Globals.InteractMode == Globals.InteractionModes.DELETION:
			if hoverTileInBounds():
				var occupyingMachine = tileOccupiedData[hoverTile.x][hoverTile.y]
				deleteMachine(occupyingMachine)
	if event.is_action_pressed("Alt Action"):
		if Globals.InteractMode == Globals.InteractionModes.PLACEMENT:
			Globals.InteractMode = Globals.InteractionModes.INSPECTION
		if Globals.InteractMode == Globals.InteractionModes.WIRING_RECEIVER:
			Globals.InteractMode = Globals.InteractionModes.WIRING_SENDER
		if Globals.InteractMode == Globals.InteractionModes.DELETION:
			Globals.InteractMode = Globals.InteractionModes.INSPECTION
	if event.is_action_pressed("Rotate"):
		if Globals.InteractMode == Globals.InteractionModes.PLACEMENT && placingMachineRotatable:
			PlacementGhost.rotation_degrees += 90

func setPlacingMachine(machine: Machines) -> void:
	placingMachine = machine
	for c in PlacementGhost.get_children():
		c.visible = false
	match machine:
		Machines.ASSEMBLER:
			PlacementGhost.get_child(0).visible = true
			placingMachineRotatable = true
		Machines.TRASHER:
			PlacementGhost.get_child(1).visible = true
			placingMachineRotatable = true
		Machines.PACKAGER:
			PlacementGhost.get_child(2).visible = true
			placingMachineRotatable = true
		Machines.SCANNER:
			PlacementGhost.get_child(3).visible = true
			placingMachineRotatable = true
		Machines.SEQUENCER:
			PlacementGhost.get_child(4).visible = true
			placingMachineRotatable = false
		Machines.REPEATER:
			PlacementGhost.get_child(5).visible = true
			placingMachineRotatable = false
		_:
			pass
	PlacementGhost.rotation = 0

func isMachinePlacementValid() -> bool:
	if !hoverTileInBounds():
		return false
	var occupyingMachine = tileOccupiedData[hoverTile.x][hoverTile.y]
	if occupyingMachine == null:
		return true
	else:
		return false

func isMachineRotationValid() -> bool:
	if !hoverTileInBounds():
		return false
	var occupyingMachine
	occupyingMachine = tileOccupiedData[hoverTile.x][hoverTile.y]
	if occupyingMachine == null || occupyingMachine is not Machine:
		return false
	if occupyingMachine.Locked:
		return false
	if placingMachine == Machines.ASSEMBLER && occupyingMachine is Adder:
		return true
	elif placingMachine == Machines.TRASHER && occupyingMachine is Trasher:
		return true
	elif placingMachine == Machines.PACKAGER && occupyingMachine is Packager:
		return true
	elif placingMachine == Machines.SCANNER && occupyingMachine is Scanner:
		return true
	elif placingMachine == Machines.SEQUENCER && occupyingMachine is Sequencer:
		return true
	elif placingMachine == Machines.REPEATER && occupyingMachine is Repeater:
		return true
	return false

func placeMachine() -> void:
	var newMachine
	var placingInventory
	match placingMachine:
		Machines.ASSEMBLER:
			newMachine = AssemblerScene.instantiate()
			AssemblerInventory -= 1
			placingInventory = AssemblerInventory
		Machines.TRASHER:
			newMachine = TrashScene.instantiate()
			TrasherInventory -= 1
			placingInventory = TrasherInventory
		Machines.PACKAGER:
			newMachine = PackagerScene.instantiate()
			PackagerInventory -= 1
			placingInventory = PackagerInventory
		Machines.SCANNER:
			newMachine = ScannerScene.instantiate()
			ScannerInventory -= 1
			placingInventory = ScannerInventory
		Machines.SEQUENCER:
			newMachine = SequencerScene.instantiate()
			SequencerInventory -= 1
			placingInventory = SequencerInventory
		Machines.REPEATER:
			newMachine = RepeaterScene.instantiate()
			RepeaterInventory -= 1
			placingInventory = RepeaterInventory
		_:
			pass
	get_parent().add_child(newMachine)
	newMachine.position = PlacementGhost.position
	newMachine.rotation = PlacementGhost.rotation
	tileOccupiedData[hoverTile.x][hoverTile.y] = newMachine
	updatePlacementButtons()
	if placingInventory == 0:
		Globals.InteractMode = Globals.InteractionModes.INSPECTION

func updatePlacementButtons() -> void:
	AssemblerButton.get_child(1).text = str(AssemblerInventory)
	TrasherButton.get_child(1).text = str(TrasherInventory)
	PackagerButton.get_child(1).text = str(PackagerInventory)
	ScannerButton.get_child(1).text = str(ScannerInventory)
	SequencerButton.get_child(1).text = str(SequencerInventory)
	RepeaterButton.get_child(1).text = str(RepeaterInventory)
	if Globals.FactoryStarted:
		AssemblerButton.disabled = true
		TrasherButton.disabled = true
		PackagerButton.disabled = true
		ScannerButton.disabled = true
		SequencerButton.disabled = true
		RepeaterButton.disabled = true
		WireButton.disabled = true
		DeleteButton.disabled = true
		InspectionButton.disabled = true
		return
	else:
		AssemblerButton.disabled = false
		TrasherButton.disabled = false
		PackagerButton.disabled = false
		ScannerButton.disabled = false
		SequencerButton.disabled = false
		RepeaterButton.disabled = false
		WireButton.disabled = false
		DeleteButton.disabled = false
		InspectionButton.disabled = false
	if AssemblerInventory == 0:
		AssemblerButton.disabled = true
	else:
		AssemblerButton.disabled = false
	if TrasherInventory == 0:
		TrasherButton.disabled = true
	else:
		TrasherButton.disabled = false
	if PackagerInventory == 0:
		PackagerButton.disabled = true
	else:
		PackagerButton.disabled = false
	if ScannerInventory == 0:
		ScannerButton.disabled = true
	else:
		ScannerButton.disabled = false
	if SequencerInventory == 0:
		SequencerButton.disabled = true
	else:
		SequencerButton.disabled = false
	if RepeaterInventory == 0:
		RepeaterButton.disabled = true
	else:
		RepeaterButton.disabled = false

func rotateMachine() -> void:
	var machineToRotate = tileOccupiedData[hoverTile.x][hoverTile.y]
	machineToRotate.rotation = PlacementGhost.rotation

func hoverTileInBounds() -> bool:
	return hoverTile.x in range(tileWidth) && hoverTile.y in range(tileHeight)

func _machine_button_clicked(machine: Machines) -> void:
	Globals.InteractMode = Globals.InteractionModes.PLACEMENT
	setPlacingMachine(machine)

func highlightWireSenders():
	for x in tileWidth:
		for y in tileHeight:
			var occupyingObject = tileOccupiedData[x][y]
			if occupyingObject is Scanner || occupyingObject is Sequencer || occupyingObject is Repeater:
				var curCoord = Vector2i(x,y)
				HiLiteTileMap.set_cell(curCoord,1,Vector2i(0,0))

func highlightWireReceivers():
	for x in tileWidth:
		for y in tileHeight:
			var occupyingObject = tileOccupiedData[x][y]
			if occupyingObject is Receiver && occupyingObject.InputSender == null:
				var curCoord = Vector2i(x,y)
				HiLiteTileMap.set_cell(curCoord,1,Vector2i(0,0))

func highlightConfigurableMachines():
	for x in tileWidth:
		for y in tileHeight:
			var occupyingObject = tileOccupiedData[x][y]
			if occupyingObject is Scanner || occupyingObject is Sequencer || occupyingObject is Adder:
				var curCoord = Vector2i(x,y)
				HiLiteTileMap.set_cell(curCoord,1,Vector2i(0,0))

func _wire_button_clicked() -> void:
	Globals.InteractMode = Globals.InteractionModes.WIRING_SENDER

func _on_delete_button_pressed() -> void:
	Globals.InteractMode = Globals.InteractionModes.DELETION

func deleteMachine(occupyingMachine : Node2D) -> void:
	if occupyingMachine != null && occupyingMachine is Machine:
		var machineDeleted = occupyingMachine.AttemptDelete()
		if machineDeleted:
			tileOccupiedData[hoverTile.x][hoverTile.y] = null
			if occupyingMachine is Adder:
				AssemblerInventory += 1
			elif occupyingMachine is Trasher:
				TrasherInventory += 1
			elif occupyingMachine is Packager:
				PackagerInventory += 1
			elif occupyingMachine is Scanner:
				ScannerInventory += 1
			elif occupyingMachine is Sequencer:
				SequencerInventory += 1
			elif occupyingMachine is Repeater:
				RepeaterInventory += 1
			updatePlacementButtons()

func _on_inspection_button_pressed() -> void:
	Globals.InteractMode = Globals.InteractionModes.INSPECTION
