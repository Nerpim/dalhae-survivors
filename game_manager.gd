extends Node
# GameManager - 게임 전역 관리자
# 모든 씬에서 GameManager.xxx 로 접근 가능

# ==================== 현재 플레이 데이터 ====================
# 한 판 진행 중에만 쓰이는 데이터 (다시 시작하면 리셋)

var current_run := {
	"kills": 0,              # 이번 판 처치 수
	"survived_time": 0.0,    # 이번 판 생존 시간
	"player_level": 1,       # 이번 판 최종 레벨
	"damage_dealt": 0,       # 이번 판 총 데미지
	"stage_cleared": false   # 이번 판 클리어 여부
}

# ==================== 누적 통계 ====================
# 여러 판을 거쳐 쌓이는 데이터 (저장/불러오기 대상)

var total_stats := {
	"total_playtime": 0.0,       # 총 플레이 시간
	"total_kills": 0,            # 누적 처치 수
	"total_runs": 0,             # 총 플레이 횟수
	"total_clears": 0,           # 총 클리어 횟수
	"highest_level": 1,          # 최고 도달 레벨
	"longest_survived": 0.0      # 최장 생존 시간
}

# ==================== 설정 ====================
var settings := {
	"bgm_volume": 0.8,
	"sfx_volume": 1.0,
	"master_volume": 1.0
}

# ==================== 신호 ====================
# 전역 이벤트들 - 어디서든 연결/발생 가능
signal enemy_killed(enemy_type: String)
signal player_leveled_up(new_level: int)
signal stage_cleared
signal player_died


# ==================== 함수 ====================

func _ready() -> void:
	print("GameManager 준비 완료")


# 새 게임 시작할 때 호출 (current_run 리셋)
func start_new_run() -> void:
	current_run = {
		"kills": 0,
		"survived_time": 0.0,
		"player_level": 1,
		"damage_dealt": 0,
		"stage_cleared": false
	}
	total_stats.total_runs += 1
	print("[GM] 새 게임 시작 (총 ", total_stats.total_runs, "회)")


# 적 처치 시 호출
func on_enemy_killed(enemy_type: String = "kkomak") -> void:
	current_run.kills += 1
	total_stats.total_kills += 1
	enemy_killed.emit(enemy_type)
	# print("[GM] 처치: ", enemy_type, " | 이번 판: ", current_run.kills, " | 누적: ", total_stats.total_kills)


# 플레이어 레벨업 시 호출
func on_player_level_up(new_level: int) -> void:
	current_run.player_level = new_level
	if new_level > total_stats.highest_level:
		total_stats.highest_level = new_level
	player_leveled_up.emit(new_level)
	print("[GM] 레벨업! Lv.", new_level)


# 스테이지 클리어 시 호출
func on_stage_cleared() -> void:
	current_run.stage_cleared = true
	total_stats.total_clears += 1
	_update_best_records()
	stage_cleared.emit()
	print("[GM] 스테이지 클리어! 결과: ", current_run)


# 플레이어 사망 시 호출
func on_player_died() -> void:
	_update_best_records()
	player_died.emit()
	print("[GM] 사망. 이번 판 결과: ", current_run)


# 기록 갱신
func _update_best_records() -> void:
	if current_run.survived_time > total_stats.longest_survived:
		total_stats.longest_survived = current_run.survived_time


# 시간 업데이트 (StageManager에서 매 프레임 호출)
func update_playtime(delta: float) -> void:
	current_run.survived_time += delta
	total_stats.total_playtime += delta
