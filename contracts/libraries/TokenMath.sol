// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TokenMath Library
/// @notice Advanced mathematical operations for token calculations
library TokenMath {
    /// @notice Custom errors for better gas efficiency
    error Overflow();
    error DivisionByZero();
    error InvalidInput();

    /// @notice Calculate linear vesting amount
    /// @param totalAmount Total amount to vest
    /// @param startTime Start time of vesting
    /// @param duration Total duration of vesting
    /// @param currentTime Current timestamp
    /// @return vestedAmount Amount vested at current time
    function calculateLinearVesting(
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration,
        uint256 currentTime
    ) internal pure returns (uint256 vestedAmount) {
        if (currentTime <= startTime) return 0;
        if (currentTime >= startTime + duration) return totalAmount;

        // Complex calculation using assembly for gas optimization
        assembly {
            // Load free memory pointer
            let ptr := mload(0x40)
            
            // Calculate time elapsed
            let elapsed := sub(currentTime, startTime)
            
            // Calculate vested amount: (totalAmount * elapsed) / duration
            // Check for overflow in multiplication
            let mult := mul(totalAmount, elapsed)
            if lt(div(mult, elapsed), totalAmount) {
                // Store error signature for Overflow()
                mstore(ptr, 0x35278d12)
                revert(ptr, 4)
            }
            
            vestedAmount := div(mult, duration)
            
            // Verify calculation
            if gt(vestedAmount, totalAmount) {
                // Store error signature for Overflow()
                mstore(ptr, 0x35278d12)
                revert(ptr, 4)
            }
        }
    }

    /// @notice Calculate compound interest with time decay
    /// @param principal Initial amount
    /// @param rate Interest rate in basis points (1/10000)
    /// @param time Time period
    /// @param decay Decay factor in basis points
    /// @return result Final amount after compound interest
    function calculateCompoundInterest(
        uint256 principal,
        uint256 rate,
        uint256 time,
        uint256 decay
    ) internal pure returns (uint256 result) {
        if (principal == 0) return 0;
        if (rate == 0) return principal;
        if (time == 0) return principal;
        if (rate > 10000) revert InvalidInput();
        if (decay > 10000) revert InvalidInput();

        // Complex calculation using assembly
        assembly {
            // Load free memory pointer
            let ptr := mload(0x40)
            
            // Initialize result with principal
            result := principal
            
            // Calculate compound interest with decay for each time unit
            for { let i := 0 } lt(i, time) { i := add(i, 1) } {
                // Calculate interest: result * rate / 10000
                let interest := div(mul(result, rate), 10000)
                
                // Apply decay to rate: rate * (10000 - decay) / 10000
                rate := div(mul(rate, sub(10000, decay)), 10000)
                
                // Add interest to result
                result := add(result, interest)
                
                // Check for overflow
                if lt(result, interest) {
                    // Store error signature for Overflow()
                    mstore(ptr, 0x35278d12)
                    revert(ptr, 4)
                }
            }
        }
    }

    /// @notice Calculate weighted average of token amounts
    /// @param amounts Array of token amounts
    /// @param weights Array of weights
    /// @return average Weighted average
    function calculateWeightedAverage(
        uint256[] memory amounts,
        uint256[] memory weights
    ) internal pure returns (uint256 average) {
        if (amounts.length != weights.length) revert InvalidInput();
        if (amounts.length == 0) revert InvalidInput();

        uint256 totalWeight = 0;
        uint256 weightedSum = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            // Check for overflow in multiplication
            uint256 weighted = amounts[i] * weights[i];
            if (weighted / weights[i] != amounts[i]) revert Overflow();
            
            weightedSum += weighted;
            // Check for overflow in addition
            if (weightedSum < weighted) revert Overflow();
            
            totalWeight += weights[i];
            // Check for overflow in addition
            if (totalWeight < weights[i]) revert Overflow();
        }

        if (totalWeight == 0) revert DivisionByZero();
        average = weightedSum / totalWeight;
    }

    /// @notice Convert between token decimals
    /// @param amount Amount to convert
    /// @param fromDecimals Current decimal places
    /// @param toDecimals Target decimal places
    /// @return converted Converted amount
    function convertDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256 converted) {
        if (fromDecimals > 77 || toDecimals > 77) revert InvalidInput();
        if (fromDecimals == toDecimals) return amount;

        if (fromDecimals < toDecimals) {
            uint256 scale = 10 ** (toDecimals - fromDecimals);
            // Check for overflow
            converted = amount * scale;
            if (converted / scale != amount) revert Overflow();
        } else {
            uint256 scale = 10 ** (fromDecimals - toDecimals);
            converted = amount / scale;
        }
    }
}
