pragma solidity 0.7.5;

import "./Owner.sol";

contract MultisignWallet is Owner {
    address[] public walletManagers;
    uint numberOfAprovalsRequired;
    mapping(address => uint) balance;
    mapping(address => bool) admins;
    
    struct TransferRequest {
        uint pendingAprovals;
        uint transactionId;
        bool aproved;
        uint ammount;
        address payable recipient;
        string motive;
    }
    
    TransferRequest[] public transferRequest;

    constructor(){
        walletManagers = [msg.sender,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db];
        numberOfAprovalsRequired = 3;
         admins[walletManagers[0]] = true;
         admins[walletManagers[1]] = true;
         admins[walletManagers[2]] = true;
    }
 
    function createTransfer(uint _ammountToTransfer, address payable _recipient, string memory motive) public {
        require(address(this).balance >= _ammountToTransfer, "The contract don't have sufficient founds");
        require(address(this) != _recipient, "Sender must be different to the contract address");
        require(admins[msg.sender] == true, "Only wallet members can create transactions");
        createPendingTransfer(TransferRequest(numberOfAprovalsRequired, generateTransactionId(), false, _ammountToTransfer, _recipient, motive));
    }
       
    function generateTransactionId() internal view returns (uint) {
        return transferRequest.length + 1;
    }
    
    function aproveAndValidateTransaction(uint _id) public {
        require(admins[msg.sender] == true, "Only wallet members can aprove transactions");
        if(!transferRequest[_id].aproved){
            transferRequest[_id].pendingAprovals -=1;
            if(transferRequest[_id].pendingAprovals == 0){
                transferRequest[_id].aproved = true;
                _transfer(transferRequest[_id].ammount, transferRequest[_id].recipient);
            }
        }
    }
    
    function _transfer(uint _ammount, address payable _recipient) internal{
        _recipient.transfer(_ammount);
        balance[address(this)] -= _ammount;
        balance[_recipient] += _ammount;
        
    }
    
    function createPendingTransfer(TransferRequest memory _transferBody) internal {
        transferRequest.push(_transferBody);
    }
    
    function depositFounds() public payable {
        uint previousBalance = balance[address(this)];
        balance[address(this)] += msg.value;
        assert(balance[address(this)] == previousBalance + msg.value);
    }   
    
    function getWalletBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getWalletInternalBalance() public view returns (uint) {
        return balance[address(this)];
    }
    
    function isMember() public view returns (bool) {
        return admins[msg.sender];
    }
   
    function getTransactionMotive(uint _id) public view returns ( string memory){
        require(admins[msg.sender] == true, "Members only");
        return transferRequest[_id].motive;
    }
}