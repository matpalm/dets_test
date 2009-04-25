-module(movie_data).
%-export([read_movie_ids/0,start/0,stop/0,ratings/1,write_movie_ratings/1]).
-compile(export_all).
-include_lib("consts.hrl").

read_movie_ids() ->
    File = ?PATH ++ "/movie_titles.txt",
    io:format("~p\n",[File]),
    {ok,B} = file:read_file(File),
    Lines = string:tokens(binary_to_list(B), "\n"),
    ParseLine = fun(Line) ->
			Tokens = string:tokens(Line,","),
			Id = hd(Tokens),
			list_to_integer(Id)
		end,
    [ ParseLine(Line) || Line <- Lines ].

start(N) ->
    TableName = list_to_atom("movie_ratings_" ++ integer_to_list(N)),
    put(ratingsTable, TableName),
    FileName = atom_to_list(TableName) ++ ".dets",
    io:format("~w opening dets table ~w from file ~w\n",[self(),TableName,FileName]),
    dets:open_file(TableName,[{file,FileName}]),
    ok.

stop() ->
    dets:close(get(ratingsTable)),
    ok.

ratings(Id) -> 
    util:extract_value(dets:lookup(get(ratingsTable), Id)).

delete_all_ratings() ->
    dets:delete_all_objects(get(ratingsTable)).
 
write_movie_ratings(MovieId,Ratings) ->   
    dets:insert(get(ratingsTable), {MovieId, Ratings}).
    
%write_movie_ratings(Ids) ->
%    lists:foreach(fun(Id) -> write_movie_rating(Id) end, Ids).
			   
%write_movie_rating(MovieId) -> 
%    Ratings = ratings_for(MovieId),

% Ratings = [ {Uid,Rating}, {Uid,Rating}, ... ]
ratings_for(MovieId) ->  
    Filename = ?PATH ++ "/training_set/mv_" ++ padded(MovieId,7) ++ ".txt",
    %io:format("file is ~p~n",[Filename]),
    {ok,B} = file:read_file(Filename),    
    Lines = string:tokens(binary_to_list(B), "\n"),
    ConvertALine = fun([UserId,Rating,_Date]) -> { list_to_integer(UserId), list_to_integer(Rating) } end,
    Ratings = [ ConvertALine(split_on_comma(X)) || X <- Lines ],
    Ratings.

split_on_comma(Line) ->    
    string:tokens(Line,",").
  
padded(Text,N) when is_integer(Text) ->
    padded(integer_to_list(Text),N);
padded(Text,N) when length(Text) >= N ->
    Text;
padded(Text,N) ->
    padded("0"++Text,N).
        
