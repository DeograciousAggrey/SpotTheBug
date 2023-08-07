const { ethers } = require("hardhat");

async function main() {
  // We get the contract to deploy
  const SimpleLottery = await ethers.getContractFactory("SimpleLottery");
  const simpleLottery = await SimpleLottery.deploy();

  await simpleLottery.deployed();

  console.log("SimpleLottery deployed to:", simpleLottery.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
