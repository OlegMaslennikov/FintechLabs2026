// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {
    address payable public owner;
    string public itemName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public endTime;
    bool public ended;

    mapping(address => uint256) public bids;

    mapping(address => uint256) public pendingReturns;

    event NewBid(address indexed bidder, uint256 amount);

    event AuctionFinished(address indexed winner, uint256 amount);


    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _itemName, uint256 _durationDays) {

        require(bytes(_itemName).length > 0, "Item name is empty");

        require(_durationDays > 0, "Duration must be > 0");

        owner = payable(msg.sender);

        itemName = _itemName;

        endTime = block.timestamp + _durationDays * 1 days;
    }

    function bid() external payable {
        require(!isExpired(), "Auction already expired");

        require(!ended, "Auction already finished");

        require(msg.sender != owner, "Owner cannot bid");

        require(msg.value > 0, "Bid must be > 0");

        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        bids[msg.sender] = msg.value;

        highestBidder = msg.sender;

        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external {
        require(msg.sender == owner, "Only owner can finish auction");

        require(isExpired(), "Auction is not expired yet");

        require(!ended, "Auction already finished");

        ended = true;

        uint256 amount = highestBid;

        emit AuctionFinished(highestBidder, amount);

        if (amount > 0) {

            (bool success, ) = owner.call{value: amount}("");

            require(success, "Transfer to owner failed");
        }
    }

    function refund() external {
        uint256 amount = pendingReturns[msg.sender];

        require(amount > 0, "Nothing to refund");

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
