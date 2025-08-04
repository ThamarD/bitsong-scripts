#!/bin/bash -e
# --------------------------------------------------------------------------------------------------------------------------------
# Bitsong Reinvestment script for rewards and commission
# --------------------------------------------------------------------------------------------------------------------------------
# Made by: Thamar
# july 2025 - adjusted for bitsong by Validator Thamar -proud member of- https://dutchpool.io/
# Based on "Cosmos Hub reinvestment script for rewards" - Copyright (C) 2019 Validator ApS -- https://validator.network
#
# This script comes without warranties of any kind. Use at your own risk.
#
# The purpose of this script is to withdraw rewards (if any) and delegate them to an appointed validator. This way you can reinvest (compound) rewards.
# Requirements: bitsongd, curl and jq must be in the path.


# ---------------------- USER SETTINGS ----------------------
KEY=""                                  # This is the key you wish to use for signing transactions, listed in first column of "bitsongd keys list".
KEYRING_PASSPHRASE=""                   # Fill in your KeyRing Passphrase to run the script periodically via cron. Becarefull, know what you are doing!
DENOM="ubtsg"                           # Coin denominator is ubtsg ("micro-btsg"). 1 btsg = 1000000 ubtsg.
MINIMUM_DELEGATION_AMOUNT="25000000"    # Only perform delegations above this amount of ubtsg. Default: 25btsg.
RESERVATION_AMOUNT="10000000"           # Keep this amount of ubtsg in account. Default: 10btsg.(Was 100btsg)
VALIDATOR="bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj"        # Default is validator THAMAR. Thank you for your support :-); but hey, you should change this ...


# ---------------------- NETWORK SETTINGS ----------------------
CHAIN_ID="bitsong-2b"          # Current chain id. Empty means auto-detect.
NODE="http://localhost:26657"  # Either run a local full node or choose one you trust.
GAS_PRICES="0.3ubtsg"          # Gas prices to pay for transaction. Default: 0.3ubtsg
GAS_ADJUSTMENT="1.5"           # Adjustment for estimated gas. Default: 1.5
GAS_FLAGS="--gas auto --gas-prices ${GAS_PRICES} --gas-adjustment ${GAS_ADJUSTMENT}"
BITSONGD=$(which bitsongd)

# ---------------------- SCRIPT START ----------------------
echo "Reinvestment script for rewards and commission starts..."

# Auto-detect CHAIN_ID if not specified
if [ -z "${CHAIN_ID}" ]; then
  NODE_STATUS=$(curl -s --max-time 5 ${NODE}/status)
  CHAIN_ID=$(echo "${NODE_STATUS}" | jq -r ".result.node_info.network")
fi

# Get key and addresses
KEY_STATUS=$(echo "${KEYRING_PASSPHRASE}" | $BITSONGD keys show ${KEY} --output json)
KEY_TYPE=$(echo "${KEY_STATUS}" | jq -r ".type")
ACCOUNT_ADDRESS=$(echo "${KEY_STATUS}" | jq -r ".address")
VALIDATOR_ADDRESS=$(echo "${KEYRING_PASSPHRASE}" | $BITSONGD keys show ${KEY} --bech val --address)

[ "${KEY_TYPE}" == "ledger" ] && SIGNING_FLAGS="--ledger"

# Get account balance
ACCOUNT_BALANCE=$($BITSONGD query bank balances ${ACCOUNT_ADDRESS} --chain-id ${CHAIN_ID} --output json \
  | jq -r ".balances[] | select(.denom == \"${DENOM}\") | .amount")
ACCOUNT_BALANCE=${ACCOUNT_BALANCE:-0}

# Get rewards
REWARDS_JSON=$($BITSONGD query distribution rewards ${ACCOUNT_ADDRESS} --chain-id ${CHAIN_ID} --output json)
REWARDS_BALANCE=$(echo "$REWARDS_JSON" \
  | jq -r '.total[]' \
  | grep "${DENOM}" \
  | sed "s/${DENOM}//" \
  | cut -d'.' -f1)
REWARDS_BALANCE=${REWARDS_BALANCE:-0}

# Get commission
COMMISSION_JSON=$($BITSONGD query distribution commission ${VALIDATOR_ADDRESS} --chain-id ${CHAIN_ID} --output json)
COMMISSION_BALANCE=$(echo "$COMMISSION_JSON" \
  | jq -r '.commission.commission[]' \
  | grep "${DENOM}" \
  | sed "s/${DENOM}//" \
  | cut -d'.' -f1)
COMMISSION_BALANCE=${COMMISSION_BALANCE:-0}

