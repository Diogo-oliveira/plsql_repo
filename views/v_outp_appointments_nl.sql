CREATE OR REPLACE VIEW V_OUTP_APPOINTMENTS_NL AS
SELECT sch.id_schedule id_schedule,
       sch.id_sch_event id_sch_event,
       sg.id_patient id_patiente,
       decode(so.flg_sched,
              'D',
              'F', --first appointments
              'M',
              'N', --follow up appointments
              NULL) type_of_appointment,
       e.dt_begin_tstz start_date, --admission_date
       nvl(sg.id_prof_ref, sg.id_inst_ref) requesting_entity_int_code,
       decode(sg.id_prof_ref,
              NULL,
              NULL,
              (SELECT pa.VALUE
                 FROM prof_accounts pa
                WHERE pa.id_professional = sg.id_prof_ref
                  AND pa.id_account = 4 /*Physician*/
                  AND pa.id_institution = sch.id_instit_requested)) requesting_entity_dbc_spec,
       sch.dt_begin_tstz schedule_start_date,
       sch.dt_end_tstz schedule_end_date,
       sch.id_instit_requested id_institution,
       (SELECT pk_translation.get_translation(1, i.code_institution)
          FROM institution i
         WHERE i.id_institution = sch.id_instit_requested) instituition_desc,
       CASE
            WHEN so.flg_state = 'S' THEN
             'N'
            WHEN so.flg_state <> 'M'
                 AND e.flg_ehr IS NULL THEN
             'N'
            ELSE
             CASE
            WHEN ei.dt_first_obs_tstz IS NULL
                 AND ei.dt_first_nurse_obs_tstz IS NULL THEN
             'A'
            ELSE
             'V'
        END END appointment_status
  FROM schedule sch
  JOIN schedule_outp so ON (sch.id_schedule = so.id_schedule)
  JOIN sch_group sg ON (sg.id_schedule = sch.id_schedule)
  LEFT JOIN epis_info ei ON sch.id_schedule = ei.id_schedule
  LEFT JOIN episode e ON (ei.id_episode = e.id_episode AND ei.id_patient = sg.id_patient)
 WHERE sch.id_sch_event IN (1, 2, 3, 4, 10, 12, 17, 20, 24, 25) --validate this
   AND sg.id_patient >= 0
	 ORDER BY sch.dt_begin_tstz;