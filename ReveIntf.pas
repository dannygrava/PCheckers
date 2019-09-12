{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\ReveIntf.paV 
{
{   Rev 1.0    28/09/03 20:28:21  Dgrava
{ Initial Revision
}
{
   Rev 1.3    10-3-2003 21:46:25  DGrava
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
   Rev 1.0    24-1-2003 21:12:24  DGrava
 Eerste Check in.
 Versie 0.27
}
unit ReveIntf;

interface

uses
  CBTypes, HashTable;

function enginecommand(aInput: PChar; aReply: PChar): integer; stdcall;
function getmove(
  var aCBBoard  : TCBBoard;
  aCBColor      : integer;
  aMaxTime      : double;
  aStr          : PChar;
  var aPlayNow  : boolean;
  aInfo         : integer;
  aUnused       : integer;
  aCBMove       : pointer
): integer; stdcall;

var
  HTable      : THashTable;

implementation

uses
  SysUtils, ReveTypes, Search, CBConversionUtils, MoveGenerator;

var
  SearchLevel : Integer = 0;

// This is an EXPORTed routing (see chkkit.def)
// This processes commands from the front end.
// Ret TRUE if command is legal, FALSE if not recognised
// Note Pay Attention to Case Sensitivity
function enginecommand(aInput: PChar; aReply: PChar): integer; stdcall;
begin
  if (Pos('name', aInput) > 0) then begin
    StrCopy(aReply, ENGINE_NAME + ' ' + ENGINE_VERSION);
    result  := Ord(True);
  end
  else if (Pos('get gametype', aInput ) > 0) then begin
    StrCopy(aReply, '21');
    result  := Ord(True);
  end
  else if (Pos('get protocolversion', aInput) > 0) then begin
    StrCopy(aReply, '2');
    result  := Ord(True);
  end
  else if (Pos('set level', aInput) > 0) then begin
    if StrLen(aInput) > StrLen('set level') then begin
      try
        SearchLevel := StrToInt(string(aInput + StrLen('set level')));
      except
        on EConvertError do begin
          SearchLevel := 0;
        end;
      end;
    end
    else begin
      SearchLevel := 0;
    end;
    StrCopy(aReply, PChar (IntToStr(SearchLevel)));
    result := Ord(True);
  end
  else if (Pos('get level', aInput) > 0) then begin
    StrCopy(aReply, PChar (IntToStr(SearchLevel)));
    result := Ord(True);
  end
  else begin
    result := Ord(False);
  end;
end; // enginecommand

// getmove(..) Is a routine called by the front end.
//   b[8][8] current position, vals are combos of CB_WHITE/CB_BLACK/CB_MAN/CB_KING..
//       (0,0) == sqr 4, (7,7) = sqr 29 etc..
//   color	side to move CB_WHITE/CB_BLACK
//   maxtime	time to use for this move. Loose control, exceed a bit if you need to
//              front end should regulate long term usage..
//   str	Output string for front end
//   *playnow	Set when front end wants to force a move. when non-zero, abort search fast..
//   struct CBmove *move   Unused here, used for other checker variants.
{  C Header
  int WINAPI getmove (int b[8][8], int color, double maxtime, char str[255],
	int *playnow, int info, int unused, struct CBmove *move)
}
function getmove(
  var aCBBoard  : TCBBoard;
  aCBColor      : integer;
  aMaxTime      : double;
  aStr          : PChar;
  var aPlayNow  : boolean;
  aInfo         : integer;
  aUnused       : integer;
  aCBMove       : pointer
): integer; stdcall;
var
  board : TBoardStruct;
begin
  result := CB_LOSS;

  FillBoard(board, aCBBoard);
  InitializeBoard(board, aCBColor);

  try
    AlphaBetaSearch(
      board,
      Trunc(aMaxTime * 1000),
      aStr,
      aPlayNow,
      HTable,
      SearchLevel
    );
    FillCBBoard(aCBBoard, board);
  except
    // Do nothing for now
  end;
end; // getmove

const
  ONE_MEGABYTE = 1 shl 20;

initialization
  hashTable_Create(HTable, 8 * ONE_MEGABYTE);
finalization
  hashTable_Free(HTable);
end.
