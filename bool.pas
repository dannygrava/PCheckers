unit bool;

interface

uses
  structs;

function bitcount(x:int32): Integer;
function LSB(x: int32): Integer;
  
implementation

var
  LSBarray   : array [0..255] of Byte;
  MSBarray   : array [0..255] of Byte;
  bitsinbyte : array [0..255] of Byte;

function recbitcount(n: int32): Integer;

  //  counts & returns the number of bits which are set in a 32-bit integer
  //  slower than a table-based bitcount if many bits are
  //  set. used to make the table for the table-based bitcount on initialization
var
  r :Integer;
begin
  r := 0;
  while (n <> 0) do
  begin
    n := n and (n-1);
    Inc (r);
  end;
  Result := r;
end;

function bitcount(x:int32): Integer;
//  table-lookup bitcount
//  returns the number of bits set in the 32-bit integer x
begin
  Result := (bitsinbyte[x and $FF] + bitsinbyte[(x shr 8)and  $FF] + bitsinbyte[(x shr 16) and  $FF] + bitsinbyte[(x shr 24)and  $FF]);
end;

function LSB(x: int32): Integer;
begin
  //-----------------------------------------------------------------------------------------------------
  // returns the position of the least significant bit in a 32-bit word x
  // or -1 if not found, if x=0.
  //-----------------------------------------------------------------------------------------------------
  if (x and  $000000FF <> 0) then
  begin
    Result :=(LSBarray[x and  $000000FF]);
    Exit;
  end;
  if (x and  $0000FF00 <> 0) then
  begin
    Result :=(LSBarray[(x shr 8) and  $000000FF]+8);
    Exit;
  end;
  if (x and  $00FF0000 <> 0) then
  begin
    Result :=(LSBarray[(x shr 16) and  $000000FF]+16);
    Exit;
  end;
  if (x and  $FF000000 <> 0) then
  begin
    Result :=(LSBarray[(x shr 24) and  $000000FF]+24);
    Exit;
  end;
  Result := -1;
end;

function MSB(x: int32): Integer;
begin
  //-----------------------------------------------------------------------------------------------------
  // returns the position of the most significant bit in a 32-bit word x
  // or -1 if not found, if x=0.
  //-----------------------------------------------------------------------------------------------------

  if (x and  $FF000000 <> 0) then
  begin
    Result :=(MSBarray[(x shr 24) and  $FF]+24);
    Exit;
  end;
  if (x and  $00FF0000 <> 0) then
  begin
    Result :=(MSBarray[(x shr 16) and  $FF]+16);
    Exit;
  end;
  if (x and  $0000FF00 <> 0) then
  begin
    Result :=(MSBarray[(x shr 8) and  $FF]+8);
    Exit;
  end;
  Result :=(MSBarray[x and  $FF]);
  //if x==0 return MSBarray[0], that's ok.
end;

procedure initbool;
var
  i,j: Integer;
begin
  // the boolean functions here are based on array lookups. initbool initializes these arrays.

  // init MSB
  for i := 0 to 255 do
  begin
    MSBarray[i] := 0;
    for j := 0 to 7 do
    begin
      if (i and (1 shl j)) <> 0 then
        MSBarray[i] := j;
    end;
  end;

  // init LSB
  for i := 0 to 255 do
  begin
    LSBarray[i] := 0;
    for j := 7 downto 0 do
    begin
      if (i and  (1 shl j)) <> 0 then
        LSBarray[i] := j;
    end;
  end;

  // init bitcount
  for i := 0 to 255 do begin
    bitsinbyte[i] := recbitcount(i);
  end;
end;

initialization
  initbool;
end.
