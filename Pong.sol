pragma solidity >= 0.6.0;

pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

abstract contract WakeInterface {
    function call() external virtual;
}

abstract contract PingInterface {
    function ping() external virtual;
}

contract PongContract {
    // Owner of contract
    uint256 _owner;
    // Contracts that required to wake
    mapping(uint256 => address) contractsToWake;
    // Required grams amount to wake contract
    uint256 REQUIRED_GRAMS;
    // Ping Pong??
    address ping;
    uint256 pingPK;
    bool pingPong;

    // Error codes
    uint8 CANNOT_SET_THIS_TIME = 101;
    uint8 ALREADY_TAKEN        = 102;
    uint8 NOT_ENOUGH_GRAMS     = 103;
    uint8 TOO_EARLY_TO_WAKE_UP = 104;
    uint8 NOT_PING             = 105;
    uint8 NOT_OWNER            = 106;

    constructor(uint256 requiredGrams, address pingAddress, bool toPongOrNotToPong) public {
        tvm.accept();
        _owner = msg.pubkey();
        REQUIRED_GRAMS = requiredGrams;
        ping = pingAddress;
        pingPong = toPongOrNotToPong;
    }

    modifier onlyOwner {
        require(msg.pubkey() == _owner, NOT_OWNER);
        tvm.accept();
        _;
    }

    modifier onlyPing {
        require(msg.pubkey() == pingPK || msg.pubkey() == _owner, NOT_PING);
        tvm.accept();
        _;
    }

    function setPing(address newPing, uint256 pk) onlyOwner external {
        ping = newPing;
        pingPK = pk;
    }

    // function request Timer to call contract
    function requestToWake(uint256 time, address contractToWake) external returns(bool) {
        // Time cannot be less than now
        require(time > now, CANNOT_SET_THIS_TIME);
        // There must be free space at requested time
        require(contractsToWake[time] == address.makeAddrNone(), ALREADY_TAKEN);
        // There must be enough grams sent to add contract to shedule
        require(msg.value >= REQUIRED_GRAMS, NOT_ENOUGH_GRAMS);
        tvm.accept();
        contractsToWake[time] = contractToWake;
        return true;
    }

    // Function to receive ping-pong messages
    function pong() onlyPing external {
        // get minimal time
        optional(uint256, address) minTime = contractsToWake.min();
        // while tere are contracts to wake
        while(minTime.hasValue()) {
            // get value from it
            (uint256 time, address cont) = minTime.get();
            // check if it is time to wake up contracts
            if (time > now)
                break;
            // call contract if it is time
            WakeInterface(cont).call();
            // delete contract from shedule
            contractsToWake.delMin();
            // get the next contract
            minTime = contractsToWake.min();
        }
        PingInterface(ping).ping();
    }
}
