import { CommandError } from '../bridge/protocol.ts';
import type { Translate } from './index.ts';

export const liveZhCN: Record<string, string> = {
	'live.proposalCount': '{group}提案数',
	'live.saveFailed': '存档操作失败。',
	'live.settingsFailed': '无法更新设置。',
	'live.quitFailed': '自动存档失败，游戏未退出。{reason}',
	'live.commandFailed': '操作失败，请重试。',
	'error.invalid_language': '不支持该语言。',
	'error.invalid_display_mode': '不支持该显示模式。',
	'error.settings_not_ready': '设置尚未就绪。',
	'error.settings_write_failed': '无法保存设置。',
	'error.invalid_save_slot': '存档编号无效。',
	'error.save_not_found': '无法读取指定存档。',
	'error.save_unavailable': '当前状态无法保存。',
	'error.snapshot_failed': '无法保存当前状态。',
	'error.save_write_failed': '无法写入存档，原存档已保留。',
	'error.invalid_save': '存档文件无效或损坏。',
	'error.invalid_snapshot': '无法恢复存档状态。',
	'error.unsupported_save_version': '不支持此存档版本。',
	'error.stale_state': '游戏状态已变化，请重试。',
	'error.stale_command': '游戏状态已变化，请重试。'
};

export const liveEn: Record<keyof typeof liveZhCN, string> = {
	'live.proposalCount': '{group} proposals',
	'live.saveFailed': 'The save operation failed.',
	'live.settingsFailed': 'Unable to update settings.',
	'live.quitFailed': 'Autosave failed. The game is still running. {reason}',
	'live.commandFailed': 'The operation failed. Please try again.',
	'error.invalid_language': 'This language is not supported.',
	'error.invalid_display_mode': 'This display mode is not supported.',
	'error.settings_not_ready': 'Settings are not ready.',
	'error.settings_write_failed': 'Unable to save settings.',
	'error.invalid_save_slot': 'The save slot is invalid.',
	'error.save_not_found': 'Unable to read the selected save.',
	'error.save_unavailable': 'The current state cannot be saved.',
	'error.snapshot_failed': 'Unable to save the current state.',
	'error.save_write_failed': 'Unable to write the save. The previous save has been kept.',
	'error.invalid_save': 'The save file is invalid or damaged.',
	'error.invalid_snapshot': 'Unable to restore the saved state.',
	'error.unsupported_save_version': 'This save version is not supported.',
	'error.stale_state': 'The game state has changed. Please try again.',
	'error.stale_command': 'The game state has changed. Please try again.'
};

export function translateCommandError(error: unknown, translator: Translate): string {
	const key = error instanceof CommandError ? `error.${error.code}` : '';
	return translator(Object.hasOwn(liveZhCN, key) ? key : 'live.commandFailed');
}
