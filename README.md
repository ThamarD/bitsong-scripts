## Bitsong reinvestment script for rewards and commission

Created for Bitsong by Thamar
Courtesy of Validator Network


The provided script enable Validators and delegators to claim their staking rewards and reinvest them, to receive compounded interest. In addition to this, it supports withdrawal of validator commission.

Requirement is to run a local full node as the script defaults to using the https://localhost:443 RPC endpoint.


### Installation

First download the script and make it executable:
```
curl -O https://raw.githubusercontent.com/ThamarD/cosmoshub-scripts/master/bitsong-reinvest-rewards.sh
chmod +x bitsong-reinvest-rewards.sh
```

### Operating

The script has some default settings and only requires you to provide the name for the account you wish to work with.

The name must match the output of the NAME: column of `bitsongcli keys list`:  

You can now run the script:
```
./bitsong-reinvest-rewards.sh testkey1
```

and expect output such as:

```
======================================================
Account: thamar_wallet (local)
Address: bitsong1d9mue6sxrxgcd8rz6cdmeamw4cey3c24smrcc0
======================================================
Account balance:      9.85 - 9854455ubtsg
Available rewards:    2.80 - 2801537ubtsg
Available commission: 4.02 - 4028064ubtsg
Available rew+commis: 6.82 - 6829601ubtsg
Net balance:          16.68 - 16684056ubtsg
Reservation:          10.00 - 10000000ubtsg

Nothing to delegate.
```

No rewards and commission are delegation because parameters are not met.


### Customize settings (optional)
Use a text editor e.g. nano to change some of the default settings of the script.

```
##############################################################################
# User settings.
##############################################################################

KEY=""                                  # This is the key you wish to use for signing transactions, listed in first column of "bitsongcli keys list".
KEYRING_PASSPHRASE=""                   # Only populate if you want to run the script periodically. This is UNSAFE and should only be done if you know what you are doing.
DENOM="ubtsg"                           # Coin denominator is ubtsg ("micro-btsg"). 1 btsg = 1000000 ubtsg.
MINIMUM_DELEGATION_AMOUNT="25000000"    # Only perform delegations above this amount of ubtsg. Default: 25btsg.
RESERVATION_AMOUNT="10000000"           # Keep this amount of ubtsg in account. Default: 10btsg.
VALIDATOR="bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj"        # Reinvest and vote for this Validator; Default is validator THAMAR. Thank you for your support :-); but hey, you should change this ...

##############################################################################
```

Take care to specify the `RESERVATION_AMOUNT` which is the minimum amount of ubtsg that will remain available in your account.
You can delegate to any validator you prefer by changing `VALIDATOR` variable.

### Run script periodically (optional)
You can run this script as much as you like, I let it run once a day. You can configure a crontab like this
- To configure this in the crontab, crontab runs every 10 minutes and this one, runs at 18:00 hour.
  - ```crontab -e```
  -  ```0 18 * * * * /bin/bash ~/bitsong-reinvest-rewards.sh my_wallet >mywithdraw.log 2>&1```

I only fill in the ```KEYRING_PASSPHRASE``` and ```VALIDATOR``` and in the crontab line ```my_wallet```
