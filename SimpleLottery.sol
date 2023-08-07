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
    bytes32 internal requestRandomnessId;

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
        uint256 winnerIndex = randomNum % ticketCount;
        address[] memory players = new address[](ticketCount);
        uint256 index = 0;

        // Create an array of unique player addresses
        for (uint256 i = 0; i < ticketCount; i++) {
            if (tickets[address(this)] > 0) {
                players[index] = address(this);
                index++;
            }
        }

        // Select the winner address from the array using the random index
        winner = players[winnerIndex];

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
        require(keyHash != bytes32(0), "Must have valid keyHash");
        require(ticketCount > 0, "No tickets purchased yet");

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestRandomnessId = requestId; // Save the requestId for verification purposes (not used in this simplified version)
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Ensure the request was made by this contract and the random number is not 0
        require(requestId == requestRandomnessId, "Wrong requestId");
        require(randomness > 0, "Random number not generated");

        randomResult = randomness;
    }

    // Add a getter function for retrieving the randomResult
    function getRandomResult() external view returns (uint256) {
        return randomResult;
    }
}
