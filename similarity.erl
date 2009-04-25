-module(similarity).
-export([start/0, stop/0, write_movie_ratings/1, write_single_movie_rating/2, calc_for/2, calc_all_for/2, worker_init/1]).
-include_lib("consts.hrl").

% api

start() ->
    put(workers, [ spawn(?MODULE, worker_init, [N]) || N <- lists:seq(1,?NUM_WORKERS) ]).

stop() ->
    broadcast(stop).

write_movie_ratings(Ids) ->
    broadcast(delete_all_ratings),
    rpc:pmap({?MODULE,write_single_movie_rating}, [get(workers)], Ids).
%    lists:foreach(
%      fun(Mid) -> write_single_movie_rating(Mid) end,
%      Ids).	     
    
write_single_movie_rating(Mid, Workers) ->
    Ratings = movie_data:ratings_for(Mid),
    io:format("~w ~w 2 #ratings=~w\n",[self(),Mid,length(Ratings)]),
    RatingsShards = shard:partition_into_shards(Ratings, ?NUM_WORKERS),
    io:format("~w ~w 3\n",[self(),Mid]),
    lists:foreach(
      fun({WorkerPid,RatingsSubList}) -> 
	      io:format("~w sending ~w ~w ratings\n",[self(),WorkerPid,length(RatingsSubList)]),
	      WorkerPid ! { ratings, Mid, RatingsSubList }
      end,
      lists:zip(Workers, RatingsShards)
      ),
    ok.		

calc_all_for(Mid, Ids) ->	        
    worker ! { calc_all_for, Mid, Ids, self() },
    receive Coeffs -> Coeffs after 60000 -> timeout end.

broadcast(Msg) ->
    [ W ! Msg || W <- get(workers) ].

% worker

worker_init(N) ->
    self() ! {start, N},
    worker().

worker() ->
    receive
	{start,N} ->
	    io:format("~w start #~w\n",[self(),N]),
	    movie_data:start(N),
	    worker();
	stop ->
	    io:format("~w stop\n",[self()]),
	    movie_data:stop(),	    
	    worker();
	delete_all_ratings ->
	    io:format("~w deleting ratings\n",[self()]),
	    movie_data:delete_all_ratings(),
	    worker();
	{ratings, Mid, Ratings} ->
	    io:format("~w writing ~w ratings for movie ~w\n",[self(),length(Ratings),Mid]),
	    movie_data:write_movie_ratings(Mid,Ratings),
	    worker();
	{calc_all_for, Mid, Ids, Pid} ->	
	    io:format("~w calc_all_for ~w\n",[self(),Mid]),
	    Coeffs = [ calc_for(Mid,OtherId) || OtherId <- Ids ],	    
	    Pid ! Coeffs,
	    worker()

    after 60000 ->
	    io:format("~w waiting...\n",[self()]),
	    worker()
    
    end.

calc_for(M1,M2) -> 
    Ratings1 = movie_data:ratings(M1),
    Ratings2 = movie_data:ratings(M2),
    {Sums, NumCommon} = coeff:summations(Ratings1,Ratings2),
    coeff:coeff(Sums,NumCommon).
    

	    


	    

