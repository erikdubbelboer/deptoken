pragma solidity ^0.4.18;

contract Backend {
    address private owner;
    mapping(address => bool) private frontends;

    // Balances for each account
    mapping(address => uint256) private balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) private allowed;

    uint256 private minted;

    function Backend() public {
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

    function isFrontendAllowed(address _frontend) public constant returns (bool) {
        return frontends[_frontend];
    }

    function setFrontend(address _frontend, bool _allowed) external {
        if (msg.sender != owner) {
            revert();
        }
        frontends[_frontend] = _allowed;
    }

    function getBalance(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function setBalance(address _owner, uint256 _amount) external {
        if (!frontends[msg.sender]) {
            revert();
        }

        balances[_owner] = _amount;
    }

    function getAllowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function setAllowance(address _owner, address _spender, uint256 _amount) external {
        if (!frontends[msg.sender]) {
            revert();
        }

        allowed[_owner][_spender] = _amount;
    }

    function getMinted() public constant returns (uint256) {
        return minted;
    }

    function setMinted(uint256 _minted) external {
        if (!frontends[msg.sender]) {
            revert();
        }

        minted = _minted;
    }

    function destruct(address _to) external {
        if (msg.sender != owner) {
            revert();
        }

        selfdestruct(_to);
    }
}

