extends RefCounted
class_name ConstitutionState

var active_articles: Dictionary[RaceDefinition, ConstitutionArticleDefinition] = {}
var clicked_articles: Dictionary[ConstitutionArticleDefinition, bool] = {}
var revision_available: bool = true
var group_mergers: Dictionary[InterestGroupDefinition, InterestGroupDefinition] = {}
var local_interest_groups: Dictionary[SeatDefinition, InterestGroupDefinition] = {}


func get_active_article(race: RaceDefinition) -> ConstitutionArticleDefinition:
	return active_articles.get(race)


func was_clicked(article: ConstitutionArticleDefinition) -> bool:
	return article != null and clicked_articles.has(article)
