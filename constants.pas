unit constants; // DG: renamed because of conflict with VCL units

interface

const
// version number
  VERSION = 0.20;

// maximal number of legal moves
  MAXMOVES = 28;

// colors
  COLOR_BLACK = 0; // DG: rename necessary due to case insensitivity
  COLOR_WHITE = 1; // DG: rename necessary due to case insensitivity

// maximal depth PubliCake can search
  MAXDEPTH = 100;

// mate value
  MATE = 2000;

(* bitboard masks for moves in various directions *)
(* here "1" means the squares in the columns 1357 and "2" in 2468.*)
  RF1 = $0F0F0F0F;
  RF2 = $00707070;
  LF1 = $0E0E0E0E;
  LF2 = $00F0F0F0;
  RB1 = $0F0F0F00;
  RB2 = $70707070;
  LB1 = $0E0E0E00;
  LB2 = $F0F0F0F0;
(* bitboard masks for jumps in various directions *)
  RFJ1 = $00070707;
  RFJ2 = $00707070;
  LFJ1 = $000E0E0E;
  LFJ2 = $00E0E0E0;
  RBJ1 = $07070700;
  RBJ2 = $70707000;
  LBJ1 = $0E0E0E00;
  LBJ2 = $E0E0E000;

(* back rank masks *)
  WBR  =$F0000000;
  BBR  =$0000000F;
  NWBR =$0FFFFFFF;
  NBBR =$FFFFFFF0;

(* square definitions: a piece on square n in normal checkers notation can be accessed with SQn*)
  SQ1 = $00000008;
  SQ2 = $00000004;
  SQ3 = $00000002;
  SQ4 = $00000001;
  SQ5 = $00000080;
  SQ6 = $00000040;
  SQ7 = $00000020;
  SQ8 = $00000010;
  SQ9 = $00000800;
  SQ10 = $00000400;
  SQ11 = $00000200;
  SQ12 =$00000100 ;
  SQ13 =$00008000 ;
  SQ14 =$00004000 ;
  SQ15 =$00002000 ;
  SQ16 =$00001000 ;
  SQ17 =$00080000 ;
  SQ18 =$00040000 ;
  SQ19 =$00020000 ;
  SQ20 =$00010000 ;
  SQ21 =$00800000 ;
  SQ22 =$00400000 ;
  SQ23 =$00200000 ;
  SQ24 =$00100000 ;
  SQ25 =$08000000 ;
  SQ26 =$04000000 ;
  SQ27 =$02000000 ;
  SQ28 =$01000000 ;
  SQ29 =$80000000 ;
  SQ30 =$40000000 ;
  SQ31 =$20000000 ;
  SQ32 =$10000000 ;

implementation

end.


