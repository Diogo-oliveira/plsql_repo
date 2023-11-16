
create or replace type aggr_pharm_id_state as object
(
	l_tbl_states	table_number,
	l_state_count	number,

	static function ODCIAggregateInitialize
	(
		i_st_id in out aggr_pharm_id_state
	)
	return number,

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_id_state,
		val		in 		number
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_id_state,
		o_ctx2	in 		aggr_pharm_id_state
	)
	return number,

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_id_state,
		o_return_value	out		table_number,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_pharm_id_state is

	static function ODCIAggregateInitialize
	(
		i_st_id in out aggr_pharm_id_state
	)
	return number
	is
	begin
		i_st_id := aggr_pharm_id_state(table_number(), 0);
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_id_state,
		val		in 		number
	)
	return number
	is
	begin
		if (val is not null) then
			self.l_state_count := self.l_state_count + 1;
			self.l_tbl_states.extend(1);
			self.l_tbl_states(self.l_state_count) := val;
		end if;

		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_id_state,
		o_ctx2	in 		aggr_pharm_id_state
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_id_state,
		o_return_value	out		table_number,
		i_flags			in		number
	)
	return number
	is
	begin
		o_return_value := self.l_tbl_states;
		return Odciconst.Success;
	end;
end;
/
