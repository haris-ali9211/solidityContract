//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyToken {
    ////////////////////////////State Variables//////////////////////////////////////////
    address private admin;
    string public constant name = "Test";
    string public constant symbol = "DC";
    uint256 public totalSupply = 10000 ether;
    uint256 public remainingTokens = totalSupply;
    uint256 public firstMonthPrice = 0.005 ether;
    uint256 public secondMonthPrice = 0.01 ether;
    uint256 public finalPrice = 0.1 ether;
    uint256 public immutable time;
    uint256 public immutable decimals;
    uint256 private constant VALUE = 1000000000000000000;

    ////////////////////////////Events/////////////////////////////////////////////
    event Transfer(
        address indexed recipient,
        address indexed to,
        uint256 amount
    );
    event Allowance(address indexed from, address indexed to, uint256 amount);

    /////////////////////////////Mappings///////////////////////////////////////////
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    ////////////////////////Constructor////////////////////////////////////
    constructor() {
        admin = msg.sender;
        decimals = 18;
        time = block.timestamp;
    }

    /////////////////////////////Modifier/////////////////////////////////
    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not allowed to do that");
        _;
    }

    /////////////////////////////Main Functions/////////////////////////////////
    function buyTokens(uint256 _value) external payable returns (bool) {
        remainingTokens = remainingTokens - (VALUE * _value);
        require(remainingTokens > 0, "We dont have that much tokens rightnow");
        if (block.timestamp <= time + 30 days) {
            require(msg.value >= firstMonthPrice * _value);
            balances[msg.sender] += VALUE * _value;
            return true;
        } else if (block.timestamp <= time + 60 days) {
            require(msg.value >= secondMonthPrice * _value);
            balances[msg.sender] += VALUE * _value;
            return true;
        } else {
            require(msg.value >= finalPrice * _value);
            balances[msg.sender] += VALUE * _value;
            return true;
        }
    }

    function withdrawMoney() external onlyAdmin {
        require(
            address(this).balance > 0,
            "Dont have money in the contract to withdraw"
        );
        payable(admin).transfer(address(this).balance);
    }

    function transfer(address reciever, uint256 amount)
        external
        returns (bool)
    {
        require(
            balances[msg.sender] >= (VALUE * amount),
            "You dont have enough tokens to transfer"
        );
        balances[msg.sender] -= (VALUE * amount);
        balances[reciever] += (VALUE * amount);

        emit Transfer(msg.sender, reciever, amount);
        return true;
    }

    function burn(uint256 amount) external onlyAdmin {
        require(totalSupply >= amount, "You dont have enough tokens to burn");
        totalSupply -= amount;
        remainingTokens -= amount;
    }

    function mint(uint256 _amount) external onlyAdmin {
        totalSupply += _amount;
        remainingTokens += _amount;
    }

    function approval(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;

        emit Allowance(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 allowedTokens = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowedTokens >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    ///////////////////////Getter Functions////////////////////////////////////

    function Contractbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function owner() public view returns (address) {
        return admin;
    }

    function realTime() public view returns (uint256) {
        return block.timestamp;
    }
}
