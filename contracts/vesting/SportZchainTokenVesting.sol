//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Vestable.sol";

contract SportZchainTokenVesting is ERC20Vestable {
    constructor (
        IERC20 sportzchain
    ) ERC20Vestable (sportzchain){

    }
}
