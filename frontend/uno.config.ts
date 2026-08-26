import extractorSvelte from '@unocss/extractor-svelte';
import { defineConfig, presetWind3 } from 'unocss';

const colors = {
	transparent: 'transparent',
	current: 'currentColor',
	indigo: {
		900: '#1E2E3B',
		700: '#344654',
		600: '#395266',
		400: '#537087'
	},
	amber: {
		500: '#EFB836',
		600: '#D6A531',
		700: '#BD922B'
	},
	shadow: {
		deep: '#1E2E3B'
	},
	surface: {
		indigo: '#344654',
		'indigo-muted': '#537087',
		amber: '#EFB836',
		'amber-pressed': '#D6A531'
	},
	ink: {
		primary: '#344654',
		secondary: '#395266'
	},
	accent: {
		'amber-deep': '#BD922B'
	}
};

const fontFamily = {
	official: '"Huiwen-Fangsong"',
	policy: '"Huiwen-MinchoGBK"',
	display: '"ZhaohuaMinA"',
	document: '"RealTypeWriter"',
	archival: '"taisyoRyakuji"'
};

const fontSize = {
	9: '9px',
	11: '11px',
	12: '12px',
	13: '13px',
	14: '14px',
	15: '15px',
	16: '16px',
	18: '18px',
	20: '20px',
	24: '24px',
	25: '25px',
	30: '30px',
	32: '32px',
	36: '36px',
	40: '40px',
	42: '42px',
	48: '48px',
	54: '54px',
	72: '72px'
};

const lineHeight = {
	0: '0',
	auto: 'normal',
	12: '12px',
	15: '15px',
	16: '16px',
	18: '18px',
	20: '20px',
	21: '21px',
	25: '25px',
	26: '26px',
	28: '28px',
	30: '30px',
	36: '36px',
	40: '40px',
	42: '42px',
	45: '45px',
	56: '56px',
	58: '58px'
};

const letterSpacing = {
	normal: '0',
	'negative-2': '-0.02em',
	'negative-3': '-0.03em',
	'negative-5': '-0.05em',
	'negative-20': '-0.2em',
	'negative-30': '-0.3em',
	'negative-45': '-0.45em',
	'negative-50': '-0.5em',
	'positive-2': '0.02em'
};

const spacing = {
	0: '0px',
	2: '2px',
	4: '4px',
	5: '5px',
	8: '8px',
	10: '10px',
	12: '12px',
	17: '17px',
	25: '25px',
	30: '30px',
	47: '47px',
	'47.5': '47.5px',
	80: '80px'
};

const size = {
	4: '4px',
	15: '15px',
	16: '16px',
	17: '17px',
	24: '24px',
	25: '25px',
	30: '30px',
	40: '40px',
	45: '45px',
	58: '58px',
	65: '65px',
	80: '80px',
	82: '82px',
	96: '96px',
	100: '100px',
	116: '116px',
	220: '220px',
	230: '230px'
};

const borderWidth = {
	3: '3px'
};

const borderRadius = {
	0: '0px',
	3: '3px'
};

type FontName = keyof typeof fontFamily;
type FontSize = keyof typeof fontSize;
type LineHeight = keyof typeof lineHeight;
type LetterSpacing = keyof typeof letterSpacing;
type FontWeight = 'light' | 'normal' | 'medium' | 'bold';

function typo(
	font: FontName,
	weight: FontWeight,
	size: FontSize,
	leading: LineHeight = 'auto',
	tracking: LetterSpacing = 'normal'
) {
	return [
		`font-${font}`,
		`font-${weight}`,
		`text-${size}`,
		`leading-${leading}`,
		`tracking-${tracking}`,
		'normal-case',
		'no-underline'
	].join(' ');
}

