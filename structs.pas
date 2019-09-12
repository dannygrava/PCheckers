unit structs;

interface

type
  int32 = Cardinal;

  // DG renamed position ---> TPosition
  TPosition = record
    bm : int32;
    bk : int32;
    wm : int32;
    wk : int32;
    color: int32;
  end;

  // DG renamed move ---> TMove
  TMove = record
    bm : int32;
    bk : int32;
    wm : int32;
    wk : int32;
  end;

implementation

end.
