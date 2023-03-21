// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRandOracle {
    function requestRandomNumber() external returns (uint256);
}