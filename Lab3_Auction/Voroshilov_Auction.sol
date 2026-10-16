pragma solidity ^0.8.26;

contract SimpleAuction {
    address public immutable owner;
    string public lotName;

    uint256 public highestBid;
    address public highestBidder;
    uint256 public immutable auctionEndTime;

    bool public ended;

    mapping(address => uint256) public bids;
    mapping(address => uint256) public pendingReturns;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _lotName, uint256 _durationInDays) {
        require(_durationInDays > 0, "Duration must be positive");

        owner = msg.sender;
        lotName = _lotName;
        auctionEndTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() external payable {
        require(!ended, "Auction already finished");
        require(block.timestamp < auctionEndTime, "Auction expired");
        require(msg.value > 0, "Bid must be positive");
        require(msg.value > highestBid, "Bid must exceed highest bid");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        bids[msg.sender] += msg.value;
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external {
        require(msg.sender == owner, "Only owner can finish");
        require(block.timestamp >= auctionEndTime, "Auction still active");
        require(!ended, "Auction already finished");

        ended = true;

        emit AuctionFinished(highestBidder, highestBid);

        if (highestBid > 0) {
            (bool success, ) = payable(owner).call{value: highestBid}("");
            require(success, "Payment to owner failed");
        }
    }

    function refund() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to refund");

        pendingReturns[msg.sender] = 0;

        emit Refunded(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() external view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
}