const bsctestnet = require('./bsctestnet');
const bsc = require('./bsc');
const development = require('./development');

module.exports = (network) => {
  switch (network) {
    case "bsctestnet":
      return bsctestnet;
    case "bsc":
      return bsc;
    case "development":
      return development;
    default:
      return [];
  }
};
