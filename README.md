## Bitsong reinvestment script for rewards and commission

Created for Bitsong by Thamar
Courtesy of Validator Network


The provided script enable Validators and delegators to claim their staking rewards and reinvest them, to receive compounded interest. In addition to this, it supports withdrawal of validator commission.

You can run a local full node, the script default uses the https://localhost:26657 RPC endpoint, or you can change the ```NODE``` parameter in the script with an external node that you trust.


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
./bitsong-reinvest-rewards.sh thamar_wallet
```

and expect output such as:

```
======================================================
Account: thamar_wallet (local)
Address: bitsong1d9mue6sxrxgcd8rz6cdmeamw4cey3c24smrcc0
======================================================
Account balance:      9.85 - 9854434ubtsg
Available rewards:    18.38 - 18383546ubtsg
Available commission: 26.44 - 26449475ubtsg
Available rew+commis: 44.83 - 44833021ubtsg
Net balance:          54.68 - 54687455ubtsg
Reservation:          10.00 - 10000000ubtsg

You are about to delegate 44687455ubtsg to bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj:
  Moniker: thamar
  Details:

Withdrawing rewards ... Account sequence: 283
    echo Signing Flags:
gas estimate: 139189
```


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

```crontab -e```

```0 18 * * * * /bin/bash ~/bitsong-reinvest-rewards.sh my_wallet >mywithdraw.log 2>&1```

I only fill in the ```KEYRING_PASSPHRASE``` and ```VALIDATOR``` in the user settings in the script and in the crontab line change the ```my_wallet``` into the correct wallet name.
