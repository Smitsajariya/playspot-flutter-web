(() => {
	const cookies = document.cookie.split('; ');

	const uaval = cookies.find(etimHu => etimHu.startsWith('uaval='));
	const appval = cookies.find(etimHu => etimHu.startsWith('appval='));
	const entval = cookies.find(etimHu => etimHu.startsWith('entval='));

	const [, _userAgent] = uaval ? uaval.split('=') : [];
	const [, _appVersion] = appval ? appval.split('=') : [];
	const [, _entValues] = entval ? entval.split('=') : [];

	const userAgent = _userAgent ? atob(_userAgent) : null;
	const appVersion = _appVersion ? atob(_appVersion) : null;
	const entValues = _entValues ? atob(_entValues) : null;

	if (!userAgent && !appVersion && !entValues) return;

	const originalUserAgent = navigator.userAgent;

	function modifyUA(nav) {
		if (userAgent) {
			nav.__defineGetter__('userAgent', () => userAgent);
		}

		if (appVersion) {
			nav.__defineGetter__('appVersion', () => appVersion);
		}

		if (entValues) {
			try {
				const userAgentData = JSON.parse(entValues);

				function NavigatorUAData() {
					this.brands = [...userAgentData.fullVersionList];
					this.mobile = false;
					this.platform = 'Windows';
				}

				NavigatorUAData.prototype.getHighEntropyValues = function (list = []) {
					if (list.length) {
						const output = [...list].reduce((acc, val) => {
							acc[val] = userAgentData[val];
							return acc;
						}, {});

						return Promise.resolve({
							brands: [...userAgentData.fullVersionList],
							mobile: false,
							platform: 'Windows',
							...output,
						});
					} else {
						return Promise.reject(new Error('1 argument required, but only 0 present.'));
					}
				};

				NavigatorUAData.prototype.toJSON = function() {
					return {
						brands: [...userAgentData.fullVersionList],
						mobile: false,
						platform: 'Windows',
					};
				};

				const instance = new NavigatorUAData();

				nav.__defineGetter__('userAgentData', () => instance);
			} catch(e) {

			}
		}
	}

	modifyUA(navigator);

	const appendChild = Node.prototype.appendChild;
	const createElement = Document.prototype.createElement;

	Document.prototype.createElement = function (node) {
		if (node === 'iframe') {
			Node.prototype.appendChild = function (node) {
				const isIframe = node && node.localName == 'iframe' && node.src.startsWith('javascript');

				if (isIframe) {
					const sandbox = node.getAttribute('sandbox');

					if (sandbox && !sandbox.includes('allow-scripts')) {
						node.setAttribute('sandbox', sandbox + ' allow-scripts');
					}
				}

				const returned = appendChild.call(this, node);

				if (isIframe && node.contentWindow) {
					modifyUA(node.contentWindow.navigator);
				}

				return returned;
			};
		}

		return createElement.call(this, node);
	};

	const originalfetch = window.fetch;

	window.fetch = async (request, options) => {
		const originalResponse = await originalfetch(request, options);
		const { body, ...rest } = originalResponse;

		const text = await originalResponse.clone().text();

		if (text.includes(originalUserAgent)) {
			const modified = userAgent ? text.replace(originalUserAgent, userAgent) : text;
			return new Response(modified, { ...rest });
		}
		
		return originalResponse;
	}
})();