 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {

    address payable public owner;
    string public lotName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public endTime;
    bool public finished;

    struct BidInfo {
        uint256 lastBid;
        uint256 bidCount;
    }

    mapping(address => BidInfo) public bids;
    mapping(address => uint256) public pendingReturns;

    event NewBid(address bidder, uint256 amount);
    event AuctionFinished(address winner, uint256 amount);
    event Refunded(address bidder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can finish");
        _;
    }

    constructor(string memory _lotName, uint256 _durationDays) {
        require(_durationDays > 0, "Invalid duration");

        owner = payable(msg.sender);
        lotName = _lotName;
        endTime = block.timestamp + _durationDays * 1 days;
        finished = false;
    }

    function bid() external payable {
        require(!finished, "Auction finished");
        require(!isExpired(), "Time expired");
        require(msg.value > 0, "Zero bid");
        require(msg.value > highestBid, "Bid is too small");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        BidInfo storage participant = bids[msg.sender];

        participant.lastBid = msg.value;
        participant.bidCount++;

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external onlyOwner {
        require(isExpired(), "Auction is still active");
        require(!finished, "Already finished");

        finished = true;

        if (highestBid > 0) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, "Transfer failed");
        }

        emit AuctionFinished(highestBidder, highestBid);
    }

    function refund() external {
        uint256 amount = pendingReturns[msg.sender];

        require(amount != 0, "Nothing to refund");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= endTime;
    }
}
