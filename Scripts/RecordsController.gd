class_name RecordsController
extends RefCounted

signal record_sent(record: Dictionary)
signal record_stored_offline(record: Dictionary)
signal records_synced(count: int)

const PENDING_PATH := "user://pending_records.json"

var _status: InGameStatusController

func init(status: InGameStatusController) -> void:
	_status = status
	_status.record_finalized.connect(_on_record_finalized)

func _on_record_finalized(record: Dictionary) -> void:
	record["advanced"] = SettingsManager.settings.is_advanced_enabled()
	NetworkHandler.records.submit_record(record, func(code, _data):
		if code == 200 or code == 201:
			record_sent.emit(record)
		elif code == 400:
			Log.d("[record] invalid, discarded")
		else:
			_store_offline(record)
	)

func sync_pending() -> void:
	var pending := _load_pending()
	if pending.is_empty():
		return
	_sync_next(pending, 0, 0)

func _sync_next(pending: Array, idx: int, sent: int) -> void:
	if idx >= pending.size():
		_save_pending(_load_pending_unsent(pending))
		records_synced.emit(sent)
		return
	var record : Dictionary = pending[idx]
	if record.get("status", "") == "sent":
		_sync_next(pending, idx + 1, sent)
		return
	NetworkHandler.records.submit_record(record, func(code, _data):
		if code == 200 or code == 201:
			pending[idx]["status"] = "sent"
			_sync_next(pending, idx + 1, sent + 1)
		elif code == 400:
			pending[idx]["status"] = "discarded"
			_sync_next(pending, idx + 1, sent)
		else:
			_sync_next(pending, idx + 1, sent)
	)

func _store_offline(record: Dictionary) -> void:
	var pending := _load_pending()
	var entry := record.duplicate()
	entry["status"] = "not_sent"
	pending.append(entry)
	_save_pending(pending)
	record_stored_offline.emit(record)

func _load_pending() -> Array:
	if not FileAccess.file_exists(PENDING_PATH):
		return []
	var f := FileAccess.open(PENDING_PATH, FileAccess.READ)
	if f == null:
		return []
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_ARRAY:
		return []
	return data

func _load_pending_unsent(pending: Array) -> Array:
	var out := []
	for r in pending:
		var st : String = r.get("status", "")
		if st != "sent" and st != "discarded":
			out.append(r)
	return out

func _save_pending(pending: Array) -> void:
	var f := FileAccess.open(PENDING_PATH, FileAccess.WRITE)
	if f == null:
		Log.d("[records] cannot write pending")
		return
	f.store_string(JSON.stringify(pending))
	f.close()
