// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/AccessControlBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/KOLONFTCallerBase.sol";
import "./base/BiddingCallerBase.sol";
import "./utils/StringUtil.sol";
import "./utils/ERC721Holder.sol";

contract KOLOMarket is ERC20TokenCallerBase, KOLONFTCallerBase, BiddingCallerBase, AccessControlBase, ERC721Holder {

    using SafeMath for uint256;
    using StringUtil for *;

    uint256 private _totalAmount = 0;
    uint256 private _withdrawAmount = 0;
    uint8 public uniqueRebateRatio = 20;

    uint8 private constant _STEP = 50;       //per step number tapes, price will increment
    uint8 private constant increasePercent = 10;      //10%

    address payable private constant TREASURY_ADDRESS = payable(0xC3B0ac7acA3Fb2AEB8D623614E7C98D0EbFF2977);

    event BuyTapeNFT(address sender, address contractAddress, uint256 totalPrice, uint256[] uniTokenIds, uint256[][] tapeIndexArrs, uint256[][] numberArrs);

    constructor() {
    }

    function setRebateRatio(uint8 rebateUniOwner_) external onlyAdmin  {
        require(rebateUniOwner_ > 0 && rebateUniOwner_ < 100, "between 0 and 100");
        uniqueRebateRatio = rebateUniOwner_;
    }

    function getTotalSaleAmount() external onlyFunds view returns(uint256) {
        return _totalAmount;
    }

    function getWithdrawAmount() external onlyFunds view returns(uint256) {
        return _withdrawAmount;
    }

    function buyTapeNFT(address contractAddress, uint256[] memory uniTokenIds, uint256[][] memory tapeIndexArrs, uint256[][] memory numberArrs) external whenNotPaused {
        require(msg.sender != address(0), "Sender is 0");
        uint256 len = uniTokenIds.length;
        require(tapeIndexArrs.length == len,"tapeArr length error");
        require(numberArrs.length == len,"numberArrs length error");
        require(_calculateTotalNumber(numberArrs) <= 50, "total number limit 50");

        for(uint i=0; i<uniTokenIds.length; i++) {
            _buyTapeNFT(contractAddress, uniTokenIds[i], tapeIndexArrs[i], numberArrs[i]);
        }
        emit BuyTapeNFT(msg.sender, contractAddress, calculateTotalPrice(uniTokenIds, tapeIndexArrs, numberArrs), uniTokenIds, tapeIndexArrs, numberArrs);
    }

    function _buyTapeNFT(address contractAddress, uint256 uniTokenId, uint256[] memory tapeIndexArr, uint256[] memory numberArr) internal {
        require(tapeIndexArr.length == numberArr.length, "numberArr length error");
        require(msg.sender != address(0), "Invalid buyer");
        require(isBiddingDone(uniTokenId), "Unique bidding not over");

        uint256 totalPrice = _calculateTotalPrice(uniTokenId, tapeIndexArr, numberArr);

        checkERC20TokenBalanceAndApproved(msg.sender, contractAddress, totalPrice);

        _totalAmount = _totalAmount.add(totalPrice);

        transferERC20TokenFrom(msg.sender, address(this), contractAddress, totalPrice);

        if(ownerOfUnique(uniTokenId) != address(0)) {
            transferERC20Token(ownerOfUnique(uniTokenId), contractAddress, totalPrice.mul(uniqueRebateRatio).div(100));
        }

        string memory _uniIdStr = _handleTokenId(uniTokenId, true, false);
        for (uint i = 0; i < tapeIndexArr.length; i++) {
            uint256 _tapeId = tapeIndexArr[i];

            require(isExistTape(uniTokenId, _tapeId), "Tape not init");

            for (uint j = 0; j < numberArr[i]; j++) {
                uint256 _currPrice = getTapeNextPrice(uniTokenId, _tapeId);

                uint256 _tapeAmount = getTapeSupply(uniTokenId, _tapeId).add(1);
                require(_tapeAmount <= 1000, "limit 1000");

                updateTapeSupply(uniTokenId, _tapeId, _tapeAmount);
                if (_tapeAmount.mod(_STEP) == 0) {
                    updateTapeNextPrice(uniTokenId, _tapeId, _currPrice.add(_currPrice.mul(increasePercent).div(100)));
                }

                string memory _tokenIdTmp = _uniIdStr.toSlice().concat(_handleTokenId(_tapeId, false, true).toSlice());
                safeMintKT(msg.sender, _parseInt(_tokenIdTmp.toSlice().concat(_handleTokenId(_tapeAmount, false, false).toSlice())));
            }
        }
    }

    function _calculateTotalNumber(uint256[][] memory numberArrs) internal pure returns (uint256) {
        uint256 len = numberArrs.length;

        uint256 totalNum = 0;
        for(uint i=0; i<len; i++) {
            for(uint256 j=0; j<numberArrs[i].length; j++) {
                totalNum = totalNum.add(numberArrs[i][j]);
            }
        }
        return totalNum;
    }

    function calculateTotalPrice(uint256[] memory uniTokenIds, uint256[][] memory tapeIndexArrs, uint256[][] memory numberArrs) public view returns (uint256) {
        uint256 len = uniTokenIds.length;
        require(tapeIndexArrs.length == len,"tapeArr length error");
        require(numberArrs.length == len,"numArr length error");

        uint256 totalPrice = 0;
        for(uint i=0; i<uniTokenIds.length; i++) {
            uint256 uniTotalPrie = _calculateTotalPrice(uniTokenIds[i], tapeIndexArrs[i], numberArrs[i]);
            totalPrice = totalPrice.add(uniTotalPrie);
        }
        return totalPrice;
    }

    // withdraw balance
    function withdrawErc20Balance(address contractAddress, uint256 amount) external onlyFunds {
        uint256 currentBalance = balanceOfERC20Token(address(this), contractAddress);
        require(amount <= currentBalance, "No enough");
        transferERC20Token(TREASURY_ADDRESS, contractAddress, amount);
        _withdrawAmount = _withdrawAmount.add(amount);
    }

    function withdraw(uint256 amount) public onlyFunds {
        TREASURY_ADDRESS.transfer(amount);
    }

    function setUniqueTapeBiddingContract(address uniContract_, address tapeContract_, address bidding_) external onlyAdmin {
        _setUniAndTapeContract(uniContract_, tapeContract_);
        _updateBiddingContract(bidding_);
    }

    function addTokenContract(address contractAddress_) external onlyAdmin {
        _addTokenContract(contractAddress_);
    }

    function _calculateTotalPrice(uint256 uniTokenId, uint256[] memory tapeIndexArr, uint256[] memory numberArr) internal view returns (uint256) {
        uint256 totalPrcie = 0;

        for (uint i = 0; i < tapeIndexArr.length; i++) {
            uint256 _tapeId = tapeIndexArr[i];

            require(isExistTape(uniTokenId, _tapeId), "calculateTotalPrice: The tokenId is not support");

            uint256 cnt = numberArr[i];
            uint256 _counter = getTapeSupply(uniTokenId, _tapeId);
            uint256 _currPrice = getTapeNextPrice(uniTokenId, _tapeId);

            for (uint j = 0; j < cnt; j++) {
                totalPrcie = totalPrcie.add(_currPrice);
                _counter = _counter.add(1);
                if (_counter.mod(_STEP) == 0) {
                    uint256 tmp = _currPrice.mul(increasePercent).div(100);
                    _currPrice = _currPrice.add(tmp);
                }
            }
        }
        return totalPrcie;
    }

    //uniqueId 6 len, tapeId 4 len, amount len 8 len
    function _handleTokenId(uint256 tokenId_, bool isUniqueId, bool isTapeId) internal pure returns (string memory) {
        uint len = 6;
        if (isTapeId) {
            len = 4;
        }

        string memory targetStr = new string(len);
        bytes memory result = bytes(targetStr);
        bytes memory resource = bytes(tokenId_.toString());

        if (isUniqueId) {
            result[0] = "1";
        } else {
            result[0] = "0";
        }

        uint cnt = 0;
        for (uint i = 1; i < (len - resource.length); i++) {
            result[i] = "0";
            cnt = i;
        }

        for (uint j = 0; j < resource.length; j++) {
            result[cnt + 1] = resource[j];
            cnt = cnt + 1;
        }

        return targetStr;
    }

    function _parseInt(string memory _a) internal pure returns (uint256) {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;

        for (uint i=0; i<bresult.length; i++){
            require((uint8(bresult[i]) >= 48)&&(uint8(bresult[i]) <= 57),"parseInt error");

            mint *= 10;
            mint += uint8(bresult[i]) - 48;
        }

        return mint;
    }

    fallback() external payable {}

    receive() external payable {}

}
