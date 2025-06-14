// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

///////////////////////////////////////////////////////
////////////////////// Imports ////////////////////////
///////////////////////////////////////////////////////

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title NFT Marketplace
/// @author Atharva Muley
/// @notice Users can list their nft and other people can buy them.

contract NFTMarketplace {
    ///////////////////////////////////////////////////////
    //////////////////// Custom Errors ////////////////////
    ///////////////////////////////////////////////////////

    error NFTMarketplace_NotTheOwner();
    error NFTMarketplace_Invalid_ListingPrice();
    error NFTMarketplace_NFT_AlreadyListed();
    error NFTMarketplace_NFT_IsNotListed();
    error NFTMarketplace_Operator_NotApproved_ToControlThisAsset();
    error NFTMarketplace_Incorrect_Amount_Sent();
    error NFTMarketplace_PurchaseFailed();

    ///////////////////////////////////////////////////////
    ////////////////// Type Declaration ///////////////////
    ///////////////////////////////////////////////////////

    struct Listing {
        uint256 price;
        address seller;
    }

    ///////////////////////////////////////////////////////
    ////////////////// Storage Variables //////////////////
    ///////////////////////////////////////////////////////

    mapping(address => mapping(uint => Listing)) public listings; // Contract Address -> (Token ID -> Listing Data)

    ///////////////////////////////////////////////////////
    ////////////////////// Modifiers //////////////////////
    ///////////////////////////////////////////////////////

    modifier isNFTOwner(address nftAddress, uint tokenId) {
        IERC721 nftContract = IERC721(nftAddress);
        if (nftContract.ownerOf(tokenId) != msg.sender) {
            revert NFTMarketplace_NotTheOwner();
        }
        _;
    }

    modifier validPrice(uint256 price) {
        if (price <= 0) {
            revert NFTMarketplace_Invalid_ListingPrice();
        }
        _;
    }

    modifier isNotListed(address nftAddress, uint tokenId) {
        if (listings[nftAddress][tokenId].price > 0) {
            revert NFTMarketplace_NFT_AlreadyListed();
        }
        _;
    }

    modifier isListed(address nftAddress, uint tokenId) {
        if (listings[nftAddress][tokenId].price <= 0) {
            revert NFTMarketplace_NFT_IsNotListed();
        }
        _;
    }

    ///////////////////////////////////////////////////////
    ////////////////////// Events /////////////////////////
    ///////////////////////////////////////////////////////

    event ListingCreated(
        address nftAddress,
        uint tokenId,
        uint price,
        address seller
    );

    event ListingCancelled(address nftAddress, uint tokenId, address seller);

    event ListingUpdated(
        address nftAddress,
        uint tokenId,
        uint newPrice,
        address seller
    );

    event ListingPurchased(
        address nftAddress,
        uint tokenId,
        uint price,
        address seller,
        address buyer
    );

    ///////////////////////////////////////////////////////
    ///////////////////// FUNCTIONS ///////////////////////
    ///////////////////////////////////////////////////////

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
            revert NFTMarketplace_Operator_NotApproved_ToControlThisAsset();
        }
        // Add the listing to our mapping
        listings[nftAddress][tokenId] = Listing({
            price: price,
            seller: msg.sender
        });
        // logging this event
        emit ListingCreated(nftAddress, tokenId, price, msg.sender);
    }

    function cancelListing(
        address nftAddress,
        uint tokenId
    ) external isNFTOwner(nftAddress, tokenId) isListed(nftAddress, tokenId) {
        delete listings[nftAddress][tokenId];
        // logging this event
        emit ListingCancelled(nftAddress, tokenId, msg.sender);
    }

    function updateListing(
        address nftAddress,
        uint tokenId,
        uint newPrice
    )
        external
        isNFTOwner(nftAddress, tokenId)
        validPrice(newPrice)
        isListed(nftAddress, tokenId)
    {
        listings[nftAddress][tokenId].price = newPrice;
        // logging this event
        emit ListingUpdated(nftAddress, tokenId, newPrice, msg.sender);
    }

    function purchaseListing(
        address nftAddress,
        uint tokenId
    ) external payable isListed(nftAddress, tokenId) {
        // here we need following 5 operations to make sure a successful purchase
        // 1. Buyer must send the right amount of ETH
        // 2. Load the listing in a local copy
        // 3. Transfer ETH from buyer to seller
        // 4. Transfer listing ownership from seller to buyer
        // 5. Delete Listing from our catalogue
        /// 1.
        if (msg.value != listings[nftAddress][tokenId].price) {
            revert NFTMarketplace_Incorrect_Amount_Sent();
        }
        // 2.
        Listing memory listing = listings[nftAddress][tokenId];
        // 3.
        address payable sellerPayable = payable(listing.seller);
        (bool sent, ) = sellerPayable.call{value: msg.value}("");
        if (!sent) {
            revert NFTMarketplace_PurchaseFailed();
        }
        // 4.
        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );
        // 5.
        delete listings[nftAddress][tokenId];
        // logging this event
        emit ListingPurchased(
            nftAddress,
            tokenId,
            listing.price,
            listing.seller,
            msg.sender
        );
    }
}
