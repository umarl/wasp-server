# Wasp Server

It leverages the signal functionality to provide easier use of websockets. You create a listener to a message type and when one is received, it will automatically call the function on the wssigned object.
It's built on top of signals and you can use functionalities that are available to it, such as bindings, oneshot connections, etc. 

A client version will be available in the future.

## How to use it

Add a *WaspServer* node somewhere in your tree.

Call `start_server()` to start the server. You can pass a number to specify the port (default is 14445). It returns [`Error`](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enumerations-enum-error). If the value returned is not `OK`, it means the server was not initialized. You can check the error code on *[@GlobalScope Error enum](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enumerations-enum-error)*.

Add and remove listeners to messages using `add_listener()` and `remove_listener()`. They are built upon [signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html) and use the same syntax as [`connect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-connect) and [`disconnect()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-disconnect).


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

func on_play_animation(message):
	# called when the server receives a message of type "play_animation"
	# it receives a dictionary as a parameter, that being the received message
	pass

func destroy():
	# ...
	# remove listeners before freeing the node
	server.remove_listener("play_animation", self, "on_play_animation")
	queue_free()
```

Be sure to remove listeners when you free objects. They can cause errors if left unremoved.


## Messages

The messages received by the server should be a valid JSON object. The only required field is `type`. When a message is received, it will call all listeners associated with the type and pass the message to the registered methods.


Example:

- **type**: string - the type of the message  __*required__
- **id**: int - a number to identify the message
- **args**: object - a dictionary containing some data


```json
{
	"type": "change-stage",
	"id": 947,
	"args": {
		"stage": "Stage2"
	}
}
```




