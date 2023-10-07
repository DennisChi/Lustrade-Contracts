// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./interfaces/ILustradePasscard.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LustradePasscard is ILusstradePasscard, AccessControl, ERC721 {
    using Strings for uint256;

    bytes32 public constant Manager = keccak256("Manager");
    bytes32 public constant AddPoints = keccak256("AddPoints");
    bytes32 public constant AddLevel = keccak256("AddLevel");

    uint256 constant SupplyCap = 5000;

    uint256 public levelCap = 0;
    uint256 totalSupply = 0;
    bool baseLevelSetted = false;

    /**
     * @dev points of token
     */
    mapping(uint256 => uint256) public pointsOf;
    /**
     * @dev level of token
     */
    mapping(uint256 => uint256) public levelOf;
    /**
     * @dev required points of level
     */
    mapping(uint256 => uint256) public requiredPointsOf;
    /**
     * @dev display level of token
     */
    mapping(uint256 => uint256) displayLevelOf;
    /**
     * @dev base URI of level
     */
    mapping(uint256 => string) baseUriOf;

    mapping(address => bool) isMinted;

    constructor(
        address owner,
        string memory baseUriOfLevelZero
    ) ERC721("Lustrade Club Passcard", "LCP") {
        _grantRole(Manager, owner);
        _setRoleAdmin(AddPoints, Manager);
        _setRoleAdmin(AddLevel, Manager);
        baseUriOf[0] = baseUriOfLevelZero;
    }

    function mint() external payable returns (uint256 tokenId) {
        require(totalSupply < SupplyCap, "LCP: all the tokens are minted");
        require(!isMinted[msg.sender], "LCP: address already minted");

        isMinted[msg.sender] = true;
        tokenId = ++totalSupply;
        _mint(msg.sender, tokenId);
    }

    function setDisplayLevel(uint256 tokenId, uint256 displayLevel) external {
        _setDisplayLevel(msg.sender, tokenId, displayLevel);
    }

    function setDisplayLevelFor(
        address tokenOwner,
        uint256 tokenId,
        uint256 displayLevel
    ) external {
        require(
            ERC721._isApprovedOrOwner(msg.sender, tokenId),
            "LCP: not owner or approved"
        );
        _setDisplayLevel(tokenOwner, tokenId, displayLevel);
    }

    function increasePoints(
        uint256 tokenId,
        uint256 addPoints,
        bool autoUpgrade
    ) external onlyRole(AddPoints) {
        ERC721._requireMinted(tokenId);
        require(addPoints > 0, "LCP: `addPoints` cannot be zero");

        uint256 points = pointsOf[tokenId];
        points += addPoints;
        pointsOf[tokenId] = points;
        if (!autoUpgrade) return;

        uint256 level = levelOf[tokenId];
        uint256 nextLevel = level + 1;
        if (nextLevel > levelCap) return;
        uint256 requiredPointsOfNextLevel = requiredPointsOf[nextLevel];
        if (points < requiredPointsOfNextLevel) return;

        levelOf[tokenId] = nextLevel;

        emit Upgrade(tokenId, nextLevel);
    }

    function addLevel(
        uint256 requiredPoints,
        string calldata levelBaseURI
    ) external onlyRole(AddLevel) {
        require(
            requiredPoints > requiredPointsOf[levelCap],
            "LCP: `requiredPoints` too less"
        );

        uint256 newLevel = levelCap + 1;
        requiredPointsOf[newLevel] = requiredPoints;
        baseUriOf[newLevel] = levelBaseURI;
        levelCap += 1;

        emit NewLevel(newLevel, requiredPoints);
    }

    function setBaseLevelOnce(
        string calldata baseLevelUri
    ) external onlyRole(Manager) {
        require(!baseLevelSetted, "LCP: already setted");
        baseUriOf[0] = baseLevelUri;
        baseLevelSetted = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint256 level = levelOf[tokenId];
        string memory baseURI = baseUriOf[level];
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ILusstradePasscard).interfaceId ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _setDisplayLevel(
        address tokenOwner,
        uint256 tokenId,
        uint256 displayLevel
    ) internal {
        require(ERC721.ownerOf(tokenId) == tokenOwner, "LCP: not token owner");
        require(displayLevel <= levelCap, "LCP: exceeds maximum level");
        require(levelOf[tokenId] >= displayLevel, "LCP: exceeds token level");

        displayLevelOf[tokenId] = displayLevel;

        emit UpdateDisplayLevel(tokenId, displayLevel);
    }
}
