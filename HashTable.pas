{**********************************************************************}
{ File archived using GP-Version                                       }
{ GP-Version is Copyright 1999 by Quality Software Components Ltd      }
{                                                                      }
{ For further information / comments, visit our WEB site at            }
{ http://www.qsc.co.uk                                                 }
{**********************************************************************}
{}
{ $Log:  C:\PROGRAM FILES\GP-VERSION LITE\Archives\Reve64\Source\HashTable.paV
{
{   Rev 1.0    28/09/03 20:28:21  Dgrava
{ Initial Revision
}
{}
unit HashTable;

interface

uses
  ReveTypes;

const
  VERY_LARGE_INDEX = $AAAAAA;

type
  TValueType = (vtExact, vtLowerBound, vtUpperBound);

  THashEntry  = packed record
    Key         : THashKey;
    Depth       : ShortInt;
    ColorToMove : Byte;
    ValueType   : TValueType;
    Value       : SmallInt;
    FromSquare  : Byte;
    ToSquare    : Byte;
  end;

  PHashEntry  = ^THashEntry;

  THashEntries = array [0..VERY_LARGE_INDEX] of THashEntry;
  PHashEntries = ^THashEntries;

  THashTable = record
    HashEntries   : PHashEntries;
    NumEntries    : Cardinal;
  end;

procedure hashTable_Create(var aHashTable : THashTable; aSize : Integer);
procedure hashTable_Free(var aHashTable : THashTable);
procedure hashTable_AddEntry(
  var aHashTable   : THashTable;
  var aKey         : THashKey;
      aDepth       : Integer;
      aColorToMove : Integer;
      aValueType   : TValueType;
      aValue       : Integer;
      aFromSquare  : Integer;
      aToSquare    : Integer
);
function  hashTable_GetEntry(
  var aHashTable  : THashTable;
  var aHashKey    : THashKey
) : PHashEntry;
function  CalculateHashKey  (var aBoard : TBoard): THashKey;
procedure AdjustHashKey (var aHashKey : THashKey; aPieceType : Integer; aSquare : Integer);
procedure hashTable_Initialize (var aHashTable: THashTable);

const                       
  RANDOM_NUMBERS  : array [1..32, 1..4] of THashKey = (
    ($4C74F7D53CC32F2E, $C59C00027EB2779C, $EAA14A119FE7BA5A, $46758FC7BCAEEEE8),
    ($A1E2C0E08D5F40C6, $5D7ADFE34DF7EF74, $80F80149BFD22E72, $2AA6343F2A300540),
    ($C7AD9E458E302F5E, $1255E8DBCE9EFC4C, $4D9AA1815B5C2F8A, $25A899B7394DE098),
    ($131C46FD1C185AF6, $AB1922D03412FE24, $F8920AB94E321DA2, $635AA02F2CDDE0F0),
    ($D7D9A8B567EE238E, $66746DCBD74354FC, $7C0B1CF19EB458BA, $B51E27A793496648),
    ($3374A36DB0FBE926, $DA5BA9C3F57360D4, $F7D6B8299F7740D2, $3959101F8C0DD0A0),
    ($68E0172581800BBE, $E386B6BB7DBA81AC, $14E9BC61E0C335EA, $12F539975D3C7FF8),
    ($CBF2E3DD482CEB56, $A4F174B3FE841784, $F8DD0999F2149802, $30E0840F58FAD450),
    ($3CE7E995C1A8E7EE, $975BC3ABC30F825C, $C96D7FD1F39BC71A, $258CCF8713022DA8),
    ($33DE084D320E6186, $A8C983A370F02234, $BFFBFF09F7BD2332, $E06FFBFFE61FEC00),
    ($5C5820056E6BB81E, $6C02949BF58D570C, $CD0D674134910C4A, $8B83E977C9B56F58),
    ($C0BD10BDB6434BB6, $5812D693C3A280E4, $CBCA9879563E2602, $C6C677EF773817B0),
    ($85D7BA755D0B7C4E, $17CA298B60BEFFBC, $458072B1BC36057A, $8BB98767DFB14508),
    ($3656FD2D43AEA9E6, $E93C6D8342C63394, $C51FD5E9433BD592, $6EE2F7DFF13E5760),
    ($9E4DB8E5220B347E, $D41827BF0D6F7C6C, $BABDA221DE5DB2AA, $540CA957AC90AEB8),
    ($36B2CD9DA0737C16, $46F54873BFC63A44, $EF12B759DDCB7FCC, $2C047BCF8A6DAB10),
    ($20E11B55412DE0AE, $6B379F6B21A9CD1C, $86FBF591CA1B13DA, $5F9C4F47312EAC68),
    ($B217820D19F4C246, $2C676341400D94F4, $96FA3CC9308B57F2, $23AA03BF7A4112C0),
    ($8EF8E1C55D7680DE, $ECBB805B30B8F1CC, $46B26D01D9C1290A, $7A477937C7A63E18),
    ($570C1A7DB4D57C76, $3810CA53B34743A4, $846D6639A8E70022, $6B928FAFA9738E70),
    ($E03C0C356928150E, $D91C254B4B27EA7C, $48980871A2E2F23A, $9D2D2727D35263C8),
    ($25796EDC00F8AAA6, $96117143E9DE4654, $694333A9A243AA52, $F9BD1F9F62001E20),
    ($F2919AA5D5C59D3E, $F3E88E3BFEC1B72C, $FDA3C7E1B6536F6A, $686C591770CE1D78),
    ($2F00F75D15814CD6, $35DD5C33B27D9D04, $5192A5192DCEA182, $9468B38FFF21C1D0),
    ($FA208D15C412196E, $6CEFBB2BF69157DC, $690CAB518025A09A, $C4640F0725F46B28),
    ($664F3BCD28D26306, $97638B23C1D047B4, $13B2BA89AEFCCCB2, $C2144B7F9D537980),
    ($F14FE3853410899E, $D040AC1BAAE1CC8C, $9049B2C177AC85CA, $D1B348F791E04CD8),
    ($AFC9643D588EED36, $8ED2FE1325C14664, $C03A73F954C12BE2, $B97EE76FCA504530),
    ($8C69DF535003EDCE, $F62A610B113E153C, $EB11DE314F7B1EFA, $D93906E71CECC288),
    ($13670ADD99E00B66, $349AB503947B9914, $1200D169A14EBF12, $51A7875F351324E0),
    ($176BBC65156F45FE, $F33BD9FB4C7131EC, $D35C2DA125646C2A, $3C1448D7A8B4CC38),
    ($AE9D611D88165D96, $D569AFF3C96A3FC4, $DE1CD2D99A188642, $F1CD2B4F5DD71890)
  );

implementation

procedure AdjustHashKey (var aHashKey : THashKey; aPieceType : Integer; aSquare : Integer);
begin
  case aPieceType of
    RP_BLACKMAN   : aHashKey := aHashKey xor RANDOM_NUMBERS[aSquare, 1];
    RP_BLACKKING  : aHashKey := aHashKey xor RANDOM_NUMBERS[aSquare, 2];
    RP_WHITEMAN   : aHashKey := aHashKey xor RANDOM_NUMBERS[aSquare, 3];
    RP_WHITEKING  : aHashKey := aHashKey xor RANDOM_NUMBERS[aSquare, 4];
  else
    Assert(False, 'Unsupported piecetype');
  end;
end; // AdjustHashKey

function  CalculateHashKey  (var aBoard : TBoard): THashKey;
var
  i   : Integer;
begin
  result := 0;
  for i := Low(aBoard) to High(aBoard) do begin
    if aBoard[i] <> RP_FREE then begin
      AdjustHashKey (result, aBoard[i], i);
    end;
  end;
end; // CalculateHashKey

procedure hashTable_Create(var aHashTable : THashTable; aSize : Integer);
var
  pTable : PHashEntries;
begin
{ TODO : Eoutofresources afvangnen }
  GetMem(pTable, aSize);
  aHashTable.HashEntries  := pTable;
  aHashTable.NumEntries   := aSize div SizeOf(THashEntry);
end; // hashTable_Create

procedure hashTable_Free(var aHashTable : THashTable);
begin
  FreeMem(aHashTable.HashEntries);
  aHashTable.HashEntries  := nil;
  aHashTable.NumEntries   := 0;
end; // hashTable_Free

procedure hashTable_AddEntry(
  var aHashTable   : THashTable;
  var aKey         : THashKey;
      aDepth       : Integer;
      aColorToMove : Integer;
      aValueType   : TValueType;
      aValue       : Integer;
      aFromSquare  : Integer;
      aToSquare    : Integer
);
var
  entryIndex  : Cardinal;
begin
  entryIndex  := Cardinal(aKey) mod aHashTable.NumEntries;

  with aHashTable.HashEntries^[entryIndex] do begin
    if (aDepth >= Depth) then begin
      Key         := aKey;
      Depth       := aDepth;
      ColorToMove := aColorToMove;
      ValueType   := aValueType;
      Value       := aValue;
      FromSquare  := aFromSquare;
      ToSquare    := aToSquare;
    end;
  end;
end; // hashTable_AddEntry

function  hashTable_GetEntry(
  var aHashTable  : THashTable;
  var aHashKey    : THashKey
) : PHashEntry;
var
  entryIndex  : Cardinal;
begin
  entryIndex  := Cardinal(aHashKey) mod aHashTable.NumEntries;

  with aHashTable.HashEntries^[entryIndex] do begin
    if Key  = aHashKey then begin
      //aHashTable.HashEntries^[entryIndex].IsRecent := True;
      result := @(aHashTable.HashEntries^[entryIndex]);
    end
    else begin
      result := nil;
    end;
  end;
end; // hashTable_GetEntry

procedure hashTable_Initialize (var aHashTable: THashTable);
var
  i : Integer;
begin
  for i := 0 to aHashTable.NumEntries - 1 do begin
    aHashTable.HashEntries^[i].Depth := 0;
    //aHashTable.HashEntries^[i].IsRecent := False;
  end;
end; // hashTable_Initialize

end.


