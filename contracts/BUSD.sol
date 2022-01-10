// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract BUSD is ERC20 {

    constructor(address to, uint256 supply) ERC20("Binance USD", "BUSD") {
        _mint(to, supply);
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return 6;
    }
}
