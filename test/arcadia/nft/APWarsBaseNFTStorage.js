const APWarsBaseNFTStorage = artifacts.require('APWarsBaseNFTStorage');

contract('APWarsBaseNFTStorage.test', accounts => {
  let smc = null;

  it('store values', async () => {
    smc = await APWarsBaseNFTStorage.new();

    await smc.setUInt256(accounts[1], 1, '0x1', 1, 5);
    const i = await smc.getScheduledUInt256(accounts[1], 1, '0x1');
    const iValue = await smc.getUInt256(accounts[1], 1, '0x1');

    expect(i.oldValue.toString()).to.be.equal('0');
    expect(i.newValue.toString()).to.be.equal('1');
    expect(iValue.toString()).to.be.equal(i.oldValue.toString());

    for (index = 0; index < 5; index++) {
      await smc.grantRole('0x0', accounts[1]);
    }

    const iNew = await smc.getScheduledUInt256(accounts[1], 1, '0x1');
    const iValueNew = await smc.getUInt256(accounts[1], 1, '0x1');

    expect(iNew.oldValue.toString()).to.be.equal('0');
    expect(i.newValue.toString()).to.be.equal('1');
    expect(iValueNew.toString()).to.be.equal(i.newValue.toString());

    //----

    await smc.setString(accounts[1], 1, '0x2', "TEST", 5);
    const s = await smc.getScheduledString(accounts[1], 1, '0x2');
    const sValue = await smc.getString(accounts[1], 1, '0x2');

    expect(s.oldValue.toString()).to.be.equal('');
    expect(s.newValue.toString()).to.be.equal('TEST');
    expect(sValue.toString()).to.be.equal(s.oldValue.toString());

    for (index = 0; index < 5; index++) {
      await smc.grantRole('0x0', accounts[1]);
    }

    const sNew = await smc.getScheduledString(accounts[1], 1, '0x2');
    const sValueNew = await smc.getString(accounts[1], 1, '0x2');

    expect(sNew.oldValue.toString()).to.be.equal('');
    expect(sNew.newValue.toString()).to.be.equal('TEST');
    expect(sValueNew.toString()).to.be.equal(sNew.newValue.toString());

    //----

    await smc.setBytes32(accounts[1], 1, '0x3', '0x2000000000000000000000000000000000000000000000000000000000000001', 5);
    const b = await smc.getScheduledBytes32(accounts[1], 1, '0x3');
    const bValue = await smc.getBytes32(accounts[1], 1, '0x3');

    expect(b.oldValue.toString()).to.be.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    expect(b.newValue.toString()).to.be.equal('0x2000000000000000000000000000000000000000000000000000000000000001');
    expect(bValue.toString()).to.be.equal(b.oldValue.toString());

    for (index = 0; index < 5; index++) {
      await smc.grantRole('0x0', accounts[1]);
    }

    const bNew = await smc.getScheduledBytes32(accounts[1], 1, '0x3');
    const bValueNew = await smc.getBytes32(accounts[1], 1, '0x3');

    expect(bNew.oldValue.toString()).to.be.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    expect(bNew.newValue.toString()).to.be.equal('0x2000000000000000000000000000000000000000000000000000000000000001');
    expect(bValueNew.toString()).to.be.equal(bNew.newValue.toString());
  });
});