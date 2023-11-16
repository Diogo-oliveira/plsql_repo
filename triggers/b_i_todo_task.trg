declare
	l_sql varchar2(1000 char);
begin
	l_sql := 'drop TRIGGER alert.B_I_TODO_TASK';
	pk_versioning.run( l_sql);
end;
/


