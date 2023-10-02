// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./interfaces/ILustradePasscardEvents.sol";
import "./interfaces/ILustradePasscardErrors.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

contract LustradeClubPasscard is
    ERC721Consecutive,
    AccessControl,
    ILustradePasscardEvents,
    ILustradePasscardErrors
{
    using Strings for uint256;

    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant ADD_POINTS = keccak256("ADD_POINTS");
    bytes32 public constant ADD_LEVEL = keccak256("ADD_LEVEL");

    mapping(uint256 => uint256) public pointsOfToken;
    mapping(uint256 => uint256) public levelOfToken;
    mapping(uint256 => uint256) public requiredPointsOfLevel;
    mapping(uint256 => uint256) displayLevelOfToken;
    mapping(uint256 => string) baseURIOfLevel;

    constructor(address owner) ERC721("Lustrade Club Passcard", "LCP") {
        _grantRole(MANAGER, owner);
        _setRoleAdmin(ADD_POINTS, MANAGER);
        _setRoleAdmin(ADD_LEVEL, MANAGER);
    }

    function setDisplayLevel(
        address from,
        uint256 tokenId,
        uint256 displayLevel
    ) external {
        address approver = getApproved(tokenId);
        address owner = ERC721.ownerOf(tokenId);
        if ((msg.sender != approver) && (msg.sender != owner)) {
            revert NotApproverOrOwner(msg.sender, tokenId);
        }
        if (owner != from) {
            revert FromIncorrectOwner(owner, from);
        }
        uint256 maxLevel = levelOfToken[tokenId];
        if (displayLevel > maxLevel) {
            revert ExceedMaxLevel(displayLevel, maxLevel);
        }

        uint256 curDisplayLevel = displayLevelOfToken[tokenId];
        if (curDisplayLevel == displayLevel) return;
        displayLevelOfToken[tokenId] = displayLevel;

        emit UpdateDisplayLevel(tokenId, displayLevel);
    }

    function increasePoints(
        uint256 tokenId,
        uint256 addPoints,
        bool autoUpgrade
    ) external onlyRole(ADD_POINTS) {
        uint256 points = pointsOfToken[tokenId];
        points += addPoints;
        pointsOfToken[tokenId] = points;
        if (!autoUpgrade) return;

        uint256 level = levelOfToken[tokenId];
        uint256 nextLevel = level + 1;
        uint256 requiredPointsOfNextLevel = requiredPointsOfLevel[nextLevel];
        if (requiredPointsOfNextLevel == 0) return;
        if (points < requiredPointsOfNextLevel) return;
        levelOfToken[tokenId] = nextLevel;

        emit Upgrade(tokenId, nextLevel);
    }

    function addLevel(
        uint256 newLevel,
        uint256 requiredPoints,
        string calldata levelBaseURI
    ) external onlyRole(ADD_LEVEL) {
        bool isFirstLevel = newLevel == 1;
        uint256 prevLevel = newLevel - 1;
        uint256 requiredPointsOfPrevLevel = requiredPointsOfLevel[prevLevel];
        bool prevLevelHasSetted = requiredPointsOfPrevLevel != 0;
        if ((!isFirstLevel) && (!prevLevelHasSetted)) return;
        if (requiredPoints <= requiredPointsOfPrevLevel) return;

        requiredPointsOfLevel[newLevel] = requiredPoints;
        baseURIOfLevel[newLevel] = levelBaseURI;

        emit NewLevel(newLevel, requiredPoints);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint256 level = levelOfToken[tokenId];
        string memory baseURI = baseURIOfLevel[level];
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}
