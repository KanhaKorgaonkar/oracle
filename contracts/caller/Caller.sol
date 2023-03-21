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
    // Set the address of the oracle contract.
    function setRandOracleAddress(address newAddress) external onlyOwner {
        // create an instance of iRANDOracle interface with an address that's provided
        randOracle = IRandOracle(newAddress);
   // event emited to let users know that a change has been made to the contract (for transparency)
        emit OracleAddressChanged(newAddress);
        // 
    }

    function getRandomNumber() external {
        // condition which requires that address of randOracle is not equal to null address (address of uninitialized contract references).
        require(randOracle != IRandOracle(address(0)), "Oracle not initialized." );
        // Call requestRandomNumber() which from IRandOracle which returns a request ID. 
        uint256 id = randOracle.requestRandomNumber();
        // mark id as valid in requests mapping.
        requests[id] = true;
        // emit an event to show that a random number has been requested.
        emit RandomNumberRequested(id);
        
    }

    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external onlyRandOracle {
        // requires requestID. 
        require(requests[id], "Request is invalid or already fulfilled.");
        // stores the randomnumber in the result mapping 
        results[id] = randomNumber;
        // delete the request ID after the request has been fulfilled.
        delete requests[id];
        // emit an event to announce that the request has been fulfilled.
        emit RandomNumberReceived(randomNumber, id);
        
    }
    
    event OracleAddressChanged(address oracleAddress);
    event RandomNumberRequested(uint256 id);
    event RandomNumberReceived(uint256 number, uint256 id);
}