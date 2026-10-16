// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAuction {
    address public owner;
    string public lotName;
    uint256 public endTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public finished;

    mapping(address => uint256) public bids;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _lotName, uint256 _durationInDays) {
        owner = msg.sender;
        lotName = _lotName;
        endTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() public payable {
        require(!isExpired(), "Auction already expired");
        require(!finished, "Auction already finished");
        require(msg.value > 0, "Bid must be greater than zero");
        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        bids[msg.sender] += msg.value;

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() public {
        require(msg.sender == owner, "Only owner can finish auction");
        require(isExpired(), "Auction not yet expired");
        require(!finished, "Auction already finished");

        finished = true;

        if (highestBidder != address(0)) {
            (bool success, ) = payable(owner).call{value: highestBid}("");
            require(success, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, highestBid);
    }

    function refund() public {
        require(finished, "Auction not finished yet");
        require(msg.sender != highestBidder, "Highest bidder cannot refund");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "Nothing to refund");

        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= endTime;
    }
}