async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  // Deploying MultiSigWallet contract
  const owners = ["0xOwner1Address", "0xOwner2Address"]; // Replace with actual addresses
  const required = 2; // Number of required confirmations
  const transactionExpiryBlocks = 200; // Transaction expiry period

  const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
  const wallet = await MultiSigWallet.deploy(
    owners,
    required,
    transactionExpiryBlocks
  );

  await wallet.deployed();

  console.log("MultiSigWallet deployed to:", wallet.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
