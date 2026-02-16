//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

contract GoFundMe{


    ///////////////// ////////
    ////// ERROR ////////////

     error  GoFundMe__NotCreator();
     error GoFundMe__TransferFailed();

  ////////////////////////////////
  ///////// EVENTS //////////////

  event _goFundMeCreated(address indexed campaigner, uint256 fundMeId,string _reason, uint256 _amount,uint256 _deadline);
  event _deposited(uint256 amount, uint256 fundMeId);
  event  _fundingWithdrawn(address campaigner,uint256 fundMeId, uint256 amountContributed);
  
    struct CreateFundMe{
        uint256 contribute;
        string reason;
        uint256 amountToFund;
        uint256 createdAt;
        uint256 deadline;
        bool fundCompleted;
        address creator;
        uint256 id;
    }

    mapping(uint256 =>  uint256) currentState;
    mapping(uint256 => address)fundMeCreator;
    mapping(uint256 => CreateFundMe) s_createFundMe;

    constructor(){

    }

      modifier onlyCreator(uint256 id){
        _onlyCreator(id);
        _;
    }

    function createFund(string memory _reason, uint256 _amount, uint256 _deadline) external {
        uint256 _id;

        s_createFundMe[_id] = CreateFundMe({
         contribute: 0,
         reason: _reason,
         amountToFund: _amount,
        createdAt: block.timestamp,
         deadline: _deadline,
         fundCompleted: false,
         creator: msg.sender,
         id: _id
    });
    fundMeCreator[_id] = msg.sender;
    emit _goFundMeCreated(msg.sender, _id,_reason,_amount,_deadline);
    _id++;
    }

receive() payable external{}
  

    function depositFundMe(uint256 _id) payable external {
        CreateFundMe memory createFundMe = s_createFundMe[_id];
        require( createFundMe.creator != address(0), 'no message created');
        require(!createFundMe.fundCompleted , 'funding already completed' );
       s_createFundMe[_id].contribute += msg.value;

       emit _deposited(msg.value, _id);
        
    }

    function withdrawFundMe(uint256 id) external onlyCreator(id){
        CreateFundMe memory createFundMe = s_createFundMe[id];
        require( createFundMe.deadline >= block.timestamp, 'time not exceeded');
        uint256 amount = createFundMe.contribute;
        if(block.timestamp >= createFundMe.deadline && createFundMe.amountToFund > createFundMe.contribute ){
            s_createFundMe[id].fundCompleted = false;
        }

         if(block.timestamp >= createFundMe.deadline && createFundMe.amountToFund <= createFundMe.contribute ){
            s_createFundMe[id].fundCompleted = true;
        }

        (bool success, ) = payable(msg.sender).call{value: amount}('');
        if(!success){
            revert GoFundMe__TransferFailed();
        }

        emit _fundingWithdrawn(msg.sender,id, amount);

    }
       function _onlyCreator(uint256 id) internal  view {
                if(msg.sender != fundMeCreator[id]){
                  revert GoFundMe__NotCreator();
          }
       }   
    function getCurrentFundMeBalance(uint256 id) public view returns(uint256){
          CreateFundMe memory createFundMe = s_createFundMe[id];
          uint256 currentBalance = createFundMe.contribute;
          return currentBalance;
    }

    function getRemainingBalanceBeforeDeadline(uint256 id) public view returns(uint256){
        CreateFundMe memory createFundMe = s_createFundMe[id];
        uint256 remainingBalance;
          if (createFundMe.deadline > block.timestamp){
            if (createFundMe.amountToFund > createFundMe.contribute){
               remainingBalance = createFundMe.amountToFund - createFundMe.contribute ;
            }
          }
          return remainingBalance;

        
    }

    function isFundMeCompleted(uint256 id) public view returns (bool result){
         CreateFundMe memory createFundMe = s_createFundMe[id];
         if(block.timestamp >= createFundMe.deadline && createFundMe.amountToFund > createFundMe.contribute ){
            result =  false;
        }

         if(block.timestamp >= createFundMe.deadline && createFundMe.amountToFund <= createFundMe.contribute ){
            result =  true;
        }

    }

}