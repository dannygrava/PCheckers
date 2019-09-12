unit stdio;

interface

procedure sprintf (buffer: PChar; const aFormat : string; const Args: array of const);

implementation

uses
  SysUtils;

procedure sprintf (buffer: PChar; const aFormat : string; const Args: array of const);
begin
  StrCopy (buffer, PChar (Format (aFormat,Args)));
end;

end.
