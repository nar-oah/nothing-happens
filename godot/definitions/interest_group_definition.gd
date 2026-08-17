extends Resource
class_name InterestGroupDefinition

@export var id: StringName
@export var display_name: String
@export_range(1, 999, 1) var base_column_weight: int = 1
@export var fixed_sort_order: int = 0
@export var proposal_definition: ProposalDefinition
