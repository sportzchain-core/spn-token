//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev An ERC20 implementation of the SportZchain ecosystem token. All tokens are initially pre-assigned to
 * the creator, and can later be distributed freely using transfer transferFrom and other ERC20 functions.
 */
contract SportZchainToken is Ownable, ERC20Pausable, ERC20Burnable, AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     *
     * @param _name = token name
     * @param _symbol = token symbol
     * @param _decimals = token decimals
     * @param _totalSupply = token supply of the token
     */
    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) ERC20(_name, _symbol)  {
        // This is the only place where we ever mint tokens for initial supply
        _mint(msg.sender,  _totalSupply * (10 ** uint256(_decimals)));
    }


    /**
     * @dev Allow only the owner to burn tokens from the owner's wallet, also decreasing the total
     * supply. There is no reason for a token holder to EVER call this method directly. It will be
     * used by the future SportZchain ecosystem token contract to implement token redemption.
     *
     * @param from = burn from account
     * @param _amount = token amount to burn
     */
    function burn(
        address from,
        uint256 _amount
    )
    public
    override (ERC20Burnable) {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        // This is the only place where we ever burn tokens.
        _burn(from, _amount);
    }


    /**
     * @dev Overrides _afterTokenTransfer - See ERC20 and ERC20Pausable
     *
     * @param from = address from which the tokens needs to be transferred
     * @param to = address to  which the tokens needs to be transferred
     * @param amount = token amount to be transferred
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
