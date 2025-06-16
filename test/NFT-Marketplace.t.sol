// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFT-Marketplace.sol";
import {CreateMockNFT} from "../src/mocks/MockNFT.sol";
import {MockTransferFailed} from "./utils/MockTransferFailed.sol";
import {DeployNFTMarketplace} from "../script/DeployNFTMarketplace.s.sol";

/**
 * @title NFT Marketplace Test Suite
 * @notice Comprehensive test coverage for NFT Marketplace functionality
 */
contract TestNFTMarketplace is Test {
    //////////////// Custom Errors ////////////////
    error NFTMarketplace_NotTheOwner();
    error NFTMarketplace_Invalid_ListingPrice();
    error NFTMarketplace_NFT_AlreadyListed();
    error NFTMarketplace_NFT_IsNotListed();
    error NFTMarketplace_NotApproved_ToControlThisAsset();
    error NFTMarketplace_Incorrect_Amount_Sent();
    error NFTMarketplace_PurchaseFailed_AmountNotSentToTheSeller();

    //////////////// Test Contracts ///////////////
    NFTMarketplace public nftMarketplace;
    CreateMockNFT public mockNFT;
    address payable public seller = payable(address(1));
    address payable public buyer = payable(address(2));
    address payable mockNFTAddress;

    //////////////// Setup ////////////////////////
    function setUp() public {
        DeployNFTMarketplace deployer = new DeployNFTMarketplace();
        nftMarketplace = deployer.run();

        vm.prank(seller);
        mockNFT = new CreateMockNFT();
        mockNFTAddress = payable(address(mockNFT));

        vm.deal(seller, 10e18);
        vm.deal(buyer, 10e18);

        mockNFT.mint(seller, 0, "mockNFT0");
    }

    ////////////////////////////////////////////////////
    /////////// Testing createListing ///////////////////
    ////////////////////////////////////////////////////

    // Successful NFT listing creation
    function test_CreateListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.stopPrank();

        (uint256 price, address owner) = nftMarketplace.listings(
            mockNFTAddress,
            0
        );
        assertEq(price, 1e18, "Incorrect listing price");
        assertEq(owner, seller, "Incorrect seller address");
    }

    // Reverts if price is invalid (<= 0)
    function test_CreateListing_InvalidPrice() public {
        vm.startPrank(seller);
        mockNFT.approve(address(this), 0);
        vm.expectRevert(NFTMarketplace_Invalid_ListingPrice.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 0);
    }

    // Reverts if NFT is already listed
    function test_CreateListing_ListingAlreadyExists() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.expectRevert(NFTMarketplace_NFT_AlreadyListed.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        vm.stopPrank();
    }

    // Reverts if caller is not the owner
    function test_CreateListing_NotTheOwner() public {
        vm.prank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        vm.expectRevert(NFTMarketplace_NotTheOwner.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
    }

    // Reverts if marketplace is not approved
    function test_CreateListing_NftMarketplaceIsNotApproved() public {
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace_NotApproved_ToControlThisAsset.selector);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
    }

    ////////////////////////////////////////////////////
    /////////// Testing cancelListing ///////////////////
    ////////////////////////////////////////////////////

    // Successful listing cancellation
    function test_CancelListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        nftMarketplace.cancelListing(mockNFTAddress, 0);

        (uint256 price, address owner) = nftMarketplace.listings(
            mockNFTAddress,
            0
        );
        assertEq(price, 0, "Listing price not reset");
        assertEq(owner, address(0), "Seller address not cleared");
    }

    ////////////////////////////////////////////////////
    /////////// Testing updateListing ///////////////////
    ////////////////////////////////////////////////////

    // Successful price update
    function test_UpdateListing_Successfull() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1e18);
        nftMarketplace.updateListing(mockNFTAddress, 0, 2e18);
        vm.stopPrank();
    }

    // Reverts if listing does not exist
    function test_UpdateListing_NoSuchListing() public {
        vm.prank(seller);
        vm.expectRevert(NFTMarketplace_NFT_IsNotListed.selector);
        nftMarketplace.updateListing(mockNFTAddress, 0, 2e18);
    }

    ////////////////////////////////////////////////////
    /////////// Testing purchaseListing /////////////////
    ////////////////////////////////////////////////////

    // Successful NFT purchase
    function test_PurchaseListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1.5e18);
        vm.stopPrank();

        vm.prank(buyer);
        nftMarketplace.purchaseListing{value: 1.5e18}(mockNFTAddress, 0);
    }

    // Reverts if payment is not equal to price
    function test_PurchaseListing_MoneySentIsNotEqualToNFTPrice() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 0);
        nftMarketplace.createListing(mockNFTAddress, 0, 1.5e18);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace_Incorrect_Amount_Sent.selector);
        nftMarketplace.purchaseListing{value: 1e18}(mockNFTAddress, 0);
    }

    // Reverts if payment transfer to seller fails
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

    // Reverts if NFT is not listed
    function test_PurchaseListing_NFTNotListed() public {
        vm.prank(buyer);
        vm.expectRevert(NFTMarketplace_NFT_IsNotListed.selector);
        nftMarketplace.purchaseListing{value: 1e18}(mockNFTAddress, 0);
    }
}
