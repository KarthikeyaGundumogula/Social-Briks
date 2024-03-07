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
import {AccountAPI} from "filecoin-solidity/v0.8/AccountAPI.sol";

using CBOR for CBOR.CBORBuffer;

struct RequestId {
    bytes32 requestId;
    bool valid;
}

struct RequestIdx {
    uint256 idx;
    bool valid;
}

struct ProviderSet {
    bytes provider;
    bool valid;
}

struct Deal {
    bytes piece_cid;
    address client;
    address provider;
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

contract One2OneDeal {
    using AccountCBOR for *;
    using MarketCBOR for *;

    address public immutable owner;

    uint64 public constant AUTHENTICATE_MESSAGE_METHOD_NUM = 2643134072;
    uint64 public constant DATACAP_RECEIVER_HOOK_METHOD_NUM = 3726118371;
    uint64 public constant MARKET_NOTIFY_DEAL_METHOD_NUM = 4186741094;
    address public constant MARKET_ACTOR_ETH_ADDRESS =
        address(0xff00000000000000000000000000000000000005);
    address public constant DATACAP_ACTOR_ETH_ADDRESS =
        address(0xfF00000000000000000000000000000000000007);

    enum Status {
        None,
        RequestSubmitted,
        DealPublished,
        DealActivated,
        DealTerminated
    }

    mapping(bytes32 => RequestIdx) public dealRequestIdx; // contract deal id -> deal index
    Deal[] public deals;

    mapping(bytes => RequestId) public pieceRequests; // commP -> dealProposalID
    mapping(bytes => ProviderSet) public pieceProviders; // commP -> provider
    mapping(bytes => uint64) public pieceDeals; // commP -> deal ID
    mapping(bytes => Status) public pieceStatus;

    event DealProposalCreate(
        bytes32 dealId,
        uint64 pieceSize,
        bool verifiedDeal,
        address provider,
        uint256 storagePricePerEpoch
    );

    constructor() {
        owner = msg.sender;
    }

    function getDealByIndex(uint256 index) public view returns (Deal memory) {
        return deals[index];
    }

    function getDealRequest(
        bytes32 requestId
    ) internal view returns (Deal memory) {
        RequestIdx memory ri = dealRequestIdx[requestId];
        address provider = deals[ri.idx].provider;
        require(provider == msg.sender, "only provider can access deal");
        require(ri.valid, "proposalId not available");
        return deals[ri.idx];
    }

    function makeDeal(Deal calldata deal) public returns (bytes32) {
        require(msg.sender == owner, "only owner can make deal");
        require(deal.client == msg.sender, "client must be the sender");

        if (
            pieceStatus[deal.piece_cid] == Status.DealPublished ||
            pieceStatus[deal.piece_cid] == Status.DealActivated
        ) {
            revert("deal with this pieceCid already published or activated");
        }

        uint256 index = deals.length;
        deals.push(deal);

        bytes32 id = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, index)
        );
        dealRequestIdx[id] = RequestIdx(index, true);

        pieceRequests[deal.piece_cid] = RequestId(id, true);
        pieceStatus[deal.piece_cid] = Status.RequestSubmitted;

        emit DealProposalCreate(
            id,
            deal.piece_size,
            deal.verified_deal,
            deal.provider,
            deal.storage_price_per_epoch
        );

        return id;
    }

    function authenticateMessage(bytes memory params) internal view {
        require(
            msg.sender == MARKET_ACTOR_ETH_ADDRESS,
            "msg.sender needs to be market actor f05"
        );

        AccountTypes.AuthenticateMessageParams memory amp = params
            .deserializeAuthenticateMessageParams();
        MarketTypes.DealProposal memory proposal = MarketCBOR
            .deserializeDealProposal(amp.message);

        bytes memory pieceCid = proposal.piece_cid.data;
        require(
            pieceRequests[pieceCid].valid,
            "piece cid must be added before authorizing"
        );
        require(
            !pieceProviders[pieceCid].valid,
            "deal failed policy check: provider already claimed this cid"
        );

        Deal memory req = getDealRequest(pieceRequests[pieceCid].requestId);
        require(
            proposal.verified_deal == req.verified_deal,
            "verified_deal param mismatch"
        );
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
            pieceRequests[proposal.piece_cid.data].valid,
            "piece cid must be added before authorizing"
        );
        require(
            !pieceProviders[proposal.piece_cid.data].valid,
            "deal failed policy check: provider already claimed this cid"
        );

        pieceProviders[proposal.piece_cid.data] = ProviderSet(
            proposal.provider.data,
            true
        );
        pieceDeals[proposal.piece_cid.data] = mdnp.dealId;
        pieceStatus[proposal.piece_cid.data] = Status.DealPublished;
    }
}
