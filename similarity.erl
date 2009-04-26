-module(similarity).
-export([start/0, stop/0, 
         write_movie_ratings/1, write_single_movie_rating/2, 
         similarity/2, calc_all_for/2, 
         worker_init/1,hook/4]).
-include_lib("consts.hrl").

% api

start() ->
    Nodes = net_adm:world(),
    io:format("Nodes ~w\n",[Nodes]),
    %rpc:multicall(init,restart,[]), % ensure code up to date on all machines
    io:format("~w ~w\n",[length(Nodes),?NUM_WORKERS]),
    case length(Nodes) == ?NUM_WORKERS of
	true  -> spawn_workers_over(Nodes);
	false -> io:format("error; #workers(~w) != #nodes(~w)\n",[?NUM_WORKERS,length(Nodes)]),
		 init:stop()
    end.
	    
spawn_workers_over(Nodes) ->
    WorkerPids = [ spawn(Node,?MODULE, worker_init, [Num]) || {Node,Num} <- lists:zip(Nodes,lists:seq(1,?NUM_WORKERS)) ],
    put(workers, WorkerPids).

stop() ->
    broadcast(stop).

write_movie_ratings(Ids) ->
    broadcast(delete_all_ratings),
    rpc:pmap({?MODULE,write_single_movie_rating}, [get(workers)], Ids).
    %lists:foreach(fun(Mid) -> write_single_movie_rating(Mid, get(workers)) end, Ids). % serial testing
    
write_single_movie_rating(Mid, Workers) ->
    Ratings = movie_data:ratings_for(Mid),
    RatingsShards = shard:partition_into_shards(Ratings, ?NUM_WORKERS),
    lists:foreach(
      fun({WorkerPid,RatingsSubList}) -> 
	      WorkerPid ! { ratings, Mid, RatingsSubList }
      end,
      lists:zip(Workers, RatingsShards)
      ),
    ok.		

similarity(M1,M2) ->
    broadcast({similarity_coeffs, M1, M2, self()}),
    Coeffs = [ receive Coeffs -> Coeffs end || _ <- get(workers)],
    coeff:coeff(Coeffs).
	       
calc_all_for(Mid, Ids) ->
    Coeffs = [ similarity(Mid,Other) || Other <- Ids ],
    io:format("~w\n",[Coeffs]),
    Coeffs.

broadcast(Msg) ->
    [ W ! Msg || W <- get(workers) ].

% worker

worker_init(N) ->
    self() ! {start, N},
    worker().

worker() ->
    %io:format("~w >worker loop #~w msgs pending\n",[self(),process_info(self(),message_queue_len)]),
    receive
	{start,N} ->
	    io:format("~w start #~w\n",[self(),N]),
	    movie_data:start(N),
	    worker();
	stop ->
	    io:format("~w stop\n",[self()]),
	    movie_data:stop(),	    
	    ok;
	delete_all_ratings ->
	    io:format("~w deleting ratings\n",[self()]),
	    movie_data:delete_all_ratings(),
	    worker();
	{ratings, Mid, Ratings} ->
	    io:format("~w writing ~w ratings for movie ~w\n",[self(),length(Ratings),Mid]),
	    movie_data:write_movie_ratings(Mid,Ratings),
	    worker();
	{similarity_coeffs, M1, M2, Pid} ->
%	    io:format("~w calcing coeffs for ~w ~w\n",[self(),M1,M2]),
	    Ratings1 = movie_data:ratings(M1),
	    Ratings2 = movie_data:ratings(M2),
	    SumsNumCommonTuple = coeff:summations(Ratings1,Ratings2),
	    Pid ! SumsNumCommonTuple,
	    worker()	    
	    
    after 60000 ->
	    io:format("~w waiting...\n",[self()]),
	    worker()
    
    end.

    
hook(M,F,A,Workers) -> % hook for when testing (with spawn) something that requires workers list in process dict
    put(workers,Workers),
    apply(M,F,A).

	    


	    

