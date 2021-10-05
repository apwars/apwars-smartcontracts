const APWarsReward = artifacts.require('APWarsReward');

contract('APWarsReward.test', accounts => {
  let reward = null;

  it('should find nonce', async () => {
    reward = await APWarsReward.new();

    let i = 0;
    let result = false;
    let check = false;
    while (!check) {
      const r = await reward.check(i);
      result = r.result;
      check = r.check;
      console.log(result.toString(), check, i);
      i++
    }
  });
});