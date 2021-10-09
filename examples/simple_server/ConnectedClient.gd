extends PanelContainer


onready var LabelID = $"vbox/hbox/LabelID"
onready var InputData = $"vbox/InputData"
onready var ButtonSendData = $"vbox/ButtonSendData"

var _is_setup := false
var _id: int
var _server


func _ready() -> void:
	LabelID.text = str(_id)


func setup(id: int, server) -> void:
	_id = id
	_server = server
	_is_setup = true
	
	if is_inside_tree():
		LabelID.text = str(id)


func _on_ButtonSendData_pressed() -> void:
	if not _is_setup:
		push_error("Client is not configured. Call 'setup' before sending data.")
		return
	var t = InputData.text
	if t != "":
		_server.send_data_to_client(_id, t.strip_edges().strip_escapes())


func _on_ButtonDisconnect_pressed() -> void:
	_server.disconnect_client(_id)
