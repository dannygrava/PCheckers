unit hash;

interface

uses
  structs, bool;

type
  THashsignature = record
    key   : int32;
    lock  : int32;
  end;

  THashentry = record
    lock: int32;
    value:Integer;
    depth:Integer;
    valuetype:Integer;
    best:Integer;
  end;

procedure positiontohashsignature(var p :TPosition; var h: THashsignature);
procedure hashstore(var p :TPosition; value, depth, alpha, beta, best: Integer);
function  hashretrieve(var p :TPosition; depth: Integer; var value: Integer; var alpha: Integer; var beta: Integer; var best: Integer): Integer;
procedure hashreset;

implementation

const
  HASHTABLESIZE = 1000000;

  UPPER = 0;
  LOWER = 1;
  EXACT = 2;

var
  //h :THashsignature;
  hashtable : array [0 ..HASHTABLESIZE-1] of THashentry;

procedure positiontohashsignature(var p :TPosition; var h: THashsignature);
begin
  // produce a hash signature from the position.
  h.key := p.bm xor p.bm shr 8 xor p.bm shr 16 xor p.bm shr 24;
  h.key := h.key xor (p.bk shr 1 xor p.bk shr 9 xor p.bk shr 17 xor p.bk shr 25);
  h.key := h.key xor (p.wm shr 2 xor p.wm shr 10 xor p.wm shr 18 xor p.wm shr 26);
  h.key := h.key xor (p.wk shr 3 xor p.wk shr 11 xor p.wk shr 19 xor p.wk shr 27);
  h.key := h.key xor (p.color shl 10);

  h.lock :=  p.bm xor p.bm shl 8 xor p.bm shr 16 xor p.bm shl 24;
  h.lock := h.lock xor (p.bk shr 1 xor p.bk shl 9 xor p.bk shr 17 xor p.bk shl 25);
  h.lock := h.lock xor (p.wm shr 2 xor p.wm shl 10 xor p.wm shr 18 xor p.wm shl 26);
  h.lock := h.lock xor (p.wk shr 3 xor p.wk shl 11 xor p.wk shr 19 xor p.wk shl 27);
  h.lock := h.lock xor (p.color shl 10);
end;

procedure hashstore(var p :TPosition; value, depth, alpha, beta, best: Integer);
var
  h: THashsignature;
  index : Integer;
begin
  // get a hash signature for this position;
  positiontohashsignature(p, h);
  // find index in table
  index := h.key mod HASHTABLESIZE;

  // save
  hashtable[index].best  := best;
  hashtable[index].depth := depth;
  hashtable[index].lock  := h.lock;
  hashtable[index].value := value;
  if (value <= alpha) then
  begin
    hashtable[index].valuetype := UPPER;
    Exit;
  end;

  if (value>= beta) then
  begin
    hashtable[index].valuetype := LOWER;
    Exit;
  end;
  hashtable[index].valuetype := EXACT;
end;

function hashretrieve(var p :TPosition; depth: Integer; var value: Integer; var alpha: Integer; var beta: Integer; var best: Integer): Integer;
var
  h: THashsignature;
  index : Integer;
begin
  // hashretrieve looks for a position in the hashtable.
  // if it finds it, it first checks if the entry causes an immediate cutoff.
  // if it does, hashretrieve returns 1, 0 otherwise.
  // if it does not cause a cutoff, hashretrieve tries to narrow the alpha-beta window
  // and sets the index of the best move to that stored in the table for move ordering.
  // get signature
  positiontohashsignature(p, h);

  // get index
  index := h.key mod HASHTABLESIZE;

  // check if it's the right position
  if (hashtable[index].lock <> h.lock) then
  begin
    // not right, return 0
    Result := 0;
    Exit;
  end;

  // check if depth this time round is higher
  if (depth>hashtable[index].depth) then
  begin
    // we are searching with a higher remaining depth than what is in the hashtable.
    // all we can do is set the best move for move ordering
    best := hashtable[index].best;
    Result := 0;
    Exit;
  end;

  // we have sufficient depth in the hashtable to possibly cause a cutoff.

  // if we have an exact value, we don't need to search for a new value.
  if (hashtable[index].valuetype = EXACT) then
  begin
    value := hashtable[index].value;
    Result := 1;
    Exit;
  end;

  // if we have a lower bound, we might either get a cutoff or raise alpha.
  if (hashtable[index].valuetype = LOWER) then
  begin
    // the value stored in the hashtable is a lower bound, so it's useful
    if (hashtable[index].value >= beta) then
    begin
      // value > beta: we can cutoff!
      value := hashtable[index].value;
      Result := 1;
      Exit;
    end;

    if (hashtable[index].value > alpha) then
      // value > alpha: we can adjust bounds
      alpha := hashtable[index].value;

    best := hashtable[index].best;
    Result := 0;
    Exit;
  end;

  // if we have an upper bound, we can either get a cutoff or lower beta.
  if (hashtable[index].value <= alpha) then
  begin
    value := hashtable[index].value;
    Result := 1;   
    Exit;
  end;

  if (hashtable[index].value < beta) then
    beta := hashtable[index].value;

  best := hashtable[index].best;
  Result := 0;
end;

procedure hashreset;
//var
//  i : Integer;
begin
  FillChar (hashtable, HASHTABLESIZE * SizeOf (THashentry) , 0);
//  for i := 0 to HASHTABLESIZE - 1 do
//  begin
//    hashtable [i].depth := 0;
//  end;
  //memset (hashtable,0,HASHTABLESIZE*sizeof(THashsignature));
end;

end.
