require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();
const { MNEMONIC } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "testnet",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {
    },
    testnet: {
      // url: "https://data-seed-prebsc-1-s1.binance.org:8545",// for bsc test net
      url: "https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", //for rinkeby
      // chainId: 97, //for bsc test net
      chainId: 4, //for rinkeby
      // gasPrice: 20000000000,
      accounts: {mnemonic: MNEMONIC}
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/", //for bsc main net
      chainId: 56, //for bsc main net
      // gasPrice: 20000000000,
      accounts: {mnemonic: MNEMONIC}
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    // apiKey: "VF1PZED1J5D6GC8AZR49J2FF4QRPX58F23"//for bsc
    apiKey: "A81SHP67CU2TXQVVS7NHB3Z8T921XYYVW5"//for rinkeby
  },
  solidity: {
  version: "0.8.12",
  settings: {
    optimizer: {
      enabled: true
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
  }
};