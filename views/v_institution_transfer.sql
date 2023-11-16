-->V_INSTITUTION_TRANSFER
-- View that contains information about all institution transfers
CREATE OR REPLACE VIEW V_INSTITUTION_TRANSFER AS
SELECT ti.id_institution_origin,
       ti.id_institution_dest,
       ti.dt_creation_tstz,
       ti.id_transp_entity,
       ti.notes,
       ti.dt_begin_tstz,
       ti.dt_end_tstz,
       ti.flg_status,
       ti.id_prof_reg,
       ti.id_prof_begin,
       ti.id_prof_end,
       ti.id_episode,
       ti.id_patient,
       ti.id_transfer_option,
       ti.id_prof_cancel,
       ti.dt_cancel_tstz,
       ti.notes_cancel,
       ti.id_dep_clin_serv
  FROM transfer_institution ti;

-- ALERT-246089: Add column transfer_institution.id_cancel_reason to view: v_institution_transfer

CREATE OR REPLACE view v_institution_transfer AS
    SELECT ti.id_institution_origin,
           ti.id_institution_dest,
           ti.dt_creation_tstz,
           ti.id_transp_entity,
           ti.notes,
           ti.dt_begin_tstz,
           ti.dt_end_tstz,
           ti.flg_status,
           ti.id_prof_reg,
           ti.id_prof_begin,
           ti.id_prof_end,
           ti.id_episode,
           ti.id_patient,
           ti.id_transfer_option,
           ti.id_prof_cancel,
           ti.dt_cancel_tstz,
           ti.notes_cancel,
           ti.id_dep_clin_serv,
           ti.id_cancel_reason
      FROM transfer_institution ti;
