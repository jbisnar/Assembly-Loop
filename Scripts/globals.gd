extends Node

var PopupLocked : bool = false
enum InteractionModes {PLACEMENT, WIRING_SENDER, WIRING_RECEIVER, INSPECTION, DELETION}
var InteractMode : InteractionModes
enum Products {METAL, WHEEL, ENGINE, UNICYCLE, BICYCLE, TRICYCLE, MOTORCYCLE, CAR, SNOWMOBILE, SCRAP, ABOMINATION, EMPTY}
var Playing : bool
var FactoryStarted : bool
