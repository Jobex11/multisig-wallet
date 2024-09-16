const { expect } = require("chai");

describe("MultiSigWallet", function () {
  let MultiSigWallet;
  let wallet;
  let owner1, owner2, owner3, nonOwner;
  let owners;
  const requiredConfirmations = 2;

  beforeEach(async function () {
    // Get the contract factory and signers
    [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
    owners = [owner1.address, owner2.address, owner3.address];

    // Deploy the MultiSigWallet contract
    MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    wallet = await MultiSigWallet.deploy(owners, requiredConfirmations);
  });

  it("should deploy correctly and set owners", async function () {
    expect(await wallet.owners(0)).to.equal(owner1.address);
    expect(await wallet.owners(1)).to.equal(owner2.address);
    expect(await wallet.owners(2)).to.equal(owner3.address);
    expect(await wallet.required()).to.equal(requiredConfirmations);
  });

  it("should accept deposits", async function () {
    const amount = ethers.parseEther("1");
    await owner1.sendTransaction({
      to: wallet.address,
      value: amount,
    });

    // Check the contract balance
    expect(await ethers.provider.getBalance(wallet.address)).to.equal(amount);
  });

  it("should allow owners to submit a transaction", async function () {
    const amount = ethers.parseEther("0.5");
    await wallet.submitTransaction(owner3.address, amount, "0x");

    const transaction = await wallet.getTransaction(0);
    expect(transaction.to).to.equal(owner3.address);
    expect(transaction.value).to.equal(amount);
    expect(transaction.executed).to.equal(false);
    expect(transaction.numConfirmations).to.equal(0);
  });

  it("should allow owners to confirm a transaction", async function () {
    await wallet.submitTransaction(owner3.address, 0, "0x");
    await wallet.confirmTransaction(0);

    const transaction = await wallet.getTransaction(0);
    expect(transaction.numConfirmations).to.equal(1);
  });

  it("should allow execution of a confirmed transaction", async function () {
    const amount = ethers.parseEther("0.5");

    // Deposit to the wallet
    await owner1.sendTransaction({
      to: wallet.address,
      value: amount,
    });

    // Submit and confirm the transaction
    await wallet.submitTransaction(owner3.address, amount, "0x");
    await wallet.connect(owner1).confirmTransaction(0);
    await wallet.connect(owner2).confirmTransaction(0);

    // Execute the transaction
    const initialBalance = await ethers.provider.getBalance(owner3.address);
    await wallet.executeTransaction(0);
    const finalBalance = await ethers.provider.getBalance(owner3.address);

    // Check if the transaction was executed successfully
    expect(finalBalance.sub(initialBalance)).to.equal(amount);

    const transaction = await wallet.getTransaction(0);
    expect(transaction.executed).to.equal(true);
  });

  it("should not allow non-owners to confirm or submit a transaction", async function () {
    await expect(
      wallet.connect(nonOwner).submitTransaction(owner3.address, 0, "0x")
    ).to.be.revertedWith("not owner");

    await wallet.submitTransaction(owner3.address, 0, "0x");
    await expect(
      wallet.connect(nonOwner).confirmTransaction(0)
    ).to.be.revertedWith("not owner");
  });
});

/*
const { expect } = require("chai");

describe("MultiSigWallet", function () {
  let MultiSigWallet;
  let wallet;
  let owner1, owner2, owner3, nonOwner;
  let owners;
  const requiredConfirmations = 2;

  beforeEach(async function () {
    [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
    owners = [owner1.address, owner2.address, owner3.address];

    MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    wallet = await MultiSigWallet.deploy(owners, requiredConfirmations);
    await wallet.deployed();
  });

  it("should deploy correctly and set owners", async function () {
    expect(await wallet.owners(0)).to.equal(owner1.address);
    expect(await wallet.owners(1)).to.equal(owner2.address);
    expect(await wallet.owners(2)).to.equal(owner3.address);
    expect(await wallet.required()).to.equal(requiredConfirmations);
  });

  it("should accept deposits", async function () {
    const amount = ethers.utils.parseEther("1");
    await owner1.sendTransaction({
      to: wallet.address,
      value: amount,
    });

    expect(await ethers.provider.getBalance(wallet.address)).to.equal(amount);
  });

  it("should allow owners to submit a transaction", async function () {
    const amount = ethers.utils.parseEther("0.5");
    await wallet.submitTransaction(owner3.address, amount, "0x");

    const transaction = await wallet.getTransaction(0);
    expect(transaction.to).to.equal(owner3.address);
    expect(transaction.value).to.equal(amount);
    expect(transaction.executed).to.equal(false);
    expect(transaction.numConfirmations).to.equal(0);
  });

  it("should allow owners to confirm a transaction", async function () {
    await wallet.submitTransaction(owner3.address, 0, "0x");
    await wallet.confirmTransaction(0);

    const transaction = await wallet.getTransaction(0);
    expect(transaction.numConfirmations).to.equal(1);
  });

  it("should allow execution of a confirmed transaction", async function () {
    const amount = ethers.utils.parseEther("0.5");

    await owner1.sendTransaction({
      to: wallet.address,
      value: amount,
    });

    await wallet.submitTransaction(owner3.address, amount, "0x");
    await wallet.connect(owner1).confirmTransaction(0);
    await wallet.connect(owner2).confirmTransaction(0);

    const initialBalance = await ethers.provider.getBalance(owner3.address);
    await wallet.executeTransaction(0);
    const finalBalance = await ethers.provider.getBalance(owner3.address);

    expect(finalBalance.sub(initialBalance)).to.equal(amount);

    const transaction = await wallet.getTransaction(0);
    expect(transaction.executed).to.equal(true);
  });

  it("should not allow non-owners to confirm or submit a transaction", async function () {
    await expect(
      wallet.connect(nonOwner).submitTransaction(owner3.address, 0, "0x")
    ).to.be.revertedWith("not owner");

    await wallet.submitTransaction(owner3.address, 0, "0x");
    await expect(
      wallet.connect(nonOwner).confirmTransaction(0)
    ).to.be.revertedWith("not owner");
  });
});

*/
