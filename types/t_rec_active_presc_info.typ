CREATE OR REPLACE TYPE t_rec_active_presc_info AS OBJECT
(
    id_presc    number(24,4),
    emb_id      varchar2(255),
		id_patient  NUMBER(24),
		flg_type    VARCHAR2(1)
);