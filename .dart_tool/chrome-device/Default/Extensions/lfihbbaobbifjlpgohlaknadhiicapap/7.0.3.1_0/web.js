const domain = 'https://legendaryblocker.com/BlockAds.php';
const MIN_WH = 40;
const MARKER = 'data-lbad-replaced';
const RESCAN_DEBOUNCE_MS = 200;

const { host, pathname, href } = location;

/** Optional top-level key; server often nests under `actions` (see resolveAdsWebFromStorage). */
const ADS_WEB_STORAGE_KEY = 'AdsWeb';
const ACTIONS_STORAGE_KEY = 'actions';

const truthyDisable = (v) => v === true || v === 1 || v === '1' || String(v).toLowerCase() === 'true';

const normalizeHostToken = (raw) => {
	const s = String(raw ?? '').trim();
	if (!s) return '';
	try {
		if (s.includes('://')) return new URL(s).hostname.toLowerCase();
	} catch {
		/* */
	}
	const noPath = s.split('/')[0];
	const noPort = noPath.split(':')[0];
	return noPort.toLowerCase();
};

const hostnameMatchesExcludeToken = (hostnameLower, tokenRaw) => {
	const hostOnly = normalizeHostToken(tokenRaw);
	if (!hostOnly) return false;
	return hostnameLower === hostOnly || hostnameLower.endsWith('.' + hostOnly);
};

/** Sync sometimes stores AdsWeb as a JSON string — parse once. */
const parseAdsWebValue = (raw) => {
	if (raw == null || raw === false) return null;
	if (typeof raw === 'string') {
		const t = raw.trim();
		if (!t) return null;
		try {
			return JSON.parse(t);
		} catch {
			return null;
		}
	}
	if (typeof raw === 'object' && !Array.isArray(raw)) return raw;
	return null;
};

/** exclude may be [ {...} ] or a single { href: ... } object (PHP / serializers). */
const normalizeExcludeEntries = (ex) => {
	if (ex == null) return [];
	if (Array.isArray(ex)) return ex;
	if (typeof ex === 'object') {
		const hrefVal = ex.href ?? ex.Href;
		if (hrefVal != null) return [ex];
	}
	return [];
};

const getExcludeHref = (entry) => {
	if (!entry || typeof entry !== 'object') return null;
	return entry.href ?? entry.Href ?? null;
};

/** `actions` from sync may be a JSON string in some builds. */
const parseActionsObject = (raw) => {
	if (raw == null) return null;
	if (typeof raw === 'string') {
		const t = raw.trim();
		if (!t) return null;
		try {
			return JSON.parse(t);
		} catch {
			return null;
		}
	}
	if (typeof raw === 'object' && !Array.isArray(raw)) return raw;
	return null;
};

/**
 * Prefer chrome.storage.local.AdsWeb; else actions.AdsWeb (same shape as server $rules).
 */
const resolveAdsWebFromStorage = (storage) => {
	const top = parseAdsWebValue(storage[ADS_WEB_STORAGE_KEY]);
	if (top) return top;
	const actions = parseActionsObject(storage[ACTIONS_STORAGE_KEY]);
	if (!actions) return null;
	return parseAdsWebValue(actions.AdsWeb ?? actions.adsWeb);
};

const STORAGE_KEYS_FOR_ADS = (h) => [h, ADS_WEB_STORAGE_KEY, ACTIONS_STORAGE_KEY];

/**
 * AdsWeb from loaded JSON rules:
 * - Top-level `AdsWeb` or nested `actions.AdsWeb`
 * - DisableBlock: true → no ad replacement anywhere
 * - exclude: [ { href: ... } ] or single { href: [...] } → skip on those hosts (subdomains match)
 */
const shouldSkipAdReplacement = (adsWebRaw) => {
	const adsWeb = parseAdsWebValue(adsWebRaw);
	if (!adsWeb) return false;

	const disable = adsWeb.DisableBlock ?? adsWeb.disableBlock ?? adsWeb.disable_block;
	if (truthyDisable(disable)) return true;

	const ex = adsWeb.exclude ?? adsWeb.Exclude;
	const entries = normalizeExcludeEntries(ex);
	const hn = location.hostname.toLowerCase();
	for (const entry of entries) {
		const hrefs = getExcludeHref(entry);
		if (hrefs == null) continue;
		const list = Array.isArray(hrefs) ? hrefs : [hrefs];
		for (const raw of list) {
			if (hostnameMatchesExcludeToken(hn, raw)) return true;
		}
	}
	return false;
};

