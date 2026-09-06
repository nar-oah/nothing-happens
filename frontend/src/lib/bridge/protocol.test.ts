import assert from 'node:assert/strict';
import test from 'node:test';
import { makeDraftSync, makeLiveState, makeParliamentLayout } from '../game/state/test-fixtures.ts';
import { deriveTermReportMetrics } from '../components/newspaper/term-report.ts';
import { CefIpcClient, type CefBridgeWindow } from './client.ts';
import { normalizeInputRegions } from './input-regions.ts';
import { CommandError, type OutboundMessage } from './protocol.ts';
import { decodeInboundMessage, encodeOutboundMessage, isOutboundType } from './validation.ts';

test('settings and quit commands encode without gameplay versions and reject invalid payloads', () => {
	for (const command of [
		{ type: 'settings.language.set', payload: { language: 'zh_CN' } },
		{ type: 'settings.language.set', payload: { language: 'en' } },
		{ type: 'settings.display.set', payload: { mode: 'windowed' } },
		{ type: 'settings.display.set', payload: { mode: 'fullscreen' } },
		{ type: 'app.quit', payload: {} }
	] satisfies OutboundMessage[]) {
		assert.equal(isOutboundType(command.type), true);
		assert.deepEqual(JSON.parse(encodeOutboundMessage(command)), command);
		assert.equal('state_version' in command.payload, false);
	}
	for (const command of [
		{ type: 'settings.language.set', payload: { language: 'fr' } },
		{ type: 'settings.language.set', payload: {} },
		{ type: 'settings.language.set', payload: { language: 'en', state_version: 1 } },
		{ type: 'settings.display.set', payload: { mode: 'borderless' } },
		{ type: 'settings.display.set', payload: { mode: 1 } },
		{ type: 'settings.display.set', payload: null },
		{ type: 'app.quit', payload: { state_version: 1 } }
	]) {
		assert.throws(() => encodeOutboundMessage(command as OutboundMessage), TypeError);
	}
});

test('state.full requires authoritative supported settings', () => {
	for (const language of ['zh_CN', 'en']) {
		for (const display_mode of ['windowed', 'fullscreen']) {
			assert.equal(decodeInboundMessage(JSON.stringify({
				type: 'state.full', payload: { ...makeLiveState(5), language, display_mode }
			})).ok, true);
		}
	}
	for (const settings of [
		{ language: undefined }, { language: 'fr' }, { language: null },
		{ display_mode: undefined }, { display_mode: 'borderless' }, { display_mode: false }
	]) {
		assert.equal(decodeInboundMessage(JSON.stringify({
			type: 'state.full', payload: { ...makeLiveState(5), ...settings }
		})).ok, false);
	}
});

test('CEF settings requests await full sync and quit failures reject through command.error', async () => {
	const sent: OutboundMessage[] = [];
	let listener: CefIpcListener | undefined;
	let snapshot = makeLiveState(8);
	const target = {
		sendIpcMessage: (raw: string) => sent.push(JSON.parse(raw)),
		ipcMessage: { addListener: (next: CefIpcListener) => { listener = next; } }
	} as unknown as CefBridgeWindow;
	const client = new CefIpcClient(target, {
		onMessage: (message) => { if (message.type === 'state.full') snapshot = message.payload; }
	});
	client.connect();
	const request = client.request('settings.language.set', { language: 'en' });
	assert.equal(snapshot.language, 'zh_CN');
	assert.deepEqual(sent[1].payload, { language: 'en' });
	listener?.(JSON.stringify({
		type: 'state.full', request_id: sent[1].request_id,
		payload: { ...snapshot, language: 'en' }
	}));
	await request;
	assert.equal(snapshot.language, 'en');
	assert.equal(snapshot.state_version, 8);
	const quit = client.request('app.quit', {});
	assert.deepEqual(sent[2].payload, {});
	listener?.(JSON.stringify({
		type: 'command.error', request_id: sent[2].request_id,
		payload: { code: 'save_write_failed', message: 'Unable to save.' }
	}));
	await assert.rejects(quit, (error) => error instanceof CommandError && error.code === 'save_write_failed');
	assert.equal(snapshot.state_version, 8);
	assert.equal(snapshot.language, 'en');
	client.destroy();
});

