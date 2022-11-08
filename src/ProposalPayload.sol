// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IAaveEcosystemReserveController} from "./external/aave/IAaveEcosystemReserveController.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

contract ProposalPayload {
    event StreamCreated(address token, uint streamID);

    address internal constant ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    // Certora Recipient address
    address internal constant CERTORA_BENEFICIARY = 0x0F11640BF66e2D9352d9c41434A5C6E597c5e4c8;
    address internal constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    uint256 internal constant USDC_VEST = 1_890_000 * 1e6;

    address internal constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    // $810,000 worth of AAVE tokens calculated according to the 30 day average price of AAVE
    // using CoinGecko historical data (data/aave-30d-price-coingecko.json)
    uint256 internal constant AAVE_VEST = 9957999999999995712000;
    
    // account for the time since Sep. 13 since last proposal finished vesting and 
    // this proposal, as of Nov. 12, 2022
    uint256 internal constant DURATION = 365 days - 60 days;

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        uint256 actualAmountUSDC = (USDC_VEST / DURATION) * DURATION; // rounding
        // Stream of $1.89 million in USDC over 12 months
        uint256 usdcStreamID = IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            CERTORA_BENEFICIARY,
            actualAmountUSDC,
            AUSDC_TOKEN,
            block.timestamp,
            block.timestamp + DURATION
        );
        emit StreamCreated(AUSDC_TOKEN, usdcStreamID);

        uint256 actualAmountAAVE = (AAVE_VEST / DURATION) * DURATION;
        uint256 aaveStreamID = IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            ECOSYSTEM_RESERVE,
            CERTORA_BENEFICIARY,
            actualAmountAAVE,
            AAVE_TOKEN,
            block.timestamp,
            block.timestamp + DURATION
        );
        emit StreamCreated(AAVE_TOKEN, aaveStreamID);
    }

}
