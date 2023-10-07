// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./LustradePasscard.sol";

import "./interfaces/ILustradeShopEvents.sol";
import "./interfaces/ILustradeShopErrors.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LustradeShop is Ownable, ILustradeShopEvents, ILustradeShopErrors {
    using SafeMath for uint256;

    LustradePasscard immutable passcard;

    uint256 globalDiscount;

    /**
     * @dev `token address` => `discount`
     */
    mapping(address => uint256) seriesDiscountOf;

    /**
     * @dev `token address` => `passcard level` => `discount`
     */
    mapping(address => mapping(uint256 => uint256)) discountOf;

    /**
     * @dev `token address` => `purchasable passcard level`
     */
    mapping(address => uint256) purchasableLevelOf;

    /**
     * @dev `token address` => `is accepted`
     */
    mapping(address => bool) isAccepted;

    /**
     * @dev `token address` => `token id` => `price`
     */
    mapping(address => mapping(uint256 => uint256)) priceOf;

    constructor(address owner, address passcardAddress) {
        _transferOwnership(owner);
        passcard = LustradePasscard(passcardAddress);
    }

    modifier onlyAccepted(address tokenAddress) {
        if (!isAccepted[tokenAddress]) {
            revert NotAccepted();
        }
        _;
    }

    modifier onlyApprovedOrOwner(address tokenAddress, uint256 tokenId) {
        IERC721 rwa = IERC721(tokenAddress);
        address owner = rwa.ownerOf(tokenId);
        address approver = rwa.getApproved(tokenId);
        if (msg.sender != owner && msg.sender != approver) {
            revert NotApprovedOrOwner();
        }
        _;
    }

    function addSupportToken(address tokenAddress) external onlyOwner {
        isAccepted[tokenAddress] = true;
    }

    function removeSupportToken(address tokenAddress) external onlyOwner {
        isAccepted[tokenAddress] = false;
    }

    function list(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyOwner
        onlyAccepted(tokenAddress)
        onlyApprovedOrOwner(tokenAddress, tokenId)
    {
        priceOf[tokenAddress][tokenId] = price;

        emit List(tokenAddress, tokenId, price);
    }

    function delist(
        address tokenAddress,
        uint256 tokenId
    )
        external
        onlyOwner
        onlyAccepted(tokenAddress)
        onlyApprovedOrOwner(tokenAddress, tokenId)
    {
        priceOf[tokenAddress][tokenId] = 0;

        emit Delist(tokenAddress, tokenId);
    }

    function buy(
        address tokenAddress,
        uint256 tokenId,
        uint256 passcardId,
        bool autoUpgrade
    ) external payable onlyAccepted(tokenAddress) {
        uint256 price = priceOf[tokenAddress][tokenId];
        if (price == 0) {
            revert NotList();
        }

        uint256 purchasableLevel = purchasableLevelOf[tokenAddress];
        uint256 passcardLevel = passcard.levelOf(passcardId);
        if (passcardLevel < purchasableLevel) {
            revert CannotBuy(purchasableLevel, passcardLevel);
        }

        uint256 discount = discountOf[tokenAddress][passcardLevel];
        if (discount == 0) {
            discount = seriesDiscountOf[tokenAddress];
        }
        if (discount == 0) {
            discount = globalDiscount;
        }

        uint256 originalPrice = priceOf[tokenAddress][tokenId];
        uint256 cutoffPrice = originalPrice.div(1000).mul(discount);
        uint256 actualPrice = originalPrice - cutoffPrice;
        if (msg.value < actualPrice) {
            revert InvalidMsgValue(actualPrice, msg.value);
        }

        address payable payto = payable(address(this));
        payto.transfer(actualPrice);

        IERC721 rwa = IERC721(tokenAddress);
        address owner = rwa.ownerOf(tokenId);
        rwa.safeTransferFrom(owner, msg.sender, tokenId);

        uint256 addPoints = actualPrice * 1000;
        passcard.increasePoints(tokenId, addPoints, autoUpgrade);
    }

    function withdraw(uint256 value) external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(value);
    }

    function setPurchasableLevel(
        address tokenAddress,
        uint256 purchasableLevel
    ) external onlyOwner {
        purchasableLevelOf[tokenAddress] = purchasableLevel;
    }

    function setGlobalDiscount(uint256 discount) external onlyOwner {
        globalDiscount = discount;
    }

    function setSeriesDiscount(
        address tokenAddress,
        uint256 discount
    ) external onlyOwner {
        seriesDiscountOf[tokenAddress] = discount;
    }

    function setDiscount(
        address tokenAddress,
        uint256 passcardLevel,
        uint256 discount
    ) external onlyOwner {
        discountOf[tokenAddress][passcardLevel] = discount;
    }
}
