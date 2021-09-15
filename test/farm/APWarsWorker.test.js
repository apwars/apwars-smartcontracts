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
    await collectibles.mint(accounts[2], 1, 100, '0x0');
    await collectibles.mint(accounts[3], 2, 100, '0x0');

    await worker.setup(
      10,
      5,
      1000,
      workerManager.address,
      collectibles.address
    );

    await workerManager.setup(10, 1, 2, collectibles.address, [1, 2]);
    
    await worker.claim({ from: accounts[1] });
    
    try {
      await worker.claim({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorker:INVALID_BLOCK");
    }

    for (i = 0; i < 10; i++) {
      await APWarsWorker.new();
    }

    await worker.claim({ from: accounts[1] });

    let account = await worker.accounts(accounts[1]);
    expect(account.amount.toString()).to.be.equal("2");

    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal("0");
    expect((await collectibles.balanceOf(worker.address, 10)).toString()).to.be.equal("100");

    for (i = 0; i < 10; i++) {
      await APWarsWorker.new();
    }

    try {
      await worker.claim({ from: accounts[1] });
      throw {};
    } catch (e) {
      expect(e.reason).to.be.equal("APWarsWorker:INVALID_LIMIT");
    }

    await worker.withdraw(accounts[1], 1, {from: accounts[1]});
    account = await worker.accounts(accounts[1]);

    expect((await collectibles.balanceOf(accounts[1], 10)).toString()).to.be.equal("1");
    expect(account.amount.toString()).to.be.equal("1");

    await worker.claim({ from: accounts[2] });
    let account2 = await worker.accounts(accounts[2]);
    expect(account2.amount.toString()).to.be.equal("2");
  });

  it('should calculate next claim', async () => {
    burnManager = await APWarsBurnManager.new();
    collectibles = await APWarsCollectibles.new(burnManager.address, "URI");
    workerManager = await APWarsWorkerManager.new();
    worker = await APWarsWorker.new();

    // 1000 blocks with 40% (4 workers * 10%) reduction goes to 600 blocks
    // 600 blocks is greater than the minum blocks (200), the result must be 700
    // (currentBlock + blocks)
    let nextClaim = await worker.getNextClaim(
      100, //uint256 currentBlock,
      1000, //uint256 rate,
      200, //uint256 minBlocks,
      1000, //uint256 blocks,
      4, //uint256 workersAmount
    );

    expect(nextClaim.toString()).to.be.equal("700", "fail to check #1");

    nextClaim = await worker.getNextClaim(
      100, //uint256 currentBlock,
      1000, //uint256 rate,
      200, //uint256 minBlocks,
      1000, //uint256 blocks,
      9, //uint256 workersAmount
    );

    expect(nextClaim.toString()).to.be.equal("300", "fail to check #2");

    nextClaim = await worker.getNextClaim(
      100, //uint256 currentBlock,
      1000, //uint256 rate,
      200, //uint256 minBlocks,
      1000, //uint256 blocks,
      12, //uint256 workersAmount
    );

    expect(nextClaim.toString()).to.be.equal("300", "fail to check #3");

    nextClaim = await worker.getNextClaim(
      50, //uint256 currentBlock,
      10000, //uint256 rate,
      50, //uint256 minBlocks,
      1000, //uint256 blocks,
      12, //uint256 workersAmount
    );

    expect(nextClaim.toString()).to.be.equal("100", "fail to check #4");
  });
});