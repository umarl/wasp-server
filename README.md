# Wasp Server

For the client, go to **Wasp Client**

## How to use it

Add a *WaspServer* node somewhere in your tree.

Call `start_server()` to start the server. You can pass a number to specify the port (default is 14445). It returns [`Error`](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enumerations-enum-error). If the value returned is not `OK`, it means the server was not initialized. You can check the error code on *[@GlobalScope Error enum](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enumerations-enum-error)*.

Add and remove listeners to messages using `add_listener()` and `remove_listener()`. They are built upon signals and use the same syntax as [`connect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-connect) and [`disconnect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-disconnect).

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

func on_play_animation():
	# called when the server receives a message with type "play_animation"
	pass

func destroy():
	# ...
	# remove listeners before freeing the node
	server.remove_listener("play_animation", self, "on_play_animation")
	queue_free()
```

Be sure to remove listeners when you free objects. They can cause errors if left unremoved.


## Messages

The messages exchanged between the client and server have the following structure:

```json
{
	"type": string - the type of the message,
	"id": int - a number to identify the message
	"args": object - a dictionary containing the data of the message
}
```

## Args



