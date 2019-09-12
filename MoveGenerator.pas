{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\MoveGenerator.paV 
{
{   Rev 1.0    28/09/03 20:28:21  Dgrava
{ Initial Revision
}
{
   Rev 1.4    15-6-2003 20:38:28  DGrava
 Disabled forward pruning. Added Quiescens check.
}
{
   Rev 1.3    10-3-2003 21:46:24  DGrava
 Little enhancements.
}
{
   Rev 1.2    20-2-2003 16:38:47  DGrava
 Forward pruning implemented. Extending capture sequences
 with conditional defines
}
{
   Rev 1.1    6-2-2003 11:48:02  DGrava
 Introduction of QuickEval component.
}
{
   Rev 1.0    24-1-2003 21:12:23  DGrava
 Eerste Check in.
 Versie 0.27
}
{}
unit MoveGenerator;
{NOTE
  Perhaps the movegenerator could be improved by taking up Board[EDGE]. 
}
interface

uses
  ReveTypes;

type
  TMove = record
    FromSquare : Integer;
    ToSquare   : Integer;
  end;

  TExtraMoveInfo  = record
    Promotion : boolean;
    JumpIndex : Integer;
    JumpSize  : Integer;
  end;

  TKilledPiece  = record
    Square  : Integer;
    Piece   : Integer;
  end;

  TMoveList  = record
    AtMove        : Integer;
    AtJump        : Integer;
    Moves         : array [1..512] of TMove;
    MoveInfo      : array [1..512] of TExtraMoveInfo;
    KilledPieces  : array [1..256] of TKilledPiece;
  end;

  TJumpList = record
    AtIndex       : Integer;
    FromSquare    : Integer;
    KilledPieces  : array [1..12] of TKilledPiece;
  end;

procedure GenerateMoves(
  var aMoveList : TMoveList;
  var aBoard    : TBoard;
      aColor    : Integer
);

procedure ExecuteMove(
  var aMoveList : TMoveList;
  var aBoard    : TBoardStruct;
      aIndex    : Integer
);

procedure UndoMove(
  var aMoveList : TMoveList;
  var aBoard    : TBoardStruct;
      aIndex    : Integer
);

function FindMove(
  var aMoveList   : TMoveList;
      aStart      : Integer;
      aEnd        : Integer;
      aFromSquare : Integer;
      aToSquare   : Integer
): Integer;

procedure SwapMoves(
  var aMoveList : TMoveList;
      aIndex1   : Integer;
      aIndex2   : Integer
);

function IsThreatPresent(
  var aBoard : TBoard;
      aColor : Integer
): Boolean;

procedure InitializeBoard(var aBoard : TBoardStruct; aColorToMove: Integer);

implementation

uses
  SysUtils, HashTable; {for IntToStr in assert message}

const
  EDGE  = 0;
  BOARD_STRUCT  : array[1..32, 1..4] of Integer  = (
    (6,5,0,0),
    (7,6,0,0),
    (8,7,0,0),
    (0,8,0,0),
    (9,0,1,0),
    (10,9,2,1),
    (11,10,3,2),
    (12,11,4,3),
    (14,13,6,5),
    (15,14,7,6),
    (16,15,8,7),
    (0,16,0,8),
    (17,0,9,0),
    (18,17,10,9),
    (19,18,11,10),
    (20,19,12,11),
    (22,21,14,13),
    (23,22,15,14),
    (24,23,16,15),
    (0,24,0,16),
    (25,0,17,0),
    (26,25,18,17),
    (27,26,19,18),
    (28,27,20,19),
    (30,29,22,21),
    (31,30,23,22),
    (32,31,24,23),
    (0,32,0,24),
    (0,0,25,0),
    (0,0,26,25),
    (0,0,27,26),
    (0,0,28,27)
  );

function IsThreatPresent(
  var aBoard : TBoard;
      aColor : Integer
): Boolean;
var
  square          : Integer;
  startDirection  : Integer;
  direction       : Integer;
  nextSquare      : Integer;
  afterSquare     : Integer;
begin
  result := False;
  {Pseudocode
    Iterate over board
    Is there a piece of our color.
    Can it jump
  }
  if aColor = RP_BLACK then begin
    startDirection := 1;
  end
  else begin
    startDirection := 3;
  end;

  for square := 1 to 32 do begin
    if aBoard[square] = (RP_MAN or aColor) then begin
      for direction := startDirection to startDirection + 1 do begin
        nextSquare := BOARD_STRUCT[square, direction];
        if (
          (nextSquare <> EDGE) and
          (aBoard[nextSquare] <> RP_FREE) and
          (aBoard[nextSquare] and aColor = 0)
        ) then begin
          afterSquare := BOARD_STRUCT[nextSquare, direction];
          if (afterSquare <> EDGE) and (aBoard[afterSquare] = RP_FREE) then begin
            result := True;
            Exit;
          end;
        end;
      end;
    end
    else if aBoard[square] = (RP_KING or aColor) then begin
      for direction := 1 to 4 do begin
        nextSquare := BOARD_STRUCT[square, direction];
        if (
          (nextSquare <> EDGE) and
          (aBoard[nextSquare] <> RP_FREE) and
          (aBoard[nextSquare] and aColor = 0)
        ) then begin
          afterSquare := BOARD_STRUCT[nextSquare, direction];
          if (afterSquare <> EDGE) and (aBoard[afterSquare] = RP_FREE) then begin
            result := True;
            Exit;
          end;
        end;
      end;
    end;
  end; // for
end; // IsThreatPresent

function GenerateManJump(
  var aMoveList     : TMoveList;
  var aBoard        : TBoard;
  var aJumpList     : TJumpList;
      aSquare       : Integer;
      aColor        : Integer
) : boolean;
var
  direction       : Integer;
  startDirection  : Integer;
  nextSquare      : Integer;
  afterSquare     : Integer;
  i               : Integer;
begin
  result := True;

  {Determine startDirection (based on color to move)}
  if aBoard[aSquare] = (RP_WHITE or RP_MAN) then begin
    startDirection := 3;
  end
  else begin
    startDirection := 1;
  end;

  for direction := startDirection to startDirection + 1 do begin
    nextSquare := BOARD_STRUCT[aSquare, direction];
    {NOTE
      Check if next square is on the board,
      if there is a piece on it,
      if this piece is of a different color
      and is not already killed.
    }
    if (
      (nextSquare <> EDGE) and
      (aBoard[nextSquare] <> RP_FREE) and
      (aBoard[nextSquare] and aColor = 0) and
      (aBoard[nextSquare] and RP_KILLED = 0)
    ) then begin
      afterSquare := BOARD_STRUCT[nextSquare, direction];
      if (afterSquare <> EDGE) and (aBoard[afterSquare] = RP_FREE) then begin
        { store the information on the jumped piece and its square
         to the buffer.}
        with aJumpList do begin
          KilledPieces[AtIndex].Square  := nextSquare;
          KilledPieces[AtIndex].Piece   := aBoard[nextSquare];
          Inc(AtIndex);
        end;

        {OK we can jump, now adjust board and search level deeper.}
        aBoard[afterSquare] := aBoard [aSquare];
        aBoard[aSquare]     := RP_FREE;
        aBoard[nextSquare]  := aBoard[nextSquare] or RP_KILLED;
        if GenerateManJump(aMoveList, aBoard, aJumpList, afterSquare, aColor) then begin
          // We have found a capture sequence!
          // Copy move from buffer to movelist
          with aJumpList do begin
            aMoveList.Moves[aMoveList.AtMove].FromSquare  := FromSquare;
            aMoveList.Moves[aMoveList.AtMove].ToSquare    := afterSquare;

            if aBoard[afterSquare] = (RP_MAN or RP_BLACK) then begin
              aMoveList.MoveInfo[aMoveList.AtMove].Promotion := afterSquare in [29..32];
            end
            else if aBoard[afterSquare] = (RP_MAN or RP_WHITE) then begin
              aMoveList.MoveInfo[aMoveList.AtMove].Promotion := afterSquare in [1..4];
            end;

            aMoveList.MoveInfo[aMoveList.AtMove].JumpIndex := aMoveList.AtJump;
            aMoveList.MoveInfo[aMoveList.AtMove].JumpSize  := AtIndex - 1;

            for i := Low(KilledPieces) to AtIndex - 1 do begin
              aMoveList.KilledPieces[aMoveList.AtJump].Square := KilledPieces[i].Square;
              aMoveList.KilledPieces[aMoveList.AtJump].Piece  := KilledPieces[i].Piece;
              Inc(aMoveList.AtJump);
            end; // while
            // Point to the next free location
            Inc(aMoveList.AtMove);
          end; // with
        end; // if
        {NOTE
          This is probably the most difficult part of this routine to understand.
          It has to do with telling the caller not to store the move found so far;
          it has already been stored as a move.
        }
        result := False;
        // Restore board now
        aBoard[aSquare]     := aBoard[afterSquare];
        aBoard[afterSquare] := RP_FREE;
        aBoard[nextSquare]  := aBoard[nextSquare] and not RP_KILLED;
        // Remove the information from the buffer.
        Dec(aJumpList.AtIndex);
      end; // if
    end; // if
  end; // for
end; // GenerateManJump

function GenerateKingJump(
  var aMoveList     : TMoveList;
  var aBoard        : TBoard;
  var aJumpList     : TJumpList;
      aSquare       : Integer;
      aColor        : Integer
) : boolean;
var
  direction   : Integer;
  nextSquare  : Integer;
  afterSquare : Integer;
  i           : Integer;
begin
  result := True;
  for direction := 1 to 4 do begin
    nextSquare := BOARD_STRUCT[aSquare, direction];
    {NOTE
      Check if next square is on the board,
      if there is a piece on it,
      if this piece is of a different color
      and is not already killed.
    }
    if (
      (nextSquare <> EDGE) and
      (aBoard[nextSquare] <> RP_FREE) and
      (aBoard[nextSquare] and aColor = 0) and
      (aBoard[nextSquare] and RP_KILLED = 0)
    ) then begin
      afterSquare := BOARD_STRUCT[nextSquare, direction];
      if (afterSquare <> EDGE) and (aBoard[afterSquare] = RP_FREE) then begin
        // store the information on the jumped piece and its square
        // to the buffer.

        with aJumpList do begin
          KilledPieces[AtIndex].Square  := nextSquare;
          KilledPieces[AtIndex].Piece   := aBoard[nextSquare];
          Inc(AtIndex);
        end;

        // OK we can jump, now adjust board and search level deeper
        aBoard[afterSquare] := aBoard [aSquare];
        aBoard[aSquare]     := RP_FREE;
        aBoard[nextSquare]  := aBoard[nextSquare] or RP_KILLED;
        if GenerateKingJump(aMoveList, aBoard, aJumpList, afterSquare, aColor) then begin
          // We have found a capture sequence!
          // Copy move from buffer to movelist
          with aJumpList do begin
            aMoveList.Moves[aMoveList.AtMove].FromSquare  := aJumpList.FromSquare;
            aMoveList.Moves[aMoveList.AtMove].ToSquare    := afterSquare;

            aMoveList.MoveInfo[aMoveList.AtMove].Promotion := False;
            aMoveList.MoveInfo[aMoveList.AtMove].JumpIndex := aMoveList.AtJump;
            aMoveList.MoveInfo[aMoveList.AtMove].JumpSize  := AtIndex - 1;

            for i := Low(KilledPieces) to AtIndex - 1 do begin
              aMoveList.KilledPieces[aMoveList.AtJump].Square := KilledPieces[i].Square;
              aMoveList.KilledPieces[aMoveList.AtJump].Piece  := KilledPieces[i].Piece;
              Inc(aMoveList.AtJump);
              // Inc(aMoveList.ExtraInfo[AtMove].JumpSize);
            end; // while
            // Point to the next free location
            Inc(aMoveList.AtMove);
          end; // with
        end; // if
        {NOTE
          This is probably the most difficult part of this routine to understand.
          It has to do with telling the caller not to store the move found so far;
          it has already been stored as a move.
        }
        result := False;
        // Restore board now
        aBoard[aSquare]     := aBoard[afterSquare];
        aBoard[afterSquare] := RP_FREE;
        aBoard[nextSquare]  := aBoard[nextSquare] and not RP_KILLED;
        // Remove the information from the buffer.
        Dec(aJumpList.AtIndex);
      end; // if
    end; // if
  end; // for
end; // GenerateKingJump

procedure GenerateKingMove(
  var aMoveList     : TMoveList;
  var aBoard        : TBoard;
      aSquare       : Integer
);
var
  direction   : Integer;
  nextSquare  : Integer;
begin
  for direction := 1 to 4 do begin
    nextSquare := BOARD_STRUCT[aSquare, direction];
    if nextSquare <> EDGE then begin
      if aBoard[nextSquare] = RP_FREE then begin
        aMoveList.Moves[aMoveList.AtMove].FromSquare  := aSquare;
        aMoveList.Moves[aMoveList.AtMove].ToSquare    := nextSquare;

        aMoveList.MoveInfo[aMoveList.AtMove].Promotion  := False;
        aMoveList.MoveInfo[aMoveList.AtMove].JumpIndex  := 0;
        aMoveList.MoveInfo[aMoveList.AtMove].JumpSize   := 0;
        // increment list pointer
        Inc(aMoveList.AtMove);
      end;
    end;
  end; // for
end; // GenerateKingMove

procedure GenerateManMove(
  var aMoveList     : TMoveList;
  var aBoard        : TBoard;
      aSquare       : Integer
);
var
  direction       : Integer;
  startDirection  : Integer;
  nextSquare      : Integer;
begin
  {Determine startDirection (based on color to move)}
  if aBoard[aSquare] = (RP_WHITE or RP_MAN) then begin
    startDirection := 3;
  end
  else begin
    startDirection := 1;
  end;

  for direction := startDirection to startDirection + 1 do begin
    nextSquare := BOARD_STRUCT[aSquare, direction];
    if nextSquare <> EDGE then begin
      if aBoard[nextSquare] = RP_FREE then begin
        aMoveList.Moves[aMoveList.AtMove].FromSquare  := aSquare;
        aMoveList.Moves[aMoveList.AtMove].ToSquare    := nextSquare;

        if aBoard[aSquare] = (RP_MAN or RP_BLACK) then begin
          aMoveList.MoveInfo[aMoveList.AtMove].Promotion  := nextSquare in [29..32];
        end
        else if aBoard[aSquare] = (RP_MAN or RP_WHITE) then begin
          aMoveList.MoveInfo[aMoveList.AtMove].Promotion  := nextSquare in [1..4];
        end;
        aMoveList.MoveInfo[aMoveList.AtMove].JumpIndex  := 0;
        aMoveList.MoveInfo[aMoveList.AtMove].JumpSize   := 0;
        // increment list pointer
        Inc(aMoveList.AtMove);
      end;
    end;
  end; // for
end; // GenerateManMove


procedure GenerateMoves(
  var aMoveList : TMoveList;
  var aBoard    : TBoard;
      aColor    : Integer
);
var
  square    : Integer;
  jumpList  : TJumpList;
  saveIndex : Integer;
begin
  saveIndex := aMoveList.AtMove;
  //for square := 32 downto 1 do begin
  for square := 1 to 32 do begin
    if aBoard[square] = (RP_MAN or aColor) then begin
      jumpList.FromSquare := square;
      jumpList.AtIndex    := 1;
      GenerateManJump(aMoveList, aBoard, jumpList, square, aColor);
    end
    else if aBoard[square] = (RP_KING or aColor) then begin
      jumpList.FromSquare := square;
      jumpList.AtIndex    := 1;
      GenerateKingJump(aMoveList, aBoard, jumpList, square, aColor);
    end;
  end; // for

  if aMoveList.AtMove = saveIndex then begin
    //for square := 32 downto 1 do begin
    for square := 1 to 32 do begin
      if aBoard[square] = (RP_MAN or aColor) then begin
        GenerateManMove(aMoveList, aBoard, square);
      end
      else if aBoard[square] = (RP_KING or aColor) then begin
        GenerateKingMove(aMoveList, aBoard, square);
      end;
    end; // for
  end;
end; // GenerateMoves

procedure ExecuteMove(
  var aMoveList : TMoveList;
  var aBoard    : TBoardStruct;
      aIndex    : Integer
);
var
  i : Integer;
  fromSq, toSq : Integer;
begin
  fromSq  := aMoveList.Moves[aIndex].FromSquare;
  toSq    := aMoveList.Moves[aIndex].ToSquare;

  with aBoard do begin
    {Move piece from original to new position.}
    Board[toSq] := Board[fromSq];

    AdjustHashKey(aBoard.HashKey, Board[fromSq], fromSq);
    AdjustHashKey(aBoard.HashKey, Board[fromSq], toSq);
    if toSq <> fromSq then begin
      if Board[fromSq] = RP_BLACKMAN then begin
        Dec(Tempo, BLACK_TEMPO[fromSq]);
        Inc(Tempo, BLACK_TEMPO[toSq]);
      end
      else if Board[fromSq] = RP_WHITEMAN then begin
        Inc(Tempo, WHITE_TEMPO[fromSq]);
        Dec(Tempo, WHITE_TEMPO[toSq]);
      end;
      Board[fromSq] := RP_FREE;
    end;
    {Crown piece if applicable}
    if aMoveList.MoveInfo[aIndex].Promotion then begin
      Board[toSq] := (Board[toSq] and not RP_MAN) or RP_KING;
      if Board[toSq] = RP_BLACKKING then begin
        Inc(QuickEval, KING_VALUE - MAN_VALUE);
        Dec(BlackMen);
        Inc(BlackKings);
        AdjustHashKey(aBoard.HashKey, RP_BLACKMAN, toSq);
        AdjustHashKey(aBoard.HashKey, RP_BLACKKING, toSq);
      end
      else begin
        Dec(QuickEval, KING_VALUE - MAN_VALUE);
        Dec(WhiteMen);
        Inc(WhiteKings);
        AdjustHashKey(aBoard.HashKey, RP_WHITEMAN, toSq);
        AdjustHashKey(aBoard.HashKey, RP_WHITEKING, toSq);
      end;
    end;

    {Take the jumped/killed pieces from the board}
    with aMoveList do begin
      if MoveInfo[aIndex].JumpIndex > 0 then begin
        for i := MoveInfo[aIndex].JumpIndex to MoveInfo[aIndex].JumpIndex + MoveInfo[aIndex].JumpSize - 1 do begin
          Board[KilledPieces[i].Square] := RP_FREE;
          case KilledPieces[i].Piece of
            RP_WHITEMAN  : begin
              Inc(QuickEval, MAN_VALUE);
              Dec(WhiteMen);
              Inc(Tempo, WHITE_TEMPO[KilledPieces[i].Square]);
              AdjustHashKey(aBoard.HashKey, RP_WHITEMAN, KilledPieces[i].Square);
            end;
            RP_BLACKMAN  : begin
              Dec(QuickEval, MAN_VALUE);
              Dec(BlackMen);
              Dec(Tempo, BLACK_TEMPO[KilledPieces[i].Square]);
              AdjustHashKey(aBoard.HashKey, RP_BLACKMAN, KilledPieces[i].Square);
            end;
            RP_WHITEKING : begin
              Inc(QuickEval, KING_VALUE);
              Dec(WhiteKings);
              AdjustHashKey(aBoard.HashKey, RP_WHITEKING, KilledPieces[i].Square);
            end;
            RP_BLACKKING : begin
              Dec(QuickEval, KING_VALUE);
              Dec(BlackKings);
              AdjustHashKey(aBoard.HashKey, RP_BLACKKING, KilledPieces[i].Square);
            end;
          end; // case
        end; // for
      end; // if
    end; // with aMovelist
    aBoard.ColorToMove := aBoard.ColorToMove xor RP_CHANGECOLOR;
  end; // with
end; // ExecuteMove

procedure UndoMove(
  var aMoveList : TMoveList;
  var aBoard    : TBoardStruct;
      aIndex    : Integer
);
var
  i : Integer;
  fromSq, toSq : Integer;
begin
  fromSq  := aMoveList.Moves[aIndex].FromSquare;
  toSq    := aMoveList.Moves[aIndex].ToSquare;

  with aBoard do begin
    {Put the piece back to its original position}
    Board[fromSq]   := Board[toSq];
    AdjustHashKey(aBoard.HashKey, Board[fromSq], fromSq);
    AdjustHashKey(aBoard.HashKey, Board[fromSq], toSq);
    if fromSq <> toSq then begin
      Board[toSq] := RP_FREE;
    end;
    {Undo promotions if applicable}
    if aMoveList.MoveInfo[aIndex].Promotion then begin
      Board[fromSq] := (Board[fromSq] and not RP_KING) or RP_MAN;
      if Board[fromSq] = RP_BLACKMAN then begin
        Dec(QuickEval, KING_VALUE - MAN_VALUE);
        Dec(BlackKings);
        Inc(BlackMen);
        AdjustHashKey(aBoard.HashKey, RP_BLACKKING, fromSq);
        AdjustHashKey(aBoard.HashKey, RP_BLACKMAN, fromSq);
      end
      else begin
        Inc(QuickEval, KING_VALUE - MAN_VALUE);
        Dec(WhiteKings);
        Inc(WhiteMen);
        AdjustHashKey(aBoard.HashKey, RP_WHITEKING, fromSq);
        AdjustHashKey(aBoard.HashKey, RP_WHITEMAN, fromSq);
      end;
    end;

    if Board[fromSq] = RP_BLACKMAN then begin
      Inc(Tempo, BLACK_TEMPO[fromSq]);
      Dec(Tempo, BLACK_TEMPO[toSq]);
    end
    else if Board[fromSq] = RP_WHITEMAN then begin
      Dec(Tempo, WHITE_TEMPO[fromSq]);
      Inc(Tempo, WHITE_TEMPO[toSq]);
    end;

    {Return the taken pieces to the board}
    with aMoveList do begin
      if MoveInfo[aIndex].JumpIndex > 0 then begin
        for i := MoveInfo[aIndex].JumpIndex to MoveInfo[aIndex].JumpIndex + MoveInfo[aIndex].JumpSize - 1 do begin
          Board[KilledPieces[i].Square] := KilledPieces[i].Piece;
          case KilledPieces[i].Piece of
            RP_WHITEMAN  : begin
              Dec(QuickEval, MAN_VALUE);
              Inc(WhiteMen);
              Dec(Tempo, WHITE_TEMPO[KilledPieces[i].Square]);
              AdjustHashKey(aBoard.HashKey, RP_WHITEMAN, KilledPieces[i].Square);
            end;
            RP_BLACKMAN  : begin
              Inc(QuickEval, MAN_VALUE);
              Inc(BlackMen);
              Inc(Tempo, BLACK_TEMPO[KilledPieces[i].Square]);
              AdjustHashKey(aBoard.HashKey, RP_BLACKMAN, KilledPieces[i].Square);
            end;
            RP_WHITEKING : begin
              Dec(QuickEval, KING_VALUE);
              Inc(WhiteKings);
              AdjustHashKey(aBoard.HashKey, RP_WHITEKING, KilledPieces[i].Square);
            end;
            RP_BLACKKING : begin
              Inc(QuickEval, KING_VALUE);
              Inc(BlackKings);
              AdjustHashKey(aBoard.HashKey, RP_BLACKKING, KilledPieces[i].Square);
            end;
          end; // case
        end; // for
      end; // if
    end; // with aMovelist
    aBoard.ColorToMove := aBoard.ColorToMove xor RP_CHANGECOLOR;
  end; // with
end; // UndoMove

function FindMove(
  var aMoveList   : TMoveList;
      aStart      : Integer;
      aEnd        : Integer;
      aFromSquare : Integer;
      aToSquare   : Integer
): Integer;
var
  i : Integer;
begin
  {If the move cannot be found then simply return the first in the range of moves.
   So no access violations occur in case a non existing move is looked for.
   This might arise when forward pruning occurs in the main variant. F.i. if a
   short term sacrifice appears to be the best.}
  result := aStart;
  for i := aStart to aEnd do begin
    if
      (aMoveList.Moves[i].FromSquare = aFromSquare) and
      (aMoveList.Moves[i].ToSquare = aToSquare)
    then begin
      result := i;
      Break;
    end;
  end;
end; // FindMove

procedure SwapMoves(
  var aMoveList : TMoveList;
      aIndex1   : Integer;
      aIndex2   : Integer
);
var
  tempMove  : TMove;
  tempInfo  : TExtraMoveInfo;
begin
{ TODO :
Take a pointer to MoveInfo in TMove. Save some processor time.
Then a proc CopyMove can be made too.
(Not a lot as at this moment (0.27) SwapMoves is only called a very few times during a search.) }
  Assert(
    (aIndex1 >= Low(aMoveList.Moves)) and (aIndex1 <= High(aMoveList.Moves)),
    'Value aIndex1 is out of bounds: ' + IntToStr(aIndex1)
  );
  Assert(
    (aIndex2 >= Low(aMoveList.Moves)) and (aIndex2 <= High(aMoveList.Moves)),
    'Value aIndex2 is out of bounds: ' + IntToStr(aIndex2)
  );

  if aIndex1 <> aIndex2 then begin
    tempMove.FromSquare := aMoveList.Moves[aIndex1].FromSquare;
    tempMove.ToSquare   := aMoveList.Moves[aIndex1].ToSquare;
    tempInfo.Promotion  := aMoveList.MoveInfo[aIndex1].Promotion;
    tempInfo.JumpIndex  := aMoveList.MoveInfo[aIndex1].JumpIndex;
    tempInfo.JumpSize   := aMoveList.MoveInfo[aIndex1].JumpSize;
    {copy aIndex2 to aIndex1}
    aMoveList.Moves[aIndex1].FromSquare    := aMoveList.Moves[aIndex2].FromSquare;
    aMoveList.Moves[aIndex1].ToSquare      := aMoveList.Moves[aIndex2].ToSquare;
    aMoveList.MoveInfo[aIndex1].Promotion  := aMoveList.MoveInfo[aIndex2].Promotion;
    aMoveList.MoveInfo[aIndex1].JumpIndex  := aMoveList.MoveInfo[aIndex2].JumpIndex;
    aMoveList.MoveInfo[aIndex1].JumpSize   := aMoveList.MoveInfo[aIndex2].JumpSize;
    {Copy temp to index2}
    aMoveList.Moves[aIndex2].FromSquare    := tempMove.FromSquare;
    aMoveList.Moves[aIndex2].ToSquare      := tempMove.ToSquare;
    aMoveList.MoveInfo[aIndex2].Promotion  := tempInfo.Promotion;
    aMoveList.MoveInfo[aIndex2].JumpIndex  := tempInfo.JumpIndex;
    aMoveList.MoveInfo[aIndex2].JumpSize   := tempInfo.JumpSize;
  end;
end; // SwapMoves

procedure InitializeBoard(var aBoard : TBoardStruct; aColorToMove: Integer);
var
  i : Integer;
begin
  with aBoard do begin
    ColorToMove := aColorToMove;
    QuickEval   := 0;
    BlackMen    := 0;
    BlackKings  := 0;
    WhiteMen    := 0;
    WhiteKings  := 0;
    Tempo       := 0;

    for i := Low(TBoard) to High(TBoard) do begin
      case Board[i] of
        RP_WHITEMAN  : begin
          Dec(QuickEval, MAN_VALUE);
          Inc(WhiteMen);
          Dec(Tempo, WHITE_TEMPO[i]);
        end;
        RP_BLACKMAN  : begin
          Inc(QuickEval, MAN_VALUE);
          Inc(BlackMen);
          Inc(Tempo, BLACK_TEMPO[i]);
        end;
        RP_WHITEKING : begin
          Dec(QuickEval, KING_VALUE);
          Inc(WhiteKings);
        end;
        RP_BLACKKING : begin
          Inc(QuickEval, KING_VALUE);
          Inc(BlackKings);
        end;
      end; // case
    end; // for

    HashKey := CalculateHashKey(aBoard.Board);
  end; // with
end; // InitializeBoard
{
  $Log
  27-11-2002, DG : First version. Simple moves. No jumps.
  02-12-2002, DG : Implemented GenerateKingJump, GenerateManJump.
  06-12-2002, DG : Added UndoMove.
  09-12-2002, DG : Implemented UndoMove and GetMoveCount.
  11-12-2002, DG : Fixed a bug in UndoMove and one in GenerateMoves.
  18-12-2002, DG : New MoveList implementation.
}
end.

