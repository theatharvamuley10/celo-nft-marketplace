// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }

    // Contract Address -> (Token ID -> Listing Data)
    mapping(address => mapping(uint => Listing)) public listings;

    // MODIFIERS

    modifier isNFTOwner(address nftAddress, uint tokenId) {
        IERC721 nftContract = IERC721(nftAddress);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "MRKT: You're not the owner of this NFT"
        );
        _;
    } // IERC721 contracts have the function ownerOf(tokenID) which when called returns the
    // address of the owner of the nft with that token Id from the collection

    modifier validPrice(uint256 price) {
        require(price > 0, "MRKT: Price must be > 0");
        _;
    }

    modifier isNotListed(address nftAddress, uint tokenId) {
        require(
            listings[nftAddress][tokenId].price == 0,
            "MRKT: Already Listed"
        );
        _;
    }

    modifier isListed(address nftAddress, uint tokenId) {
        require(listings[nftAddress][tokenId].price > 0, "MRKT: Is not Listed");
        _;
    }

    // EVENTS

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

    // FUNCTIONS

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

        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this),
            "MRKT : No approval for nft"
        );

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

        // 1.
        require(
            msg.value == listings[nftAddress][tokenId].price,
            "Insufficient ETH transfer"
        );

        // 2.
        Listing memory listing = listings[nftAddress][tokenId];

        // 3.
        address payable sellerPayable = payable(listing.seller);
        (bool sent, ) = sellerPayable.call{value: msg.value}("");
        require(sent, "Transaction failed");

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
