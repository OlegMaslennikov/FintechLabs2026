// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PrizeFinder {

    address[] public participants;
    uint[] public scores;

    function addParticipant(address _participant, uint _score) public {
        participants.push(_participant);
        scores.push(_score);
    }

    function findWinners(uint minScore)
        public
        view
        returns (address[] memory, uint[] memory)
    {
        uint count = 0;
        for (uint i = 0; i < participants.length; i++) {
            if (scores[i] >= minScore) {
                count++;
            }
        }

        address[] memory winnerAddresses = new address[](count);
        uint[] memory winnerScores = new uint[](count);

        uint j = 0;
        for (uint i = 0; i < participants.length; i++) {
            if (scores[i] >= minScore) {
                winnerAddresses[j] = participants[i];
                winnerScores[j] = scores[i];
                j++;
            }
        }

        return (winnerAddresses, winnerScores);
    }

    function getParticipantsCount() public view returns (uint) {
        return participants.length;
    }
}