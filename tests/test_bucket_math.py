import brownie
from brownie import Contract
import pytest
import math


def indexToPricePy(index: int) -> int:
    # x^y = 2^(y*log_2(x))
    return 2 ** (index * math.log2(1.005))

def priceToIndexPy(price: int) -> int:
    index = math.log2(price) / math.log2(1.005)
    return math.floor(index)

WAD = 10 ** 18

def test_index_to_price(bucket_math):

    index_to_price_test_cases = [
        # 1,
        2,
        3,
        4,
        10,
        50,
        350,
        3000,
        6926
    ]

    for i in index_to_price_test_cases:
        price = bucket_math.indexToPrice(i)

        print(f"testing index: {i}", price, indexToPricePy(i))
        assert price == indexToPricePy(i) * WAD

def test_price_to_index(bucket_math):
    price = 100

    price_to_index_test_cases = [
        # .5,
        # 1.0100249999999997,
        5,
        10000,
        450000
    ]

    for p in price_to_index_test_cases:

        index = bucket_math.priceToIndex(p)
        index_py = priceToIndexPy(p)

        print(f"testing price: {p}", index, index_py)
        assert index == index_py
