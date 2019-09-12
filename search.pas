unit search;

interface

uses
  structs;

function  compute(var p : TPosition; time: Integer; output: PChar): Integer;
procedure domove        (var p : TPosition; var m: TMove); forward;
procedure undomove      (var p : TPosition; var m: TMove); forward;

implementation

uses
  SysUtils, Math {DG: for Max-function},
  Constants, Eval, MoveGen, Hash, Bool, Time, stdio;

var
  realdepth : Integer;
  nodes : Integer;
  bestrootmove : TMove;

function  negamax       (var p : TPosition; depth: Integer; alpha, beta: Integer): Integer; forward;
//procedure domove        (var p : TPosition; var m: TMove); forward;
//procedure undomove      (var p : TPosition; var m: TMove); forward;
procedure retrievepv    (q : TPosition; pv: PChar); forward;
function  testcapture   (var p : TPosition): Integer; forward;
procedure movetonotation(var p : TPosition; var m: TMove; str: PChar); forward;

procedure movetonotation(var p : TPosition; var m: TMove; str: PChar);
const
  square: array [0..31] of Integer = (4,3,2,1,8,7,6,5,12,11,10,9,16,15,14,13,
    20,19,18,17,24,23,22,21,28,27,26,25,32,31,30,29
  ); (* maps bits to checkers notation *)
var
  from, _to : Int32;
  c : string;
 (*

       WHITE
        28  29  30  31           32  31  30  29
         24  25  26  27           28  27  26  25
           20  21  22  23           24  23  22  21
         16  17  18  19           20  19  18  17
           12  13  14  15           16  15  14  13
          8   9  10  11           12  11  10   9
            4   5   6   7            8   7   6   5
          0   1   2   3            4   3   2   1
              BLACK
*)
begin
   // make a notation out of a move
  if (p.color=COLOR_BLACK) then
  begin
    if (m.wk or m.wm) <> 0 then
      c := 'x'
    else
      c := '-'; (* capture or normal ? *)
    from := (m.bm or m.bk) and (p.bm or p.bk);    (* bit set on square from *)
    Assert (from <> 0, 'from = 0');
    _to :=  (m.bm or m.bk) and ( not (p.bm or p.bk));
    Assert (_to <> 0, '_to=0');
    from := LSB(from);
    _to := LSB(_to);
    from := square[from];
    _to := square[_to];
    //sprintf(str,'%2i%c%2i',from,c,_to);

    sprintf(str,'%2d%s%2d',[from,c,_to]);
    //StrCopy (str, PChar (Format ('%2d%s%2d',[from,c,_to])));
  end
  else
  begin
    if (m.bk or m.bm) <> 0 then
      c := 'x'
    else
      c := '-'; (* capture or normal ? *)

    from := (m.wm or m.wk) and  (p.wm or p.wk);    (* bit set on square from *)
    //Assert (from <> 0, 'from = 0');
    _to :=  (m.wm or m.wk) and  ( not (p.wm or p.wk));
    //Assert (_to <> 0, '_to=0');
    from := LSB(from);
    _to := LSB(_to);
    from := square[from];
    _to := square[_to];
    //sprintf(str,'%2i%c%2i',from,c,_to);
    sprintf(str,'%2d%s%2d',[from,c,_to]);
    //StrCopy (str, PChar (Format ('%2d%s%2d',[from,c,_to])));
  end;
end; // movetonotation

function compute(var p : TPosition; time: Integer; output: PChar): Integer;
var
  depth : Integer;
  value : Integer;
  dummy,alpha,beta :Integer;
  bestindex: Integer;
  n: Integer;
  t, elapsed: Double;
  movelist: array [0..MAXMOVES-1] of TMove;
  str: array [0..255] of Char;
  pv: array [0..255] of Char;
