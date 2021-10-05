extends Node
class_name WaspServer

const SIGNAL_PREFIX = "WASP_"

var _wss: WebSocketServer = WebSocketServer.new()
var _clients: Array = []

var _is_started := false

var _id_counter := 0

signal client_connected(id)
signal client_disconnected(id)
signal no_clients
# signal message


func _enter_tree() -> void:
	_wss.connect("client_connected", self, "_on_client_connected")
	_wss.connect("client_disconnected", self, "_on_client_disconnected")
	_wss.connect("client_close_request", self, "_on_client_close_request")
	_wss.connect("data_received", self, "_on_data_received")


func _exit_tree() -> void:
	_wss.disconnect("client_connected", self, "_on_client_connected")
	_wss.disconnect("client_disconnected", self, "_on_client_disconnected")
	_wss.disconnect("client_close_request", self, "_on_client_close_request")
	_wss.disconnect("data_received", self, "_on_data_received")


func _ready() -> void:
	set_process(_is_started)


func _process(delta: float) -> void:
	if _wss.is_listening():
		_wss.poll()


func _on_client_connected(id: int, protocol: String) -> void:
	var peer: WebSocketPeer = _wss.get_peer(id)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_clients.append(id)
	emit_signal("client_connected", id)


func _on_client_close_request(id: int, code: int, reason: String) -> void:
	# beleza po
	pass


func _on_client_disconnected(id: int, was_clean_close: bool) -> void:
	_clients.erase(id)
	emit_signal("client_disconnected", id)
	if _clients.empty():
		emit_signal("no_clients")


func _on_data_received(id: int) -> void:
	var peer: WebSocketPeer = _wss.get_peer(id)
	var packet: PoolByteArray = peer.get_packet()
	
	if not peer.was_string_packet():
		push_warning("Received binary packet")
		return
	
	# Parse and validate message
	
	var jr: JSONParseResult = JSON.parse(packet.get_string_from_utf8())
	
	if jr.error != OK:
		push_warning("JSON parsing error: %s" % jr.error_string)
		return
	
	if not jr.result is Dictionary:
		push_warning("JSON is not a dictionary\n%s" % jr.result)
		return
	
	var data: Dictionary = jr.result
	if not data.has("type"):
		push_warning("Message doesn't have a type\n%s" % data)
		return
	
	# print("Message: %s" % data)
	
	var sig: String = SIGNAL_PREFIX + data["type"]
	if has_user_signal(sig):
		if data.has("args"):
			emit_signal(sig, data["args"])
		else:
			emit_signal(sig)
	else:
		push_warning("No listener for message type %s" % data["type"])


func _get_message_id() -> int:
	_id_counter += 1
	return _id_counter




func start_server(port: int = 14445) -> int:
	_wss.stop()
	var err = _wss.listen(port)
	if err != OK:
		_is_started = false
		set_process(false)
		push_error("Wasp server was not started. Error num %d" % err)
		return err
	_is_started = true
	set_process(true)
	return OK


func stop_server() -> void:
	_wss.stop()
	_is_started = false
	set_process(false)


func disconnect_client(id: int) -> void:
	if _wss.has_peer(id):
		var p: WebSocketPeer = _wss.get_peer(id)
		p.close()


func add_listener(message_type: String, target: Object, method: String, binds: Array = [], flags: int = 0) -> int:
	var sig := SIGNAL_PREFIX + message_type
	if not has_user_signal(sig):
		add_user_signal(sig)
	
	return connect(sig, target, method, binds, flags)


func remove_listener(message_type: String, target: Object, method: String) -> void:
	var sig := SIGNAL_PREFIX + message_type
	
	if not has_user_signal(sig):
		push_error("There are no listeners for message type %s" % message_type)
		return
	
	if is_connected(sig, target, method):
		disconnect(sig, target, method)


# Send a raw message to a specific client
# Intended to be used when more fields are needed in the message (nonce, ids, etc)
func send_raw(id: int, data: PoolByteArray) -> void:
	if not _wss.is_listening():
		push_error("Wasp server is not started!")
		return
	
	if not _wss.has_peer(id):
		push_warning("No client with id %d" % id)
		return
	
	_wss.get_peer(id).put_packet(data)


# Send a raw message to all connected clients
# see send_raw
func broadcast_raw(data: PoolByteArray) -> void:
	for id in _clients:
		send_raw(id, data)


# Send a message to a specific client
func send(id: int, message_type: String, args: Dictionary = {}) -> void:
	if not _wss.is_listening():
		push_error("Wasp server is not started!")
		return
	
	if not _wss.has_peer(id):
		push_warning("No client with id %d" % id)
		return
	
	var m: Dictionary = {
		"type": message_type,
		"id": _get_message_id()
	}
	if not args.empty():
		m["args"] = args
	
	send_raw(id, JSON.print(m).to_utf8())


# Send a message to all connected clients
func broadcast(message_type: String, args: Dictionary = {}) -> void:
	for id in _clients:
		send(id, message_type, args)
