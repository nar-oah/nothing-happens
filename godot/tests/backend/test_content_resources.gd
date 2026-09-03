extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const ConstitutionBoard = preload("res://data/constitutions/constitution_board.tres")
const ConstitutionArticleScript = preload("res://definitions/constitution_article_definition.gd")


func run(t: BackendTestContext) -> void:
	_test_formal_constitution_board_resources(t)


func _test_formal_constitution_board_resources(t: BackendTestContext) -> void:
	t.check(ConstitutionBoard.validate(), "formal constitution board validates")
	t.check_equal(ConstitutionBoard.columns.size(), 7, "formal constitution board has seven columns")
	t.check_equal(ConstitutionBoard.get_center_column_index(), 3, "常制 is the center column")
	var rows := ConstitutionBoard.get_rows()
	t.check_equal(rows.size(), 6, "formal constitution board has six rows")
	var expected_rows: Array[String] = ["外交", "文化", "偃偶", "桃源", "团体", "监管"]
	for index in range(expected_rows.size()):
		t.check_equal(rows[index].display_name, expected_rows[index], "formal row order matches the confirmed board")
	var expected_center: Array[String] = ["外藩", "包容", "有限", "自治", "工会", "哲人王"]
	for index in range(rows.size()):
		var article := ConstitutionBoard.get_article(rows[index], 3)
		t.check(article != null, "every formal row has a central default article")
		if article != null:
			t.check_equal(article.display_name, expected_center[index], "central article matches the confirmed default")
	var articles := ConstitutionBoard.get_articles()
	t.check_equal(articles.size(), 27, "formal constitution board contains exactly twenty-seven real nodes")
	var terminal_names: Array[String] = []
	for article in articles:
		t.check(
			article.get_script() == ConstitutionArticleScript,
			"every formal constitution node composes effects on the base article script"
		)
		for effect in article.effects:
			t.check(effect != null, "formal constitution effects are valid Resource references")
		if article.is_terminal:
			terminal_names.append(article.display_name)
	terminal_names.sort()
	var expected_terminals: Array[String] = ["地区自治", "托拉斯", "法团", "理想国", "行省"]
	expected_terminals.sort()
	t.check_equal(terminal_names, expected_terminals, "only the five race 90% nodes are terminal")
	var regulation := rows[5]
	t.check(regulation.free_navigation, "regulation row allows direct navigation")
	t.check(regulation.ignores_column_unlocks, "regulation row ignores meta column unlocks")
	for article in articles:
		t.check(article.row != null, "every formal constitution node belongs to a row")
