extends Control

# Pantalla de inicio (escena inicial): título con "PULSA CUALQUIER TECLA" y, al pulsar, las tres
# ranuras de guardado. Elegir una la carga en GameState, tapa la pantalla con ScreenWipe y pasa al
# menú principal. Escape vuelve de las ranuras al título.

enum Phase { TITLE, SLOTS, CONFIRM, ENTERING }

const MAIN_MENU: PackedScene = preload("res://scenes/MainMenu.tscn")
# Fila de arriba del bloque del título; al salir las ranuras sube TITLE_RISE px mientras se desvanece.
const TITLE_Y: float = 168.0
const TITLE_RISE: float = 16.0
const TITLE_FADE_TIME: float = 0.35
const INTRO_FADE_TIME: float = 0.6
# Parpadeo de "PULSA CUALQUIER TECLA" (ciclo y parte encendida) y parpadeo rápido al pulsar.
const BLINK_PERIOD: float = 1.0
const BLINK_ON: float = 0.6
const ACK_BLINKS: int = 6
const ACK_BLINK_TIME: float = 0.05
const FADE_TIME: float = 0.2
# Entrada de las tarjetas: cada una se descubre de arriba abajo mientras llega desde la derecha.
const CARD_STAGGER: float = 0.09
const CARD_REVEAL_TIME: float = 0.24
const CARD_SLIDE: float = 16.0
const CONTENT_FADE_TIME: float = 0.15
# Botón de borrar, a la derecha de la tarjeta, y su cruz de píxeles.
const DELETE_GAP: int = 9
const DELETE_SIZE: Vector2 = Vector2(36, 36)
const CROSS_SIZE: int = 10
# Entrar: destellos de la tarjeta, tapado desde ella, pausa en negro y destapado del menú.
const ENTER_FLASHES: int = 3
const ENTER_FLASH_TIME: float = 0.07
const COVER_TIME: float = 0.7
const HOLD_TIME: float = 0.15
const UNCOVER_TIME: float = 0.6

@onready var title_block: VBoxContainer = $TitleBlock
@onready var press_key_label: Label = $PressKeyLabel
@onready var slots_screen: Control = $SlotsScreen
@onready var slots_panel: OverlayFrame = %SlotsPanel
@onready var slot_list: VBoxContainer = %SlotList
@onready var hint_label: Label = %HintLabel
@onready var confirm_layer: Control = $ConfirmLayer
@onready var confirm_message: Label = %ConfirmMessage
@onready var input_blocker: Control = $InputBlocker

var _phase: Phase = Phase.TITLE
# Hay una animación en marcha: se ignoran teclas y el bloqueador para el ratón.
var _busy: bool = false
var _blinking: bool = true
var _blink_time: float = 0.0
var _cards: Array[SlotCard] = []
var _delete_buttons: Array[Button] = []
# Hijo de cada hueco de la lista: se mueve libre del contenedor para la entrada deslizada.
var _rows: Array[Control] = []
var _pending_delete: int = 0

func _ready() -> void:
	_build_slots()
	_fix_danger_pressed(%ConfirmDeleteButton)
	$ConfirmLayer/Dim.gui_input.connect(_on_dim_gui_input)
	slots_screen.hide()
	confirm_layer.hide()
	input_blocker.hide()
	_set_title_y(TITLE_Y)
	title_block.modulate.a = 0.0
	press_key_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title_block, "modulate:a", 1.0, INTRO_FADE_TIME)
	tween.tween_property(press_key_label, "modulate:a", 1.0, FADE_TIME)

func _process(delta: float) -> void:
	if _blinking:
		_blink_time += delta
		press_key_label.visible = fmod(_blink_time, BLINK_PERIOD) < BLINK_ON

func _input(event: InputEvent) -> void:
	if _busy:
		return
	match _phase:
		Phase.TITLE:
			if _is_any_press(event):
				get_viewport().set_input_as_handled()
				_show_slots()
		Phase.SLOTS:
			if event.is_action_pressed(&"ui_cancel"):
				get_viewport().set_input_as_handled()
				_show_title()
		Phase.CONFIRM:
			if event.is_action_pressed(&"ui_cancel"):
				get_viewport().set_input_as_handled()
				_close_confirm()

# Cualquier tecla, clic (sin la rueda) o botón de mando.
func _is_any_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	if event is InputEventJoypadButton:
		return event.pressed
	return false

