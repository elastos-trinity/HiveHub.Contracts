const { ethers } = require("hardhat");
const config = require("../hardhat.config");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Initializing contracts...", deployer.address, (await deployer.getBalance()).toString());

  if (!config.parameters.script.ContractAddress) {
    console.log("Contract address is not set.");
    return;
  }
  if (!config.parameters.script.PlatformAddress) {
    console.log("Platform address is not set.");
    return;
  }
  if (config.parameters.script.PlatformFee < 0) {
    console.log("Platform Fee is incorrect.");
    return;
  }

  const NodeRegistry = await ethers.getContractFactory("NodeRegistry");
  const nodeRegistry = NodeRegistry.attach(config.parameters.script.ContractAddress);
  try {
    await nodeRegistry.setPlatformFee(
      config.parameters.script.PlatformAddress,
      config.parameters.script.PlatformFee
    );
    console.log("Set Platform Fee Success");
    console.log("");
  } catch (err) {
    console.error(err);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
