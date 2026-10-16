// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleAuction {
    address private  immutable owner;
    string public lotName;
    uint256 public immutable auctionEndTime;
    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public bids;
    bool public ended;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _lotName, uint256 _biddingTimeDays) {
        owner = msg.sender;
        lotName = _lotName;
        auctionEndTime = block.timestamp + (_biddingTimeDays * 1 days);
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(msg.value > highestBid, "Bid not high enough");
        require(msg.value > 0, "Bid must be > 0");

        if (highestBidder != address(0) && highestBidder != msg.sender) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function refund() public {
        require(bids[msg.sender] > 0, "No funds to refund");

        uint256 amount = bids[msg.sender];
        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function finishAuction() public {
        require(msg.sender == owner, "Only owner can finish");
        require(block.timestamp >= auctionEndTime, "Auction not ended yet");
        require(!ended, "Auction already finished");

        ended = true;

        if (highestBid > 0) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, highestBid);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
}