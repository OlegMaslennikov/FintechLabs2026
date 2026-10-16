pragma solidity ^0.8.20;

contract PrizeFinder {
    address[] public participants;
    uint[] public scores;

    function addParticipant(address participant, uint score) public {
        participants.push(participant);
        scores.push(score);
    }

    function findWinners(uint minScore)
        public
        view
        returns (address[] memory, uint[] memory)
    {
        uint winnersCount = 0;

        for (uint i = 0; i < scores.length; i++) {
            if (scores[i] >= minScore) {
                winnersCount++;
            }
        }

        address[] memory winners = new address[](winnersCount);
        uint[] memory winnerScores = new uint[](winnersCount);

        uint index = 0;

        for (uint i = 0; i < scores.length; i++) {
            if (scores[i] >= minScore) {
                winners[index] = participants[i];
                winnerScores[index] = scores[i];
                index++;
            }
        }

        return (winners, winnerScores);
    }
}