begin
  // compute searches the best move on position p in time time.
  // it uses iterative deepening to drive the negamax search.
  str [0] := #0;
  pv [0]  := #0;

  alpha := -MATE;
  beta  :=MATE;

  nodes := 0;
  realdepth := 0;

  hashreset();

  t := clock();

  StrCopy (output, 'publicake');

  for depth := 0 to MAXDEPTH - 1 do
  begin
    value := negamax(p, depth, -MATE, MATE);
    elapsed := (clock ()-t)/CLK_TCK;

    bestindex := 0;
    // get best move from hashtable:
    hashretrieve(p, MAXMOVES+1, dummy, alpha, beta, bestindex);
    // we always store in the last call to negamax, so there MUST be a move here!
    n := makecapturelist(p, movelist);
    if n=0 then
      n := makemovelist(p,movelist);

    movetonotation(p, movelist[bestindex],str);

    //sprintf(pv,"");
    //sprintf(output,"[thinking] [depth %i] [move %s] [time %.2f] [eval %i] [nodes %i]",depth,str,elapsed,value,nodes,pv);
    //printf("\n%s",output);

    pv [0] := #0;
    sprintf(output,'[thinking] [depth %d] [move %s] [time %.2f] [eval %d] [nodes %d]',[depth,string(str),elapsed,value,nodes,string(pv)]);
    //output := StrCopy (output, PChar (Format ('[thinking] [depth %d] [move %s] [time %.2f] [eval %d] [nodes %d]',[depth,string(str),elapsed,value,nodes,string(pv)])));

    // break conditions:
    // 1) time elapsed
    if (1000*elapsed > time) then
      break;

    // found a win or a loss
    if (abs(value)>MATE-MAXDEPTH-1) then
      break;

    // only one move todo!
    if (n=1) then begin
      value := 0;
      bestrootmove :=movelist[0];
      break;
    end;
  end; // for

  pv [0] := #0;
  retrievepv (p,pv);
  //sprintf(output,"[done] [depth %i] [move %s] [time %.2f] [eval %i] [nodes %i] [PV%s]",depth,str,elapsed,value,nodes,pv);
  //printf(''#10'%s',output);
  sprintf (output, '[done] [depth %d] [move %s] [time %.2f] [eval %d] [nodes %d] [PV%s]',[depth,string(str),elapsed,value,nodes,string(pv)]);
  //output := StrCopy (output, PChar (Format ('[done] [depth %d] [move %s] [time %.2f] [eval %d] [nodes %d] [PV%s]',[depth,string(str),elapsed,value,nodes,string(pv)])));
  domove(p, bestrootmove);

  Result := value;
end; // compute

procedure retrievepv(q : TPosition; pv: PChar);
// get a pv string:
var
  bestindex,n: Integer;
  movelist: array [0..MAXMOVES-1] of TMove;
  dummy, alpha, beta : Integer;
  pvmove : array [0 ..255] of Char;
  count :Integer;
begin
  // gets the pv from the hashtable
  // get a pv string:
  count := 0;

  bestindex := -1;
  hashretrieve(q, MAXDEPTH+1, dummy, alpha, beta, bestindex);
  pv [0] := #0;
  while (bestindex <> -1) and (count<10) do
  begin
    // we always store in the last call to negamax, so there MUST be a move here!
    n := makecapturelist(q, movelist);
    if n=0 then
      makemovelist(q,movelist);//n := makemovelist(q,movelist);
    movetonotation(q, movelist[bestindex],pvmove);
    domove(q, movelist[bestindex]);

    // look up next move
    bestindex := -1;
    hashretrieve(q, MAXMOVES+1, dummy, alpha, beta, bestindex);
    pv := StrCat(pv,' ');
    pv := StrCat(pv,pvmove);
    Inc (count);
  end;
end; // retrievepv

function negamax(var p : TPosition; depth: Integer; alpha, beta: Integer): Integer;
(*----------------------------------------------------------------------------
|                                                                                                                                                         |
|               negamax: the basic recursion routine of PubliCake                                         |
|                                       returns the negamax value of the current position                 |
|                                                                                                                                                         |
 ----------------------------------------------------------------------------*)
var
  value : Integer;
  localalpha, localbeta  : Integer;
  maxvalue : Integer;

  i,j,index,n : Integer;
  bestordervalue : Integer;
  bestindex : Integer;    // index of the move with the highest value
  capture : Integer;              // is there a capture for the side to move?
  movelist : array [0..MAXMOVES-1] of TMove;
  ordervalues: array [0..MAXMOVES-1] of Integer;
