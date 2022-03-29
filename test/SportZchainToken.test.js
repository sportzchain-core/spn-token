const { expect } = require("chai");

describe("SportZchainToken contract test", async function () {
  let SportZchainTokenFactory;
  let SportZchainToken;
  let owner;
  let addr1;
  let addr2;

  const NAME = 'SportZChain Token';
  const SYMBOLE = 'SPN';
  const DECIMALS = 18;
  const TOTAL_SUPPLY = 100 * (10 ** DECIMALS);
  const FIFTY_TOKENS = 50 * (10 ** DECIMALS);
  const FIFTY_TOKENS_STRING = FIFTY_TOKENS.toString();
  const HUNDRED_TOKENS_STRING = (FIFTY_TOKENS * 2).toString();
  const ZERO_ADDRESS = ethers.constants.AddressZero;

  const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const BURNER_ROLE = '0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848';
  const PAUSER_ROLE = '0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a';

  before(async function () {
    SportZchainTokenFactory = await ethers.getContractFactory("SportZchainToken");

    [owner, addr1, addr2] = await ethers.getSigners();

    SportZchainToken = await SportZchainTokenFactory.deploy(NAME, SYMBOLE, DECIMALS, TOTAL_SUPPLY.toString());
  });

  describe("Deployment", function() {
    it("Should set correct name, symbol, decimals", async function() {
      expect(await SportZchainToken.name()).to.equal(NAME);
      expect(await SportZchainToken.symbol()).to.equal(SYMBOLE);
      expect(await SportZchainToken.decimals()).to.equal(DECIMALS);
    });

    it("Should set the right owner", async function () {
      expect(await SportZchainToken.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await SportZchainToken.balanceOf(owner.address);
      expect(await SportZchainToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("User's Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await expect(SportZchainToken.transfer(addr1.address, FIFTY_TOKENS_STRING))
      .to.emit(SportZchainToken, "Transfer")
      .withArgs(owner.address, addr1.address, FIFTY_TOKENS_STRING);

      expect(await SportZchainToken.balanceOf(addr1.address)).to.equal(FIFTY_TOKENS_STRING);
    });

    it("Should fail transfer if sender doesn’t have enough tokens", async function () {
      await expect(SportZchainToken.connect(addr1).transfer(addr2.address, HUNDRED_TOKENS_STRING))
      .to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Should fail transfer if contract is in paused state", async function () {
      await expect(SportZchainToken.grantRole(PAUSER_ROLE , owner.address));
      await expect(SportZchainToken.pause());

      await expect(SportZchainToken.transfer(addr2.address, FIFTY_TOKENS_STRING))
      .to.be.revertedWith("ERC20Pausable: token transfer while paused");

      await expect(SportZchainToken.unpause());
    });

    it("Should fail burn if user has not BURNER_ROLE", async function () {
      await expect(SportZchainToken.connect(addr1).burn(FIFTY_TOKENS_STRING))
      .to.be.revertedWith("Caller is not a burner");
    });

    it("Should fail pause if user has not PAUSER_ROLE", async function () {
      await expect(SportZchainToken.connect(addr1).pause())
      .to.be.revertedWith("Caller is not a pauser");
    });

    it("Should approve tokens spend to other account", async function () {
      await expect(SportZchainToken.approve(addr1.address, FIFTY_TOKENS_STRING));

      expect(await SportZchainToken.allowance(owner.address, addr1.address)).to.equal(FIFTY_TOKENS_STRING);
    });

    it("Should increase tokens spend allowance", async function () {
      await expect(SportZchainToken.approve(addr1.address, FIFTY_TOKENS_STRING));
      await expect(SportZchainToken.increaseAllowance(addr1.address, FIFTY_TOKENS_STRING));

      expect(await SportZchainToken.allowance(owner.address, addr1.address)).to.equal(HUNDRED_TOKENS_STRING);
    });
    it("Should decrease tokens spend allowance", async function () {
      await expect(SportZchainToken.approve(addr1.address, FIFTY_TOKENS_STRING));
      await expect(SportZchainToken.decreaseAllowance(addr1.address, FIFTY_TOKENS_STRING));

      expect(await SportZchainToken.allowance(owner.address, addr1.address)).to.equal(0);
    });
    it("Should transfer tokens allowed tokens on behalf of owner", async function () {
      await expect(SportZchainToken.approve(addr1.address, FIFTY_TOKENS_STRING));
      await expect(SportZchainToken.connect(addr1).transferFrom(owner.address, addr2.address, FIFTY_TOKENS_STRING))
      .to.emit(SportZchainToken, "Transfer")
      .withArgs(owner.address, addr2.address, FIFTY_TOKENS_STRING);

      expect(await SportZchainToken.balanceOf(addr2.address)).to.equal(FIFTY_TOKENS_STRING);
    });
  });

  describe("Owner's Transactions", function () {
    it("Should grant roles to user", async function () {
      expect(await SportZchainToken.grantRole(BURNER_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleGranted")
      .withArgs(BURNER_ROLE, owner.address, owner.address);

      expect(await SportZchainToken.grantRole(PAUSER_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleGranted")
      .withArgs(PAUSER_ROLE, owner.address, owner.address);
    });

    it("Should be able to pause & unpause token transfer", async function () {
      await expect(SportZchainToken.pause());
      await expect(SportZchainToken.unpause());
    });

    it("Should be able to burn tokens", async function () {
      await expect(SportZchainToken.burn(FIFTY_TOKENS_STRING))
      .to.emit(SportZchainToken, "Transfer")
      .withArgs(owner.address, ZERO_ADDRESS, FIFTY_TOKENS_STRING);
    });

    it("Should check role for user", async function () {
      expect(await SportZchainToken.hasRole(BURNER_ROLE, addr1.address)).to.equal(false);
    });

    it("Should revoke role from user", async function () {
      await expect(SportZchainToken.revokeRole(BURNER_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleRevoked")
      .withArgs(BURNER_ROLE, owner.address, owner.address);

      await expect(SportZchainToken.revokeRole(PAUSER_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleRevoked")
      .withArgs(PAUSER_ROLE, owner.address, owner.address);
    });

    it("Should transfer ownership", async function () {
      await expect(SportZchainToken.grantRole(DEFAULT_ADMIN_ROLE , addr1.address))
      .to.emit(SportZchainToken, "RoleGranted")
      .withArgs(DEFAULT_ADMIN_ROLE, addr1.address, owner.address);

      await expect(SportZchainToken.transferOwnership(addr1.address))
      .to.emit(SportZchainToken, "OwnershipTransferred")
      .withArgs(owner.address, addr1.address);

      expect(await SportZchainToken.connect(addr1).revokeRole(DEFAULT_ADMIN_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleRevoked")
      .withArgs(DEFAULT_ADMIN_ROLE, owner.address, addr1.address);

      expect(await SportZchainToken.connect(addr1).revokeRole(DEFAULT_ADMIN_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleRevoked")
      .withArgs(BURNER_ROLE, owner.address, addr1.address);

      expect(await SportZchainToken.connect(addr1).revokeRole(DEFAULT_ADMIN_ROLE , owner.address))
      .to.emit(SportZchainToken, "RoleRevoked")
      .withArgs(PAUSER_ROLE, owner.address, addr1.address);

      expect(await SportZchainToken.owner()).to.equal(addr1.address);
      expect(await SportZchainToken.hasRole(DEFAULT_ADMIN_ROLE, addr1.address)).to.equal(true);
      expect(await SportZchainToken.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(false);
    });
  });
});