-module(coeff).
-export([pearson/2]).
%-compile(export_all).

pearson(A,B) ->
    {Sums, NumCommon} = summations(A,B),
    coeff(Sums,NumCommon).

summations(A,B) ->
    summations(A,B,{0,0,0,0,0},0).
    
summations([],_B, Sums, NumCommon) ->
    { Sums, NumCommon };

summations(_A,[], Sums, NumCommon) ->
    { Sums, NumCommon };

summations([{IdxA,RatingA}|TA]=A, [{IdxB,RatingB}|TB]=B, Sums, NumCommon) ->
    if
	IdxA == IdxB ->
	    NewSums = sums(RatingA,RatingB,Sums),
	    summations(TA,TB,NewSums,NumCommon+1);
	IdxA < IdxB ->
	    summations(TA,B,Sums,NumCommon);
	true ->
	    summations(A,TB,Sums,NumCommon)
    end.
	    
sums(A,B,{SumA,SumB,SumASq,SumBSq,ProductSum}) ->
    {SumA + A,
     SumB + B,
     SumASq + (A*A),
     SumBSq + (B*B),
     ProductSum + (A*B)}.
    
coeff(_Sums, 0) ->
    0.0;

coeff({SumA,SumB,SumASq,SumBSq,ProductSum}, NumCommon) ->
    PA = SumASq - (SumA * SumA / NumCommon),
    PB = SumBSq - (SumB * SumB / NumCommon),    
    Denominator = math:sqrt(PA * PB),
    if
	Denominator == 0 ->
	    0.0;
	true ->
	    Numerator = ProductSum - ( SumA * SumB / NumCommon),
	    Numerator / Denominator
    end.

	



    