begin
  localalpha := alpha;
  localbeta := beta;
  maxvalue := -MATE;

  bestindex := 0;       // index of the move with the highest value

  Inc (nodes);

  // check material: if one side has nothing left, return a win for the other side!
  if (p.bm + p.bk = 0) then
  begin
    if p.color=COLOR_BLACK then
    begin
      Result := (-MATE+realdepth);
      Exit;
    end
    else
    begin
      Result := (MATE-realdepth);
      Exit;
    end;
  end;

  if (p.wm + p.wk = 0) then
  begin
    if  p.color=COLOR_WHITE then
    begin
      Result := -MATE+realdepth
    end
    else
    begin
      Result := MATE+realdepth;
    end;
    Exit;
  end;

  // stop search if maximal search depth is reached
  if (realdepth>MAXDEPTH) then
  begin
    Result := evaluation(p);
    Exit;
  end;

  // todo: hashlookup here
  if (hashretrieve(p, depth, value, alpha, beta, bestindex)) <> 0 then
  begin
    // this position was in the table, and the value & depth stored make it possible to cutoff.
    Result := value;
    Exit;
  end;

  // todo: repcheck here

  // todo: dblookup here

  // check if the side to move has a capture:
  capture := testcapture(p);

  // now, check return condition - never evaluate with a capture on board!
  if ((depth<= 0) and (capture = 0)) then
  begin
    Result := evaluation(p);
    Exit;
  end;

  if (capture <>0) then
    n := makecapturelist(p,movelist)
  else
    n := makemovelist(p,movelist);

  // if we have no move:
  if (n=0) then
  begin
    Result := -MATE+realdepth;
    Exit;
  end;

  // order movelist by filling values into the array "ordervalues".
  // moves with high ordervalues will be looked at first.
  // at the moment, only the hashmove is used.
  for i := 0 to n - 1 do
  begin
    ordervalues[i] := 0;
  end;

  if (bestindex <> 0) then
    ordervalues[bestindex] := 1;

  for i := 0 to n - 1 do
  begin
    // get index we want to look at by doing a linear search
    // through the ordervalues array. look at the move with
    // the highest value. set it's ordervalue to -MATE to
    // prevent it from being looked at again.
    bestordervalue := -MATE;
    for j := 0 to n - 1 do
    begin
      if (ordervalues[j]>bestordervalue) then
      begin
        index := j;
        bestordervalue :=ordervalues[j];
      end;
    end;

    ordervalues[index] := -MATE;

    // domove
    domove(p, movelist[index]);

    // recursion
    value := -negamax(p,depth-1,-beta,-localalpha);

    // undo move
    undomove(p, movelist[index]);

    // update best value so far
    maxvalue := max(value,maxvalue);
//    if value > maxvalue then
//      maxvalue := value;

    // and set alpha and beta bounds
    if (maxvalue>= localbeta) then
    begin
      bestindex := index;
      break;
    end;

    if (maxvalue>localalpha) then
    begin
      localalpha := maxvalue;
      bestindex := index;
    end;
  end; // end main recursive loop of forallmoves

  // todo: save position in hashtable
  hashstore(p, maxvalue, depth, alpha, beta, bestindex);

  // todo: set a killer move

  if (realdepth=0) then
    bestrootmove := movelist[bestindex];

  Result := maxvalue;
end; // negamax


procedure domove(var p : TPosition; var m: TMove);
begin
  p.bm := p.bm xor m.bm;
  p.bk := p.bk xor m.bk;
  p.wm := p.wm xor m.wm;
  p.wk := p.wk xor m.wk;
  p.color := p.color xor 1;
  Inc (realdepth);
end; // domove

procedure undomove(var p : TPosition; var m: TMove);
begin
  p.bm:= p.bm xor m.bm;
  p.bk:= p.bk xor m.bk;
  p.wm:= p.wm xor m.wm;
  p.wk:= p.wk xor m.wk;
  p.color:= p.color xor 1;
  Dec (realdepth)
end; // undomove

function testcapture(var p : TPosition): Integer;
var
  black,white,free,m : int32;
begin
  // testcapture returns 1 if there is a capture for the side to move in p
  if (p.color=COLOR_BLACK) then
  begin
    black :=p.bm or p.bk;
    white := p.wm or p.wk;
    free := not (black or white);

    m := ((((black and  LFJ2) shl 4) and  white) shl 3);
    m := m or ((((black and  LFJ1) shl 3)  and white) shl 4);
    m := m or  ((((black and  RFJ1) shl 4) and  white) shl 5);
    m := m or  ((((black and  RFJ2) shl 5) and  white) shl 4);
    if (p.bk <>0) then
    begin
      m := m or ((((p.bk and  LBJ1) shr 5) and  white) shr 4);
      m := m or ((((p.bk and LBJ2) shr 4) and  white) shr 5);
      m := m or ((((p.bk and  RBJ1) shr 4)and  white) shr 3);
      m := m or ((((p.bk and RBJ2) shr 3) and  white) shr 4);
    end;

    if (m and  free)<>0 then
    begin
      Result := 1;
      Exit;
    end;

    Result := 0;
    Exit;
  end
  else
  begin
    black := p.bm or p.bk;
    white := p.wm or p.wk;
    free := not (black or white);
    m := ((((white and  LBJ1) shr 5) and  black) shr 4);
    m := m or ((((white  and  LBJ2) shr 4)and  black) shr 5);
    m := m or  ((((white and  RBJ1) shr 4) and  black) shr 3);
    m := m or  ((((white and  RBJ2) shr 3) and  black) shr 4);

    if (p.wk)<>0 then
    begin
      m := m or  ((((p.wk and  LFJ2) shl 4) and  black) shl 3);
      m := m or  ((((p.wk and LFJ1) shl 3)  and  black) shl 4);
      m := m or  ((((p.wk and  RFJ1) shl 4) and  black) shl 5);
      m := m or ((((p.wk  and  RFJ2) shl 5) and  black) shl 4);
    end;

    if (m and  free)<> 0 then
    begin
      Result := 1;
      Exit;
    end;
    Result := 0;
    Exit;
  end;
end; // testcapture

end.
