//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error StakeNFT__NotOwner();
error StakeNFT__NFTStakingLimitReached();
error StakeNFT__TokenIdNotFound(uint256 _tokenId);
error StakeNFT__StakingPeriodNotOverYet(uint256 _endTime);

contract StakeNFT is IERC721Receiver, Ownable {
    struct NFTDetails {
        uint256 tokenId;
        uint256 stakingStartTime;
        uint256 stakingEndTime;
        bool isStaked;
    }

    IERC721 private erc721Helper;

    mapping(uint256 => uint256) private nft_counter;
    mapping(address => mapping(uint256 => NFTDetails)) public nft_details;

    event NFTStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed timeStamp,
        uint256 plan
    );
    event NFTUnStaked(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed timeStamp
    );

    constructor(address _nftAddress) {
        erc721Helper = IERC721(_nftAddress);
    }

    function stakeNFT(uint256 _tokenId, uint256 _plan) external {
        require(_plan > 0 && _plan < 4, "Please choose correct plan");
        address owner = erc721Helper.ownerOf(_tokenId);
        if (owner != _msgSender()) revert StakeNFT__NotOwner();
        uint256 count = nft_counter[_tokenId];
        if (count > 1) revert StakeNFT__NFTStakingLimitReached();
        if (_plan == 1) {
            nft_details[_msgSender()][_tokenId] = NFTDetails(
                _tokenId,
                block.timestamp,
                (block.timestamp + 1 minutes),
                true
            );
        } else if (_plan == 2) {
            nft_details[_msgSender()][_tokenId] = NFTDetails(
                _tokenId,
                block.timestamp,
                (block.timestamp + 2 minutes),
                true
            );
        } else {
            nft_details[_msgSender()][_tokenId] = NFTDetails(
                _tokenId,
                block.timestamp,
                (block.timestamp + 3 minutes),
                true
            );
        }

        erc721Helper.safeTransferFrom(_msgSender(), address(this), _tokenId);
        nft_counter[_tokenId] = count + 1;
        emit NFTStaked(_msgSender(), _tokenId, block.timestamp, _plan);
    }

    function unStakeNFT(uint256 _tokenId) external {
        NFTDetails memory details = nft_details[_msgSender()][_tokenId];
        if (details.isStaked == false) {
            revert StakeNFT__TokenIdNotFound(_tokenId);
        }
        if (block.timestamp > details.stakingEndTime) {
            delete nft_details[_msgSender()][_tokenId];
            erc721Helper.safeTransferFrom(
                address(this),
                _msgSender(),
                _tokenId
            );
            emit NFTUnStaked(_msgSender(), _tokenId, block.timestamp);
        } else {
            revert StakeNFT__StakingPeriodNotOverYet(details.stakingEndTime);
        }
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function isLimitReached(uint256 _tokenId) external view returns (bool) {
        return nft_counter[_tokenId] > 1 ? true : false;
    }

    function isNFTStaked(uint256 _tokenId) external view returns (bool) {
        NFTDetails memory details = nft_details[_msgSender()][_tokenId];
        return details.isStaked;
    }
}
