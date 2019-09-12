unit SearchTypes;

interface

uses
  ReveTypes, MoveGenerator {?};

const
  MAX_DEPTH = 50;

type
  TMoveLine = record
    AtMove  : Integer;
    Moves   : array [1..MAX_DEPTH] of TMove;
  end;

  TSearchResults = record
    BestLine  : TMoveLine;
    NumABs    : Integer;
    NumEvals  : Integer;
    Time      : Cardinal;
    Depth     : Integer;
    Value     : Integer;
  end;

procedure InitSearchResults(var aSearchResults : TSearchResults);
procedure SearchResultsToString(var aSearchResults: TSearchResults; var aStr : string);
procedure CopyMoveLine(var aOrigin, aTarget : TMoveLine);
procedure FillSearchResults(
  var aSearchResults : TSearchResults;
      aDepth         : Integer;
      aNumAbs        : Cardinal;
      aNumEvs        : Cardinal;
      aValue         : Integer;
      aTime          : Cardinal
);

implementation

uses
  SysUtils;

procedure CopyMoveLine(var aOrigin, aTarget : TMoveLine);
var
  i : Integer;
begin
  {Copy BestLine to MainLine and feed it to the search.}
  for i := Low(aOrigin.Moves) to aOrigin.AtMove - 1 do begin
    aTarget.Moves[i].FromSquare  := aOrigin.Moves[i].FromSquare;
    aTarget.Moves[i].ToSquare    := aOrigin.Moves[i].ToSquare;
  end;
  aTarget.AtMove := aOrigin.AtMove - 1;
end; // CopyMoveLine

procedure FillSearchResults(
  var aSearchResults : TSearchResults;
      aDepth         : Integer;
      aNumAbs        : Cardinal;
      aNumEvs        : Cardinal;
      aValue         : Integer;
      aTime          : Cardinal
);
begin
  with aSearchResults do begin
    aSearchResults.Depth     := aDepth;
    aSearchResults.NumABs    := aNumAbs;
    aSearchResults.NumEvals  := aNumEvs;
    aSearchResults.Value     := aValue;
    aSearchResults.Time      := aTime; 
  end;
end; // FillSearchResults

procedure InitSearchResults(var aSearchResults : TSearchResults);
begin
  with aSearchResults do begin
    BestLine.AtMove := Low(Bestline.Moves);
    NumABs          := 0;
    NumEvals        := 0;
    Time            := 0;
    Depth           := 0;
    Value           := 0;
  end;
end; // InitSearchResults

procedure SearchResultsToString(var aSearchResults: TSearchResults; var aStr : string);
const
  CRLF        = #13#10;
  DELIMITER   = #32;
var
  i                 : Integer;
  isComputerMove    : Boolean;
  sFrom, sTo        : string[2];
  sTime, sValue     : string;
  sNumAbs, sNumEvs  : string;
  sDepth            : string;
  seperator         : string[1];
begin
  aStr := '';
  try
  {$RANGECHECKS ON}
    with aSearchResults do begin
      isComputerMove := True;
      for i := BestLine.AtMove - 1 downto Low(BestLine.Moves) do begin
        Str(BestLine.Moves[i].FromSquare, sFrom);
        Str(BestLine.Moves[i].ToSquare, sTo);

        if Abs(BestLine.Moves[i].FromSquare - BestLine.Moves[i].ToSquare) in [3,4,5] then begin
          seperator := '-';
        end
        else begin
          seperator := 'x';
        end;

        if isComputerMove then begin
          aStr   := aStr + sFrom + seperator + sTo;
        end
        else begin
          aStr   := aStr + '(' + sFrom + seperator + sTo + ')';
        end;
        isComputerMove := not isComputerMove;
      end;

      Str(Time, sTime);
      Str(Depth, sDepth);
      Str(Value, sValue);
      Str(NumAbs div Integer(Time), sNumAbs);
      Str(NumEvals div Integer(Time), sNumEvs);
      aStr := 'Value = ' + sValue + DELIMITER + 'Time = '
        + sTime + DELIMITER + 'Depth = ' + sDepth + DELIMITER + 'abs = '
        + sNumAbs + DELIMITER + 'evs = ' + sNumEvs + DELIMITER + aStr;
    end; // with
  {$RANGECHECKS OFF}
  except
    on ERangeError do begin
      aStr := 'Not enough room to display statistics!';
    end;
  else
    raise;
  end;
end; // SearchResultsToString

end.
