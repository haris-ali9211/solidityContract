////////////////////////////////////USDSC MAIN////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
error USDSCMAIN__TransferFailed();
error USDSCMAIN__MarketCapReached();
error USDSCMAIN__DontHaveThatMuchTokens(uint256 remainingSupply);

contract USDSCMAIN is ERC20, Ownable {
    struct Detail {
        uint256 bnb;
        uint256 busd;
    }
    AggregatorV3Interface internal priceFeed;
    // uint256 public noOfUSDSCReleased;
    uint256 public remainingSupply = 1_000_000_000_000 ether;
    mapping(address => Detail) public details;
    address payable[10] public wallets;

    constructor(address payable[10] memory _payees) ERC20("USDSC", "USDSC") {
        priceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        for (uint256 i; i < _payees.length; ++i) {
            wallets[i] = _payees[i];
        }
    }

    function BNBTOUSDSC() external payable {
        if (remainingSupply == 0) {
            revert USDSCMAIN__MarketCapReached();
        }
        uint256 amount = getPrice(msg.value);
        console.log(amount);
        if (remainingSupply - amount == 0) {
            revert USDSCMAIN__DontHaveThatMuchTokens(remainingSupply);
        }
        remainingSupply = remainingSupply - amount;
        _mint(_msgSender(), amount);
        uint256 sharePerAcc = (msg.value / 1000) * 100;
        address payable[10] memory _wallets = wallets;
        for (uint256 i; i < _wallets.length; ++i) {
            (bool success, ) = _wallets[i].call{value: sharePerAcc}("");
            if (!success) {
                revert USDSCMAIN__TransferFailed();
            }
            Detail memory detail = details[_wallets[i]];
            detail.bnb = detail.bnb + sharePerAcc;
            details[_wallets[i]] = detail;
        }
    }

    function getLatestPrice() public view returns (int256 price) {
        (, price, , , ) = priceFeed.latestRoundData();
    }

    function getPrice(uint256 _price) public view returns (uint256 price) {
        uint256 temp = uint256(getLatestPrice());
        price = ((_price * temp) / 10**8);
    }

    function contractValue() public view returns (uint256 value) {
        uint256 BNBAmount;
        address payable[10] memory _wallets = wallets;
        for (uint256 i; i < _wallets.length; i++) {
            BNBAmount = BNBAmount + details[_wallets[i]].bnb;
        }
        value = getPrice(BNBAmount);
    }
}

//["0x7ddBA5379549Fc746B28841D8B927CA0740072a7","0xA2D12AF07aBBD3127E85B4d5658040CFA3773631","0x216B01f973Cfef7c82D245a182CCEDa7C132fF6a","0x1e35F878abC61f3455A90F11B2eA97244E894AE0","0x19C23F51c62D3f3680f146213C7C1eEb2b7F981C","0x1416094708F0F592332EE0E4D36f0FcE99915dE5","0xc761B1bf923BA0a6B96F6F8F7BAb821d95f82c11","0x19Ba547192222D3480665D4AF454270b3FbE6749","0xbc0C92a5b3aCf9dE85A9D8F4d724908db8493caC","0x7626DF04264fEf7f14c11670189749fcbAd2E708"]
//[10,10,10,10,10,10,10,10,10,10]
