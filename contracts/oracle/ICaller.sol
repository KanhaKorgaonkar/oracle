// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICaller {
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external;
}