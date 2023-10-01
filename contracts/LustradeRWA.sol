// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./interfaces/ILustradeRWAErrors.sol";
import "./interfaces/ILustradeRWAEvents.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract LustradeRWA is
    ERC721URIStorage,
    Ownable,
    ILustradeRWAErrors,
    ILustradeRWAEvents
{
    mapping(uint256 => bool) isStaking;
    mapping(uint256 => bool) isRedeeming;
    uint256 tokenSupplied = 0;

    constructor(address owner) ERC721("Lustrade RWA NFT", "LRN") {
        _transferOwnership(owner);
    }

    modifier onlyApproverOrOwner(address from, uint256 tokenId) {
        if (!_isApprovedOrOwner(from, tokenId)) {
            revert NotApprovedOrOwner(msg.sender, tokenId);
        }
        _;
    }

    modifier onlyStaking(uint256 tokenId) {
        if (!isStaking[tokenId]) {
            revert IsNotStaking(tokenId);
        }
        _;
    }

    modifier onlyRedeeming(uint256 tokenId) {
        if (!isRedeeming[tokenId]) {
            revert IsNotRedeeming(tokenId);
        }
        _;
    }

    modifier notStaking(uint256 tokenId) {
        if (isStaking[tokenId]) {
            revert IsStaking(tokenId);
        }
        _;
    }

    modifier notRedeeming(uint256 tokenId) {
        if (isRedeeming[tokenId]) {
            revert IsRedeeming(tokenId);
        }
        _;
    }

    function stake(
        address from,
        uint256 tokenId
    )
        external
        onlyApproverOrOwner(from, tokenId)
        notStaking(tokenId)
        notRedeeming(tokenId)
    {
        isStaking[tokenId] = true;
        emit Stake(tokenId);
    }

    function redeem(
        address from,
        uint256 tokenId
    )
        external
        onlyApproverOrOwner(from, tokenId)
        onlyStaking(tokenId)
        notRedeeming(tokenId)
    {
        isStaking[tokenId] = false;
        isRedeeming[tokenId] = true;
        emit Redeem(tokenId);
    }

    function release(
        uint256 tokenId
    ) external onlyOwner onlyRedeeming(tokenId) {
        isRedeeming[tokenId] = false;
        emit Release(tokenId);
    }

    function mint(
        address to,
        string calldata tokenURI,
        bytes calldata data
    ) external onlyOwner {
        uint256 tokenId = tokenSupplied + 1;
        tokenSupplied = tokenId;
        _safeMint(to, tokenId, data);
        _setTokenURI(tokenId, tokenURI);
    }

    function batchMint(
        address[] calldata tos,
        string[] calldata tokenURIs,
        bytes[] calldata datas
    ) external onlyOwner {
        uint256 leng = tos.length;
        if (leng != tokenURIs.length || leng != datas.length) {
            revert ArrayLengthNotEqual(leng, tokenURIs.length, datas.length);
        }
        uint256 tokenId = tokenSupplied;
        for (uint256 i = 0; i < leng; i++) {
            tokenId += 1;
            address to = tos[i];
            bytes calldata data = datas[i];
            string calldata tokenURI = tokenURIs[i];
            _safeMint(to, tokenId, data);
            _setTokenURI(tokenId, tokenURI);
        }
        tokenSupplied = tokenId;
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId,
        uint256
    ) internal view override notStaking(tokenId) notRedeeming(tokenId) {}
}
