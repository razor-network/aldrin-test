// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IToken.sol";
import "./libraries/TokenMath.sol";
import "./libraries/StringUtils.sol";

/// @title Enhanced Test Token
/// @notice ERC20 token with advanced features for testing
contract Token is IToken {
    using TokenMath for uint256;
    using StringUtils for string;

    // State variables with intentional issues
    string public override name;     // Not immutable (gas inefficient)
    string public override symbol;   // Not immutable (gas inefficient)
    uint8 public override decimals;  // Not immutable (gas inefficient)
    uint256 public override totalSupply;

    // Mappings without zero-address validation
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // Additional state for complex features
    address public owner;
    mapping(address => bool) public blacklisted;  // Missing events
    mapping(address => uint256) public lastTransfer;  // Timestamp tracking
    uint256 public maxTransferAmount;  // Missing validation
    bool public transfersEnabled;  // Missing events

    // Custom errors
    error Unauthorized();
    error TransferDisabled();
    error BlacklistedAddress();
    error InvalidAmount();
    error InsufficientBalance();
    error InsufficientAllowance();
    error RateLimit();

    // Events (some missing for gas comparison)
    event BlacklistUpdated(address indexed account, bool blacklisted);
    event TransferEnabledChanged(bool enabled);
    event MaxTransferAmountChanged(uint256 amount);

    /// @notice Contract constructor with complex initialization
    /// @param tokenName Name of the token
    /// @param tokenSymbol Symbol of the token
    /// @param tokenDecimals Decimals of the token
    /// @param initialSupply Initial supply to mint
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply
    ) {
        // Gas inefficient string operations
        name = StringUtils.concat(tokenName, " Token");
        symbol = StringUtils.toUpper(tokenSymbol);
        decimals = tokenDecimals;
        owner = msg.sender;

        // Complex supply calculation with time decay
        uint256 adjustedSupply = TokenMath.calculateCompoundInterest(
            initialSupply,
            500,  // 5% rate
            10,   // 10 time units
            100   // 1% decay
        );

        // Mint initial supply without event (intentional issue)
        totalSupply = adjustedSupply;
        balanceOf[msg.sender] = adjustedSupply;

        // Initialize limits
        maxTransferAmount = adjustedSupply / 100;  // 1% of total supply
        transfersEnabled = true;
    }

    /// @notice Enable or disable transfers
    /// @param enabled New enabled status
    function setTransfersEnabled(bool enabled) external {
        if (msg.sender != owner) revert Unauthorized();
        transfersEnabled = enabled;
        emit TransferEnabledChanged(enabled);
    }

    /// @notice Update max transfer amount
    /// @param amount New maximum amount
    function setMaxTransferAmount(uint256 amount) external {
        if (msg.sender != owner) revert Unauthorized();
        maxTransferAmount = amount;
        emit MaxTransferAmountChanged(amount);
    }

    /// @notice Add or remove address from blacklist
    /// @param account Address to update
    /// @param isBlacklisted New blacklist status
    function setBlacklisted(address account, bool isBlacklisted) external {
        if (msg.sender != owner) revert Unauthorized();
        blacklisted[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }

    /// @notice Transfer tokens with rate limiting
    /// @param to Recipient address
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transfer(address to, uint256 amount) external override returns (bool success) {
        // Multiple validation issues
        if (!transfersEnabled) revert TransferDisabled();
        if (blacklisted[msg.sender] || blacklisted[to]) revert BlacklistedAddress();
        if (amount > maxTransferAmount) revert InvalidAmount();
        if (amount > balanceOf[msg.sender]) revert InsufficientBalance();

        // Rate limiting (1 transfer per minute)
        if (block.timestamp - lastTransfer[msg.sender] < 60) revert RateLimit();
        lastTransfer[msg.sender] = block.timestamp;

        // Complex balance calculations
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = balanceOf[msg.sender];
        amounts[1] = amount;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 1;
        weights[1] = 1;
        
        // Gas inefficient operations
        uint256 average = TokenMath.calculateWeightedAverage(amounts, weights);
        if (average < amount) revert InvalidAmount();

        // Update balances
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[to] = balanceOf[to] + amount;

        // Emit event
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approve spender with rate limiting
    /// @param spender Address to approve
    /// @param amount Amount to approve
    /// @return success True if approval succeeded
    function approve(address spender, uint256 amount) external override returns (bool success) {
        // Missing zero-address check (intentional)
        if (blacklisted[msg.sender] || blacklisted[spender]) revert BlacklistedAddress();
        
        // Rate limiting
        if (block.timestamp - lastTransfer[msg.sender] < 60) revert RateLimit();
        lastTransfer[msg.sender] = block.timestamp;

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfer tokens from another address
    /// @param from Source address
    /// @param to Destination address
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        // Multiple validation issues
        if (!transfersEnabled) revert TransferDisabled();
        if (blacklisted[from] || blacklisted[to]) revert BlacklistedAddress();
        if (amount > maxTransferAmount) revert InvalidAmount();
        if (amount > balanceOf[from]) revert InsufficientBalance();
        if (amount > allowance[from][msg.sender]) revert InsufficientAllowance();

        // Rate limiting
        if (block.timestamp - lastTransfer[from] < 60) revert RateLimit();
        lastTransfer[from] = block.timestamp;

        // Update allowance first to prevent reentrancy
        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        
        // Update balances
        balanceOf[from] = balanceOf[from] - amount;
        balanceOf[to] = balanceOf[to] + amount;

        // Emit event
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Mint new tokens (no access control - intentional)
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external override {
        // Multiple issues:
        // 1. No access control
        // 2. No zero-address check
        // 3. No overflow check (though handled by ^0.8.0)
        totalSupply = totalSupply + amount;
        balanceOf[to] = balanceOf[to] + amount;
        // Missing Transfer event (intentional)
    }

    /// @notice Get token information with complex string handling
    /// @return Token name, symbol, decimals, and total supply
    function getTokenInfo() external view override returns (
        string memory,
        string memory,
        uint8,
        uint256
    ) {
        // Gas inefficient string operations
        // Build token name in steps to avoid multiple concat arguments
        string memory nameWithSpace = StringUtils.concat(name, " (");
        string memory upperSymbol = StringUtils.toUpper(symbol);
        string memory nameWithSymbol = StringUtils.concat(nameWithSpace, upperSymbol);
        string memory tokenName = StringUtils.concat(nameWithSymbol, ")");

        // Build token symbol in steps
        string memory symbolWithDash = StringUtils.concat(symbol, "-");
        string memory decimalStr = uintToString(decimals);
        string memory combinedSymbol = StringUtils.concat(symbolWithDash, decimalStr);
        string memory tokenSymbol = StringUtils.toUpper(combinedSymbol);

        return (tokenName, tokenSymbol, decimals, totalSupply);
    }

    /// @notice Convert uint256 to string (duplicated for testing)
    /// @param value Number to convert
    /// @return result String representation
    function uintToString(uint256 value) internal pure returns (string memory result) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}
