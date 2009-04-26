-module(coeff).
-export([pearson/2,summations/2,coeff/1,coeff/2,aggregate_coeffs/1]).
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

coeff(Coeffs) ->    
    {Sums,NumCommon} = aggregate_coeffs(Coeffs),
    coeff(Sums,NumCommon).

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

aggregate_coeffs(Coeffs) ->	
    aggregate_coeffs(Coeffs,{{0,0,0,0,0},0}).
aggregate_coeffs([], Acc) ->
    Acc;
% cleaner way to do this?
aggregate_coeffs([{{SA1,SB1,SAS1,SBS1,PS1},NC1}|Coeffs],{{SA2,SB2,SAS2,SBS2,PS2},NC2}) -> 
    aggregate_coeffs(Coeffs,{{SA1+SA2,SB1+SB2,SAS1+SAS2,SBS1+SBS2,PS1+PS2},NC1+NC2}).
    




    
