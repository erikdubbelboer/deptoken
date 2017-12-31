
const Frontend = artifacts.require("./Frontend.sol")
const Backend = artifacts.require("./Backend.sol")
const ERC20Interface = artifacts.require("./ERC20Interface.sol")

module.exports = function(deployer, network, accounts) {
	deployer.deploy([Backend, ERC20Interface]).then(function() {
		Backend.deployed().then(function(backend) {
			ERC20Interface.deployed().then(function(erc20) {
				deployer.deploy(Frontend, backend.address, erc20.address).then(function() {
					Frontend.deployed().then(function(frontend) {
						/*frontend.getBackend().then(function(a) {
							console.log(a);
							console.log(backend.address);
						});*/
						backend.setFrontend(Frontend.address, true);
						erc20.setFrontend(frontend.address);
					});
				});
			});
		});
	});
};

