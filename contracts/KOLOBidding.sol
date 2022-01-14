// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IKOLOBidding.sol";
import "./base/AccessControlBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/KOLONFTCallerBase.sol";
import "./utils/ERC721Holder.sol";

contract KOLOBidding is IKOLOBidding, KOLONFTCallerBase, ERC20TokenCallerBase, AccessControlBase, ERC721Holder {

    struct UniqueNFT {
        address lastBidder;
        address erc20Contract;
        uint256 startPrice;
        uint256 lastPrice;
        uint8 increaseStep;       // increasePerent %
        uint256 biddingNum;
        bool isStarting;
        bool isDone;       //true - bidding had done
        bool isExist;
    }

    using SafeMath for uint256;

    uint256 private _totalAmount = 0;
    uint256 private _withdrawAmount = 0;
    mapping(uint256 => UniqueNFT) private _biddingUnique;

    address payable private constant TREASURY_ADDRESS = payable(0xC3B0ac7acA3Fb2AEB8D623614E7C98D0EbFF2977);

    event InitUniqueBidding(uint256 uniId, uint256 startPrice, uint8 step, bool isStarting);
    event PlaceBid(uint256 uniqudId, address newBidder, uint256 bidAmount, address preBidder, uint256 preAmount);
    event BiddingOver(uint256 uniqudId, address newOwner);

    function batchInitBidding(uint256[] memory uniIdArr, uint256[] memory startPriceArr, uint8[] memory stepArr, bool[] memory isStartingArr) external onlyBusiness {
        uint256 len = uniIdArr.length;
        require(len == startPriceArr.length ,"startPriceArr length not equeal");
        require(len == stepArr.length ,"stepArr length not equeal");
        require(len == isStartingArr.length ,"isStartingArr length not equeal");

        for(uint8 i=0; i<len; i++) {
            _initUniqueBidding(uniIdArr[i], startPriceArr[i], stepArr[i], isStartingArr[i]);
        }

    }

    function initUniqueBidding(uint256 uniId_, uint256 startPrice_, uint8 step_, bool isStarting_) external onlyBusiness {
        _initUniqueBidding(uniId_, startPrice_, step_, isStarting_);
    }

    function _initUniqueBidding(uint256 uniId_, uint256 startPrice_, uint8 step_, bool isStarting_) internal  {
        require(!_biddingUnique[uniId_].isStarting, "Bidding has started");
        require(step_ > 0 && step_ < 100, "IncreaseStep should be between 0 and 100");

        if(!uniqueExist(uniId_)) {
            uint256 tokenId = _safeMintKU(address (this));
            require(tokenId == uniId_, "Unique NFT unique tokenId is wrong");
        } else {
            address uniOwner = ownerOfUnique(uniId_);
            require(uniOwner != address(this), "Unique nft had owner");
        }

        UniqueNFT memory uniqueNFT = UniqueNFT(
                    address(0),
                    address(0),
                    startPrice_,
                    0,
                    step_,
                    0,
                    isStarting_,
                    false,
                    true
                );

        _biddingUnique[uniId_] = uniqueNFT;

        emit InitUniqueBidding(uniId_, startPrice_, step_, isStarting_);
    }

    function placeBid(uint256 uniqudId, address contractAddress, uint256 amount) external whenNotPaused {
        require(msg.sender != address(0), "Sender can not be empty");
        require(_isInitBidding(uniqudId), "The unique nft has not init");
        require(_biddingUnique[uniqudId].isStarting, "Unique auction did not start bidding");
        require(!_biddingUnique[uniqudId].isDone, "Unique NFT bidding had done");

        UniqueNFT memory unique = _biddingUnique[uniqudId];

        uint256 lastAmount;
        if(unique.biddingNum == 0) {
            lastAmount = unique.startPrice;

        } else {
            lastAmount = unique.lastPrice.mul(unique.increaseStep).div(100) + unique.lastPrice;
        }

        require(amount >= lastAmount, "The price should be more than start price");

        checkERC20TokenBalanceAndApproved(msg.sender, contractAddress, amount);

        _totalAmount = _totalAmount.add(amount);
        _biddingUnique[uniqudId].lastBidder = msg.sender;
        _biddingUnique[uniqudId].lastPrice = amount;
        _biddingUnique[uniqudId].biddingNum = unique.biddingNum.add(1);
        _biddingUnique[uniqudId].erc20Contract = contractAddress;

        transferERC20TokenFrom(msg.sender, address(this), contractAddress, amount);

        if(unique.lastBidder != address(0)) {
            transferERC20Token(unique.lastBidder, unique.erc20Contract, unique.lastPrice);
        }

        emit PlaceBid(uniqudId, msg.sender, amount, unique.lastBidder, unique.lastPrice);

    }

    function getLastBiddingInfo(uint256 uniqudId) external view returns(UniqueNFT memory) {
        return _biddingUnique[uniqudId];
    }

    function updateIncreaseStep(uint256 uniqudId, uint8 step_) external onlyAdmin {
        require(step_ > 0 && step_ < 100, "IncreaseStep should be between 0 and 100");
        require(_isInitBidding(uniqudId), "The unique nft has not init");
        require(!_isBiddingDone(uniqudId), "The unique nft has bidding over");
        _biddingUnique[uniqudId].increaseStep = step_;
    }

    function biddingStart(uint256 uniqudId) external onlyBusiness {
        require(_isInitBidding(uniqudId), "The unique nft has not init");
        require(!_isBiddingDone(uniqudId), "The unique nft has bidding over");
        _biddingUnique[uniqudId].isStarting = true;
    }

    function biddingOver(uint256 uniqudId) external onlyBusiness {
        require(_isInitBidding(uniqudId), "The unique nft has not init");
        require(!_isBiddingDone(uniqudId), "The unique nft has bidding over");
        _biddingUnique[uniqudId].isDone = true;
        _biddingUnique[uniqudId].isStarting = false;

        if(_biddingUnique[uniqudId].lastBidder != address(0)) {
            _transferUnique( _biddingUnique[uniqudId].lastBidder, uniqudId);
        }

        emit BiddingOver(uniqudId, _biddingUnique[uniqudId].lastBidder);
    }

    function isBiddingDone(uint256 uniqueId_) external view override returns(bool) {
        return _isBiddingDone(uniqueId_);
    }

    function _isBiddingDone(uint256 uniqueId_) internal view returns(bool) {
        require(_isInitBidding(uniqueId_), "The unique nft has not init");
        return _biddingUnique[uniqueId_].isDone;
    }

    function _isInitBidding(uint256 uniqueId_) internal view returns(bool) {
        return _biddingUnique[uniqueId_].isExist;
    }

    function setUniqueAndTapeContract(address uniContract_, address tapeContract_) external onlyAdmin {
        _setUniAndTapeContract(uniContract_, tapeContract_);
    }

    function addTokenContract(address contractAddress_) external onlyAdmin {
        _addTokenContract(contractAddress_);
    }

    function getTotalSaleAmount() external onlyFunds view returns(uint256) {
        return _totalAmount;
    }

    function getWithdrawAmount() external onlyFunds view returns(uint256) {
        return _withdrawAmount;
    }

    // withdraw balance
    function withdrawErc20Balance(address contractAddress, uint256 amount) external onlyFunds {
        uint256 currentBalance = balanceOfERC20Token(address(this), contractAddress);
        require(amount <= currentBalance, "No enough balance");
        transferERC20Token(TREASURY_ADDRESS, contractAddress, amount);
        _withdrawAmount = _withdrawAmount.add(amount);
    }

    function withdraw(uint256 amount) public onlyFunds {
        TREASURY_ADDRESS.transfer(amount);
    }

    fallback() external payable {}

    receive() external payable {}
}
