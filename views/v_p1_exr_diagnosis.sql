CREATE OR REPLACE VIEW V_P1_EXR_DIAGNOSIS AS
SELECT id_exr_diagnosis,
       id_external_request,
       id_diagnosis,
       id_professional,
       id_institution,
       flg_type,
       flg_status,
       dt_insert_tstz,
       desc_diagnosis,
       year_begin,
       month_begin,
       day_begin
  FROM p1_exr_diagnosis;
