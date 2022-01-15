from scripts.deploy import deploy
from scripts.helpful_scripts import get_account, LOCAL_BLOCKCHAIN_ENVIRONMENTS
from brownie import accounts, network, exceptions
import pytest


def test_deploy_nd_start_tender():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    tender = deploy()
    tx = tender.start_tender({"from": account})
    tx.wait(1)
    tx = tender.bid_for_tender({"from": accounts[1], "value": 1*10**18})
    tx.wait(1)
    tx = tender.bid_for_tender({"from": accounts[2], "value": 10*10**18})
    tx.wait(1)
    tx = tender.bid_for_tender({"from": accounts[3], "value": 11*10**18})
    tx.wait(1)
    tx = tender.bid_for_tender({"from": accounts[2], "value": 10*10**18})
    tx.wait(1)
    # check the balances , initial each wallet will have 100 eth in our local test
    assert accounts[1].balance() == ((100-1)*10**18)
    assert accounts[2].balance() == ((100-20)*10**18)
    assert accounts[3].balance() == ((100-11)*10**18)
    tx = tender.end_tender({"from": account})
    tx.wait(1)
    # check the winner
    assert tender.winner() == accounts[2].address
    # account[2] bidded for 20 eth
    assert accounts[2].balance() == ((100-20)*10**18)
    # check for the refunded amount
    assert accounts[1].balance() == 100*10**18
    assert accounts[3].balance() == 100*10**18
