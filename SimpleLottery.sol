// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/// @title SimpleLottery - A simple lottery contract using Chainlink VRF for randomness.
contract SimpleLottery is VRFConsumerBase {
    address public owner; // Owner of the contract
    uint256 public ticketPrice; // Price per ticket in wei
    uint256 public ticketCount; // Total number of tickets sold
    address public winner; // Address of the winner
    bytes32 internal keyHash; // Chainlink VRF key hash
    uint256 internal fee; // Chainlink VRF fee
    bytes32 internal requestRandomnessId; // Request ID for Chainlink VRF

    mapping(address => uint256) public tickets; // Mapping to store the number of tickets purchased by each player

    event TicketPurchased(address indexed player, uint256 tickets); // Event emitted when tickets are purchased
    event WinnerDrawn(address indexed winner); // Event emitted when the winner is drawn

    /// @dev Initializes the SimpleLottery contract.
    /// @param vrfCoordinator The address of the Chainlink VRF coordinator contract.
    /// @param linkToken The address of the LINK token contract used for payments to Chainlink VRF.
    /// @param _keyHash The Chainlink VRF key hash.
    /// @param _fee The fee required to request randomness from Chainlink VRF.
    /// @param _ticketPrice The price per ticket in wei.
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

    /// @dev Allows players to purchase tickets for the lottery.
    /// @param numberOfTickets The number of tickets to purchase.
    /// @notice The function requires sending enough ether to cover the ticket price multiplied by the number of tickets.
    function buyTicket(uint256 numberOfTickets) external payable {
        require(numberOfTickets > 0, "Number of tickets should be greater than 0");
        require(msg.value >= ticketPrice * numberOfTickets, "Not enough ether sent");

        tickets[msg.sender] += numberOfTickets; // Update the number of tickets purchased by the player
        ticketCount += numberOfTickets; // Increase the total number of tickets sold

        emit TicketPurchased(msg.sender, numberOfTickets);
    }

    /// @dev Draws the winner of the lottery using a random number from Chainlink VRF.
    /// @notice Only the owner of the contract can call this function, and the winner cannot be drawn again.
    function drawWinner() external onlyOwner notWinnerSelected {
        require(ticketCount > 0, "No tickets purchased yet");

        uint256 randomNum = getRandomNumber();
        uint256 winnerIndex = randomNum % ticketCount;
        address[] memory players = new address[](ticketCount);
        uint256 index = 0;

        // Create an array of unique player addresses with tickets
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

    /// @dev Returns the address of the current winner.
    /// @return The address of the winner if the winner has been drawn, otherwise reverts with an error message.
    function getWinner() external view returns (address) {
        require(winner != address(0), "Winner has not been drawn yet");
        return winner;
    }

    /// @dev Allows the owner to withdraw any remaining LINK tokens in the contract.
    function withdrawLink() external onlyOwner {
        LINK.transfer(owner, LINK.balanceOf(address(this))); // Transfer remaining LINK tokens to the owner
    }

    /// @dev Allows the owner to withdraw the prize amount to the winner.
    /// @notice The winner must have been drawn before calling this function.
    function withdrawPrize() external onlyOwner {
        require(winner != address(0), "Winner has not been drawn yet");

        uint256 prizeAmount = ticketPrice * ticketCount; // Calculate the prize amount
        payable(winner).transfer(prizeAmount); // Transfer the prize to the winner
    }

    /// @dev Requests a random number from Chainlink VRF.
    /// @return requestId The request ID generated for the randomness request.
    function getRandomNumber() internal returns (uint256) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        require(keyHash != bytes32(0), "Must have valid keyHash");
        require(ticketCount > 0, "No tickets purchased yet");

        bytes32 requestId = requestRandomness(keyHash, fee); // Request a random number from Chainlink VRF
        requestRandomnessId = requestId; // Save the requestId for verification purposes (not used in this simplified version)
    }

    /// @dev Callback function called by Chainlink VRF to fulfill the randomness request.
    /// @param requestId The request ID generated for the randomness request.
    /// @param randomness The random number generated by Chainlink VRF.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Ensure the request was made by this contract and the random number is not 0
        require(requestId == requestRandomnessId, "Wrong requestId");
        require(randomness > 0, "Random number not generated");

        randomResult = randomness; // Store the random number in the contract
    }

    /// @dev Returns the latest random number generated by Chainlink VRF.
    /// @return The latest random number.
    function getRandomResult() external view returns (uint256) {
        return randomResult;
    }
}