# Calculate totals
REW_COM_BALANCE=$((REWARDS_BALANCE + COMMISSION_BALANCE))
NET_BALANCE=$((ACCOUNT_BALANCE + REWARDS_BALANCE + COMMISSION_BALANCE))

if [ "${NET_BALANCE}" -gt $((MINIMUM_DELEGATION_AMOUNT + RESERVATION_AMOUNT)) ]; then
    DELEGATION_AMOUNT=$((NET_BALANCE - RESERVATION_AMOUNT))
else
    DELEGATION_AMOUNT=0
fi

# Format values
to_btsg() { echo "scale=2; $1 / 1000000" | bc; }

ACCOUNT_BALANCE_2=$(to_btsg ${ACCOUNT_BALANCE})
REWARDS_BALANCE_2=$(to_btsg ${REWARDS_BALANCE})
COMMISSION_BALANCE_2=$(to_btsg ${COMMISSION_BALANCE})
REW_COM_BALANCE_2=$(to_btsg ${REW_COM_BALANCE})
NET_BALANCE_2=$(to_btsg ${NET_BALANCE})
RESERVATION_AMOUNT_2=$(to_btsg ${RESERVATION_AMOUNT})
DELEGATION_AMOUNT_2=$(to_btsg ${DELEGATION_AMOUNT})

# Display summary
echo "======================================================"
echo "Account:                ${KEY} (${KEY_TYPE})"
echo "Chain-ID:               ${CHAIN_ID}"
echo "Account Address:        ${ACCOUNT_ADDRESS}"
echo "Validator Address:      ${VALIDATOR_ADDRESS}"
echo "Minimum Re-invest Amt:  ${MINIMUM_DELEGATION_AMOUNT} ${DENOM}"
echo "======================================================"
echo "Account Balance:        ${ACCOUNT_BALANCE_2} ${DENOM}"
echo "Available Rewards:      ${REWARDS_BALANCE_2} ${DENOM}"
echo "Available Commission:   ${COMMISSION_BALANCE_2} ${DENOM}"
echo "Total Available:        ${NET_BALANCE_2} ${DENOM}"
echo "Reservation:            ${RESERVATION_AMOUNT_2} ${DENOM}"
echo "Re-invest Amount:       ${DELEGATION_AMOUNT_2} ${DENOM}"
echo "======================================================"

if [ "${DELEGATION_AMOUNT}" -eq 0 ]; then
    echo "Nothing to re-invset. Exiting."
    exit 0
fi

# Get validator info
VALIDATOR_STATUS=$($BITSONGD query staking validator ${VALIDATOR} --chain-id ${CHAIN_ID} --node ${NODE} --output json)
VALIDATOR_MONIKER=$(echo "${VALIDATOR_STATUS}" | jq -r ".validator.description.moniker")
VALIDATOR_DETAILS=$(echo "${VALIDATOR_STATUS}" | jq -r ".validator.description.details")

echo ""
echo "Delegating to validator ${VALIDATOR} (${VALIDATOR_MONIKER})"
echo "Details: ${VALIDATOR_DETAILS}"
echo ""

# Withdraw rewards
if [ "${REWARDS_BALANCE}" -gt 0 ]; then
  echo "Withdrawing rewards..."
  yes "${KEYRING_PASSPHRASE}" | $BITSONGD tx distribution withdraw-all-rewards \
    --from ${KEY} --chain-id ${CHAIN_ID} ${GAS_FLAGS} ${SIGNING_FLAGS} --yes -b sync
  echo "Waiting 10 seconds for rewards tx to confirm..."
  sleep 10
fi

# Withdraw commission
if [ "${COMMISSION_BALANCE}" -gt 0 ]; then
  echo "Withdrawing commission..."
  yes "${KEYRING_PASSPHRASE}" | $BITSONGD tx distribution withdraw-rewards ${VALIDATOR_ADDRESS} --commission \
    --from ${KEY} --chain-id ${CHAIN_ID} ${GAS_FLAGS} ${SIGNING_FLAGS} --yes -b sync
  echo "Waiting 10 seconds for commission tx to confirm..."
  sleep 10
fi

# Final delegation
echo "Delegating ${DELEGATION_AMOUNT} ${DENOM} to ${VALIDATOR_MONIKER}..."
yes "${KEYRING_PASSPHRASE}" | $BITSONGD tx staking delegate ${VALIDATOR} ${DELEGATION_AMOUNT}${DENOM} \
  --from ${KEY} --chain-id ${CHAIN_ID} ${GAS_FLAGS} ${SIGNING_FLAGS} --yes -b sync

echo ""
echo "✅ Reinvestment complete!"
echo "Have a marvelous BitSong day!"
