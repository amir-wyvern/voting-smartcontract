// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HooshimaVoting {

    struct sVoter {
        bytes32 name;
        uint256 countVoting;
        uint256 depositAmnt;
        bool hasProfile;
        bool hasVote;
    }

    struct sVoting {
        uint256 id;
        uint256 minDeposit;
        uint256 totalBalance;
        uint256 totalVoters;
        uint256 endRegisterTime;
        uint256 endVotingTime;
        bool activeID;
    }

    address public owner;
    uint256 private votingID;

    mapping(uint256 => sVoting) public voting;
    mapping(uint256 => mapping(address => sVoter)) public linkVoter;
    mapping(uint256 => mapping(bytes32 => address)) public linkName;
    mapping(uint256 => bytes32[]) public listNames;

    constructor() {
        votingID = 1;
        owner = msg.sender;
    }

    function registerVoting(uint256 minDeposit
                            , uint256 endRegisterTime, uint256 endVotingTime ) public {

        require(!voting[votingID].activeID , "this is ID exisy already !");
        require(block.timestamp < endRegisterTime ,"endRegisterTime must be older than currentTime !");
        require(endRegisterTime < endVotingTime ,"endVotingTime must be older than endRegisterTime !");
        votingID += 1;
        voting[votingID] = sVoting(votingID ,minDeposit ,0 ,0 ,endRegisterTime ,endVotingTime ,true);
    }

    function deposit(uint256 _id ,bytes32 _name) public payable {

        require(linkName[_id][_name] == address(0x0000000000000000000000000000000000000000000000000000000000000000) ,"this name already taken by another user !"); 
        require(block.timestamp < voting[_id].endRegisterTime ,"deposit is disable,is late for that");
        require(!linkVoter[_id][msg.sender].hasProfile
            ,"you have profile already in this voting !");

        linkName[_id][_name] = msg.sender;
        
        listNames[_id].push(_name);
        voting[_id].totalVoters += 1;
        linkVoter[_id][msg.sender] = sVoter(_name ,0 ,msg.value ,true ,false);
        voting[_id].totalBalance += msg.value;
        
    }

    function submitVote(uint256 _id,bytes32 name) public {

        require(block.timestamp < voting[_id].endVotingTime ,"time voting is finished !");
        require(block.timestamp > voting[_id].endRegisterTime ,"time voting is not start yet !");
        require(!linkVoter[_id][msg.sender].hasVote ,"you had voted to voting session!");

        address addrName ;
        linkVoter[_id][msg.sender].hasVote = true;
        addrName = linkName[_id][name];
        linkVoter[_id][addrName].countVoting += 1;
    }

    function clearVote(uint256 _id ,bytes32 name) public {
        require(block.timestamp < voting[_id].endVotingTime ,"time voting is finished !");
        require(block.timestamp > voting[_id].endRegisterTime ,"time voting is not start yet !");
        require(linkVoter[_id][msg.sender].hasVote ,"you haven't vote in voting!");

        address addrName ;
        addrName = linkName[_id][name];
        linkVoter[_id][msg.sender].hasVote = false;
        linkVoter[_id][addrName].countVoting -= 1;
    } 

    function getListNameFromID(uint256 _id ) public view returns(bytes32[] memory) {
        return listNames[_id];
    }

    function withdraw(uint256 _id) public payable {
        uint256 amnt;
        amnt = linkVoter[_id][msg.sender].countVoting / voting[_id].totalVoters * voting[_id].totalBalance;
        payable(address(msg.sender)).transfer(amnt);
    }
} 
