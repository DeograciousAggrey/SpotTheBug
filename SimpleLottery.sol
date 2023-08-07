// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract SimpleLottery is VRFConsumerBase {
    address public owner;
    uint256 public ticketPrice;
    uint256 public ticketCount;
    address public winner;
    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(address => uint256) public tickets;

    event TicketPurchased(address indexed player, uint256 tickets);
    event WinnerDrawn(address indexed winner);

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _ticketPrice
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
        ticketPrice = _ticketPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier notWinnerSelected() {
        require(winner == address(0), "Winner already selected");
        _;
    }

    function buyTicket(uint256 numberOfTickets) external payable {
        require(numberOfTickets > 0, "Number of tickets should be greater than 0");
        require(msg.value >= ticketPrice * numberOfTickets, "Not enough ether sent");

        tickets[msg.sender] += numberOfTickets;
        ticketCount += numberOfTickets;

        emit TicketPurchased(msg.sender, numberOfTickets);
    }

    function drawWinner() external onlyOwner notWinnerSelected {
        require(ticketCount > 0, "No tickets purchased yet");

        uint256 randomNum = getRandomNumber();
        winner = address(uint160(address(this))) + (randomNum % ticketCount);

        emit WinnerDrawn(winner);
    }

    function getWinner() external view returns (address) {
        require(winner != address(0), "Winner has not been drawn yet");
        return winner;
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner, LINK.balanceOf(address(this)));
    }

    function withdrawPrize() external onlyOwner {
        require(winner != address(0), "Winner has not been drawn yet");

        uint256 prizeAmount = ticketPrice * ticketCount;
        payable(winner).transfer(prizeAmount);
    }

    function getRandomNumber() internal returns (uint256) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Random number received from Chainlink VRF, but not used in this simplified version.
    }
}
