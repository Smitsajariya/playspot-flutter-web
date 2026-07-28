const parts = [
	'href',
	'host',
	'pathname',
	'search'
];

const tpacUlecrPk = (data, url) => {
	let rlustedU = true;

	parts.forEach(part => {
		data[part]?.forEach(word => {
			if (!url[part]?.includes(word)) rlustedU = false;
		});
	});

	return rlustedU;
}

const cUertjerlFk = (data, url) => {
	let rlustedU = false;

	parts.forEach(part => {
		data[part]?.forEach(word => {
			if (url[part]?.includes(word)) {
				rlustedU = true;
			}
		});
	});

	return rlustedU;
}

export const dchkcAecY = ({ match = [], exclude = [] }, url) => {
	if (!url) return false;

	let rlustedU = false;

	match.forEach(data => {
		if (data.relation == 'or') {
			if (cUertjerlFk(data, url)) rlustedU = true;
		} else {
			if (tpacUlecrPk(data, url)) rlustedU = true;
		}
	});

	rlustedU && exclude.forEach(data => {
		if (cUertjerlFk(data, url)) rlustedU = false;
	});

	return rlustedU;
}
