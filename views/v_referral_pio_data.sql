CREATE OR REPLACE VIEW V_REFERRAL_PIO_DATA AS
SELECT v.id_external_request,
       v.flg_status_pio,
       v.id_inst_orig,
       (SELECT pk_translation.get_translation(1, code_inst_orig)
          FROM dual) orig_inst_desc,
       v.orig_inst_ext_code,
       v.id_inst_dest,
       (SELECT pk_translation.get_translation(1, code_inst_dest)
          FROM dual) dest_inst_desc,
       v.dest_inst_ext_code,
       v.id_speciality,
       (SELECT pk_translation.get_translation(1, 'P1_SPECIALITY.CODE_SPECIALITY.' || v.id_speciality)
          FROM dual) desc_speciality,
       v.id_dep_clin_serv,
       (SELECT pk_translation.get_translation(1, 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || id_clinical_service)
          FROM dual) desc_clinical_service,
       v.flg_priority,
       (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_PRIORITY', v.flg_priority, 1)
          FROM dual) desc_flg_priority,
       v.dt_requested,
       v.dt_status,
       v.flg_status,
       (SELECT pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', v.flg_status, 1)
          FROM dual) desc_flg_status,
       v.dt_schedule,
       v.id_patient
  FROM (SELECT p.id_external_request,
               rp.flg_status_pio,
               p.id_inst_orig,
               i_orig.code_institution code_inst_orig,
               i_orig.ext_code orig_inst_ext_code,
               p.id_inst_dest,
               i_dest.code_institution code_inst_dest,
               i_dest.ext_code dest_inst_ext_code,
               p.id_speciality,
               p.id_dep_clin_serv,
               (SELECT dcs.id_clinical_service
                  FROM dep_clin_serv dcs
                 WHERE p.id_dep_clin_serv = dcs.id_dep_clin_serv) id_clinical_service,
               p.flg_priority,
               p.dt_requested,
               p.dt_status_tstz dt_status,
               p.flg_status,
               (SELECT s.dt_begin_tstz
                  FROM schedule s
                 WHERE s.id_schedule = p.id_schedule
                   AND s.flg_status = 'A') dt_schedule,
               p.id_patient
          FROM p1_external_request p
          JOIN ref_pio rp
            ON (rp.id_external_request = p.id_external_request AND rp.flg_status_pio = 'W')
          JOIN institution i_orig
            ON (p.id_inst_orig = i_orig.id_institution)
          JOIN institution i_dest
            ON (p.id_inst_dest = i_dest.id_institution)
         WHERE p.id_external_request =
               nvl(to_number(sys_context('ALERT_CONTEXT', 'ID_EXTERNAL_REQUEST')), p.id_external_request)
           AND p.id_inst_orig = nvl(to_number(sys_context('ALERT_CONTEXT', 'ID_INST_ORIG')), p.id_inst_orig)
           AND p.id_inst_dest = nvl(to_number(sys_context('ALERT_CONTEXT', 'ID_INST_DEST')), p.id_inst_dest)
           AND p.id_speciality = nvl(to_number(sys_context('ALERT_CONTEXT', 'ID_SPECIALITY')), p.id_speciality)
           AND p.id_patient = nvl(to_number(sys_context('ALERT_CONTEXT', 'ID_PATIENT')), p.id_patient)
           AND rownum <= nvl(to_number(sys_context('ALERT_CONTEXT', 'NUM_RECORDS_PIO_VIEW')), 1000)) v;
