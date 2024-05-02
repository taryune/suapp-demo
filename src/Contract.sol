// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "suave-std/Suapp.sol";
import "suave-std/Context.sol";
import "suave-std/Transactions.sol";
import "suave-std/suavelib/Suave.sol";

contract Contract is Suapp {
    Suave.DataId signingKeyRecord;
    string public PRIVATE_KEY = "KEY";
    event TxnSignature(bytes32 r, bytes32 s);

    function updateKeyOnchain(Suave.DataId _signingKeyRecord) public {
        signingKeyRecord = _signingKeyRecord;
    }

    function registerPrivateKeyOffchain() public returns (bytes memory) {
        bytes memory keyData = Context.confidentialInputs();

        address[] memory peekers = new address[](1);
        peekers[0] = address(this);

        Suave.DataRecord memory record = Suave.newDataRecord(
            0, // decryption condition: deprecated
            peekers, // who can get the data
            peekers, // who can set the data
            "private_key" // data type
        );
        Suave.confidentialStore(record.id, PRIVATE_KEY, keyData);

        return
            abi.encodeWithSelector(this.updateKeyOnchain.selector, record.id);
    }

    function onchain() public emitOffchainLogs {}

    function offchain() public returns (bytes memory) {
        bytes memory signingKey = Suave.confidentialRetrieve(
            signingKeyRecord,
            PRIVATE_KEY
        );

        Transactions.EIP155Request memory txnWithToAddress = Transactions
            .EIP155Request({
                to: address(0x00000000000000000000000000000000DeaDBeef),
                gas: 1000000,
                gasPrice: 500,
                value: 1,
                nonce: 1,
                data: bytes(""),
                chainId: 1337
            });

        Transactions.EIP155 memory txn = Transactions.signTxn(
            txnWithToAddress,
            string(signingKey)
        );
        emit TxnSignature(txn.r, txn.s);

        return abi.encodeWithSelector(this.onchain.selector);
    }
}
