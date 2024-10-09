// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {YTProof} from "../src/YTProof.sol";

contract YTProofTest is Test {
    YTProof public ytProof;

    function setUp() public {
        ytProof = new YTProof();
    }

    function test_extractFromContest() public view {
        console.log(ytProof.testExtractFieldFromContext());
    }
}
