const { ethers } = require("hardhat");
const config = require("../hardhat.config");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Initializing contracts...", deployer.address, (await deployer.getBalance()).toString());

  if (!config.parameters.script.ContractAddress) {
    console.log('Contract Address is not set.')
    return ;
  }
  if (!config.parameters.script.NodeEntry) {
    console.log('Node Entry is not set.')
    return ;
  }

  const NodeRegistry = await ethers.getContractFactory("NodeRegistry");
  const nodeRegistry = NodeRegistry.attach(config.parameters.script.ContractAddress);

  const tokenId = await nodeRegistry.getTokenId(config.parameters.script.NodeEntry);
  
  console.log(`Displaying tokenId of ${config.parameters.script.NodeEntry}  =====>>`);
  console.log(`Token Id: ${tokenId}`);
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
