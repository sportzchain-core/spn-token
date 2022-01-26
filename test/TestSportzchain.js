var web3 = require("web3");
const BigNumber = web3.BigNumber;
const { expect } = require("chai").use(require('chai-bignumber')(BigNumber));

describe("SportZChainToken", function() {
  const _name = 'SportZChain Token';
  const _symbol = 'SPN';
  const _decimals = 18;
  const _supplyUpperLimit = 10 * (10 ** 9);
  const _initialSupply = 3 * (10 ** 9)
  let SportZchainToken;
  let token;

  let owner;

  beforeEach(async function () {
      SportZchainToken = await ethers.getContractFactory("SportZchainToken");
      token = await SportZchainToken.deploy(_name,_symbol,_decimals, _supplyUpperLimit,_initialSupply);
      [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    });

  describe("Deployment", function() {
      it("set correct name, symbol, decimals", async function() {
        expect(await token.decimals()).to.equal(_decimals);
        expect(await token.name()).to.equal(_name);
        expect(await token.symbol()).to.equal(_symbol);
      });

      it("Should set the right owner", async function () {
           expect(await token.owner()).to.equal(owner.address);
      });

      it("Should assign the total supply of tokens to the owner", async function () {
        const ownerBalance = await token.balanceOf(owner.address);
        expect(await token.totalSupply()).to.equal(ownerBalance);
      });
  });

  describe("Transactions", function () {
      it("Should transfer tokens between accounts", async function () {
        // Transfer 50 tokens from owner to addr1
        await token.transfer(addr1.address, 50);
        const addr1Balance = await token.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(50);
  
        // Transfer 50 tokens from addr1 to addr2
        // We use .connect(signer) to send a transaction from another account
        await token.connect(addr1).transfer(addr2.address, 50);
        const addr2Balance = await token.balanceOf(addr2.address);
        expect(addr2Balance).to.equal(50);
      });

      it("Should fail if sender doesn’t have enough tokens", async function () {
        const initialOwnerBalance = await token.balanceOf(owner.address);

        // Try to send 1 token from addr1 (0 tokens) to owner (1000000 tokens).
        // `require` will evaluate false and revert the transaction.
        await expect(
          token.connect(addr1).transfer(owner.address, 1)
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

        // Owner balance shouldn't have changed.
        expect(await token.balanceOf(owner.address)).to.equal(
          initialOwnerBalance
        );
      });

      it("Should update balances after transfers", async function () {
        const initialOwnerBalance = await token.balanceOf(owner.address);

        // Transfer 100 tokens from owner to addr1.
        await token.transfer(addr1.address, 100);

        // Transfer another 50 tokens from owner to addr2.
        await token.transfer(addr2.address, 50);

        // Check balances.
        const finalOwnerBalance = await token.balanceOf(owner.address);
        //console.log(finalOwnerBalance);
        //expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150);

        const addr1Balance = await token.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(100);

        const addr2Balance = await token.balanceOf(addr2.address);
        expect(addr2Balance).to.equal(50);
      });
    });

     describe("mint", function () {
          it("Should be able to mint more", async function () {
            let additionalSupply = (1 * (10 ** 9));
            let initialSupply = await token.balanceOf(owner.address);
            await token.mint(owner.address, additionalSupply);
            const newBalance = await token.balanceOf(owner.address);
            expect(newBalance.toString()).to.equal('4000000000000000000000000000');
          });
          it("Max mint", async function () {
              let additionalSupply = (7 * (10 ** 9));
              let initialSupply = await token.balanceOf(owner.address);
              await token.mint(owner.address, additionalSupply);
              const newBalance = await token.balanceOf(owner.address);
              expect(newBalance.toString()).to.equal('10000000000000000000000000000');
         });

         it("Cant mint more than total supply", async function () {
          let additionalSupply = (8 * (10 ** 9));
          await expect(token.mint(owner.address, additionalSupply))
          .to.be.revertedWith("Cant mint more than supply limit");
         });
     });
});
