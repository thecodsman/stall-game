extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id : int, player_info : Dictionary)
signal player_disconnected(peer_id : int)
signal player_assigned_index(peer_id : int)
signal player_info_changed(peer_id : int)
signal server_disconnected

const DEFAULT_SERVER_IP : String = "127.0.0.1" # IPv4 localhost
const DEFAULT_SERVER_PORT : int = 5835
const MAX_CONNECTIONS : int = 4
const MATCHMAKING_ATTEMPTS_PER_PHASE : int = 10

const CONNECT_MENU_UID : String = "uid://jhomeys3bfhg"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players : Dictionary[int, Dictionary] = {}

var player_indices : Dictionary[int, int] = {} ## peer_id -> player_index

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info : Dictionary[String,String] = {"name": "PLACEHOLDER"}
var players_loaded : int = 0
var player_index : int = 0
var lobby_id : int = 0
var lobby_data : Dictionary[String,String] = {
	"quickplay":"false",
	}
var lobby_members : Array = []
var steam_id: int = 0
var steam_username: String = ""
var matchmaking_phase: int = 0
var matchmaking_phase_attempt : int = 0
var peer : MultiplayerPeer = null


func _process(_delta: float) -> void:
	if lobby_id == 0: return
	read_messages()


func _ready() -> void:
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
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.network_messages_session_request.connect(_on_session_request)
	Steam.network_messages_session_failed.connect(_on_session_connect_fail)



func join_game(address : String = "", port : int = 0) -> int:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if not port:
		port = DEFAULT_SERVER_PORT
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_client(address, port)
	if error: return error
	multiplayer.multiplayer_peer = peer
	return 0


func create_game(port : int) -> int:
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_server(port, MAX_CONNECTIONS)
	if error: return error
	multiplayer.multiplayer_peer = peer
	players[1] = player_info
	player_connected.emit(1, player_info)
	return 0


func steam_start_matchmaking() -> void:
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")
	await UI.on_transition
	matchmaking_phase = 0
	lobby_data["quickplay"] = "true"
	steam_create_lobby(Steam.LOBBY_TYPE_PUBLIC)
	matchmaking_loop()


func matchmaking_loop() -> void:
	if matchmaking_phase < 4:
		Steam.addRequestLobbyListDistanceFilter(matchmaking_phase)
		Steam.addRequestLobbyListStringFilter("quickplay", "true", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.requestLobbyList()


# TODO make quick play not break when 2 people are searching at the same time
func _on_lobby_match_list(lobbies: Array) -> void:
	var attempting_join: bool = false
	for this_lobby : int in lobbies:
		if this_lobby == lobby_id: continue
		var lobby_name : String = Steam.getLobbyData(this_lobby, "name")
		var lobby_nums : int = Steam.getNumLobbyMembers(this_lobby)
		if lobby_nums < MAX_CONNECTIONS && not attempting_join:
			attempting_join = true
			print("Attempting to join %s" % lobby_name)
			UI.hide_element(UI.game_text)
			Steam.joinLobby(this_lobby)
	if not attempting_join && players.size() <= 1:
		if matchmaking_phase_attempt < MATCHMAKING_ATTEMPTS_PER_PHASE:
			matchmaking_phase_attempt += 1
			matchmaking_loop()
		elif matchmaking_phase == 3:
			matchmaking_phase_attempt += 1
			matchmaking_loop()
		else:
			matchmaking_phase += 1
			matchmaking_phase_attempt = 0
			matchmaking_loop()


func steam_join_lobby(new_lobby_id : int) -> void:
	print("Attempting to join lobby %s" % new_lobby_id)
	players.clear()
	Steam.joinLobby(new_lobby_id)


func steam_create_lobby(lobby_type : int = Steam.LOBBY_TYPE_PUBLIC) -> void:
	if lobby_id != 0: return
	Steam.createLobby(lobby_type, MAX_CONNECTIONS)


func _on_steam_lobby_join_requested(new_lobby_id: int, friend_id: int) -> void:
	Globals.is_online = true
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	UI.anim.play("transition_close")
	await UI.anim.animation_finished
	steam_join_lobby(new_lobby_id)
	await multiplayer.connected_to_server
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")
	UI.anim.play("transition_open")


func _on_steam_lobby_joined(new_lobby_id : int, _permissions : int, _locked : bool, response : int) -> int:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("ERROR JOINING LOBBY, CODE: %s" % response)
		return response
	lobby_id = new_lobby_id
	var id : int = Steam.getLobbyOwner(new_lobby_id)
	if id == Steam.getSteamID(): return Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS
	get_lobby_members()
	make_p2p_handshake()
	connect_steam_socket(id)
	return Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS


func _on_steam_lobby_created(response : int, new_lobby_id : int) -> int:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("ERROR CREATING LOBBY, CODE: %s" % response)
		return response
	lobby_id = new_lobby_id
	create_steam_socket()
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "name", "%s's Server" % str(Steam.getPersonaName()))
	for i : int in range(lobby_data.size()):
		var key : String = lobby_data.keys()[i]
		var value : String = lobby_data.values()[i]
		Steam.setLobbyData(lobby_id, key, value)
	Steam.allowP2PPacketRelay(true)
	return Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS


