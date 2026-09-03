class_name MV_Profile_AchievementsSystem
extends Node

const BADGE_BASE := "https://media.retroachievements.org/Badge/"
const OWN_NOT_LINKED_TEXT := "ACH_NOT_LINKED"
const OTHER_NOT_LINKED_TEXT := "ACH_OTHER_NOT_LINKED"
const OWN_EMPTY_TEXT := "ACH_OWN_EMPTY"
const OTHER_EMPTY_TEXT := "ACH_OTHER_EMPTY"

@export var achievement_prefab : PackedScene
@export var achievements_container : VBoxContainer
@export var not_linked_panel : RichTextLabel
@export var scroll : ScrollContainer

var _achievements : Array[MV_Profile_AchievementsData] = []
var _is_own : bool = true

func _ready() -> void:
	if not_linked_panel != null:
		not_linked_panel.meta_clicked.connect(_on_link_clicked)

func _on_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	Popups_Controller.instance.show_confirm(tr("POPUP_OPEN_BROWSER"), func(): OS.shell_open(url))

func load_achievements(user_id: int) -> void:
	_is_own = user_id == RpcModules.user.user_id
	NetworkHandler.profile.get_achievements(user_id, func(data):
		if data == null:
			_show_not_linked()
			return
		var linked : bool = data.get("linked", false)
		if not linked:
			_show_not_linked()
			return
		var total : int = int(data.get("totalPlayers", 0))
		var list : Array[MV_Profile_AchievementsData] = []
		for item in data.get("achievements", []):
			var ach := MV_Profile_AchievementsData.new()
			ach.title = item.get("title", "")
			ach.description = item.get("description", "")
			ach.percentage = _pct(int(item.get("numAwarded", 0)), total)
			ach.hardcore_percentage = _pct(int(item.get("numAwardedHardcore", 0)), total)
			ach.date = item.get("dateEarned", "") if item.get("dateEarned") != null else ""
			ach.unlocked = item.get("unlocked", false)
			ach.unlocked_hardcore = item.get("unlockedHardcore", false)
			ach.badge_url = _resolve_badge_url(item)
			list.append(ach)
		set_achievements(list)
	)

func _pct(awarded: int, total: int) -> float:
	if total <= 0:
		return 0.0
	return float(awarded) / float(total) * 100.0

func _resolve_badge_url(item: Dictionary) -> String:
	var direct : String = str(item.get("badgeUrl", ""))
	if direct != "":
		return direct
	var badge : String = str(item.get("badgeName", ""))
	if badge == "":
		return ""
	if item.get("unlocked", false):
		return BADGE_BASE + badge + ".png"
	return BADGE_BASE + badge + "_lock.png"

func set_achievements(data: Array[MV_Profile_AchievementsData]) -> void:
	_achievements = _sort_achievements(_filter_achievements(data))
	_rebuild()
	if _achievements.is_empty():
		_show_empty()
		return
	_show_achievements()

func _filter_achievements(data: Array[MV_Profile_AchievementsData]) -> Array[MV_Profile_AchievementsData]:
	if _is_own:
		return data
	var result : Array[MV_Profile_AchievementsData] = []
	for item in data:
		if item.unlocked:
			result.append(item)
	return result

func _sort_achievements(data: Array[MV_Profile_AchievementsData]) -> Array[MV_Profile_AchievementsData]:
	var unlocked : Array[MV_Profile_AchievementsData] = []
	var locked : Array[MV_Profile_AchievementsData] = []
	for item in data:
		if item.unlocked:
			unlocked.append(item)
		else:
			locked.append(item)
	unlocked.sort_custom(func(a, b): return a.date > b.date)
	locked.sort_custom(func(a, b): return a.percentage > b.percentage)
	var result : Array[MV_Profile_AchievementsData] = []
	result.append_array(unlocked)
	result.append_array(locked)
	return result

func _rebuild() -> void:
	for child in achievements_container.get_children():
		child.queue_free()
	for item in _achievements:
		var prefab : MV_Profile_AchievementPrefab = achievement_prefab.instantiate()
		achievements_container.add_child(prefab)
		prefab.setup(item)

func _show_not_linked() -> void:
	_show_message(tr(OWN_NOT_LINKED_TEXT) if _is_own else tr(OTHER_NOT_LINKED_TEXT))

func _show_empty() -> void:
	_show_message(tr(OWN_EMPTY_TEXT) if _is_own else tr(OTHER_EMPTY_TEXT))

func _show_message(text: String) -> void:
	if not_linked_panel != null:
		not_linked_panel.text = text
		not_linked_panel.show()
	achievements_container.hide()
	scroll.hide()

func _show_achievements() -> void:
	if not_linked_panel != null:
		not_linked_panel.hide()
	achievements_container.show()
	scroll.show()