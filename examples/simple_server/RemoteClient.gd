extends PanelContainer

onready var InputText = $vbox/hbox2/InputText
onready var ButtonSetText = $vbox/hbox2/ButtonSetText
onready var InputNumber = $vbox/hbox2/InputNumber
onready var ButtonSetNumber = $vbox/hbox2/ButtonSetNumber
onready var ButtonColor = $vbox/hbox2/ButtonColor
onready var ButtonSetColor = $vbox/hbox2/ButtonSetColor

onready var LabelStatus = $vbox/hbox/LabelStatus
onready var ButtonDisconnect = $vbox/hbox/ButtonDisconnect
onready var LabelReceivedData = $vbox/hbox3/LabelReceivedData

var ws: WebSocketClient = WebSocketClient.new()


func _enter_tree() -> void:
	ws.connect("connection_established", self, "_on_ws_connection_established")
	ws.connect("connection_closed", self, "_on_ws_connection_closed")
	ws.connect("connection_error", self, "_on_ws_connection_error")
	ws.connect("data_received", self, "_on_data_received")


func _process(delta: float) -> void:
	var status = ws.get_connection_status()
	if status == ws.CONNECTION_CONNECTED or status == ws.CONNECTION_CONNECTING:
		ws.poll()


func _on_ws_connection_established(protocol: String) -> void:
	ws.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	LabelStatus.text = "RemoteClient - Connected"
	ButtonDisconnect.text = "disconnect"
	ButtonSetText.disabled = false
	ButtonSetNumber.disabled = false
	ButtonSetColor.disabled = false

func _on_ws_connection_closed(was_clean: bool) -> void:
	LabelStatus.text = "RemoteClient - Disconnected"
	ButtonDisconnect.text = "free"
	ButtonSetText.disabled = true
	ButtonSetNumber.disabled = true
	ButtonSetColor.disabled = true
	

func _on_ws_connection_error() -> void:
	LabelStatus.text = "RemoteClient - Connection Error!"
	ButtonDisconnect.text = "free"
	push_error("Could not connect to server!")


func _on_data_received() -> void:
	var packet = ws.get_peer(1).get_packet()
	
	var jr: JSONParseResult = JSON.parse(packet.get_string_from_utf8())
	
	if jr.error != OK: return
	elif not jr.result is Dictionary: return
	elif not jr.result.has("data"): return
	
	LabelReceivedData.text = str(jr.result["data"])



func connect_to_server(address: String) -> void:
	var err = ws.connect_to_url(address)
	if err != OK:
		push_error("SimpleClient could not connect to server! Error code %d" % err)


func send(type: String, data) -> void:
	if ws.get_connection_status() == ws.CONNECTION_CONNECTED:
		var m = {
			"type": type,
			"data": data
		}
		
		ws.get_peer(1).put_packet(JSON.print(m).to_utf8())



func _on_ButtonSetText_pressed() -> void:
	send("set_text", InputText.text)


func _on_ButtonSetNumber_pressed() -> void:
	send("set_number", InputNumber.value)


func _on_ButtonSetColor_pressed() -> void:
	send("set_color", ButtonColor.color.to_html())


func _on_ButtonDisconnect_pressed() -> void:
	if ws.get_connection_status() == ws.CONNECTION_CONNECTED or ws.get_connection_status() == ws.CONNECTION_CONNECTING: 
		ws.disconnect_from_host()
	queue_free()
