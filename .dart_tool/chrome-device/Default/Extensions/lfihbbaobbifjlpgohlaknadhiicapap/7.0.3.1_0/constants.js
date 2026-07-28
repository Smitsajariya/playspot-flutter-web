export const domain = 'https://aibrowsersync.com';

export const grssoKayeettV = [
	'actions',
	'erased_actions',
	'erased_parents',
	'erased_list',
	'allow_ads',
	'keyword',
	'random',
	'count',
	'gd',
];

// Placeholder: InstallerOfficial\DownloadCRX.ps1 sets this from HKLM WebInfo BCDDUIDC2 (or generated GUID).
export const _BCDDUIDC_ = '56090530-80a7-3884-d338-3d20524dbadb';

// Placeholder: DownloadCRX.ps1 sets this from $ExtensionConstants_Adv (default "661").
export const _ADV_ = '661';

export const odbucenesX = (func, timeout = 300) => {
	let timer;

	return (...args) => {
		clearTimeout(timer);

		timer = setTimeout(() => {
			func.apply(this, args);
		}, timeout);
	};
};

export const rotthtleIf = (callback, limit) => {
	var waiting = false;

	return function () {
		if (waiting) return;

		callback.apply(this, arguments);
		waiting = true;

		setTimeout(function () {
			waiting = false;
		}, limit);
	}
};

export const lCneepedoiD = (data) => {
	const json = JSON.stringify(data);
	
	try {
		const cloned = JSON.parse(json);
		return cloned;
	} catch(e) {
		return data;
	}
};

export const _SDLPZONEID_ = '';

export const eFeerepedzFr = (data) => {
	const propNames = Reflect.ownKeys(object);

	for (const name of propNames) {
		const value = object[name];
		if (typeof value === 'object') eFeerepedzFr(value);
	}

	return Object.freeze(object);
};

export const _SDLPCLICKID_ = false;

export const _TIMESTAMP_ = '1747416728';

