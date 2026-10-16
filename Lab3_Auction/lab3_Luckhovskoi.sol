
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {
    address payable public auctionOwner;
    string public product;
    uint256 public currentBid;
    address public currentWinner;
    uint256 public auctionDeadline;
    bool public auctionClosed;

    mapping(address => uint256) public userBids;
    mapping(address => uint256) public refunds;

    event BidPlaced(address indexed bidder, uint256 value);
    event AuctionClosed(address indexed winner, uint256 value);
    event RefundIssued(address indexed bidder, uint256 value);

    constructor(string memory _product, uint256 _durationDays) {
        require(bytes(_product).length != 0, "Product name required");
        require(_durationDays != 0, "Invalid duration");

        auctionOwner = payable(msg.sender);
        product = _product;
        auctionDeadline = block.timestamp + (_durationDays * 1 days);
    }

    function placeBid() external payable {
        require(block.timestamp < auctionDeadline, "Auction expired");
        require(!auctionClosed, "Auction is closed");
        require(msg.sender != auctionOwner, "Owner cannot participate");
        require(msg.value > currentBid, "Bid is too low");

        address previousWinner = currentWinner;

        if (previousWinner != address(0)) {
            refunds[previousWinner] += currentBid;
        }

        userBids[msg.sender] = msg.value;
        currentWinner = msg.sender;
        currentBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function closeAuction() external {
        require(msg.sender == auctionOwner, "Not auction owner");
        require(block.timestamp >= auctionDeadline, "Auction still active");
        require(!auctionClosed, "Already closed");

        auctionClosed = true;

        uint256 winningAmount = currentBid;

        emit AuctionClosed(currentWinner, winningAmount);

        if (winningAmount != 0) {
            (bool sent, ) = auctionOwner.call{value: winningAmount}("");
            require(sent, "Payment failed");
        }
    }

    function withdrawRefund() external {
        uint256 refundAmount = refunds[msg.sender];

        require(refundAmount > 0, "No refund available");

        refunds[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: refundAmount}("");
        require(sent, "Refund transfer failed");

        emit RefundIssued(msg.sender, refundAmount);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function hasExpired() public view returns (bool) {
        return block.timestamp >= auctionDeadline;
    }
}

