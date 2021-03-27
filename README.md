## Cosmos Hub reinvestment script for rewards

Courtesy of [Validator🌐Network](https://validator.network).
Adjusted for bitsong by Thamar

The provided script enable delegators to claim all their staking rewards and reinvest them, to receive compounded interest. In addition to this, it supports withdrawal of validator commission.

Not sure about this [Thamar] Requirement is to run a local full node as the script defaults to using the https://localhost:443 RPC endpoint.


### Installation

First download the script and make it executable:
```
curl -O https://raw.githubusercontent.com/block-finance/cosmoshub-scripts/master/cosmoshub-reinvest-rewards.sh
chmod +x cosmoshub-reinvest-rewards.sh
```

### Enjoy the show

The script has some default settings and only requires you to provide the name for the account you wish to work with.

The name must match the output of the NAME: column of `bitsongcli keys list`:  

You can now run the script:
```
./bitsong-reinvest-rewards.sh testkey1
```

and expect output such as:

```
======================================================
Account: testkey1 (local)
Address: btsg1mjgh0rejtljxg8rurmxlrff0kk2ztxmgc8mvzj
======================================================
Account balance:   20000122217ubtsg
Available rewards: 23588169ubtsg
Net balance:       20023710386ubtsg
Reservation:       100000000ubtsg

You are about to delegate 19923710386uabtsg to bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj:
  Moniker: Thamar
  Details: Highly resilient and secure validator operating out of Northern Europe. See website for terms of service.
```

### Customize settings (optional)
If you like, you can use your favorite text editor to change some of the default settings of the script.

```
##############################################################################
# User settings.
##############################################################################

MINIMUM_DELEGATION_AMOUNT="25000000"
RESERVATION_AMOUNT="100000000"
VALIDATOR="bitsongvaloper1d9mue6sxrxgcd8rz6cdmeamw4cey3c243ll3gj"

##############################################################################
```

Take care to specify the `RESERVATION_AMOUNT` which is the minimum amount of ubtsg that will remain available in your account.

You can delegate to any validator you prefer by changing `VALIDATOR` variable.
