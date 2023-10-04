//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Consumer {
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartWallet {
    address payable public owner;
    mapping(address => uint) public allowance;
    mapping(address => bool) public IsallowedTosend;
    mapping(address => bool) public Guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerguardianVotedBool;
    uint guardiansResetCount;
    uint public constant confirmationFromTheGuardianForResetCount = 3;

    constructor() {
        owner = payable(msg.sender);
    }
    function setguardians(address _guardian,bool _IsGuardian) public {
        require(msg.sender == owner,"You are not the owner");
        Guardians[_guardian] = _IsGuardian;
    }
    function proposenewOwner(address payable _newowner) public {
        require(Guardians[msg.sender],"You are not the guardian");
        require(nextOwnerguardianVotedBool[_newowner][msg.sender] == false,"You already voted!");
        if(_newowner != nextOwner){
            nextOwner = _newowner;
            guardiansResetCount = 0;
        }
        guardiansResetCount++;
        if(guardiansResetCount >= confirmationFromTheGuardianForResetCount){
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }
    function setAllowance(address _for,uint _amount) public {
        require(msg.sender == owner,"You are not the owner");
        allowance[_for] = _amount;
        if(_amount > 0){
            IsallowedTosend[_for] = true;
        }else{
            IsallowedTosend[_for] = false;
        }
    }
    function Transfer(address payable _to,uint _amount,bytes memory _payload) public returns(bytes memory) {
        require(msg.sender == owner,"You are not the owner,Aborting");
        // address(this).balance -= _amount;
        if(msg.sender != owner){
            require(IsallowedTosend[msg.sender],"You are not allwed to send funds from the smart contract");
            require(allowance[msg.sender] >= _amount,"You are not allowed to use this much funds");
            allowance[payable(msg.sender)] -= _amount;
        }
        (bool success,bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success,"Aborting,call was not succesfull");
        return returnData;
    }
    receive() external payable{}
}
