extends Control

# 시그널: 무기 선택했을 때 Player에 알림
signal weapon_selected(weapon_id: String)

# 노드 레퍼런스
@onready var card1: PanelContainer = $CardContainer/Card
@onready var card2: PanelContainer = $CardContainer/Card2
@onready var card3: PanelContainer = $CardContainer/Card3

# 각 카드가 대표하는 무기 id
var card_weapons: Array = ["", "", ""]

func _ready() -> void:
	# 게임 일시정지 상태에서도 이 화면은 작동하도록
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# 각 카드 버튼에 클릭 시그널 연결
	card1.get_node("Button").pressed.connect(_on_card_pressed.bind(0))
	card2.get_node("Button").pressed.connect(_on_card_pressed.bind(1))
	card3.get_node("Button").pressed.connect(_on_card_pressed.bind(2))
	
	# 처음엔 숨김
	hide()

# 레벨업 시 호출: 3개 무기 제시
func show_options(weapon_choices: Array) -> void:
	# weapon_choices는 [{id, name, description}, ...] 형태의 딕셔너리 배열
	var cards = [card1, card2, card3]
	
	for i in 3:
		var choice = weapon_choices[i]
		card_weapons[i] = choice.id
		
		var name_label = cards[i].get_node("VBoxContainer/WeaponName")
		var desc_label = cards[i].get_node("VBoxContainer/Description")
		
		name_label.text = choice.name
		desc_label.text = choice.description
	
	# 게임 일시정지 + 화면 표시
	get_tree().paused = true
	show()

func _on_card_pressed(card_index: int) -> void:
	var selected_id = card_weapons[card_index]
	weapon_selected.emit(selected_id)
	
	# 게임 재개 + 화면 숨김
	get_tree().paused = false
	hide()
