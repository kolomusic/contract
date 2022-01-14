// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interface/IKOLOBidding.sol";

abstract contract BiddingCallerBase {

    address public _biddingContract;

    constructor() {
    }

    modifier biddingReady() {
        require(_biddingContract != address(0), "Bidding not ready");
        _;
    }

    function _updateBiddingContract(address addr) internal {
        require(addr != address(0), "Bidding is 0");
        _biddingContract = addr;
    }

    function isBiddingDone(uint256 uniId_) internal view biddingReady returns(bool) {
        return IKOLOBidding(_biddingContract).isBiddingDone(uniId_);
    }

}