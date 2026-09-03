extends RaceDefinition
class_name PeachRaceDefinition

# The first Peach seat uses this weight. Each following Peach seat halves it and rounds
# upward, with a floor of 1. The voting behavior itself is intentionally not implemented
# in this structural commit.
@export_range(1, 999, 1) var max_elder_weight: int = 1
