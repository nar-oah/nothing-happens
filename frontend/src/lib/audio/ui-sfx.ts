import otherUrl from './assets/other.ogg?url';
import memorialToggleUrl from './assets/memorial-toggle.ogg?url';
import memorialInsertUrl from './assets/memorial-insert.ogg?url';
import passedUrl from './assets/passed.ogg?url';
import bribeUrl from './assets/bribe.ogg?url';

export type UiSfx = 'other' | 'memorial-toggle' | 'memorial-insert' | 'passed' | 'bribe';

const sources: Record<UiSfx, string> = {
	other: otherUrl,
	'memorial-toggle': memorialToggleUrl,
	'memorial-insert': memorialInsertUrl,
	passed: passedUrl,
	bribe: bribeUrl
};

const pools = new Map<UiSfx, HTMLAudioElement[]>();
let suppressDefaultClick = false;

function poolFor(name: UiSfx): HTMLAudioElement[] {
	let pool = pools.get(name);
	if (pool) return pool;
	pool = Array.from({ length: 3 }, () => {
		const audio = new Audio(sources[name]);
		audio.preload = 'auto';
		return audio;
	});
	pools.set(name, pool);
	return pool;
}

export function playUiSfx(name: UiSfx, suppressDefault = false): void {
	if (typeof window === 'undefined') return;
	if (suppressDefault) suppressDefaultClick = true;
	const pool = poolFor(name);
	const audio = pool.find((candidate) => candidate.paused || candidate.ended) ?? pool[0];
	audio.currentTime = 0;
	audio.volume = name === 'other' ? 0.72 : 0.86;
	void audio.play().catch(() => {});
}

function disabled(control: HTMLElement): boolean {
	if (control.getAttribute('aria-disabled') === 'true') return true;
	return control instanceof HTMLButtonElement || control instanceof HTMLInputElement
		? control.disabled
		: false;
}

function handleClick(event: MouseEvent): void {
	if (suppressDefaultClick) {
		suppressDefaultClick = false;
		return;
	}
	const target = event.target;
	if (!(target instanceof Element)) return;
	const control = target.closest<HTMLElement>(
		'button, [role="button"], a[href], input[type="button"], input[type="submit"]'
	);
	if (!control || disabled(control)) return;
	playUiSfx('other');
}

export function installUiSfx(): () => void {
	if (typeof document === 'undefined') return () => {};
	document.addEventListener('click', handleClick);
	return () => document.removeEventListener('click', handleClick);
}
