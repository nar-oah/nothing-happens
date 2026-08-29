extends Resource
class_name ConstitutionColumnDefinition

@export var display_name: String
@export_range(0, 9999, 1) var unlock_cost_months: int = 0
@export var articles: Array[ConstitutionArticleDefinition] = []
