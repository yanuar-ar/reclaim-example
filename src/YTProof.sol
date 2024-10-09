// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Reclaim} from "./reclaim/Reclaim.sol";
import {Claims} from "./reclaim/Claims.sol";

contract YTProof is ERC721 {
    // reclaim
    address public constant reclaimAddress = 0x8CDc031d5B7F148ab0435028B16c682c469CEfC3;
    string public constant providersHash = "0xf44817617d1dfa5219f6aaa0d4901f9b9b7a6845bbf7b639d9bffeacc934ff9a";

    constructor() ERC721("Youtube Proof", "YTP") {}

    function mintYT(Reclaim.Proof memory proof) public {
        uint256 tokenId = verifyProof(proof);
        _safeMint(msg.sender, tokenId);
    }

    function verifyProof(Reclaim.Proof memory proof) public view returns (uint256) {
        Reclaim(reclaimAddress).verifyProof(proof);

        // check if providerHash is valid
        string memory submittedProviderHash =
            Claims.extractFieldFromContext(proof.claimInfo.context, '"providerHash":"');

        // compare two strings
        require(
            keccak256(abi.encodePacked(submittedProviderHash)) == keccak256(abi.encodePacked(providersHash)),
            "Invalid ProviderHash"
        );

        string memory videoId = Claims.extractFieldFromContext(proof.claimInfo.context, '"channelId":"');

        // generate videoId to tokenId
        uint256 tokenId = convertId(videoId);

        // check if already minted
        address owner = _ownerOf(tokenId);
        require(owner == address(0), "Already minted");

        return tokenId;
    }

    function convertId(string memory videoId) public pure returns (uint256) {
        // generate tokenId base on videoId. Convert to Keccak256 -> bytes32 -> uint256
        return uint256(keccak256(abi.encodePacked(videoId)));
    }

    function testExtractFieldFromContext() public pure returns (string memory) {
        string memory context =
            "{\"extractedParameters\":{\"channelId\":\"UCABGsypuWBF08hLaO7Gv0vg\",\"title\":\"Channel_NAME\"},\"providerHash\":\"0x15a4812b1c592ef1d4b746e94f6c5136ef1c7a55c01db28bb54ed045e5fb4251\"}";
        return Claims.extractFieldFromContext(context, '"channelId":"');
    }
}
