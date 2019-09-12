unit eval;

interface

uses
  structs;

function evaluation(var p:TPosition): Integer;

implementation

uses
  Bool, Constants;

var
  backrankblack : array [0..255] of Byte;
  backrankwhite : array [0..255] of Byte;

const
  DEVSINGLECORNER  = 4;
  OREO = 10;
  IDEALBACKRANK = 20;
  BRIDGEBACKRANK = 15;
  GOODBACKRANK = 10;
  GOALKEEPERBACKRANK = 5;
  KINGCENTERVALUE = 5;
  OPENINGTEMPO = -2;
  ENDGAMETEMPO = 2;
  DOGHOLE = 5;
  SINGLEROAMINGKING = 90;
  TRAPPEDKINGSC = 30;

  CENTER = $00666600;

function evaluation(var p:TPosition): Integer;
var
  value :Integer;
  tempo : Integer;
  bm, wm, bk, wk :Integer;
  free : Int32;  
begin
  value := 0;
  tempo := 0;
  bm := bitcount(p.bm); wm := bitcount(p.wm); bk := bitcount(p.bk); wk := bitcount(p.wk);
  free := not (p.bm or p.bk or p.wm or p.wk);

  // material ------------------------------------------

  Inc (value, 100*(bm-wm));
  Inc (value, 130*(bk-wk));

  // exchange when you have more:
  Inc (value, ((bm+bk-wm-wk)*100) div (bm+bk+wm+wk));
  
  // positional stuff ----------------------------------

  // back rank
  Inc (value, backrankblack[p.bm and  $FF]);
  Dec (value, backrankwhite[(p.wm shr 24) and  $FF]);

  // tempo
  if  (bk+wk=0) and (bm=wm) then
  begin
    Inc (tempo,  bitcount(p.bm and $0FFFFFF0));
    Inc (tempo,  bitcount(p.bm and $0FFFFF00));
    Inc (tempo,  bitcount(p.bm and $0FFFF000));
    Inc (tempo,  bitcount(p.bm and $0FFF0000));
    Inc (tempo,  bitcount(p.bm and $0FF00000));
    Inc (tempo,  bitcount(p.bm and $0F000000));

    Dec (tempo,  bitcount(p.wm and $0FFFFFF0));
    Dec (tempo,  bitcount(p.wm and $00FFFFF0));
    Dec (tempo,  bitcount(p.wm and $000FFFF0));
    Dec (tempo,  bitcount(p.wm and $0000FFF0));
    Dec (tempo,  bitcount(p.wm and $00000FF0));
    Dec (tempo,  bitcount(p.wm and $000000F0));

    if (bm+bk >= 18) then
      Inc (value,  OPENINGTEMPO*tempo);

    if (bm+bk<= 10) then
      Inc (value, ENDGAMETEMPO*tempo);
    end;

  // cramps

  // center control

  // doghole
  if (p.bm and SQ1<>0) and (p.wm and SQ5<>0) then
    Inc (value, DOGHOLE);
  if (p.bm and SQ3<>0) and (p.wm and SQ12<>0) then
    Inc (value, DOGHOLE);
  if (p.wm and SQ32<>0) and (p.bm and SQ28<>0) then
    Dec (value, DOGHOLE);
  if (p.wm and SQ30<>0) and (p.bm and SQ21<>0) then
    Dec (value, DOGHOLE);

  // runaway men

  // king centralization
  Inc (value, bitcount(p.bk and  CENTER)*KINGCENTERVALUE);
  Dec (value,  bitcount(p.wk and CENTER)*KINGCENTERVALUE);

  // trapped kings
  // in single corner:
  if (p.bk and SQ29<>0) and (p.wm and SQ30<>0) and (free and  SQ21 <>0) then
    Dec (value, TRAPPEDKINGSC);
  if (p.wk and SQ4<>0) and (p.bm and SQ3<>0) and (free and SQ12 <> 0) then
    Inc (value, TRAPPEDKINGSC);

  // single roaming king
  if (bk<>0) and (wk=0) then
  begin
    if (
      ((p.bk and CENTER) <> 0) and
      ((p.bm and (SQ1 or SQ2 or SQ3)) = (SQ1 or SQ2 or SQ3))
    ) then
      Inc (value, SINGLEROAMINGKING);
  end;
  if (wk<>0) and (bk=0) then
  begin
    if (
      ((p.wk and CENTER) <> 0) and
      ((p.wm and  (SQ30 or SQ31 or SQ32)) = (SQ30 or SQ31 or SQ32))
    ) then
      Dec (value, SINGLEROAMINGKING);
  end;

  // negamax formulation requires this:
  if (p.color=COLOR_WHITE) then value := -value;
  Result := value;
end;

procedure initeval;
var
  i,j : int32;
  eval: Integer;
begin
  // evaluation uses some tables to look up values which are initialized here

  // init backrankblack
  for i := 0 to 255 do
  begin
    eval := 0;
    // imagine black pieces set up as i and evaluate them

    // developed single corner
    if (not i and SQ4<>0) and (not i and  SQ8<>0) then
      Inc (eval, DEVSINGLECORNER);

    // oreo
    if (i and SQ2<>0) and (i and SQ3<>0) and (i and SQ7<>0) then
      Inc (eval, OREO);

    // ideal back rank
    if (i and SQ1<>0) and (i and SQ2<>0) and (i and SQ3<>0) then
      Inc (eval, IDEALBACKRANK);

    // bridge back rank
    if (i and SQ1<>0) and (not i and SQ2<>0) and (i and SQ3<>0) then
      Inc (eval, BRIDGEBACKRANK);

    // good back rank
    if (i and SQ2<>0) and (i and SQ3<>0) and (not i and SQ1<>0) then
      Inc (eval, GOODBACKRANK);

    // goalkeeper-piece - if only one piece is left on the backrank, this is the best
    if i and SQ2<>0 then
      Inc (eval, GOALKEEPERBACKRANK);

    backrankblack[i] := eval;
  end;

    // init backrankwhite
  for j := 0 to 255 do
  begin
    eval := 0;
    // imagine white pieces set up as j<<24 and evaluate them
    i := j shl 24;

    // developed single corner
    if (not i and SQ25<>0) and (not i and  SQ29<>0) then
      Inc (eval, DEVSINGLECORNER);

    // oreo
    if (i and SQ31<>0) and (i and SQ26<>0) and (i and SQ30<>0) then
      Inc (eval, OREO);

    // ideal back rank
    if (i and SQ30<>0)and (i and  SQ31<>0) and (i and  SQ32<>0) then
      Inc (eval, IDEALBACKRANK);

    // bridge back rank
    if (i and  SQ32<>0) and (not i and SQ31<>0) and (i and  SQ30<>0) then
      Inc (eval, BRIDGEBACKRANK);

    // good back rank
    if (i and SQ30<>0) and (i and  SQ31<>0) and (not i and SQ32<>0) then
      Inc (eval, GOODBACKRANK);

    // goalkeeper-piece - if only one piece is left on the backrank, this is the best
    if (i and SQ31)<>0 then
      Inc (eval, GOALKEEPERBACKRANK);

    backrankwhite[j] := eval;
  end;
end;

initialization
  initeval;
end.
