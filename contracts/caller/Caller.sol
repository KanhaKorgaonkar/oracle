// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Ownable - to implement fucntions that only allow contract owner to call the functions.
import "@openzeppelin-solidity/contracts/access/Ownable.sol";
// IRandOracle - a local contract (interface) that tells Caller.sol how to interact with the oracle contract
import "./IRandOracle.sol";

contract Caller is Ownable {
    // create a variable to reference the oracle contract 
    IRandOracle private randOracle;
    // mapping to track active requests
    mapping(uint256=>bool) requests;
    // mapping to store results
    mapping(uint256=>uint256) results;

   // restrict access to fulfillment function 
    modifier onlyRandOracle() {
        // This is how Oracles work - if this condition as not there, then anyone could submit random numbers to fulfill our requests. Function caller address should be the same as the oracle contract.
        require(msg.sender == address(randOracle), "Unauthorized.");
        _;
    }
    function setRandOracleAddress(address newAddress) external onlyOwner {
        randOracle = IRandOracle(newAddress);
        emit OracleAddressChanged(newAddress);
    }
    
}