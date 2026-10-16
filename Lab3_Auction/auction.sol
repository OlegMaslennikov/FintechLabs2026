// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SimpleAuction {
    address public owner;                 
    string public lotName;                
    uint256 public highestBid;            
    address public highestBidder;         
    uint256 public auctionEndTime;        
    bool public ended;                    

    mapping(address => uint256) public bids;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _lotName, uint256 _durationInDays) {
        owner = msg.sender;
        lotName = _lotName;
        auctionEndTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already expired");
        require(!ended, "Auction already finished");
        require(msg.value > 0, "Bid must be greater than zero");
        require(msg.value > highestBid, "There already is a higher bid");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function refund() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds available for refund");

        bids[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Refunded(msg.sender, amount);
    }

    function finishAuction() external {
        require(msg.sender == owner, "Only owner can finish auction");
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        require(!ended, "Auction finish already called");

        ended = true;
        emit AuctionFinished(highestBidder, highestBid);

        if (highestBid > 0) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, "Failed to send ETH to owner");
        }
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}