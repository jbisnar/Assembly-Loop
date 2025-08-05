extends Node2D
class_name Product

@onready var spr2DNode = $Sprite2D
@onready var areaNode = $Area2D
@onready var MaterialCounter = $MaterialCounter
@onready var MetalCountLabel : Label = $MaterialCounter/MetalCounter
@onready var WheelCountLabel : Label = $MaterialCounter/WheelCounter
@onready var EngineCountLabel : Label = $MaterialCounter/EngineCounter

var metalCount : int = 0
var wheelCount : int = 0
var engineCount : int = 0
var current_Product : Globals.Products
var targetPos : Vector2
var moveSpeed : float = 250
var interactionLocked : bool
var trashing : bool
var fadeRate : float = 2
var shrinkRate : float = 1
var firstTick : bool
var secondCaller : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	targetPos = position
	current_Product = Globals.Products.SCRAP
	interactionLocked = false
	trashing = false
	firstTick = true
	secondCaller = false
	EventBus.connect("Reset_Factory", queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if targetPos != null:
		position = position.move_toward(targetPos, moveSpeed * delta)
	if trashing:
		modulate.a -= fadeRate * delta
		var curScale = scale.x
		var newScale = curScale - shrinkRate * delta
		scale = Vector2(newScale, newScale)
		if modulate.a < 0 || newScale < 0:
			queue_free()
	if firstTick:
		var overlaps = areaNode.get_overlapping_areas()
		for area in overlaps:
			var possibleProduct = area.get_parent()
			if possibleProduct is Product:
				metalCount += possibleProduct.metalCount
				wheelCount += possibleProduct.wheelCount
				engineCount += possibleProduct.engineCount
				updateSprite()
				possibleProduct.secondCaller = true
				if !secondCaller:
					possibleProduct.queue_free()
	#firstTick = false

func addPart(part: int) -> void:
	if part == 1:
		metalCount += 1
	elif  part == 2:
		wheelCount += 1
	else:
		engineCount += 1
	MetalCountLabel.text = str(metalCount)
	WheelCountLabel.text = str(wheelCount)
	EngineCountLabel.text = str(engineCount)
	updateSprite()
	
func updateSprite() -> void:
	var newSprite : String
	MaterialCounter.visible = false
	if (metalCount == 1 && wheelCount == 0 && engineCount == 0): # Metal
		newSprite = "res://Sprites/Metal Plate.png"
		current_Product = Globals.Products.METAL
	elif (metalCount == 0 && wheelCount == 1 && engineCount == 0): # Wheel
		newSprite = "res://Sprites/WheelBG.png"
		current_Product = Globals.Products.WHEEL
	elif (metalCount == 0 && wheelCount == 0 && engineCount == 1): # Engine
		newSprite = "res://Sprites/Engine.png"
		current_Product = Globals.Products.ENGINE
	elif (metalCount == 1 && wheelCount == 1 && engineCount == 0): # Unicycle
		newSprite = "res://Sprites/Unicycle.png"
		current_Product = Globals.Products.UNICYCLE
	elif (metalCount == 1 && wheelCount == 2 && engineCount == 0): # Bicycle
		newSprite = "res://Sprites/Bicycle.png"
		current_Product = Globals.Products.BICYCLE
	elif (metalCount == 1 && wheelCount == 3 && engineCount == 0): # Tricycle
		newSprite = "res://Sprites/Tricycle2.png"
		current_Product = Globals.Products.TRICYCLE
	elif (metalCount == 2 && wheelCount == 2 && engineCount == 1): # Motorcycle
		newSprite = "res://Sprites/Motorcycle.png"
		current_Product = Globals.Products.MOTORCYCLE
	elif (metalCount == 3 && wheelCount == 4 && engineCount == 1): # Car
		newSprite = "res://Sprites/Golf Cart.png"
		current_Product = Globals.Products.CAR
	elif (metalCount == 2 && wheelCount == 0 && engineCount == 1): # Snowmobile
		newSprite = "res://Sprites/Snowmobile.png"
		current_Product = Globals.Products.SNOWMOBILE
	elif isProductSubset():
		newSprite = "res://Sprites/Scrap.png"
		current_Product = Globals.Products.SCRAP
		MaterialCounter.visible = true
	else:
		newSprite = "res://Sprites/abominationD.png"
		current_Product = Globals.Products.ABOMINATION
	var newTexture = load(newSprite)
	spr2DNode.texture = newTexture

func isProductSubset() -> bool:
	if (metalCount <= 1 && wheelCount <= 2 && engineCount <= 0): # Bicycle
		return true
	elif (metalCount <= 1 && wheelCount <= 3 && engineCount <= 0): # Tricycle
		return true
	elif (metalCount <= 2 && wheelCount <= 2 && engineCount <= 1): # Motorcycle
		return true
	elif (metalCount <= 3 && wheelCount <= 4 && engineCount <= 1): # Car
		return true
	elif (metalCount <= 2 && wheelCount <= 0 && engineCount <= 1): # Snowmobile
		return true
	return false

func trash() -> void:
	if interactionLocked:
		return
	trashing = true
