// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

error StakeS39Token__NotOwner();
error StakeS39Token__SelectCorrectPlan(uint256 planA, uint256 planB);

contract StakeS39Token is Ownable, IERC721Receiver {
    struct NFTDetails {
        address owner;
        uint256 tokenId;
        uint256 stakedFrom;
        uint256 plan;
    }

    IERC721 private immutable i_erc721helper;
    mapping(uint256 => NFTDetails) public s_nftDetails;

    event NFTStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed timeStamp,
        uint256 plan
    );

    event NFTUnStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed timeStamp
    );

    modifier isOwner(uint256 tokenId, address spender) {
        address owner = i_erc721helper.ownerOf(tokenId);
        if (spender != owner) {
            revert StakeS39Token__NotOwner();
        }
        _;
    }

    constructor(address _collectionAddr) {
        i_erc721helper = IERC721(_collectionAddr);
    }

    /////////////////////////Main Functions///////////////////////////////////

    function stakeNFT(uint256 plan, uint256 _tokenId)
        external
        isOwner(_tokenId, _msgSender())
    {
        i_erc721helper.safeTransferFrom(_msgSender(), address(this), _tokenId);
        if (plan == 1) {
            s_nftDetails[_tokenId] = NFTDetails(
                _msgSender(),
                _tokenId,
                block.timestamp,
                plan
            );
        } else if (plan == 2) {
            s_nftDetails[_tokenId] = NFTDetails(
                _msgSender(),
                _tokenId,
                block.timestamp,
                plan
            );
        } else {
            revert StakeS39Token__SelectCorrectPlan(1, 2);
        }
        emit NFTStaked(_msgSender(), _tokenId, block.timestamp, plan);
    }

    function unStakeNFT(uint256 _tokenId) external {
        NFTDetails memory details = s_nftDetails[_tokenId];
        if (details.owner != _msgSender()) {
            revert StakeS39Token__NotOwner();
        }
        delete (s_nftDetails[_tokenId]);
        i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
        emit NFTUnStaked(_msgSender(), _tokenId, block.timestamp);
    }

    /////////////////////////View Functions///////////////////////////////////

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
