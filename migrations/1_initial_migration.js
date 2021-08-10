const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }
  
  deployer.deploy(Migrations);
};
