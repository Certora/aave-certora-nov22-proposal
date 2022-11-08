// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IAaveEcosystemReserveController} from "./external/aave/IAaveEcosystemReserveController.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

contract ProposalPayload {
    event StreamCreated(address token, uint streamID);
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    address internal constant ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    // Certora Recipient address
    address internal constant CERTORA_BENEFICIARY = 0x0F11640BF66e2D9352d9c41434A5C6E597c5e4c8;
    address internal constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    uint256 internal constant USDC_VEST = 1_890_000 * 1e6;

    address internal constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 internal constant AAVE_DECIMALS = 18;
    uint256 internal constant AAVE_VEST_USDC_WORTH = 810_000 * 1e6;
    // 30d average AAVE price calculated from CoinGecko historic data
    uint256 internal constant AAVE_AVG_PRICE_30D_USDC = 81340000;
    uint256 internal constant AAVE_VEST = AAVE_VEST_USDC_WORTH / AAVE_AVG_PRICE_30D_USDC
        * 10**AAVE_DECIMALS;

    uint256 internal constant DURATION = 365 days - 60 days;

    uint public usdcStreamID;
    uint public aaveStreamID;



    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        uint256 actualAmountUSDC = (USDC_VEST / DURATION) * DURATION; // rounding
        // Stream of $1.89 million in USDC over 12 months
        usdcStreamID = IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            CERTORA_BENEFICIARY,
            actualAmountUSDC,
            AUSDC_TOKEN,
            block.timestamp,
            block.timestamp + DURATION
        );
        emit StreamCreated(AUSDC_TOKEN, usdcStreamID);

        uint256 actualAmountAAVE = (AAVE_VEST / DURATION) * DURATION;
        aaveStreamID = IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            ECOSYSTEM_RESERVE,
            CERTORA_BENEFICIARY,
            actualAmountAAVE,
            AAVE_TOKEN,
            block.timestamp,
            block.timestamp + DURATION
        );
        emit StreamCreated(AAVE_TOKEN, aaveStreamID);
    }

    function getUSDCStreamID() public view returns (uint) { 
        return usdcStreamID;
    }

    function getAAVEStreamID() public view returns (uint) {
        return aaveStreamID;
    }
}
