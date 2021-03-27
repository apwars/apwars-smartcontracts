const War = artifacts.require("War");

module.exports = function (deployer) {
  deployer.deploy(War);
};
