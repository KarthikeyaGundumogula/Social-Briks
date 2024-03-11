//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MarketAPI} from "filecoin-solidity/v0.8/MarketAPI.sol";
import {CommonTypes} from "filecoin-solidity/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "filecoin-solidity/v0.8/types/MarketTypes.sol";
import {AccountTypes} from "filecoin-solidity/v0.8/types/AccountTypes.sol";
import {AccountCBOR} from "filecoin-solidity/v0.8/cbor/AccountCbor.sol";
import {MarketCBOR} from "filecoin-solidity/v0.8/cbor/MarketCbor.sol";
import {BytesCBOR} from "filecoin-solidity/v0.8/cbor/BytesCbor.sol";
import {BigNumbers, BigNumber} from "solidity-BigNumber/BigNumbers.sol";
import {BigInts} from "filecoin-solidity/v0.8/utils/BigInts.sol";
import {CBOR} from "solidity-cborutils/contracts/CBOR.sol";
import {Misc} from "filecoin-solidity/v0.8/utils/Misc.sol";
import {FilAddresses} from "filecoin-solidity/v0.8/utils/FilAddresses.sol";

using CBOR for CBOR.CBORBuffer;

struct IntialDealRequestID {
    bytes32 id;
    uint256 dealIndex;
    bool valid;
}

struct ProviderSet {
    bytes provider;
    bool valid;
}

struct InitialDeal {
    bytes provider;
    uint64 max_peice_size;
    uint64 min_piece_size;
    bool verified_deal;
    int64 start_epoch;
    int64 end_epoch;
}

struct DealRequest {
    bytes piece_cid;
    uint64 piece_size;
    bool verified_deal;
    string label;
    int64 start_epoch;
    int64 end_epoch;
    uint256 storage_price_per_epoch;
    uint256 provider_collateral;
    uint256 client_collateral;
    uint64 extra_params_version;
    ExtraParamsV1 extra_params;
}

struct ExtraParamsV1 {
    string location_ref;
    uint64 car_size;
    bool skip_ipni_announce;
    bool remove_unsealed_copy;
}

contract DataLimitContract {
    address owner;

    constructor() {
        owner = msg.sender;
    }
}
