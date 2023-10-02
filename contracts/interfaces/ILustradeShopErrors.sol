// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradeShopErrors {
    error NotAccepted();
    error NotList();
    error InvalidMsgValue(uint256 expected, uint256 actual);
    error CannotBuy(uint256 requiredLevel, uint256 passcardLevel);
    error NotApprovedOrOwner();
}
