create or replace function pharmacy_uni_type2varchar
	(
		i_type	in	t_tbl_pharm_car_drawers
	)
	return varchar2
	is
		l_car_drawers	varchar2(1000) := '';
	begin
		if (i_type.count > 0) then
			for i in i_type.first .. i_type.last
			loop
				if (i > 1) then
					l_car_drawers := l_car_drawers || '<br/>';
				end if;

				l_car_drawers := l_car_drawers || i_type(i).car_name;

				if (i_type(i).drawers.count > 0) then
					for j in i_type(i).drawers.first .. i_type(i).drawers.last
					loop
						l_car_drawers := l_car_drawers || ', ' || i_type(i).drawers(j);
					end loop;
				end if;
			end loop;
		end if;

		return l_car_drawers;

	exception
	when others then
		raise;
	end pharmacy_uni_type2varchar;
/

--ALERT-59304
create or replace function pharmacy_uni_type2varchar
(
	i_type	in	t_tbl_pharm_car_drawers
)
return varchar2
is
	l_car_drawers	varchar2(4000 char) := '';
begin
	if (i_type.count > 0) then
		for i in i_type.first .. i_type.last
		loop
			if (i > 1) then
				l_car_drawers := l_car_drawers || '<br/>';
			end if;

			l_car_drawers := l_car_drawers || i_type(i).car_name;

			if (i_type(i).drawers.count > 0) then
				for j in i_type(i).drawers.first .. i_type(i).drawers.last
				loop
					l_car_drawers := l_car_drawers || ', ' || i_type(i).drawers(j);
				end loop;
			end if;
		end loop;
	end if;

	return l_car_drawers;

exception
when others then
	raise;
end pharmacy_uni_type2varchar;
/
