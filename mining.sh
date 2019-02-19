#!/bin/bash

# Author: Daniel Lima

# TODO: the tx math is wrong.. not time left to work on it.

# Description: simple solo "mining" example 

# setup

difficult=1
blocknumber=1 # genesis

alicebalance=40000
bobbalance=20000

# miner balance
minerjackbalance=0

# first transaction
amount=$RANDOM

blockchain="alice:$amount:bob\nalice:$alicebalance:alice"

# alice after first tx
alicebalance=$((alicebalance - amount))

# ------------------

nextBlockTimestamp() {
    timeblock=$(date +%s)
}
nextBlockTimestamp

# genesis block
genesis=$(echo $blocknumber$blockchain$timeblock | shasum | cut -c1-32)
previousblockhash=$genesis

# ------------------

checkBalance() {
  echo Alice balance: $alicebalance 
  echo Bob balance: $bobbalance
}

checkTx() {
  # check balance

# global  amount=$1

  final_balance=$(( alicebalance - amount ))
  if [ $final_balance -lt 0 ]
  then
    echo 1 #out of money
  else
    echo 0
  fi
}

# update balances
sendTx() {

 # amount=$2

  if [ $( checkTx $amount ) -eq 0 ]; then

    alicebalance=$(( alicebalance - amount ))
    bobbalance=$(( bobbalance + amount ))

    return 0

  else

    return 1

  fi
}


# increase 50% of the rounds
increaseDiff() {

    if [ $(( $RANDOM % 2 )) = 0 ] ; then
        echo 
        difficult=$(( difficult + 1 ))
        echo -n Increasing difficulty to $difficult ... 

        sleep 1
        echo Done.
    fi

}

# 0 00 000 0000 ..
increaseChallenge() {
    echo -n Setting up new challenge..

    challenge=$(head -c $difficult < /dev/zero | tr '\0' '0')

    sleep 1
    echo Done.
}

# ------------------

echo 
echo "======================================"
echo "      Basic cryptomining script       "
echo "======================================"
echo 

increaseChallenge

mineit() {
    echo Starting .. 

    for i in {0..100000}
    do 

        # SHA256(index + previousHash + timestamp + data + nonce)
        hashres=$(echo -n $blocknumber$previousblockhash$timeblock$blockchain$i | shasum | cut -c1-32)

        echo "Mine attempt $i (nonce): $hashres"

        if [[ ${challenge} == ${hashres:0:$difficult} ]]
        then
            echo 
            echo "======================================"
            echo "     BLOCK $blocknumber MINED!        "
            echo "======================================"

            blocknumber=$(( blocknumber + 1 ))

            echo Block found: $hashres
            echo
            echo Previous blockhash: $previousblockhash
            echo Genesis block: $genesis
            echo Difficulty: $difficult
            echo Timestamp: $timeblock
            echo
            echo -e "Transactions:\n$blockchain"
            echo 

            nextBlockTimestamp
            increaseDiff
            increaseChallenge

            amount=$RANDOM
            echo $amount ...

            checkBalance

             echo Alice sending $amount to Bob...
            if [[ $( sendTx $TX $amount ) -eq 0 ]]
            then
                echo $amount ...
                TX="alice:$amount:bob\nalice:$((alicebalance - amount)):alice"

                # update blockchain

                blockchain=$blockchain"\n"$TX
            fi

            echo 
            
            /bin/sleep 2

            previousblockhash=$hashres

            break
        fi
    done
}

rounds=4
while [ $rounds -gt 0 ]
do
    mineit
    (( rounds-- ))
done


