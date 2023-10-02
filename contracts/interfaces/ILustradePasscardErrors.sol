// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface ILustradePasscardErrors {
    error NotApproverOrOwner(address caller, uint256 tokenid);
    error FromIncorrectOwner(address correctOwner, address incorrectOwner);
    error ExceedMaxLevel(uint256 toDisplayLevel, uint256 maxLevel);
}
