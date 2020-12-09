// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./interfaces/IERC20.sol";
import "./maths/SafeMath.sol";
import "./structures/PoolStruct.sol";
import "./libs/string.sol";

contract PeetStakingContract {
    using SafeMath for uint256;
    using strings for *;

    address private _poolManager;
    
    mapping(bytes32 => PoolStructure) private _pools;

    bytes32[] public allPoolsIndices;
    bytes32[] public activePoolsIndices;

    constructor(address manager) {
        _poolManager = manager;
    }

    event LogNewPublishedPool(
        bytes32 pool_name,
        bool state,
        uint256 roi,
        uint256 participation,
        uint256 startDate,
        uint256 endDate
    );

   event LogUpdatedPublishedPool(
        bytes32 pool_name,
        bool state,
        uint256 roi,
        uint256 participation,
        uint256 startDate,
        uint256 endDate
    );

    function removeActivePoolIndexation(uint index) private {
        if (index >= activePoolsIndices.length) return;
        PoolStructure storage pool = _pools[activePoolsIndices[index]];

        for (uint i = index; i < activePoolsIndices.length-1; i++){
            activePoolsIndices[i] = activePoolsIndices[i+1];
        }
    
        // emit disabled pool event
        emit LogUpdatedPublishedPool(
            pool.pool_name,
            pool.pool_active,
            pool.rewards_pool.roi_percent,
            pool.funds_pool.max_total_participation,
            pool.start_date,
            pool.end_date
        );
    }

    function enableActivePoolIndexation(bytes32 indice, PoolStructure storage pool) private {
        activePoolsIndices.push(indice);

        // emit enabled pool event
        emit LogNewPublishedPool(
            pool.pool_name,
            pool.pool_active,
            pool.rewards_pool.roi_percent,
            pool.funds_pool.max_total_participation,
            pool.start_date,
            pool.end_date
        );
    }

    function addPoolToIndexation(bytes32 indice, PoolStructure storage pool) private {
        // for all pool history
        allPoolsIndices.push(indice);

        // save the indice key in case the pool is already active at publishment
        if (pool.pool_active) {
            enableActivePoolIndexation(indice, pool);
        }
    }

    function publishPool(bytes32 name, address in_asset,
        address out_asset, uint256 start_date, uint256 end_date,
        bool state_pool, bool auto_renew, uint256 roi, uint256 hodl_mode_bonus,
        uint hodl_mode_period, uint256 max_reward, uint max_wallet, uint max_total) public returns(bytes32) {
        
        bytes32 pool_indice = keccak256(abi.encode(name,
          strings.uint2str(start_date), strings.uint2str(end_date)));

        // Pool base structure
        PoolStructure storage new_pool = _pools[pool_indice];
        new_pool.pool_name = name;
        new_pool.input_asset = in_asset;
        new_pool.output_asset = out_asset;
        new_pool.start_date = start_date;
        new_pool.end_date = end_date;
        new_pool.pool_active = state_pool;
        new_pool.pool_auto_renew = auto_renew;
        
        // Pool Rewards
        PoolRewards memory rewards;
        rewards.roi_percent = roi;
        rewards.hodl_mode_bonus = hodl_mode_bonus;
        rewards.hodl_mode_period = hodl_mode_period;
        new_pool.rewards_pool = rewards;
        //

        // Pool Funds
        PoolFunds memory funds;
        funds.max_amount_reward = max_reward;
        funds.max_wallet_participation = max_wallet;
        funds.max_total_participation = max_total;
        new_pool.funds_pool = funds;
        //

        addPoolToIndexation(pool_indice, _pools[pool_indice]);
        return pool_indice;
    }

    function fetchLivePools() public view returns(bytes32 [] memory, address [] memory,
    address [] memory, uint256 [] memory, uint256 [] memory) {
        bytes32 [] memory names = new bytes32[](activePoolsIndices.length);
        address [] memory input_assets = new address[](activePoolsIndices.length);
        address [] memory output_assets = new address[](activePoolsIndices.length);
        uint256 [] memory starts = new uint256[](activePoolsIndices.length);
        uint256 [] memory ends = new uint256[](activePoolsIndices.length);

        for (uint i = 0; i < activePoolsIndices.length; i++) {
            names[i] =  _pools[activePoolsIndices[i]].pool_name;
            input_assets[i] = _pools[activePoolsIndices[i]].input_asset;
            output_assets[i] = _pools[activePoolsIndices[i]].output_asset;
            starts[i] = _pools[activePoolsIndices[i]].start_date;
            ends[i] = _pools[activePoolsIndices[i]].end_date;
        }
        return (names, input_assets,
         output_assets, starts, ends);
    }
    
}