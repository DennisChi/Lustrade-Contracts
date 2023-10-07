// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradeShop {
    event List(address tokenAddress, uint256 tokenId, uint256 price);
    event Delist(address tokenAddress, uint256 tokenId);

    error NotList();
    error InvalidMsgValue(uint256 expected, uint256 actual);
    error CannotBuy(uint256 requiredLevel, uint256 passcardLevel);

    function addSupportToken(address tokenAddress) external;

    function removeSupportToken(address tokenAddress) external;

    function list(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    ) external;

    function delist(address tokenAddress, uint256 tokenId) external;

    function buy(
        address tokenAddress,
        uint256 tokenId,
        uint256 passcardId,
        bool autoUpgrade
    ) external payable;

    function withdraw(uint256 value) external;

    function setPurchasableLevel(
        address tokenAddress,
        uint256 purchasableLevel
    ) external;

    function setGlobalDiscount(uint256 discount) external;

    function setSeriesDiscount(address tokenAddress, uint256 discount) external;

    function setDiscount(
        address tokenAddress,
        uint256 passcardLevel,
        uint256 discount
    ) external;
}
