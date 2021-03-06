extends Node
class_name WaspServer

const SIGNAL_PREFIX = "WASP_"

var _wss: WebSocketServer = WebSocketServer.new()
var _clients: Array = []

var _port := 14445
var _type_field := "type"
var _show_warnings := true
var _is_started := false

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


func _process(_delta: float) -> void:
	if _wss.is_listening():
		_wss.poll()


func _show_warning(warning: String) -> void:
	if _show_warnings:
		push_warning(warning)


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
	
	# Received binary message
	if not peer.was_string_packet():
		_on_binary_message_received(id, packet)
		return
	
	# Parse and validate message
	var msg_str = packet.get_string_from_utf8()
	var jr: JSONParseResult = JSON.parse(msg_str)
	
	# JSON parsing failed
	if jr.error != OK:
		_on_invalid_json_received(id, msg_str, jr)
		return
	
	# Parsed JSON is not a dictionary
	if not jr.result is Dictionary:
		_on_invalid_json_received(id, msg_str, jr)
		return
	
	# Message doesn't have type
	if not jr.result.has(_type_field):
		_on_invalid_json_received(id, msg_str, jr)
		return
	
	_on_message_received(id, jr.result)




func _on_binary_message_received(client_id: int, packet: PoolByteArray) -> void:
	_show_warning("Received binary packet")


func _on_invalid_json_received(client_id: int, message: String, parse_result: JSONParseResult) -> void:
	if parse_result.error != OK:
		_show_warning("Error parsing JSON: %s\n%s" % [parse_result.error_string, message])
	elif not parse_result.result is Dictionary:
		_show_warning("JSON is not a dictionary\n%s" % parse_result.result)
	else:
		_show_warning("Message doesn't have the expected type field '%s'\n%s" % [_type_field, parse_result.result])


func _on_message_received(client_id: int, message: Dictionary) -> void:
	# print("Message: %s" % message)
	var sig: String = SIGNAL_PREFIX + message[_type_field]
	if has_user_signal(sig):
		emit_signal(sig, client_id, message)
	else:
		_show_warning("No listener for message of type %s" % message[_type_field])



func start_server(port: int = 14445, message_type_field = "type", show_warnings: bool = true) -> int:
	_wss.stop()
	
	# range of listening ports
	if port < 1 or port > 65535 :
		return ERR_PARAMETER_RANGE_ERROR
	
	var err = _wss.listen(port)
	if err != OK:
		_is_started = false
		set_process(false)
		push_error("Wasp Server was not started. Error num %d" % err)
		return err
	_show_warnings = show_warnings
	_port = port
	_type_field = message_type_field
	_is_started = true
	set_process(true)
	return OK


func stop_server() -> void:
	_wss.stop()
	_is_started = false
	set_process(false)


func is_listening() -> bool:
	return _wss.is_listening()


func get_listening_port() -> int:
	return _port


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
func send_raw(client_id: int, data: PoolByteArray) -> void:
	if not is_listening():
		push_error("Wasp server is not started!")
		return
	
	if not _wss.has_peer(client_id):
		_show_warning("No client with id %d" % client_id)
		return
	
	_wss.get_peer(client_id).put_packet(data)


# Send a raw message to all connected clients
func broadcast_raw(data: PoolByteArray) -> void:
	if not is_listening():
		push_error("Wasp server is not started!")
		return
	
	for id in _clients:
		send_raw(id, data)


# Send a message to a specific client.
# This adds a "type" field to the message. If it already has one, it will be overwritten
func send(client_id: int, message_type: String, message: Dictionary = {}) -> void:
	if not is_listening():
		push_error("Wasp server is not started!")
		return
	
	if not _wss.has_peer(client_id):
		_show_warning("No client with id %d" % client_id)
		return
	
	message[_type_field] = message_type
	
	send_raw(client_id, JSON.print(message).to_utf8())


# Send a message to all connected clients
func broadcast(message_type: String, message: Dictionary = {}) -> void:
	if not is_listening():
		push_error("Wasp server is not started!")
		return
	
	message[_type_field] = message_type
	broadcast_raw(JSON.print(message).to_utf8())
