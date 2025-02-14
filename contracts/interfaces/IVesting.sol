// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVesting {
    /// @notice Information about a vesting schedule
    /// @param beneficiary Address receiving the tokens
    /// @param startTime Start time of the vesting period
    /// @param duration Duration of the vesting period
    /// @param totalAmount Total amount of tokens to vest
    /// @param releasedAmount Amount of tokens already released
    /// @param revocable Whether the vesting can be revoked
    /// @param revoked Whether the vesting has been revoked
    struct VestingSchedule {
        address beneficiary;
        uint256 startTime;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool revocable;
        bool revoked;
    }

    /// @notice Create a new vesting schedule
    /// @param beneficiary Address that will receive the tokens
    /// @param startTime Start time of the vesting
    /// @param duration Duration of the vesting period
    /// @param amount Total amount of tokens to vest
    /// @param revocable Whether the vesting can be revoked
    /// @return scheduleId The ID of the created vesting schedule
    function createVestingSchedule(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        bool revocable
    ) external returns (bytes32 scheduleId);

    /// @notice Release vested tokens for a schedule
    /// @param scheduleId The ID of the vesting schedule
    /// @return amount The amount of tokens released
    function release(bytes32 scheduleId) external returns (uint256 amount);

    /// @notice Revoke a vesting schedule
    /// @param scheduleId The ID of the vesting schedule
    function revoke(bytes32 scheduleId) external;

    /// @notice Get the vesting schedule information
    /// @param scheduleId The ID of the vesting schedule
    /// @return The vesting schedule information
    function getVestingSchedule(bytes32 scheduleId) external view returns (VestingSchedule memory);

    /// @notice Calculate the vested amount for a schedule
    /// @param scheduleId The ID of the vesting schedule
    /// @return The amount of tokens vested
    function computeVestedAmount(bytes32 scheduleId) external view returns (uint256);

    /// @notice Get all vesting schedules for a beneficiary
    /// @param beneficiary Address to query schedules for
    /// @return Array of schedule IDs
    function getVestingSchedulesByBeneficiary(address beneficiary) external view returns (bytes32[] memory);

    /// @notice Emitted when a vesting schedule is created
    /// @param scheduleId The ID of the created schedule
    /// @param beneficiary Address that will receive the tokens
    /// @param amount Total amount of tokens to vest
    event VestingScheduleCreated(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);

    /// @notice Emitted when tokens are released
    /// @param scheduleId The ID of the vesting schedule
    /// @param beneficiary Address that received the tokens
    /// @param amount Amount of tokens released
    event TokensReleased(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);

    /// @notice Emitted when a vesting schedule is revoked
    /// @param scheduleId The ID of the revoked schedule
    /// @param beneficiary Address that was receiving the tokens
    /// @param refund Amount of tokens returned to owner
    event VestingScheduleRevoked(bytes32 indexed scheduleId, address indexed beneficiary, uint256 refund);
}