test('IPC supports all save commands and validates the save list in full and list responses', () => {
	const saves = [
		{
			slot_id: 'auto',
			automatic: true,
			term: 1,
			year: 2,
			month: 0,
			saved_at: '2026-09-05T10:00:00'
		}
	];
	for (const type of ['saves.list', 'saves.create', 'saves.overwrite', 'saves.load'])
		assert.equal(isOutboundType(type), true);
	assert.deepEqual(JSON.parse(encodeOutboundMessage({ type: 'saves.list', payload: {} })), {
		type: 'saves.list',
		payload: {}
	});
	assert.deepEqual(
		JSON.parse(encodeOutboundMessage({ type: 'saves.create', payload: { state_version: 5 } })),
		{ type: 'saves.create', payload: { state_version: 5 } }
	);
	for (const type of ['saves.overwrite', 'saves.load'] as const) {
		assert.deepEqual(
			JSON.parse(
				encodeOutboundMessage({ type, payload: { slot_id: 'manual-1', state_version: 5 } })
			),
			{ type, payload: { slot_id: 'manual-1', state_version: 5 } }
		);
	}
	assert.deepEqual(
		decodeInboundMessage(
			JSON.stringify({ type: 'saves.list', request_id: 'ui-save', payload: { saves } })
		),
		{ ok: true, value: { type: 'saves.list', request_id: 'ui-save', payload: { saves } } }
	);
	assert.equal(
		decodeInboundMessage(
			JSON.stringify({ type: 'state.full', payload: { ...makeLiveState(), saves } })
		).ok,
		true
	);
	for (const invalid of [
		{ ...saves[0], slot_id: '' },
		{ ...saves[0], automatic: 'true' },
		{ ...saves[0], term: -1 },
		{ ...saves[0], month: 13 },
		{ ...saves[0], year: 1.5 },
		{ ...saves[0], saved_at: null }
	]) {
		assert.equal(
			decodeInboundMessage(JSON.stringify({ type: 'saves.list', payload: { saves: [invalid] } }))
				.ok,
			false
		);
		assert.equal(
			decodeInboundMessage(
				JSON.stringify({ type: 'state.full', payload: { ...makeLiveState(), saves: [invalid] } })
			).ok,
			false
		);
	}
});

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
				type: 'office.visit.resolve',
				payload: { state_version: 4, accept_trait: true }
			})
		),
		{ type: 'office.visit.resolve', payload: { state_version: 4, accept_trait: true } }
	);
	assert.deepEqual(
		JSON.parse(
			encodeOutboundMessage({ type: 'office.visit.resolve', payload: { state_version: 4 } })
		),
		{ type: 'office.visit.resolve', payload: { state_version: 4 } }
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
	assert.equal(isOutboundType('vote.donation.add'), true);
	assert.equal(isOutboundType('constitution.column.unlock'), true);
	assert.equal(isOutboundType('office.visit.resolve'), true);
	assert.equal(isOutboundType('proposal.bonus.resolve'), false);

	const decoded = decodeInboundMessage(
		JSON.stringify({ type: 'state.full', request_id: 'ui-1', payload: makeLiveState(4) })
	);
	assert.equal(decoded.ok, true);
	if (decoded.ok) {
		assert.equal(decoded.value.type, 'state.full');
		assert.equal(decoded.value.request_id, 'ui-1');
	}
});

test('IPC validates both office visit dialogue variants', () => {
	const interestGroup = makeLiveState(4);
	assert.equal(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: interestGroup })).ok,
		true
	);

	const eventIntel = makeLiveState(5);
	eventIntel.pending_dialogue = {
		kind: 'event_intel',
		race_name: '南柯',
		metric: 2,
		requirement: 112,
		strength: 73
	};
	assert.equal(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: eventIntel })).ok,
		true
	);

	const invalidMetric = {
		...eventIntel,
		pending_dialogue: { ...eventIntel.pending_dialogue, metric: 99 }
	};
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: invalidMetric })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);

	const legacyDialogue = {
		...interestGroup,
		pending_dialogue: { hand_index: 0, proposal: interestGroup.proposal_hand[0] }
	};
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: legacyDialogue })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
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

