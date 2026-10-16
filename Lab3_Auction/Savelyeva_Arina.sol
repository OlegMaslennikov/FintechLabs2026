// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleAuction {
    address public owner;
    string public lotName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public auctionEndTime;
    mapping(address => uint256) public bids;
    bool public finished;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed participant, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier notExpired() {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        _;
    }

    modifier expired() {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        _;
    }

    constructor(string memory _lotName, uint256 _durationInDays) {
        require(_durationInDays > 0, "Duration must be greater than 0");

        owner = msg.sender;
        lotName = _lotName;
        auctionEndTime = block.timestamp + (_durationInDays * 1 days);
        finished = false;
    }

    function bid() external payable notExpired {
        require(!finished, "Auction already finished");
        require(msg.value > 0, "Bid must be greater than 0");
        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        bids[msg.sender] += msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external onlyOwner expired {
        require(!finished, "Auction already finished");

        finished = true;

        if (highestBidder != address(0)) {
            (bool success, ) = payable(owner).call{value: highestBid}("");
            require(success, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, highestBid);
    }

    function refund() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "Nothing to refund");
        require(msg.sender != highestBidder, "Highest bidder cannot refund");

        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
}