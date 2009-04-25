-module(util).
-export([extract_value/1,split/2,next_line/1,time/2]).
%-compile(export_all).

extract_value(Record) ->
    case length(Record) of
	0 -> 
	    record_not_found;
	_ ->
	    [{_Key,Value}] = Record,
	    Value
    end.


% split List into N chunks
% retains order; ie if i<j in original then i<j if in same chunk
split(List,N) -> 
    Chunks = [ [] || _X <- lists:seq(1,N)],
    [ lists:reverse(SubList) || SubList <- split(List,Chunks,[])].
split([],Chunks,Acc) ->
    Chunks ++ Acc;
split(List,[],Acc) ->
    split(List,Acc,[]);
split([H|T],[CH|CT],Acc) ->
    split(T,CT,[[H|CH]|Acc]).


next_line(Binary) ->
    next_line(Binary, []).
next_line(<<>>, _Collected) ->
    ignore_last_line_if_didnt_end_in_newline;
next_line(<<"\n",Rest/binary>>, Collected) ->  
    { Rest, binary_to_list(list_to_binary(lists:reverse(Collected))) }; % black magic voodoo line
next_line(<<C:1/binary,Rest/binary>>, Collected) ->
    next_line(Rest, [C|Collected]). 


time(Msg, Fun) ->
    Start = now(),
    Fun(),
    io:format("~p ~p s\n",[Msg, timer:now_diff(now(),Start)/1000/1000]).

