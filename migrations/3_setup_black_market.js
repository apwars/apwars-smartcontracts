const APWarsCollectibles = artifacts.require("APWarsCollectibles");
const APWarsGoldToken = artifacts.require("APWarsGoldToken");
const APWarsMarketNFTSwapEscrow = artifacts.require(
  "APWarsMarketNFTSwapEscrow"
);

module.exports = async (deployer, network, accounts) => {
  const collectibles = await APWarsCollectibles.deployed();

  await collectibles.mint(accounts[0], 14, 50, "0x0");
  await collectibles.mint(accounts[1], 15, 50, "0x0");
  await collectibles.mint(accounts[2], 16, 50, "0x0");
  await collectibles.mint(accounts[3], 17, 50, "0x0");
  await deployer.deploy(APWarsMarketNFTSwapEscrow);
  escrow = await APWarsMarketNFTSwapEscrow.deployed();

  const wGOLD = await APWarsGoldToken.deployed();
  await wGOLD.transfer(accounts[0], web3.utils.toWei("5000", "ether"));
  await wGOLD.transfer(accounts[1], web3.utils.toWei("5000", "ether"));
  await wGOLD.transfer(accounts[2], web3.utils.toWei("5000", "ether"));
  await wGOLD.transfer(accounts[3], web3.utils.toWei("5000", "ether"));
  await wGOLD.transfer(accounts[7], web3.utils.toWei("5000", "ether"));

  await escrow.setup(accounts[9], 250, [wGOLD.address]);

  // Approves
  await wGOLD.approve(escrow.address, web3.utils.toWei("100000000", "ether"), {
    from: accounts[0],
  });
  await wGOLD.approve(escrow.address, web3.utils.toWei("100000000", "ether"), {
    from: accounts[1],
  });
  await wGOLD.approve(escrow.address, web3.utils.toWei("100000000", "ether"), {
    from: accounts[2],
  });
  await wGOLD.approve(escrow.address, web3.utils.toWei("100000000", "ether"), {
    from: accounts[3],
  });
  await collectibles.setApprovalForAll(escrow.address, true, {
    from: accounts[0],
  });
  await collectibles.setApprovalForAll(escrow.address, true, {
    from: accounts[1],
  });
  await collectibles.setApprovalForAll(escrow.address, true, {
    from: accounts[2],
  });
  await collectibles.setApprovalForAll(escrow.address, true, {
    from: accounts[3],
  });

  // send account 7
  collectibles.safeTransferFrom(accounts[0], accounts[7], 14, 10, "0x0", {
    from: accounts[0],
  });
  collectibles.safeTransferFrom(accounts[1], accounts[7], 15, 10, "0x0", {
    from: accounts[1],
  });
  collectibles.safeTransferFrom(accounts[2], accounts[7], 16, 10, "0x0", {
    from: accounts[2],
  });
  collectibles.safeTransferFrom(accounts[3], accounts[7], 17, 10, "0x0", {
    from: accounts[3],
  });

  // create order BUY and execute
  await escrow.createOrder(
    0,
    collectibles.address,
    14,
    wGOLD.address,
    web3.utils.toWei("200", "ether"),
    1,
    { from: accounts[1] }
  );
  // await escrow.executeOrder(0, { from: accounts[0] });
  // create orderns BUY

  await escrow.createOrder(
    0,
    collectibles.address,
    14,
    wGOLD.address,
    web3.utils.toWei("700", "ether"),
    1,
    { from: accounts[1] }
  );

  await escrow.createOrder(
    0,
    collectibles.address,
    17,
    wGOLD.address,
    web3.utils.toWei("2000", "ether"),
    1,
    { from: accounts[2] }
  );

  await escrow.createOrder(
    0,
    collectibles.address,
    15,
    wGOLD.address,
    web3.utils.toWei("1000", "ether"),
    1,
    { from: accounts[0] }
  );

  // create order SELL and execute
  await escrow.createOrder(
    1,
    collectibles.address,
    16,
    wGOLD.address,
    web3.utils.toWei("1500", "ether"),
    1,
    { from: accounts[2] }
  );
  // await escrow.executeOrder(4, { from: accounts[1] });

  // create orderns SELL

  await escrow.createOrder(
    1,
    collectibles.address,
    14,
    wGOLD.address,
    web3.utils.toWei("700", "ether"),
    1,
    { from: accounts[0] }
  );

  await escrow.createOrder(
    1,
    collectibles.address,
    16,
    wGOLD.address,
    web3.utils.toWei("2000", "ether"),
    1,
    { from: accounts[2] }
  );

  await escrow.createOrder(
    1,
    collectibles.address,
    17,
    wGOLD.address,
    web3.utils.toWei("1000", "ether"),
    1,
    { from: accounts[3] }
  );

  console.log("\n Collectibles:");
  console.log("Address:", collectibles.address);

  console.log("\n NFTSwapEscrow:");
  console.log("Address:", escrow.address);
};
