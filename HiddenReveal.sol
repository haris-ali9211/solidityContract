// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

error URIQueryForNonexistentToken();

contract HiddenReveal is ERC721Enumerable, Ownable {
    string private _baseTokenURI;

    bool public revealed = false;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory metadataPointerId = !revealed ? 'unrevealed' : _toString(tokenId);
        string memory result = string(abi.encodePacked(baseURI, metadataPointerId, '.json'));

        return bytes(baseURI).length != 0 ? result : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }
}
