unit time;

interface

const
  CLK_TCK = 1000;
  
function clock(): Double;

implementation

uses
  Windows;

function clock(): Double;
begin
  result := GetTickCount;
end;

end.