func _build_slots() -> void:
	for slot: int in range(1, GameState.SLOT_COUNT + 1):
		var holder: Control = Control.new()
		holder.name = "Slot%d" % slot
		holder.custom_minimum_size = Vector2(SlotCard.CARD_SIZE.x + DELETE_GAP + DELETE_SIZE.x, SlotCard.CARD_SIZE.y)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_list.add_child(holder)
		var row: Control = Control.new()
		row.name = "Row"
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(row)
		var card: SlotCard = SlotCard.new()
		card.name = "Card"
		card.slot = slot
		card.pressed.connect(_enter_slot.bind(card))
		row.add_child(card)
		var delete: Button = Button.new()
		delete.name = "DeleteButton"
		delete.theme_type_variation = &"DangerButton"
		delete.focus_mode = Control.FOCUS_NONE
		delete.custom_minimum_size = DELETE_SIZE
		delete.size = DELETE_SIZE
		delete.position = Vector2(SlotCard.CARD_SIZE.x + DELETE_GAP, roundf((SlotCard.CARD_SIZE.y - DELETE_SIZE.y) / 2.0))
		delete.draw.connect(_draw_cross.bind(delete))
		delete.pressed.connect(_open_confirm.bind(slot))
		row.add_child(delete)
		_fix_danger_pressed(delete)
		_cards.append(card)
		_delete_buttons.append(delete)
		_rows.append(row)

# DangerButton no tiene estilo para pulsado con el ratón encima: se usa su hover (rojo, no cian).
func _fix_danger_pressed(button: Button) -> void:
	button.add_theme_stylebox_override(&"hover_pressed", button.get_theme_stylebox(&"hover"))
	button.add_theme_color_override(&"font_hover_pressed_color", button.get_theme_color(&"font_hover_color"))

# Cruz de píxeles de 2 px de grueso, en el color del texto del botón.
func _draw_cross(button: Button) -> void:
	var color: Color = button.get_theme_color(&"font_hover_color" if button.is_hovered() else &"font_color")
	var origin: Vector2i = Vector2i((button.size - Vector2(CROSS_SIZE, CROSS_SIZE)) / 2.0)
	for i: int in CROSS_SIZE - 1:
		button.draw_rect(Rect2(origin.x + i, origin.y + i, 2, 2), color)
		button.draw_rect(Rect2(origin.x + CROSS_SIZE - 2 - i, origin.y + i, 2, 2), color)

func _refresh_slots() -> void:
	for i: int in _cards.size():
		_cards[i].set_summary(GameState.get_slot_summary(i + 1))
		_delete_buttons[i].visible = _cards[i].has_save()

func _show_slots() -> void:
	_phase = Phase.SLOTS
	_set_busy(true)
	_blinking = false
	var ack: Tween = create_tween()
	for i: int in ACK_BLINKS:
		ack.tween_callback(func() -> void: press_key_label.visible = not press_key_label.visible)
		ack.tween_interval(ACK_BLINK_TIME)
	ack.tween_callback(press_key_label.hide)
	await _fade_title(false)
	_refresh_slots()
	slots_screen.modulate.a = 1.0
	slots_panel.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	for i: int in _cards.size():
		_hide_card(i)
	slots_screen.show()
	create_tween().tween_property(slots_panel, "modulate:a", 1.0, FADE_TIME)
	await _reveal_cards(range(_cards.size()), FADE_TIME * 0.5)
	create_tween().tween_property(hint_label, "modulate:a", 1.0, FADE_TIME)
	_set_busy(false)

func _show_title() -> void:
	_phase = Phase.TITLE
	_set_busy(true)
	var fade: Tween = create_tween()
	fade.tween_property(slots_screen, "modulate:a", 0.0, FADE_TIME)
	await fade.finished
	slots_screen.hide()
	await _fade_title(true)
	_blink_time = 0.0
	_blinking = true
	_set_busy(false)