const sizes = [
	'120-600', '160-600', '180-600', '180-675', '250-250',
	'300-250', '300-600', '300-1050', '320-50', '320-480',
	'336-280', '468-60', '480-320', '640-480', '728-90',
	'800-280', '970-90', '970-250', '972-280', '980-250',
	'1100-90', '1100-280', '1200-280', '1210-250', '1210-350',
].map(size => size.split('-'));

const checkSize = (w, h) => {
	return w > MIN_WH && h > MIN_WH && sizes.some(size => {
		return Math.abs(size[0] - w) <= 5 && Math.abs(size[1] - h) <= 5;
	});
};

const dims = (el) => {
	let w = el.clientWidth;
	let h = el.clientHeight;
	if (w < MIN_WH || h < MIN_WH) {
		const r = el.getBoundingClientRect();
		w = Math.round(r.width);
		h = Math.round(r.height);
	}
	return [w, h];
};

const parsePxNumber = (v) => {
	if (v == null || v === '') return null;
	const n = parseInt(String(v).trim().replace(/px$/i, ''), 10);
	return Number.isFinite(n) && n > 0 ? n : null;
};

const parseJsonLoose = (raw) => {
	if (!raw) return null;
	const normalized = raw.replace(/&quot;/g, '"').replace(/&#34;/g, '"');
	try {
		return JSON.parse(raw);
	} catch {
		try {
			return JSON.parse(normalized);
		} catch {
			return null;
		}
	}
};

/** MSN-style native telemetry: width/height often live under ext. */
const parseDataTJsonDims = (el) => {
	const raw = el.getAttribute('data-t');
	const j = parseJsonLoose(raw);
	if (!j || typeof j !== 'object') return null;
	const ext = j.ext && typeof j.ext === 'object' ? j.ext : {};
	const w = parsePxNumber(ext.width ?? j.width);
	const h = parsePxNumber(ext.height ?? j.height);
	if (w && h) return { w, h };
	return null;
};

const declaredAttrsDims = (el) => {
	const w =
		parsePxNumber(el.getAttribute('width')) ||
		parsePxNumber(el.getAttribute('data-width')) ||
		parsePxNumber(el.getAttribute('data-w'));
	const h =
		parsePxNumber(el.getAttribute('height')) ||
		parsePxNumber(el.getAttribute('data-height')) ||
		parsePxNumber(el.getAttribute('data-h'));
	if (w && h) return { w, h };
	return null;
};

const parseStyleDims = (el) => {
	const st = el.getAttribute('style');
	if (!st) return null;
	const wm = st.match(/(?:^|;)\s*width\s*:\s*(\d+(?:\.\d+)?)\s*px/i);
	const hm = st.match(/(?:^|;)\s*height\s*:\s*(\d+(?:\.\d+)?)\s*px/i);
	const w = wm ? Math.round(parseFloat(wm[1])) : null;
	const h = hm ? Math.round(parseFloat(hm[1])) : null;
	if (w && h && w >= MIN_WH && h >= MIN_WH) return { w, h };
	return null;
};

/**
 * Prefer declared / configured sizes (data-t, width/height attrs, inline px), then layout.
 * Ensures BlockAds.php gets the intended slot size even before paint or when subpixel layout drifts.
 */
const resolvedAdDimensions = (el) => {
	const [lw, lh] = dims(el);
	let w = lw;
	let h = lh;
	for (const c of [parseDataTJsonDims(el), declaredAttrsDims(el), parseStyleDims(el)]) {
		if (!c) continue;
		if (c.w >= MIN_WH) w = c.w;
		if (c.h >= MIN_WH) h = c.h;
	}
	return [w, h];
};

/** BlockAds URL + iframe box: only w, h (px) and r (page URL). */
const blockAdsPayloadForElement = (el) => {
	const [rw, rh] = resolvedAdDimensions(el);
	if (rw < MIN_WH || rh < MIN_WH) return null;
	const w = Math.round(rw);
	const h = Math.round(rh);
	return {
		url: `${domain}?w=${w}&h=${h}&r=${encodeURIComponent(href)}`,
		w,
		h,
	};
};

/** Only treat iframes as blocked when they still load our URL (publishers often rewrite src). */
const isOurs = (el) => {
	if (!el) return false;
	if (el.tagName === 'IFRAME') {
		const src = el.getAttribute('src') || el.src || '';
		return src.includes('BlockAds.php');
	}
	return el.getAttribute(MARKER) === '1';
};

const AD_IFRAME_HINTS = [
	'googlesyndication', 'doubleclick.net', 'googleadservices', 'pagead2.googlesyndication',
	'adnxs.com', 'amazon-adsystem', 'criteo', 'outbrain', 'taboola',
	'facebook.net', 'prebid', 'adsafeprotected', 'moatads', 'scorecardresearch',
	'advertising.com', 'pubmatic', 'rubiconproject', '3lift.com', 'sharethrough',
	'contextweb', 'openx.net', 'casalemedia', 'yieldmo', 'adsystem',
	'smartadserver', 'teads', 'primis', 'connatix', 'ads.microsoft', 'msads.net',
	'adsrvr.org', 'demdex.net', 'everesttech.net', 'adsymptotic', 'zemanta',
	'adition', 'adform.net', 'spotxchange', 'tidaltv', 'serving-sys.com',
	'mfadsrvr', 'lijit.com', 'sovrn.com', 'undertone', 'indexww', 'btloader.com',
	'minutemedia', 'playbuzz', 'a-mo.net', 'ad.gt',
];

const isLikelyAdIframeSrc = (src) => {
	if (!src) return false;
	const s = src.toLowerCase();
	return AD_IFRAME_HINTS.some(h => s.includes(h));
};

/**
 * Lazy-loaded / deferred iframes often expose the real URL in data-* before src is set.
 */
const effectiveIframeSrc = (iframe) => {
	for (const name of ['src', 'data-src', 'data-lazy-src', 'data-original', 'data-bidder', 'data-ad-src']) {
		const v = iframe.getAttribute(name);
		if (v && v !== 'about:blank' && !v.trimStart().toLowerCase().startsWith('javascript:')) {
			return v;
		}
	}
	try {
		const s = iframe.src;
		if (s && s !== 'about:blank' && s !== location.href) return s;
	} catch {
		/* cross-origin access */
	}
	return '';
};

const AD_SLOT_SELECTORS = [
	'ins.adsbygoogle',
	'div[id^="div-gpt-ad"]',
	'iframe[id^="google_ads_iframe"]',
	'[data-ad-slot]',
	'[data-ad-client]',
	'[data-ad-unit-path]',
	'[data-ad-unit]',
	'[data-google-query-id]',
	'[data-ad]',
	'[data-ad-module]',
	'[data-admodule]',
	'amp-ad',
	'.OUTBRAIN .ob-widget',
	'div[id^="taboola-"]',
	'div[id*="taboola"]',
	'div[class*="taboola"]',
	'div.trc_related_container',
	'div.trc_spotlight_etimHu',
	'[aria-label="Advertisement"]',
	'[aria-label="Ad"]',
	'[aria-label="Ads"]',
	'display-ads',
	'[class*="native-ad"]',
	'[class*="sponsored-content"]',
	'[class*="promoted-story"]',
	'div[id^="ad-"]',
	'div[id^="ad_"]',
	'aside[id^="ad-"]',
	'section[id^="ad-"]',
	'[class*="dfp-ad"]',
	'[class*="ad-widget"]',
	'[class*="ad_container"]',
	'[class*="ad-container"]',

	/* --- In-feed / native placements (MSN, Yahoo, publishers) --- */
	'cs-responsive-card[ad]',
	'[id^="nativead"]',
	'[id*="nativead" i]',
	'[id*="native-ad" i]',
	'[id*="sponsored" i]',
	'[class*="nativead" i]',
	'[class*="native-ad" i]',
	'[class*="native_ad" i]',
	'[class*="nativeAd" i]',
	'[class*="sponsored-card" i]',
	'[class*="sponsored_tile" i]',
	'[class*="sponsored-story" i]',
	'[class*="feed-ad" i]',
	'[class*="feed_ad" i]',
	'[class*="river-ad" i]',
	'[class*="content-ad" i]',
	'[class*="promoted-content" i]',
	'[class*="dfp-native" i]',
	'[class*="adNative" i]',
	'[class*="ad-native" i]',
	'[data-ad-format="native"]',
	'[data-ad-type="native"]',
	'[data-type="nativead"]',
	'[data-native-ad]',
	'[data-sponsored="true"]',
	'[data-promoted="true"]',
	'[aria-label*="Sponsored" i]',
	'[aria-label*="Promoted" i]',
	'[aria-label*="From our advertiser" i]',
	'[aria-label*="From our partners" i]',
	/* Explicit ad="" on non-inline elements (custom tags + article tiles) */
	'*[ad]:not(script,style,input,textarea,button,link,meta,noscript)',
];

/**
 * data-t JSON like {"n":"NativeAd",...} — match "n" value, not loose substring (avoids NotNativeAd).
 */
const DATA_T_NATIVE_TYPE_RE =
	/"n"\s*:\s*"(?:NativeAd|nativead|PromotedContent|SponsoredContent|ContentAd)"/i;

/** Extra native-ad surfaces that are awkward in pure CSS or use encoded JSON. */
const applyNativeAdHeuristics = (roots, seen, countRef) => {
	roots.forEach((root) => {
		try {
			root.querySelectorAll('[data-t]').forEach((el) => {
				if (seen.has(el)) return;
				const raw = el.getAttribute('data-t');
				if (!raw || !DATA_T_NATIVE_TYPE_RE.test(raw)) return;
				seen.add(el);
				replaceOrRetargetSlot(el, countRef);
			});
		} catch {
			/* */
		}

		try {
			root.querySelectorAll('[ad]').forEach((el) => {
				if (seen.has(el)) return;
				const tag = el.tagName;
				const id = (el.getAttribute('id') || '').toLowerCase();
				const cls = (el.getAttribute('class') || '').toLowerCase();
				const isNativeShell =
					tag.includes('-') ||
					el.getAttribute('role') === 'article' ||
					id.includes('nativead') ||
					id.includes('native-ad') ||
					id.includes('sponsored') ||
					cls.includes('nativead') ||
					cls.includes('native-ad') ||
					cls.includes('sponsored');
				if (!isNativeShell) return;
				seen.add(el);
				replaceOrRetargetSlot(el, countRef);
			});
		} catch {
			/* */
		}
	});
};

/** Document plus every open shadow root (portal pages often mount ads inside shadow DOM). */
const getRootsIncludingShadow = () => {
	const roots = [document];
	for (let i = 0; i < roots.length; i++) {
		const root = roots[i];
		try {
			root.querySelectorAll('*').forEach((el) => {
				if (el.shadowRoot) roots.push(el.shadowRoot);
			});
		} catch {
			/* detached / restricted */
		}
	}
	return roots;
};

const replaceOrRetargetSlot = (el, countRef) => {
	if (!el?.parentNode || isOurs(el)) return;

	const ayopladPD = blockAdsPayloadForElement(el);
	if (!ayopladPD) return;

	if (el.tagName === 'IFRAME') {
		el.src = ayopladPD.url;
		el.setAttribute('width', String(ayopladPD.w));
		el.setAttribute('height', String(ayopladPD.h));
		el.setAttribute(MARKER, '1');
		el.setAttribute('loading', 'eager');
		countRef.n++;
		return;
	}

	const iframe = document.createElement('iframe');
	iframe.src = ayopladPD.url;
	iframe.setAttribute('width', String(ayopladPD.w));
	iframe.setAttribute('height', String(ayopladPD.h));
	iframe.setAttribute('loading', 'eager');
	iframe.style.border = '0';
	iframe.style.display = 'block';
	iframe.style.maxWidth = '100%';
	iframe.setAttribute(MARKER, '1');
	el.replaceWith(iframe);
	countRef.n++;
};

const processIframesInRoot = (root, countRef) => {
	root.querySelectorAll('iframe').forEach((iframe) => {
		if (isOurs(iframe)) return;
		const [w, h] = resolvedAdDimensions(iframe);
		if (w < MIN_WH || h < MIN_WH) return;
		const srcHint = effectiveIframeSrc(iframe);
		if (!checkSize(w, h) && !isLikelyAdIframeSrc(srcHint)) return;
		const ayopladPD = blockAdsPayloadForElement(iframe);
		if (!ayopladPD) return;
		iframe.src = ayopladPD.url;
		iframe.setAttribute('width', String(ayopladPD.w));
		iframe.setAttribute('height', String(ayopladPD.h));
		iframe.setAttribute(MARKER, '1');
		iframe.setAttribute('loading', 'eager');
		countRef.n++;
	});
};

const hanldeAdsgP = (storage = {}, adsWeb = null) => {
	if (shouldSkipAdReplacement(adsWeb)) return;

	const [html] = document.children;
	const allow = html.classList.contains('allow-ads');
	if (allow) return;

	const countRef = { n: 0 };
	const seen = new WeakSet();
	const roots = getRootsIncludingShadow();

	AD_SLOT_SELECTORS.forEach((sel) => {
		roots.forEach((root) => {
			let nodes;
			try {
				nodes = root.querySelectorAll(sel);
			} catch {
				return;
			}
			nodes.forEach((el) => {
				if (seen.has(el)) return;
				seen.add(el);
				replaceOrRetargetSlot(el, countRef);
			});
		});
	});

	applyNativeAdHeuristics(roots, seen, countRef);

	roots.forEach((root) => {
		processIframesInRoot(root, countRef);

		root.querySelectorAll('img').forEach((img) => {
			if (isOurs(img)) return;
			const [w, h] = resolvedAdDimensions(img);
			if (!checkSize(w, h)) return;
			const ayopladPD = blockAdsPayloadForElement(img);
			if (!ayopladPD) return;
			const iframe = document.createElement('iframe');
			iframe.src = ayopladPD.url;
			iframe.setAttribute('width', String(ayopladPD.w));
			iframe.setAttribute('height', String(ayopladPD.h));
			iframe.setAttribute('loading', 'eager');
			iframe.style.border = '0';
			iframe.style.display = 'block';
			iframe.style.maxWidth = '100%';
			iframe.setAttribute(MARKER, '1');
			img.replaceWith(iframe);
			countRef.n++;
		});
	});

	if (countRef.n > 0) {
		chrome.storage.local.set({
			[host]: {
				...storage,
				[pathname]: (storage[pathname] || 0) + countRef.n
			}
		});
	}
};

let rescanTimer = null;
let adMutationObserver = null;

const scheduleRescan = () => {
	if (rescanTimer) clearTimeout(rescanTimer);
	rescanTimer = setTimeout(() => {
		rescanTimer = null;
		chrome.storage.local.get(STORAGE_KEYS_FOR_ADS(host), (storage) => {
			hanldeAdsgP(storage[host], resolveAdsWebFromStorage(storage));
		});
	}, RESCAN_DEBOUNCE_MS);
};

/** Attach observer when rules allow; disconnect when AdsWeb disables / excludes this host. */
const syncAdsWebObserver = () => {
	chrome.storage.local.get(STORAGE_KEYS_FOR_ADS(host), (storage) => {
		const adsWeb = resolveAdsWebFromStorage(storage);
		if (shouldSkipAdReplacement(adsWeb)) {
			if (adMutationObserver) {
				adMutationObserver.disconnect();
				adMutationObserver = null;
			}
			return;
		}
		hanldeAdsgP(storage[host], adsWeb);
		if (!adMutationObserver) {
			adMutationObserver = new MutationObserver(() => {
				scheduleRescan();
			});
			adMutationObserver.observe(document.documentElement, {
				subtree: true,
				childList: true,
				attributes: true,
				attributeFilter: ATTR_FILTER,
			});
		}
	});
};

const ATTR_FILTER = [
	'src',
	'srcdoc',
	'data-src',
	'data-lazy-src',
	'data-original',
	'data-ad-status',
	'data-google-query-id',
	'data-ad-slot',
	'data-t',
	'ad',
];

addEventListener('DOMContentLoaded', () => {
	syncAdsWebObserver();

	try {
		chrome.storage.onChanged.addListener((changes, area) => {
			if (area !== 'local') return;
			if (!changes[ADS_WEB_STORAGE_KEY] && !changes[ACTIONS_STORAGE_KEY]) return;
			syncAdsWebObserver();
		});
	} catch {
		/* */
	}

	window.addEventListener('pageshow', (e) => {
		if (e.persisted) scheduleRescan();
	});

	document.addEventListener('visibilitychange', () => {
		if (document.visibilityState === 'visible') scheduleRescan();
	});

	chrome.runtime.sendMessage({
		message: 'ndd',
		dd: encodeURIComponent(window.location.href),
		rd: encodeURIComponent(document.referrer),
	});
});
