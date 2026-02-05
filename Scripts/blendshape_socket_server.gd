extends Node3D
class_name SocketBlendShapes
@onready var facialAnimation:FacialAnimation = $"../FacialAnimation"

# The port we will listen to.
const PORT:int = 8080

# Our TCP Server instance.
var _tcp_server:TCPServer = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id:int = 1


func _ready():
	# Start listening on the given port.
	var err:Error = _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		set_process(false)


func _process(_delta):
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		print("+ Peer %d connected." % last_peer_id)
		var ws:WebSocketPeer = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]

		peer.poll()

		var peer_state = peer.get_ready_state()
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count():
				var packet:PackedByteArray = peer.get_packet()
				if peer.was_string_packet():
					var packet_text:String = packet.get_string_from_utf8()
					if packet_text != null:
						var parsed_message = JSON.parse_string(packet_text)
						if parsed_message != null:
							var categories = parsed_message["categories"]
							if categories != null:
								facialAnimation.setBlendShapesFromSocket(categories)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			var code:int = peer.get_close_code()
			var reason:String = peer.get_close_reason()
			print("- Peer %s closed with code: %d, reason %s. Clean: %s" % [peer_id, code, reason, code != -1])
