//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MarketAPI} from "filecoin-solidity/v0.8/MarketAPI.sol";
import {CommonTypes} from "filecoin-solidity/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "filecoin-solidity/v0.8/types/MarketTypes.sol";
import {AccountTypes} from "filecoin-solidity/v0.8/types/AccountTypes.sol";
import {MarketCBOR} from "filecoin-solidity/v0.8/cbor/MarketCbor.sol";
import {AccountCBOR} from "filecoin-solidity/v0.8/cbor/AccountCbor.sol";
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
}

struct DealRequestID {
    bytes32 id;
    uint256 dealIndex;
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

function serializeAggrementParams(
    Aggrement memory params
) pure returns (bytes memory) {
    CBOR.CBORBuffer memory buf = CBOR.create(64);
    buf.startFixedArray(7);
    buf.writeBytes(params.provider);
    buf.writeUInt64(params.threshold_peice_size);
    buf.writeUInt64(params.min_piece_size);
    buf.writeBool(params.verified_deal);
    buf.writeInt64(params.start_epoch);
    buf.writeUInt64(params.currently_stored_data_size);
    buf.writeUInt256(params.storage_price_per_epoch);
    buf.writeInt64(params.end_epoch);
    return buf.data();
}

contract GrowingDataDeal {
    using AccountCBOR for *;
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
        AggrementSubmitted,
        AggrementAccepted,
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
    mapping(bytes32 => DataAddonStatus) dataAddonStatus;
    mapping(bytes => DataAddonStatus) dataCidStatus;
    mapping(bytes32 => bytes32) dealAggrementMap;
    mapping(bytes => bytes32) peiceCidDealMap;

    Aggrement[] public aggrements;
    DealRequest[] public deals;

    event AggrementRequestCreated(
        bytes32 indexed id,
        bytes provider,
        uint64 threshold_peice_size,
        bool verified_deal
    );

    event DataAddOnRequested(bytes32 indexed id, bytes provider);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyClient(address sender) {
        require(sender == owner, "Only client can call this function");
        _;
    }

    function getAggrement(bytes32 id) internal view returns (Aggrement memory) {
        uint index = aggrementRequests[id].index;
        return aggrements[index];
    }

    function getDeal(bytes32 id) internal view returns (DealRequest memory) {
        uint index = dealRequests[id].dealIndex;
        return deals[index];
    }

    function makeAggrementRequest(Aggrement calldata aggrementParams) public {
        uint index = aggrements.length;
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, index)
        );
        aggrementRequests[id] = AggrementRequestID(id, index);
        aggrements.push(aggrementParams);
        aggrementStatus[id] = AggrementStatus.AggrementSubmitted;
        emit AggrementRequestCreated(
            id,
            aggrementParams.provider,
            aggrementParams.threshold_peice_size,
            aggrementParams.verified_deal
        );
    }

    function acceptAggrementRequest(bytes32 id) public {
        require(
            aggrementStatus[id] == AggrementStatus.AggrementSubmitted,
            "Aggrement request not found"
        );
        aggrementStatus[id] = AggrementStatus.AggrementAccepted;
    }

    function sendDataDeal(
        DealRequest calldata deal,
        bytes32 aggrementID
    ) public {
        Aggrement memory agg = getAggrement(aggrementID);
        uint64 current_data_size = agg.currently_stored_data_size;
        uint64 threshold_size = agg.threshold_peice_size;
        if (
            dataCidStatus[deal.piece_cid] == DataAddonStatus.RequestSubmitted ||
            dataCidStatus[deal.piece_cid] == DataAddonStatus.DataRecieved
        ) {
            revert("deal with this pieceCid already published or activated");
        }
        if (deal.piece_size > threshold_size - current_data_size) {
            revert("peice size is greater than the agrred threshold size");
        }
        uint index = deals.length;
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, index)
        );
        dealRequests[id] = DealRequestID(id, index);
        deals.push(deal);
        dataAddonStatus[id] = DataAddonStatus.RequestSubmitted;
        dealAggrementMap[id] = aggrementID;
        peiceCidDealMap[deal.piece_cid] = id;
        dataCidStatus[deal.piece_cid] = DataAddonStatus.RequestSubmitted;
        emit DataAddOnRequested(id, deal.provider);
    }

    function getAggrementProposal(
        bytes32 aggrementID
    ) public view returns (bytes memory) {
        require(
            aggrementStatus[aggrementID] == AggrementStatus.AggrementSubmitted,
            "Aggrement request not found"
        );
        require(
            msg.sender == owner,
            "Only client choosen sp can call this function"
        );
        Aggrement memory aggrement = getAggrement(aggrementID);
        return serializeAggrementParams(aggrement);
    }

    function getDealProposal(
        bytes32 dealID
    ) public view returns (bytes memory) {
        require(
            dataAddonStatus[dealID] == DataAddonStatus.RequestSubmitted ||
                dataAddonStatus[dealID] == DataAddonStatus.DataRecieved,
            "Deal request not found"
        );
        require(
            msg.sender == owner,
            "Only client choosen sp can call this function"
        );
        DealRequest memory deal = getDeal(dealID);

        MarketTypes.DealProposal memory ret;
        ret.piece_cid = CommonTypes.Cid(deal.piece_cid);
        ret.piece_size = deal.piece_size;
        ret.verified_deal = deal.verified_deal;
        ret.client = FilAddresses.fromEthAddress(address(this));
        ret.provider = FilAddresses.fromBytes(deal.provider);
        ret.label = CommonTypes.DealLabel(bytes(deal.label), true);
        ret.start_epoch = CommonTypes.ChainEpoch.wrap(deal.start_epoch);
        ret.end_epoch = CommonTypes.ChainEpoch.wrap(deal.end_epoch);
        ret.storage_price_per_epoch = BigInts.fromUint256(
            deal.storage_price_per_epoch
        );
        ret.provider_collateral = BigInts.fromUint256(deal.provider_collateral);
        ret.client_collateral = BigInts.fromUint256(deal.client_collateral);
        return MarketCBOR.serializeDealProposal(ret);
    }

    function authenticateMessage(bytes memory params) public view {
        if (msg.sender != MARKET_ACTOR_ETH_ADDRESS) {
            revert("Only market actor can call this function");
        }
        AccountTypes.AuthenticateMessageParams memory amp = params
            .deserializeAuthenticateMessageParams();
        MarketTypes.DealProposal memory proposal = MarketCBOR
            .deserializeDealProposal(amp.message);
        bytes32 dealID = peiceCidDealMap[proposal.piece_cid.data];
        DealRequest memory req = getDeal(dealID);
        if (dataAddonStatus[dealID] != DataAddonStatus.DataRecieved) {
            revert("data already claimed or not found");
        }
        (
            uint256 proposalStoragePricePerEpoch,
            bool storagePriceConverted
        ) = BigInts.toUint256(proposal.storage_price_per_epoch);
        (uint256 proposalClientCollateral, bool collateralConverted) = BigInts
            .toUint256(proposal.storage_price_per_epoch);
        require(
            storagePriceConverted && collateralConverted,
            "Issues converting uint256 to BigInt, may not have accurate values"
        );
        require(
            proposalStoragePricePerEpoch <= req.storage_price_per_epoch,
            "storage price greater than request amount"
        );
        require(
            proposalClientCollateral <= req.client_collateral,
            "client collateral greater than request amount"
        );
    }

    function dealNotify(bytes memory params) internal {
        require(
            msg.sender == MARKET_ACTOR_ETH_ADDRESS,
            "msg.sender needs to be market actor f05"
        );

        MarketTypes.MarketDealNotifyParams memory mdnp = MarketCBOR
            .deserializeMarketDealNotifyParams(params);
        MarketTypes.DealProposal memory proposal = MarketCBOR
            .deserializeDealProposal(mdnp.dealProposal);
        require(
            dataCidStatus[proposal.piece_cid.data] !=
                DataAddonStatus.DataRecieved,
            "data already claimed"
        );
        dataCidStatus[proposal.piece_cid.data] = DataAddonStatus.DataRecieved;
    }

    function handle_filecoin_method(
        uint64 method,
        uint64,
        bytes memory params
    ) public returns (uint32, uint64, bytes memory) {
        bytes memory ret;
        uint64 codec;
        // dispatch methods
        if (method == AUTHENTICATE_MESSAGE_METHOD_NUM) {
            authenticateMessage(params);
            // If we haven't reverted, we should return a CBOR true to indicate that verification passed.
            CBOR.CBORBuffer memory buf = CBOR.create(1);
            buf.writeBool(true);
            ret = buf.data();
            codec = Misc.CBOR_CODEC;
        } else if (method == MARKET_NOTIFY_DEAL_METHOD_NUM) {
            dealNotify(params);
        } else {
            revert("the filecoin method that was called is not handled");
        }
        return (0, codec, ret);
    }
}
