// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    /// @notice Token name
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @notice Token symbol
    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @notice Number of decimals the token uses
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Total supply of the token
    /// @return The total supply
    function totalSupply() external view returns (uint256);

    /// @notice Balance of a specific account
    /// @param account Address to query balance for
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Amount of tokens approved for spender
    /// @param owner Address that owns the tokens
    /// @param spender Address approved to spend tokens
    /// @return The amount of tokens approved
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Transfer tokens to a specified address
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transfer(address to, uint256 amount) external returns (bool success);

    /// @notice Approve spender to spend tokens
    /// @param spender Address to approve
    /// @param amount Amount to approve
    /// @return success True if approval succeeded
    function approve(address spender, uint256 amount) external returns (bool success);

    /// @notice Transfer tokens from one address to another
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @return success True if transfer succeeded
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);

    /// @notice Mint new tokens
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external;

    /// @notice Get token information
    /// @return Token name, symbol, decimals, and total supply
    function getTokenInfo() external view returns (string memory, string memory, uint8, uint256);

    /// @notice Emitted when tokens are transferred
    /// @param from Address tokens transferred from
    /// @param to Address tokens transferred to
    /// @param value Amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when allowance is set
    /// @param owner Address that approved tokens
    /// @param spender Address approved to spend tokens
    /// @param value Amount of tokens approved
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
