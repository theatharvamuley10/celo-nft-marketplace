// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFT-Marketplace.sol";
import {DeployNFTMarketplace} from "../script/DeployNFTMarketplace.s.sol";

contract TestNFTMarketplace is Test {
    NFTMarketplace nftMarketplace;

    function setup() public {
        DeployNFTMarketplace deploynftMarketplace = new DeployNFTMarketplace();
        nftMarketplace = deploynftMarketplace.run();
    }

    function test_createListing() public {
        
    }
}