test('IPC requires constitution effects and parliament display metadata', () => {
	const valid = makeLiveState(8);
	valid.constitution.active_articles[0].effects = [
		{ display_name: '奏请', description: '每年可奏请一次', timing: 0 }
	];
	valid.constitution.articles[0].effects = [
		{ display_name: '奏请', description: '每年可奏请一次', timing: 0 }
	];
	assert.equal(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: valid })).ok,
		true
	);

	const missingEffects = JSON.parse(JSON.stringify(valid)) as Record<string, unknown>;
	const missingEffectsConstitution = missingEffects.constitution as Record<string, unknown>;
	const missingEffectsArticles = missingEffectsConstitution.active_articles as Record<
		string,
		unknown
	>[];
	delete missingEffectsArticles[0].effects;
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: missingEffects })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);

	const invalidEffect = JSON.parse(JSON.stringify(valid)) as Record<string, unknown>;
	const invalidEffectConstitution = invalidEffect.constitution as Record<string, unknown>;
	const invalidEffectArticles = invalidEffectConstitution.active_articles as Record<
		string,
		unknown
	>[];
	invalidEffectArticles[0].effects = [{ display_name: '奏请', description: '说明', timing: -1 }];
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: invalidEffect })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);

	const missingParliamentName = JSON.parse(JSON.stringify(valid)) as Record<string, unknown>;
	delete (missingParliamentName.parliament as Record<string, unknown>).display_name;
	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: missingParliamentName })),
		{ ok: false, error: 'Invalid payload for state.full' }
	);
});

test('IPC validates normalized parliament seat anchors', () => {
	const valid = makeLiveState(9);
	valid.parliament_seat_anchors = [
		{ seat_index: 0, x: 0, y: 1 },
		{ seat_index: 1, x: 0.25, y: 0.75 }
	];
	assert.equal(
		decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: valid })).ok,
		true
	);

	const missing = { ...valid } as Partial<typeof valid>;
	delete missing.parliament_seat_anchors;
	assert.deepEqual(decodeInboundMessage(JSON.stringify({ type: 'state.full', payload: missing })), {
		ok: false,
		error: 'Invalid payload for state.full'
	});

	for (const parliament_seat_anchors of [
		[{ seat_index: 0.5, x: 0.5, y: 0.5 }],
		[{ seat_index: 0, x: -0.01, y: 0.5 }],
		[{ seat_index: 0, x: 0.5, y: 1.01 }]
	]) {
		assert.deepEqual(
			decodeInboundMessage(
				JSON.stringify({
					type: 'state.full',
					payload: { ...valid, parliament_seat_anchors }
				})
			),
			{ ok: false, error: 'Invalid payload for state.full' }
		);
	}
});

test('IPC decodes lightweight parliament layout updates', () => {
	const payload = makeParliamentLayout();
	const decoded = decodeInboundMessage(JSON.stringify({ type: 'parliament.layout', payload }));
	assert.deepEqual(decoded, {
		ok: true,
		value: { type: 'parliament.layout', payload }
	});

	for (const parliament_seat_anchors of [
		[{ seat_index: -1, x: 0.5, y: 0.5 }],
		[{ seat_index: 0, x: 1.01, y: 0.5 }],
		[{ seat_index: 0, x: 0.5, y: Number.NaN }]
	]) {
		assert.deepEqual(
			decodeInboundMessage(
				JSON.stringify({
					type: 'parliament.layout',
					payload: { parliament_seat_anchors }
				})
			),
			{ ok: false, error: 'Invalid payload for parliament.layout' }
		);
	}

	assert.deepEqual(
		decodeInboundMessage(JSON.stringify({ type: 'parliament.layout', payload: {} })),
		{ ok: false, error: 'Invalid payload for parliament.layout' }
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
