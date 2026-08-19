import extractorSvelte from '@unocss/extractor-svelte';
import { defineConfig, presetWind3 } from 'unocss';

const colors = {
	transparent: 'transparent',
	current: 'currentColor',

	'indigo-900': '#1E2E3B',
	'indigo-700': '#344654',
	'indigo-600': '#395266',
	'indigo-400': '#537087',

	'amber-500': '#EFB836',
	'amber-600': '#D6A531',
	'amber-700': '#BD922B',

	'shadow-deep': '#1E2E3B',

	'surface-indigo': '#344654',
	'surface-indigo-muted': '#537087',

	'ink-primary': '#344654',
	'ink-secondary': '#395266',

	'accent-amber-deep': '#BD922B',

	'surface-amber': '#EFB836',
	'surface-amber-pressed': '#D6A531'
};

const fontFamily = {
	official: '"Huiwen-Fangsong"',
	policy: '"Huiwen-MinchoGBK"',
	display: '"ZhaohuaMinA"',
	document: '"RealTypeWriter"',
	archival: '"taisyoRyakuji"'
};

type FontName = keyof typeof fontFamily;
type FontWeight = 'light' | 'normal' | 'bold';

function typo(
	font: FontName,
	weight: FontWeight,
	size: number,
	lineHeight?: number,
	letterSpacing?: string
) {
	return [
		`font-${font}`,
		`font-${weight}`,
		`text-[${size}px]`,
		lineHeight === undefined ? 'leading-auto' : `leading-[${lineHeight}px]`,
		letterSpacing ? `tracking-[${letterSpacing}]` : 'tracking-normal',
		'normal-case',
		'no-underline'
	].join(' ');
}

export default defineConfig({
	presets: [presetWind3()],
	extractors: [extractorSvelte()],

	extendTheme: (theme) => {
		theme.colors = colors;
		theme.fontFamily = fontFamily;
	},

	rules: [['leading-auto', { 'line-height': 'normal' }]],

	shortcuts: {
		'typo-data-metric-sign': typo('official', 'normal', 16),
		'typo-data-metric-value': typo('document', 'light', 16),
		'typo-data-metric-label-vertical': typo('archival', 'normal', 48, 45),

		'typo-timing-lag-value': typo('document', 'light', 30, undefined, '-0.5em'),
		'typo-timing-lag-label': typo('archival', 'normal', 40, undefined, '-0.2em'),
		'typo-timing-lag-unit': typo('archival', 'normal', 36, undefined, '-0.2em'),

		'typo-dialogue-body': typo('document', 'light', 48),
		'typo-dialogue-speaker-vertical': typo('archival', 'normal', 48, 36, '-0.2em'),

		'typo-proposal-sponsor-group-default': typo('archival', 'normal', 32),
		'typo-proposal-sponsor-group-compact': typo('archival', 'normal', 32, undefined, '-0.2em'),
		'typo-proposal-sponsor-group-tight': typo('archival', 'normal', 32, undefined, '-0.3em'),

		'typo-seal-policy-name': typo('policy', 'normal', 36),
		'typo-seal-policy-clause': typo('policy', 'normal', 16, 20),
		'typo-seal-policy-detail': typo('document', 'light', 13, 16),

		'typo-filter-primary': typo('official', 'normal', 16, 20),
		'typo-filter-secondary': typo('document', 'light', 13, 18),

		'typo-document-display-title': typo('display', 'bold', 30, 36),
		'typo-document-kicker': typo('archival', 'normal', 13, 18, '-0.05em'),
		'typo-document-metadata': typo('document', 'light', 11, 16),
		'typo-document-section-heading': typo('policy', 'normal', 20, 26),
		'typo-document-lead': typo('official', 'normal', 16, 25),
		'typo-document-body': typo('document', 'light', 15, 26),
		'typo-document-body-compact': typo('document', 'light', 13, 21),
		'typo-document-clause-number': typo('display', 'bold', 24, 28, '-0.05em'),
		'typo-document-quote': typo('official', 'normal', 18, 30),
		'typo-document-annotation': typo('official', 'normal', 12, 18),
		'typo-document-data': typo('document', 'light', 14, 20, '0.02em'),
		'typo-document-signature': typo('archival', 'normal', 14, 20, '-0.05em'),
		'typo-document-rule-label': typo('policy', 'normal', 14, 20)
	},

	preflights: [
		{
			getCSS: () => `
@font-face {
	font-family: "Huiwen-Fangsong";
	src: url("/fonts/Huiwen-Fangsong-Regular.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}

@font-face {
	font-family: "Huiwen-MinchoGBK";
	src: url("/fonts/Huiwen-MinchoGBK-Regular.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}

@font-face {
	font-family: "ZhaohuaMinA";
	src: url("/fonts/ZhaohuaMinA-Bold.woff2") format("woff2");
	font-style: normal;
	font-weight: 700;
	font-display: swap;
}

@font-face {
	font-family: "RealTypeWriter";
	src: url("/fonts/RealTypeWriter-Light.woff2") format("woff2");
	font-style: normal;
	font-weight: 300;
	font-display: swap;
}

@font-face {
	font-family: "taisyoRyakuji";
	src: url("/fonts/taisyoRyakuji-Regular.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}
`
		}
	]
});
