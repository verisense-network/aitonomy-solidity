// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AgentDelegator is Ownable, ReentrancyGuard {

    address public tokenAddress;
    mapping(uint256 => bool) public tickets;
    mapping(address => uint256[]) private user_tickets;
    mapping(address => uint256) public user_tickets_length;
    mapping(address => uint256) public user_max_withdrawed;
    event WithdrawEvent(
        address user,
        uint256 amt,
        uint256 seq
    );


    struct Reward {
        bytes  _messageBytes;
        bytes  _signature;
    }

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
        _withdraw(_messageBytes, _signature);
    }

    function user_withdraws(address user) public view returns(uint256[] memory) {
        uint256 l = user_tickets_length[user];
        if (l == 0 ) {
            return new uint256[](0);
        }
        uint256[] memory seqs = new uint256[](l);
        for (uint256 i = 0; i < l; i++) {
            seqs[i] = user_tickets[user][i];
        }
        return seqs;
    }

    function _withdraw(bytes memory _messageBytes, bytes memory _signature) internal nonReentrant {
        require(verifySignature(_messageBytes, _signature), "signature validate failed");
        (uint256 sequence, address destination, uint256 amt) = abi.decode(
            _messageBytes,
            (uint256, address, uint256)
        );
        require(destination == _msgSender(), "permission deny");
        require(!tickets[sequence], "the reward had been withdrawn");
        tickets[sequence] = true;
        user_tickets[destination].push(sequence);
        uint256 l = user_tickets_length[destination];
        user_tickets_length[destination] = l+1;
        if (user_max_withdrawed[destination] < sequence) {
            user_max_withdrawed[destination] = sequence;
        }
        TokenContract(tokenAddress).transfer(destination, amt);
        emit WithdrawEvent(_msgSender(), amt, sequence);
    }

    function batch_withdraw(Reward[] memory rewards) external {
        require(rewards.length > 0, "No rewards provided");
        for (uint256 i = 0; i < rewards.length; i++) {
            _withdraw(rewards[i]._messageBytes, rewards[i]._signature);
        }
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
