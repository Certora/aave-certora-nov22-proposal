// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {IStreamable} from "../external/aave/IStreamable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract ProposalPayloadTest is Test {
    address internal constant ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

    uint256 public proposalId;

    IERC20 public constant AUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    // 0x464
    address public immutable AAVE_COLLECTOR = AaveV2Ethereum.COLLECTOR;
    address public constant CERTORA_RECIPIENT = 0x0F11640BF66e2D9352d9c41434A5C6E597c5e4c8;

    IStreamable public immutable STREAMABLE_AAVE_COLLECTOR = IStreamable(AaveV2Ethereum.COLLECTOR);
    IStreamable public immutable STREAMABLE_RESERVE = IStreamable(ECOSYSTEM_RESERVE);

    uint256 public constant USDC_VEST = 1_890_000 * 1e6;
    uint256 internal constant AAVE_AVG_PRICE_30D_USDC = 81340000;
    uint256 internal constant AAVE_VEST_USDC_WORTH = 810_000 * 1e6;
    uint256 internal constant AAVE_VEST = AAVE_VEST_USDC_WORTH / AAVE_AVG_PRICE_30D_USDC
        * 10**18;
    uint256 public constant DURATION = 365 days - 60 days;

    uint256 public constant actualAmountUSDC = (USDC_VEST) / DURATION * DURATION;
    uint256 public constant actualAmountAAVE = (AAVE_VEST) / DURATION * DURATION;

    ProposalPayload public proposalPayload;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        proposalPayload = new ProposalPayload();
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            bytes32(0x5d0543d0e66abc240eceeae5ada6240d4d6402c2ccfe5ad521824dc36be71c45) // TODO: replace with actual ipfshash
        );
        
    }

    // Full Vesting Test
    function testExecute() public {

        // Capturing next Stream IDs before proposal is executed
        uint256 nextCollectorStreamID = STREAMABLE_AAVE_COLLECTOR.getNextStreamId();
        uint256 nextReserveStreamID = STREAMABLE_RESERVE.getNextStreamId();

        uint256 initialCertoraUSDCBalance = AUSDC.balanceOf(CERTORA_RECIPIENT);
        uint256 initialCertoraAAVEBalance = AAVE.balanceOf(CERTORA_RECIPIENT);

        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        uint usdcStreamID = nextCollectorStreamID;
        console.log("usdc stream id");
        console.log(usdcStreamID);
        uint aaveStreamID = nextReserveStreamID;
        console.log("aave stream id");
        console.log(aaveStreamID);

        // Checking if the streams have been created properly
        (
            address senderUSDC,
            address recipientUSDC,
            uint256 depositUSDC,
            address tokenAddressUSDC,
            uint256 startTimeUSDC,
            uint256 stopTimeUSDC,
            uint256 remainingBalanceUSDC,
        ) = STREAMABLE_AAVE_COLLECTOR.getStream(usdcStreamID);

        assertEq(senderUSDC, AAVE_COLLECTOR);
        assertEq(recipientUSDC, CERTORA_RECIPIENT);
        assertEq(depositUSDC, actualAmountUSDC);
        assertEq(tokenAddressUSDC, address(AUSDC));
        assertEq(stopTimeUSDC - startTimeUSDC, DURATION);
        assertEq(remainingBalanceUSDC, actualAmountUSDC);

         (
            address senderAAVE,
            address recipientAAVE,
            uint256 depositAAVE,
            address tokenAddressAAVE,
            uint256 startTimeAAVE,
            uint256 stopTimeAAVE,
            uint256 remainingBalanceAAVE,
        ) = STREAMABLE_RESERVE.getStream(aaveStreamID);
        assertEq(senderAAVE, ECOSYSTEM_RESERVE);
        assertEq(recipientAAVE, CERTORA_RECIPIENT);
        assertEq(depositAAVE, actualAmountAAVE);
        assertEq(tokenAddressAAVE, address(AAVE));
        assertEq(stopTimeAAVE - startTimeAAVE, DURATION);
        assertEq(remainingBalanceAAVE, actualAmountAAVE);

        // Checking if Certora can withdraw from streams
        vm.startPrank(CERTORA_RECIPIENT);
        vm.warp(block.timestamp + DURATION + 1 days);
        uint256 currentUSDCStreamBalance = STREAMABLE_AAVE_COLLECTOR.balanceOf(
            usdcStreamID,
            CERTORA_RECIPIENT
        );
        console.log("stream USDC balance");
        console.log(currentUSDCStreamBalance);
        console.log("actual amount USDC");
        console.log(actualAmountUSDC);

        STREAMABLE_AAVE_COLLECTOR.withdrawFromStream(
            usdcStreamID, actualAmountUSDC
        );
        STREAMABLE_RESERVE.withdrawFromStream(
            aaveStreamID, actualAmountAAVE);
        uint256 nextCertoraUSDCBalance = AUSDC.balanceOf(CERTORA_RECIPIENT);
        uint256 nextCertoraAAVEBalance = AAVE.balanceOf(CERTORA_RECIPIENT);
        assertEq(initialCertoraUSDCBalance, nextCertoraUSDCBalance - actualAmountUSDC);
        assertEq(initialCertoraAAVEBalance, nextCertoraAAVEBalance - actualAmountAAVE);
        console.log("Certora aUSDC balance increase");
        console.log((nextCertoraUSDCBalance - initialCertoraUSDCBalance) / 10**6);
        console.log("Certora AAVE balance increase");
        console.log((nextCertoraAAVEBalance - initialCertoraAAVEBalance) / 10**18);

        vm.stopPrank();
    }
}