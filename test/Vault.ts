import { ethers } from "hardhat";
import { expect } from "chai";

import { Vault } from "../typechain";

describe("Vault", function () {
  let vault: Vault;

  beforeEach(async () => {
    const VaultFactory = await ethers.getContractFactory("Vault");

    vault = (await VaultFactory.deploy("0x0...", "0x0...")) as Vault;

    await vault.deployed();
  });

  // it("should return the new greeting once it's changed", async function () {
  //   expect(await greeter.greet()).to.equal("Hello, world!");

  //   const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

  //   // wait until the transaction is mined
  //   await setGreetingTx.wait();

  //   expect(await greeter.greet()).to.equal("Hola, mundo!");
  // });
});
