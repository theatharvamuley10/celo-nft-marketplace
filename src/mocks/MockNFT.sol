// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreateMockNFT is ERC721URIStorage, Ownable {
    constructor() ERC721("Hooded Monkey", "HM") Ownable(msg.sender) {}

    function mint(address to, uint256 tokenId, string calldata uri) external {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
