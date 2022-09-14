require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("./tasks/flatter");

/**
 * @type import('hardhat/config').HardhatUserConfig
 * */

module.exports = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    elastosmainnet: {
      url: "https://api.elastos.io/esc",
      accounts: [],
    },
    elastostestnet: {
      url: "https://api-testnet.elastos.io/eth",
      accounts: [],
    },
  },
  parameters: {
    deployment: {
      PlatformAddress: '', // Platform Fee Address of the Node Registry Contract 
      WithProxy: true, // Set true for new proxy contract deployment, set false for updates  
      ContractAddress: '', // Deployed proxy contract address of the Node Registry Contract
    },
    script: {
      testAddress1: '',
      testAddress2: '',
      testAddress3: '',
    },
  }
};
