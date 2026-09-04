extends RefCounted
class_name OfficeVisitState

enum Kind {
	EVENT_INTEL,
	INTEREST_GROUP,
}

var kind: Kind
var race: RaceDefinition
var event: EventState
var proposal: ProposalInstance
