{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\ReveTypes.paV 
{
{   Rev 1.0    28/09/03 20:28:22  Dgrava
{ Initial Revision
}
{
   Rev 1.5    16-6-2003 21:13:13  DGrava
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
{}
unit ReveTypes;
{This unit contains the native types and consts of my checker engine.}
interface

uses
  CBTypes;

const
  ENGINE_NAME     = 'Reve64';
  ENGINE_VERSION  = '0.43'{$IFDEF QUIESCENSE_SEARCH}+'+'{$ENDIF}{$IFDEF DEBUG_REVE}+'Debug mode'{$ENDIF};

type
  THashKey      = Int64;
  TBoard        = array [1..32] of Integer;

  TBoardStruct  = record
    Board       : TBoard;
    ColorToMove : Integer;
    QuickEval   : Integer;
    HashKey     : THashKey;
    BlackMen    : Integer;
    BlackKings  : Integer;
    WhiteMen    : Integer;
    WhiteKings  : Integer;
    Tempo       : Integer;
  end;

const
  // value for reve pieces
  RP_WHITE  = CB_WHITE; // 1
  RP_BLACK  = CB_BLACK; // 2
  RP_MAN    = CB_MAN;   // 4
  RP_KING   = CB_KING;  // 8
  RP_FREE   = 0;// CB_FREE; // 16
  RP_BLACKMAN   = RP_BLACK or RP_MAN;
  RP_WHITEMAN   = RP_WHITE or RP_MAN;
  RP_BLACKKING  = RP_BLACK or RP_KING;
  RP_WHITEKING  = RP_WHITE or RP_KING;
  RP_KILLED       = 32;
  RP_CHANGECOLOR  = 3;

  // Evaluation values
  WIN                   = 30000;
  LOSS                  = - WIN;
  MAN_VALUE             = 1000;
  KING_VALUE            = 1300;

  // Tempo values
  BLACK_TEMPO : array [1..32] of Integer = (
    -7, -7, -7, -7,
    -6, -6, -6, -6,
    -5, -5, -5, -5,
    -4, -4, -4, -4,
    -3, -3, -3, -3,
    -2, -2, -2, -2,
    -1, -1, -1, -1,
     0,  0,  0,  0
  );

  WHITE_TEMPO : array [1..32] of Integer = (
     0,  0,  0,  0,
    -1, -1, -1, -1,
    -2, -2, -2, -2,
    -3, -3, -3, -3,
    -4, -4, -4, -4,
    -5, -5, -5, -5,
    -6, -6, -6, -6,
    -7, -7, -7, -7
  );


implementation
{ $Log
  25-11-2002, DG : Created.
}
end.

