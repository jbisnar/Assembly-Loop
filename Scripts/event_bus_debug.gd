extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_game_tick_pressed() -> void:
	EventBus.emit_signal("Tick_Move")


func _on_adder_tick_pressed() -> void:
	EventBus.emit_signal("Tick_Adders")


func _on_non_impacting_tick_pressed() -> void:
	EventBus.emit_signal("Tick_Non_Altering")


func _on_input_signal_tick_pressed() -> void:
	EventBus.emit_signal("Tick_Signal_Input")


func _on_full_tick_pressed() -> void:
	EventBus.emit_signal("Tick_Move")
	await get_tree().create_timer(.5).timeout
	EventBus.emit_signal("Tick_Non_Altering")
	EventBus.emit_signal("Tick_Signal_Input")
	EventBus.emit_signal("Tick_Adders")
	EventBus.emit_signal("Tick_Trash")
	EventBus.emit_signal("Tick_Packagers")
