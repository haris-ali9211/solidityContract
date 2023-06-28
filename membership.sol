// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

error Membership_PriceNotMatched(uint256 price);
error Membership_InvalidOption(string _err);
error Membership__TransferFailed();

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract MemberShip is Ownable {
  struct Details {
    uint256 membershipSelected;
    uint256 time;
  }
  IERC20 private immutable i_erc20Helper;
  uint256[4] public memberships;
  address private walletAddress1;
  address private walletAddress2;

  mapping(address => Details) public MembershipDetails;

  event MembershipBrought(uint256 indexed amount);

  constructor(
    address _busd,
    uint256[4] memory _prices,
    address _addr1,
    address _addr2
  ) {
    i_erc20Helper = IERC20(_busd);
    for (uint256 i = 0; i < memberships.length; i++) {
      memberships[i] = _prices[i];
    }
    walletAddress1 = _addr1;
    walletAddress2 = _addr2;
  }

  function buyMembership(uint256 _option, uint256 _amount) public {
    if (_option != 0 && _option <= memberships.length) {
      if (_amount < memberships[_option - 1]) {
        revert Membership_PriceNotMatched(_amount);
      }
    } else {
      revert Membership_InvalidOption("Please select option between 1 to 4");
    }

    uint256 amountForWallets1 = (_amount * 880) / 1000;
    uint256 amountForWallets2 = (_amount * 120) / 1000;

    bool success1 = i_erc20Helper.transferFrom(
      _msgSender(),
      walletAddress1,
      amountForWallets1
    );
    if (!success1) {
      revert Membership__TransferFailed();
    }

    bool success2 = i_erc20Helper.transferFrom(
      _msgSender(),
      walletAddress2,
      amountForWallets2
    );
    if (!success2) {
      revert Membership__TransferFailed();
    }

    MembershipDetails[_msgSender()] = Details(_option, block.timestamp);
    emit MembershipBrought(_amount);
  }
}
