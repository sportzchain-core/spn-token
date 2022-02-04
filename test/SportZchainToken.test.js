const { writeContracts } = require("truffle");
const truffleAssert = require('truffle-assertions');
const SportZchainToken = artifacts.require('SportZchainToken.sol');

contract('SPN Token Test', (accounts) => {

    describe("SportZchain Token Tests", () => {

        var fiveSPN = BigInt(5*Math.pow(10,18));
        let tokenContract;
        before(async () => {
            // Params name, symbol, decimals, supply upper limit, initial supply
            tokenContract = await SportZchainToken.deployed({from: accounts[0]});
        });
        // Test 01: Checking Owner is sender address
        it("01: Owner must be deployer", async () => {
            const ownerAddr = await tokenContract.owner();
            assert.equal(ownerAddr, accounts[0]);
        });
        // Test 02: Owner balance must be equal to initial supply
        it("02: Owner balance must be equal to initial supply", async () => {
            const supply = await tokenContract.totalSupply(); // function totalSupply returns circulating supply
            const ownerBalance = await tokenContract.balanceOf(accounts[0]);
            assert.equal(supply.toString(), ownerBalance.toString());
        });
        // Test 03: Transfer 5 SPN to another account
        it("03: Transfer 5 SPN to another account", async () => {
            await tokenContract.transfer(accounts[1],  fiveSPN); // Transfering 5 SPN to account 1
            const accountBalance = await tokenContract.balanceOf(accounts[1]);
            assert.equal(accountBalance.toString(), fiveSPN.toString());
        });
        // Test 04: Only owner must be allowed to mint more tokens
        it("04: Only owner must be allowed to mint more tokens", async () => {
            // Trying to mint tokens from a non owner account
            await truffleAssert.fails(tokenContract.mint(accounts[1], 10, {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
        });
        // Test 05: Owner cannot mint more than supply upper limit
        it("05: Owner cannot mint more than supply upper limit", async () => {
            // supply upper limit is 100, initial supply is 50 therefore owner cannot mint 51 tokens.
            await truffleAssert.fails(tokenContract.mint(accounts[1], 51, {from: accounts[0]}), truffleAssert.ErrorType.REVERT);
        });
        // Test 06: Sender address can approve an address to spend specific tokens on its behalf.
        it("06: Transaction sender approving account at 0 to spend 5 Tokens on its behalf", async () => {
            // Account 0 allowing account 1 to spend 5 tokens on its behalf.
            await tokenContract.approve(accounts[1], fiveSPN, {from: accounts[0]});
            // Account 1 transfering 5 tokens from account 0 to account 2
            await tokenContract.transferFrom(accounts[0], accounts[2], fiveSPN, {from: accounts[1]});
            const account2Balance = await tokenContract.balanceOf(accounts[2]);
            assert.equal(fiveSPN, account2Balance);
        });
        // Test 07: Cannot spend more than allowance.
        it("07: Cannot spend more than allowance", async () => {
            // Account 0 allowing account 1 to spend 5 tokens on its behalf.
            await tokenContract.approve(accounts[1], fiveSPN, {from: accounts[0]});
            // Account 1 trying to spend more than allowance.
            truffleAssert.fails(tokenContract.transferFrom(accounts[0], accounts[2], fiveSPN + BigInt(1), {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
        });
        // Test 08: Increasing Allowance
        it("08: Increasing Allowance", async () => {
            // Initial allowance 5 tokens
            await tokenContract.approve(accounts[1], fiveSPN, {from: accounts[0]});
            // Increase allowance by 5 tokens, allowance = 10 tokens
            await tokenContract.increaseAllowance(accounts[1], fiveSPN, {from: accounts[0]});
            // Reading allowance between account 0 and account 1
            const newAllowance =  await tokenContract.allowance(accounts[0], accounts[1]);
            assert.equal(newAllowance, fiveSPN+fiveSPN);
        });
        // Test 09: Decrease Allowance
        it("09: Decrease Allowance", async () => {
            // Initial allowance 5 tokens
            await tokenContract.approve(accounts[1], fiveSPN, {from: accounts[0]});
            // Decrease allowance by 5 tokens, allowance = 10 tokens
            await tokenContract.decreaseAllowance(accounts[1], fiveSPN, {from: accounts[0]});
            // Reading allowance between account 0 and account 1
            const newAllowance =  await tokenContract.allowance(accounts[0], accounts[1]);
            assert.equal(newAllowance, 0);
        });
        // Test 10: Non-Owner can not burn tokens
        it("10: Non-owner can not burn tokens", async () => {
            truffleAssert.fails(tokenContract.burn(5, {from:accounts[1]}), truffleAssert.ErrorType.REVERT);
        });
        // Test 12: Owner transferring Ownership
        it("12: Owner must be able to transfer ownership", async () => {
            await tokenContract.transferOwnership(accounts[1], {from: accounts[0]});
            const owner = await tokenContract.owner();
            assert.equal(owner, accounts[1]);
        });
        // Test 13: Non owner transferring ownership
        it("13: Non-Owner must not be able to transfer ownership", async () => {
            truffleAssert.fails(tokenContract.transferOwnership(accounts[1], {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
        });
        // Test 14: Non-owner cannot renounce ownership
        it("14: Non-owner cannot renounce ownership", async() => {
            truffleAssert.fails(tokenContract.renounceOwnership({from:accounts[2]}), truffleAssert.ErrorType.REVERT);
        });
        //Test 10: Owner can renounce ownership
        it("10: Renouncing ownership", async () => {
            await tokenContract.renounceOwnership({from: accounts[1]});
            const owner = await tokenContract.owner();
            assert.equal(owner.toString(), '0x0000000000000000000000000000000000000000');
        });      
    });
});