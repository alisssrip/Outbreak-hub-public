extends Node
signal private_message_received(from_id: int, data: Dictionary)

var user         := RpcUserModule.new()
var friend       := RpcFriendModule.new()
var user_store   := RpcUserStore.new()
var global_chat  := RpcGlobalChatModule.new()
var private_chat := RpcPrivateChatModule.new()
var ingame       := RpcInGameModule.new()
var user_search  := RpcUserSearchModule.new()
var friend_requests := RpcFriendRequestsModule.new()
var ingame_status := InGameStatusController.new()
var ingame_predictor := IngamePredictor.new()
var launcher := RpcLauncherModule.new()

func _process(delta: float) -> void:
	ingame_predictor.tick(delta)

func _ready() -> void:
	private_chat.message_received.connect(func(from_id, data):
		private_message_received.emit(from_id, data)
	)
	user.profile_loaded.connect(_on_self_profile_loaded)
	friend.friend_updated.connect(_on_friend_event)
	RpcClient.disconnected.connect(func(): user_store.clear())
	RpcClient.connected.connect(func():
		user.load_profile()
		friend.load_friends()
		friend_requests.load_pending()
		global_chat.get_history()
	)
	ingame_status.init(self)
	ingame.init(self, ingame_status)
	ingame_predictor.init(user_store)

func _on_self_profile_loaded() -> void:
	user_store.set_user(user.user_id, {
		"nickname":  user.nickname,
		"status":    user.status,
		"ranking":   user.ranking,
		"charFav":   user.char_fav,
		"title":     user.title,
		"avatarUrl": user.avatar_url
	})

func _on_friend_event(uid: int) -> void:
	if uid == -1:
		user_store.set_users_bulk(friend.list)
	elif friend.list.has(uid):
		user_store.set_user(uid, friend.list[uid])
