unit movegen;
{
  Noot 1. over conversie C to Pascal:

  if (m) --> if m <> 0
  if (!m) --> if m = 0
  ^ --> xor
  ! --> (logical) not
  & --> and of als deref in functie calls dan verwijderen
  ~ --> (bitwise) not

  Noot 2.

  Precedence of operators (Pascal)
  ================================
  Operators                           Precedence
  @, not                              first (highest)
  *, /, div, mod, and, shl, shr, as   second
  +, -, or, xor                       third
  =, <>, <, >, <=, >=, in, is         fourth (lowest)



  Operator Precedence Chart (C)
  =============================

  Primary Expression Operators
  ----------------------------
  () [] . -> expr++ expr--
  Unary Operators
  * & + - ! ~ ++expr --expr (typecast) sizeof()
  Binary Operators
  * / %
  + -
  >> <<
  < > <= >=
  == !=
  &
  ^
  |
  &&
  ||

  Ternary Operator
  ----------------
  ?:

  Assignment Operators
  --------------------
  = += -= *= /= %= >>= <<= &= ^= |=
  Comma
  -----
  ,
}
interface
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}
 // vanwege m := -m
uses
  structs, constants;

function makecapturelist(var p : TPosition; var movelist: array of TMove): Integer;
function makemovelist(var p : TPosition; var movelist: array of TMove) : Integer;
(*
     WHITE
  28  29  30  31
   24  25  26  27
     20  21  22  23
   16  17  18  19
     12  13  14  15
    8   9  10  11
    4  5  6  7
    0   1   2   3
      BLACK
*)

implementation

