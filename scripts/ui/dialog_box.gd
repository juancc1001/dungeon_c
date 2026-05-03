extends CanvasLayer

signal dialog_closed

const TYPING_SPEED := 0.04
const WORDS_PER_MINUTE := 200.0
const MIN_READING_TIME := 2.0
const IDLE_TEXT := "..."
const AVATAR_TEXTURE := preload("res://assets/icons/ojo.png")
const AVATAR_SIZE := Vector2(45, 45)
const AVATAR_GAP := 8.0

var _lines: Array = []
var _current_line: int = 0
var _tween: Tween = null

var _panel: PanelContainer
var _avatar: TextureRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _continue_label: Label

func _ready():
	layer = 10
	_build_ui()
	_enter_idle()

func _build_ui():
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.35
	_panel.anchor_right = 0.65
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_top = 14
	_panel.offset_bottom = 100
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.08, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.55, 0.25, 0.75)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_avatar = TextureRect.new()
	_avatar.texture = AVATAR_TEXTURE
	_avatar.custom_minimum_size = AVATAR_SIZE
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar.anchor_left = _panel.anchor_left
	_avatar.anchor_right = _panel.anchor_left
	_avatar.anchor_top = 0.0
	_avatar.anchor_bottom = 0.0
	_avatar.offset_right = -AVATAR_GAP
	_avatar.offset_left = -AVATAR_GAP - AVATAR_SIZE.x
	_avatar.offset_top = _panel.offset_top
	_avatar.offset_bottom = _panel.offset_top + AVATAR_SIZE.y
	_avatar.hide()
	add_child(_avatar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_panel.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color(0.95, 0.7, 1.0))
	_speaker_label.hide()
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.custom_minimum_size = Vector2(0, 36)
	_text_label.add_theme_font_size_override("normal_font_size", 12)
	_text_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95))
	vbox.add_child(_text_label)

	_continue_label = Label.new()
	_continue_label.text = "[ K — Saltar ]"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_label.add_theme_font_size_override("font_size", 9)
	_continue_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_continue_label.hide()
	vbox.add_child(_continue_label)

func show_dialog(lines: Array, speaker: String = ""):
	if lines.is_empty():
		return
	_lines = lines
	_current_line = 0
	if speaker.is_empty():
		_speaker_label.hide()
	else:
		_speaker_label.text = speaker
		_speaker_label.show()
	_avatar.show()
	_show_current_line()

func _show_current_line():
	if _current_line >= _lines.size():
		_close()
		return
	var line_text := str(_lines[_current_line])
	_text_label.text = line_text
	_text_label.visible_characters = 0
	_continue_label.show()

	if _tween and _tween.is_valid():
		_tween.kill()
	var total_chars: int = _text_label.get_total_character_count()
	var typing_duration: float = total_chars * TYPING_SPEED
	var reading_duration: float = max(_count_words(line_text) / WORDS_PER_MINUTE * 60.0, MIN_READING_TIME)

	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_characters", total_chars, typing_duration)
	_tween.tween_interval(reading_duration)
	_tween.tween_callback(advance)

func advance():
	if _tween and _tween.is_valid():
		_tween.kill()
	_current_line += 1
	if _current_line >= _lines.size():
		_close()
	else:
		_show_current_line()

func _close():
	if _tween and _tween.is_valid():
		_tween.kill()
	_lines = []
	_current_line = 0
	_enter_idle()
	dialog_closed.emit()

func _enter_idle():
	_speaker_label.hide()
	_continue_label.hide()
	if _avatar:
		_avatar.hide()
	_text_label.text = IDLE_TEXT
	_text_label.visible_characters = -1

func is_dialog_active() -> bool:
	return not _lines.is_empty()

func _count_words(s: String) -> int:
	var stripped := s.strip_edges()
	if stripped.is_empty():
		return 0
	return stripped.split(" ", false).size()

func _unhandled_input(event):
	if not is_dialog_active():
		return
	if event.is_action_pressed("dialog_skip"):
		advance()
		get_viewport().set_input_as_handled()
