// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedVotingSystem {
    address public owner;
    string public electionName;
    uint256 public candidatesCount;
    bool public electionStarted;
    bool public electionEnded;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    mapping(uint256 => Candidate) public candidates;

    mapping(address => bool) public hasVoted;

    mapping(address => uint256) public voteTimestamp;
    mapping(address => uint256) public voteBlockHeight;

    event VoteCast(address indexed voter, uint256 indexed candidateId);

    event WinnerAnnounced(string winnerName, uint256 voteCount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier electionNotStarted() {
        require(!electionStarted, "Election has already started");
        _;
    }

    modifier electionInProgress() {
        require(electionStarted && !electionEnded, "Election is not in progress");
        _;
    }

    modifier electionNotEnded() {
        require(!electionEnded, "Election has already ended");
        _;
    }

    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name;
    }

    function addCandidate(string memory _name) public onlyOwner electionNotStarted {
        candidates[candidatesCount] = Candidate(_name, 0);
        candidatesCount++;
    }

    function startElection() public onlyOwner electionNotStarted {
        electionStarted = true;
    }

    function castVote(uint256 _candidateId, address _tokenAddress) public electionInProgress {
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateId < candidatesCount, "Invalid candidate ID");

        IERC20 token = IERC20(_tokenAddress);
        uint256 voterBalance = token.balanceOf(msg.sender);

        require(voterBalance > 0, "Insufficient balance to vote");

        token.transferFrom(msg.sender, address(this), 1);

        hasVoted[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        voteTimestamp[msg.sender] = block.timestamp;
        voteBlockHeight[msg.sender] = block.number;

        emit VoteCast(msg.sender, _candidateId);
    }

    function endElection() public onlyOwner electionNotEnded {
        electionEnded = true;

        uint256 winningVoteCount = 0;
        string memory winningCandidateName;

        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateName = candidates[i].name;
            }
        }

        emit WinnerAnnounced(winningCandidateName, winningVoteCount);
    }

    function viewResults() public view returns (string[] memory, uint256[] memory) {
        string[] memory candidateNames = new string[](candidatesCount);
        uint256[] memory voteCounts = new uint256[](candidatesCount);

        for (uint256 i = 0; i < candidatesCount; i++) {
            candidateNames[i] = candidates[i].name;
            voteCounts[i] = candidates[i].voteCount;
        }

        return (candidateNames, voteCounts);
    }
}
