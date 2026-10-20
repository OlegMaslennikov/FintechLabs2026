pragma solidity ^0.8.20;

contract SimpleAuction {

    address public owner;
    string public lotName;
    uint256 public endTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public finished;

    mapping(address => uint256) public bids;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinished(address indexed winner, uint256 amount);
    event Refunded(address indexed participant, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(string memory _lotName, uint256 _days) {
        require(_days > 0, "Duration must be > 0");
        owner = msg.sender;
        lotName = _lotName;
        endTime = block.timestamp + _days * 1 days;
    }


    function bid() external payable {
        require(!isExpired(), "Auction already ended");
        require(!finished, "Auction already finished");
        require(msg.value > 0, "Bid must be > 0");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

    
        highestBidder = msg.sender;
        highestBid = msg.value;

        bids[msg.sender] += msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    
    
    function finishAuction() external onlyOwner {
        require(isExpired(), "Auction not yet ended");
        require(!finished, "Auction already finished");

        finished = true;

        uint256 amount = highestBid;

        if (amount > 0) {
            (bool ok, ) = payable(owner).call{value: amount}("");
            require(ok, "Transfer to owner failed");
        }

        emit AuctionFinished(highestBidder, amount);
    }

    function refund() external {
        require(!isExpired() || finished, "Auction still running");
        require(msg.sender != highestBidder, "Highest bidder cannot refund");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "Nothing to refund");

        bids[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Refund failed");

        emit Refunded(msg.sender, amount);
    }

  

    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= endTime;
    }
}