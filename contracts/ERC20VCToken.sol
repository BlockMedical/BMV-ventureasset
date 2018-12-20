pragma solidity ^0.4.24;

// ERC20 standard interface with SafeMath
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

// Use SafeMath.sol to perform safe arithmetic. Static linking here.
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "an overflow occured");
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a, "can't end up with negative value");
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "results exceeded 256 bits");
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0, "can't end up with negative value");
        c = a / b;
    }
}

interface InterfaceERC20 {

    // Get the total token supply
    function totalSupply() external view returns (uint256);
    // Get the account balance of another account with address _owner
    function balanceOf(address _tokenOwner) external view returns (uint256);
    // Send _value amount of tokens to address _to
    function transfer(address _toAddr, uint256 _tokenAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _tokenAmount.
    function approve(address _spender, uint256 _tokenAmount) external returns (bool);
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) external view returns (uint256);
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenAmount);
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokenAmount);
}

contract ERC20VCToken is SafeMath, InterfaceERC20 {
    
    // contract owner
    address public owner;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;
    string public symbol;
    uint256 public constant decimals = 18; // the decimal here aligns with the 'byte' unit and our definition
    uint256 private constant eth_to_wei = 10 ** decimals;
    uint256 public constant tokenSupply = 1000000000; // 1B
    uint256 public TOTALSUPPLY = tokenSupply * eth_to_wei; // 1 billion token
    // activate token sale
    bool public allowTokenSale = true;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Custom events
    event Register(string msg, address reg_addr);
    event Replenish(string msg, uint256 _value, address replenish_addr);

    modifier restricted() {
        if (msg.sender != owner) {
            revert("caller is not contract owner");
        }
        _;
    }

    constructor(string tokenName, string tokenSymbol) public {
        name = tokenName; // [optional] assign a name for this new token
        symbol = tokenSymbol; // [optional] as well
        owner = msg.sender;
        _balances[msg.sender] = TOTALSUPPLY;
        emit Transfer(this, msg.sender, TOTALSUPPLY);
    }

    function name() public view returns (string) {
        return name;
    }

    function symbol() public view returns (string) {
        return symbol;
    }

    // remaining total supply
    function totalSupply() public view returns (uint256) {
        return TOTALSUPPLY;
    }
    
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return _balances[_tokenOwner];
    }

    // tokenAmount is by token, 1 ether = 200 tokens
    function transfer(address toAddr, uint256 tokenAmount) public returns (bool) {
        if (tokenAmount == 0) {
            emit Transfer(msg.sender, toAddr, tokenAmount);    // Follow the spec to fire the event when transfer 0
            return;
        }

        if (_balances[msg.sender] < tokenAmount) {
            revert("caller does not have sufficient token");
            return false;
        }
        
        // This overflow rarely happens or should never happen
        if (safeAdd(_balances[toAddr], tokenAmount) < _balances[toAddr]) {
            revert("the token receiver balance overflow and result in negative balance");
            return false;
        }
        
        _balances[msg.sender] = safeSub(_balances[msg.sender], tokenAmount);
        _balances[toAddr] = safeAdd(_balances[toAddr], tokenAmount);
        emit Transfer(msg.sender, toAddr, tokenAmount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Prohibiting transfering tokens to this contract!");
        uint256 allowance = allowed[_from][msg.sender];
        require(_balances[_from] >= _value && allowance >= _value, "token does NOT have sufficient balance to transfer");
        _balances[_to] = safeAdd(_balances[_to], _value);
        _balances[_from] = safeSub(_balances[_from], _value);
        // protect overflow
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Prohibit approving tokens owned by this contract!");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * Prevent eth coming in by accident
     */
    function () public payable {
        revert("somebody is sending me free ether, i don't want it, really?");
    }

    function terminate() public restricted {
        selfdestruct(owner);
    }
}
