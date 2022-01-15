from brownie import Tender, config, network, MockV3Aggregator
from scripts.helpful_scripts import get_account, deploy_mocks, LOCAL_BLOCKCHAIN_ENVIRONMENTS


def deploy():
    account = get_account()
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address
    tender = Tender.deploy(price_feed_address,
                           {"from": account},
                           publish_source=config["networks"][network.show_active()].get("verify"))

    print(f"Contract deployed to {tender.address}")
    return tender


def main():
    deploy()
