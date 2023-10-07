// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface ILusstradePasscard is IERC721 {
    /**
     * Emit when a token levels up
     * @param tokenId ID of upgraded token
     * @param newLevel the new level of the token
     */
    event Upgrade(uint256 indexed tokenId, uint256 newLevel);

    /**
     * Emit when the manager add a new level
     * @param level the value of new level
     * @param requiredPoints points required to reach a new level
     */
    event NewLevel(uint256 indexed level, uint256 requiredPoints);

    /**
     * Emit when a user set new level for display
     * @param tokenId ID of the updated token
     * @param displayLevel updated level for display
     */
    event UpdateDisplayLevel(uint256 tokenId, uint256 displayLevel);

    /**
     * Mint a passcard.
     * @dev one address can only mint once.
     *      revert if repeat mint
     * @return tokenId the ID of token minted.
     */
    function mint() external payable returns (uint256 tokenId);

    /**
     * @dev set new display level for the appointed token
     *      revert if `tokenId` doesn't exist
     *      revert if `displayLevel` exceeds maximum level
     *      revert if `msg.sender` is not token's owner
     *      revert if token of `tokenId`'s level is less than the display level
     * @param tokenId the ID of the token that will set the new display level
     * @param displayLevel the new level for display
     */
    function setDisplayLevel(uint256 tokenId, uint256 displayLevel) external;

    /**
     * @dev set new display level for the appointed token
     *      revert if `tokenOwner` is zero
     *      revert if `tokenId` doesn't exist
     *      revert if `displayLevel` exceeds maximum level
     *      revert if `msg.sender` is not token's owner or approved
     *      revert if token of `tokenId`'s level is less than the display level
     * @param tokenOwner the address to set new display level
     * @param tokenId the ID of the token that will set the new display level
     * @param displayLevel the new level for display
     */
    function setDisplayLevelFor(
        address tokenOwner,
        uint256 tokenId,
        uint256 displayLevel
    ) external;

    /**
     * @dev Add `addPoints` points to token of `tokenId` and auto upgrade
     *      display level if autoUpgrade is true
     *      emit `Upgrade` if a token upgraded
     *      revert if `tokenId` doesn't exist
     *      revert if addPoints is zero
     * @param tokenId the ID of token to add points
     * @param addPoints the points to be added
     * @param autoUpgrade whether to automatically upgrade
     */
    function increasePoints(
        uint256 tokenId,
        uint256 addPoints,
        bool autoUpgrade
    ) external;

    /**
     * @dev Add a new level with points requirements and base URI.
     *      emit `NewLevel` if succeed
     *      revert if `requiredPoints` is zero
     *      revert if `requiredPoints` is less or equal than previous level
     * @param requiredPoints points required to reach the new level
     * @param levelBaseURI the base URI of new level
     */
    function addLevel(
        uint256 requiredPoints,
        string calldata levelBaseURI
    ) external;

    /**
     * @dev Set base level once.
     *      revert if setted.
     *      revert if level cap is not 0.
     * @param baseLevelUri the URI of base level.
     */
    function setBaseLevelOnce(string calldata baseLevelUri) external;
}
