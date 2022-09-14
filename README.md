# ELASTOS HIVE NODE REGISTRY CONTRACT

### Introduction
Elastos Hive Node Registry Contract



### HowTo

- Set enviroment
Clone the repository onto your local device, and install all depedencies

```shell
$ git clone https://github.com/elastos-trinity/NodeRegistry.git
$ npm install
```

then, configurate hardhat.config.js, put your private key in the network config item

```javascript
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
```

**Notice**: *put your private key string in the item "accounts"*.

- Testing
Run the following command in the terminal to start testing on testnet enviroment.

```shell
$ npx hardhat test
```


- Deploy contracts
Deploy contracts by running such command in terminal

```shell
$ npx hardhat run scripts/deploy.js --network elastostestnet
```