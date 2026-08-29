extends RefCounted
class_name MetaProgressionState

var available_governing_months: int = 0
var lifetime_governing_months: int = 0
var unlocked_constitution_columns: Dictionary[ConstitutionColumnDefinition, bool] = {}


func add_governing_months(months: int) -> void:
	var amount := maxi(months, 0)
	available_governing_months += amount
	lifetime_governing_months += amount


func is_column_unlocked(column: ConstitutionColumnDefinition) -> bool:
	if column == null:
		return false
	return column.unlock_cost_months == 0 or unlocked_constitution_columns.has(column)


func can_unlock_column(
	board: ConstitutionBoardDefinition, column: ConstitutionColumnDefinition
) -> bool:
	if board == null or column == null or column not in board.columns:
		return false
	if is_column_unlocked(column) or available_governing_months < column.unlock_cost_months:
		return false
	var center := board.get_center_column_index()
	var index := board.columns.find(column)
	if center < 0 or index == center:
		return false
	var inward_index := index + 1 if index < center else index - 1
	return inward_index == center or is_column_unlocked(board.columns[inward_index])


func unlock_column(
	board: ConstitutionBoardDefinition, column: ConstitutionColumnDefinition
) -> bool:
	if not can_unlock_column(board, column):
		return false
	available_governing_months -= column.unlock_cost_months
	unlocked_constitution_columns[column] = true
	return true
