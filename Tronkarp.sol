pragma solidity ^0.4.23;

import { SafeMath } from "./SafeMath.sol";
import { TRC20 } from "./TRC20.sol";

interface TronkarpLock {
    function lockTokens(address player, uint256 amount) external returns (bool success);
}

contract Tronkarp is TRC20 {

    // Token distribution: 20% dev, 60% mining, 20% hodlers
    string public name;
    string public symbol;
    uint256 public decimals = 6;
    uint256 public totalSupply;

    address public ceoAddress;
    address public configurator;
    TronkarpLock public lockContract;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed _spender, uint256 value);
    event Burn (address indexed from, uint256 value);

    uint256 initialSupply = 100000000;
    string tokenName = "Tronkarp";
    string tokenSymbol = "KOI";
    constructor (address _configurator) public {
        require (_configurator != 0x0, "Invalid configurator");

        configurator = _configurator;
        totalSupply = initialSupply*10**uint256(decimals);
        name = tokenName;
        symbol = tokenSymbol;
        ceoAddress = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function () external payable { }

    function getBalance () external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance (uint256 amount) external {
        require (msg.sender == ceoAddress, "Unauthorized");
        require (amount <= address(this).balance, "Insufficient funds");

        msg.sender.transfer(amount);
    }

    function totalSupply () external view returns (uint256) {
        return totalSupply;
    }

    function balanceOf (address player) external view returns (uint256) {
        return balanceOf[player];
    }

    function allowance (address player, address approvee) external view returns (uint256) {
        return allowance[player][approvee];
    }

    function _transfer (address _from, address _to, uint256 _value) internal {
        require (_to != 0x0, "Invalid receiver address");
        require (balanceOf[_from] >= _value, "Insufficient funds");
        require (SafeMath.add(balanceOf[_to], _value) >= balanceOf[_to], "Invalid amount");

        uint256 previousBalances = SafeMath.add(balanceOf[_from], balanceOf[_to]);

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

        assert (SafeMath.add(balanceOf[_from], balanceOf[_to]) == previousBalances);

        emit Transfer (_from, _to, _value);
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        _transfer (msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success) {
        require (_value <= allowance[_from][msg.sender], "Insufficient allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer (_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) public returns (bool success) {
        require (_spender != 0x0, "Invalid spender address");
        require (_value > 0, "Invalid amount");
        allowance[msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);

        return true;
    }

    function burn (uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value, "Insufficient amount");
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);

        emit Burn (msg.sender, _value);
        return true;
    }

    function burnFrom (address _from, uint256 _value) public returns (bool success) {
        require (balanceOf[_from] >= _value, "Insufficient amount");
        require (_value <= allowance[_from][msg.sender], "Insufficient allowance");
        require (totalSupply >= _value, "Invalid amount");

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, _value);

        emit Burn (_from, _value);
        return true;
    }

    function setLockContract (address _lockAddress) external returns (bool success) {
        require (configurator != 0x0, "Not initialized");
        require ((msg.sender == ceoAddress) || (msg.sender == configurator), "Unauthorized");
        require (_lockAddress != 0x0, "Invalid lock address");

        lockContract = TronkarpLock(_lockAddress);

        return true;
    }

    function lockTokens (uint256 _value) public returns (bool success) {
        require (address(lockContract) != 0x0, "Lock contract not active");
        require (balanceOf[msg.sender] >= _value, "Insufficient amount");

        transfer(address(lockContract), _value);
        lockContract.lockTokens(msg.sender, _value);

        return true;
    }
}
