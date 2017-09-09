pragma solidity 0.4.8; 

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


    function Frontend(address _backend, address _erc20) {
        owner = msg.sender;
        backend = Backend(_backend);
        erc20 = ERC20Interface(_erc20);
    }


    function getOwner() constant returns (address) {
        return owner;
    }

    function setOwner(address _owner) external {
        if (msg.sender != owner) {
            throw;
        }

        owner = _owner;
    }


    function getBackend() constant returns (address) {
        return backend;
    }

    function getERC20() constant returns (address) {
        return erc20;
    }


    function totalSupply() constant returns (uint256) {
        return total;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256) {
        return backend.balanceOf(_owner);
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) external returns (bool) {
        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(msg.sender);
        uint256 balanceTo = backend.getBalance(_to);

        if (balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(msg.sender, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            Transfer(msg.sender, _to, _amount);
            erc20.triggerTransfer(msg.sender, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    // Internal transfer function that can only be used by our ERC20 interface contract.
    function internalTransfer(address _sender, address _to, uint256 _amount) external returns (bool) {
        if (msg.sender != erc20) {
            throw;
        }

        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_sender);
        uint256 balanceTo = backend.getBalance(_to);

        if (balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_sender, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            Transfer(_sender, _to, _amount);
            erc20.triggerTransfer(msg.sender, _to, _amount);
            Destroy(_sender, cost);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_from);
        uint256 balanceTo = backend.getBalance(_to);
        uint256 allowanceSpender = backend.getAllowance(_from, msg.sender);

        if (allowanceSpender > amountPlusCost && balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_from, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            backend.setAllowance(_from, msg.sender, allowanceSpender - amountPlusCost);
            Transfer(_from, _to, _amount);
            erc20.triggerTransfer(msg.sender, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    // Internal transferFrom function that can only be used by our ERC20 interface contract.
    function internalTransferFrom(address _sender, address _from, address _to, uint256 _amount) external returns (bool) {
        if (msg.sender != erc20) {
            throw;
        }

        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = backend.getBalance(_from);
        uint256 balanceTo = backend.getBalance(_to);
        uint256 allowanceSpender = backend.getAllowance(_from, _sender);

        if (allowanceSpender > amountPlusCost && balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            backend.setBalance(_from, balanceFrom - amountPlusCost);
            backend.setBalance(_to, balanceTo + _amount);
            backend.setAllowance(_from, _sender, allowanceSpender - amountPlusCost);
            Transfer(_from, _to, _amount);
            erc20.triggerTransfer(msg.sender, _to, _amount);
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
        if (msg.sender != erc20) {
            throw;
        }

        backend.setAllowance(_sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
        return backend.getAllowance(_owner, _spender);
    }


    function buy() payable external returns (uint256) {
        if (block.number <= mintAfterBlock) {
            throw;
        }
        uint256 amount = msg.value / price;
        uint256 minted = backend.getMinted();
        if (minted + amount < minted) {
            throw;
        }
        if (minted + amount > total) {
            throw;
        }
        uint256 balance = backend.getBalance(msg.sender);
        if (balance + amount < balance) {
            throw;
        }
        backend.setBalance(msg.sender, balance + amount);
        backend.setMinted(minted + amount);
        Transfer(this, msg.sender, _amount);
        return amount;
    }

    function withdraw(address _to, uint256 _amount) external {
        if (msg.sender != owner) {
            throw;
        }

        _to.transfer(_amount);
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            throw;
        }

        selfdestruct(_to);
    }
}

contract Backend {
    address private owner;
    mapping(address => bool) private frontends;

    // Balances for each account
    mapping(address => uint256) private balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) private allowed;

    uint256 private minted;

    function Backend() {
        owner = msg.sender;
    }

    function getOwner() constant returns (address) {
        return owner;
    }

    function setOwner(address _owner) external {
        if (msg.sender != owner) {
            throw;
        }

        owner = _owner;
    }

    function isFrontendAllowed(address _frontend) constant returns (bool) {
        return frontends[_frontend];
    }

    function setFrontend(address _frontend, bool allowed) external {
        if (msg.sender != owner) {
            throw;
        }
        frontends[_frontend] = allowed;
    }

    function getBalance(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function setBalance(address _owner, uint256 _amount) external {
        if (!frontends[msg.sender]) {
            throw;
        }

        balances[_owner] = _amount;
    }

    function getAllowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function setAllowance(address _owner, address _spender, uint256 _amount) external {
        if (!frontends[msg.sender]) {
            throw;
        }

        allowed[_owner][_spender] = _amount;
    }

    function getMinted() constant returns (uint256) {
        return minted;
    }

    function setMinted(uint256 _minted) external {
        if (!frontends[msg.sender]) {
            throw;
        }

        minted = _minted;
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            throw;
        }

        selfdestruct(_to);
    }
}

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    address private owner;
    Frontend private frontend;

    string public constant symbol = "TTT";
    string public constant name = "Test Token";
    uint8 public constant decimals = 18;

    function ERC20Interface() {
        owner = msg.sender;
    }

    function getOwner() constant returns (address) {
        return owner;
    }

    function setOwner(address _owner) external {
        if (msg.sender != owner) {
            throw;
        }

        owner = _owner;
    }

    function getFrontend() constant returns (address) {
        return frontend;
    }

    function setFrontend(address _frontend) external {
        if (msg.sender != owner) {
            throw;
        }

        frontend = Frontend(_frontend);
    }

    // Get the total token supply
    function totalSupply() constant returns (uint256) {
        return frontend.totalSupply();
    }

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256) {
        return frontend.balanceOf(_owner);
    }

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool) {
        return frontend.internalTransfer(msg.sender, _to, _value);
    }

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        return frontend.internalTransferFrom(msg.sender, _from, _to, _value);
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) returns (bool) {
        return frontend.internalApprove(msg.sender, _spender, _value);
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return frontend.allowance(_owner, _spender);
    }

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function triggerTransfer(address _from, address _to, uint256 _value) {
        Transfer(_from, _to, _value);
    }

    function triggerApproval(address _owner, address _spender, uint256 _value) {
        Approval(_owner, _spender, _value);
    }
}