func create_steam_socket() -> int:
	peer = SteamMultiplayerPeer.new()
	var error : int = peer.create_host(0)
	if error:
		print("ERROR CREATING SOCKET, ERROR CODE : %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	players[1] = player_info
	player_connected.emit(1, player_info)
	return 0


func connect_steam_socket(_steam_id : int) -> int:
	peer = SteamMultiplayerPeer.new()
	var error : int = peer.create_client(_steam_id, 0)
	if error: 
		print("ERROR CONNECTING SOCKET, ERROR CODE : %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	return 0


func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()


func get_lobby_members() -> void:
	lobby_members.clear()
	var num_of_members : int = Steam.getNumLobbyMembers(lobby_id)
	for member : int in range(num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})


func _on_session_request(remote_id: int) -> void:
	var _requester: String = Steam.getFriendPersonaName(remote_id)
	print("uhhh")
	if lobby_data["quickplay"] == "true":
		# only host if steam_id is greater than opponents steam id
		if remote_id < steam_id:
			Steam.acceptSessionWithUser(remote_id)
			make_p2p_handshake()
	else:
		Steam.acceptSessionWithUser(remote_id)
		print("GUHHH")
		make_p2p_handshake()


func _on_session_connect_fail(reason: int, remote_steam_id: int, connection_state: int, debug_message: String) -> void:
	print(debug_message)


func make_p2p_handshake() -> void:
	print("GUH")
	send_message(0, {"message": "handshake", "from": steam_id})


func read_messages() -> void:
	var messages : Array = Steam.receiveMessagesOnChannel(0, 1000)
	if messages.size() == 0: return
	for message : Dictionary in messages:
		if message.is_empty() or message == null:
			print("WARNING: read an empty message with non-zero size!")
		else:
			message.payload = bytes_to_var(message.payload).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
			var _message_sender: int = message['remote_steam_id']
			print("Message: %s" % message.payload)
			# Append logic here to deal with message data


func send_message(target: int, packet_data: Dictionary) -> void:
	var send_type : int = Steam.NETWORKING_SEND_RELIABLE_NO_NAGLE
	var channel   : int = 0
	var data      : PackedByteArray
	data.append_array(var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP))
	if target != 0:
		Steam.sendMessageToUser(target, data, send_type, channel)
	elif lobby_members.size() <= 1: return
	for member : Dictionary in lobby_members:
		if member['steam_id'] == steam_id: continue
		Steam.sendMessageToUser(member['steam_id'], data, send_type, channel)


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path : String) -> void:
	UI.transition_to_scene(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded != players.size(): return
		$/root/stage.start_game()
		players_loaded = 0
		#print("all players loaded!")


@rpc("any_peer", "reliable")
func update_player_info(new_player_info : Dictionary, peer_id : int) -> void:
	players[peer_id] = new_player_info
	player_info_changed.emit(peer_id)


# TODO make it so player_connected is emitted after player index is assigned
@rpc("authority", "call_local", "reliable")
func set_player_index(index : int, id : int, current_indices : Dictionary[int,int]) -> void:
	player_indices = current_indices
	player_indices[id] = index
	if multiplayer.get_unique_id() == id:
		player_index = index
	player_assigned_index.emit(id)


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(id : int) -> void:
	_register_player.rpc_id(id, player_info)
	if is_multiplayer_authority():
		set_player_index.rpc(players.size(), id, player_indices)


@rpc("any_peer", "reliable")
func _register_player(new_player_info : Dictionary) -> void:
	var new_player_id : int = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_peer_disconnected(id : int) -> void:
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok() -> void:
	var peer_id : int = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null
	UI.transition_to_scene(CONNECT_MENU_UID)


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
