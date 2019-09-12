{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\DebugUtils.paV
{
{   Rev 1.0    28/09/03 20:28:20  Dgrava
{ Initial Revision
}
{
   Rev 1.3    15-6-2003 20:38:28  DGrava
 Disabled forward pruning. Added Quiescens check.
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
unit DebugUtils;

interface

uses
  ReveTypes, SearchTypes, MoveGenerator, Search, HashTable;

procedure CopyBoard (var aOrigin: TBoardStruct; var aCopy : TBoardStruct);
function  CompareBoard(var aOrigin: TBoardStruct; var aCopy : TBoardStruct): Integer;
function  CalculateCheck  (var aBoard : TBoard): Cardinal;
procedure CheckCertainPositions(
  var aBoard       : TBoardStruct;
  var aMainVariant : TMoveLine;
      aDepth       : Integer;
      aValue       : Integer;
      aAlpha       : Integer;
      aBeta        : Integer;
      aValueType   : TValueType
);

implementation

uses
  SysUtils;

var
  Log           : TextFile;

const
  LOG_FILENAME = 'Reve.Log';

procedure CopyBoard (var aOrigin: TBoardStruct; var aCopy : TBoardStruct);
var
  i : Integer;
begin
  aCopy.QuickEval   := aOrigin.QuickEval;
  aCopy.BlackMen    := aOrigin.BlackMen;
  aCopy.BlackKings  := aOrigin.BlackKings;
  aCopy.WhiteMen    := aOrigin.WhiteMen;
  aCopy.WhiteKings  := aOrigin.WhiteKings;
  aCopy.Tempo       := aOrigin.Tempo;
  aCopy.HashKey     := aOrigin.HashKey;
  for i := 1 to 32 do begin
    aCopy.Board[i] := aOrigin.Board[i];
  end;
end; // CopyBoard

function CompareBoard(var aOrigin: TBoardStruct; var aCopy : TBoardStruct): Integer;
var
  i     : Integer;
  hash  : THashKey;
begin
  result := 0;
  if (
        (aCopy.QuickEval  <> aOrigin.QuickEval)
    or  (aCopy.BlackMen   <> aOrigin.BlackMen)
    or  (aCopy.BlackKings <> aOrigin.BlackKings)
    or  (aCopy.WhiteMen   <> aOrigin.WhiteMen)
    or  (aCopy.WhiteKings <> aOrigin.WhiteKings)
  )then begin
    result := -1;
    Assert(False, 'Board was not restored correctly');
  end;

  Assert(aCopy.Tempo = aOrigin.Tempo, 'Tempo differs from origin!');
  Assert(aCopy.HashKey = aOrigin.HashKey, 'Hashkey differs from origin!');

  hash := CalculateHashKey(aCopy.Board);
  if hash <> aCopy.HashKey then begin
    result := -1;
    Assert(False, 'Hashkey differs from calculated.');
  end;

  for i := 1 to 32 do begin
    if aOrigin.Board[i] <> aCopy.Board[i] then begin
      result := i;
      Assert(
        False,
        'Board was not restored correctly. Differs at square '
        + IntToStr(i) + ' found: ' + IntToStr(aOrigin.Board[i]) + ' expected: '+ IntToStr(aCopy.Board[i])
      );
      Break;
    end;
  end;
end; // CompareBoard

const
  RANDOM_2 : array [1..32, 1..4] of Cardinal = (
    ($C1081D76, $9811EF53, $5260FCA4, $AB520339),
    ($8C13F822, $E16DE4AF, $B6903770, $30EF5935),
    ($D85C960E, $1FA6AA4B, $4070837C, $49E70571),
    ($4BE1E33A, $E66BDC27, $3EDFECC8, $5EBF43ED),
    ($08330BA6, $10395643, $B3B9BF54, $EBF090A9),
    ($7B9A7B52, $8433349F, $A1228720, $3461A7A5),
    ($CD89DE3E, $0441D33B, $8014102C, $C22384E1),
    ($5246206A, $1F6DCE17, $6C296678, $716D645D),
    ($972CCC52, $7D2C99F, $24147020, $C73F34A5),
    ($50919F3E, $9AEC983B, $A6FDE92C, $E098C1E1),
    ($4604516A, $7B68C317, $46642F78, $4C37515D),
    ($7DF90ED6, $103C2633, $267F8F04, $26645F19),
    ($49CF4382, $83F3DD8F, $BE8193D0, $AF47A715),
    ($473D9B6E, $7BD1452B, $DC2109DC, $8CA32551),
    ($98FE029A, $E325F907, $C65FD28, $5CF15CD),
    ($2B9A506, $26EFD523, $35B5B9B4, $35F5F489),
    ($4CB9F060, $EA9BB5E5, $BE05257E, $8167377B),
    ($5B80056C, $5FB44F21, $606313AA, $ED6B8E57),
    ($4B3F27B8, $E7F2A9D, $1F654D16, $F9725D73),
    ($630BA344, $3191C459, $13E73DC2, $A574C0CF),
    ($F5330410, $C09FD855, $A15B91AE, $6360146B),
    ($7EC8161C, $3E376291, $6A7834DA, $8E71F447),
    ($6C6EE568, $BFBC9F0D, $69225346, $92D43C63),
    ($5068BDF4, $2BA609C9, $159A58F2, $617908BF),
    ($BC4F0DEC, $482179A1, $886EE82A, $7338B4D7),
    ($E41AE838, $5E0BED1D, $556F1996, $79155BF3),
    ($E0749BC4, $88C09ED9, $C47B8242, $AFAC174F),
    ($64E1B490, $860B4AD5, $777ECE2E, $A14242EB),
    ($C82CFE9C, $F911ED11, $1426E95A, $97ED7AC7),
    ($813285E8, $A50C18D, $53D0FFC6, $9D2F9AE3),
    ($94EB9674, $BDD64449, $A2B57D72, $45D2BF3F),
    ($1BABC40, $3BBF3145, $7A540E5E, $260543DB)
  );

function  CalculateCheck  (var aBoard : TBoard): Cardinal;
var
  i   : Integer;
begin
  result := 0;
  for i := Low(aBoard) to High(aBoard) do begin
    case aBoard[i] of
      RP_BLACKMAN   : result := result xor RANDOM_2[i, 1];
      RP_BLACKKING  : result := result xor RANDOM_2[i, 2];
      RP_WHITEMAN   : result := result xor RANDOM_2[i, 3];
      RP_WHITEKING  : result := result xor RANDOM_2[i, 4];
    end;
  end;
end; // CalculateHashKey

function IsPositionToBeChecked(var aHashKey : THashKey): Boolean;
const
  POSITIONS : array [1..1] of THashKey = (
//    $D367753511477308 // 3-8, 21-17
//    $8AF6AA2DE48F5A40, //1-5:
   $1D0488D579BE92E8//, //3-8:
//    $BE167C2DB0127200, //3-7:
//    $11F15E6D3D57DE40 //6-10:
  );
var
  i : Integer;
begin
  result := False;
  for i := Low(POSITIONS) to High(POSITIONS) do begin
    if aHashKey = POSITIONS[i] then begin
      result := True;
      Break;
    end;
  end;
end; // IsPositionToBeChecked

procedure CheckCertainPositions(
  var aBoard       : TBoardStruct;
  var aMainVariant : TMoveLine;
      aDepth       : Integer;
      aValue       : Integer;
      aAlpha       : Integer;
      aBeta        : Integer;
      aValueType   : TValueType
);
var
  searchResults : TSearchResults;
  temp          : string;
  i             : Integer;
begin
  if IsPositionToBeChecked(aBoard.HashKey) then begin
    InitSearchResults(searchResults);
    for i := aMainVariant.AtMove - 1 downto Low(aMainVariant.Moves) do begin
      searchResults.BestLine.Moves[i].FromSquare := aMainVariant.Moves[i].FromSquare;
      searchResults.BestLine.Moves[i].ToSquare   := aMainVariant.Moves[i].ToSquare;
    end;
    searchResults.BestLine.AtMove := aMainVariant.AtMove;

    searchResults.Depth     := aDepth - 1;
    searchResults.Value     := aValue div 10;
    searchResults.NumABs    := aAlpha div 10;
    searchResults.NumEvals  := aBeta div 10;
    searchResults.Time      := 1;

    SearchResultsToString(searchResults, temp);
    WriteLn(Log, Format('Position: %x', [aBoard.HashKey]));
    case aValueType of
      vtExact      : WriteLn(Log, 'Exact');
      vtUpperBound : WriteLn(Log, 'Upper bound');
      vtLowerBound : WriteLn(Log, 'Lower bound');
    end;
    WriteLn(Log, temp);
  end;
end; // CheckCertainPositions

initialization
  {$IFDEF DEBUG_REVE}
  AssignFile(Log, LOG_FILENAME);
  Rewrite(Log);
  {$ENDIF}

finalization
  {$IFDEF DEBUG_REVE}
  CloseFile(Log);
  {$ENDIF}
end.
