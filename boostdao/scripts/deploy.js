const { ethers, hardhat } = require("hardhat");

async function main() {
  const DAO = await ethers.getContractFactory('DAO');
  const dao = await DAO.deploy(
    process.env.GOVERNANCE_TOKEN_ADDRESS
  );

  await dao.deployed();
  console.log("BoostDAO deployed to:", dao.address);

  // Store the contract ABI and address for future use
  const fs = require('fs');
  const contractsDir = __dirname + '/../frontend/store';

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + '/DAO-address.json',
    JSON.stringify({ DAO: dao.address }, undefined, 2)
  );

  const DAOArtifact = artifacts.readArtifactSync('DAO');

  fs.writeFileSync(
    contractsDir + '/DAO.json',
    JSON.stringify(DAOArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
