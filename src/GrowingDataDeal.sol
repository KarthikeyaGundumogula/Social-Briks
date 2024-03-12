//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MarketAPI} from "filecoin-solidity/v0.8/MarketAPI.sol";
import {CommonTypes} from "filecoin-solidity/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "filecoin-solidity/v0.8/types/MarketTypes.sol";
import {AccountTypes} from "filecoin-solidity/v0.8/types/AccountTypes.sol";
import {MarketCBOR} from "filecoin-solidity/v0.8/cbor/MarketCbor.sol";
import {BytesCBOR} from "filecoin-solidity/v0.8/cbor/BytesCbor.sol";
import {BigNumbers, BigNumber} from "solidity-BigNumber/BigNumbers.sol";
import {BigInts} from "filecoin-solidity/v0.8/utils/BigInts.sol";
import {CBOR} from "solidity-cborutils/contracts/CBOR.sol";
import {Misc} from "filecoin-solidity/v0.8/utils/Misc.sol";
import {FilAddresses} from "filecoin-solidity/v0.8/utils/FilAddresses.sol";

using CBOR for CBOR.CBORBuffer;

struct AggrementRequestID {
    bytes32 id;
    uint256 index;
    bool valid;
}

struct DealRequestID {
    bytes32 id;
    uint256 dealIndex;
    bool valid;
}

struct Provider {
    bytes provider;
    bool valid;
}

struct Aggrement {
    bytes provider;
    uint64 threshold_peice_size;
    uint64 min_piece_size;
    bool verified_deal;
    int64 start_epoch;
    uint64 currently_stored_data_size;
    uint256 storage_price_per_epoch;
    int64 end_epoch;
}

struct DealRequest {
    bytes piece_cid;
    uint64 piece_size;
    bytes provider;
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

function serializeExtraParamsV1(
    ExtraParamsV1 memory params
) pure returns (bytes memory) {
    CBOR.CBORBuffer memory buf = CBOR.create(64);
    buf.startFixedArray(4);
    buf.writeString(params.location_ref);
    buf.writeUInt64(params.car_size);
    buf.writeBool(params.skip_ipni_announce);
    buf.writeBool(params.remove_unsealed_copy);
    return buf.data();
}

contract DataLimitContract {
    using MarketCBOR for *;

    uint64 public constant AUTHENTICATE_MESSAGE_METHOD_NUM = 2643134072;
    uint64 public constant DATACAP_RECEIVER_HOOK_METHOD_NUM = 3726118371;
    uint64 public constant MARKET_NOTIFY_DEAL_METHOD_NUM = 4186741094;
    address public constant MARKET_ACTOR_ETH_ADDRESS =
        address(0xff00000000000000000000000000000000000005);
    address public constant DATACAP_ACTOR_ETH_ADDRESS =
        address(0xfF00000000000000000000000000000000000007);

    address immutable owner;

    enum AggrementStatus {
        None,
        RequestSubmitted,
        DealAccepted,
        AggrementCompleted
    }

    enum DataAddonStatus {
        None,
        RequestSubmitted,
        DataRecieved
    }

    mapping(bytes32 => AggrementRequestID) aggrementRequests;
    mapping(bytes32 => DealRequestID) dealRequests;
    mapping(bytes32 => AggrementStatus) aggrementStatus;
    mapping(bytes32 => Provider) aggrementProviders;
    mapping(bytes32 => DataAddonStatus)  dataAddonStatus;

    Aggrement[] public aggrements;
    DealRequest[] public deals;

    event AggrementRequestCreated(
        bytes32 indexed id,
        bytes provider,
        uint64 threshold_peice_size,
        bool verified_deal
    );

    event DataAddOnRequested(
        bytes32 indexed id,
        bytes provider
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyClient(address sender) {
        require(sender == owner, "Only client can call this function");
        _;
    }

    function getAggrement(bytes32 id) public view returns (Aggrement memory) {
        uint index = aggrementRequests[id].index;
        return aggrements[index];
    }

    function getDeal(bytes32 id) public view returns (DealRequest memory) {
        uint index = dealRequests[id].dealIndex;
        return deals[index];
    }

    function makeAggrementRequest(Aggrement calldata aggrementParams) public {
        uint index = aggrements.length;
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, index)
        );
        aggrementRequests[id] = AggrementRequestID(id, index, true);
        aggrements.push(aggrementParams);
        aggrementStatus[id] = AggrementStatus.RequestSubmitted;
        aggrementProviders[id] = Provider(aggrementParams.provider, true);
        emit AggrementRequestCreated(
            id,
            aggrementParams.provider,
            aggrementParams.threshold_peice_size,
            aggrementParams.verified_deal
        );
    }

    function acceptAggrementRequest(bytes32 id) public {
        require(
            aggrementStatus[id] == AggrementStatus.RequestSubmitted,
            "Aggrement request not found"
        );
        aggrementStatus[id] = AggrementStatus.DealAccepted;
    }

    function sendDataDeal(
        DealRequest calldata deal,
        bytes32 aggrementID
    ) public {
        Aggrement memory agg = getAggrement(aggrementID);
        uint64 current_data_size = agg.currently_stored_data_size;
        uint64 threshold_size = agg.threshold_peice_size;
        
        if( deal.piece_size > threshold_size-current_data_size){
            revert("peice size is greater than the agrred threshold size");
        }
        uint index = deals.length;
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, index)
        );
        dealRequests[id] = DealRequestID(id, index, true);
        deals.push(deal);
        dataAddonStatus[id] = DataAddonStatus.DataRecieved;

        emit DataAddOnRequested(
            id,
            deal.provider
        );
    }


}
