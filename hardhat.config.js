const { BigNumber } = require("ethers");

require("@nomiclabs/hardhat-waffle");
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
      LastTokenId: 0, // Last TokenId of Node Registry Contract
      PlatformAddress: '', // Platform Address of the Node Registry Contract 
      PlatformFee: BigNumber.from('0'), // Platform Fee of the Node Registry Contract 
    },
    script: {
      ContractAddress: '', // Deployed proxy contract address of the Node Registry Contract
      PlatformAddress: '', 
      PlatformFee: BigNumber.from('0'),
      testAddress1: '',
      testAddress2: '',
      testAddress3: '',
    },
  }
};
