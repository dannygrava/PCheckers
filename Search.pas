{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\Search.paV
{
{   Rev 1.1    28/09/03 20:32:05  Dgrava
}
{
   Rev 1.5    16-6-2003 21:13:14  DGrava
 NegaScout refinement applied
}
{
   Rev 1.4    15-6-2003 20:38:29  DGrava
 Disabled forward pruning. Added Quiescens check.
}
{
   Rev 1.3    10-3-2003 21:46:25  DGrava
 Little enhancements.
}
{
   Rev 1.2    20-2-2003 16:38:48  DGrava
 Forward pruning implemented. Extending capture sequences
 with conditional defines
}
{
   Rev 1.1    6-2-2003 11:48:03  DGrava
 Introduction of QuickEval component.
}
{
   Rev 1.0    24-1-2003 21:12:24  DGrava
 Eerste Check in.
 Versie 0.27
}
{}
unit Search;

interface

uses
  ReveTypes, SearchTypes, MoveGenerator, HashTable;

var
  GLOBAL_NumAlphaBetas    : Integer;

const
  UNKNOWN   = -1;

function AlphaBetaSearch(
  var aBoard    : TBoardStruct;
      aMaxTime  : cardinal;
      aOutput   : PChar;
  var aPlayNow  : boolean;
  var aHashTable: THashTable;
      aDepth    : Integer
): Integer;

implementation

uses
  Windows{for GetTickCount :(}, SysUtils, Evaluation
  {$IFDEF DEBUG_REVE}
  , DebugUtils
  {$ENDIF}
  ;

const
  ALPHABETA_FRAME = KING_VALUE - MAN_VALUE;

function AlphaBeta(
  var aBoard          : TBoardStruct;
  var aMoveList       : TMoveList;
      aDepth          : Integer;
      aAlpha          : Integer;
      aBeta           : Integer;
      aDepthFromRoot  : Integer;
  var aBestLine       : TMoveLine;
  var aHashTable      : THashTable
): Integer; forward;

function AlphaBetaSearch(
  var aBoard    : TBoardStruct;
      aMaxTime  : Cardinal;
      aOutput   : PChar;
  var aPlayNow  : Boolean;
  var aHashTable: THashTable;
      aDepth    : Integer
): Integer;
{NOTE aMaxTime is specified in ms.}
var
  moveList      : TMoveList;
  startTime     : cardinal;
  depth         : Integer;
  numMoves      : Integer;
  temp          : string;
  alfa, beta    : Integer;
  searchResults : TSearchResults;
  maxTime       : Cardinal;
  maxDepth      : Integer;
begin
  result          := UNKNOWN;
  GLOBAL_NumAlphaBetas  := 0;
  GLOBAL_NumEvaluations := 0;

  moveList.AtMove := Low(moveList.Moves);
  moveList.AtJump := Low(moveList.KilledPieces);

  InitSearchResults(searchResults);

  startTime       := GetTickCount;

  GenerateMoves(moveList, aBoard.Board, aBoard.ColorToMove);
  { NOTE Check number of moves.
    If no moves then break and return loss;
    if only one move then execute move without further searching;
    if more than one move then perform alpha beta search.
  }
  numMoves := moveList.AtMove - Low(moveList.Moves);
  if numMoves = 0 then begin
    result := LOSS;
    Exit;
  end
  else if numMoves = 1 then begin
    ExecuteMove(moveList, aBoard, 1);
    StrCopy(aOutput, #0);
    Exit;
  end;

  // Main flow
  alfa  := LOSS - 1;
  beta  := WIN + 1;
  if aDepth > 0 then begin
    maxDepth := aDepth;
    maxTime  := 1000 * 60 * 30; // = 30 minutes
  end
  else begin
    maxDepth := MAX_DEPTH;
    maxTime  := aMaxTime;
  end;

  hashTable_Initialize(aHashTable);

  depth := 2;
  while depth <= maxDepth do begin
    moveList.AtMove := Low(moveList.Moves);
    moveList.AtJump := Low(moveList.KilledPieces);

    result := AlphaBeta(
      aBoard,
      moveList,
      depth,
      alfa,
      beta,
      0,
      searchResults.bestLine,
      aHashTable
    );

    if (result <= alfa) or (result >= beta) then begin
      {Fail high or fail low situation,
       research with full alfa beta window.}
      alfa := LOSS - 1;
      beta := WIN + 1;

      result := AlphaBeta(
        aBoard,
        moveList,
        depth,
        alfa,
        beta,
        0,
        searchResults.bestLine,
        aHashTable
      );
    end;

    FillSearchResults (
      searchResults, depth, GLOBAL_NumAlphaBetas, GLOBAL_NumEvaluations, result div 10, GetTickCount - startTime + 1
    );

    SearchResultsToString(searchResults, temp);
    StrCopy(aOutput, @temp[1]);

    if (
      ((GetTickCount - StartTime) > maxTime) or
      aPlayNow or
      (Abs(result) = WIN)
    ) then begin
      Break;
    end;

    {Set alfa beta window}
    alfa := result - ALPHABETA_FRAME;
    beta := result + ALPHABETA_FRAME;

    Inc(depth);
  end; // for

  ExecuteMove(
    moveList,
    aBoard,
    FindMove(
      moveList,
      Low(moveList.Moves),
      High(moveList.Moves),
      searchResults.bestLine.Moves[searchResults.bestLine.AtMove - 1].FromSquare,
      searchResults.bestLine.Moves[searchResults.bestLine.AtMove - 1].ToSquare
    )
  );
end; // AlphaBetaSearch

function AlphaBeta(
  var aBoard          : TBoardStruct;
  var aMoveList       : TMoveList;
      aDepth          : Integer;
      aAlpha          : Integer;
      aBeta           : Integer;
      aDepthFromRoot  : Integer;
  var aBestLine       : TMoveLine;
  var aHashTable      : THashTable
): Integer;
const
  NO_SQUARE = 0;
var
  firstMove     : Integer;
  firstJump     : Integer;
  i, j          : Integer;
  value         : Integer;
  newLine       : TMoveLine;
  pHEntry       : PHashEntry;
  resultType    : TValueType;
  bestFrom      : Integer;
  bestTo        : Integer;
  {$IFDEF DEBUG_REVE}
  tmpBoard      : TBoardStruct;
  {$ENDIF}
begin
  Inc(GLOBAL_NumAlphaBetas);

  { NOTE
    If the other color threatens to take at the next move then we add a penalty
    to the score, so that it might not give a good score to a variant that is
    a dead loss.

    This appeared to introduce a lot of instability (search results changing with
    great amounts on consecutive search depths) in the search.

    Instead of giving a penalty we might also extend the search depth. This may
    seem to lead to better evaluations of the position, but instead it might end
    up in an infinite loop in case of kings.
    For example the following position:
    Black: 3, K10
    White: K2
    White to move.

    It will loop inifinitely with the following variant:
    2-7 (10-6) white king threatened 7-2 black king threatened (6-10) 7-2 etc.
    As the engine does not recognize move repititions at this moment it will
    keep on repeating this variant and extending the search depth.

    So what we might need to do is to just search 1 extra level to check if
    the piece is not immediately taken.

    We will abuse the search depth param by assigning it a special value.
  }

  {$IFDEF QUIESCENSE_SEARCH}
  if (aDepth = 0) and IsThreatPresent(aBoard.Board, aBoard.ColorToMove xor RP_CHANGECOLOR) then begin
    aDepth := -1;
  end;

  if aDepth = -2 then begin
    { search depth is -2 then we come from a non stable terminal node. Evaluate it.}
    aDepth := 0;
  end;
  {$ENDIF}

  if (aDepth = 0) then begin
    result := Evaluate(aBoard);
    Exit;
  end;

  bestFrom := NO_SQUARE;
  bestTo   := NO_SQUARE;
  {Lookup position in hashtable before doing anything else.
    if found there we can simply return the value and skip the search.}
  pHEntry := hashTable_GetEntry(aHashTable, aBoard.HashKey);
  if (pHEntry <> nil) and (pHEntry^.ColorToMove = aBoard.ColorToMove) then begin
    if pHEntry^.Depth >= aDepth then begin
      case pHEntry^.ValueType of
        vtExact : begin
          result := pHEntry^.Value;
          Exit;
        end;
        vtLowerBound : begin
          if pHEntry^.Value >= aBeta then begin
            result    := pHEntry^.Value;
            Exit;
          end
          else begin
           { Smart trick from PubliCake:
             You can narrow the alpha beta frame with the upper and lower bound
             values from the hash table.

             In some positions it results in significant improvements of
             the search results, but in most positions it costs a little
             performance.
           }
            if pHEntry^.Value > aAlpha then begin
              aAlpha := pHEntry^.Value;
            end;
            bestFrom  := pHEntry^.FromSquare;
            bestTo    := pHEntry^.ToSquare;
          end;
        end;
        vtUpperBound : begin
          if pHEntry^.Value <= aAlpha then begin
            result := pHEntry^.Value;
            Exit;
          end
          else begin
            if pHEntry^.Value < aBeta then begin
              aBeta := pHEntry^.Value;
            end;
          end;
        end;
      end; // case
    end
    else begin
      bestFrom  := pHEntry^.FromSquare;
      bestTo    := pHEntry^.ToSquare;
    end;
  end;

  firstMove   := aMoveList.AtMove;
  firstJump   := aMoveList.AtJump;

  GenerateMoves(aMoveList, aBoard.Board, aBoard.ColorToMove);

  {Check if there are any moves!!!}
  if aMoveList.AtMove = firstMove then begin
    result      := LOSS;
    resultType  := vtExact;

    hashTable_AddEntry(
      aHashTable,
      aBoard.HashKey,
      aDepth,
      aBoard.ColorToMove,
      resultType,
      result,
      NO_SQUARE,
      NO_SQUARE
    );
    Exit;
  end;

  // Main Flow
  {Put move from main line in front.}
//  if aMainLine.AtMove >= Low(aMainLine.Moves) then begin
  if bestFrom <> NO_SQUARE then begin
    SwapMoves(
      aMoveList,
      firstMove,
      FindMove(
        aMoveList,
        firstMove,
        aMoveList.AtMove -1,
        bestFrom,
        bestTo
      )
    );
    //Dec(aMainLine.AtMove);
  end;

  result      := aAlpha;
  resultType  := vtUpperBound;

  i := firstMove;
  while i < (aMoveList.AtMove) do begin
    {$IFDEF DEBUG_REVE}
    CopyBoard(aBoard, tmpBoard);
    {$ENDIF}
    ExecuteMove(aMoveList, aBoard, i);
    // Test code
    if aMoveList.AtMove - 1 = firstMove then begin
      // There is just one move extend depth
      Inc (aDepth);
    end;

    if i = firstMove then begin
      newLine.AtMove  := 1;
      value := - AlphaBeta(
        aBoard,
        aMoveList,
        aDepth - 1,
        - aBeta,
        - result,
        aDepthFromRoot + 1,
        newLine,
        aHashTable
      );
    end
    else begin
      // Negascout refinement
      { NOTE
        Tests revealed that the window should realy be minimal (=1). Otherwise
        performance drops rapidly.
      }
      newLine.AtMove  := 1;
      value := - AlphaBeta(
        aBoard,
        aMoveList,
        aDepth - 1,
        - result - 1,
        - result,
        aDepthFromRoot + 1,
        newLine,
        aHashTable
      );
      if (value > result) and (value < aBeta) then begin
        newLine.AtMove  := 1;
        value := - AlphaBeta(
          aBoard,
          aMoveList,
          aDepth - 1,
          - aBeta,
          - result,
          aDepthFromRoot + 1,
          newLine,
          aHashTable
        );
      end;
    end;

    UndoMove(aMoveList, aBoard, i);

    {$IFDEF DEBUG_REVE}
    CompareBoard(aBoard, tmpBoard);
    {$ENDIF}

    // Check alpha beta prune
    if value >= aBeta then begin
      result := value;
      resultType := vtLowerBound;
      bestFrom   := aMoveList.Moves[i].FromSquare;
      bestTo     := aMoveList.Moves[i].ToSquare;

      Break;
    end;

    // Check if it is the best move so far
    if value > result then begin
      resultType  := vtExact;
      result      := value;
      // copy new line to best line
      for j := 1 to newLine.AtMove - 1 do begin
        aBestLine.Moves[j].FromSquare  := newLine.Moves[j].FromSquare;
        aBestLine.Moves[j].ToSquare    := newLine.Moves[j].ToSquare;
      end;
      aBestLine.AtMove  := newLine.AtMove;
      // Add the new move
      aBestLine.Moves[aBestLine.AtMove].FromSquare  := aMoveList.Moves[i].FromSquare;
      bestFrom                                      := aMoveList.Moves[i].FromSquare;
      aBestLine.Moves[aBestLine.AtMove].ToSquare    := aMoveList.Moves[i].ToSquare;
      bestTo                                        := aMoveList.Moves[i].ToSquare;

      Inc(aBestLine.AtMove);
      {NOTE
        copying the new moveline to best moveline.
        Costs some performance (not a lot: between 0.5-2.0%).
        You can restrict this performence penalty by having an array of movelines;
        for every ply one + a best line. In case of a better line you simply
        swap the pointers of the best line and the current line of that ply level.
      }
    end;
    Inc(i);
  end; // while

  // Reset list pointer
  aMoveList.AtJump := firstJump;
  aMoveList.AtMove := firstMove;

  hashTable_AddEntry(
    aHashTable,
    aBoard.HashKey,
    aDepth,
    aBoard.ColorToMove,    
    resultType,
    result,
    bestFrom,
    bestTo
  );

  {$IFDEF DEBUG_REVE}
  CheckCertainPositions(aBoard, aBestLine, aDepth, result, aAlpha, aBeta, resultType);
  {$ENDIF}
end; // AlphaBeta
{
  $Log
  06-12-2002, DG : Created.
  09-12-2002, DG : First working version.
  10-12-2002, DG : Fixed several bugs.
  11-12-2002, DG : AlphaBeta did not return best value.
  18-12-2002, DG : Adjusted for new MoveList implementation.
  04-01-2002, DG : Saving principle variation for display.
  12-01-2003, DG : Added ab windowing.
}
end.
