extends Node

# BGM 파일들
@onready var bgm_main_stream: AudioStream = preload("res://audio/bgm_main.mp3")
@onready var bgm_game_stream: AudioStream = preload("res://audio/bgm_game.mp3")

# 오디오 플레이어 (동적으로 만듦)
var player: AudioStreamPlayer

# 현재 재생 중인 BGM 타입
enum BGMType { NONE, MAIN, GAME }
var current_bgm: BGMType = BGMType.NONE

func _ready() -> void:
	# 오디오 플레이어 노드 만들기
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = -10.0  # 기본 볼륨 (0이 최대, -80이 최소)
	add_child(player)
	print("BGMManager 준비 완료")


# 메인 화면 BGM 재생
func play_main() -> void:
	if current_bgm == BGMType.MAIN:
		return  # 이미 재생 중이면 무시
	current_bgm = BGMType.MAIN
	player.stream = bgm_main_stream
	player.play()
	print("[BGM] 메인 음악 재생")


# 게임 BGM 재생
func play_game() -> void:
	if current_bgm == BGMType.GAME:
		return  # 이미 재생 중이면 무시
	current_bgm = BGMType.GAME
	player.stream = bgm_game_stream
	player.play()
	print("[BGM] 게임 음악 재생")


# 정지
func stop() -> void:
	current_bgm = BGMType.NONE
	player.stop()


# 볼륨 조절 (0.0 ~ 1.0)
func set_volume(value: float) -> void:
	# linear 0~1 을 dB로 변환
	if value <= 0.0:
		player.volume_db = -80.0  # 음소거
	else:
		player.volume_db = linear_to_db(value)
