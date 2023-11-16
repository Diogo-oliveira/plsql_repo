-->V_EPIS_ANAMNESIS
CREATE OR REPLACE VIEW V_EPIS_ANAMNESIS AS
SELECT id_epis_anamnesis,
       id_episode,
       flg_type,
       dt_epis_anamnesis_tstz,
       desc_epis_anamnesis,
       flg_temp,
       flg_status,
       flg_edition_type,
       flg_reported_by,
       flg_class,
       id_diagnosis,
       desc_epis_anamnesis_bck,
       id_professional,
       id_institution,
       id_software,
       id_patient,
       id_epis_anamnesis_parent,
       id_cancel_info_det,
       id_diag_inst_owner
  FROM alert.epis_anamnesis;
