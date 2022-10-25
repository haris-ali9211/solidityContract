// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./MyToken.sol";

error NFT__DontHaveEnoughTokensToMintNFT();
error NFT__YouDidntProvideApprovalOFTokensForNFTMinting();
error NFT__TransferFailed();
error NFT__NFTMintingLimitReached();
contract NFT is ERC721URIStorage {
////////////////////////////////Struct//////////////////////////////////////////
struct NFTDetails {
    uint256 tokenid;
    address owner;
}
    ////////////////////////////State Variables//////////////////////////////////
    
    uint256 private s_tokenCounter;
      MyToken private immutable token;
      uint256 private constant VALUE = 5000000000;

    /////////////////////////mapping////////////////////////////////////
    mapping(uint256 => NFTDetails) private details;

    //////////////////////////Events////////////////////////////////////
    event NFTMinted( address indexed owner, address indexed nftAddress, uint256 indexed tokenId);
    constructor(address _token) ERC721("My NFT", "MN") {
        s_tokenCounter = 0;
        token = MyToken(_token);
    }

///////////////////////Main Function////////////////////////////////////

    function mintNft(string memory _tokenURI) public returns (uint256) {

        if(s_tokenCounter > 2) {
            revert NFT__NFTMintingLimitReached();
        }
    
        if(token.balanceOf(msg.sender) < VALUE){
            revert NFT__DontHaveEnoughTokensToMintNFT(); 
        }
        if(token.allowance(msg.sender, address(this)) < VALUE) {
            revert NFT__YouDidntProvideApprovalOFTokensForNFTMinting();
        }
   
        (bool success) = token.transferFrom(msg.sender, address(this), VALUE);

        if(!success) {
            revert NFT__TransferFailed();
        }

        _safeMint(msg.sender, s_tokenCounter);
        _setTokenURI(s_tokenCounter, _tokenURI);
        details[s_tokenCounter] = NFTDetails(s_tokenCounter,msg.sender);
        emit NFTMinted(msg.sender, address(this), s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
        return s_tokenCounter;
    }
///////////////////////Getter Functions////////////////////////////////////

 function getAllNFTs() public view returns (NFTDetails[] memory) {
       
        NFTDetails[] memory nfts = new NFTDetails[](s_tokenCounter);

        for(uint i=0;i<s_tokenCounter;i++)
        {
            NFTDetails storage currentItem = details[i];
            nfts[i] = currentItem;
        }
        return nfts;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
    function mintingFees() public pure returns(uint256) {
        return VALUE;
    }

}