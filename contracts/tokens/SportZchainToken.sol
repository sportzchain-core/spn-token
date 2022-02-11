//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @dev An ERC20 implementation of the SportZchain ecosystem token. All tokens are initially pre-assigned to
 * the creator, and can later be distributed freely using transfer transferFrom and other ERC20 functions.
 */
contract SportZchainToken is Ownable, ERC20Votes, ERC20Pausable, ERC20Burnable {

    // SportZchain token upper limit
    uint256 supplyUpperLimit;

    // decimal value of the token
    uint8 decimalValue;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     *
     * @param _name = token name
     * @param _symbol = token symbol
     * @param _decimals = token decimals
     * @param _supplyUpperLimit = token supply upper limit.
     * @param _initialSupply = token amount to increase
     */
    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supplyUpperLimit,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        decimalValue = _decimals;
        uint256 _initSupply = _initialSupply * (10 ** uint256(_decimals));

        // Token upper limit is fixed during the creation of the contract.
        supplyUpperLimit = _supplyUpperLimit * (10 ** uint256(_decimals));

        // This is the only place where we ever mint tokens for initial supply
        _mint(msg.sender, _initSupply);
    }


    /**
     * @dev Allow only the owner of the contract to increase the supply of the token.
     * The max supply is restricted by the token upper limit.
     *
     * @param amount = token amount to increase
     */
    function mint(
        uint256 amount
    )
    external
    onlyOwner {
        uint256 _amount = amount * (10 ** uint256(decimalValue));
        uint256 _finalSupply = totalSupply() + _amount;
        require(_finalSupply <= supplyUpperLimit, "Cant mint more than supply limit ");
        _mint(msg.sender, _amount);
    }


    /**
     * @dev Allow only the owner to burn tokens from the owner's wallet, also decreasing the total
     * supply. There is no reason for a token holder to EVER call this method directly. It will be
     * used by the future SportZchain ecosystem token contract to implement token redemption.
     *
     * @param amount = token amount to burn
     */
    function burn(
        uint256 amount
    )
    public
    override (ERC20Burnable)
    onlyOwner {
        uint256 _amount = amount * (10 ** uint256(decimalValue));
        // This is the only place where we ever burn tokens.
        _burn(msg.sender, _amount);
        supplyUpperLimit -= _amount;
    }


    function _mint(address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }


    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
    internal
    virtual
    override (ERC20,ERC20Pausable){
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev Triggers stopped state. Can be paused only by the owner
     */
    function pause()
    external
    onlyOwner {
        _pause();
    }

    /**
    * @dev Returns to normal state. Can be unpaused only by the owner
     */
    function unpause()
    external
    onlyOwner {
        _unpause();
    }
}
