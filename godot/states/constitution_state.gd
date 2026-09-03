extends RefCounted
class_name ConstitutionState

var active_articles: Dictionary[ConstitutionRowDefinition, ConstitutionArticleDefinition] = {}
var revision_available: bool = true
var terminal_article: ConstitutionArticleDefinition
# Canonical group -> canonical merger destination. All group comparisons resolve this map.
var group_mergers: Dictionary[InterestGroupDefinition, InterestGroupDefinition] = {}
# Canonical group -> active institutional variant. Identity remains canonical elsewhere.
var group_variants: Dictionary[InterestGroupDefinition, InterestGroupDefinition] = {}
var local_interest_groups: Dictionary[SeatDefinition, InterestGroupDefinition] = {}


func get_active_article_for_row(
	row: ConstitutionRowDefinition
) -> ConstitutionArticleDefinition:
	return active_articles.get(row)


func get_active_article(race: RaceDefinition) -> ConstitutionArticleDefinition:
	if race == null:
		return null
	for row in active_articles:
		if row != null and row.race == race:
			return active_articles[row]
	return null
