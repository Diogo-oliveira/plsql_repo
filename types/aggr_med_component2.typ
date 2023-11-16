create or replace type aggr_med_component2 as object
(
 	l_type_comp   t_component_struct,
	l_tbl_out     t_tbl_component_struct,
	l_state_count	number,

	static function ODCIAggregateInitialize
	(
		i_st_id in out aggr_med_component2

	)
	return number,

	member function ODCIAggregateIterate
	(
		self	in out	aggr_med_component2,

		val		in 		t_component_struct
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_med_component2,
		o_ctx2	in 		aggr_med_component2
	)
	return number,

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_med_component2,
		o_return_value	out		t_tbl_component_struct,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_med_component2 is

	static function ODCIAggregateInitialize
	(
		i_st_id in out aggr_med_component2
	)
	return number
	is
	begin
		i_st_id := aggr_med_component2(t_component_struct(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),t_tbl_component_struct(), 0);
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate
	(
		self	in out	aggr_med_component2,
		val		in 		  t_component_struct
	)
	return number
	is
	begin


    if (val.id_drug is not null) then
			self.l_state_count := self.l_state_count + 1;
			self.l_tbl_out.extend(1);
			self.l_tbl_out(self.l_state_count) := val;
		end if;

		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_med_component2,
		o_ctx2	in 		aggr_med_component2
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_med_component2,
		o_return_value	out		t_tbl_component_struct,
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