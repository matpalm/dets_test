-module(similarity).
-export([start/0, stop/0, write_movie_ratings/1, calc_for/2, calc_all_for/2]).

start() ->
    ok.

stop() ->
    ok.

write_movie_ratings(Ids) ->
    movie_data:write_movie_ratings(Ids).

calc_for(M1,M2) ->
    Ratings1 = movie_data:ratings(M1),
    Ratings2 = movie_data:ratings(M2),
    {Sums, NumCommon} = coeff:summations(Ratings1,Ratings2),
    coeff:coeff(Sums,NumCommon).
    
calc_all_for(Mid, Ids) ->	        
    [ calc_for(Mid,OtherId) || OtherId <- Ids ].


	    


	    

