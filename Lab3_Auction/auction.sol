// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Auction{
    address public owner;
    string public lotTitle;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public auctionEndTime;
    bool public ended;
    mapping(address => uint256) public bids;
    
    event NewBid(address bidder, uint256 amount);
    event AuctionFinished(address bidder, uint256 amount);
    event Refunded(address bidder, uint256 amount);

    constructor(string memory _lotTitle, uint256 _durationInDays) {
    owner = msg.sender;
    lotTitle = _lotTitle;
    auctionEndTime = block.timestamp + (_durationInDays * 1 days);
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function isExpired() public view returns (bool){
        return block.timestamp >= auctionEndTime;
    }

    function bid() public payable {
        require(msg.value > 0, unicode"Ставка должа быть больше 0");
        require(msg.value > highestBid, unicode"Уже есть более высокая ставка");
        require(!isExpired(), unicode"Аукцион закончился");
        require(!ended, unicode"Аукцион уже завершился");

         if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewBid(msg.sender, msg.value);
        }

    function refund() public {
        uint256 amount = bids[msg.sender];
        require(amount > 0, unicode"Средства для возврата отсутствуют");
        bids[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, unicode"Произошла ошибка при предаче");
        emit Refunded(msg.sender, amount);
    }
    
    function finishAuction() public {
        require(msg.sender == owner, unicode"Только владелец может завершить аукцион");
        require(isExpired(), unicode"Время аукциона еще не истекло");
        require(!ended, unicode"Аукцион уже завершен");

        ended = true;

        if (highestBid > 0) {
            (bool success, ) = owner.call{value: highestBid}("");
            require(success, unicode"Ошибка при переводе средств владельцу");
        }
        emit AuctionFinished(highestBidder, highestBid);
    }
}