// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IKOLOUnique.sol";
import "./base/AccessControlBase.sol";

contract KOLOUnique is IKOLOUnique, ERC721, AccessControlBase {

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _preURI;

    constructor(string memory baseURI_) ERC721("KOLO Unique", "KU") {
        _setBaseURI(baseURI_);
    }

    function safeBatchMintKU(address to, uint256 numberOfTokens) external onlyMinter  {

        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(to, tokenId);
        }

    }

    function safeMintKU(address to) external onlyMinter override returns (uint256) {

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function exists(uint256 tokenId) external view virtual override returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory baseURI_) external override onlyAdmin {
        _setBaseURI(baseURI_);
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return _preURI;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _preURI = baseURI_;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,AccessControlBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
