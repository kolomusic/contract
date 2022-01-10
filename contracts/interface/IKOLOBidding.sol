// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// market contract interface
interface IKOLOBidding {
    function isBiddingDone(uint256 uniqueId_) external view returns(bool);
}