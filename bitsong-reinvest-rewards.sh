#!/bin/bash -e
# --------------------------------------------------------------------------------------------------------------------------------
# Bitsong Reinvestment script for rewards and commission
# --------------------------------------------------------------------------------------------------------------------------------
# Made by: Thamar
# december 2021 - adjusted for bitsong by Validator Thamar -proud member of- https://dutchpool.io/
# Based on "Cosmos Hub reinvestment script for rewards" - Copyright (C) 2019 Validator ApS -- https://validator.network
#
# This script comes without warranties of any kind. Use at your own risk.
#
# The purpose of this script is to withdraw rewards (if any) and delegate them to an appointed validator. This way you can reinvest (compound) rewards.
# Requirements: bitsongd, curl and jq must be in the path.



##############################################################################################################################################################
# User settings.
##############################################################################################################################################################

KEY=""                                  # This is the key you wish to use for signing transactions, listed in first column of "bitsongd keys list".
KEYRING_PASSPHRASE=""                   # Fill in your KeyRing Passphrase to run the script periodically via cron. Becarefull, know what you are doing!
DENOM="ubtsg"                           # Coin denominator is ubtsg ("micro-btsg"). 1 btsg = 1000000 ubtsg.
MINIMUM_DELEGATION_AMOUNT="25000000"    # Only perform delegations above this amount of ubtsg. Default: 25btsg.
RESERVATION_AMOUNT="10000000"           # Keep this amount of ubtsg in account. Default: 10btsg.(Was 100btsg)
VALIDATOR="bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj"        # Default is validator THAMAR. Thank you for your support :-); but hey, you should change this ...

##############################################################################################################################################################


##############################################################################################################################################################
# Sensible defaults.
##############################################################################################################################################################

CHAIN_ID="bitsong-2b"          # Current chain id. Empty means auto-detect.
NODE="http://localhost:26657"  # Either run a local full node or choose one you trust.
GAS_PRICES="0.3ubtsg"          # Gas prices to pay for transaction. Default: 0.3ubtsg
GAS_ADJUSTMENT="1.5"           # Adjustment for estimated gas. Default: 1.5
GAS_FLAGS="--gas auto --gas-prices ${GAS_PRICES} --gas-adjustment ${GAS_ADJUSTMENT}"

##############################################################################################################################################################

echo "Reinvestment script for rewards and commission starts..."
echo ""

# Auto-detect chain-id if not specified.
if [ -z "${CHAIN_ID}" ]
then
  NODE_STATUS=$(curl -s --max-time 5 ${NODE}/status)
  CHAIN_ID=$(echo ${NODE_STATUS} | jq -r ".result.node_info.network")
  echo "  Chain-ID: ${CHAIN_ID}"
fi

# Use first command line argument in case KEY is not defined.
if [ -z "${KEY}" ] && [ ! -z "${1}" ]
then
  KEY=${1}
fi

# Get information about key
KEY_STATUS=$(echo ${KEYRING_PASSPHRASE} | ~/go/bin/bitsongd keys show ${KEY} --output json)
KEY_TYPE=$(echo ${KEY_STATUS} | jq -r ".type")
if [ "${KEY_TYPE}" == "ledger" ]
then
    SIGNING_FLAGS="--ledger"
fi

# Get current account balance.
#logtest echo "Script - Get current account balance"
ACCOUNT_ADDRESS=$(echo ${KEY_STATUS} | jq -r ".address")
ACCOUNT_STATUS=$( ~/go/bin/bitsongd query account ${ACCOUNT_ADDRESS} --chain-id ${CHAIN_ID} --output json)
ACCOUNT_SEQUENCE=$(echo ${ACCOUNT_STATUS} | jq -r ".sequence")

ACCOUNT_BANK_BALANCE=$( ~/go/bin/bitsongd query bank balances ${ACCOUNT_ADDRESS} --chain-id ${CHAIN_ID} --output json)
ACCOUNT_BALANCE=$(echo ${ACCOUNT_BANK_BALANCE} | jq -r ".balances[] | select(.denom == \"${DENOM}\") | .amount" || true)

if [ -z "${ACCOUNT_BALANCE}" ]
then
    # Empty response means zero balance.
    ACCOUNT_BALANCE=0
