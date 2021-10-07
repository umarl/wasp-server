extends Control

const SimpleClient = preload("SimpleClient.tscn")

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
onready var ClientList = $PanelListening/vbox/hsplit/vbox_clients/scrollv/ClientList

onready var TestLabelText = $"PanelListening/vbox/hsplit/TestFields/LabelText"
onready var TestLabelNumber = $"PanelListening/vbox/hsplit/TestFields/LabelNumber"
onready var TestRectColor = $"PanelListening/vbox/hsplit/TestFields/RectColor"

# DialogError controls
onready var DialogErrorLabel = $DialogError/DialogErrorLabel


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
	PanelListening.grab_focus()
	LabelPort.text = str(server.get_listening_port())
	PanelStart.hide()
	PanelListening.show()
	
	# add listeners
	server.add_listener("set_text", self, "_on_set_text")
	server.add_listener("set_number", self, "_on_set_number")
	server.add_listener("set_color", self, "_on_set_color")
	


func _on_DialogErrorLabel_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_ButtonAddClient_pressed() -> void:
	var c = SimpleClient.instance()
	ClientList.add_child(c)
	c.connect_to_server("ws://localhost:%d" % server.get_listening_port())


# WaspServer listeners!
func _on_set_text(message: Dictionary) -> void:
	TestLabelText.text = message["data"]

func _on_set_number(message: Dictionary) -> void:
	TestLabelNumber.text = str(message["data"])

func _on_set_color(message: Dictionary) -> void:
	TestRectColor.color = Color(message["data"])
