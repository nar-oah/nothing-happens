extends Node
class_name RunSession

@export_group("配置")
@export var balance: GameBalanceDefinition
@export var constitution_board: ConstitutionBoardDefinition = preload("res://data/constitutions/constitution_board.tres")

@export_group("游戏内容")
@export var race_definitions: Array[RaceDefinition] = []
@export var interest_groups: Array[InterestGroupDefinition] = []
@export var seat_definitions: Array[SeatDefinition] = []
@export var constitution_articles: Array[ConstitutionArticleDefinition] = []
@export var newspaper_front_definitions: Array[NewspaperFrontDefinition] = [
	preload("res://data/newspaper_fronts/无公开事件.tres"),
	preload("res://data/newspaper_fronts/新任开议.tres"),
	preload("res://data/newspaper_fronts/法案通过.tres"),
	preload("res://data/newspaper_fronts/政策触发.tres"),
	preload("res://data/newspaper_fronts/崩溃预期50.tres"),
	preload("res://data/newspaper_fronts/崩溃预期80.tres"),
	preload("res://data/newspaper_fronts/崩溃预期90.tres"),
]

var save_directory: String = "user://saves"
var autosave_enabled: bool = true
var last_save_error: Dictionary = {}

var state: RunState
var meta_progression := MetaProgressionState.new()
var context: RunContext
var time_system: TimeSystem
var random_system: RandomSystem
var proposal_system: ProposalSystem
var market_system: MarketSystem
var policy_system: PolicySystem
var inflation_system: InflationSystem
var parliament_system: ParliamentSystem
var race_system: RaceSystem
var draft_bill_system: DraftBillSystem
var vote_system: VoteSystem
var event_system: EventSystem
var constitution_system: ConstitutionSystem
var collapse_system: CollapseSystem
var annual_settlement_system: AnnualSettlementSystem
var flow_controller: FlowController
var term_report: Dictionary = {}
var _last_awarded_term: int = 0
var _previous_newspaper_collapse: int = 0


func configure_content(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	seats: Array[SeatDefinition],
	articles: Array[ConstitutionArticleDefinition] = [],
	board: ConstitutionBoardDefinition = null
) -> void:
	race_definitions = races
	interest_groups = groups
	seat_definitions = seats
	constitution_board = board
	constitution_articles = board.get_articles() if board != null else articles


func start_new_run() -> void:
	term_report.clear()
	_last_awarded_term = 0
	if _start_term(1) and autosave_enabled and not FileAccess.file_exists(save_directory.path_join("auto.json")):
		save_automatically()


func _start_term(term_number: int) -> bool:
	if balance == null:
		push_error("RunSession requires GameBalanceDefinition.")
		return false
	if race_definitions.is_empty():
		push_error("RunSession requires race definitions.")
		return false
	if interest_groups.is_empty():
		push_error("RunSession requires interest group definitions.")
		return false
	if seat_definitions.is_empty():
		push_error("RunSession requires seat definitions.")
		return false
	if constitution_board != null:
		constitution_articles = constitution_board.get_articles()
	state = RunState.new()
	state.term = maxi(term_number, 1)
	state.political_donation_pool = balance.initial_political_donation_pool
	var previous_rng: Variant = random_system.rng.state if term_number > 1 and random_system != null else null
	_build_runtime()
	if previous_rng != null:
		random_system.rng.state = previous_rng
	inflation_system.initialize_metrics(state.metrics, balance)
	state.year_start_metrics = state.metrics.copy()
	if not race_system.initialize_races(state, race_definitions, balance):
		return false
	if not parliament_system.initialize_seats(state, seat_definitions, race_definitions):
		return false
	if not constitution_system.initialize(context):
		return false
	constitution_system.run_effects(context, ConstitutionEffect.Timing.BEFORE_SEAT_ALLOCATION)
	var allocated := (
		race_system.allocate_opening_seats(context)
		if constitution_board != null
		else race_system.allocate_annual_seats(context)
	)
	if not allocated:
		push_error("Failed to allocate opening race seats.")
		return false
	constitution_system.run_effects(context, ConstitutionEffect.Timing.AFTER_SEAT_ALLOCATION)
	if not parliament_system.initialize_base_groups(context, interest_groups):
		return false
	constitution_system.run_effects(context, ConstitutionEffect.Timing.AFTER_GROUP_ALLOCATION)
	constitution_system.run_effects(context, ConstitutionEffect.Timing.ON_ACTIVATE)
	race_system.rebuild_annual_expectations(context)
	_previous_newspaper_collapse = state.collapse_level
	return true


