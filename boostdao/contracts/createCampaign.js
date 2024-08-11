const { ethers } = require("hardhat");
const MyContractABI = require('../frontend/store/abi');


async function main() {
  const contractAddress = "0xbC55d80915c8b22c48311Ded0944C67ee00c9849";

  const contractABI = [
    MyContractABI
  ];


  const [signer] = await ethers.getSigners();

  const contract = new ethers.Contract(contractAddress, contractABI, signer);


  const tx = await contract.createCampaign("Test Description", ethers.utils.parseEther("0.004"), Math.floor(Date.now() / 1000) + 86400, "0x4104e9C71F7020b9A2E765C861268F8381b1FDD6");

  console.log("Transaction hash:", tx.hash);


  await tx.wait();

  console.log("Transaction confirmed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
