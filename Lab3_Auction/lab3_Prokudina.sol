// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleAuction {
    address public immutable owner;
    string public lotName;
    uint256 public immutable endTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public finished;

    mapping(address => uint256) public bids;

    uint256 private constant MAX_DURATION_IN_DAYS = 90;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed participant, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier notFinished() {
        require(!finished, "Auction already finished");
        _;
    }

    constructor(string memory _lotName, uint256 _durationInDays) {
        require(_durationInDays > 0, "Duration must be positive");
        require(_durationInDays <= MAX_DURATION_IN_DAYS, "Duration too long");
        require(bytes(_lotName).length > 0, "Lot name required");

        owner = msg.sender;
        lotName = _lotName;
        endTime = block.timestamp + _durationInDays * 1 days;
    }

    function bid() external payable notFinished {
        require(block.timestamp < endTime, "Auction expired");
        require(msg.value > 0, "Bid must be > 0");
        require(msg.value > highestBid, "Bid too low");
        require(msg.sender != highestBidder, "Already highest bidder");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external onlyOwner notFinished {
        require(block.timestamp >= endTime, "Auction not yet ended");

        finished = true;

        if (highestBid > 0) {
            (bool ok, ) = payable(owner).call{value: highestBid}("");
            require(ok, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, highestBid);
    }

    function refund() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "Nothing to refund");
        require(msg.sender != highestBidder, "Leader cannot refund");

        bids[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= endTime;
    }
}
