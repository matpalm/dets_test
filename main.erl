-module(main).
-compile(export_all).

write_ratings() ->
    similarity:start(),
    Ids = movie_data:read_movie_ids(),
    io:format("#movies = ~w\n",[length(Ids)]),
    util:time("write ratings", fun() -> similarity:write_movie_ratings(Ids) end),    
    similarity:stop(),
    init:stop().

calc(Args) ->
    similarity:start(),
    Ids = movie_data:read_movie_ids(), 
    CalcFun = fun() -> 
		      lists:foreach(
			fun(Id) -> similarity:calc_all_for(Id,Ids) end,
			parse_args(Args))
		      end,
    util:time("calc similarity", CalcFun),
    similarity:stop(),
    init:stop().

checksum(Args) ->
    similarity:start(),
    Ids = movie_data:read_movie_ids(),
    lists:foreach(
      fun(Id) ->
	      io:format("check ~w ~w\n",[Id, lists:sum(similarity:calc_all_for(Id,Ids))])
      end,
      parse_args(Args)),
    similarity:stop(),
    init:stop().

parse_args(Args) ->
    [A,B] = [ list_to_integer(atom_to_list(Arg)) || Arg <- Args ],
    lists:seq(A,B).
    
    
