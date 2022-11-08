# Certora <> AAVE Proposal

Payload and tests for the Certora Continuous Formal Verification

## Specification

This repository contains the Payload and tests for the [Certora <> Aave Proposal](https://governance.aave.com/t/security-and-agility-of-aave-smart-contracts-via-continuous-formal-verification/10181)

The Proposal Payload does the following:

1. Creates a 12-month stream of 1,890,000 aUSDC ($1.89M) to the Certora beneficiary address.
2. Creates a 12-month stream of 9958 AAVE ($810,000) to the Certora beneficiary address.

We've used the  30 days average AAVE price, to calculate the amount of AAVE tokens that corresponds to the $810,000 sum in the proposal.
The json file with the price data used is available [here](data/aave-30d-price-coingecko.json).
## Installation

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

In order to install, run the following commands:

```sh
$ git clone https://github.com/Certora/aave-proposal-2
$ cd aave-proposal-2
$ npm install
$ forge install
```

## Setup

Duplicate `.env.example` and rename to `.env`:

- Add a valid mainnet URL for an Ethereum JSON-RPC client for the `RPC_MAINNET_URL` variable.
- Add a valid Private Key for the `PRIVATE_KEY` variable.
- Add a valid Etherscan API Key for the `ETHERSCAN_API_KEY` variable.

### Commands

- `make build` - build the project
- `make test [optional](V={1,2,3,4,5})` - run tests (with different debug levels if provided)
- `make match MATCH=<TEST_FUNCTION_NAME> [optional](V=<{1,2,3,4,5}>)` - run matched tests (with different debug levels if provided)

### Deploy and Verify

- `make deploy-payload` - deploy and verify payload on mainnet
- `make deploy-proposal`- deploy proposal on mainnet

To confirm the deploy was successful, re-run your test suite but use the newly created contract address.
