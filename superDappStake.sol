// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";
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

error SuperDapps__StakeCountLimitReached(uint256 time);
error SuperDapps__StakeTimeNotCompleted(uint256 time);
error SuperDapps__NotOwner();
error SuperDapps__SelectCorrectPlan(
    uint256 planA,
    uint256 planB,
    uint256 planC
);

contract SuperDappsStake3Plan is Ownable, IERC721Receiver {
    struct NFTDetails {
        address owner;
        uint256 firstTokenId;
        uint256 secondTokenId;
        uint256 firstNft_from;
        uint256 firstNft_end;
        uint256 secondNft_from;
        uint256 secondNft_end;
        uint256 first_plan;
        uint256 second_plan;
        uint256 stakeCounter;
    }

    IERC721 private immutable i_erc721helper;

    uint256 constant futureTimestamp12 = 1 * 60; //twelveMinutes
    uint256 constant futureTimestamp24 = 2 * 60; //twentyFourMinutes
    uint256 constant futureTimestamp36 = 3 * 60; //thirtySixMinutes
    uint256 constant futureTimestampNonResponsiveUser = 10 * 60; //NonResponsiveUser

    mapping(uint256 => NFTDetails) public s_nftDetails;

    event NFTStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed timeStamp,
        uint256 plan,
        string _type,
        uint256 count
    );

    event NFTUnStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed timeStamp,
        string _type
    );

    modifier isOwner(uint256 tokenId, address spender) {
        address owner = i_erc721helper.ownerOf(tokenId);
        if (spender != owner) {
            revert SuperDapps__NotOwner();
        }
        _;
    }

    constructor(address _collectionAddr) {
        i_erc721helper = IERC721(_collectionAddr);
    }

    function stakeNFT(uint256 _plan, uint256 _tokenId)
        external
        isOwner(_tokenId, _msgSender())
        returns (string memory message)
    {
        console.log("==>Start");
        NFTDetails memory details = s_nftDetails[_tokenId];
        if (details.stakeCounter >= 2) {
            console.log("==>SuperDapps__StakeCountLimitReached");
            revert SuperDapps__StakeCountLimitReached(block.timestamp);
        }

        if (details.stakeCounter == 0) {
            console.log("==>details.stakeCounter == 0");
            i_erc721helper.safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId
            );
            if (_plan == 1) {
                console.log("==>_plan == 1");
                s_nftDetails[_tokenId] = NFTDetails(
                    _msgSender(),
                    _tokenId,
                    0,
                    block.timestamp,
                    block.timestamp + futureTimestamp12,
                    0,
                    0,
                    _plan,
                    0,
                    1
                );
            } else if (_plan == 2) {
                console.log("==>_plan == 2");
                s_nftDetails[_tokenId] = NFTDetails(
                    msg.sender,
                    _tokenId,
                    0,
                    block.timestamp,
                    block.timestamp + futureTimestamp12,
                    0,
                    0,
                    _plan,
                    0,
                    1
                );
            } else if (_plan == 3) {
                console.log("==>_plan == 3");
                s_nftDetails[_tokenId] = NFTDetails(
                    msg.sender,
                    _tokenId,
                    0,
                    block.timestamp,
                    block.timestamp + futureTimestamp12,
                    0,
                    0,
                    _plan,
                    0,
                    1
                );
            } else {
                console.log("==>SuperDapps__SelectCorrectPlan");
                revert SuperDapps__SelectCorrectPlan(1, 2, 3);
            }

            emit NFTStaked(
                msg.sender,
                _tokenId,
                block.timestamp,
                _plan,
                "NFTStake",
                details.stakeCounter
            );
            return "1 Nft Staked";
        } else if (details.stakeCounter == 1) {
            console.log("==>details.stakeCounter == 1");
            uint256 time = details.firstNft_end +
                futureTimestampNonResponsiveUser;
            console.log(
                "==>Time",
                details.firstNft_end,
                futureTimestampNonResponsiveUser
            );

            if (block.timestamp < details.firstNft_end) {
                console.log("==>SuperDapps__StakeTimeNotCompleted");
                revert SuperDapps__StakeTimeNotCompleted(block.timestamp);
            } else if (getNonResponceUserTime(time)) {
                console.log("==>futureTimestampNonResponsiveUser");
                i_erc721helper.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    _tokenId
                );
                address owner1 = i_erc721helper.ownerOf(_tokenId);
                if (owner1 != address(this)) {
                    delete (s_nftDetails[_tokenId]);
                    emit NFTUnStaked(
                        msg.sender,
                        _tokenId,
                        block.timestamp,
                        "NFTStake"
                    );
                    return "Nft unStaked due to NonResponsiveUser";
                } else {
                    console.log("==>else in futureTimestampNonResponsiveUser");
                }
            }

            i_erc721helper.safeTransferFrom(
                address(this),
                _msgSender(),
                _tokenId
            );

            i_erc721helper.safeTransferFrom(
                _msgSender(),
                address(this),
                s_nftDetails[_tokenId].firstTokenId
            );
            address owner = i_erc721helper.ownerOf(_tokenId);
            if (owner != address(this)) {
                console.log("!success");
                // i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
                delete (s_nftDetails[_tokenId]);
                emit NFTUnStaked(
                    msg.sender,
                    _tokenId,
                    block.timestamp,
                    "NFTStake"
                );
                return "Nft unStaked due to Reject transcation";
            }

            if (_plan == 1) {
                console.log("==>_plan ==> 1");
                s_nftDetails[_tokenId].secondTokenId = _tokenId;
                s_nftDetails[_tokenId].secondNft_from = block.timestamp;
                s_nftDetails[_tokenId].secondNft_end =
                    block.timestamp +
                    futureTimestamp12;
                s_nftDetails[_tokenId].second_plan = _plan;
                s_nftDetails[_tokenId].stakeCounter++;
            } else if (_plan == 2) {
                console.log("==>_plan ==> 2");
                s_nftDetails[_tokenId].secondTokenId = _tokenId;
                s_nftDetails[_tokenId].secondNft_from = block.timestamp;
                s_nftDetails[_tokenId].secondNft_end =
                    block.timestamp +
                    futureTimestamp24;
                s_nftDetails[_tokenId].second_plan = _plan;
                s_nftDetails[_tokenId].stakeCounter++;
            } else if (_plan == 3) {
                console.log("==>_plan ==> 3");
                s_nftDetails[_tokenId].secondTokenId = _tokenId;
                s_nftDetails[_tokenId].secondNft_from = block.timestamp;
                s_nftDetails[_tokenId].secondNft_end =
                    block.timestamp +
                    futureTimestamp36;
                s_nftDetails[_tokenId].second_plan = _plan;
                s_nftDetails[_tokenId].stakeCounter++;
            } else {
                console.log("==>SuperDapps__SelectCorrectPlan");
                revert SuperDapps__SelectCorrectPlan(1, 2, 3);
            }
            emit NFTStaked(
                msg.sender,
                _tokenId,
                block.timestamp,
                _plan,
                "NFTStake",
                details.stakeCounter
            );
            return "2 Nft Staked";
        } else {
            revert SuperDapps__StakeCountLimitReached(block.timestamp);
        }
    }

    function unStakeNFT(uint256 _tokenId) public {
        NFTDetails memory details = s_nftDetails[_tokenId];
        if (details.owner != msg.sender) {
            console.log("etails.owner !=");
            revert SuperDapps__NotOwner();
        }
        if (block.timestamp < details.secondNft_end) {
            console.log("SuperDapps__StakeTimeNotCompleted");
            revert SuperDapps__StakeTimeNotCompleted(block.timestamp);
        }
        console.log("unstake");

        i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
        delete (s_nftDetails[_tokenId]);
        emit NFTUnStaked(msg.sender, _tokenId, block.timestamp, "NFTStake");
    }

    function getNonResponceUserTime(uint256 time) public view returns (bool) {
        if (block.timestamp > time) {
            console.log("if==>", block.timestamp, time);
            return true;
        } else {
            console.log("else==>", block.timestamp, time);
            return false;
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
