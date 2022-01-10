// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Unique contract interface
interface IKOLOUnique {
    function safeMintKU(address to) external returns (uint256);

    function setBaseURI(string memory baseURI_) external;

    function exists(uint256 tokenId) external view returns (bool);

}