// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Tape contract interface
interface IKOLOTape {
    function setBaseURI(string memory baseURI_) external;

    function getTapeNextPrice(uint256 uniId_, uint256 tapeId_) external view returns(uint256) ;

    function getTapeSupply(uint256 uniId_, uint256 tapeId_) external view returns(uint256) ;

    function isExistTape(uint256 uniId_, uint256 tapeId_) external view returns(bool);

    function updateTapeNextPrice(uint256 uniId_, uint256 tapeId_, uint256 price_) external;

    function updateTapeSupply(uint256 uniId_, uint256 tapeId_, uint256 supply_) external;

    function safeMintKT(address to, uint256 tapeTokenId) external;
}