# El título se desvanece subiendo (o aparece bajando a su sitio).
func _fade_title(appear: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_method(_set_title_y, title_block.position.y, TITLE_Y if appear else TITLE_Y - TITLE_RISE,
			TITLE_FADE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if appear else Tween.EASE_IN)
	tween.tween_property(title_block, "modulate:a", 1.0 if appear else 0.0, TITLE_FADE_TIME)
	await tween.finished

func _hide_card(i: int) -> void:
	_rows[i].position.x = CARD_SLIDE
	_cards[i].reveal = 0.0
	_cards[i].content_alpha = 0.0
	_delete_buttons[i].modulate.a = 0.0

# Entrada escalonada de las tarjetas `indices`: llegan deslizándose, se descubren con una línea de
# escaneo y después aparecen sus textos y su botón de borrar.
func _reveal_cards(indices: Array, start_delay: float) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	for n: int in indices.size():
		var i: int = indices[n]
		var delay: float = start_delay + n * CARD_STAGGER
		_hide_card(i)
		tween.tween_method(_set_row_x.bind(_rows[i]), CARD_SLIDE, 0.0, CARD_REVEAL_TIME) \
				.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_cards[i], "reveal", 1.0, CARD_REVEAL_TIME).set_delay(delay)
		tween.tween_property(_cards[i], "content_alpha", 1.0, CONTENT_FADE_TIME).set_delay(delay + CARD_REVEAL_TIME)
		tween.tween_property(_delete_buttons[i], "modulate:a", 1.0, CONTENT_FADE_TIME).set_delay(delay + CARD_REVEAL_TIME)
	await tween.finished

# Las posiciones animadas se redondean para que el pixel art no caiga entre píxeles.
func _set_title_y(y: float) -> void:
	title_block.position.y = roundf(y)

func _set_row_x(x: float, row: Control) -> void:
	row.position.x = roundf(x)

func _set_busy(busy: bool) -> void:
	_busy = busy
	input_blocker.visible = busy

func _open_confirm(slot: int) -> void:
	if _busy or _phase != Phase.SLOTS:
		return
	_pending_delete = slot
	confirm_message.text = tr("START_CONFIRM_DELETE") % slot
	_phase = Phase.CONFIRM
	confirm_layer.modulate.a = 0.0
	confirm_layer.show()
	create_tween().tween_property(confirm_layer, "modulate:a", 1.0, FADE_TIME)

func _close_confirm() -> void:
	_phase = Phase.SLOTS
	var tween: Tween = create_tween()
	tween.tween_property(confirm_layer, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(confirm_layer.hide)

# Clic fuera de la caja de confirmación: como cancelar.
func _on_dim_gui_input(event: InputEvent) -> void:
	if _phase == Phase.CONFIRM and event is InputEventMouseButton and event.pressed:
		_close_confirm()

func _on_confirm_delete_pressed() -> void:
	if _phase != Phase.CONFIRM:
		return
	GameState.delete_slot(_pending_delete)
	_close_confirm()
	_refresh_slots()
	_set_busy(true)
	await _reveal_cards([_pending_delete - 1], FADE_TIME)
	_set_busy(false)

func _on_confirm_cancel_pressed() -> void:
	if _phase == Phase.CONFIRM:
		_close_confirm()

func _enter_slot(card: SlotCard) -> void:
	if _busy or _phase != Phase.SLOTS:
		return
	_phase = Phase.ENTERING
	_set_busy(true)
	var is_new: bool = not GameState.has_save(card.slot)
	GameState.load_slot(card.slot)
	if is_new:
		# La ranura queda ocupada desde que se entra, aunque aún no se haya jugado.
		GameState.flush()
	# Todo menos la tarjeta elegida se apaga mientras ella destella.
	var fade: Tween = create_tween().set_parallel(true)
	fade.tween_property(hint_label, "modulate:a", 0.0, FADE_TIME)
	fade.tween_property(%SlotsHeader, "modulate:a", 0.0, FADE_TIME)
	for i: int in _cards.size():
		fade.tween_property(_delete_buttons[i], "modulate:a", 0.0, FADE_TIME)
		if _cards[i] != card:
			fade.tween_property(_rows[i], "modulate:a", 0.0, FADE_TIME)
	var flash: Tween = create_tween()
	for i: int in ENTER_FLASHES:
		flash.tween_property(card, "flash", 1.0, ENTER_FLASH_TIME)
		flash.tween_property(card, "flash", 0.0, ENTER_FLASH_TIME)
	flash.tween_property(card, "flash", 1.0, ENTER_FLASH_TIME)
	await flash.finished
	var wipe: ScreenWipe = ScreenWipe.new()
	get_tree().root.add_child(wipe)
	await wipe.cover(card.get_global_rect().get_center(), COVER_TIME)
	await get_tree().create_timer(HOLD_TIME).timeout
	var center: Vector2 = get_viewport_rect().size / 2.0
	_open_main_menu()
	wipe.uncover(center, UNCOVER_TIME)

func _open_main_menu() -> void:
	var menu: Node = MAIN_MENU.instantiate()
	var tree: SceneTree = get_tree()
	tree.root.add_child(menu)
	tree.current_scene = menu
	queue_free()
