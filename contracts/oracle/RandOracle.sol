// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import AccessControl - for role based access control. 
import "@openzeppelin/contracts/access/AccessControl.sol";
// import the caller interface.
import "./ICaller.sol";

contract RandOracle is AccessControl {
    // DEFINE A NAME FOR OUR DATA PROVIDER ROLE 
    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    // COUNT THE NUMBER OF DATA PROVIDERS. 
    uint private numProviders = 0;
    // DEFINE THE MINIMUM NUMBER OF PROVIDER RESPONSES TO FULFILL A REQUEST.
    uint private providersThreshold = 1;

    // Number we use to generate request IDs. This is a counter that we increment everytime requestRandomNumber() is called. 
    uint private randNonce = 0;
    // mapping of pending requests
    mapping(uint256=>bool) private pendingRequests;
    // struct to store key details of each random number we receive from the data providers.
    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }
    //  MAPPING OF REQUEST IDs to ARRAYS of RESPONSE STRUCTS. 
    mapping(uint256=>Response[]) private idToResponses;
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // make the deployer admin.
    }
    
    function requestRandomNumber() external returns (uint256) {
        
        require(numProviders > 0, " No data providers added yet.");
        // generate an id
        randNonce++;
        uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
        // add that id to pending requests
        pendingRequests[id] = true;
        // emit event
        emit RandomNumberRequested(msg.sender, id);
        return id;
    }

    function returnRandomNumber(uint256 randomNumber, address callerAddress, uint256 id) external onlyRole(PROVIDER_ROLE) {
        // you need an unfulfilled request first to return a random number.
        require(pendingRequests[id], "Request not found.");
        // Add newest response to the list
        Response memory res = Response(msg.sender, callerAddress, randomNumber);
        idToResponses[id].push(res);
        // store length of the array to compare for threshold
        uint numResponses = idToResponses[id].length;

        // check if we've got enough respones:
        if (numResponses == providersThreshold){
            uint compositeRandomNumber = 0;

            // Loop through the array and combine responses. 
            for (uint i=0; i<idToResponses[id].length; i++) {
                compositeRandomNumber = compositeRandomNumber ^ idToResponses[id][i].randomNumber; // bitwise XOR   
            }

            // cleanup
            delete pendingRequests[id];
            delete idToResponses[id];
            // fulfill request 
            ICaller(callerAddress).fulfillRandomNumberRequest(compositeRandomNumber, id);
            emit RandomNumberReturned(compositeRandomNumber, callerAddress, id);
        }
    }

    function addProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // duplication check
        require(!hasRole(PROVIDER_ROLE, provider), "Provider already added.");
        // assign providerrole to address
        _grantRole(PROVIDER_ROLE, provider);
        numProviders;
        emit ProviderAdded(provider);
    }

    function removeProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(PROVIDER_ROLE, provider), "Address is not a recognized provider.");
        require (numProviders>1, "Cannot remove the only provider.");
        _revokeRole(PROVIDER_ROLE, provider);
        numProviders--;
        emit ProviderRemoved(provider);
    }

    function setProvidersThereshold(uint threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(threshold > 0, "Threshold cannot be zero.");
        providersThreshold = threshold;
        emit ProvidersThresholdChanged(providersThreshold);
    }

    event RandomNumberRequested(address callerAddress, uint id);
    event RandomNumberReturned(uint256 randomNumber, address callerAddress, uint id);
    event ProviderAdded(address providerAddress);
    event ProviderRemoved(address providerAddress);
    event ProvidersThresholdChanged(uint threshold);
}