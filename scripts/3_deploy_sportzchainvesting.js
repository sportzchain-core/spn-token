// scripts/deploy_sportzchain.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const _name = 'SportZchain Token';
  const _symbol = 'SPN';
  const _decimals = 18;
  const _supplyUpperLimit = 10 * (10 ** 9);
  const _initialSupply = 10 * (10 ** 9)

  console.log('Deploying SportZchainToken Token...');
  const SampleToken = await ethers.getContractFactory("SportZchainToken");
  token = await SampleToken.deploy(_name,_symbol,_decimals,_supplyUpperLimit,  _initialSupply);
  console.log('SportZchainToken Token deployed to:', token.address);

  console.log('Deploying Vesting Contract...');
  const SportZchainTokenVesting = await ethers.getContractFactory("SportZchainTokenVesting");
  vesting = await SportZchainTokenVesting.deploy(token.address);
  console.log('Vesting Contract deployed to:', vesting.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
