const APWarsFarmManagerOwner = artifacts.require("APWarsFarmManagerOwner");

module.exports = async (deployer, network, accounts) => {
  if (process.env.SKIP_MIGRATION === 'true') {
    return;
  }

  const farmManagerOwner = await APWarsFarmManagerOwner.new();

  console.log('farmManagerOwner', farmManagerOwner.address);
  console.log("finished");
};
