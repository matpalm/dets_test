-module(similarity).
-export([calc_for/2, calc_all_for/2]).

calc_for(M1,M2) ->
    Ratings1 = movie_data:ratings(M1),
    Ratings2 = movie_data:ratings(M2),
    coeff:pearson(Ratings1, Ratings2).
    
calc_all_for(Mid, Ids) ->	        
    [ calc_for(Mid,OtherId) || OtherId <- Ids ].


	    


	    

