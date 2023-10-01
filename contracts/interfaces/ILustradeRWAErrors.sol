// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradeRWAErrors {
    error IsStaking(uint256 tokenId);
    error IsNotStaking(uint256 tokenId);
    error IsRedeeming(uint256 tokenId);
    error IsNotRedeeming(uint256 tokenId);
    error NotApprovedOrOwner(address caller, uint256 tokenId);
    error ArrayLengthNotEqual(uint256 len1, uint256 len2, uint256 len3);
}
