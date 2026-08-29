extends Resource
class_name ConstitutionBoardDefinition

@export var columns: Array[ConstitutionColumnDefinition] = []


func get_center_column_index() -> int:
	var result := -1
	for index in range(columns.size()):
		var column := columns[index]
		if column == null or column.unlock_cost_months != 0:
			continue
		if result >= 0:
			return -1
		result = index
	return result


func get_rows() -> Array[ConstitutionRowDefinition]:
	var seen: Dictionary[ConstitutionRowDefinition, bool] = {}
	var rows: Array[ConstitutionRowDefinition] = []
	for column in columns:
		if column == null:
			continue
		for article in column.articles:
			if article == null or article.row == null or seen.has(article.row):
				continue
			seen[article.row] = true
			rows.append(article.row)
	rows.sort_custom(func(a: ConstitutionRowDefinition, b: ConstitutionRowDefinition) -> bool:
		return a.display_order < b.display_order
	)
	return rows


func get_articles() -> Array[ConstitutionArticleDefinition]:
	var result: Array[ConstitutionArticleDefinition] = []
	for column in columns:
		if column == null:
			continue
		for article in column.articles:
			if article != null and article not in result:
				result.append(article)
	return result


func get_column_index_for_article(article: ConstitutionArticleDefinition) -> int:
	if article == null:
		return -1
	for index in range(columns.size()):
		var column := columns[index]
		if column != null and article in column.articles:
			return index
	return -1


func get_article(
	row: ConstitutionRowDefinition, column_index: int
) -> ConstitutionArticleDefinition:
	if row == null or column_index < 0 or column_index >= columns.size():
		return null
	var column := columns[column_index]
	if column == null:
		return null
	for article in column.articles:
		if article != null and article.row == row:
			return article
	return null


func validate() -> bool:
	if columns.is_empty() or get_center_column_index() < 0:
		push_error("Constitution board requires exactly one zero-cost center column.")
		return false
	var seen_columns: Dictionary[ConstitutionColumnDefinition, bool] = {}
	var seen_articles: Dictionary[ConstitutionArticleDefinition, bool] = {}
	for column in columns:
		if column == null or seen_columns.has(column):
			push_error("Constitution columns require unique non-null Resources.")
			return false
		seen_columns[column] = true
		var seen_rows: Dictionary[ConstitutionRowDefinition, bool] = {}
		for article in column.articles:
			if article == null or article.row == null or seen_articles.has(article):
				push_error("Every constitution article must belong to one row and one column.")
				return false
			if seen_rows.has(article.row):
				push_error("A constitution column cannot contain two articles from the same row.")
				return false
			seen_rows[article.row] = true
			seen_articles[article] = true
	return true
