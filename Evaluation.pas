{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\Evaluation.paV 
{
{   Rev 1.0    28/09/03 20:28:20  Dgrava
{ Initial Revision
}
{
   Rev 1.3    15-6-2003 20:38:28  DGrava
 Disabled foward pruning. Added Quiescens check.
}
{
   Rev 1.2    10-3-2003 21:46:24  DGrava
 Little enhancements.
}
{
   Rev 1.1    6-2-2003 11:48:01  DGrava
 Introduction of QuickEval component.
}
{
   Rev 1.0    24-1-2003 21:12:23  DGrava
 Eerste Check in.
 Versie 0.27
}
{}
unit Evaluation;

interface

uses
  ReveTypes;

var
  GLOBAL_NumEvaluations : Integer;

const
  OREO_BONUS            = 100;
  TRIANGLE_BONUS        = 60;
  BACKRANK_VALUE        = 50;
  BRIDGE_BONUS          = 50;
  GOALKEEPER_BONUS      = 10;
  DEV_SINGLE_CORNER     = 60;
  DOGHOLE               = 5;
  CENTER_CONTROL_MEN    = 20;
  CENTER_CONTROL_KINGS  = 50;
  SINGLE_CORNER_CRAMP   = 150;
  DANGLING_PIECE_BONUS  = 200;
  DOUBLE_CORNER_CRAMP   = 90;
  ENDGAME_TEMPO_MULTIPLIER  = 10;
  THREAT_PENALTY        = KING_VALUE;

  CENTER_SQUARES  : array [0..5] of Integer = (
    14, 15, 16, 19, 22, 23
  );

// TEMPOOPENING/ENDGIME KING TRAPPED, SINGLE ROAMING KING

function Evaluate(var aBoard : TBoardStruct): Integer;

implementation

{ TODO :
Perhaps it is faster to create bit boards (sets) for every type of piece (4)
and for every color (2).
In that way you can simply evaluate if blackPiece in [1,2,3] then result etc. }
function Evaluate(var aBoard : TBoardStruct): Integer;
var
  i : Integer;
begin
  Inc(GLOBAL_NumEvaluations);
  with aBoard do begin
    if WhiteMen + WhiteKings = 0 then begin
      result := WIN;
      if ColorToMove = RP_WHITE then begin
        result := - result;
      end;
      Exit;
    end
    else if BlackMen + BlackKings = 0 then begin
      result := LOSS;
      if ColorToMove = RP_WHITE then begin
        result := - result;
      end;
      Exit;
    end;

    result := QuickEval;

    { Evaluate backrank}
    for i := 1 to 3 do begin
      if (Board[i] =  RP_BLACKMAN) then begin
        Inc(result, BACKRANK_VALUE);
      end;
    end;

    if (Board[1] =  RP_BLACKMAN) and (Board[3] = RP_BLACKMAN) then begin
      Inc(result, BRIDGE_BONUS);
    end;

    if  (Board[2] = RP_BLACKMAN) then begin
      Inc(result, GOALKEEPER_BONUS);
    end;

    for i := 30 to 32 do begin
      if (Board[i] =  RP_WHITEMAN) then begin
        Dec(result, BACKRANK_VALUE);
      end;
    end;

    if (Board[30] =  RP_WHITEMAN) and (Board[32] = RP_WHITEMAN) then begin
      Dec(result, BRIDGE_BONUS);
    end;

    if  (Board[31] = RP_WHITEMAN) then begin
      Dec(result, GOALKEEPER_BONUS);
    end;

    { Check developed single corner }
    if Board[4] = RP_FREE then begin
      Inc(result, DEV_SINGLE_CORNER);
    end;

    if Board[29] = RP_FREE then begin
      Dec(result, DEV_SINGLE_CORNER);
    end;

    { Check dogholes }
    if (Board[5] = RP_BLACKMAN) and (Board[1] and not RP_WHITE <> 0) then begin
      Dec(result, DOGHOLE);
    end;

    if (Board[28] = RP_WHITEMAN) and (Board[32] and not RP_BLACK <> 0) then begin
      Inc(result, DOGHOLE);
    end;

    if (Board[12] = RP_BLACKMAN) and (Board[3] and not RP_WHITE <> 0) then begin
      Dec(result, DOGHOLE);
    end;

    if (Board[30] = RP_WHITEMAN) and (Board[21] and not RP_BLACK <> 0) then begin
      Inc(result, DOGHOLE);
    end;

    { Evaluate Oreo's triangle}

    // Note skip square 2/31
    if (*(Board[2] =  RP_BLACKMAN) and *)(Board[3] = RP_BLACKMAN) and (Board[7] = RP_BLACKMAN) then begin
      Inc(result, OREO_BONUS);
    end;

    if (Board[30] =  RP_WHITEMAN) and (*(Board[31] = RP_WHITEMAN) and *)(Board[26] = RP_WHITEMAN) then begin
      Dec(result, OREO_BONUS);
    end;

    { Evaluate other triangle}
    if (Board[1] =  RP_BLACKMAN) and (*(Board[2] = RP_BLACKMAN) and *)(Board[6] = RP_BLACKMAN) then begin
      Inc(result, TRIANGLE_BONUS);
    end;

    if (*(Board[31] =  RP_WHITEMAN) and *)(Board[32] = RP_WHITEMAN) and (Board[27] = RP_WHITEMAN) then begin
      Dec(result, TRIANGLE_BONUS);
    end;

    { Evaluate center control with men}
    if (Board[14] =  RP_BLACKMAN) then begin
      Inc(result, CENTER_CONTROL_MEN);
    end;

    if (Board[15] =  RP_BLACKMAN) then begin
      Inc(result, CENTER_CONTROL_MEN);
    end;

    if (Board[18] =  RP_WHITEMAN) then begin
      Dec(result, CENTER_CONTROL_MEN);
    end;

    if (Board[19] =  RP_WHITEMAN) then begin
      Dec(result, CENTER_CONTROL_MEN);
    end;

    { Evaluate center control with kings}
    for i := Low(CENTER_SQUARES) to High (CENTER_SQUARES) do begin
      if Board[CENTER_SQUARES[i]] =  RP_BLACKKING then begin
        Inc(result, CENTER_CONTROL_KINGS);
      end
      else if Board[CENTER_SQUARES[i]] =  RP_WHITEKING then begin
        Dec(result, CENTER_CONTROL_KINGS);
      end;
    end;

    { Check single corner cramp }
    if (
      (Board[13] = RP_BLACKMAN) and
      (Board[17] = RP_WHITEMAN) and
      (Board[22] = RP_WHITEMAN)
    )then begin
      Inc(result, SINGLE_CORNER_CRAMP);
      if (
        (Board[21] = RP_WHITEMAN) and
        (Board[25] = RP_WHITEMAN) and
        (Board[29] = RP_FREE)
      )then begin
        Inc(result, DANGLING_PIECE_BONUS);
      end;
    end;

    if (
      (Board[20] = RP_WHITEMAN) and
      (Board[16] = RP_BLACKMAN) and
      (Board[11] = RP_BLACKMAN)
    )then begin
      Dec(result, SINGLE_CORNER_CRAMP);
      if (
        (Board[12] = RP_BLACKMAN) and
        (Board[8] = RP_BLACKMAN) and
        (Board[4] = RP_FREE)
      )then begin
        Dec(result, DANGLING_PIECE_BONUS);
      end;
    end;

    { Double corner cramp}
    if (
      (Board[20] = RP_BLACKMAN) and
      (Board[24] = RP_WHITEMAN) and
      (Board[27] = RP_WHITEMAN)
    )then begin
      Inc(result, DOUBLE_CORNER_CRAMP);
    end;

    if (
      (Board[13] = RP_BLACKMAN) and
      (Board[9] = RP_WHITEMAN) and
      (Board[6] = RP_WHITEMAN)
    )then begin
      Dec(result, DOUBLE_CORNER_CRAMP);
    end;

    {Give bonus for development near the end of the game}
    if BlackMen + WhiteMen + BlackKings + WhiteKings <= 16 then begin
      Dec(result, Tempo * ENDGAME_TEMPO_MULTIPLIER);
    end;
  end; // with

  { Set correct result if White is to move}
  if aBoard.ColorToMove = RP_WHITE then begin
    result := -result;
  end;
end; // Evaluate

{
  $Log
  06-12-2002, DG : Created with default random implemenation.
  14-12-2002, DG : Real implementation.
}
end.
