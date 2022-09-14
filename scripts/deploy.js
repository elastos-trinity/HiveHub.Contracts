const hre = require("hardhat");
const { ethers, upgrades } = hre;
const config = require("../hardhat.config");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying contracts...",
    deployer.address,
    (await deployer.getBalance()).toString()
  );

  // ***************************  Node Registry  *************************** //
  if (!config.parameters.deployment.PlatformAddress) {
    console.log("Platform address is not set.");
    return ;
  }
  // deploy proxy contract
  const NodeRegistry = await ethers.getContractFactory("NodeRegistry");
  let proxiedNodeRegisty;
  if (config.parameters.deployment.WithProxy) {
    proxiedNodeRegisty = await upgrades.deployProxy(NodeRegistry, [config.parameters.deployment.PlatformAddress]);
    await proxiedNodeRegisty.deployed();
  }
  else {
    proxiedNodeRegisty = await upgrades.upgradeProxy(config.parameters.deployment.ContractAddress, NodeRegistry)
  }

  // verify implementation contract
  const nodeRegistryAddress = await upgrades.erc1967.getImplementationAddress(proxiedNodeRegisty.address);

  console.log("Node Registry proxy contract deployed to:", proxiedNodeRegisty.address);
  console.log("Node Registry logic contract deployed to:", nodeRegistryAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
