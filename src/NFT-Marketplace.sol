// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

////////////////////////////////////////////////////////
/////////////////////// IMPORTS ////////////////////////
////////////////////////////////////////////////////////

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFT Marketplace
 * @author Atharva Muley
 * @notice Decentralized marketplace for ERC721 token trading
 * @dev Implementts ERC721 interface and mock nft creation.
 * @dev Implements core NFT listing/purchasing functionality with safety checks.
 */
contract NFTMarketplace {
    ////////////////////////////////////////////////////////
    ////////////////////// CUSTOM ERRORS ///////////////////
    ////////////////////////////////////////////////////////

    error NFTMarketplace_NotTheOwner();
    error NFTMarketplace_Invalid_ListingPrice();
    error NFTMarketplace_NFT_AlreadyListed();
    error NFTMarketplace_NFT_IsNotListed();
    error NFTMarketplace_NotApproved_ToControlThisAsset();
    error NFTMarketplace_Incorrect_Amount_Sent();
    error NFTMarketplace_PurchaseFailed_AmountNotSentToTheSeller();

    ////////////////////////////////////////////////////////
    //////////////////// TYPE DECLARATIONS /////////////////
    ////////////////////////////////////////////////////////

    /// @dev Stores listing price and seller address
    struct Listing {
        uint256 price;
        address seller;
    }

    ////////////////////////////////////////////////////////
    //////////////////// STATE VARIABLES ///////////////////
    ////////////////////////////////////////////////////////

    /// @dev NFT contract address => Token ID => Listing details
    mapping(address => mapping(uint256 => Listing)) public listings;

    ////////////////////////////////////////////////////////
    //////////////////////// EVENTS ////////////////////////
    ////////////////////////////////////////////////////////

    event ListingCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller
    );

    event ListingCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );

    event ListingUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 newPrice,
        address indexed seller
    );

    event ListingPurchased(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address indexed buyer
    );

    ////////////////////////////////////////////////////////
    ////////////////////// MODIFIERS ///////////////////////
    ////////////////////////////////////////////////////////

    /// @dev Verifies caller owns the specified NFT
    modifier isNFTOwner(address nftAddress, uint256 tokenId) {
        if (IERC721(nftAddress).ownerOf(tokenId) != msg.sender) {
            revert NFTMarketplace_NotTheOwner();
        }
        _;
    }

    /// @dev Ensures listing price is greater than zero
    modifier validPrice(uint256 price) {
        if (price == 0) revert NFTMarketplace_Invalid_ListingPrice();
        _;
    }

    /// @dev Checks if NFT is not already listed
    modifier isNotListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].price != 0) {
            revert NFTMarketplace_NFT_AlreadyListed();
        }
        _;
    }

    /// @dev Checks if NFT is currently listed
    modifier isListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].price == 0) {
            revert NFTMarketplace_NFT_IsNotListed();
        }
        _;
    }

    ////////////////////////////////////////////////////////
    ////////////////// EXTERNAL FUNCTIONS //////////////////
    ////////////////////////////////////////////////////////

    /**
     * @notice List an NFT for sale
     * @param nftAddress Address of NFT contract
     * @param tokenId ID of NFT to list
     * @param price Listing price in wei
     */
    function createListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        validPrice(price)
        isNotListed(nftAddress, tokenId)
        isNFTOwner(nftAddress, tokenId)
    {
        IERC721 nftContract = IERC721(nftAddress);
        if (
            !(nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this))
        ) {
            revert NFTMarketplace_NotApproved_ToControlThisAsset();
        }

        listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ListingCreated(nftAddress, tokenId, price, msg.sender);
    }

    /**
     * @notice Cancel an existing NFT listing
     * @param nftAddress Address of NFT contract
     * @param tokenId ID of NFT to unlist
     */
    function cancelListing(
        address nftAddress,
        uint256 tokenId
    ) external isNFTOwner(nftAddress, tokenId) isListed(nftAddress, tokenId) {
        delete listings[nftAddress][tokenId];
        emit ListingCancelled(nftAddress, tokenId, msg.sender);
    }

    /**
     * @notice Update price of an existing listing
     * @param nftAddress Address of NFT contract
     * @param tokenId ID of NFT to update
     * @param newPrice New listing price in wei
     */
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isNFTOwner(nftAddress, tokenId)
        validPrice(newPrice)
        isListed(nftAddress, tokenId)
    {
        listings[nftAddress][tokenId].price = newPrice;
        emit ListingUpdated(nftAddress, tokenId, newPrice, msg.sender);
    }

    /**
     * @notice Purchase a listed NFT
     * @param nftAddress Address of NFT contract
     * @param tokenId ID of NFT to purchase
     */
    function purchaseListing(
        address nftAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) {
        // Validate payment amount
        if (msg.value != listings[nftAddress][tokenId].price) {
            revert NFTMarketplace_Incorrect_Amount_Sent();
        }

        // Cache listing details
        Listing memory listing = listings[nftAddress][tokenId];

        // Transfer funds to seller
        (bool success, ) = payable(listing.seller).call{value: msg.value}("");
        if (!success)
            revert NFTMarketplace_PurchaseFailed_AmountNotSentToTheSeller();

        // Transfer NFT ownership
        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        // Remove listing
        delete listings[nftAddress][tokenId];

        emit ListingPurchased(
            nftAddress,
            tokenId,
            listing.price,
            listing.seller,
            msg.sender
        );
    }
}
