//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SportZchainToken is Ownable, ERC20Pausable, ERC20Burnable {
    using SafeMath for uint256;
    uint256 supplyUpperLimit;
    uint8 decimalValue;

    constructor (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supplyUpperLimit,
        uint256 _initialSupply
    ) ERC20(_name, _symbol)  {
        // This is the only place where we ever mint tokens for initial supply
        uint256 _initSupply = _initialSupply.mul(10 ** uint256(_decimals));
        supplyUpperLimit = _supplyUpperLimit.mul(10 ** uint256(_decimals));
        decimalValue = _decimals;
        _mint(msg.sender, _initSupply);
    }

    // allow owner to mint more to increase the supply
    function mint(
        address to,
        uint256 amount
    )
    external
    onlyOwner {
        uint256 _amount = amount.mul(10 ** uint256(decimalValue));
        uint256 _finalSupply = totalSupply() + _amount;
        require(_finalSupply <= supplyUpperLimit, "Cant mint more than supply limit ");
        _mint(to, _amount);
    }

    // allow the token to be burnt by the owner
    function burn(
        uint256 amount
    )
    public
    override (ERC20Burnable)
    onlyOwner {
        uint256 _amount = amount.mul(10 ** uint256(decimalValue));
        _burn(msg.sender, _amount);
        supplyUpperLimit -= _amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override (ERC20,ERC20Pausable){
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}
