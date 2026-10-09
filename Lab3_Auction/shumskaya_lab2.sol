// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {
    address public owner;
    string public lotName;
    uint256 public endTime;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionFinished;
    mapping(address => uint256) public bids;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can use this function");
        _;
    }
    modifier notFinished() {
        require(!auctionFinished, "Auction already finished");
        _;
    }
    constructor(string memory _lotName, uint256 _durationInDays) {
        require(_durationInDays > 0,"Duration must be greater than zero");
        owner = msg.sender;
        lotName = _lotName;
        endTime = block.timestamp + (_durationInDays * 1 days);
        auctionFinished = false;

    }
    function bid() external payable notFinished{
        require(block.timestamp < endTime, "Auction has expired");
        require(msg.value > 0, "Bid must be more than zero");
        require(msg.value > highestBid, "There is highest bid");

        if (highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }
        
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit NewBid(msg.sender, msg.value);

    }
    function finishAuction() external onlyOwner notFinished {
        require(block.timestamp >= endTime, "Auction has not finished");

        auctionFinished = true;

        
        if (highestBidder != address(0)) {
        (bool success, ) = payable(owner).call{value: highestBid}("");
        require(success, "Transfer to owner failed");
        } 
        emit AuctionFinished(highestBidder, highestBid);
    }

    function refund() external notFinished{
        uint256 amount = bids[msg.sender];
        require(amount > 0, "There is nothing to refund");
        bids[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount} ("");
        require(success,"Refund failed");

        emit Refunded(msg.sender, amount);
    }
    
    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
    function isExpired() external view returns(bool) {
        return block.timestamp >= endTime;
    }
}
