import type {
	Bill,
	Constitution,
	Metric,
	MetricValues,
	PolicyDefinition,
	Proposal
} from '$lib/game';

export type LeftItemKind = 'constitution' | 'bill' | 'proposal' | 'policy';
export type LeftCollection = 'constitutions' | 'bills' | 'proposals' | 'policies';

export type LeftItemRef = {
	collection: LeftCollection;
	index: number;
};

export type ConstitutionLeftItem = {
	kind: 'constitution';
	ref: LeftItemRef & { collection: 'constitutions' };
	constitution: Constitution;
};

export type BillLeftItem = {
	kind: 'bill';
	ref: LeftItemRef & { collection: 'bills' };
	bill: Bill;
};

export type ProposalLeftItem = {
	kind: 'proposal';
	ref: LeftItemRef & { collection: 'proposals' };
	proposal: Proposal;
};

export type PolicyLeftItem = {
	kind: 'policy';
	ref: LeftItemRef & { collection: 'policies' };
	policy: PolicyDefinition;
};

export type LeftItem =
	| ConstitutionLeftItem
	| BillLeftItem
	| ProposalLeftItem
	| PolicyLeftItem;

export type ArchiveFilterState = {
	kinds: LeftItemKind[];
	metrics: Metric[];
	timeAscending: boolean;
	valueAscending: boolean;
};

export type SynthesisFilterState = {
	group?: string;
	metrics: Metric[];
	timeAscending: boolean;
	valueAscending: boolean;
};

export type ProposalPreview = {
	metrics: import('../memorial/types').MemorialMetricData[];
	reverseSource?: ProposalLeftItem;
};

export type SynthesisConfirmation = {
	proposals: ProposalLeftItem[];
	refs: LeftItemRef[];
	reverseSource?: ProposalLeftItem;
};

export type LeftProps = {
	items: LeftItem[];
	baseline: MetricValues;
	onItemSelect?: (item: LeftItem) => void;
	onSynthesisConfirm?: (confirmation: SynthesisConfirmation) => void;
};
