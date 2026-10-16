pragma solidity ^0.8.0;

contract SimpleAuction {
    address payable public owner;
    string public itemName;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public auctionEndTime;
    bool public ended;

    mapping(address => uint256) public pendingReturns;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address winner, uint256 amount);
    event Refunded(address indexed bidder, uint256 amount);

    constructor(string memory _itemName, uint256 _durationDays) {
        owner = payable(msg.sender);
        itemName = _itemName;
        auctionEndTime = block.timestamp + (_durationDays * 1 days);
    }

    function bid() public payable {
        require(!isExpired(), "Auction already ended");
        require(msg.value > 0, "Bid must be greater than zero");
        require(msg.value > highestBid, "There already is a higher bid");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() public {
        require(msg.sender == owner, "Only owner can finish the auction");
        require(isExpired(), "Auction not yet ended");
        require(!ended, "Auction finish already called");

        ended = true;
        emit AuctionFinished(highestBidder, highestBid);

        if (highestBid > 0) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, "Transfer failed");
        }
    }

    function refund() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to refund");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Refunded(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
}
