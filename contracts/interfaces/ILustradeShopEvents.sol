// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradeShopEvents {
    event List(address tokenAddress, uint256 tokenId, uint256 price);
    event Delist(address tokenAddress, uint256 tokenId);
}
