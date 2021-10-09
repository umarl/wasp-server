extends Control

const ConnectedClient = preload("ConnectedClient.tscn")
const RemoteClient = preload("RemoteClient.tscn")

onready var server = $WaspServer

# panels
onready var PanelStart = $PanelStart
onready var PanelListening = $PanelListening
onready var DialogError = $DialogError

# PanelStart controls
onready var ButtonStart = $PanelStart/vbox/hbox/ButtonStart
onready var InputPort = $PanelStart/vbox/hbox/InputPort

# PanelListening controls
onready var LabelPort = $PanelListening/vbox/hbox/LabelPort

onready var TestLabelText = $"PanelListening/vbox/hsplit/TestFields/LabelText"
onready var TestLabelNumber = $"PanelListening/vbox/hsplit/TestFields/LabelNumber"
onready var TestRectColor = $"PanelListening/vbox/hsplit/TestFields/RectColor"
onready var ConnectedClientList = $"PanelListening/vbox/hsplit/TestFields/scroll/ConnectedClientList"

onready var RemoteClientList = $PanelListening/vbox/hsplit/vbox_clients/scrollv/RemoteClientList


# DialogError controls
onready var DialogErrorLabel = $DialogError/DialogErrorLabel


var _clients := {}


func _ready() -> void:
	PanelStart.show()
	PanelListening.hide()
	DialogError.hide()


func _on_ButtonStart_pressed() -> void:
	var port = InputPort.text
	if not port.is_valid_integer():
		DialogErrorLabel.bbcode_text = "Please type a valid port number."
		DialogError.popup_centered()
		return
	
	var error = server.start_server(port.to_int())
	
	if error != OK:
		var text = "Could not start server. Error code: %d.\n" % error
		text += "Please go to [url=https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-error]the docs[/url] to check the error code."
		DialogErrorLabel.bbcode_text = text
		DialogError.popup_centered()
		return
	
	# hide and show panels
	LabelPort.text = str(server.get_listening_port())
	PanelStart.hide()
	PanelListening.show()
	
	# connect signals
	server.connect("client_connected", self, "_on_client_connected")
	server.connect("client_disconnected", self, "_on_client_disconnected")
	
	# add listeners
	server.add_listener("set_text", self, "_on_set_text")
	server.add_listener("set_number", self, "_on_set_number")
	server.add_listener("set_color", self, "_on_set_color")


func _on_DialogErrorLabel_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_ButtonAddClient_pressed() -> void:
	var c = RemoteClient.instance()
	RemoteClientList.add_child(c)
	c.connect_to_server("ws://localhost:%d" % server.get_listening_port())


# WaspServer signals:
func _on_client_connected(id: int) -> void:
	var c = ConnectedClient.instance()
	c.setup(id, self)
	_clients[id] = c
	ConnectedClientList.add_child(c)


func _on_client_disconnected(id: int) -> void:
	if _clients.has(id):
		_clients[id].queue_free()
	_clients.erase(id)


# WaspServer listeners!
func _on_set_text(client_id: int, message: Dictionary) -> void:
	TestLabelText.text = message["data"]

func _on_set_number(client_id: int, message: Dictionary) -> void:
	TestLabelNumber.text = str(message["data"])

func _on_set_color(client_id: int, message: Dictionary) -> void:
	TestRectColor.color = Color(message["data"])


func send_data_to_client(client_id: int, data: String) -> void:
	server.send(client_id, "data", { "data": data })

func disconnect_client(client_id: int) -> void:
	server.disconnect_client(client_id)
