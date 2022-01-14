// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IKOLOTape.sol";
import "../interface/IKOLOUnique.sol";

abstract contract KOLONFTCallerBase {

    address public _uniqueContract;
    address public _tapeContract;

    constructor() {
    }

    modifier nftReady() {
        require(_uniqueContract != address(0), "Unique is 0");
        require(_tapeContract != address(0), "Tape is 0");
        _;
    }

    function getTapeNextPrice(uint256 uniId_, uint256 tapeId_) internal view nftReady returns (uint256) {
        return IKOLOTape(_tapeContract).getTapeNextPrice(uniId_, tapeId_);
    }

    function updateTapeNextPrice(uint256 uniId_, uint256 tapeId_, uint256 price_) internal  {
        IKOLOTape(_tapeContract).updateTapeNextPrice(uniId_, tapeId_, price_);
    }

    function getTapeSupply(uint256 uniId_, uint256 tapeId_) internal view nftReady returns (uint256) {
        return IKOLOTape(_tapeContract).getTapeSupply(uniId_, tapeId_);
    }

    function updateTapeSupply(uint256 uniId_, uint256 tapeId_, uint256 supply_) internal {
        IKOLOTape(_tapeContract).updateTapeSupply(uniId_, tapeId_, supply_);
    }

    function isExistTape(uint256 uniId_, uint256 tapeId_) internal view nftReady returns (bool) {
        return IKOLOTape(_tapeContract).isExistTape(uniId_, tapeId_);
    }

    function safeMintKT(address to, uint256 tapeTokenId) internal {
        IKOLOTape(_tapeContract).safeMintKT(to, tapeTokenId);
    }

    function _safeMintKU(address to) internal returns(uint256) {
        return IKOLOUnique(_uniqueContract).safeMintKU(to);
    }

    function _setUniAndTapeContract(address uniContract_, address tapeContract_) internal {
        require(uniContract_ != address(0), "Unique is 0");
        require(tapeContract_ != address(0), "Tape is 0");
        _tapeContract = tapeContract_;
        _uniqueContract = uniContract_;
    }

    function _transferUnique(address to_, uint256 tokenId_) internal {
        IERC721(_uniqueContract).safeTransferFrom(address(this), to_, tokenId_);
    }

    function ownerOfUnique(uint256 tokenId) internal view nftReady returns (address)  {
        return IERC721(_uniqueContract).ownerOf(tokenId);
    }

    function uniqueExist(uint256 tokenId) internal view nftReady returns (bool)  {
        return IKOLOUnique(_uniqueContract).exists(tokenId);
    }

}