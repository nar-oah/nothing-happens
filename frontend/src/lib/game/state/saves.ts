import type { GameStatusDto, SaveSlotDto } from './types.ts';

export type SaveItem = {
	slot: SaveSlotDto;
	item: { text: string; value: string };
};

export function deriveSaveItems(
	saves: SaveSlotDto[],
	current: Pick<GameStatusDto, 'term' | 'year' | 'month'>,
	loading: boolean
): SaveItem[] {
	const manual = saves.filter((slot) => !slot.automatic);
	const automatic = saves.find((slot) => slot.automatic);
	const last = loading
		? automatic
		: { ...automatic, slot_id: 'auto', automatic: true, saved_at: '', ...current };
	return [...manual, ...(last ? [last] : [])].map((slot) => ({
		slot,
		item: { text: `第 ${slot.term} 任`, value: `${slot.year} 年 ${slot.month} 月` }
	}));
}

export function getSaveAction(slot: SaveSlotDto, loading: boolean) {
	if (loading) return { type: 'saves.load' as const, payload: { slot_id: slot.slot_id } };
	if (slot.automatic) return { type: 'saves.create' as const, payload: {} };
	return { type: 'saves.overwrite' as const, payload: { slot_id: slot.slot_id } };
}
