// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IKOLOTape.sol";
import "../interface/IKOLOUnique.sol";
import "../interface/IKOLOBidding.sol";

abstract contract BiddingCallerBase {

    address internal _biddingContract;

    constructor() {
    }

    modifier biddingReady() {
        require(_biddingContract != address(0), "Bidding contract is not ready");
        _;
    }

    function biddingContract() public view biddingReady returns (address) {
        return _biddingContract;
    }

    function _updateBiddingContract(address addr) internal {
        _biddingContract = addr;
    }

    function isBiddingDone(uint256 uniId_) internal view biddingReady returns(bool) {
        return IKOLOBidding(_biddingContract).isBiddingDone(uniId_);
    }

}