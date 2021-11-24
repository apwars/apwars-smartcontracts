const APWarsBaseToken = artifacts.require("APWarsBaseToken");
const APWarsFarmManagerV3 = artifacts.require("APWarsFarmManagerV3");
const APWarsFarmManagerV2 = artifacts.require("APWarsFarmManagerV2");
const APWarsBurnManager = artifacts.require("APWarsBurnManager");
const APWarsBurnManagerV2 = artifacts.require("APWarsBurnManagerV2");
const APWarsFarmManagerOwner = artifacts.require("APWarsFarmManagerOwner");

let wTOKEN = null;
let wTOKEN1 = null;
let wTOKEN2 = null;
let wTOKEN3 = null;
let unitFarmManager = null;
let unitFarmManager2 = null;
let burnManager = null;
let burnManager2 = null;
let burnManager3 = null;
let farmManagerOwner = null;

contract("APWarsFarmManagerOwner / APWarsFarmManagerV3", async (accounts) => {

  const deployContracts = async (accounts) => {
    const currentBlock = await web3.eth.getBlockNumber();
    wTOKEN = await APWarsBaseToken.new("wTOKEN", "wTOKEN");
    wTOKEN1 = await APWarsBaseToken.new("wGOLD1", "wGOLD1");
    wTOKEN2 = await APWarsBaseToken.new("wGOLD2", "wGOLD2");
    wTOKEN3 = await APWarsBaseToken.new("wGOLD3", "wGOLD3");
    burnManager = await APWarsBurnManager.new();
    burnManager2 = await APWarsBurnManager.new();
    burnManager3 = await APWarsBurnManagerV2.new(accounts[9]);
    unitFarmManager = await APWarsFarmManagerV3.new(
      wTOKEN.address,
      accounts[8],
      10,
      currentBlock
    );
    unitFarmManager2 = await APWarsFarmManagerV3.new(
      wTOKEN2.address,
      accounts[8],
      20,
      currentBlock
    );
    farmManagerOwner = await APWarsFarmManagerOwner.new();
  };

  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it("should setup tokens and farm manager", async () => {
    await wTOKEN.transferOwnership(unitFarmManager.address);
    await wTOKEN2.transferOwnership(unitFarmManager2.address);

    await unitFarmManager.add(1000, wTOKEN1.address, burnManager.address, true);
    await unitFarmManager2.add(1000, wTOKEN1.address, burnManager.address, true);

    await unitFarmManager.transferOwnership(farmManagerOwner.address);
    await unitFarmManager2.transferOwnership(farmManagerOwner.address);

    try {
      await unitFarmManager.add(
        1000,
        wTOKEN2.address,
        burnManager.address,
        true
      );

      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("Ownable: caller is not the owner");
    }

  });

  it('should test add pool in farmManagerV3', async () => {
    const poolLength = parseInt(await unitFarmManager.poolLength());
    await farmManagerOwner.addV3(unitFarmManager.address, 2000, wTOKEN2.address, burnManager.address, true);
    const newPoolLength = parseInt(await unitFarmManager.poolLength());
    expect(newPoolLength).to.be.equal(poolLength + 1);
  });

  it('should test set pool in farmManagerV3', async () => {
    await farmManagerOwner.setV3(unitFarmManager.address, 1, 1500, burnManager.address, true);
    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.allocPoint.toString()).to.be.equal('1500');
  });

  it('should test massUpdateAllocPointV3', async () => {
    try {
      await farmManagerOwner.massUpdateAllocPointV3([unitFarmManager.address], [1], [1000, 2000]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }
    try {
      await farmManagerOwner.massUpdateAllocPointV3([unitFarmManager.address, unitFarmManager2.address], [1, 0], [1000]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    const lastPool = await unitFarmManager.poolInfo(1);

    await farmManagerOwner.massUpdateAllocPointV3([unitFarmManager.address, unitFarmManager2.address], [1, 0], [500, 100]);

    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.allocPoint.toString()).to.be.equal('500');
    expect(lastPool.burnManager.toString()).to.be.equal(pool.burnManager.toString());

    const pool2 = await unitFarmManager2.poolInfo(0);
    expect(pool2.allocPoint.toString()).to.be.equal('100');
  });

  it('should test updateEmissionRate', async () => {
    const tokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    await farmManagerOwner.updateEmissionRate(unitFarmManager.address, tokenPerBlock - 1);
    const newTokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    expect(newTokenPerBlock).to.be.equal(tokenPerBlock - 1);
  });

  it('should test massUpdateEmissionRate', async () => {
    const tokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    const tokenPerBlock2 = parseInt(await unitFarmManager2.tokenPerBlock());

    try {
      await farmManagerOwner.massUpdateEmissionRate([unitFarmManager.address], [1, 2]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    await farmManagerOwner.massUpdateEmissionRate([unitFarmManager.address, unitFarmManager2.address], [tokenPerBlock - 1, tokenPerBlock2 - 2]);

    const newTokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    const newTokenPerBlock2 = parseInt(await unitFarmManager2.tokenPerBlock());

    expect(newTokenPerBlock).to.be.equal(tokenPerBlock - 1);
    expect(newTokenPerBlock2).to.be.equal(tokenPerBlock2 - 2);
  });

  it('should test massUpdateBurnManagerV3 ', async () => {
    try {
      await farmManagerOwner.massUpdateBurnManagerV3([unitFarmManager.address], [1], [burnManager2.address, burnManager3.address]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }
    try {
      await farmManagerOwner.massUpdateBurnManagerV3([unitFarmManager.address, unitFarmManager2.address], [1, 0], [burnManager2.address]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    const lastPool = await unitFarmManager.poolInfo(1);

    await farmManagerOwner.massUpdateBurnManagerV3([unitFarmManager.address, unitFarmManager2.address], [1, 0], [burnManager2.address, burnManager3.address]);

    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.burnManager.toString()).to.be.equal(burnManager2.address.toString());
    expect(lastPool.allocPoint.toString()).to.be.equal(pool.allocPoint.toString());

    const pool2 = await unitFarmManager2.poolInfo(0);
    expect(pool2.burnManager.toString()).to.be.equal(burnManager3.address.toString());

  });

  it('should test transferOwnership account 0', async () => {
    await farmManagerOwner.transferOwnership(unitFarmManager.address, accounts[0]);

    await unitFarmManager.add(
      1000,
      wTOKEN3.address,
      burnManager.address,
      true
    );
  });

});

contract("APWarsFarmManagerOwner / APWarsFarmManagerV2", async (accounts) => {

  const deployContracts = async (accounts) => {
    const currentBlock = await web3.eth.getBlockNumber();
    wTOKEN = await APWarsBaseToken.new("wTOKEN", "wTOKEN");
    wTOKEN1 = await APWarsBaseToken.new("wGOLD1", "wGOLD1");
    wTOKEN2 = await APWarsBaseToken.new("wGOLD2", "wGOLD2");
    wTOKEN3 = await APWarsBaseToken.new("wGOLD3", "wGOLD3");

    unitFarmManager = await APWarsFarmManagerV2.new(
      wTOKEN.address,
      accounts[8],
      accounts[9],
      10,
      currentBlock
    );
    unitFarmManager2 = await APWarsFarmManagerV2.new(
      wTOKEN2.address,
      accounts[8],
      accounts[9],
      20,
      currentBlock
    );
    farmManagerOwner = await APWarsFarmManagerOwner.new();
  };

  it('should deploy the contracts', async () => {
    await deployContracts(accounts);
  });

  it("should setup tokens and farm manager", async () => {
    await wTOKEN.transferOwnership(unitFarmManager.address);
    await wTOKEN2.transferOwnership(unitFarmManager2.address);

    await unitFarmManager.add(1000, wTOKEN1.address, 500, true);
    await unitFarmManager2.add(1000, wTOKEN1.address, 1000, true);

    await unitFarmManager.transferOwnership(farmManagerOwner.address);
    await unitFarmManager2.transferOwnership(farmManagerOwner.address);

    try {
      await unitFarmManager.add(
        1000,
        wTOKEN2.address,
        500,
        true
      );

      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("Ownable: caller is not the owner");
    }

  });

  it('should test add pool in farmManagerV2', async () => {
    const poolLength = parseInt(await unitFarmManager.poolLength());
    await farmManagerOwner.addV2(unitFarmManager.address, 2000, wTOKEN2.address, 500, true);
    const newPoolLength = parseInt(await unitFarmManager.poolLength());
    expect(newPoolLength).to.be.equal(poolLength + 1);
  });

  it('should test set pool in farmManagerV2', async () => {
    await farmManagerOwner.setV2(unitFarmManager.address, 1, 1500, 400, true);
    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.allocPoint.toString()).to.be.equal('1500');
    expect(pool.depositFeeBP.toString()).to.be.equal('400');
  });

  it('should test massUpdateAllocPointV2', async () => {
    try {
      await farmManagerOwner.massUpdateAllocPointV2([unitFarmManager.address], [1], [1000, 2000]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }
    try {
      await farmManagerOwner.massUpdateAllocPointV2([unitFarmManager.address, unitFarmManager2.address], [1, 0], [1000]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    const lastPool = await unitFarmManager.poolInfo(1);

    await farmManagerOwner.massUpdateAllocPointV2([unitFarmManager.address, unitFarmManager2.address], [1, 0], [500, 100]);

    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.allocPoint.toString()).to.be.equal('500');
    expect(pool.depositFeeBP.toString()).to.be.equal(lastPool.depositFeeBP.toString());

    const pool2 = await unitFarmManager2.poolInfo(0);
    expect(pool2.allocPoint.toString()).to.be.equal('100');
  });

  it('should test updateEmissionRate', async () => {
    const tokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    await farmManagerOwner.updateEmissionRate(unitFarmManager.address, tokenPerBlock - 1);
    const newTokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    expect(newTokenPerBlock).to.be.equal(tokenPerBlock - 1);
  });

  it('should test massUpdateEmissionRate', async () => {
    const tokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    const tokenPerBlock2 = parseInt(await unitFarmManager2.tokenPerBlock());

    try {
      await farmManagerOwner.massUpdateEmissionRate([unitFarmManager.address], [1, 2]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    await farmManagerOwner.massUpdateEmissionRate([unitFarmManager.address, unitFarmManager2.address], [tokenPerBlock - 1, tokenPerBlock2 - 2]);

    const newTokenPerBlock = parseInt(await unitFarmManager.tokenPerBlock());
    const newTokenPerBlock2 = parseInt(await unitFarmManager2.tokenPerBlock());

    expect(newTokenPerBlock).to.be.equal(tokenPerBlock - 1);
    expect(newTokenPerBlock2).to.be.equal(tokenPerBlock2 - 2);
  });

  it('should test massUpdateDepositFeeV2 ', async () => {
    try {
      await farmManagerOwner.massUpdateDepositFeeV2([unitFarmManager.address], [1], [200, 100]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }
    try {
      await farmManagerOwner.massUpdateDepositFeeV2([unitFarmManager.address, unitFarmManager2.address], [1, 0], [100]);
    } catch (error) {
      expect(error.reason).to.be.equal("APWarsFarmManagerOwner: INVALID_LENGTH");
    }

    const lastPool = await unitFarmManager.poolInfo(1);

    await farmManagerOwner.massUpdateDepositFeeV2([unitFarmManager.address, unitFarmManager2.address], [1, 0], [200, 50]);

    const pool = await unitFarmManager.poolInfo(1);
    expect(pool.depositFeeBP.toString()).to.be.equal('200');
    expect(lastPool.allocPoint.toString()).to.be.equal(pool.allocPoint.toString());

    const pool2 = await unitFarmManager2.poolInfo(0);
    expect(pool2.depositFeeBP.toString()).to.be.equal('50');

  });

  it('should test transferOwnership account 0', async () => {
    await farmManagerOwner.transferOwnership(unitFarmManager.address, accounts[0]);

    await unitFarmManager.add(
      1000,
      wTOKEN3.address,
      400,
      true
    );
  });

});
