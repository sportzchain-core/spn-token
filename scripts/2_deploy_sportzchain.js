// scripts/deploy_sportzchain.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const _name = 'SportZchain Token';
  const _symbol = 'SPN';
  const _decimals = 18;
  const _supplyUpperLimit = 10 * (10 ** 9);
  const _initialSupply = 3 * (10 ** 9)

  console.log('Deploying SportZchainToken...');
  const SportZchainToken = await ethers.getContractFactory("SportZchainToken");
  token = await SportZchainToken.deploy(_name,_symbol,_decimals, _supplyUpperLimit,_initialSupply);
  console.log('SportZchainToken deployed to:', token.address);
  //0xDB83275D7a6d4356D2c72F2747e34dc51d2879D3
  //0xAE3d0fd34fc8492dC4c7a5a86736d56E1a220128
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
