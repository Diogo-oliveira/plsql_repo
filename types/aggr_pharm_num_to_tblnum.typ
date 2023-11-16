
create or replace type aggr_pharm_num_to_tblnum as object
(
	l_tbl_num		table_number,

	static function ODCIAggregateInitialize
	(
		i_num in out aggr_pharm_num_to_tblnum
	)
	return number,

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_num_to_tblnum,
		val		in 		number
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_num_to_tblnum,
		o_ctx2	in 		aggr_pharm_num_to_tblnum
	)
	return number,

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_num_to_tblnum,
		o_return_value	out		table_number,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_pharm_num_to_tblnum is

	static function ODCIAggregateInitialize
	(
		i_num in out aggr_pharm_num_to_tblnum
	)
	return number
	is
	begin
		i_num := aggr_pharm_num_to_tblnum(table_number());
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate
	(
		self	in out	aggr_pharm_num_to_tblnum,
		val		in 		number
	)
	return number
	is
	begin
		if (val is not null) then
			self.l_tbl_num.extend(1);
			self.l_tbl_num(self.l_tbl_num.count) := val;
		end if;

		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_num_to_tblnum,
		o_ctx2	in 		aggr_pharm_num_to_tblnum
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate
	(
		self			in out	aggr_pharm_num_to_tblnum,
		o_return_value	out		table_number,
		i_flags			in		number
	)
	return number
	is
	begin
		o_return_value := self.l_tbl_num;
		return Odciconst.Success;
	end;
end;
/
