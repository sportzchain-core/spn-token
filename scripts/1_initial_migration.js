// scripts/deploy_sportzchain.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  console.log('Deploying Migrations...');
  const migration = await ethers.getContractFactory("Migration");
  migrate = await migration.deploy();
  console.log('Migrations deployed to:', migrate.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
