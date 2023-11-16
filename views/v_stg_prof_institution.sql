CREATE OR REPLACE view v_stg_prof_institution AS 
SELECT id_stg_professional, id_stg_institution, flg_state, dt_begin_tstz, dt_end_tstz,id_stg_files,id_institution
  FROM stg_prof_institution;