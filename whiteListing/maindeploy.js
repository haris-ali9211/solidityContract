const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  const [deployer, per1, per2] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const addresses = [
    "0xc35E93975d68F5f2bb284c0dF1B941754D73B337",
    "0xbb45AF76f5198db4e38bA3668993c82739343c40",
    "0x8a7cFda813a2871028BE4aE919777548b26E843D",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  ];
  const leaves = addresses.map((x) => keccak256(x));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  const buf2hex = (x) => "0x" + x.toString("hex");
  const Root = buf2hex(tree.getRoot());

  console.log("Root : ", Root);

  console.log("start");
  whiteList = await ethers.getContractFactory("Whitelist");
  console.log("1");
  list = await whiteList.deploy(Root);
  console.log("2");
  await list.deployed();
  console.log("WhitList", list.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
