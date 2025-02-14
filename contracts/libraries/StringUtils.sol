// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title StringUtils Library
/// @notice Advanced string manipulation with Unicode support
library StringUtils {
    /// @notice Custom errors
    error InvalidUTF8();
    error BufferOverflow();
    error InvalidHexString();
    error InvalidInput();

    /// @notice UTF-8 character information
    struct Char {
        bytes raw;    // Raw UTF-8 bytes
        uint256 size; // Number of bytes
    }

    /// @notice Convert string to uppercase
    /// @param str Input string
    /// @return result Uppercase string
    function toUpper(string memory str) internal pure returns (string memory result) {
        bytes memory bStr = bytes(str);
        bytes memory bResult = new bytes(bStr.length);
        
        for (uint256 i = 0; i < bStr.length; i++) {
            // ASCII lowercase letter
            if (bStr[i] >= 0x61 && bStr[i] <= 0x7A) {
                bResult[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bResult[i] = bStr[i];
            }
        }
        
        return string(bResult);
    }

    /// @notice Convert hex string to bytes
    /// @param hexStr Hex string (with or without 0x prefix)
    /// @return result Decoded bytes
    function hexToBytes(string memory hexStr) internal pure returns (bytes memory result) {
        bytes memory bStr = bytes(hexStr);
        uint256 start = 0;
        
        // Skip 0x prefix if present
        if (bStr.length >= 2 && bStr[0] == "0" && (bStr[1] == "x" || bStr[1] == "X")) {
            start = 2;
        }
        
        // Must have even length
        if ((bStr.length - start) % 2 != 0) revert InvalidHexString();
        
        result = new bytes((bStr.length - start) / 2);
        for (uint256 i = 0; i < result.length; i++) {
            uint8 high = _hexDigitToUint8(bStr[start + i * 2]);
            uint8 low = _hexDigitToUint8(bStr[start + i * 2 + 1]);
            result[i] = bytes1((high << 4) | low);
        }
    }

    /// @notice Convert single hex character to uint8
    /// @param c Hex character
    /// @return Value of hex digit
    function _hexDigitToUint8(bytes1 c) private pure returns (uint8) {
        uint8 value = uint8(c);
        if (value >= 48 && value <= 57) return value - 48;  // 0-9
        if (value >= 97 && value <= 102) return value - 87; // a-f
        if (value >= 65 && value <= 70) return value - 55;  // A-F
        revert InvalidHexString();
    }

    /// @notice Get UTF-8 character at index
    /// @param str Input string
    /// @param index Byte index
    /// @return c Character information
    function charAtIndex(string memory str, uint256 index) internal pure returns (Char memory c) {
        bytes memory bStr = bytes(str);
        if (index >= bStr.length) revert InvalidUTF8();
        
        // Get first byte
        uint8 first = uint8(bStr[index]);
        
        // Single byte character (ASCII)
        if (first < 0x80) {
            c.raw = new bytes(1);
            c.raw[0] = bStr[index];
            c.size = 1;
            return c;
        }
        
        // Multi-byte character
        uint256 size;
        if (first >= 0xF0) size = 4;      // 4-byte UTF-8
        else if (first >= 0xE0) size = 3;  // 3-byte UTF-8
        else if (first >= 0xC0) size = 2;  // 2-byte UTF-8
        else revert InvalidUTF8();         // Invalid UTF-8
        
        if (index + size > bStr.length) revert InvalidUTF8();
        
        // Validate continuation bytes
        for (uint256 i = 1; i < size; i++) {
            if ((uint8(bStr[index + i]) & 0xC0) != 0x80) revert InvalidUTF8();
        }
        
        c.raw = new bytes(size);
        for (uint256 i = 0; i < size; i++) {
            c.raw[i] = bStr[index + i];
        }
        c.size = size;
    }

    /// @notice Count UTF-8 characters in string
    /// @param str Input string
    /// @return count Number of UTF-8 characters
    function charCount(string memory str) internal pure returns (uint256 count) {
        bytes memory bStr = bytes(str);
        uint256 i = 0;
        
        while (i < bStr.length) {
            Char memory c = charAtIndex(str, i);
            i += c.size;
            count++;
        }
    }

    /// @notice Concatenate strings with proper UTF-8 handling
    /// @param a First string
    /// @param b Second string
    /// @return result Concatenated string
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        bytes memory bA = bytes(a);
        bytes memory bB = bytes(b);
        
        // Validate UTF-8 encoding of both strings
        uint256 i = 0;
        while (i < bA.length) {
            Char memory c = charAtIndex(a, i);
            i += c.size;
        }
        
        i = 0;
        while (i < bB.length) {
            Char memory c = charAtIndex(b, i);
            i += c.size;
        }
        
        // Concatenate
        bytes memory bResult = new bytes(bA.length + bB.length);
        for (i = 0; i < bA.length; i++) {
            bResult[i] = bA[i];
        }
        for (i = 0; i < bB.length; i++) {
            bResult[bA.length + i] = bB[i];
        }
        
        return string(bResult);
    }

    /// @notice Slice string with UTF-8 character boundaries
    /// @param str Input string
    /// @param start Start character index
    /// @param end End character index (exclusive)
    /// @return result Sliced string
    function slice(
        string memory str,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory result) {
        if (end < start) revert InvalidInput();
        
        bytes memory bStr = bytes(str);
        uint256[] memory charPositions = new uint256[](charCount(str) + 1);
        uint256 pos = 0;
        uint256 charIndex = 0;
        
        // Map character indices to byte positions
        while (pos < bStr.length) {
            charPositions[charIndex] = pos;
            Char memory c = charAtIndex(str, pos);
            pos += c.size;
            charIndex++;
        }
        charPositions[charIndex] = pos;
        
        // Validate indices
        if (end > charIndex) revert InvalidInput();
        
        // Create sliced string
        uint256 sliceStart = charPositions[start];
        uint256 sliceEnd = charPositions[end];
        bytes memory bResult = new bytes(sliceEnd - sliceStart);
        
        for (uint256 i = 0; i < bResult.length; i++) {
            bResult[i] = bStr[sliceStart + i];
        }
        
        return string(bResult);
    }
}
