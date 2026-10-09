// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {
    address payable public owner;
    string public lotName;

    uint256 public endTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public finished;

    mapping(address => uint256) public bids;

    mapping(address => uint256) public refunds;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed participant, uint256 amount);

    constructor(string memory _lotName, uint256 _durationInDays) {
        require(_durationInDays > 0, "Duration must be > 0");

        owner = payable(msg.sender);
        lotName = _lotName;
        endTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Auction already ended");
        require(!finished, "Auction already finished");
        require(msg.value > 0, "Bid must be > 0");
        require(msg.value > highestBid, "Bid is not high enough");

        if (highestBidder != address(0)) {
            refunds[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        bids[msg.sender] = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external {
        require(msg.sender == owner, "Only owner can finish");
        require(block.timestamp >= endTime, "Auction is not ended yet");
        require(!finished, "Auction already finished");

        finished = true;

        uint256 amount = highestBid;

        if (amount > 0) {
            (bool success, ) = owner.call{value: amount}("");
            require(success, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, amount);
    }

    function refund() external {
        uint256 amount = refunds[msg.sender];
        require(amount > 0, "Nothing to refund");

        refunds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= endTime;
    }
}
