const { ethers } = require('hardhat');

async function main() {
    const GovernanceToken = await ethers.getContractFactory("GovernanceToken");
    const governanceToken = await GovernanceToken.deploy();

    await governanceToken.deployed();

    console.log("GovernanceToken deployed to:", governanceToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
