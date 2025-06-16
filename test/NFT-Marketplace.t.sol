// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFT-Marketplace.sol";
import {CreateMockNFT} from "../src/mocks/MockNFT.sol";
import {MockTransferFailed} from "./utils/MockTransferFailed.sol";

// Mock ERC721 Token

contract TestNFTMarketplace is Test {
    error NFTMarketplace_NotTheOwner();
    error NFTMarketplace_Invalid_ListingPrice();
    error NFTMarketplace_NFT_AlreadyListed();
    error NFTMarketplace_NFT_IsNotListed();
    error NFTMarketplace_NotApproved_ToControlThisAsset();
    error NFTMarketplace_Incorrect_Amount_Sent();
    error NFTMarketplace_PurchaseFailed_AmountNotSentToTheSeller();

    NFTMarketplace public nftMarketplace;
    CreateMockNFT public mockNFT;

    address payable public seller = payable(address(1));
    address payable public buyer = payable(address(2));
    address payable mockNFTAddress;

    function setUp() public {
        nftMarketplace = new NFTMarketplace();
        vm.prank(seller);
        mockNFT = new CreateMockNFT();
        mockNFTAddress = payable(address(mockNFT));

        vm.deal(seller, 10e18);
        vm.deal(buyer, 10e18);

        mockNFT.mint(seller, 0, "mockNFT0");
        // mockNFT.mint(seller, 1, "mockNFT1");
        // mockNFT.mint(seller, 2, "mockNFT2");
        // mockNFT.mint(seller, 3, "mockNFT3");
    }

    ////////////////////////////////////////////////////
    ///////////Testing createListing////////////////////
    ////////////////////////////////////////////////////

    // Create Listing Successful
    function test_CreateListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.stopPrank();
        (uint price0, address nft_owner0) = nftMarketplace.listings(
            mockNFTAddress,
            0
        );
        assertEq(price0, 1e18);
        assertEq(nft_owner0, seller);
    }

    // Create Listing Reverts as Price is Invalid (<=0)
    function test_CreateListing_InvalidPrice() public {
        vm.startPrank(seller);
        mockNFT.approve(address(this), 0);
        vm.expectRevert(NFTMarketplace_Invalid_ListingPrice.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 0);
    }

    // Create Listing Reverts as NFT is already Listed
    function test_CreateListing_ListingAlreadyExists() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.expectRevert(NFTMarketplace_NFT_AlreadyListed.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.stopPrank();
    }

    // Create Listing Reverts as the person listing the NFT is not the owner of the nft

    function test_CreateListing_NotTheOwner() public {
        vm.prank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        vm.expectRevert(NFTMarketplace_NotTheOwner.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
    }

    // Create Listing Reverts as Nft Marketplace isn't approved to control the nft
    function test_CreateListing_NftMarketplaceIsNotApproved() public {
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace_NotApproved_ToControlThisAsset.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
    }

    ////////////////////////////////////////////////////
    ///////////Testing cancelListing////////////////////
    ////////////////////////////////////////////////////

    // Cancel Listing Successful

    function test_CancelListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        nftMarketplace.cancelListing(mockNFTAddress, 0);
        (uint256 price, address nft_owner) = nftMarketplace.listings(
            mockNFTAddress,
            0
        );
        assertEq(price, 0);
        assertEq(nft_owner, address(0));
    }

    ////////////////////////////////////////////////////
    ///////////Testing updateListing////////////////////
    ////////////////////////////////////////////////////

    // Update Listing Successful
    function test_UpdateListing_Successfull() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        nftMarketplace.updateListing(mockNFTAddress, 0, 2e18);
        vm.stopPrank();
    }

    // Update Listing Reverts as Listing Doesn't Exist
    function test_UpdateListing_NoSuchListing() public {
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace_NFT_IsNotListed.selector);
        nftMarketplace.updateListing(mockNFTAddress, 0, 2e18);
    }

    ////////////////////////////////////////////////////
    ///////////Testing updateListing////////////////////
    ////////////////////////////////////////////////////

    // Purchase Listing Successful

    function test_PurchaseListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1.5e18);
        vm.stopPrank();

        vm.prank(buyer);
        nftMarketplace.purchaseListing{value: 1.5e18}(mockNFTAddress, 0);
    }

    // Purcahse Listing Reverts as the money sent by the buyer is not equal to the nft price
    function test_PurchaseListing_MoneySentIsNotEqualToNFTPrice() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1.5e18);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace_Incorrect_Amount_Sent.selector);
        nftMarketplace.purchaseListing{value: 1e18}(mockNFTAddress, 0);
    }

    // Purchase Listing Reverts as money wasn't sent to the seller successfully
    function test_PurchaseListing_MoneyTransactionFailed() public {
        MockTransferFailed sellerRevert = new MockTransferFailed();
        mockNFT.mint(address(sellerRevert), 1, "mockNFT1");
        vm.startPrank(address(sellerRevert));
        mockNFT.approve(address(nftMarketplace), 1);
        nftMarketplace.createListing(mockNFTAddress, 1, 1.5e18);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert(
            NFTMarketplace_PurchaseFailed_AmountNotSentToTheSeller.selector
        );
        nftMarketplace.purchaseListing{value: 1.5e18}(mockNFTAddress, 1);
    }
}
