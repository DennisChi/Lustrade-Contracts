// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradeRWAEvents {
    event Stake(uint256 indexed tokenId);
    event Redeem(uint256 indexed tokenId);
    event Release(uint256 indexed tokenId);
}
