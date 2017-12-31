pragma solidity ^0.4.18;

import './Frontend.sol';

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    address private owner;
    Frontend private frontend;

    string public constant symbol = "TTT";
    string public constant name = "Test Token";
    uint8 public constant decimals = 18;

    function ERC20Interface() public {
        owner = msg.sender;
    }

    function getOwner() public constant returns (address) {
        return owner;
    }

    function setOwner(address _owner) external {
        if (msg.sender != owner) {
            revert();
        }

        owner = _owner;
    }

    function getFrontend() public constant returns (address) {
        return frontend;
    }

    function setFrontend(address _frontend) external {
        if (msg.sender != owner) {
            revert();
        }

        frontend = Frontend(_frontend);
    }

    // Get the total token supply
    function totalSupply() public constant returns (uint256) {
        return frontend.totalSupply();
    }

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256) {
        return frontend.balanceOf(_owner);
    }

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool) {
        return frontend.internalTransfer(msg.sender, _to, _value);
    }

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return frontend.internalTransferFrom(msg.sender, _from, _to, _value);
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool) {
        return frontend.internalApprove(msg.sender, _spender, _value);
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return frontend.allowance(_owner, _spender);
    }

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function triggerTransfer(address _from, address _to, uint256 _value) public {
        Transfer(_from, _to, _value);
    }

    function triggerApproval(address _owner, address _spender, uint256 _value) public {
        Approval(_owner, _spender, _value);
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            revert();
        }

        selfdestruct(_to);
    }
}

