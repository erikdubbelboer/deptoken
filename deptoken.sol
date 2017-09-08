pragma solidity 0.4.8; 

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
interface ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256 totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Frontend {
    address private owner;
    address private backend;

    function Frontend(address _backend) {
        backend = _backend;
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

    function getBackend() constant returns (address) {
        return backend;
    }

    function setBackend(address _backend) external {
        if (msg.sender != owner) {
            throw;
        }
        backend = _backend;
    }

    function() public {
        if (!backend.delegatecall(msg.data)) {
            throw;
        }
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            throw;
        }

        selfdestruct(_to);
    }
}

contract Storage {
    address private owner;
    mapping(address => bool) private backends;

    // Balances for each account
    mapping(address => uint256) private balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) private allowed;

    uint256 private minted;

    function Storage() {
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

    function isBackendAllowed(address _backend) constant returns (bool) {
        return backends[_backend];
    }

    function setBackend(address _backend, bool allowed) external {
        if (msg.sender != owner) {
            throw;
        }
        backends[_backend] = allowed;
    }

    function getBalance(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function setBalance(address _owner, uint256 _amount) external {
        if (!backends[msg.sender]) {
            throw;
        }

        balances[_owner] = _amount;
    }

    function getAllowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function setAllowance(address _owner, address _spender, uint256 _amount) external {
        if (!backends[msg.sender]) {
            throw;
        }

        allowed[_owner][_spender] = _amount;
    }

    function getMinted() constant returns (uint256) {
        return minted;
    }

    function setMinted(uint256 _minted) external {
        if (!backends[msg.sender]) {
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

contract Backend is ERC20Interface {
    address private owner;
    Storage private storage;

    string public constant symbol = "TTT";
    string public constant name = "Test Token";
    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 1000000;
    uint256 public constant transferCost = 1;

    uint public constant mintAfterBlock = 1234;
    uint256 public constant price = 1000; // 1000 wei for one token.

    event Destroy(address indexed _from, uint256 _value);

    function Backend(address _storage) {
        owner = msg.sender;
        storage = Storage(_storage);
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


    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256) {
        return storage.balanceOf(_owner);
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) external returns (bool) {
        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = storage.getBalance(msg.sender);
        uint256 balanceTo = storage.getBalance(_to);

        if (balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            storage.setBalance(msg.sender, balanceFrom - amountPlusCost);
            storage.setBalance(_to, balanceTo + _amount);
            Transfer(msg.sender, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        uint256 cost = _transferCost;
        uint256 amountPlusCost = _amount + cost;
        uint256 balanceFrom = storage.getBalance(_from);
        uint256 balanceTo = storage.getBalance(_to);
        uint256 allowanceSpender = storage.getAllowance(_from, msg.sender);

        if (allowanceSpender > amountPlusCost && balanceFrom >= amountPlusCost && balanceTo + _amount > balanceTo) {
            storage.setBalance(_from, balanceFrom - amountPlusCost);
            storage.setBalance(_to, balanceTo + _amount);
            storage.setAllowance(_from, msg.sender, allowanceSpender - amountPlusCost);
            Transfer(_from, _to, _amount);
            Destroy(_from, cost);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        storage.setAllowance(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
        return storage.getAllowance(_owner, _spender);
    }


    function buy() payable external returns (uint256) {
        if (block.number <= mintAfterBlock) {
            throw;
        }
        uint256 amount = msg.value / price;
        uint256 minted = storage.getMinted();
        if (minted + amount < minted) {
            throw;
        }
        if (minted + amount > totalSupply) {
            throw;
        }
        uint256 balance = storage.getBalance(msg.sender);
        if (balance + amount < balance) {
            throw;
        }
        storage.setBalance(msg.sender, balance + amount);
        storage.setMinted(minted + amount);
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
