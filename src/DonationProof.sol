// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Reclaim} from "./reclaim/Reclaim.sol";
import {Claims} from "./reclaim/Claims.sol";

contract DonationProof is Ownable {
    using SafeERC20 for IERC20;

    struct Transaction {
        address account;
        uint256 productId;
        uint256 timestamp;
        bool proved;
        string link;
    }

    // reclaim
    address public constant reclaimAddress = 0x8CDc031d5B7F148ab0435028B16c682c469CEfC3;
    string public constant providersHash = "0xf44817617d1dfa5219f6aaa0d4901f9b9b7a6845bbf7b639d9bffeacc934ff9a";

    IERC20 public constant usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    uint256 public currentTransactionId = 0;

    // id product => price in USDC
    mapping(uint256 => uint256) public products;

    // transaction id => transaction
    mapping(uint256 => Transaction) public donations;

    constructor() Ownable(msg.sender) {
        // add sample
        products[1] = 10;
    }

    function donate(uint256 productId) external {
        uint256 price = products[productId];
        usdc.safeTransferFrom(msg.sender, address(this), price);

        uint256 transactionId = currentTransactionId++;

        donations[transactionId] = Transaction({
            account: msg.sender,
            productId: productId,
            timestamp: block.timestamp,
            proved: false,
            link: ""
        });
    }

    function proveDonation(uint256 transactionId, Reclaim.Proof memory proof) external {
        Transaction storage transaction = donations[transactionId];
        require(transaction.account != address(0), "Transaction not found");
        require(transaction.proved == false, "Alreadt proved");
        require(verifyProof(proof), "Proof is not valid");

        transaction.proved = true;
    }

    function verifyProof(Reclaim.Proof memory proof) public view returns (bool) {
        Reclaim(reclaimAddress).verifyProof(proof);

        // check if providerHash is valid
        string memory submittedProviderHash =
            Claims.extractFieldFromContext(proof.claimInfo.context, '"providerHash":"');

        // compare two strings
        require(
            keccak256(abi.encodePacked(submittedProviderHash)) == keccak256(abi.encodePacked(providersHash)),
            "Invalid ProviderHash"
        );

        string memory delivered = Claims.extractFieldFromContext(proof.claimInfo.context, '"delivered":"');

        require(keccak256(abi.encodePacked(delivered)) == keccak256(abi.encodePacked("true")), "Not Delivered");

        return true;
    }

    function setProduct(uint256 id, uint256 price) external onlyOwner {
        products[id] = price;
    }

    function removeProduct(uint256 id) external onlyOwner {
        delete products[id];
    }

    function withdrawDonation() external onlyOwner {
        usdc.transfer(owner(), usdc.balanceOf(address(this)));
    }
}
