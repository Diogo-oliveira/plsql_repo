-- AGGR TYPE
create or replace type aggr_pharm_uni_car_drawer as object
(
	-- Author  : RUI.MARANTE
	-- Created : 15-07-2009 11:30:28
	-- Purpose : aggregate unidose cars by patient and at the same time, aggregate drawers by unidose car (for the pharmacy unidose grid)

	l_typ_car		t_rec_pharm_uni_car_drawer,
	l_tbl_out		t_tbl_pharm_car_drawers,
	l_count_car		number,

	static function ODCIAggregateInitialize
	(
		i_car in out aggr_pharm_uni_car_drawer
	)
	return number,

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_uni_car_drawer,
		val		in 		t_rec_pharm_uni_car_drawer
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_uni_car_drawer,
		o_ctx2	in 		aggr_pharm_uni_car_drawer
	)
	return number,

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_uni_car_drawer,
		o_return_value	out		t_tbl_pharm_car_drawers,
		i_flags			in		number
	)
	return number
);
/
create or replace type body aggr_pharm_uni_car_drawer is

	-- Author  : RUI.MARANTE
	-- Created : 15-07-2009 11:30:28

	static function ODCIAggregateInitialize
	(
		i_car in out aggr_pharm_uni_car_drawer
	)
	return number
	is
	begin
		i_car := aggr_pharm_uni_car_drawer(t_rec_pharm_uni_car_drawer(null, null, null, null), t_tbl_pharm_car_drawers(), 0);
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_uni_car_drawer,
		val		in 		t_rec_pharm_uni_car_drawer
	)
	return number
	is
		l_found		boolean := false;

		--"distinct" for drawers
		function is_new_drawer
		(
			i_idx		in	number,
			i_drawer	in	varchar2
		)
		return boolean
		is
			l_ret	boolean := true;
		begin
			for j in 1 .. self.l_tbl_out(i_idx).drawers.count
			loop
				if (self.l_tbl_out(i_idx).drawers(j) = i_drawer) then
					l_ret := false;
					exit;
				end if;
			end loop;

			return l_ret;

		exception
		when others then
			raise;
		end is_new_drawer;
	begin
		if (val.car_model_name is not null) then

			for i in 1 .. self.l_tbl_out.count
			loop
				if (self.l_tbl_out(i).car_name = val.car_model_name) then
					--o carro já existe, por isso, acrescentar gaveta
					if (val.drawer_number is not null and is_new_drawer(i, val.drawer_label || ' ' || val.drawer_number)) then
						self.l_tbl_out(i).drawers.extend(1);
						self.l_tbl_out(i).drawers(self.l_tbl_out(i).drawers.count) := val.drawer_label || ' ' || val.drawer_number;
					end if;
					l_found := true;
					exit; --sair do loop
				end if;
			end loop;

			if (not l_found) then
				--nao foi encontrado o carro, por isso, acrescentar carro e gaveta
				self.l_count_car := self.l_count_car + 1;
				self.l_tbl_out.extend(1);
				if (val.drawer_number is not null) then
					self.l_tbl_out(self.l_count_car) := t_rec_pharm_uni_drawers(val.car_model_name, table_varchar(val.drawer_label || ' ' || val.drawer_number));
				else
					--pode estar no carro mas sem estar em nenhuma gaveta
					self.l_tbl_out(self.l_count_car) := t_rec_pharm_uni_drawers(val.car_model_name, table_varchar());
				end if;
			end if;

		end if;

		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_uni_car_drawer,
		o_ctx2	in 		aggr_pharm_uni_car_drawer
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_uni_car_drawer,
		o_return_value	out		t_tbl_pharm_car_drawers,
		i_flags			in		number
	)
	return number
	is
	begin
		o_return_value := self.l_tbl_out;
		return Odciconst.Success;
	end;
end;
/
