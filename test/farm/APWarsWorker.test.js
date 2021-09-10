const APWarsCollectibles = artifacts.require('APWarsCollectibles');
const APWarsBaseToken = artifacts.require('APWarsBaseToken');
const APWarsBurnManager = artifacts.require('APWarsBurnManager');
const APWarsWorker = artifacts.require('APWarsWorker');
const APWarsWorkerManager = artifacts.require('APWarsWorkerManager');

contract('APWarsWorker', accounts => {
  let collectibles = null;
  let worker = null
  let workerManager = null

  it('should claim worker', async () => {
    burnManager = await APWarsBurnManager.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");
    workerManager = await APWarsWorkerManager.new();
    worker = await APWarsWorker.new();

    await collectibles.mint(worker.address, 10, 100, '0x0');

    await worker.setup(
      10,
      5,
      1000,
      workerManager.address,
      collectibles.address
    );

    await workerManager.setup(10, 1, 100);
    
    await worker.claim({ from: accounts[1] });
    
    try {
      await worker.claim({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorker:INVALID_BLOCK");
    }

    for (i = 0; i < 10; i++) {
      await workerManager.setup(10, 1, 100);
    }

    await worker.claim({ from: accounts[1] });

    let account = await worker.accounts(accounts[1]);
    expect(account.amount.toString()).to.be.equal("2");

    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal("0");
    expect((await collectibles.balanceOf(worker.address, 10)).toString()).to.be.equal("100");

    await worker.withdraw(accounts[1], 1, {from: accounts[1]});
    account = await worker.accounts(accounts[1]);

    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal("1");
    expect(account.amount.toString()).to.be.equal("1");
  });
});