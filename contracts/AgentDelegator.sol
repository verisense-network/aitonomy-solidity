// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenContract.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract AgentDelegator is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable {

    address public tokenAddress;
    mapping(uint256 => bool) public tickets;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        bool newIssue;
        address tokenAddress;
    }

    event WithdrawEvent(
        address user,
        uint256 amt,
        uint256 seq
    );


    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function initialize(TokenInfo calldata info) public initializer {
        if (info.newIssue) {
            require(info.decimals > 0 && info.decimals <19, "decimals must between 1 and 18");
            require(info.totalSupply > 0, "total supply error");
            tokenAddress = address(new TokenContract(info.name, info.symbol, info.decimals, info.totalSupply));
        }else {
            require(info.tokenAddress != address(0), "token addr error");
            tokenAddress = info.tokenAddress;
        }
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function transfer(address to, uint256 amt) external onlyOwner {
        require(amt > 0, "amt error");
        require(to != address(0), "to addr error");
        TokenContract(tokenAddress).transfer(to, amt);
    }

    function withdraw(bytes memory _messageBytes, bytes memory _signature) external {
        (uint256 sequence, address destination, uint256 amt) = abi.decode(
            _messageBytes,
            (uint256, address, uint256)
        );
        require(destination == _msgSender(), "permission deny");
        require(!tickets[sequence], "the reward had been withdrawed");
        require(verifySignature(_messageBytes, _signature), "signature validate failed");
        TokenContract(tokenAddress).transfer(destination, amt);
        tickets[sequence] = true;
        emit WithdrawEvent(_msgSender(), amt, sequence);
    }

    using Strings for uint256;
    function verifySignature(
        bytes memory _messageBytes,
        bytes memory _signature
    ) internal view returns (bool) {
        require(_signature.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid v value");
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                _messageBytes.length.toString(),
                _messageBytes
            )
        );
        address signer = ecrecover(hash, v, r, s);
        return signer == owner();
    }
}
