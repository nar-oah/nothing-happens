import type {
	Bill,
	Constitution,
	Metric,
	MetricValues,
	PolicyDefinition,
	Proposal
} from '../../game/index.ts';

export type LeftItemKind = 'constitution' | 'bill' | 'proposal' | 'policy';
export type LeftCollection = 'constitution' | 'bills' | 'proposals' | 'policies';
export type LeftScene = 'office' | 'parliament' | 'dialogue';
export type LeftMode = 'archive' | 'synthesis' | 'selection';

export type LeftItemRef = {
	collection: LeftCollection;
	index: number;
};

export type ConstitutionLeftItem = {
	kind: 'constitution';
	ref: LeftItemRef & { collection: 'constitution' };
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

export type LeftItem = ConstitutionLeftItem | BillLeftItem | ProposalLeftItem | PolicyLeftItem;

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
	metrics: import('../memorial/types.ts').MemorialMetricData[];
	reverseSource?: ProposalLeftItem;
};

export type SynthesisConfirmation = {
	proposals: ProposalLeftItem[];
	refs: LeftItemRef[];
	negativeBaseRef: LeftItemRef;
	reverseSource?: ProposalLeftItem;
};

export type LeftSelectionState = {
	proposalRefs: LeftItemRef[];
	policyDisplayNames: string[];
	editingSavedBillIndex?: number;
};

export type LeftProps = {
	scene: LeftScene;
	items: LeftItem[];
	baseline: MetricValues;
	activeMode?: LeftMode;
	selection?: LeftSelectionState;
	onModeChange?: (mode: LeftMode) => void;
	onItemSelect?: (item: LeftItem, mode: LeftMode) => void;
	onSynthesisConfirm?: (confirmation: SynthesisConfirmation) => void;
};
