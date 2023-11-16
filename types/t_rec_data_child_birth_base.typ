begin
  pk_versioning.drop_types( table_varchar('t_tbl_data_child_birth_base', 't_rec_data_child_birth_base') );
end;
/  

CREATE OR REPLACE TYPE t_rec_data_child_birth_base force AS OBJECT
(
    id_institution     NUMBER,
    code_institution   VARCHAR2(2000 CHAR),
    dt_delivery_tstz   TIMESTAMP WITH LOCAL TIME ZONE,
    echild_id_patient  NUMBER,
    echild_id_episode  NUMBER,
    id_pat_pregnancy   NUMBER,
    edoc_child_number  NUMBER,
    child_nation       NUMBER,
    emother_id_patient NUMBER,
    emother_id_episode NUMBER,
    mother_nation      NUMBER,
	id_episode         number
)
;
/

CREATE OR REPLACE TYPE t_tbl_data_child_birth_base AS TABLE OF t_rec_data_child_birth_base;
/