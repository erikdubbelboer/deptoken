pragma solidity ^0.4.18;

import './Backend.sol';
import './ERC20Interface.sol';

contract Frontend {
    address private owner;
    Backend private backend;
    ERC20Interface private erc20; // The address of our ERC20 interface contract.

    uint256 public constant total = 1000000; // Max number of tokens that can be in existence.
    uint256 public constant transferCost = 1;

    uint public constant mintAfterBlock = 1234;
    uint256 public constant price = 1000; // 1000 wei for one token.

    event Destroy(address indexed _from, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function Frontend(address _backend, address _erc20) public {
        owner = msg.sender;
        backend = Backend(_backend);
        erc20 = ERC20Interface(_erc20);
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


    function getBackend() public constant returns (address) {
        return backend;
    }

    function getERC20() public constant returns (address) {
        return erc20;
    }


    function totalSupply() public pure returns (uint256) {
        return total;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) public constant returns (uint256) {
        return backend.getBalance(_owner);
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) external returns (bool) {
        uint256 cost = transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(msg.sender);
        uint256 balanceTo = backend.getBalance(_to);

        if (balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(msg.sender, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            Transfer(msg.sender, _to, _amount);
            erc20.triggerTransfer(msg.sender, _to, _amount);
            Destroy(msg.sender, cost);
            return true;
        } else {
            return false;
        }
    }

    // Internal transfer function that can only be used by our ERC20 interface contract.
    function internalTransfer(address _sender, address _to, uint256 _amount) external returns (bool) {
        if (msg.sender != address(erc20)) {
            revert();
        }

        uint256 cost = transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_sender);
        uint256 balanceTo = backend.getBalance(_to);

        if (balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_sender, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            Transfer(_sender, _to, _amount);
            erc20.triggerTransfer(_sender, _to, _amount);
            Destroy(_sender, cost);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        uint256 cost = transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_from);
        uint256 balanceTo = backend.getBalance(_to);
        uint256 allowanceSpender = backend.getAllowance(_from, msg.sender);

        if (allowanceSpender > amountPlusCost && balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_from, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            backend.setAllowance(_from, msg.sender, allowanceSpender - amountPlusCost);
            Transfer(_from, _to, _amount);
            erc20.triggerTransfer(_from, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    // Internal transferFrom function that can only be used by our ERC20 interface contract.
    function internalTransferFrom(address _sender, address _from, address _to, uint256 _amount) external returns (bool) {
        if (msg.sender != address(erc20)) {
            revert();
        }

        uint256 cost = transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_from);
        uint256 balanceTo = backend.getBalance(_to);
        uint256 allowanceSpender = backend.getAllowance(_from, _sender);

        if (allowanceSpender > amountPlusCost && balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_from, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            backend.setAllowance(_from, _sender, allowanceSpender - amountPlusCost);
            Transfer(_from, _to, _amount);
            erc20.triggerTransfer(_from, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        backend.setAllowance(msg.sender, _spender, _amount);
        Approval(msg.sender, _spender, _amount);
        erc20.triggerApproval(msg.sender, _spender, _amount);
        return true;
    }

    // Internal approve function that can only be used by our ERC20 interface contract.
    function internalApprove(address _sender, address _spender, uint256 _amount) external returns (bool) {
        if (msg.sender != address(erc20)) {
            revert();
        }

        backend.setAllowance(_sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return backend.getAllowance(_owner, _spender);
    }


    function buy() payable external returns (uint256) {
        if (block.number <= mintAfterBlock) {
            revert();
        }
        uint256 amount = msg.value / price;
        uint256 minted = backend.getMinted();
        if (minted + amount < minted) {
            revert();
        }
        if (minted + amount > total) {
            revert();
        }
        uint256 balance = backend.getBalance(msg.sender);
        if (balance + amount < balance) {
            revert();
        }
        backend.setBalance(msg.sender, balance + amount);
        backend.setMinted(minted + amount);
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function withdraw(address _to, uint256 _amount) external {
        if (msg.sender != owner) {
            revert();
        }

        _to.transfer(_amount);
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            revert();
        }

        selfdestruct(_to);
    }
}

