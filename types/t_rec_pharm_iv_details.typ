create or replace type t_rec_pharm_iv_details as object (
	id_drug_presc_det	number(24),
	id_drug				varchar2(255 char),
	version				varchar2(255 char),
	desc_iv				varchar2(2000 char),
	desc_instr			varchar2(2000 char),
	dose				varchar2(2000 char),
	bolus				varchar2(2000 char),
	route				varchar2(2000 char),
	drip				varchar2(2000 char),
	freq				varchar2(2000 char),
	schedule			varchar2(2000 char),
	qty					varchar2(2000 char),
	notes				varchar2(2000 char),
	dt_begin			timestamp with local time zone,
	dt_end				timestamp with local time zone,
	id_prof_prescriber	number,
	dt_prescription		timestamp with local time zone
);
/
