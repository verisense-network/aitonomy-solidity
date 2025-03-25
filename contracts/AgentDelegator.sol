// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract AgentDelegator is Ownable {

    address public tokenAddress;
    mapping(uint256 => bool) public tickets;
    event WithdrawEvent(
        address user,
        uint256 amt,
        uint256 seq
    );

    event TokenAdded(address a);
    constructor(string memory name,
                        string memory symbol,
                        uint8 decimals,
                        uint256 totalSupply,
                        bool newIssue,
                        address _tokenAddress) Ownable(_msgSender()) {
        if (newIssue) {
            require(decimals > 0 && decimals <19, "decimals must between 1 and 18");
            require(totalSupply > 0, "total supply error");
            tokenAddress = address(new TokenContract(name, symbol, decimals, totalSupply));
            emit TokenAdded(tokenAddress);
        }else {
            ERC20 ct = ERC20(_tokenAddress);
            require(ct.decimals() == decimals, "deceimals error");
            require(keccak256(bytes(ct.name())) == keccak256(bytes(name)), "name error");
            require(keccak256(bytes(ct.symbol())) == keccak256(bytes(symbol)), "symbol error");
            tokenAddress = _tokenAddress;
        }
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