procedure blackmancapture1 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure blackmancapture2 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure blackkingcapture1(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure blackkingcapture2(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure whitemancapture1 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure whitemancapture2 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure whitekingcapture1(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;
procedure whitekingcapture2(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32); forward;


function makemovelist(var p : TPosition; var movelist: array of TMove) : Integer;
var
  n, free : Int32;
  m,tmp : Int32;
begin
  n :=0;
  free := not(p.bm or p.bk or p.wm or p.wk);
  if (p.color=COLOR_BLACK) then
  begin
    if (p.bk <> 0) then
    begin
      // moves left forward
      // I: columns 1357
      m := ((p.bk and LF1) shl 3) and free;
      //now m contains a bit for every free square where a black king can move
      while(m <> 0) do
      begin
        tmp := (m and -m); // least significant bit of m
        tmp := tmp or (tmp shr 3);
        movelist[n].bm := 0;
        movelist[n].bk := tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);   // clears least significant bit of m
      end;
      // II: columns 2468
      m := ((p.bk and LF2) shl 4) and free;
      while (m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 4);
        movelist[n].bm := 0;
        movelist[n].bk :=tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
      //moves right forwards
      // I: columns 1357 */
      m := ((p.bk and RF1) shl 4) and free;
      while (m <> 0) do
      begin
        tmp := (m and -m);
        tmp :=tmp or (tmp shr 4);
        movelist[n].bm := 0;
        movelist[n].bk := tmp;
        movelist[n].wm := 0;
        movelist[n].wk :=0;
        Inc (n);
        m := m and (m-1);
      end;
      // II: columns 2468
      m := ((p.bk and RF2) shl 5) and free;
      while (m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 5);
        movelist[n].bm := 0;
        movelist[n].bk := tmp;
        movelist[n].wm :=0;
        movelist[n].wk := 0;
        Inc (n);
        m :=m and (m-1);
      end;
      // moves left backwards
      // I: columns 1357
      m := ((p.bk and LB1) shr 5) and free;
      // now m contains a bit for every free square where a black man can move*/
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        tmp := tmp or (tmp shl 5);
        movelist[n].bm := 0;
        movelist[n].bk :=tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      // II: columns 2468 */
      m := ((p.bk and LB2) shr 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk := tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
      (* moves right backwards *)
      (* I: columns 1357 *)
      m := ((p.bk and RB1) shr 4) and free;
      while(m <> 0) do
      begin
        tmp :=(m and -m);
        tmp := tmp or (tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk :=tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
      (* II: columns 2468 *)
      m := ((p.bk and RB2) shr 3) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shl 3);
        movelist[n].bm := 0;
        movelist[n].bk := tmp;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
    end;
    (* moves with black stones:*)
    if (p.bm <> 0) then
    begin
       (* moves left forwards *)
      (* I: columns 1357: just moves *)
      m :=((p.bm and LF1) shl 3) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp :=(m and -m); (* least significant bit of m *)
        tmp := tmp or (tmp shr 3); (* square where man came from *)
        movelist[n].bm := tmp and NWBR; (* NWBR: not white back rank *)
        movelist[n].bk := tmp and WBR; (*if stone moves to WBR (white back rank) it's a king*)
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);   (* clears least significant bit of m *)
      end;

      (* II: columns 2468 *)
      m := ((p.bm and LF2) shl 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 4);
        movelist[n].bm := tmp;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
      (* moves right forwards *)
      (* I: columns 1357 :just moves*)
      m := ((p.bm and RF1) shl 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 4);
        movelist[n].bm := tmp and NWBR;
        movelist[n].bk := tmp and WBR;
        movelist[n].wm :=0;
        movelist[n].wk := 0;
        Inc (n);
        m :=m and (m-1);
      end;

      (* II: columns 2468 *)
      m := ((p.bm and RF2) shl 5) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 5);
        movelist[n].bm := tmp;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
    end;
    result := n;
    Exit;
  end
  //* ****************************************************************)
  else   (* color is WHITE *)
  (******************************************************************)
  begin
    (* moves with white kings:*)
    if (p.wk <> 0) then
    begin
      (* moves left forwards *)
      (* I: columns 1357 *)
      m := ((p.wk and LF1) shl 3) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        tmp := tmp or (tmp shr 3);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm :=0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* II: columns 2468 *)
      m := ((p.wk and LF2) shl 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp :=tmp or(tmp shr 4);
        movelist[n].bm := 0;
        movelist[n].bk :=0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);
      end;
      (* moves right forwards *)
      (* I: columns 1357 *)
      m :=((p.wk and RF1) shl 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or(tmp shr 4);
        movelist[n].bm :=0;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);
      end;
      (* II: columns 2468 *)
      m :=((p.wk and RF2) shl 5) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shr 5);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);
      end;

      (* moves left backwards *)
      (* I: columns 1357 *)
      m :=((p.wk and LB1) shr 5) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        tmp := tmp or (tmp shl 5);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* II: columns 2468 *)
      m := ((p.wk and LB2) shr 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);
      end;

      (* moves right backwards *)
      (* I: columns 1357 *)
      m := ((p.wk and RB1) shr 4) and free;
      while(m <> 0) do
      begin
        tmp :=(m and -m);
        tmp := tmp or(tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := 0;
        movelist[n].wk := tmp;
        Inc (n);
        m :=m and (m-1);
      end;
      (* II: columns 2468 *)
      m :=((p.wk and RB2) shr 3) and free;
      while(m <> 0) do
      begin
        tmp :=(m and -m);
        tmp := tmp or (tmp shl 3);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm :=0;
        movelist[n].wk := tmp;
        Inc (n);
        m := m and (m-1);
      end;
    end;

    (* moves with white stones:*)
    if (p.wm <> 0) then
    begin
      (* moves left backwards *)
      (* II: columns 2468 ;just moves*)
      m := ((p.wm and LB2) shr 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk :=0;
        movelist[n].wm := tmp and NBBR;
        movelist[n].wk :=tmp and BBR;
        Inc (n);
        m := m and (m-1);
      end;
      (* I: columns 1357 *)
      m := ((p.wm and LB1) shr 5) and free;
      (* now m contains a bit for every free square where a white man can move*)
      while(m <> 0) do
      begin
        tmp :=(m and -m); (* least significant bit of m *)
        tmp :=tmp or (tmp shl 5);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm :=tmp;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);   (* clears least significant bit of m *)
      end;

      (* moves right backwards *)

      (* II: columns 2468 : just the moves*)
      m := ((p.wm and RB2) shr 3) and free;
      while(m <> 0) do
      begin
        tmp :=(m and -m);
        tmp := tmp or (tmp shl 3);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := tmp and NBBR;
        movelist[n].wk := tmp and BBR;
        Inc (n);
        m := m and (m-1);
      end;
      (* I: columns 1357 *)
      m := ((p.wm and RB1) shr 4) and free;
      while(m <> 0) do
      begin
        tmp := (m and -m);
        tmp := tmp or (tmp shl 4);
        movelist[n].bm := 0;
        movelist[n].bk := 0;
        movelist[n].wm := tmp;
        movelist[n].wk := 0;
        Inc (n);
        m := m and (m-1);
      end;
    end;
    Result := n;
    Exit;
  end;
end;


(******************************************************************************)
(* capture list *)
(******************************************************************************)

(* generates the capture moves *)


function makecapturelist(var p : TPosition; var movelist: array of TMove): Integer;
var
  free,free2,m,tmp,white,black,white2,black2: int32;
  n : Integer;
  partial: TMove;
  q: TPosition;
begin
  n := 0;

(*
     WHITE
  28  29  30  31
   24  25  26  27
     20  21  22  23
   16  17  18  19
     12  13  14  15
    8   9  10  11
    4  5  6  7
    0   1   2   3
      BLACK
*)

  free :=not(p.bm or p.bk or p.wm or p.wk);
  if (p.color=COLOR_BLACK) then
  begin
    if(p.bm<>0) then
    begin
      (* captures with black men! *)
      white := p.wm or p.wk;
      (* jumps left forwards with men*)
      m := ((((p.bm and LFJ2) shl 4) and white) shl 3) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        (* find a move *)
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := (tmp or (tmp shr 7)) and NWBR;  (* NWBR: not white back rank *)
        partial.bk := (tmp or (tmp shr 7)) and WBR;  (*if stone moves to WBR (white back rank) it's a king*)
        partial.wm := (tmp shr 3) and p.wm;
        partial.wk := (tmp shr 3) and p.wk;
        (* toggle it *)
        q.bm :=p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        (* recursion *)
        (* only if black has another capture move! *)
        white2 :=p.wm or p.wk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( (((((tmp and LFJ2) shl 4) and white2) shl 3) and free2) or (((((tmp and RFJ2) shl 5) and white2) shl 4) and free2)) <> 0 then
          blackmancapture2(q, movelist, n, partial, tmp)
        else
        begin
          (* save move *)
          movelist[n] := partial;
          Inc (n);
        end;

        (* clears least significant bit of m, associated with that move. *)
        m := m and (m-1);
      end;
      m := ((((p.bm and LFJ1) shl 3) and white) shl 4) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp :=(m and -m); (* least significant bit of m *)
        partial.bm :=(tmp or (tmp shr 7));
        partial.bk := 0;
        partial.wm := (tmp shr 4) and p.wm;
        partial.wk := (tmp shr 4) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        white2 := p.wm or p.wk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LFJ1) shl 3) and white2) shl 4) and free2 ) or ( ((((tmp and RFJ1) shl 4) and white2) shl 5) and free2 )) <> 0 then
          blackmancapture1 (q, movelist, n, partial, tmp)
        else
        begin
          (* save move *)
          movelist[n] := partial;
          Inc (n);
        end;
        m :=m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right forwards with men*)
      m := ((((p.bm and RFJ2) shl 5) and white) shl 4) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm :=(tmp or (tmp shr 9)) and NWBR;
        partial.bk := (tmp or (tmp shr 9)) and WBR;
        partial.wm := (tmp shr 4) and p.wm;
        partial.wk := (tmp shr 4) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk :=p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        white2 := p.wm or p.wk;
        free2 :=not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LFJ2) shl 4) and white2) shl 3) and free2 ) or ( ((((tmp and RFJ2) shl 5) and white2) shl 4) and free2 )) <>  0 then
          blackmancapture2(q,movelist, n,  partial,tmp)
        else
        begin
          (* save move *)

          movelist[n] := partial;
          Inc (n);
        end;

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.bm and RFJ1) shl 4) and white) shl 5) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := tmp or(tmp shr 9);
        partial.bk := 0;
        partial.wm := (tmp shr 5) and p.wm;
        partial.wk := (tmp shr 5) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;


        white2 := p.wm or p.wk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LFJ1) shl 3) and white2) shl 4) and free2 ) or ( ((((tmp and RFJ1) shl 4) and white2) shl 5) and free2 )) <> 0 then
          blackmancapture1(q,movelist,n,partial,tmp)
        else
        begin
          (* save move *)

          movelist[n] := partial;
          Inc (n);
        end;
        m := m and (m-1);   (* clears least significant bit of m *)
      end;
    end;
    if (p.bk <> 0) then
    begin
      white := p.wm or p.wk;
      (* jumps left forwards with black kings*)
      m := ((((p.bk and LFJ1) shl 3) and white) shl 4) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm :=0;
        partial.bk := (tmp or (tmp shr 7));
        partial.wm := (tmp shr 4) and p.wm;
        partial.wk := (tmp shr 4) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.bk and LFJ2) shl 4) and white) shl 3) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk := (tmp or(tmp shr 7));
        partial.wm := (tmp shr 3) and p.wm;
        partial.wk := (tmp shr 3) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture2( q,movelist, n,  partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right forwards with black kings*)
      m := ((((p.bk and RFJ1) shl 4) and white) shl 5) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk := tmp or (tmp shr 9);
        partial.wm :=(tmp shr 5) and p.wm;
        partial.wk := (tmp shr 5) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture1(q,movelist, n,  partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.bk and RFJ2) shl 5) and white) shl 4) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk := (tmp or (tmp shr 9));
        partial.wm := (tmp shr 4) and p.wm;
        partial.wk := (tmp shr 4) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture2(q,movelist,  n,  partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;

      (* jumps left backwards with black kings*)
      m := ((((p.bk and LBJ1) shr 5) and white) shr 4) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk := (tmp or(tmp shl 9));
        partial.wm :=(tmp shl 4) and p.wm;
        partial.wk := (tmp shl 4) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk :=p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.bk and LBJ2) shr 4) and white) shr 5) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm :=0;
        partial.bk := (tmp or (tmp shl 9));
        partial.wm := (tmp shl 5) and p.wm;
        partial.wk := (tmp shl 5) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;

        blackkingcapture2(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right backwards with black kings*)
      m := ((((p.bk and RBJ1) shr 4) and white) shr 3) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk := tmp or (tmp shl 7);
        partial.wm := (tmp shl 3) and p.wm;
        partial.wk := (tmp shl 3) and p.wk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk :=p.wk xor partial.wk;

        blackkingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m :=((((p.bk and RBJ2) shr 3) and white) shr 4) and free;
      (* now m contains a bit for every free square where a black king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.bm := 0;
        partial.bk :=(tmp or (tmp shl 7));
        partial.wm := (tmp shl 4) and p.wm;
        partial.wk := (tmp shl 4) and p.wk;

        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        blackkingcapture2(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
    end;

    Result := n;
    Exit;
  end
  else (*******************COLOR IS WHITE *********************************)
  begin
    if (p.wm <> 0) then
    begin
      black := p.bm or p.bk;
      (* jumps left backwards with men*)
      m := ((((p.wm and LBJ1) shr 5) and black) shr 4) and free;
      (* now m contains a bit for every free square where a white man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := (tmp or (tmp shl 9)) and NBBR;
        partial.wk := (tmp or (tmp shl 9)) and BBR;
        partial.bm := (tmp shl 4) and p.bm;
        partial.bk := (tmp shl 4) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        (* only if white has another capture move! *)
        black2 := p.bm or p.bk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LBJ1) shr 5) and black2) shr 4) and free2) or ( ((((tmp and RBJ1) shr 4) and black2) shr 3) and free2 )) <> 0 then
          whitemancapture1(q,movelist, n, partial,tmp)
        else
        begin
          (* save move *)
          movelist[n] := partial;
          Inc (n);
        end;


        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wm and LBJ2) shr 4) and black) shr 5) and free;
      (* now m contains a bit for every free square where a white man can move*)
      while(m <> 0) do
      begin
        tmp :=(m and -m); (* least significant bit of m *)
        partial.wm :=(tmp or (tmp shl 9));
        partial.wk := 0;
        partial.bm := (tmp shl 5) and p.bm;
        partial.bk := (tmp shl 5) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        black2 := p.bm or p.bk;
        free2 :=not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LBJ2) shr 4) and black2) shr 5) and free2) or ( ((((tmp and RBJ2) shr 3) and black2) shr 4) and free2 )) <> 0 then
          whitemancapture2(q,movelist,n, partial,tmp)
        else
        begin
          // save move
          movelist[n] := partial;
          Inc (n);
        end;


        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right backwards with men*)
      m := ((((p.wm and RBJ1) shr 4) and black) shr 3) and free;
      (* now m contains a bit for every free square where a white man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := (tmp or (tmp shl 7)) and NBBR;
        partial.wk := (tmp or (tmp shl 7)) and BBR;
        partial.bm := (tmp shl 3) and p.bm;
        partial.bk := (tmp shl 3) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        black2 :=p.bm or p.bk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LBJ1) shr 5) and black2) shr 4) and free2) or ( ((((tmp and RBJ1) shr 4) and black2) shr 3) and free2 )) <> 0 then
          whitemancapture1(q,movelist, n, partial,tmp)
        else
        begin
          // save move
          movelist[n] :=partial;
          Inc (n);
        end;

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wm and RBJ2) shr 3) and black) shr 4) and free;
      (* now m contains a bit for every free square where a black man can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := (tmp or (tmp shl 7));
        partial.wk := 0;
        partial.bm :=(tmp shl 4) and p.bm;
        partial.bk := (tmp shl 4) and p.bk;
        q.bm :=p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        black2 := p.bm or p.bk;
        free2 := not(p.wm or p.wk or p.bm or p.bk);
        if ( ( ((((tmp and LBJ2) shr 4) and black2) shr 5) and free2) or ( ((((tmp and RBJ2) shr 3) and black2) shr 4) and free2 )) <> 0 then
          whitemancapture2(q,movelist,n, partial,tmp)
        else
        begin
          (* save move *)
          movelist[n] := partial;
          Inc (n);
        end;

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
    end;
    if(p.wk <> 0) then
    begin
      black := p.bm or p.bk;
      (* jumps left forwards with white kings*)
      m := ((((p.wk and LFJ1) shl 3) and black) shl 4) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := (tmp or (tmp shr 7));
        partial.bm := (tmp shr 4) and p.bm;
        partial.bk := (tmp shr 4) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wk and LFJ2) shl 4) and black) shl 3) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := (tmp or (tmp shr 7));
        partial.bm :=(tmp shr 3) and p.bm;
        partial.bk := (tmp shr 3) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk :=p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture2(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right forwards with white kings*)
      m := ((((p.wk and RFJ1) shl 4) and black) shl 5) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := tmp or (tmp shr 9);
        partial.bm := (tmp shr 5) and p.bm;
        partial.bk := (tmp shr 5) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture1(q,movelist,n,partial,tmp);

        m :=m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wk and RFJ2) shl 5) and black) shl 4) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := (tmp or (tmp shr 9));
        partial.bm :=(tmp shr 4) and p.bm;
        partial.bk :=(tmp shr 4) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture2(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;


      (* jumps left backwards with white kings*)
      m := ((((p.wk and LBJ1) shr 5) and black) shr 4) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk :=(tmp or (tmp shl 9));
        partial.bm := (tmp shl 4) and p.bm;
        partial.bk := (tmp shl 4) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wk and LBJ2) shr 4) and black) shr 5) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := (tmp or (tmp shl 9));
        partial.bm := (tmp shl 5) and p.bm;
        partial.bk := (tmp shl 5) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture2(q,movelist,n,partial,tmp);

        m :=m and (m-1);   (* clears least significant bit of m *)
      end;
      (* jumps right backwards with white kings*)
      m := ((((p.wk and RBJ1) shr 4) and black) shr 3) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp :=(m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := tmp or (tmp shl 7);
        partial.bm := (tmp shl 3) and p.bm;
        partial.bk := (tmp shl 3) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk :=p.wk xor partial.wk;
        whitekingcapture1(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
      m := ((((p.wk and RBJ2) shr 3) and black) shr 4) and free;
      (* now m contains a bit for every free square where a white king can move*)
      while(m <> 0) do
      begin
        tmp := (m and -m); (* least significant bit of m *)
        partial.wm := 0;
        partial.wk := (tmp or (tmp shl 7));
        partial.bm := (tmp shl 4) and p.bm;
        partial.bk := (tmp shl 4) and p.bk;
        q.bm := p.bm xor partial.bm;
        q.bk := p.bk xor partial.bk;
        q.wm := p.wm xor partial.wm;
        q.wk := p.wk xor partial.wk;
        whitekingcapture2(q,movelist,n,partial,tmp);

        m := m and (m-1);   (* clears least significant bit of m *)
      end;
    end;

    Result := n;
    Exit;
  end;
end;

procedure blackmancapture1(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var

  m,free,white : int32;
  found : Integer ;
  next_partial,whole_partial: TMove ;
  q: TPosition ;
begin
  (* partial move has already been executed. seek LFJ1 and RFJ1 *)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  white := p.wm or p.wk;
  (* left forward jump *)
  m := ((((square and LFJ1) shl 3) and white) shl 4) and free;
  if(m <> 0) then
  begin
    next_partial.bm := (m or (m shr 7));
    next_partial.bk := 0;
    next_partial.wm := (m shr 4) and p.wm;
    next_partial.wk := (m shr 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;
    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackmancapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ1) shl 4) and white) shl 5) and free;
  if (m <> 0) then
  begin
    next_partial.bm := (m or (m shr 9));
    next_partial.bk := 0;
    next_partial.wm := (m shr 5) and p.wm;
    next_partial.wk := (m shr 5) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm :=p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackmancapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if(found =0) then
  begin
    // no continuing jumps - save the move in the movelist
    movelist[n] := partial;
    Inc (n);
  end;
