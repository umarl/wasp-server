# Wasp Server

A [Godot](https://godotengine.org) addon that uses Signals to facilitate the use of WebSocket with JSON. You create a listener to message type and, when one is received, it will call the function on the assigned object.
It's built on top of signals and you can use features that are available to it, such as bindings, oneshot connections, etc.

Compatible with Godot Engine 3.3.x. A client version will be available in the future.


## How can this help me?

If you are working with websockets/json and the messages have an identifier for what type of data they contain, it will make handling messages just like using regular signals.
You chose a port, tell the name of the type field and then add a listener for each type.

If you're going to exchange lots of binary messages, messages that are not valid jsons, or if they don't have a common identifier, this addon won't help you very much.


## How to use it

Add a *WaspServer* node somewhere in your tree.

Call `start_server()` to start the server. You can pass a number to specify the port (default is 14445). It returns [`Error`](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-error). If the value returned is not `OK`, it means the server was not initialized. You can check the error code on *[@GlobalScope enum Error](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-error)*.

Add and remove listeners to messages using `add_listener()` and `remove_listener()`. They are built upon [signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html) and receive the same parameters as [`connect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-connect) and [`disconnect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-disconnect).


The following code shows how to use listeners.

```gdscript
# example.gd

extends Node

onready var server = get_node("WaspServer")

func _ready():
	# ...
	
	# "play_animation" is the message type
	# self is the target object where the function will be called. In this case, this node
	# "on_play_animation" is the name of the function to be called
	server.add_listener("play_animation", self, "on_play_animation")
	
	# starts server on port 9000
	server.start_server(9000)

func on_play_animation(message):
	# called when the server receives a message of type "play_animation"
	# eg. { "type": "play_animation" }
	# the parameter 'message' is the received message dictionary
	pass

func destroy():
	# ...
	# remove listeners before freeing the node
	server.remove_listener("play_animation", self, "on_play_animation")
	queue_free()
```

Be sure to remove listeners when you free objects. They can cause errors if left unremoved.


## Messages

The messages received by the server must be valid JSON objects and have a field specifying the type. The default field name is `type`, but it can be changed during server initialization.
When a message is received, it will call all listeners added to that type and pass the parsed message to the registered methods.


Example:

```gdscript
func _ready():
	server = get_node("WaspServer")
	
	# add listener for "change-sprite"
	server.add_listener("change-sprite", self, "on_change_sprite")
	
	# start server on port 14445 and uses field 'cmd' of messages to call listeners
	server.start_server(14445, "cmd")
```

Message:


```json
{
	"cmd": "change-sprite",
	"id": 947,
	"args": {
		"sprite": "Sprite2"
	}
}
```

When the message above is received by the server, it will call `on_change_scene`, passing the parsed message as parameter:

```gdscript
func on_change_sprite(message):
	print("ID: " + str(message["id"])
	# prints 'ID: 947'
	
	print("Next sprite: " + message["args"]["sprite"])
	# prints 'Next sprite: Sprite2'
```



