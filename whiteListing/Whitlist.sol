// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";      

contract Whitelist {

   bytes32 public root;

    constructor(bytes32 _root) {
        root = _root;
    }
   function isValid(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof,root,leaf);
    }
}