fi


# Get available rewards.
REWARDS_STATUS=$(~/go/bin/bitsongd query distribution rewards ${ACCOUNT_ADDRESS} --chain-id ${CHAIN_ID} --output json)
if [ "${REWARDS_STATUS}" == "null" ]
then
    # Empty response means zero balance.
    REWARDS_BALANCE="0"
else
    REWARDS_BALANCE=$(echo ${REWARDS_STATUS} | jq -r ".total[] | select(.denom == \"${DENOM}\") | .amount" || true)
    if [ -z "${REWARDS_BALANCE}" ] || [ "${REWARDS_BALANCE}" == "null" ]
    then
        # Empty response means zero balance.
        REWARDS_BALANCE="0"
    else
        # Remove decimals.
        REWARDS_BALANCE=${REWARDS_BALANCE%.*}
    fi
fi


# Get available commission.
VALIDATOR_ADDRESS=$(echo ${KEYRING_PASSPHRASE} | ~/go/bin/bitsongd keys show ${KEY} --bech val --address)
COMMISSION_STATUS=$(~/go/bin/bitsongd query distribution commission ${VALIDATOR_ADDRESS} --chain-id ${CHAIN_ID} --output json)
if [ "${COMMISSION_STATUS}" == "null" ]
then
    # Empty response means zero balance.
    COMMISSION_BALANCE="0"
else
    COMMISSION_BALANCE=$(echo ${COMMISSION_STATUS} | jq -r ".commission[] | select(.denom == \"${DENOM}\") | .amount" || true)
    #testlog echo "COMM balance: ${COMMISSION_BALANCE}"
    if [ -z "${COMMISSION_BALANCE}" ]
    then
        # Empty response means zero balance.
        COMMISSION_BALANCE="0"
    else
        # Remove decimals.
        COMMISSION_BALANCE=${COMMISSION_BALANCE%.*}
    fi
fi

# Calculate net balance and amount to delegate.
REW_COM_BALANCE=$((${COMMISSION_BALANCE} + ${REWARDS_BALANCE}))
NET_BALANCE=$((${ACCOUNT_BALANCE} + ${REWARDS_BALANCE} + ${COMMISSION_BALANCE}))
if [ "${NET_BALANCE}" -gt $((${MINIMUM_DELEGATION_AMOUNT} + ${RESERVATION_AMOUNT})) ]
then
    DELEGATION_AMOUNT=$((${NET_BALANCE} - ${RESERVATION_AMOUNT}))
else
    DELEGATION_AMOUNT="0"
fi


# Display what we know so far.
ACCOUNT_BALANCE_2=$(echo "scale=2; ${ACCOUNT_BALANCE}/1000000" |bc -l)
REWARDS_BALANCE_2=$(echo "scale=2; ${REWARDS_BALANCE}/1000000" |bc -l)
COMMISSION_BALANCE_2=$(echo "scale=2; ${COMMISSION_BALANCE}/1000000" |bc -l)
REW_COM_BALANCE_2=$(echo "scale=2; ${REW_COM_BALANCE}/1000000" |bc -l)
NET_BALANCE_2=$(echo "scale=2; ${NET_BALANCE}/1000000" |bc -l)
RESERVATION_AMOUNT_2=$(echo "scale=2; ${RESERVATION_AMOUNT}/1000000" |bc -l)
DELEGATION_AMOUNT_2=$(echo "scale=2; ${DELEGATION_AMOUNT}/1000000" |bc -l)

echo "======================================================"
echo "Account:                ${KEY} (${KEY_TYPE})"
echo "Chain-ID:               ${CHAIN_ID}"
echo "Account Address:        ${ACCOUNT_ADDRESS}"
echo "Validator Address:      ${VALIDATOR_ADDRESS}"
echo "Minimum Re-invest Amm.: ${MINIMUM_DELEGATION_AMOUNT} ${DENOM}"
echo "======================================================"
echo "Account Balance:        ${ACCOUNT_BALANCE_2} (${ACCOUNT_BALANCE} ${DENOM})"
echo "Available Rewards:      ${REWARDS_BALANCE_2} (${REWARDS_BALANCE} ${DENOM})"
echo "Available Commission:   ${COMMISSION_BALANCE_2} (${COMMISSION_BALANCE} ${DENOM})"
echo "Tot Avail Bal+Rew+Com:  ${NET_BALANCE_2} (${NET_BALANCE} ${DENOM})"
echo ""
echo "Reservation Balance:    ${RESERVATION_AMOUNT_2} (${RESERVATION_AMOUNT} ${DENOM})"
echo "======================================================"
echo "Re-invest Ammount:      ${NET_BALANCE_2} - ${RESERVATION_AMOUNT_2} = ${DELEGATION_AMOUNT_2} "
echo ""

