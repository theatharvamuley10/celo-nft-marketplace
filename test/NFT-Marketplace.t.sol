// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFT-Marketplace.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CreateMockNFT} from "../src/mocks/MockNFT.sol";

// Mock ERC721 Token

contract TestNFTMarketplace is Test {
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
        mockNFT.mint(seller, 1, "mockNFT1");
        // mockNFT.mint(seller, 2, "mockNFT2");
        // mockNFT.mint(seller, 3, "mockNFT3");
    }

    ////////////////////////////////////////////////////
    ///////////Testing createListing////////////////////
    ////////////////////////////////////////////////////

    // Create Listing Successful
    function test_CreateListing_Successful() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 1);
        nftMarketplace.createListing(mockNFTAddress, 1, 1e18);
        vm.stopPrank();
        (uint price1, address nft_owner1) = nftMarketplace.listings(
            mockNFTAddress,
            1
        );
        assertEq(price1, 1e18);
        assertEq(nft_owner1, seller);
    }

    // Create Listing Reverts as Price is Invalid (<=0)
    function test_CreateListing_InvalidPrice() public {
        vm.startPrank(seller);
        mockNFT.approve(address(this), 0);
        vm.expectRevert();
        nftMarketplace.createListing(mockNFTAddress, 0, 0);
    }

    // Create Listing Reverts as NFT is already Listed
    function test_CreateListing_ListingAlreadyExists() public {
        vm.startPrank(seller);
        mockNFT.approve(address(nftMarketplace), 1);
        nftMarketplace.createListing(mockNFTAddress, 1, 1e18);
        vm.expectRevert();
        nftMarketplace.createListing(mockNFTAddress, 1, 1e18);
        vm.stopPrank();
    }

    // Create Listing Reverts as the person listing the NFT is not the owner of the nft

    function test_CreateListing_NotTheOwner() public {
        vm.prank(seller);
        mockNFT.approve(address(nftMarketplace), 1);
        vm.expectRevert();
        nftMarketplace.createListing(mockNFTAddress, 1, 1e18);
    }

    // Create Listing Reverts as Nft Marketplace isn't approved to control the nft
    function test_CreateListing_NftMarketplaceIsNotApproved() public {
        vm.prank(seller);
        vm.expectRevert();
        nftMarketplace.createListing(mockNFTAddress, 1, 1e18);
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
    function test_UpdateListing_Successfull() public {}
}
