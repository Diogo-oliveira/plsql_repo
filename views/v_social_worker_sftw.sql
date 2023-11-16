CREATE OR REPLACE VIEW V_SOCIAL_WORKER_SFTW AS
SELECT
   ID_EPISODE
  ,ID_SCHEDULE
  ,ID_PROFESSIONAL
  ,ID_DEP_CLIN_SERV
  ,id_department
  ,CODE_DEPARTMENT
  ,dep_flg_type
  ,id_epis_type
  ,CODE_CLINICAL_SERVICE
  ,ID_ROOM,CODE_ROOM
  ,DESC_ROOM
  ,ID_BED
  ,CODE_BED
  ,DESC_BED
  ,ID_PATIENT
  ,GENDER
  ,E_ID_INSTITUTION
  ,E_ID_SOFTWARE
  ,ID_SOFTWARE
  ,CODE_SOFTWARE
  ,ID_FIRST_NURSE_RESP
  ,ID_REASON
  ,FLG_REASON_TYPE
  ,FLG_STATE
  ,OP_ID_PROFISSIONAL
  ,ID_PROF_QUESTIONED
  ,ID_OPINION
  ,ID_EPISODE_ANSWER
  ,ID_PROF_QUESTIONS
  ,DT_LAST_UPDATE
  ,DT_PROBLEM_TSTZ
  ,OP_EPISODE
  ,I_LANG
  ,I_PROF_ID
  ,I_INSTITUTION
  ,I_SOFTWARE
  ,ROWNUMBER
  FROM (WITH o_type AS (SELECT otc.id_opinion_type
                          FROM opinion_type_category otc
                         WHERE otc.flg_available = 'Y'
                           AND ((otc.id_category = ALERT_CONTEXT( 'i_category') AND
                               otc.id_profile_template IS NULL) OR
                               (otc.id_profile_template = ALERT_CONTEXT('i_profile_template'))))
           SELECT epis.id_episode,
                  epis.id_schedule,
                  epis.id_professional,
                  epis.id_dep_clin_serv,
                  d.code_department,
          d1.id_department,
          d1.flg_type dep_flg_type,
		          decode( epis.id_epis_type, 16, 1, epis.id_epis_type) id_epis_type,
                  cs.code_clinical_service,
                  epis.id_room,
                  r.code_room,
                  r.desc_room,
                  epis.id_bed,
                  b.code_bed,
                  b.desc_bed,
                  epis.id_patient,
                  p.gender,
                  epis.id_institution e_id_institution,
                  epis.id_software e_id_software,
                  epis.id_software,
                  sfw.code_software,
                  epis.id_first_nurse_resp,
                  s.id_reason,
                  s.flg_reason_type,
                  o.flg_state,
                  op.id_professional op_id_profissional,
                  o.id_prof_questioned,
                  o.id_opinion,
                  o.id_episode_answer,
                  o.id_prof_questions,
                  o.dt_last_update,
                  o.dt_problem_tstz,
                  o.id_episode op_episode,
                  alert_context('i_lang') i_lang,
                  alert_context('i_prof_id') i_prof_id,
                  alert_context('i_institution') i_institution,
                  alert_context('i_software') i_software,
                  decode(o.dt_problem_tstz,
                         NULL,
                         1,
                         row_number() over(PARTITION BY o.id_episode ORDER BY o.dt_problem_tstz DESC)) rownumber
             FROM v_episode_act epis
			 join epis_info ei on ei.id_episode = epis.id_episode
			 join dep_clin_serv dcs on dcs.id_dep_clin_serv = ei.id_dep_clin_serv
			 join department d1 on d1.id_department = dcs.id_department
             LEFT JOIN schedule s
               ON epis.id_schedule = s.id_schedule
             LEFT JOIN schedule_outp so
               ON s.id_schedule = so.id_schedule -- este join so da' nos episodios de outp, pp, pc, edis
             LEFT JOIN clinical_service cs
               ON epis.id_clinical_service = cs.id_clinical_service
             LEFT JOIN bed b
               ON epis.id_bed = b.id_bed
             LEFT JOIN room r
               ON r.id_room = b.id_room
              AND r.flg_available = 'Y'
             LEFT JOIN department d
               ON d.id_department = r.id_department
              AND d.flg_available = 'Y'
             LEFT JOIN patient p
               ON epis.id_patient = p.id_patient
             LEFT JOIN software sfw
               ON epis.id_software = sfw.id_software
             LEFT JOIN opinion o
               ON epis.id_episode = o.id_episode
              AND o.id_opinion_type IN (SELECT *
                                          FROM o_type)
             LEFT JOIN opinion_prof op
               ON o.id_opinion = op.id_opinion
            WHERE epis.id_institution = alert_context('i_institution')
              AND epis.flg_ehr = 'N'
              AND epis.id_software IN (1, 2, 3, 8, 11, 12)
              AND epis.id_epis_type NOT IN (18, 19, 22, 26)
			  )
            WHERE rownumber = 1
;
