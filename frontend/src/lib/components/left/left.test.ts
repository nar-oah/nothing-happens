import assert from 'node:assert/strict';
import test from 'node:test';
import type { InterestGroupDefinition, Proposal } from '../../game/index.ts';
import {
	createSynthesisConfirmation,
	getLeftSecondaryMode,
	toggleProposalSelection
} from './left.ts';
import type { ProposalLeftItem } from './types.ts';

const sourceGroup: InterestGroupDefinition = {
	display_name: '商会',
	description: '商会简介',
	base_column_weight: 1,
	decrease_tax: true,
	decrease_consumption: false,
	decrease_production: false,
	decrease_employment: false,
	decrease_investment: false
};

function proposalItem(index: number, tax: number): ProposalLeftItem {
	const proposal: Proposal = {
		source_group: sourceGroup,
		base_effect: { tax, consumption: 0, production: 0, employment: 0, investment: 0 },
		positive_effect: { tax: 0, consumption: 0, production: 0, employment: 0, investment: 0 },
		lag_months: 2,
		donation_offer: 0,
		bonus_choice_resolved: true,
		positive_trait_accepted: true
	};
	return { kind: 'proposal', ref: { collection: 'proposals', index }, proposal };
}

test('Left chooses the scene-specific secondary mode', () => {
	assert.equal(getLeftSecondaryMode('office'), 'synthesis');
	assert.equal(getLeftSecondaryMode('parliament'), 'selection');
	assert.equal(getLeftSecondaryMode('dialogue'), undefined);
});

test('proposal synthesis selection is capped at three', () => {
	const proposals = [0, 1, 2, 3].map((index) => proposalItem(index, -(index + 1)));
	const selected = proposals.reduce(
		(current, proposal) => toggleProposalSelection(current, proposal),
		[] as ProposalLeftItem[]
	);
	assert.deepEqual(
		selected.map((item) => item.ref.index),
		[0, 1, 2]
	);
});

test('synthesis confirmation preserves all refs and the chosen negative base', () => {
	const proposals = [proposalItem(2, -2), proposalItem(4, -4), proposalItem(9, -9)];
	const confirmation = createSynthesisConfirmation(proposals, proposals[1]);
	assert.equal(confirmation.negativeBaseRef, proposals[1].ref);
	assert.deepEqual(
		confirmation.refs,
		proposals.map((item) => item.ref)
	);
});
