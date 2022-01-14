// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IKOLOTape.sol";
import "./base/AccessControlBase.sol";


contract KOLOTape is IKOLOTape, ERC721, AccessControlBase {

    struct Tape {
        uint256 totalSupply;
        uint256 nextPrice;      //next tape price
        bool isExist;
    }

    using Strings for uint8;
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _totalTokenIds;

    mapping(uint256 => mapping(uint256 => Tape)) private _tapeTotalSupply;   //uniId -> (tapeId, supply)
    mapping(uint256 => uint256) private _tapeAmount;

    string private _preURI;

    event InitTapeInfo(uint256 uniId, uint256 tapeAmount, uint256[] priceArr);

    constructor(string memory baseURI_) ERC721("KOLO Tape", "KT") {
        _preURI = baseURI_;
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId_, bytes memory _data) public virtual override {
        //require(!_bindNFT[tokenId_].isBind, "safeTransferFrom: The token has been bound");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId_, _data);
    }

    function initTapeInfo(uint256 uniId, uint256 tapeAmount, uint256[] memory priceArr) external onlyBusiness {
        require(tapeAmount == priceArr.length, "tape amount not equeal price array length");

        for(uint i=1; i<=tapeAmount; i++) {
            if(_tapeTotalSupply[uniId][i].isExist) continue;
            _tapeTotalSupply[uniId][i] = Tape(0, priceArr[i-1], true);
        }
        _tapeAmount[uniId] = tapeAmount;
        emit InitTapeInfo(uniId, tapeAmount, priceArr);
    }

    function safeMintKT(address to, uint256 tapeTokenId) external override onlyMinter {

        _safeMint(to, tapeTokenId);
        _totalTokenIds.increment();

    }

    function isExistTape(uint256 uniId_, uint256 tapeId_) public view override returns(bool) {
        return _tapeTotalSupply[uniId_][tapeId_].isExist;
    }

    function getTapeNextPrice(uint256 uniId_, uint256 tapeId_) public view override returns(uint256) {
        return _tapeTotalSupply[uniId_][tapeId_].nextPrice;
    }

    function getTapeSupply(uint256 uniId_, uint256 tapeId_) public view override returns(uint256) {
        return _tapeTotalSupply[uniId_][tapeId_].totalSupply;
    }

    function updateTapeNextPrice(uint256 uniId_, uint256 tapeId_, uint256 price_) external override onlyMinter {
        _tapeTotalSupply[uniId_][tapeId_].nextPrice = price_;
    }

    function updateTapeSupply(uint256 uniId_, uint256 tapeId_, uint256 supply_) external override onlyMinter{
        _tapeTotalSupply[uniId_][tapeId_].totalSupply = supply_;
    }

    function getTapePrice(uint256 uniqueId_, uint256 tapeId_) public view  returns (uint256) {
        require(_tapeTotalSupply[uniqueId_][tapeId_].isExist, "The tokenId is not support");

        return _tapeTotalSupply[uniqueId_][tapeId_].nextPrice;
    }

    function getTapeInfo(uint256 uniqueId_, uint256 tapeId_) public view  returns (Tape memory) {
        require(_tapeTotalSupply[uniqueId_][tapeId_].isExist, "The tokenId is not support");

        return _tapeTotalSupply[uniqueId_][tapeId_];
    }

    function getAllTapeInfo(uint256 uniqueId_) public view  returns (uint256[] memory prices, uint256[] memory supplys) {
        uint256 cnt = _tapeAmount[uniqueId_];
        prices = new uint256[](cnt);
        supplys = new uint256[](cnt);
        for(uint256 i=0; i<cnt; i++) {
            prices[i] = _tapeTotalSupply[uniqueId_][i+1].nextPrice;
            supplys[i] = _tapeTotalSupply[uniqueId_][i+1].totalSupply;
        }
        return (prices, supplys);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _preURI;
        return string(abi.encodePacked(base, tokenId.toString()));
    }


    function setBaseURI(string memory baseURI_) external override onlyAdmin {
        _preURI = baseURI_;
    }

    function baseURI() public view virtual returns (string memory) {
        return _preURI;
    }

    function totalTapeSupply(uint256 uniqueId_, uint256 tapeId_) public view returns (uint256) {
        require(_tapeTotalSupply[uniqueId_][tapeId_].isExist, "The tokenId is not support");
        return _tapeTotalSupply[uniqueId_][tapeId_].totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalTokenIds.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,AccessControlBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