export default defineConfig({
	presets: [presetWind3()],
	extractors: [extractorSvelte()],

	theme: {
		colors,
		fontFamily,
		fontSize,
		lineHeight,
		letterSpacing,
		spacing,
		width: size,
		height: size,
		borderWidth,
		borderRadius
	},

	shortcuts: {
		'typo-data-metric-sign': typo('official', 'medium', 16),
		'typo-data-metric-value': typo('document', 'light', 16),
		'typo-data-metric-label-vertical': typo('archival', 'normal', 48, 45),
		'typo-data-metric-value-tight': typo('document', 'light', 24, 'auto', 'negative-45'),
		'typo-data-metric-label-large': typo('archival', 'normal', 72, 58),

		'typo-timing-lag-value': typo('document', 'light', 30, 'auto', 'negative-50'),
		'typo-timing-lag-label': typo('archival', 'normal', 40, 'auto', 'negative-20'),
		'typo-timing-lag-unit': typo('archival', 'normal', 36, 'auto', 'negative-20'),

		'typo-dialogue-body': typo('document', 'light', 48),
		'typo-dialogue-speaker-vertical': typo('archival', 'normal', 48, 36, 'negative-20'),
		'typo-control-heading': typo('policy', 'medium', 48, 40),
		'typo-filter-context-label': typo('document', 'light', 30),
		'typo-filter-marker': typo('archival', 'normal', 24),
		'typo-filter-option': typo('document', 'light', 24),

		'typo-proposal-sponsor-group-default': typo('archival', 'normal', 32),
		'typo-proposal-sponsor-group-compact': typo('archival', 'normal', 32, 'auto', 'negative-20'),
		'typo-proposal-sponsor-group-tight': typo('archival', 'normal', 32, 'auto', 'negative-30'),

		'typo-seal-policy-name': typo('policy', 'medium', 36),
		'typo-seal-policy-clause': typo('policy', 'medium', 16, 20),
		'typo-seal-policy-detail': typo('document', 'light', 13, 16),

		'typo-filter-primary': typo('official', 'medium', 16, 20),
		'typo-filter-secondary': typo('document', 'light', 13, 18),

		'typo-document-display-title': typo('display', 'bold', 30, 36),
		'typo-document-kicker': typo('archival', 'normal', 13, 18, 'negative-5'),
		'typo-document-metadata': typo('document', 'light', 11, 16),
		'typo-document-section-heading': typo('policy', 'normal', 20, 26),
		'typo-document-lead': typo('official', 'normal', 16, 25),
		'typo-document-body': typo('document', 'light', 15, 26),
		'typo-document-body-compact': typo('document', 'light', 13, 21),
		'typo-document-clause-number': typo('display', 'bold', 24, 28, 'negative-5'),
		'typo-document-quote': typo('official', 'normal', 18, 30),
		'typo-document-annotation': typo('official', 'normal', 12, 18),
		'typo-document-data': typo('document', 'light', 14, 20, 'positive-2'),
		'typo-document-signature': typo('archival', 'normal', 14, 20, 'negative-5'),
		'typo-document-rule-label': typo('policy', 'normal', 14, 20),

		'typo-newspaper-masthead': typo('display', 'bold', 54, 56),
		'typo-newspaper-caption': typo('archival', 'normal', 9, 12, 'negative-3'),
		'typo-newspaper-data-hero': typo('document', 'light', 42, 42, 'negative-2'),
		'typo-newspaper-headline': typo('policy', 'medium', 25, 28),
		'typo-newspaper-body': typo('document', 'light', 11, 15),
		'typo-newspaper-subhead': typo('official', 'medium', 16, 20)
	},

	preflights: [
		{
			getCSS: () => `
@font-face {
	font-family: "Huiwen-Fangsong";
	src: url("/fonts/Huiwen-Fangsong.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}

@font-face {
	font-family: "Huiwen-MinchoGBK";
	src: url("/fonts/Huiwen-MinchoGBK.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}

@font-face {
	font-family: "ZhaohuaMinA";
	src: url("/fonts/ZhaohuaMinA.woff2") format("woff2");
	font-style: normal;
	font-weight: 700;
	font-display: swap;
}

@font-face {
	font-family: "RealTypeWriter";
	src: url("/fonts/RealTypeWriter.woff2") format("woff2");
	font-style: normal;
	font-weight: 300;
	font-display: swap;
}

@font-face {
	font-family: "taisyoRyakuji";
	src: url("/fonts/taisyoRyakuji.woff2") format("woff2");
	font-style: normal;
	font-weight: 400;
	font-display: swap;
}
`
		}
	]
});
