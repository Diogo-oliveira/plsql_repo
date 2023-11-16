create or replace
function pivot( p_stmt in varchar2, p_fmt in varchar2 := 'upper(@p@)', dummy in number := 0 )
return anydataset pipelined using PivotImpl;
/
