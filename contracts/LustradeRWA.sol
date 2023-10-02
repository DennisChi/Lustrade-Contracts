// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./interfaces/ILustradeRWAErrors.sol";
import "./interfaces/ILustradeRWAEvents.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@chiru-labs/pbt/src/IPBT.sol";

contract LustradeRWA is
    ERC721URIStorage,
    Ownable,
    IPBT,
    ILustradeRWAErrors,
    ILustradeRWAEvents
{
    using ECDSA for bytes32;

    uint256 public MaxBlockhashValidWindow = 100;

    mapping(uint256 => bool) isStaking;
    mapping(uint256 => bool) isRedeeming;
    mapping(address => uint) tokenIdOfChipAddress;
    mapping(uint256 => address) chipAddressOfTokenId;
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
        address chipAddress,
        bytes calldata data
    ) external onlyOwner {
        uint256 tokenId = tokenSupplied + 1;
        tokenSupplied = tokenId;
        chipAddressOfTokenId[tokenId] = chipAddress;
        tokenIdOfChipAddress[chipAddress] = tokenId;
        _safeMint(to, tokenId, data);
        _setTokenURI(tokenId, tokenURI);
    }

    function batchMint(
        address[] calldata tos,
        string[] calldata tokenURIs,
        address[] calldata chipAddresses,
        bytes[] calldata datas
    ) external onlyOwner {
        uint256 leng = tos.length;
        if (
            leng != tokenURIs.length ||
            leng != datas.length ||
            leng != chipAddresses.length
        ) {
            revert ArrayLengthNotEqual(
                leng,
                tokenURIs.length,
                datas.length,
                chipAddresses.length
            );
        }
        uint256 tokenId = tokenSupplied;
        for (uint256 i = 0; i < leng; i++) {
            tokenId += 1;
            address to = tos[i];
            bytes calldata data = datas[i];
            string calldata tokenURI = tokenURIs[i];
            address chipAddress = chipAddresses[i];
            tokenIdOfChipAddress[chipAddress] = tokenId;
            chipAddressOfTokenId[tokenId] = chipAddress;
            _safeMint(to, tokenId, data);
            _setTokenURI(tokenId, tokenURI);
        }
        tokenSupplied = tokenId;
    }

    function transferTokenWithChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig,
        bool useSafeTransferFrom
    ) external {
        _transferTokenWithChip(
            signatureFromChip,
            blockNumberUsedInSig,
            useSafeTransferFrom
        );
    }

    function transferTokenWithChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        _transferTokenWithChip(signatureFromChip, blockNumberUsedInSig, false);
    }

    function tokenIdFor(address chipAddress) external view returns (uint256) {
        uint256 tokenId = tokenIdOfChipAddress[chipAddress];
        if (!_exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        return tokenId;
    }

    function isChipSignatureForToken(
        uint256 tokenId,
        bytes calldata payload,
        bytes calldata signature
    ) external view returns (bool) {
        if (!_exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        bytes32 signedHash = keccak256(payload).toEthSignedMessageHash();
        address recoveredAddress = signedHash.recover(signature);
        address chipAddress = chipAddressOfTokenId[tokenId];
        return chipAddress == recoveredAddress;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721, IERC721)
        notStaking(tokenId)
        notRedeeming(tokenId)
    {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        virtual
        override(ERC721, IERC721)
        notStaking(tokenId)
        notRedeeming(tokenId)
    {
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721, IERC721)
        notStaking(tokenId)
        notRedeeming(tokenId)
    {
        ERC721.transferFrom(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) || interfaceId == 0x4901df9f;
    }

    function _transferTokenWithChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig,
        bool useSafeTransferFrom
    ) internal {
        if (block.number <= blockNumberUsedInSig) {
            revert InvalidBlockNumber();
        }
        unchecked {
            if (block.number - blockNumberUsedInSig > MaxBlockhashValidWindow) {
                revert BlockNumberTooOld();
            }
        }

        bytes32 blockHash = blockhash(blockNumberUsedInSig);
        bytes32 signedHash = keccak256(abi.encodePacked(msg.sender, blockHash))
            .toEthSignedMessageHash();
        address chipAddress = signedHash.recover(signatureFromChip);

        uint256 tokenId = tokenIdOfChipAddress[chipAddress];
        if (!_exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        if (!isStaking[tokenId]) {
            revert IsNotStaking(tokenId);
        }
        if (isRedeeming[tokenId]) {
            revert IsRedeeming(tokenId);
        }

        if (useSafeTransferFrom) {
            _safeTransfer(ownerOf(tokenId), _msgSender(), tokenId, "");
        } else {
            _transfer(ownerOf(tokenId), _msgSender(), tokenId);
        }
    }
}
