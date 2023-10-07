// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@chiru-labs/pbt/src/IPBT.sol";

interface ILustradeRWA is IERC721, IPBT {
    event Stake(uint256 indexed tokenId);
    event Redeem(uint256 indexed tokenId);
    event Release(uint256 indexed tokenId);

    /**
     * Stake token to retrive the asset.
     * @param from owner of token
     * @param tokenId ID of token
     */
    function stake(address from, uint256 tokenId) external;

    /**
     * Return the asset to redeem asset.
     * @param from owner of token
     * @param tokenId ID of token
     */
    function redeem(address from, uint256 tokenId) external;

    /**
     * Release the token so it can be redeemed.
     * @param tokenId ID of token
     */
    function release(uint256 tokenId) external;

    /**
     * Mint a token for asset
     * @param to address to send token
     * @param tokenURI the URI of token
     * @param chipAddress the chip address of this asset
     * @param data data used for mint
     */
    function mint(
        address to,
        string calldata tokenURI,
        address chipAddress,
        bytes calldata data
    ) external;

    /**
     * Batch mint.
     * @param tos array of address to send tokens
     * @param tokenURIs array of token URI
     * @param chipAddresses array of chip address
     * @param datas array of data used for mint
     */
    function batchMint(
        address[] calldata tos,
        string[] calldata tokenURIs,
        address[] calldata chipAddresses,
        bytes[] calldata datas
    ) external;
}