func _build_runtime() -> void:
	time_system = TimeSystem.new()
	random_system = RandomSystem.new()
	proposal_system = ProposalSystem.new()
	market_system = MarketSystem.new()
	policy_system = PolicySystem.new()
	inflation_system = InflationSystem.new()
	parliament_system = ParliamentSystem.new()
	race_system = RaceSystem.new()
	draft_bill_system = DraftBillSystem.new()
	vote_system = VoteSystem.new()
	event_system = EventSystem.new()
	constitution_system = ConstitutionSystem.new()
	collapse_system = CollapseSystem.new()
	annual_settlement_system = AnnualSettlementSystem.new()
	context = RunContext.new()
	context.setup(
		state,
		balance,
		time_system,
		random_system,
		proposal_system,
		market_system,
		policy_system,
		inflation_system,
		parliament_system,
		race_system,
		draft_bill_system,
		vote_system,
		event_system,
		constitution_system,
		collapse_system,
		annual_settlement_system
	)
	context.race_definitions = race_definitions
	context.interest_groups = interest_groups
	context.seat_definitions = seat_definitions
	context.constitution_board = constitution_board
	context.constitution_articles = constitution_articles
	context.meta_progression = meta_progression
	flow_controller = FlowController.new()
	flow_controller.setup(context)


func advance_month() -> bool:
	var advanced := true if state.run_phase == RunState.RunPhase.TERM_ENDED else flow_controller.advance_month()
	if not advanced:
		return false
	if state.run_phase != RunState.RunPhase.TERM_ENDED:
		_resolve_newspaper_front(state)
	if state.run_phase == RunState.RunPhase.TERM_ENDED and not _settle_and_start_next_term():
		return false
	if autosave_enabled:
		save_automatically()
	return true


func start_next_term() -> bool:
	if state == null or state.run_phase != RunState.RunPhase.TERM_ENDED:
		return false
	if not _settle_and_start_next_term():
		return false
	if autosave_enabled:
		save_automatically()
	return true


func clear_term_report() -> void:
	term_report.clear()


func list_saves() -> Array[Dictionary]:
	return RunSaveStore.list_saves(save_directory)


func create_manual_save() -> Dictionary:
	return _save_result(RunSaveStore.create_manual(self))


func overwrite_manual_save(slot_id: String) -> Dictionary:
	return _save_result(RunSaveStore.overwrite_manual(self, slot_id))


func save_automatically() -> Dictionary:
	return _save_result(RunSaveStore.write_save(self, RunSaveStore.AUTO_SLOT))


func load_save(slot_id: String) -> Dictionary:
	var saved := RunSaveStore.read_save(save_directory, slot_id)
	if not saved["ok"]:
		return saved
	var restored := RunSnapshot.decode(saved["snapshot"])
	if not restored["ok"]:
		return {"ok": false, "error": {"code": "invalid_snapshot", "message": "无法恢复存档状态或资源引用。"}}
	state = restored["state"]
	meta_progression = restored["meta_progression"]
	var session_data: Dictionary = restored["session"]
	term_report = session_data["term_report"]
	_last_awarded_term = session_data["_last_awarded_term"]
	_previous_newspaper_collapse = session_data["_previous_newspaper_collapse"]
	_build_runtime()
	random_system.rng.state = restored["rng_state"]
	last_save_error.clear()
	return {"ok": true, "slot_id": slot_id}


func _save_result(result: Dictionary) -> Dictionary:
	last_save_error = {} if result["ok"] else result["error"]
	return result


func _settle_and_start_next_term() -> bool:
	var ended_state := state
	var previous_governing_months := meta_progression.available_governing_months
	if _last_awarded_term != ended_state.term:
		var elapsed_months := maxi((ended_state.year - 1) * 12 + ended_state.month, 0)
		meta_progression.add_governing_months(elapsed_months)
		_last_awarded_term = ended_state.term
	term_report = {
		"outcome": ended_state.term_outcome,
		"previous_governing_months": previous_governing_months,
		"current_governing_months": meta_progression.available_governing_months,
	}
	return _start_term(ended_state.term + 1)


func unlock_constitution_column(column: ConstitutionColumnDefinition) -> bool:
	return meta_progression.unlock_column(constitution_board, column)


func enact_bill(draft: DraftBillState) -> void:
	flow_controller.enact_bill(draft)


func submit_draft(bribed_seat_indices: Array[int] = []) -> VoteResultState:
	return flow_controller.submit_draft(state.draft_bill, bribed_seat_indices)


func start_new_bill(title: String = "") -> void:
	draft_bill_system.start_new_bill(state, title)


func edit_saved_bill(saved_index: int) -> bool:
	return draft_bill_system.load_saved_bill_for_editing(context, saved_index)


func cancel_bill_editing() -> void:
	draft_bill_system.cancel_editing(state)


func revise_constitution(article: ConstitutionArticleDefinition) -> bool:
	return constitution_system.revise(context, article)


func use_petition(event: EventState = null) -> bool:
	return parliament_system.use_petition(context, event)


func accept_proposal_trait(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, true)


func convert_proposal_trait_to_donation(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, false)


func _resolve_newspaper_front(current_state: RunState) -> void:
	current_state.newspaper_front.clear()
	for definition in newspaper_front_definitions:
		if definition == null:
			continue
		var result: Variant = definition.resolve(
			current_state,
			balance,
			_previous_newspaper_collapse
		)
		if result is Dictionary and not result.is_empty():
			current_state.newspaper_front = result.duplicate(true)
	current_state.newspaper_pending_bill = null
	current_state.newspaper_triggered_policies.clear()
	_previous_newspaper_collapse = current_state.collapse_level
