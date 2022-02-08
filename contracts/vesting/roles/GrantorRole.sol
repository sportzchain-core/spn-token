//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../lib/Roles.sol";


/**
 * @dev GrantorRole trait
 *
 * This adds support for a role that allows creation of vesting token grants, allocated from the
 * role holder's wallet.
 *
 * Owner is not allowed to renounce ownership, lest the contract go without administration. But
 * it is ok for owner to shed initially granted roles by removing role from self.
 */
abstract contract GrantorRole is Ownable {
    bool private constant OWNER_UNIFORM_GRANTOR_FLAG = false;

    using Roles for Roles.Role;

    event GrantorAdded(address indexed account);
    event GrantorRemoved(address indexed account);

    Roles.Role private _grantors;
    mapping(address => bool) private _isUniformGrantor;

    constructor () {
        _addGrantor(msg.sender, OWNER_UNIFORM_GRANTOR_FLAG);
    }

    modifier onlyGrantor() {
        require(isGrantor(msg.sender), "onlyGrantor");
        _;
    }

    modifier onlyGrantorOrSelf(address account) {
        require(isGrantor(msg.sender) || msg.sender == account, "onlyGrantorOrSelf");
        _;
    }

    function isGrantor(address account) public view returns (bool) {
        return _grantors.has(account);
    }

    function addGrantor(address account, bool uniformGrantor) public onlyOwner {
        _addGrantor(account, uniformGrantor);
    }

    function removeGrantor(address account) public onlyOwner {
        _removeGrantor(account);
    }

    function _addGrantor(address account, bool uniformGrantor) private {
        require(account != address(0));
        _grantors.add(account);
        _isUniformGrantor[account] = uniformGrantor;
        emit GrantorAdded(account);
    }

    function _removeGrantor(address account) private {
        require(account != address(0));
        _grantors.remove(account);
        emit GrantorRemoved(account);
    }

    function isUniformGrantor(address account) public view returns (bool) {
        return isGrantor(account) && _isUniformGrantor[account];
    }

    modifier onlyUniformGrantor() {
        require(isUniformGrantor(msg.sender), "onlyUniformGrantor");
        // Only grantor role can do this.
        _;
    }


    // =========================================================================
    // === Overridden ERC20 functionality
    // =========================================================================

    /**
     * Ensure there is no way for the contract to end up with no owner. That would inadvertently result in
     * token grant administration becoming impossible. We override this to always disallow it.
     */
    function renounceOwnership() public override view onlyOwner {
        require(false, "forbidden");
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public override virtual  onlyOwner {
        _removeGrantor(msg.sender);
        super.transferOwnership(newOwner);
        _addGrantor(newOwner, OWNER_UNIFORM_GRANTOR_FLAG);
    }
}
