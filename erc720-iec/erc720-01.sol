// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract MyToken 
{
    address admin;

    string public constant name = "erc720-alpha";
    string public constant symbol = "alpha";
    uint public totalSupply = 1000;
    uint256 public immutable decimals; 
 
    event Transfer(address indexed recipient, address indexed to, uint amount);
    event Allowance(address indexed from, address indexed to, uint amount);
    
    mapping(address=>uint) private balances;
    mapping(address=>mapping(address=>uint)) private allowed;

    constructor() 
    {
        admin = msg.sender;
        balances[msg.sender] = totalSupply;
        decimals = 18;
    } 

    modifier onlyAdmin()
    {
        require(msg.sender == admin,"You are not allowed to do that");
        _;
    }

    function balanceOf(address user) public view returns(uint)
    {
        return balances[user];
    }

    function transfer(address reciever, uint amount) public returns(bool)
    {
        require(balances[msg.sender] >= amount,"You dont have enough tokens to transfer");
        balances[msg.sender] -= amount; 
        balances[reciever] += amount;

        emit Transfer(msg.sender,reciever,amount);
        return true;
    }

    function mint(uint quantity) public onlyAdmin returns(uint)
    {
        totalSupply += quantity;
        balances[msg.sender] += quantity;
        return totalSupply;
    }

    function burn(address user, uint amount) public onlyAdmin returns(uint) 
    {
        require(balances[user] >= amount,"You have enough tokens to burn");
        balances[user] -= amount;
        totalSupply -= amount;
        return totalSupply;
    }
}