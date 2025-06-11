// scripts are never deployed

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFT-Marketplace.sol";

contract DeployNFTMarketplace is Script {
    NFTMarketplace public nftMarketplace;

    function setUp() public {}

    function run() public returns (NFTMarketplace) {
        vm.startBroadcast();

        nftMarketplace = new NFTMarketplace();

        vm.stopBroadcast();

        return nftMarketplace;
    }
}
