require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

//const { alchemyApiKey, mnemonic_bsc } = require('./secrets.json');

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
      version: "0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    paths: {
      sources: "./contracts",
      tests: "./test",
      cache: "./cache",
      artifacts: "./artifacts"
    },
    mocha: {
      timeout: 20000
    },
	networks: {
	   Ropsten: {
		  url: process.env.ROPSTEN_URL || "",
          accounts:
            process.env.OWNER_PRIVATE_KEY !== undefined ? [process.env.OWNER_PRIVATE_KEY] : [],
		},
	    Rinkeby: {
	       url: process.env.RINKEBY_URL || "",
	       accounts:
	         process.env.OWNER_PRIVATE_KEY !== undefined ? [process.env.OWNER_PRIVATE_KEY] : [],
	    },
	    bsc_testnet: {
          url: process.env.BSC_TESTNET_URL || "",
          chainId: 97,
          gasPrice: 20000000000,
          accounts:
             process.env.OWNER_PRIVATE_KEY_BSC !== undefined ? [process.env.OWNER_PRIVATE_KEY_BSC] : [],
        },
        bsc_mainnet: {
          url: process.env.BSC_MAINNET_URL || "",
          chainId: 56,
          gasPrice: 20000000000,
          accounts:
             process.env.OWNER_PRIVATE_KEY_BSC !== undefined ? [process.env.OWNER_PRIVATE_KEY_BSC] : [],
        }
	},
	gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
      },
      etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
      },

};

