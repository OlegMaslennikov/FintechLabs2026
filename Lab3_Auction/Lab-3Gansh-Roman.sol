pragma solidity ^0.8.0;

contract SimpleAuction {
    address public owner;
    string public lotName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public endTime;
    bool public finished;

    mapping(address => uint256) public bids;
    mapping(address => uint256) public pendingReturns;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed participant, uint256 amount);

    constructor(string memory _lotName, uint256 _durationDays) {
        owner = msg.sender;
        lotName = _lotName;
        endTime = block.timestamp + (_durationDays * 1 days);
    }

    function bid() external payable {
        require(!isExpired(), "Auction ended");
        require(msg.value > 0, "Bid must be > 0");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        bids[msg.sender] = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external {
        require(msg.sender == owner, "Not owner");
        require(isExpired(), "Not expired");
        require(!finished, "Already finished");

        finished = true;

        (bool success, ) = payable(owner).call{value: highestBid}("");
        require(success, "Transfer failed");

        emit AuctionFinished(highestBidder, highestBid);
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