pragma solidity >= 0.6.0;

pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

abstract contract PongInterface {
    function pong() external virtual;
}

contract TimerContract {
    // Owner of contract
    uint256 _owner;

    // Pong contract
    address pong;
    uint256 pongPK;

    // Do i need to pong?
    bool pingPong;

    // Errors
    uint8 NOT_PONG = 101;
    uint8 NOT_OWNER = 102;

    constructor(address pongContract, bool toPingOrNotToPing) public {
        tvm.accept();
        _owner = msg.pubkey();
        pong = pongContract;
        pingPong = toPingOrNotToPing;
    }

    modifier onlyPong {
        require(msg.pubkey() == pongPK || msg.pubkey() == _owner, NOT_PONG);
        tvm.accept();
        _;
    }

    modifier onlyOwner {
        require(msg.pubkey() == _owner, NOT_OWNER);
        tvm.accept();
        _;
    }

    function ping() onlyPong external {
        if (pingPong) {
            PongInterface(pong).pong();
        }
    }

    function setPong(address newPong, uint256 PK) onlyOwner external {
        pong = newPong;
        pongPK = PK;
    }

    function setActiveState(bool toPingOrNotToPing) onlyOwner external {
        pingPong = toPingOrNotToPing;
    }
}