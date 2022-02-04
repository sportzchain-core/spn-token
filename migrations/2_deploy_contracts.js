const SportZchainToken = artifacts.require('SportZchainToken.sol');


module.exports = function (deployer) {


  // Params name, symbol, decimals, supply upper limit, initial supply
  deployer.deploy(SportZchainToken,"SportZToken", "SPN", 18, 100, 50);


};