end;

procedure blackmancapture2(var p : TPosition; var movelist : array of TMove; var n: Integer; var partial: TMove;square : Int32);
var
  m,free,white : int32;
  next_partial,whole_partial: TMove;
  found :Integer ;
  q:TPosition;
begin
  (* partial move has already been executed. seek LFJ2 and RFJ2 *)
  (* additional complication: black stone might crown here *)
  found := 0;

  free :=not(p.bm or p.bk or p.wm or p.wk);
  white := p.wm or p.wk;
  (* left forward jump *)
  m :=((((square and LFJ2) shl 4) and white) shl 3) and free;
  if (m <> 0) then
  begin
    next_partial.bm := (m or (m shr 7)) and NWBR;
    next_partial.bk := (m or (m shr 7)) and WBR;
    next_partial.wm := (m shr 3) and p.wm;
    next_partial.wk := (m shr 3) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackmancapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ2) shl 5) and white) shl 4) and free;
  if (m <> 0) then
  begin
    next_partial.bm := (m or (m shr 9)) and NWBR;
    next_partial.bk := (m or (m shr 9)) and WBR;
    next_partial.wm := (m shr 4) and p.wm;
    next_partial.wk :=(m shr 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackmancapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if ( found = 0) then
  begin
    (* no continuing jumps - save the move in the movelist *)

    movelist[n] :=partial;
    Inc (n);
  end;
end;


procedure blackkingcapture1(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,white: int32;
  next_partial,whole_partial: TMove;
  found : Integer;
  q: TPosition;

begin
  (* partial move has already been executed. seek LFJ1 RFJ1 LBJ1 RBJ1*)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  white := p.wm or p.wk;
  (* left forward jump *)
  m :=((((square and LFJ1) shl 3) and white) shl 4) and free;
  if (m <> 0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or (m shr 7));
    next_partial.wm := (m shr 4) and p.wm;
    next_partial.wk := (m shr 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ1) shl 4) and white) shl 5) and free;
  if (m <> 0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or (m shr 9));
    next_partial.wm :=(m shr 5) and p.wm;
    next_partial.wk := (m shr 5) and p.wk;
    q.bm :=p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm :=p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture1(q,movelist,n,whole_partial,m);

    found := 1;
  end;

  (* left backward jump *)
  m := ((((square and LBJ1) shr 5) and white) shr 4) and free;
  if (m <> 0) then
  begin
    next_partial.bm := 0;
    next_partial.bk :=(m or (m shl 9));
    next_partial.wm := (m shl 4) and p.wm;
    next_partial.wk := (m shl 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)
  m := ((((square and RBJ1) shr 4) and white) shr 3) and free;
  if (m<>0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or(m shl 7));
    next_partial.wm := (m shl 3) and p.wm;
    next_partial.wk := (m shl 3) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if (found = 0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
    movelist[n] := partial;
    Inc(n);
  end;
end;

procedure blackkingcapture2(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,white: int32;
  next_partial,whole_partial: TMove;
  found :Integer;
  q:TPosition;

begin
  (* partial move has already been executed. seek LFJ1 RFJ1 LBJ1 RBJ1*)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  white :=p.wm or p.wk;
  (* left forward jump *)
  m := ((((square and LFJ2) shl 4) and white) shl 3) and free;
  if (m<>0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or (m shr 7));
    next_partial.wm := (m shr 3) and p.wm;
    next_partial.wk := (m shr 3) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk :=partial.wk xor next_partial.wk;
    blackkingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ2) shl 5) and white) shl 4) and free;
  if (m<>0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or (m shr 9));
    next_partial.wm := (m shr 4) and p.wm;
    next_partial.wk := (m shr 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* left backward jump *)
  m := ((((square and LBJ2) shr 4) and white) shr 5) and free;
  if (m<>0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or (m shl 9));
    next_partial.wm := (m shl 5) and p.wm;
    next_partial.wk := (m shl 5) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)

  m := ((((square and RBJ2) shr 3) and white) shr 4) and free;
  if (m<>0) then
  begin
    next_partial.bm := 0;
    next_partial.bk := (m or(m shl 7));
    next_partial.wm := (m shl 4) and p.wm;
    next_partial.wk :=(m shl 4) and p.wk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    blackkingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if(found =0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
    movelist[n] := partial;
    Inc(n);
  end;
end;

procedure whitemancapture1 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,black: int32;
  next_partial,whole_partial: TMove;
  found :Integer ;
  q:TPosition;
begin
  (* partial move has already been executed. seek LBJ1 and RBJ1 *)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  black := p.bm or p.bk;
  (* left backward jump *)
  m := ((((square and LBJ1) shr 5) and black) shr 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := (m or (m shl 9)) and NBBR;
    next_partial.wk := (m or (m shl 9)) and BBR;
    next_partial.bm := (m shl 4) and p.bm;
    next_partial.bk := (m shl 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitemancapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)
  m := ((((square and RBJ1) shr 4) and black) shr 3) and free;
  if (m<>0) then
  begin
    next_partial.wm := (m or (m shl 7)) and NBBR;
    next_partial.wk := (m or(m shl 7)) and BBR;
    next_partial.bm := (m shl 3) and p.bm;
    next_partial.bk := (m shl 3) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitemancapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if (found= 0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
     movelist[n] := partial;
    Inc(n);
  end;
end;

procedure whitemancapture2 (var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,black: int32;
  next_partial,whole_partial: TMove;
  found :Integer ;
  q:TPosition ;

begin
  (* partial move has already been executed. seek LBJ1 and RBJ1 *)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  black :=p.bm or p.bk;
  (* left backward jump *)
  m :=((((square and LBJ2) shr 4) and black) shr 5) and free;
  if (m<>0) then
  begin
    next_partial.wm := (m or (m shl 9));
    next_partial.wk := 0;
    next_partial.bm := (m shl 5) and p.bm;
    next_partial.bk := (m shl 5) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitemancapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)
  m := ((((square and RBJ2) shr 3) and black) shr 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := (m or (m shl 7));
    next_partial.wk := 0;
    next_partial.bm := (m shl 4) and p.bm;
    next_partial.bk := (m shl 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitemancapture2(q,movelist,n,whole_partial,m);

    found := 1;
  end;

  if (found=0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
    movelist[n] := partial;
    Inc(n);
  end;
end;

procedure whitekingcapture1(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,black: int32;
  next_partial,whole_partial: TMove;
  found :Integer ;
  q: TPosition;

begin
  (* partial move has already beeng executed. seek LFJ1 RFJ1 LBJ1 RBJ1*)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  black := p.bm or p.bk;
  (* left forward jump *)
  m := ((((square and LFJ1) shl 3) and black) shl 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shr 7));
    next_partial.bm := (m shr 4) and p.bm;
    next_partial.bk := (m shr 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ1) shl 4) and black) shl 5) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shr 9));
    next_partial.bm := (m shr 5) and p.bm;
    next_partial.bk := (m shr 5) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* left backward jump *)
  m := ((((square and LBJ1) shr 5) and black) shr 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shl 9));
    next_partial.bm := (m shl 4) and p.bm;
    next_partial.bk := (m shl 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)
  m :=((((square and RBJ1) shr 4) and black) shr 3) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shl 7));
    next_partial.bm := (m shl 3) and p.bm;
    next_partial.bk := (m shl 3) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture1(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if (found=0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
    movelist[n] :=partial;
    Inc(n);
  end;
end;

procedure whitekingcapture2(var p: TPosition; var movelist: array of TMove; var n: Integer; var partial: TMove; square: Int32);
var
  m,free,black:int32 ;
  next_partial,whole_partial:TMove ;
  found :Integer ;
  q:TPosition ;

begin
  (* partial move has already been executed. seek LFJ1 RFJ1 LBJ1 RBJ1*)
  found := 0;

  free := not(p.bm or p.bk or p.wm or p.wk);
  black := p.bm or p.bk;
  (* left forward jump *)
  m := ((((square and LFJ2) shl 4) and black) shl 3) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shr 7));
    next_partial.bm := (m shr 3) and p.bm;
    next_partial.bk := (m shr 3) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right forward jump *)
  m := ((((square and RFJ2) shl 5) and black) shl 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shr 9));
    next_partial.bm := (m shr 4) and p.bm;
    next_partial.bk := (m shr 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* left backward jump *)
  m := ((((square and LBJ2) shr 4) and black) shr 5) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shl 9));
    next_partial.bm := (m shl 5) and p.bm;
    next_partial.bk := (m shl 5) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  (* right backward jump *)
  m := ((((square and RBJ2) shr 3) and black) shr 4) and free;
  if (m<>0) then
  begin
    next_partial.wm := 0;
    next_partial.wk := (m or (m shl 7));
    next_partial.bm :=(m shl 4) and p.bm;
    next_partial.bk := (m shl 4) and p.bk;
    q.bm := p.bm xor next_partial.bm;
    q.bk := p.bk xor next_partial.bk;
    q.wm := p.wm xor next_partial.wm;
    q.wk := p.wk xor next_partial.wk;

    whole_partial.bm := partial.bm xor next_partial.bm;
    whole_partial.bk := partial.bk xor next_partial.bk;
    whole_partial.wm := partial.wm xor next_partial.wm;
    whole_partial.wk := partial.wk xor next_partial.wk;
    whitekingcapture2(q,movelist,n, whole_partial,m);

    found := 1;
  end;

  if (found=0) then
  begin
    (* no continuing jumps - save the move in the movelist *)
    movelist[n] := partial;
    Inc(n);
  end;
end;


end.

