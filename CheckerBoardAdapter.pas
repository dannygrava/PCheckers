unit CheckerBoardAdapter;

interface

uses
  ExtCtrls, CBTypes,
  // DeepBrew
  DataTypes, Thinker;

type
  TCheckerBoardAdapter = class
  private
    //FTimer   : TTimer;
    FThinker : TThinkerThread;
    FSearchStartedAt : Cardinal;
    FLastUpdateAt : Cardinal;
    FSearchTime : Cardinal;
    FOutput     : PChar;

//    procedure HandleTimeUp (aSender : TObject);
//    procedure HandleSearchEnded (aSender: TObject);
    function  IsSquareSetOnBitBoard(const aBitBoard: TBitBoard;
      aSquare: Integer): Boolean;
    procedure SetSquareOnBitBoard(var aBitBoard: TBitBoard;
      aSquare: Integer);
    procedure ConvertToBitBoard (var aCBBoard : TCBBoard);
    procedure ConvertFromBitBoard (var aCBBoard : TCBBoard);
    procedure UpdateSearchStats;
    function  MustStopSearch : Boolean;

  public
    constructor Create;
    destructor  Destroy; override;

    procedure GetMove (var aCBBoard : TCBBoard; aCBColor : Integer;
      aMaxTime : Double; aStr : PChar; var aPlayNow  : Boolean; aInfo : Integer
    );
    function EngineCommand(aInput: PChar; aReply: PChar): Integer; 

  end;

implementation

uses
  SysUtils, Windows,
  // DeepBrew
  Utils, Hashing;

constructor TCheckerBoardAdapter.Create;
begin
  PreInitialise;

  FThinker := TThinkerThread.Create(True);
  FThinker.NodeCounter := 0;
  FThinker.FreeOnTerminate := False;
  FThinker.OnCheckSearchTerminated := MustStopSearch;
  //FThinker.OnTerminate := HandleSearchEnded;

//  FTimer := TTimer.Create(nil);
//  FTimer.Enabled := False;
//  FTimer.Interval := 5000;
//  FTimer.OnTimer := HandleTimeUp;
end; // TCheckerBoardAdapter.Create

destructor TCheckerBoardAdapter.Destroy;
begin
  try
    FreeAndNil (FThinker);
    //FreeAndNil (FTimer);
  finally
    inherited Destroy;
  end;
end; // TCheckerBoardAdapter.Destroy

//procedure TCheckerBoardAdapter.HandleTimeUp(aSender: TObject);
//begin
//  FThinker.Terminate;
//end; // TCheckerBoardAdapter.HandleTimeUp

//procedure TCheckerBoardAdapter.HandleSearchEnded(aSender: TObject);
//begin
//  //memo1.Lines.Text := GetSearchResults;
//  FTimer.Enabled := False;
//end; // TCheckerBoardAdapter.HandleSearchEnded

procedure TCheckerBoardAdapter.UpdateSearchStats;
var
  timeSpent   : Cardinal;
  nodesPerSec : Cardinal;
  result : string;
begin
  timeSpent := (FSearchStartedAt - GetTickCount) div 1000;
  nodesPerSec := (FThinker.NodeCounter div timeSpent);
  // TODO use Format
  result := 'Best ' + MoveToString(FThinker.BestSoFar);
  result := result + '; Score ' + IntToStr(FThinker.Score);
  result := result + '; Depth ' + IntToStr(FThinker.MinDepth) + '/' + IntToStr(PeakDepth);
  result := result + '; ' + IntToStr(FThinker.NodeCounter) + ' nodes (' + IntToStr(nodesPerSec) + '/sec)';
  result := result + '; ' + IntToStr(nHashHits) + ' hash hits';

  StrCopy(FOutPut, PChar (result));
end; // TCheckerBoardAdapter.UpdateSearchStats

