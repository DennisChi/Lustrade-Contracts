// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradePasscardEvents {
    event Upgrade(uint256 indexed tokenId, uint256 newLevel);
    event NewLevel(uint256 indexed level, uint256 requiredPoints);
    event UpdateDisplayLevel(uint256 tokenId, uint256 displayLevel);
}
