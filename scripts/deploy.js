const hre = require("hardhat");
const { ethers } = hre;
const config = require("../hardhat.config");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying contracts...",
    deployer.address,
    (await deployer.getBalance()).toString()
  );

  // ***************************  Node Registry  *************************** //
  if (config.parameters.deployment.LastTokenId < 0) {
    console.log("Last tokenId is incorrect.");
    return ;
  }
  if (!config.parameters.deployment.PlatformAddress) {
    console.log("Platform address is not set.");
    return ;
  }
  if (!config.parameters.deployment.PlatformFee) {
    console.log("Platform fee is not set.");
    return ;
  }
  // deploy proxy contract
  const NodeRegistry = await ethers.getContractFactory("NodeRegistry");
  const nodeRegisty = await NodeRegistry.deploy(
    config.parameters.deployment.LastTokenId, 
    config.parameters.deployment.PlatformAddress, 
    config.parameters.deployment.PlatformFee
  );

  console.log("Node Registry contract deployed to:", nodeRegisty.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
