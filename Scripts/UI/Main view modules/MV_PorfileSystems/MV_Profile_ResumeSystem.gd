class_name MV_Profile_ResumeSystem
extends Node

enum Status { ONLINE, AFK, BUSY, INGAME, OFFLINE }
enum Relation { NONE, PENDING_OUTGOING, PENDING_INCOMING, FRIEND }
const BIO_MAX_LENGTH : int = 120

signal status_changed(status: Status)
signal bio_changed(new_bio: String)
signal add_friend_requested()
signal remove_friend_requested()

@export var avatar_rect    : TextureRect
@export var username_label : Label
@export var bio_rich : RichTextLabel
@export var bio_edit : TextEdit
@export var status_dropdown: OptionButton
@export var add_friend_btn : Button
@export var remove_friend_btn : Button
@export var bio_warning_label : Label
@export var pending_label : Label
@export var background_rect: UserProfileUIBgSystem

var current_color : Color

var last_status: int;

var _setting_status := false
var _setting_bio_text : bool = false
var _editable : bool = true
var _current_bio : String = ""

func _ready() -> void:
	status_dropdown.item_selected.connect(_on_status_selected)
	bio_edit.focus_exited.connect(_on_bio_focus_lost)
	bio_edit.gui_input.connect(_on_bio_gui_input)
	bio_edit.text_changed.connect(_on_bio_text_changed)
	add_friend_btn.pressed.connect(func(): add_friend_requested.emit())
	remove_friend_btn.pressed.connect(func(): remove_friend_requested.emit())
	bio_rich.gui_input.connect(_enter_bio_edit)
	add_friend_btn.hide()
	remove_friend_btn.hide()
	bio_warning_label.hide()
	pending_label.hide()
	current_color = bio_rich.get_theme_color("default_color", "RichTextLabel")

func set_avatar(texture: Texture2D) -> void:
	avatar_rect.texture = texture

func set_username(username: String) -> void:
	username_label.text = username

func set_bio(bio: String) -> void:
	if bio == "" and _editable: 
		bio_rich.add_theme_color_override("default_color", Color.DARK_GRAY)
		bio = tr("PROFILE_BIO_EMPTY")
	else: bio_rich.add_theme_color_override("default_color", current_color)
	_current_bio = bio
	bio_rich.text = bio
	bio_edit.text = bio


func set_status(status: Status) -> void:
	_setting_status = true
	set_background(status)
	if status < status_dropdown.item_count:
		status_dropdown.select(status)
	_setting_status = false

func set_background(index: int) -> void:
	background_rect._change_active_status(index)

func set_editable(editable: bool) -> void:
	_editable = editable
	status_dropdown.visible = editable
	add_friend_btn.hide()
	remove_friend_btn.hide()
	pending_label.hide()
	bio_rich.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not editable:
		bio_edit.hide()
		bio_rich.show()
		bio_rich.mouse_default_cursor_shape = Control.CURSOR_ARROW

func set_friendship_state(is_friend: bool) -> void:
	if _editable:
		add_friend_btn.hide()
		remove_friend_btn.hide()
		return
	add_friend_btn.visible = not is_friend
	remove_friend_btn.visible = is_friend

func _enter_bio_edit(event : InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if not _editable: return
	if not _editable: return
	bio_edit.text = _current_bio
	bio_rich.hide()
	bio_edit.show()
	bio_edit.grab_focus()

func _on_bio_submitted(text: String) -> void:
	_commit_bio(text)

func _on_bio_text_changed() -> void:
	if _setting_bio_text: return
	var text := bio_edit.text
	if text.length() > BIO_MAX_LENGTH:
		var caret_line := bio_edit.get_caret_line()
		var caret_col := bio_edit.get_caret_column()
		_setting_bio_text = true
		bio_edit.text = text.substr(0, BIO_MAX_LENGTH)
		bio_edit.set_caret_line(caret_line)
		bio_edit.set_caret_column(min(caret_col, bio_edit.get_line(caret_line).length()))
		_setting_bio_text = false
		bio_warning_label.show()
	else:
		bio_warning_label.hide()
func _on_bio_focus_lost() -> void:
	_commit_bio(bio_edit.text)

func _commit_bio(text: String) -> void:
	if text.length() > BIO_MAX_LENGTH:
		bio_edit.text = _current_bio
		bio_warning_label.hide()
		return
	if text == _current_bio: return
	bio_changed.emit(text)

func _on_status_selected(index: int) -> void:
	if LauncherController.instance.EMULATOR_RUNNING: 
		status_dropdown.select(last_status)
		return
	if _setting_status: return
	last_status = index
	set_background(index)
	status_changed.emit(index as Status)

func _on_bio_rich_clicked(event: InputEvent) -> void:
	if not _editable: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		bio_rich.hide()
		bio_edit.text = _current_bio
		bio_edit.show()
		bio_edit.grab_focus()
		bio_edit.set_caret_column(bio_edit.text.length())

func _on_bio_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not event.shift_pressed:
		_commit_bio(bio_edit.text)
		bio_edit.release_focus()
		get_viewport().set_input_as_handled()

func set_relation(relation: Relation) -> void:
	if _editable:
		add_friend_btn.hide()
		remove_friend_btn.hide()
		pending_label.hide()
		return
	match relation:
		Relation.NONE:
			add_friend_btn.show()
			add_friend_btn.disabled = false
			remove_friend_btn.hide()
			pending_label.hide()
		Relation.PENDING_OUTGOING:
			add_friend_btn.hide()
			remove_friend_btn.hide()
			pending_label.text = tr("PROFILE_RELATION_PENDING")
			pending_label.show()
		Relation.PENDING_INCOMING:
			add_friend_btn.hide()
			remove_friend_btn.hide()
			pending_label.text = tr("PROFILE_RELATION_INCOMING")
			pending_label.show()
		Relation.FRIEND:
			add_friend_btn.hide()
			remove_friend_btn.show()
			pending_label.hide()

func _status_name(status: Status) -> String:
	match status:
		Status.ONLINE: return tr("BADGE_ONLINE")
		Status.AFK:    return tr("BADGE_AFK")
		Status.BUSY:   return tr("BADGE_BUSY")
		Status.INGAME: return tr("BADGE_INGAME")
		_:             return tr("BADGE_OFFLINE")
