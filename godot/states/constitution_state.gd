extends RefCounted
class_name ConstitutionState

var active_articles: Dictionary[StringName, ConstitutionArticleDefinition] = {}
var revision_available: bool = true
var terminal_article_id: StringName
var annual_petition_count: int = 0
var pending_group_seat_targets: Dictionary[StringName, int] = {}


func has_flag(flag: StringName) -> bool:
	for article in active_articles.values():
		if article != null and flag in article.flags:
			return true
	return false


func get_active_article(axis_id: StringName) -> ConstitutionArticleDefinition:
	return active_articles.get(axis_id)


func get_influence_rules() -> Array[ConstitutionInfluenceRule]:
	var result: Array[ConstitutionInfluenceRule] = []
	for article in active_articles.values():
		if article == null:
			continue
		result.append_array(article.influence_rules)
	return result
