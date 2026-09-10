extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const BiyiAssimilation = preload("res://data/constitutions/比翼化.tres")
const Cooperative = preload("res://data/constitutions/合作社.tres")
const Nationalization = preload("res://data/constitutions/国有化.tres")


func run(t: BackendTestContext) -> void:
	var serializer := UiSerializer.new()
	t.check_approx(
		serializer._article_requirement_percent(BiyiAssimilation),
		50.0,
		"UI serializes a race seat threshold from a formal non-Yano constitution"
	)
	t.check_approx(
		serializer._article_requirement_percent(Cooperative),
		50.0,
		"UI serializes an interest-group threshold from a formal non-Yano constitution"
	)
	t.check_approx(
		serializer._article_requirement_percent(Nationalization),
		5.0,
		"UI serializes the first threshold from a formal multi-condition constitution"
	)

	var top_condition := ConstitutionSeatCondition.new()
	top_condition.required_rate = 0.4
	var legacy_condition := ConstitutionSeatCondition.new()
	legacy_condition.required_rate = 0.9
	var article := ConstitutionArticleDefinition.new()
	article.conditions = [top_condition]
	article.seat_condition = legacy_condition
	t.check_approx(
		serializer._article_requirement_percent(article),
		40.0,
		"UI percentage follows the topmost condition before the legacy seat condition"
	)
