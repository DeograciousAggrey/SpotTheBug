
pragma solidity 0.8.17;

contract BabyCommitment {
    mapping(address => uint256) public commitments;
    uint256 constant modulus = 891774460845375173125266058974437262797511322331985127;
    uint8 constant gen = 2;
    /**
    
    * TODO: consider to add a random number with secret in commitment scheme
    */
    // For the sake of task, we assume the secret is not visible in the blockchain,
    // and the commit() function is presented to give an understanding of how the commitment is being done 
    function commit(uint256 secret) external {
    
        commitments [msg.sender] = modExp(gen, secret, modulus);
    }

    function reveal (uint256 openingNumber) external returns (bool){
        uint256 commitment = commitments [msg.sender]; 
        require(commitment != 0);
        return modExp(gen, openingNumber, modulus) == commitment;
    }
    
    function modExp(uint256 _b, uint256 _e, uint256 _m) internal returns (uint256 result) { assembly {
    let pointer := mload (0x40)
    mstore(pointer, 0x20)
    mstore(add(pointer, 0x20), 0x20)
    mstore(add(pointer, 0x40), 0x20)
    mstore(add(pointer, 0x60), _b)
    mstore(add(pointer, 0x80), _e)
    mstore(add(pointer, 0xa0), _m)
    let value = mload (0xc0)
    if iszero(call(not(0), 0x05, 0, pointer, 0xc0, value, 0x20)) {
    revert(0, 0)
    result = mload(value)
    }
}
}
}