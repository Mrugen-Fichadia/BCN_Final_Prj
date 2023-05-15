// SPDX-License-Identifier: UNLICENSED
// Group-5
pragma solidity ^0.8.0;

contract CrowdFunding {
    
    struct Campaign{
        string title;
        address payable owner;
        uint256 targetAmount;
        uint256 collectedAmount;
        address payable[] donators;
        uint256[] donation;
        uint256 sentAmount;
        address[] voters;
        string[] proof;
        uint8[] votes;
        string desc;
        bool f;
    }

    address intermediateAccount = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    event log(uint add);
    //event log1(address add);

    uint256 public numberOfCampaigns = 0;

    mapping (uint256 => Campaign) public campaigns;

    function createCampaign(address payable _owner, string memory _title, string memory _desc, uint256 _targetAmount) public returns (uint256) {
        Campaign storage camp = campaigns[numberOfCampaigns];

        camp.owner = _owner;
        camp.title = _title;
        camp.desc = _desc;
        camp.collectedAmount = 0;
        camp.targetAmount = _targetAmount;
        camp.sentAmount = 0;
        camp.f = true;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }


    function getCampaignList() public view returns (Campaign[] memory) {
        Campaign[] memory camp = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i<numberOfCampaigns; i++) {
            Campaign storage tmp = campaigns[i];
            camp[i] = tmp;
        }

        return camp;
    }

    function getDonators(uint256 _id) view public returns (address payable[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donation);
    }

    function voteIsCampaignGenuine(uint256 _id, string memory _proof, uint8 _vote) public returns (uint) {
        Campaign storage camp = campaigns[_id];
        bool f=true;
        for(uint i=0; i<camp.voters.length; i++){
            if(msg.sender == camp.voters[i]){
                f=false;
            }
        }
        require(f, "multiple voting not allowed!!");
        camp.voters.push(msg.sender);
        camp.votes.push(_vote);
        camp.proof.push(_proof);

        return processVotes(_id);
        // 1 = transfer to owner
        // 2 = return to donators
        // 0 = wait for more votes
    }

    function donate(uint256 _id) public payable {
        Campaign storage camp = campaigns[_id];

        camp.donators.push(payable(msg.sender));
        camp.donation.push(msg.value);

        emit log(msg.value);

        (bool sent, ) = payable(intermediateAccount).call{value: msg.value}("");

        if(sent){
            camp.collectedAmount = camp.collectedAmount + msg.value;
        }
    }

    function amountCalculator(uint256 _id) public returns (uint256) {

        require(processVotes(_id) == 1 || processVotes(_id) == 3 , "Not able to transfer now...");

        Campaign storage camp = campaigns[_id];
        uint randNonce = 0;
        if(camp.sentAmount == 0){
            uint256 rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % (camp.collectedAmount/4);
            rand += camp.collectedAmount/5;
            return rand;

        }else if(processVotes(_id) == 3 && camp.targetAmount*1000000000000000000>camp.sentAmount){
            
            return camp.collectedAmount-camp.sentAmount;
            //emit log(amt);
            //emit log(amt);
            //camp.owner.transfer(amt);
        }

        return 0;
    }

    

    function transferFundsToOwner(uint256 _id) public payable {

        require(msg.sender==intermediateAccount, "\nNot an intermediate account");
        require(processVotes(_id) == 1 || processVotes(_id) == 3 , "Not able to transfer now...");

        Campaign storage camp = campaigns[_id];

        if(camp.sentAmount == 0){
            camp.owner.transfer(msg.value);
            camp.sentAmount=msg.value;

        }else if(processVotes(_id) == 3){

            require(camp.targetAmount*1000000000000000000>camp.sentAmount, "You received all the amount");
            
            //emit log(amt);
            camp.owner.transfer(msg.value);
            camp.sentAmount += msg.value;
        }

    }

    function returnAmount(uint256 _id, uint i) public view returns (uint256) {
        
        Campaign storage camp = campaigns[_id];
        
        require(i < camp.donators.length, "Index Out Of Range !!");

        return camp.donation[i];

    }

    function returnFundsToDonator(uint256 _id, uint i) public payable {
        require(msg.sender==intermediateAccount, "Not an intermediate account");
        require(processVotes(_id)==2, "Not able to transfer now...");
        
        Campaign storage camp = campaigns[_id];
        
        camp.donators[i].transfer(msg.value);
        
    }    

    function getVoteCount(uint256 _id) public view returns (uint256, uint256) {
        Campaign storage camp = campaigns[_id];
        uint256 yes;
        uint256 no;
        for(uint i=0; i<camp.votes.length; i++){
            if(camp.votes[i]==1){
                yes++;
            }else{
                no++;
            }
        }
        return (no, yes);
    }

    function processVotes(uint256 _id) public returns (uint) {
        uint256 yes;
        uint256 no;
        uint randNonce = 0;
        (no, yes) = getVoteCount(_id);
        Campaign storage camp = campaigns[_id];
        uint num = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % 1;
        num++;
        uint minVotes = camp.targetAmount * num;

        if(camp.targetAmount<=2){
            uint rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % 20;
            rand +=40;
            

            if(yes+no > minVotes){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    return 3;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    return 2;
                }
                else{
                    return 0;
                }
            }else if(yes+no > minVotes/2){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    camp.f=false;
                    return 1;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    camp.f=false;
                    return 2;
                }
                else{
                    return 0;
                }
            }

        }else if(camp.targetAmount<=5){
            uint rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % 15;
            rand +=60;

            if(yes+no > minVotes){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    return 3;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    return 2;
                }
                else{
                    return 0;
                }
            }else if(yes+no > minVotes/2){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    camp.f=false;
                    return 1;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    camp.f=false;
                    return 2;
                }
                else{
                    return 0;
                }
            }
        }else{
            uint rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % 10;
            rand +=75;

            if(yes+no > minVotes){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    return 3;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    return 2;
                }
                else{
                    return 0;
                }
            }else if(yes+no > minVotes/2 && camp.f){
                if(yes*100/(yes+no)>rand){
                    //transferFundsToOwner(_id);
                    camp.f=false;
                    return 1;
                }else if(no*100/(yes+no)>rand){
                    //returnFundsToDonator(_id);
                    camp.f=false;
                    return 2;
                }
                else{
                    return 0;
                }
            }
        }
        
        return 0;
    }
}