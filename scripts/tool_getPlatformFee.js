const { ethers } = require("hardhat");
const config = require("../hardhat.config");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Initializing contracts...", deployer.address, (await deployer.getBalance()).toString());

  if (!config.parameters.script.ContractAddress) {
    console.log("Contract address is not set.");
    return;
  }

  const NodeRegistry = await ethers.getContractFactory("NodeRegistry");
  const nodeRegistry = NodeRegistry.attach(config.parameters.script.ContractAddress);
  const platformFeeInfo = await nodeRegistry.getPlatformFee();
  console.log("Displaying platform fee config  =====>>");
  console.log("Platform Address: ", platformFeeInfo.platformAddress);
  console.log("Platform Fee: ", platformFeeInfo.platformFee);
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