if [ "${DELEGATION_AMOUNT}" -eq 0 ]
then
    echo "Nothing to Re-invest (delegate)."
    exit 0
fi


# Display delegation information.
VALIDATOR_STATUS=$(~/go/bin/bitsongd query staking validator ${VALIDATOR} --chain-id ${CHAIN_ID} --node ${NODE} --output json)
VALIDATOR_MONIKER=$(echo ${VALIDATOR_STATUS} | jq -r ".description.moniker")
VALIDATOR_DETAILS=$(echo ${VALIDATOR_STATUS} | jq -r ".description.details")
echo "You are about to delegate ${DELEGATION_AMOUNT}${DENOM} to validator ${VALIDATOR}:"
echo "  Moniker: ${VALIDATOR_MONIKER}"
echo "  Details: ${VALIDATOR_DETAILS}"
echo

# Ask for passphrase to sign transactions.
if [ -z "${SIGNING_FLAGS}" ] && [ -z "${KEYRING_PASSPHRASE}" ]
then
    read -s -p "Enter your passphrase, required to sign for \"${KEY}\": " KEYRING_PASSPHRASE
    echo ""
fi

# Run transactions
MEMO=$'Reinvesting rewards'
if [ "${REWARDS_BALANCE}" -gt 0 ]
then
    echo ""
    echo "Withdrawing rewards ... "
    echo "Account sequence: ${ACCOUNT_SEQUENCE}"
    echo "Signing Flags: ${SIGNING_FLAGS}"

    yes "$KEYRING_PASSPHRASE" | ~/go/bin/bitsongd tx distribution withdraw-all-rewards --yes --from ${KEY} --sequence ${ACCOUNT_SEQUENCE} --chain-id ${CHAIN_ID} --node ${NODE} ${GAS_FLAGS} ${SIGNING_FLAGS} --memo "${MEMO}" --broadcast-mode async
    ACCOUNT_SEQUENCE=$((ACCOUNT_SEQUENCE + 1))
fi

if [ "${COMMISSION_BALANCE}" -gt 0 ]
then
    echo ""
    echo "Withdrawing commission ... "
    yes "${KEYRING_PASSPHRASE}" | ~/go/bin/bitsongd tx distribution withdraw-rewards ${VALIDATOR_ADDRESS} --commission --yes --from ${KEY} --sequence ${ACCOUNT_SEQUENCE} --chain-id ${CHAIN_ID} ${GAS_FLAGS} ${SIGNING_FLAGS} --memo "${MEMO}" --broadcast-mode async
    ACCOUNT_SEQUENCE=$((ACCOUNT_SEQUENCE + 1))
fi

echo ""
echo "Wait for 15 seconds for next chain transaction, the rewards and commission need to be confirmed on chain ..."
echo "Zzzz"
sleep 15 & wait
echo ""
echo "Start Delegating ${DELEGATION_AMOUNT} ${DENOM} to validator /"${VALIDATOR_MONIKER}/" with address ${VALIDATOR_ADDRESS}."
echo ""
yes "${KEYRING_PASSPHRASE}" | ~/go/bin/bitsongd tx staking delegate ${VALIDATOR} ${DELEGATION_AMOUNT}${DENOM} --yes --from ${KEY} --sequence ${ACCOUNT_SEQUENCE} -b block --chain-id ${CHAIN_ID} ${GAS_FLAGS} ${SIGNING_FLAGS} --memo "${MEMO}" --broadcast-mode async

echo ""
echo "Done!"
echo "Have a marvelous bitsong day!"
