{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\CBConversionUtils.paV
{
{   Rev 1.0    28/09/03 20:28:22  Dgrava
{ Initial Revision
}
{
   Rev 1.2    10-3-2003 21:46:23  DGrava
 Little enhancements.
}
{
   Rev 1.1    6-2-2003 11:48:01  DGrava
 Introduction of QuickEval component.
}
{
   Rev 1.0    24-1-2003 21:12:22  DGrava
 Eerste Check in.
 Versie 0.27
}
unit CBConversionUtils;
{This unit contains routines to convert between a native board and
  a CB type board.}
interface

uses
  CBTypes, ReveTypes;

const
  STDBOARD  : TCBBoard  = (
    (4, 0, 12, 0, 20, 0, 28, 0),
    (0, 8, 0, 16, 0, 24, 0, 32),
    (3, 0, 11, 0, 19, 0, 27, 0),
    (0, 7, 0, 15, 0, 23, 0, 31),
    (2, 0, 10, 0, 18, 0, 26, 0),
    (0, 6, 0, 14, 0, 22, 0, 30),
    (1, 0, 9, 0, 17, 0, 25, 0),
    (0, 5, 0, 13, 0, 21, 0, 29)
  );

procedure SetCBSquare (var aCBBoard : TCBBoard; aSquare : Integer; aPieceValue : Integer);
function  GetCBSquare (var aCBBoard : TCBBoard; aSquare : Integer) : Integer;
procedure FillBoard   (var aBoard : TBoardStruct; var aCBBoard : TCBBoard);
procedure FillCBBoard (var aCBBoard : TCBBoard; var aBoard: TBoardStruct);

implementation

{Sets the piece (aPieceValue) on the CB type board. aSquare is in standard
 notation.
 This routine is not optimized for speed.}
procedure SetCBSquare (var aCBBoard : TCBBoard; aSquare : Integer; aPieceValue : Integer);
var
  i, j : Integer;
begin
  for i := Low(TCBBoard) to High(TCBBoard) do begin
    for j := Low(TCBBoard) to High (TCBBoard) do begin
      if (STDBOARD[i,j] = aSquare) then begin
        aCBBoard[i,j] := aPieceValue;
        Break;
      end;
    end;
  end;
end; // StdToCBBoard

{Returns the piece/value for a square in standard notation on CBBoard type board.}
function GetCBSquare (var aCBBoard : TCBBoard; aSquare : Integer) : Integer;
var
  i, j : Integer;
begin
  result := CB_FREE;
  for i := Low(TCBBoard) to High(TCBBoard) do begin
    for j := Low(TCBBoard) to High (TCBBoard) do begin
      if (STDBOARD[i,j] = aSquare) then begin
        result := aCBBoard[i,j];
        break;
      end;
    end;
  end;
end; // GetCBSquare

{Converts a CBboard to a standard board.}
procedure FillBoard (var aBoard : TBoardStruct; var aCBBoard : TCBBoard);
var
  i : Integer;
begin
  with aBoard do begin
    for i := Low(TBoard) to High(TBoard) do begin
      Board[i] := GetCBSquare(aCBBoard, i);
    end; // for
  end; // with
end; // FillBoard

{Converts a standard board to a CBBoard.}
procedure FillCBBoard (var aCBBoard : TCBBoard; var aBoard: TBoardStruct);
var
  i : Integer;
begin
  for i := Low(TBoard) to High(TBoard) do begin
    SetCBSquare(aCBBoard, i, aBoard.Board[i]);
  end;
end; //FillCBBoard

{ $Log
  25-11-2002, DG : Created.
}
end.

