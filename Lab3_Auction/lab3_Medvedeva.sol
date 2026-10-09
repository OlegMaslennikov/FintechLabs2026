// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {
    address public immutable auctioneer;
    string public lotName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public auctionEndTime;
    bool public isFinished;

    mapping(address => uint256) public pendingReturns;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address winner, uint256 highestBid);
    event Refunded(address indexed bidder, uint256 amount);

    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Only auctioneer can call this");
        _;
    }

    constructor(string memory _lotName, uint256 _durationInDays) {
        auctioneer = msg.sender;
        lotName = _lotName;
        auctionEndTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(!isFinished, "Auction is already finished");
        require(msg.value > 0, "Bid must be greater than zero");
        require(msg.value > highestBid, "There already is a higher bid");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external onlyAuctioneer {
        require(block.timestamp >= auctionEndTime, "Auction time not expired yet");
        require(!isFinished, "finishAuction has already been called");

        isFinished = true;
        emit AuctionFinished(highestBidder, highestBid);

        if (highestBid > 0) {
            (bool success, ) = payable(auctioneer).call{value: highestBid}("");
            require(success, "Transfer to auctioneer failed");
        }
    }

    function refund() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to refund");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund transfer failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
}
