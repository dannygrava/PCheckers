{ $Log:  D:\GPVersion\Archives\Reve64\Source\Reve64.dpV
{
{   Rev 1.4    15-6-2003 20:38:29  DGrava
{ Disabled forward pruning. Added Quiescens check.
}
{
{   Rev 1.3    10-3-2003 21:46:24  DGrava
{ Little enhancements.
}
{
{   Rev 1.2    20-2-2003 16:38:47  DGrava
{ Forward pruning implemented. Extending capture sequences 
{ with conditional defines
}
{
{   Rev 1.1    6-2-2003 11:48:02  DGrava
{ Introduction of QuickEval component.
}
{
{   Rev 1.0    24-1-2003 21:12:24  DGrava
{ Eerste Check in.
{ Versie 0.27
}
{}
library Reve64;
{NOTE On debugging
  How to debug a dll?
  1. Turn Debug information on.
  2. Remote Debuggin Info on
  3. Attach to process (is this necessary)
     or:
     Define HostApplication in Run\Debug\Parameters...
     and Load.
}

uses
  CBTypes in 'CBTypes.pas',
  CBConversionUtils in 'CBConversionUtils.pas',
  ReveTypes in 'ReveTypes.pas',
  MoveGenerator in 'MoveGenerator.pas',
  Search in 'Search.pas',
  Evaluation in 'Evaluation.pas',
  DebugUtils in 'DebugUtils.pas',
  ReveIntf in 'ReveIntf.pas',
  HashTable in 'HashTable.pas',
  SearchTypes in 'SearchTypes.pas';

{$R *.res}

exports
  enginecommand,
  getmove;

begin
  // EntryPoint
end.
