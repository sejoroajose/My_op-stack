const hre =  require('hardhat');

async function main () {
    const DAO =  await hre.ethers.getContractFactory('DAO');
    const dao = await DAO.deploy(
        process.env.GOVERNANCE_TOKEN_ADDRESS,
        process.env.WORLD_ID_ADDRESS
    );

    await dao.deployed();

    console.log("BoostDAO deployed to:", dao.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });