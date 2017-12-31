
const Frontend = artifacts.require('Frontend');
const Backend = artifacts.require('Backend');
const ERC20Interface = artifacts.require('ERC20Interface');

contract('Frontend', function (accounts) {
  let frontend, backend, erc20;
  beforeEach(async function() {
		backend = await Backend.new({ from: accounts[0] });
		erc20 = await ERC20Interface.new({ from: accounts[0] });
    frontend = await Frontend.new(backend.address, erc20.address, { from: accounts[0] });
  });
  describe('owner', function() {
    it('getOwner is correct', async function() {
      assert.equal(await frontend.getOwner(), accounts[0]);
    });
		it('setOwner is allowed', async function() {
			await frontend.setOwner(accounts[1]);
			assert.equal(await frontend.getOwner(), accounts[1]);
		});
  });

	it('getBackend should be correct', async function() {
		assert.equal(await frontend.getBackend(), backend.address);
	});
});

