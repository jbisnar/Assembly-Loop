extends Machine
class_name Receiver

var InputSignal : bool
@export var InputSender : Machine

signal InputSignalUpdated

func DisconnectWire() -> void:
	InputSignal = true
	if InputSender != null:
		InputSender.disconnectReceiver(self)
	InputSender = null
	emit_signal("InputSignalUpdated")
