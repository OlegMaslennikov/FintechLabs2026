// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {

    address public owner;

    string public itemName;

    uint256 public highestBid;

    address public highestBidder;

    uint256 public auctionEndTime;

    bool public ended;

    mapping(address => uint256) public bids;

    event NewBid(address indexed bidder, uint256 amount);

    event AuctionFinished(address winner, uint256 amount);

    event Refunded(address indexed bidder, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, unicode"Только владелец может вызвать эту функцию");
        _;
    }

    constructor(string memory _itemName, uint256 _durationInDays) {
        require(bytes(_itemName).length > 0, unicode"Название лота не может быть пустым");
        require(_durationInDays > 0, unicode"Продолжительность аукциона должна быть больше нуля");

        owner = msg.sender;
        itemName = _itemName;
        auctionEndTime = block.timestamp + (_durationInDays * 1 days);
    }

    function bid() external payable {
        require(!ended, unicode"Аукцион уже завершён владельцем");
        require(!isExpired(), unicode"Время аукциона истекло");
        require(msg.value > 0, unicode"Ставка должна быть больше нуля");
        require(msg.value > highestBid, unicode"Ставка должна быть больше текущей максимальной");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function finishAuction() external onlyOwner {
        require(isExpired(), unicode"Аукцион ещё не окончен по времени");
        require(!ended, unicode"Аукцион уже был завершён");

        ended = true;

        uint256 amount = highestBid;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, unicode"Перевод средств владельцу не удался");

        emit AuctionFinished(highestBidder, amount);
    }

    function refund() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0, unicode"Нет средств для возврата");

        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, unicode"Перевод средств участнику не удался");

        emit Refunded(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isExpired() public view returns (bool) {
        return block.timestamp >= auctionEndTime;
    }
    
    receive() external payable {
        revert(unicode"Используйте функцию bid() для участия в аукционе");
    }
}
