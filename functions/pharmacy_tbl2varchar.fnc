
create or replace function pharmacy_tbl2varchar
	(
		i_tbl		in	table_varchar,
		i_sep		in	varchar2 default ', '
	)
return varchar2
is
	l_str	varchar2(32000 char) := '';
	l_els	number := 0;
begin
	l_els := i_tbl.count;
	
	for i in 1 .. l_els
	loop
		l_str := l_str || i_sep || i_tbl(i);
	end loop;
	
	l_str := ltrim(l_str, i_sep);
	
	return l_str;

exception
when others then
	raise;
end pharmacy_tbl2varchar;
/
