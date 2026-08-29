import assert from 'node:assert/strict';
import test from 'node:test';
import { makeDraftSync, makeLiveState } from '../game/state/test-fixtures.ts';
import { deriveTermReportMetrics } from '../components/newspaper/term-report.ts';
import { CefIpcClient, type CefBridgeWindow } from './client.ts';
import { normalizeInputRegions } from './input-regions.ts';
import { CommandError } from './protocol.ts';
import { decodeInboundMessage, encodeOutboundMessage, isOutboundType } from './validation.ts';

test('IPC envelope encodes and decodes discriminated messages', () => {
	const encoded = encodeOutboundMessage({
		type: 'draft.proposal.add',
		request_id: 'ui-1',
		payload: { state_version: 4, hand_index: 2 }
	});
	assert.deepEqual(JSON.parse(encoded), {
		type: 'draft.proposal.add',
		request_id: 'ui-1',
		payload: { state_version: 4, hand_index: 2 }
	});
	assert.deepEqual(
		JSON.parse(encodeOutboundMessage({ type: 'term.next', payload: { state_version: 4 } })),
		{ type: 'term.next', payload: { state_version: 4 } }
	);
	assert.deepEqual(
		JSON.parse(
			encodeOutboundMessage({
				type: 'constitution.column.unlock',
				payload: { state_version: 4, column_index: 2 }
			})
		),
		{
			type: 'constitution.column.unlock',
			payload: { state_version: 4, column_index: 2 }
		}
	);
	assert.equal(isOutboundType('term.next'), true);
	assert.equal(isOutboundType('constitution.column.unlock'), true);

	const decoded = decodeInboundMessage(
		JSON.stringify({ type: 'state.full', request_id: 'ui-1', payload: makeLiveState(4) })
	);
	assert.equal(decoded.ok, true);
	if (decoded.ok) {
		assert.equal(decoded.value.type, 'state.full');
		assert.equal(decoded.value.request_id, 'ui-1');
	}
});

test('IPC validates authoritative term lifecycle and integer collapse status', () => {
	const ended = makeLiveState(4);
	ended.run_phase = 'TERM_ENDED';
	ended.term_outcome = 'NOTHING_HAPPENS';
	ended.governing_months = 19;
	const decoded = decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: ended }));
	assert.equal(decoded.ok, true);
	if (decoded.ok && decoded.value.type === 'state.full') {
		assert.equal(decoded.value.payload.run_phase, 'TERM_ENDED');
		assert.equal(decoded.value.payload.term_outcome, 'NOTHING_HAPPENS');
		assert.equal(decoded.value.payload.governing_months, 19);
	}

	const fractionalCollapse = { ...makeLiveState(5), collapse_level: 1.5 };
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: fractionalCollapse })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
	const missingPhase: Record<string, unknown> = { ...makeLiveState(6) };
	delete missingPhase.run_phase;
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: missingPhase })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
});

test('IPC validates term settlement reports and derives year/month rollover metrics', () => {
	const settled = {
		...makeLiveState(5),
		term_report: {
			outcome: 'COLLAPSE' as const,
			previous_governing_months: 11,
			current_governing_months: 13
		}
	};
	const decoded = decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: settled }));
	assert.equal(decoded.ok, true);
	assert.deepEqual(deriveTermReportMetrics(settled.term_report), [
		{ metric: '執政年數', value: 0, change: 1 },
		{ metric: '執政月數', value: 11, change: -10 }
	]);

	const invalid = {
		...settled,
		term_report: { ...settled.term_report, current_governing_months: 10 }
	};
	assert.deepEqual(decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: invalid })), {
		ok: false,
		error: 'Invalid payload for state.full'
	});
});

test('IPC rejects the legacy flat constitution payload shape', () => {
	const state = makeLiveState(7);
	const legacyState: Record<string, unknown> = {
		...state,
		constitution: {
			title: '蓬莱约法',
			revision_available: true,
			active_articles: state.constitution.active_articles,
			articles: [
				{
					article_index: 0,
					race_display_name: '人类',
					display_name: '外藩',
					content: '',
					policies: [],
					active: true,
					selected: true,
					clicked: true,
					eligible: false
				}
			]
		}
	};
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: legacyState })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
});

test('IPC decode rejects malformed JSON, unknown types, and invalid payloads', () => {
	assert.deepEqual(decodeInboundMessage('{'), { ok: false, error: 'Malformed JSON' });
	assert.deepEqual(decodeInboundMessage(JSON.stringify({ type: 'unknown', payload: {} })), {
		ok: false,
		error: 'Unknown or missing message type'
	});
	assert.deepEqual(decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: {} })), {
		ok: false,
		error: 'Invalid payload for state.full'
	});
});

test('CEF client installs its listener before ready and correlates request results', async () => {
	const events: string[] = [];
	const sent: string[] = [];
	let listener: CefIpcListener | undefined;
	let removed: CefIpcListener | undefined;
	const target = {
		sendIpcMessage(raw: string) {
			events.push('send');
			sent.push(raw);
		},
		ipcMessage: {
			addListener(next: CefIpcListener) {
				events.push('listen');
				listener = next;
			},
			removeListener(next: CefIpcListener) {
				removed = next;
			}
		}
	} as unknown as CefBridgeWindow;
	const received: string[] = [];
	const client = new CefIpcClient(target, { onMessage: (message) => received.push(message.type) });
	client.connect();
	assert.deepEqual(events.slice(0, 2), ['listen', 'send']);
	assert.equal(JSON.parse(sent[0]).type, 'ui.ready');

	const resultPromise = client.request('draft.title.set', { state_version: 1, title: '新草案' });
	const requestId = JSON.parse(sent[1]).request_id as string;
	listener?.(
		JSON.stringify({ type: 'draft.sync', request_id: requestId, payload: makeDraftSync(2) })
	);
	assert.equal((await resultPromise).type, 'draft.sync');
	assert.deepEqual(received, ['draft.sync']);

	const errorPromise = client.request('bill.new', { state_version: 2 });
	const errorRequestId = JSON.parse(sent[2]).request_id as string;
	listener?.(
		JSON.stringify({
			type: 'command.error',
			request_id: errorRequestId,
			payload: { code: 'stale_command', message: '状态已变化', recover_full_state: true }
		})
	);
	await assert.rejects(
		errorPromise,
		(error) => error instanceof CommandError && error.code === 'stale_command'
	);

	client.destroy();
	assert.equal(removed, listener);
});

test('input blocker rects are clipped and normalized', () => {
	assert.deepEqual(
		normalizeInputRegions(
			[
				{ left: -10, top: 25, right: 50, bottom: 75 },
				{ left: 80, top: 10, right: 120, bottom: 20 },
				{ left: 200, top: 200, right: 220, bottom: 220 }
			],
			100,
			100
		),
		[
			{ x: 0, y: 0.25, width: 0.5, height: 0.5 },
			{ x: 0.8, y: 0.1, width: 0.2, height: 0.1 }
		]
	);
});
