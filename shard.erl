-module(shard).
-export([partition_into_shards/2]).

% partition ratings list across N sublists
% s.t. rating {Uid,Rating} is added to sublist element Uid % N

% eg1
% partition_into_shards( [{0,r0},{1,r1},{3,r3},{4,r4},{5,r5},{7,r7}], 3) ->
%    [ [{0,r0},{3,r3}],        [{1,r1},{4,r4},{7,r7}], [{5,r5}] ]

% eg2
% partition_into_shards( [{0,t0},{2,t2},{3,t3},{5,t5},{6,t6}], 3) ->				
%    [ [{0,t0},{3,t3},{6,t6}], [],                     [{2,t2},{5,t5} ]

partition_into_shards(Ratings,NumShards) ->
    partition_into_shards(Ratings, NumShards, dict:new()).

partition_into_shards([], NumShards, Result) ->
    [ fetch_or_empty(K-1,Result) || K <- lists:seq(1,NumShards) ];

partition_into_shards([{Uid,_Rating}=NextRating|OtherRatings], NumShards, Result) ->
    Shard = Uid rem NumShards, % 0 .. NumShards-1
    NewResult = dict:append(Shard, NextRating, Result),
    partition_into_shards(OtherRatings, NumShards, NewResult).
    
fetch_or_empty(K,Dict) ->
    case dict:is_key(K,Dict) of
	true  -> dict:fetch(K,Dict);
	false -> []
    end.
			       

    