procedure TCheckerBoardAdapter.GetMove (var aCBBoard : TCBBoard; aCBColor : Integer;
  aMaxTime : Double; aStr : PChar; var aPlayNow  : Boolean; aInfo : Integer
);
begin
  ConvertToBitBoard (aCBBoard);
  //FTimer.Interval := Trunc (aMaxTime * 1000);
  if aCBColor = CB_BLACK then begin
    Board.SideToMove := BLACK_TO_MOVE;
  end
  else if aCBColor = CB_WHITE then begin
    Board.SideToMove := WHITE_TO_MOVE;
  end;

  FSearchTime := Trunc(aMaxTime * 1000);
  FOutPut     := aStr;
  // TODO implement aPlayNow

  // aInfo not used here, contains some flags (new game started etc.)
  //FThinker.SearchTime := Trunc (aMaxTime * 1000);
  FSearchStartedAt := GetTickCount;
  FLastUpdateAt := FSearchStartedAt;
  FThinker.Resume;
  //FTimer.Enabled := True;
  FThinker.WaitFor; // waits for thread to finish

  ConvertFromBitBoard(aCBBoard);
  // TODO Get rid of HandleTimeUp; put code here
end; // TCheckerBoardAdapter.StartSearch

procedure TCheckerBoardAdapter.SetSquareOnBitBoard (
  var aBitBoard :TBitBoard; aSquare : Integer
);
begin
  aBitBoard := (aBitBoard or (1 shl (aSquare - 1)))
end; // TCheckerBoardAdapter.SetSquare

function TCheckerBoardAdapter.IsSquareSetOnBitBoard(
  const aBitBoard : TBitBoard; aSquare : Integer
): Boolean;
begin
  result := (aBitBoard and (1 shl (aSquare - 1))) <> 0;
end; // TForm1.IsSquareOccupied

procedure TCheckerBoardAdapter.ConvertToBitBoard(var aCBBoard: TCBBoard);
var
  i : Integer;
  square : Integer;
begin
  Board.BlackPieces := 0;
  Board.BlackKings := 0;
  Board.WhitePieces := 0;
  Board.WhiteKings := 0;

  for i := 1 to 32 do begin
    square := GetCBSquare(aCBBoard, i);
    case square of
      CB_MAN or CB_WHITE : SetSquareOnBitBoard (Board.WhitePieces, i);
      CB_MAN or CB_BLACK : SetSquareOnBitBoard (Board.BlackPieces, i);
      CB_KING or CB_WHITE: SetSquareOnBitBoard (Board.WhiteKings, i);
      CB_KING or CB_BLACK: SetSquareOnBitBoard (Board.BlackKings, i);
    end;
  end;
end; // TCheckerBoardAdapter.ConvertToBitBoard

procedure TCheckerBoardAdapter.ConvertFromBitBoard(var aCBBoard: TCBBoard);
var
  i : Integer;
begin
  for i := 1 to 32 do begin
    if IsSquareSetOnBitBoard (Board.WhitePieces, i) then begin
      SetCBSquare(aCBBoard, i, CB_MAN or CB_WHITE);
    end
    else if IsSquareSetOnBitBoard (Board.BlackPieces, i) then begin
      SetCBSquare(aCBBoard, i, CB_MAN or CB_BLACK);
    end
    else if IsSquareSetOnBitBoard (Board.WhiteKings, i) then begin
      SetCBSquare(aCBBoard, i, CB_KING or CB_WHITE);
    end
    else if IsSquareSetOnBitBoard (Board.BlackKings, i) then begin
      SetCBSquare(aCBBoard, i, CB_KING or CB_BLACK);
    end;
  end;
end; // TCheckerBoardAdapter.ConvertFromBitBoard

function TCheckerBoardAdapter.MustStopSearch: Boolean;
begin
  result := GetTickCount - FSearchStartedAt > FSearchTime;
  // Update search stats only every 500 ms as expensive operation
  if GetTickCount - FSearchStartedAt > 500 then begin
    FSearchStartedAt := GetTickCount;
    UpdateSearchStats;
  end;
end; // TCheckerBoardAdapter.MustStopSearch

function TCheckerBoardAdapter.EngineCommand(aInput,
  aReply: PChar): Integer;
begin
  if (Pos('name', aInput) > 0) then begin
    StrCopy(aReply, 'Deep Brew 1.1');
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
  else begin
    result := Ord(False);
  end;
end; // TCheckerBoardAdapter.EngineCommand

end.
