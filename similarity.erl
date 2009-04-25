-module(similarity).
-export([start/0, stop/0, write_movie_ratings/1, calc_for/2, calc_all_for/2, worker/0]).

% api

start() ->
    register(worker, spawn(?MODULE, worker, [])),
    worker ! start.

stop() ->
    worker ! stop.

write_movie_ratings(Ids) ->
    worker ! delete_all_ratings,
    lists:foreach(
      fun(Mid) ->
	      Ratings = movie_data:ratings_for(Mid),
	      worker ! { ratings, Mid, Ratings }
      end,
      Ids).
	     
calc_all_for(Mid, Ids) ->	        
    worker ! { calc_all_for, Mid, Ids, self() },
    receive Coeffs -> Coeffs after 60000 -> timeout end.

% worker

worker() ->
    receive
	start ->
	    io:format("~w start\n",[self()]),
	    movie_data:start(),
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

    after 10000 ->
	    io:format("~w timeout\n",[self()])
    end.

calc_for(M1,M2) -> 
    Ratings1 = movie_data:ratings(M1),
    Ratings2 = movie_data:ratings(M2),
    {Sums, NumCommon} = coeff:summations(Ratings1,Ratings2),
    coeff:coeff(Sums,NumCommon).
    

	    


	    

