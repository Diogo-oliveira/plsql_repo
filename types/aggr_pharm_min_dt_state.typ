
create or replace type aggr_pharm_min_dt_state as object 
(
	l_typ_st_dt t_rec_pharm_state_dt,

	static function ODCIAggregateInitialize 
	(
		i_st_dt in out aggr_pharm_min_dt_state
	)
	return number,

	member function ODCIAggregateIterate 
	(
		self	in out	aggr_pharm_min_dt_state, 
		val		in 		t_rec_pharm_state_dt
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_min_dt_state,
		o_ctx2	in 		aggr_pharm_min_dt_state
	)
	return number,

	member function ODCIAggregateTerminate 
	(
		self			in out	aggr_pharm_min_dt_state,
		o_return_value	out		number,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_pharm_min_dt_state is  

	static function ODCIAggregateInitialize 
	(
		i_st_dt in out aggr_pharm_min_dt_state
	)
	return number
	is
	begin
		i_st_dt := aggr_pharm_min_dt_state(t_rec_pharm_state_dt(null, null));
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate 
	(
		self	in out	aggr_pharm_min_dt_state, 
		val		in 		t_rec_pharm_state_dt
	)
	return number
	is
	begin
		if ((self.l_typ_st_dt.dt_state is null) or (val.dt_state < self.l_typ_st_dt.dt_state)) then
			self.l_typ_st_dt.id_state := val.id_state;
			self.l_typ_st_dt.dt_state := val.dt_state;
		end if;
		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_min_dt_state,
		o_ctx2	in 		aggr_pharm_min_dt_state
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate 
	(
		self			in out	aggr_pharm_min_dt_state,
		o_return_value	out		number,
		i_flags			in		number
	)
	return number
	is
	begin 
		o_return_value := self.l_typ_st_dt.id_state;
		return Odciconst.Success;
	end;
end;
/

drop type aggr_pharm_min_dt_state;

create or replace type aggr_pharm_min_dt_state as object 
(
	l_typ_st_dt t_rec_pharm_state_dt_rank,

	static function ODCIAggregateInitialize 
	(
		i_st_dt in out aggr_pharm_min_dt_state
	)
	return number,

	member function ODCIAggregateIterate 
	(
		self	in out	aggr_pharm_min_dt_state, 
		val		in 		t_rec_pharm_state_dt_rank
	)
	return number,

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_min_dt_state,
		o_ctx2	in 		aggr_pharm_min_dt_state
	)
	return number,

	member function ODCIAggregateTerminate 
	(
		self			in out	aggr_pharm_min_dt_state,
		o_return_value	out		t_rec_pharm_state_dt,
		i_flags			in		number
	)
	return number
);
/

create or replace type body aggr_pharm_min_dt_state is  

	static function ODCIAggregateInitialize 
	(
		i_st_dt in out aggr_pharm_min_dt_state
	)
	return number
	is
	begin
		i_st_dt := aggr_pharm_min_dt_state(t_rec_pharm_state_dt_rank(null, null, null));
		return Odciconst.Success;
	end;

	member function ODCIAggregateIterate 
	(
		self	in out	aggr_pharm_min_dt_state, 
		val		in 		t_rec_pharm_state_dt_rank
	)
	return number
	is
	begin
		if 
		(
			(self.l_typ_st_dt.id_state is null) or --first time
			(nvl(val.rank, 999) < self.l_typ_st_dt.rank) or --lower rank (higher priority state)
			(val.rank = self.l_typ_st_dt.rank and val.dt_state < self.l_typ_st_dt.dt_state) --equal rank but older date
		)
		then
			self.l_typ_st_dt.id_state	:= val.id_state;
			self.l_typ_st_dt.dt_state	:= val.dt_state;
			self.l_typ_st_dt.rank		:= val.rank;
		end if;
		return Odciconst.Success;
	end;

	member function ODCIAggregateMerge
	(
		self	in out	aggr_pharm_min_dt_state,
		o_ctx2	in 		aggr_pharm_min_dt_state
	)
	return number
	is
	begin
		return Odciconst.Success;
	end;

	member function ODCIAggregateTerminate 
	(
		self			in out	aggr_pharm_min_dt_state,
		o_return_value	out		t_rec_pharm_state_dt,
		i_flags			in		number
	)
	return number
	is
	begin 
		o_return_value := t_rec_pharm_state_dt(self.l_typ_st_dt.id_state, self.l_typ_st_dt.dt_state);
		return Odciconst.Success;
	end;
end;
/
