// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

contract testnets39globalcom {
  uint256 public s39TokenLeft = 0;
  IBEP20 public immutable S39Globle;
  address public immutable owner;

  mapping(address => uint256) private s39balances;

  event Transfer(address indexed from, uint256 indexed value);

  constructor(address token) {
    owner = msg.sender;
    S39Globle = IBEP20(token);
  }

  function getPoints(uint256 amount) external {
    S39Globle.transferFrom(msg.sender, address(this), amount);
    s39TokenLeft = s39TokenLeft + amount;
    s39balances[msg.sender] += amount;
    emit Transfer(msg.sender, amount);
  }

  function withdrawFunds() external {
    require(msg.sender == owner, "Only Owner can call");
    uint256 balanceOfContract = S39Globle.balanceOf(address(this));
    S39Globle.transfer(owner, balanceOfContract);
  }

  function getSpoint() public view returns (uint256){
    return s39balances[msg.sender];
  }
}
