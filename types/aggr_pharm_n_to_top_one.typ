
create or replace type aggr_pharm_n_to_top_one as object
(
	l_num	number,

	static function ODCIAggregateInitialize
	(
		i_num in out aggr_pharm_n_to_top_one
	)
	return number,

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_n_to_top_one,
		val		in 		number
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_n_to_top_one,
		o_ctx2	in 		aggr_pharm_n_to_top_one
	)
	return number,

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_n_to_top_one,
		o_return_value	out		number,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_pharm_n_to_top_one is

	static function ODCIAggregateInitialize
	(
		i_num in out aggr_pharm_n_to_top_one
	)
	return number
	is
	begin
		i_num := aggr_pharm_n_to_top_one(null);
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_n_to_top_one,
		val		in 		number
	)
	return number
	is
	begin
		if (val is not null and l_num is null) then
			l_num := val;
		end if;

		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_n_to_top_one,
		o_ctx2	in 		aggr_pharm_n_to_top_one
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_n_to_top_one,
		o_return_value	out		number,
		i_flags			in		number
	)
	return number
	is
	begin
		o_return_value := self.l_num;
		return Odciconst.Success;
	end;
end;
/
