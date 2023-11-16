CREATE OR REPLACE TYPE rec_pat_presc_info as object
(
    id_presc  number(24),
    flg_type  varchar2(1),
	id_drug   varchar2(255),
	drug_context varchar2(6),
	presc_type  varchar2(2)
);
/