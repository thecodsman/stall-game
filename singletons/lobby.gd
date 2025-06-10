extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const DEFAULT_SERVER_PORT = 5835
const MAX_CONNECTIONS = 10

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players : Dictionary = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info : Dictionary = {"name": "Name"}
var players_loaded : int = 0
var lobby_id : int
var peer : MultiplayerPeer = null


func _ready():
	multiplayer.allow_object_decoding = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if not OS.has_feature("Steam"): return
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	Steam.join_requested.connect(_on_steam_lobby_join_requested)


func join_game(address : String = "", port : int = 0):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if not port:
		port = DEFAULT_SERVER_PORT
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error: return error
	multiplayer.multiplayer_peer = peer


func create_game(port : int):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error: return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)


func steam_join_lobby(new_lobby_id : int):
	print("Attempting to join lobby %s" % new_lobby_id)
	players.clear()
	Steam.joinLobby(new_lobby_id)


func steam_create_lobby():
	if lobby_id != 0: return
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_CONNECTIONS)


func _on_steam_lobby_join_requested(new_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")
	steam_join_lobby(new_lobby_id)
	#await Steam.lobby_joined


func _on_steam_lobby_joined(new_lobby_id : int, _permissions : int, _locked : bool, response : int):
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("ERROR JOINING LOBBY, CODE: %s" % response)
		return response
	lobby_id = new_lobby_id
	var id = Steam.getLobbyOwner(new_lobby_id)
	if id != Steam.getSteamID():
		connect_steam_socket(id)
		await multiplayer.connected_to_server
		_register_player.rpc(player_info)
		#players[multiplayer.get_unique_id()].name = "test"


func _on_steam_lobby_created(response : int, new_lobby_id : int):
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("ERROR CREATING LOBBY, CODE: %s" % response)
		return response
	lobby_id = new_lobby_id
	create_steam_socket()
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName(), "'s Server"))
	Steam.allowP2PPacketRelay(true)
	players[1] = player_info
	player_connected.emit(1, player_info)


func create_steam_socket():
	peer = SteamMultiplayerPeer.new()
	var error = peer.create_host(0)
	if error:
		print("ERROR CREATING SOCKET, ERROR CODE : %s" % error)
		return error
	multiplayer.multiplayer_peer = peer


func connect_steam_socket(steam_id : int):
	peer = SteamMultiplayerPeer.new()
	var error = peer.create_client(steam_id, 0)
	if error: 
		print("ERROR CONNECTING SOCKET, ERROR CODE : %s" % error)
		return error
	multiplayer.multiplayer_peer = peer


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		print("player loaded")
		players_loaded += 1
		if players_loaded == players.size():
			$/root/stage.start_game()
			players_loaded = 0
			print("all players loaded!")


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(id):
	_register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_peer_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
