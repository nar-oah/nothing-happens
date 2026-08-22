import { MEMORIAL_LINE_WIDTH, TITLED_PAGE_BODY_LINES, UNTITLED_PAGE_BODY_LINES } from './constants';
import type { MemorialHorizontalContentData } from './types';

const isEnglishLetter = (character: string) => /^[A-Za-z]$/.test(character);
const isPunctuation = (character: string) => /^\p{P}$/u.test(character);
const getCharacterWidth = (character: string) => (isEnglishLetter(character) ? 0.5 : 1);

export function splitMemorialBodyIntoLines(body: string): string[] {
	const characters = Array.from(body);
	const lines: string[] = [];
	let start = 0;

	while (start < characters.length) {
		let end = start;
		let width = 0;
		let forcedBreak = false;

		while (end < characters.length) {
			if (characters[end] === '\n') {
				forcedBreak = true;
				break;
			}

			const nextWidth = getCharacterWidth(characters[end]);
			if (width + nextWidth > MEMORIAL_LINE_WIDTH) break;
			width += nextWidth;
			end += 1;
		}

		if (!forcedBreak && end < characters.length && isPunctuation(characters[end]) && end > start) {
			end -= 1;
		}

		if (end === start && !forcedBreak) end += 1;
		lines.push(characters.slice(start, end).join(''));
		start = end + (forcedBreak ? 1 : 0);
	}

	return lines;
}

export function paginateMemorialContents(
	contents: MemorialHorizontalContentData[]
): MemorialHorizontalContentData[] {
	return contents.flatMap((content) => {
		const lines = splitMemorialBodyIntoLines(content.body);
		const firstPageLineCount = content.title ? TITLED_PAGE_BODY_LINES : UNTITLED_PAGE_BODY_LINES;

		if (lines.length === 0) return [{ ...content }];

		const pages: MemorialHorizontalContentData[] = [
			{ ...content, body: lines.slice(0, firstPageLineCount).join('\n') }
		];

		for (let index = firstPageLineCount; index < lines.length; index += UNTITLED_PAGE_BODY_LINES) {
			pages.push({ body: lines.slice(index, index + UNTITLED_PAGE_BODY_LINES).join('\n') });
		}

		return pages;
	});
}
