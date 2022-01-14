// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20TokenCallerBase {

    mapping(uint8 => address) internal _supportTokenContract;
    uint8 _supportCnt;

    constructor() {
        _supportTokenContract[0] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        _supportCnt = 1;
    }

    function isSupportToken(address contract_) public view returns (bool) {
        bool isExist = false;
        for(uint8 i=0; i<_supportCnt; i++) {
            if(_supportTokenContract[i] == contract_) {
                isExist = true;
                break;
            }
        }
        return isExist;
    }

    function supportTokens() public view returns (address[] memory tokenArr) {
        tokenArr = new address[](_supportCnt);
        for(uint8 i=0; i<_supportCnt; i++) {
            tokenArr[i] = _supportTokenContract[i];
        }
        return tokenArr;
    }

    function _addTokenContract(address addr) internal {
        require(!isSupportToken(addr), "Token already");
        require(_supportCnt <= 5, "limit 5");

        _supportTokenContract[_supportCnt] = addr;
        _supportCnt += 1;
    }

    function balanceOfERC20Token(address owner, address tokenContract_) internal view returns (uint256) {
        require(isSupportToken(tokenContract_), "not support");

        return IERC20(tokenContract_).balanceOf(owner);
    }

    function transferERC20Token(address recipient, address tokenContract_, uint256 amount) internal {
        require(isSupportToken(tokenContract_), "not support");
        IERC20(tokenContract_).transfer(recipient, amount);
    }

    function transferERC20TokenFrom(address sender, address recipient, address tokenContract_, uint256 amount) internal {
        require(isSupportToken(tokenContract_), "not support");
        bool isSuccess = IERC20(tokenContract_).transferFrom(sender, recipient, amount);
        require(isSuccess, "transfer return false");
    }

    function checkERC20TokenBalanceAndApproved(address owner, address tokenContract_, uint256 amount) internal view{
        require(isSupportToken(tokenContract_), "not support");

        uint256 tokenBalance = IERC20(tokenContract_).balanceOf(owner);
        require(tokenBalance >= amount, "Token balance not enough");

        uint256 allowanceToken = IERC20(tokenContract_).allowance(owner, address(this));
        require(allowanceToken >= amount, "Token allowance not enough");
    }

}