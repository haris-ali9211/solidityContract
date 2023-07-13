// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

error SuperDapps__StakeCountLimitReached(uint256 time);
error SuperDapps__StakeTimeNotCompleted(uint256 time);
error SuperDapps__NotOwner();
error SuperDapps__SelectCorrectPlan(
    uint256 planA,
    uint256 planB,
    uint256 planC
);

contract SuperDappsStake3Plan {
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

    uint256 constant futureTimestamp12 = 1 * 60; //twelveMinutes
    uint256 constant futureTimestamp24 = 2 * 60; //twentyFourMinutes
    uint256 constant futureTimestamp36 = 3 * 60; //thirtySixMinutes
    uint256 constant futureTimestampNonResponsiveUser = 2 * 60; //NonResponsiveUser

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

    function stakeNFT(uint256 _plan, uint256 _tokenId) public {
        console.log("==>Start");
        NFTDetails memory details = s_nftDetails[_tokenId];
        if (details.stakeCounter >= 2) {
            console.log("==>SuperDapps__StakeCountLimitReached");
            revert SuperDapps__StakeCountLimitReached(block.timestamp);
        }

        if (details.stakeCounter == 0) {
            console.log("==>details.stakeCounter == 0");
            // i_erc721helper.safeTransferFrom(_msgSender(), address(this), _tokenId);
            if (_plan == 1) {
                console.log("==>_plan == 1");
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
        }
        //  else if (getNonResponceUserTime()) {
        //     console.log("==>futureTimestampNonResponsiveUser");
        //     //bool success = i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
        //     bool success = true;
        //     if (!success) {
        //         // i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
        //         delete (s_nftDetails[_tokenId]);
        //         emit NFTUnStaked(
        //             msg.sender,
        //             _tokenId,
        //             block.timestamp,
        //             "NFTStake"
        //         );
        //     }
        // }
        else if (details.stakeCounter == 1) {
            console.log("==>details.stakeCounter == 1");
            if (block.timestamp < details.firstNft_end) {
                console.log("==>SuperDapps__StakeTimeNotCompleted");
                revert SuperDapps__StakeTimeNotCompleted(block.timestamp);
            }
            //bool success = i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
            bool success = true;
            if (!success) {
                // i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
                delete (s_nftDetails[_tokenId]);
                emit NFTUnStaked(
                    msg.sender,
                    _tokenId,
                    block.timestamp,
                    "NFTStake"
                );
            }
            // i_erc721helper.safeTransferFrom(_msgSender(), address(this), s_nftDetails[_tokenId].firstTokenId);
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
        } else {
            revert SuperDapps__StakeCountLimitReached(block.timestamp);
        }
    }

    function unStakeNFT(uint256 _tokenId) public {
        NFTDetails memory details = s_nftDetails[_tokenId];
        if (details.owner != msg.sender) {
            revert SuperDapps__NotOwner();
        }
        if (block.timestamp < details.secondNft_end) {
            revert SuperDapps__StakeTimeNotCompleted(block.timestamp);
        }

        // i_erc721helper.safeTransferFrom(address(this), _msgSender(), _tokenId);
        delete (s_nftDetails[_tokenId]);
        emit NFTUnStaked(msg.sender, _tokenId, block.timestamp, "NFTStake");
    }

        uint256 time = block.timestamp + futureTimestampNonResponsiveUser;
    function getNonResponceUserTime() public view {
        if (block.timestamp > time) {
            console.log("if==>", block.timestamp, time);
        } else {
            console.log("else==>", block.timestamp, time);
        }
    }
}
