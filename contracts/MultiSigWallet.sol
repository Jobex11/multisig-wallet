// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Events
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(uint indexed txId);
    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event ExecuteTransaction(uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event TransactionExpired(uint indexed txId);

    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    uint public transactionExpiryBlocks; // number of blocks after which a transaction expires

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        uint submittedBlock;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!isConfirmed[_txId][msg.sender], "tx already confirmed");
        _;
    }

    modifier notExpired(uint _txId) {
        require(
            block.number <=
                transactions[_txId].submittedBlock + transactionExpiryBlocks,
            "tx expired"
        );
        _;
    }

    constructor(
        address[] memory _owners,
        uint _required,
        uint _transactionExpiryBlocks
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid number of required confirmations"
        );
        require(_transactionExpiryBlocks > 0, "invalid transaction expiry");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
        transactionExpiryBlocks = _transactionExpiryBlocks;
    }

    // Functions
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                submittedBlock: block.number
            })
        );

        emit SubmitTransaction(txId);
    }

    function confirmTransaction(
        uint _txId
    )
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
        notExpired(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    function executeTransaction(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) notExpired(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(transaction.numConfirmations >= required, "cannot execute tx");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) {
            transaction.executed = false;
            revert("tx failed");
        }

        emit ExecuteTransaction(_txId);
    }

    function revokeConfirmation(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        require(isConfirmed[_txId][msg.sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "invalid owner");
        require(!isOwner[_newOwner], "already owner");

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit OwnerAdded(_newOwner);
    }

    function removeOwner(address _owner) public onlyOwner {
        require(isOwner[_owner], "not owner");

        isOwner[_owner] = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        // Update required confirmations if necessary
        if (required > owners.length) {
            required = owners.length;
        }

        emit OwnerRemoved(_owner);
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txId
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations,
            uint submittedBlock
        )
    {
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.submittedBlock
        );
    }

    // Cancel a transaction after the expiry period
    function expireTransaction(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        require(
            block.number >
                transactions[_txId].submittedBlock + transactionExpiryBlocks,
            "tx not yet expired"
        );

        delete transactions[_txId];

        emit TransactionExpired(_txId);
    }
}

/*
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Events
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(uint indexed txId);
    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event ExecuteTransaction(uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);

    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!isConfirmed[_txId][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    // Functions
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(txId);
    }

    function confirmTransaction(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    function executeTransaction(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(transaction.numConfirmations >= required, "cannot execute tx");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(_txId);
    }

    function revokeConfirmation(
        uint _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        require(isConfirmed[_txId][msg.sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txId
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

*/
