extends Node

signal dialog_started
signal dialog_ended

const DIALOG_DATA_PATH := "res://resources/dialogs/dialogs.json"
const WELCOME_DIALOG_ID := "welcome"

var is_active: bool = false

var _box: CanvasLayer = null
var _dialogs: Dictionary = {}

func _ready():
	_load_dialogs()
	var DialogBoxScript = load("res://scripts/ui/dialog_box.gd")
	_box = DialogBoxScript.new()
	_box.name = "DialogBox"
	_box.dialog_closed.connect(_on_closed)
	get_tree().root.call_deferred("add_child", _box)
	call_deferred("_show_welcome")

func _load_dialogs():
	if not FileAccess.file_exists(DIALOG_DATA_PATH):
		push_warning("DialogManager: no se encontró ", DIALOG_DATA_PATH)
		return
	var f := FileAccess.open(DIALOG_DATA_PATH, FileAccess.READ)
	if f == null:
		push_warning("DialogManager: no se pudo abrir ", DIALOG_DATA_PATH)
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("DialogManager: JSON inválido en ", DIALOG_DATA_PATH)
		return
	_dialogs = parsed

func _show_welcome():
	if _dialogs.has(WELCOME_DIALOG_ID):
		show_dialog_by_id(WELCOME_DIALOG_ID)

func show_dialog(lines: Array, speaker: String = ""):
	if is_active:
		return
	if lines.is_empty():
		return
	is_active = true
	_box.show_dialog(lines, speaker)
	dialog_started.emit()

func show_dialog_by_id(id: String):
	if not _dialogs.has(id):
		push_warning("DialogManager: id desconocido '", id, "'")
		return
	var entry: Dictionary = _dialogs[id]
	var lines: Array = entry.get("lines", [])
	var speaker: String = entry.get("speaker", "")
	show_dialog(lines, speaker)

func _on_closed():
	is_active = false
	dialog_ended.emit()
