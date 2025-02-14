// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVesting.sol";
import "./interfaces/IToken.sol";
import "./libraries/TokenMath.sol";
import "./libraries/StringUtils.sol";

/// @title Token Vesting Contract
/// @notice Manages token vesting schedules with complex calculations
contract Vesting is IVesting {
    using TokenMath for uint256;
    using StringUtils for string;

    // State variables
    IToken public immutable token;
    address public owner;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    mapping(address => bytes32[]) private beneficiarySchedules;

    // Custom errors for gas efficiency
    error Unauthorized();
    error InvalidSchedule();
    error NoTokensVested();
    error TransferFailed();
    error ScheduleNotFound();
    error AlreadyRevoked();
    error NotRevocable();

    // Events for better indexing
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Contract constructor
    /// @param _token Address of the token to vest
    constructor(address _token) {
        if (_token == address(0)) revert InvalidSchedule();
        token = IToken(_token);
        owner = msg.sender;
    }

    /// @notice Modifier to restrict access to owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    /// @notice Transfer ownership of the contract
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidSchedule();
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @inheritdoc IVesting
    function createVestingSchedule(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount,
        bool revocable
    ) external override onlyOwner returns (bytes32 scheduleId) {
        // Input validation
        if (beneficiary == address(0)) revert InvalidSchedule();
        if (duration == 0) revert InvalidSchedule();
        if (amount == 0) revert InvalidSchedule();
        if (startTime < block.timestamp) revert InvalidSchedule();

        // Generate unique schedule ID using assembly
        assembly {
            // Load free memory pointer
            let ptr := mload(0x40)
            
            // Pack data into memory
            mstore(ptr, beneficiary)
            mstore(add(ptr, 32), startTime)
            mstore(add(ptr, 64), duration)
            mstore(add(ptr, 96), amount)
            
            // Calculate keccak256
            scheduleId := keccak256(ptr, 128)
        }

        // Create vesting schedule
        vestingSchedules[scheduleId] = VestingSchedule({
            beneficiary: beneficiary,
            startTime: startTime,
            duration: duration,
            totalAmount: amount,
            releasedAmount: 0,
            revocable: revocable,
            revoked: false
        });

        // Add to beneficiary's schedules
        beneficiarySchedules[beneficiary].push(scheduleId);

        // Transfer tokens to this contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        emit VestingScheduleCreated(scheduleId, beneficiary, amount);
    }

    /// @inheritdoc IVesting
    function release(bytes32 scheduleId) external override returns (uint256 amount) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) revert ScheduleNotFound();
        if (schedule.revoked) revert AlreadyRevoked();

        // Calculate vested amount using TokenMath library
        uint256 vested = TokenMath.calculateLinearVesting(
            schedule.totalAmount,
            schedule.startTime,
            schedule.duration,
            block.timestamp
        );

        // Calculate releasable amount
        amount = vested - schedule.releasedAmount;
        if (amount == 0) revert NoTokensVested();

        // Update released amount
        schedule.releasedAmount += amount;

        // Transfer tokens
        bool success = token.transfer(schedule.beneficiary, amount);
        if (!success) revert TransferFailed();

        emit TokensReleased(scheduleId, schedule.beneficiary, amount);
    }

    /// @inheritdoc IVesting
    function revoke(bytes32 scheduleId) external override onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) revert ScheduleNotFound();
        if (!schedule.revocable) revert NotRevocable();
        if (schedule.revoked) revert AlreadyRevoked();

        // Calculate vested amount
        uint256 vested = TokenMath.calculateLinearVesting(
            schedule.totalAmount,
            schedule.startTime,
            schedule.duration,
            block.timestamp
        );

        // Calculate refund amount
        uint256 refund = schedule.totalAmount - vested;
        schedule.revoked = true;

        // Transfer refund to owner
        if (refund > 0) {
            bool success = token.transfer(owner, refund);
            if (!success) revert TransferFailed();
        }

        emit VestingScheduleRevoked(scheduleId, schedule.beneficiary, refund);
    }

    /// @inheritdoc IVesting
    function getVestingSchedule(bytes32 scheduleId) external view override returns (VestingSchedule memory) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) revert ScheduleNotFound();
        return schedule;
    }

    /// @inheritdoc IVesting
    function computeVestedAmount(bytes32 scheduleId) external view override returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) revert ScheduleNotFound();
        if (schedule.revoked) return schedule.releasedAmount;

        return TokenMath.calculateLinearVesting(
            schedule.totalAmount,
            schedule.startTime,
            schedule.duration,
            block.timestamp
        );
    }

    /// @inheritdoc IVesting
    function getVestingSchedulesByBeneficiary(address beneficiary) external view override returns (bytes32[] memory) {
        return beneficiarySchedules[beneficiary];
    }

    /// @notice Get detailed information about a vesting schedule
    /// @param scheduleId The ID of the vesting schedule
    /// @return info Formatted string with schedule details
    function getScheduleInfo(bytes32 scheduleId) external view returns (string memory info) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        if (schedule.beneficiary == address(0)) revert ScheduleNotFound();

        // Use StringUtils for string manipulation
        info = StringUtils.concat(
            "Schedule: ",
            StringUtils.toUpper(string(StringUtils.hexToBytes(StringUtils.slice(bytes32ToString(scheduleId), 0, 8))))
        );
        info = StringUtils.concat(info, "\nBeneficiary: ");
        info = StringUtils.concat(info, addressToString(schedule.beneficiary));
        info = StringUtils.concat(info, "\nAmount: ");
        info = StringUtils.concat(info, uintToString(schedule.totalAmount));
        info = StringUtils.concat(info, "\nVested: ");
        info = StringUtils.concat(info, uintToString(schedule.releasedAmount));
        info = StringUtils.concat(info, "\nStatus: ");
        info = StringUtils.concat(info, schedule.revoked ? "Revoked" : "Active");
    }

    /// @notice Convert bytes32 to string
    /// @param value The bytes32 value to convert
    /// @return result The string representation
    function bytes32ToString(bytes32 value) internal pure returns (string memory result) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[i*2+1] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    /// @notice Convert address to string
    /// @param value The address to convert
    /// @return result The string representation
    function addressToString(address value) internal pure returns (string memory result) {
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(uint160(value) >> (8 * (19 - i)) >> 4)];
            str[2+i*2+1] = alphabet[uint8(uint160(value) >> (8 * (19 - i)) & 0x0f)];
        }
        return string(str);
    }

    /// @notice Convert uint256 to string
    /// @param value The uint256 to convert
    /// @return result The string representation
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
