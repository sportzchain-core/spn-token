//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract VerifiedAccount {

    mapping(address => bool) private _isRegistered;

    constructor ()  {
        // The smart contract starts off registering itself, since address is known.
        registerAccount();
    }

    event AccountRegistered(address indexed account);

    /**
     * This registers the calling wallet address as a known address. Operations that transfer responsibility
     * may require the target account to be a registered account, to protect the system from getting into a
     * state where administration or a large amount of funds can become forever inaccessible.
     */
    function registerAccount() public returns (bool ok) {
        _isRegistered[msg.sender] = true;
        emit AccountRegistered(msg.sender);
        return true;
    }

    function isRegistered(address account) external view returns (bool ok) {
        return _isRegistered[account];
    }

    function _accountExists(address account) internal view returns (bool exists) {
        return account == msg.sender || _isRegistered[account];
    }

    modifier onlyExistingAccount(address account) {
        require(_accountExists(account), "account not registered");
        _;
    }

}
