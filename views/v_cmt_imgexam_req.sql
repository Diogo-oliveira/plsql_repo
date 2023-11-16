CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_IMGEXAM_REQ AS
SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      d.code_department) || ' | ' ||
       pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      cs.code_clinical_service) as desc_clinical_service,
            cs.id_clinical_service,
       cs.id_content as id_content_cs,
       dcs.id_dep_clin_serv,
       pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'), ex.code_exam) AS desc_exam,
       ex.id_exam AS id_context,
       c_data.cnt_req
  FROM (SELECT id_dep_clin_serv,
               id_software,
               id_exam,
               count(rownum) cnt_req
          FROM (SELECT CASE
                         WHEN res.id_software IN (8, 29) THEN
                          nvl(nvl((SELECT pdcs.id_dep_clin_serv
                                    FROM alert.prof_dep_clin_serv pdcs
                                   WHERE pdcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                     AND pdcs.flg_status = 'S'
                                     AND pdcs.flg_default = 'Y'
                                     AND pdcs.id_professional = res.i_context
                                     AND EXISTS
                                   (SELECT 1
                                            FROM alert.dep_clin_serv dcs
                                           INNER JOIN alert.department d
                                              ON d.id_department =
                                                 dcs.id_department
                                           INNER JOIN alert.software_dept sd
                                              ON sd.id_dept = d.id_dept
                                           WHERE sd.id_software =
                                                 res.id_software
                                             AND pdcs.id_dep_clin_serv =
                                                 dcs.id_dep_clin_serv
                                             AND d.flg_type = 'U'
                                             AND d.flg_available = 'Y'
                                             AND dcs.flg_available = 'Y')
                                     AND rownum = 1),
                                  (SELECT pdcs.id_dep_clin_serv
                                     FROM alert.prof_dep_clin_serv pdcs
                                    WHERE pdcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                      AND pdcs.flg_status = 'S'
                                      AND pdcs.id_professional = res.i_context
                                      AND EXISTS
                                    (SELECT 1
                                             FROM alert.dep_clin_serv dcs
                                            INNER JOIN alert.department d
                                               ON d.id_department =
                                                  dcs.id_department
                                            INNER JOIN alert.software_dept sd
                                               ON sd.id_dept = d.id_dept
                                            WHERE sd.id_software =
                                                  res.id_software
                                              AND pdcs.id_dep_clin_serv =
                                                  dcs.id_dep_clin_serv)
                                      AND NOT EXISTS
                                    (SELECT 1
                                             FROM alert.prof_dep_clin_serv pdcs1
                                            WHERE pdcs1.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                              AND pdcs1.flg_status = 'S'
                                              AND pdcs1.id_professional =
                                                  res.i_context
                                              AND pdcs1.id_dep_clin_serv !=
                                                  pdcs.id_dep_clin_serv
                                              AND EXISTS
                                            (SELECT 1
                                                     FROM alert.dep_clin_serv dcs1
                                                    INNER JOIN alert.department d1
                                                       ON d1.id_department =
                                                          dcs1.id_department
                                                    INNER JOIN alert.software_dept sd1
                                                       ON sd1.id_dept = d1.id_dept
                                                    WHERE sd1.id_software =
                                                          res.id_software
                                                      AND pdcs1.id_dep_clin_serv =
                                                          dcs1.id_dep_clin_serv))

                                   )),
                              -1)
                         ELSE
                          res.i_context

                       END id_dep_clin_serv,

                       res.id_software,
                       res.id_exam
                  FROM (SELECT i_context, id_software, id_complaint, id_exam
                          FROM (SELECT decode(ei.id_software,
                                              8,
                                              er.Id_Prof_Req,
                                              29,
                                              er.Id_Prof_Req,
                                              ei.id_dep_clin_serv) i_context,
                                       ei.id_software,
                                       ec.id_complaint,
                                       erd.id_exam
                                  FROM exam_req_det          erd,
                                       exam_req             er,
                                       epis_info            ei,
                                       alert.epis_complaint ec
                                 WHERE (ei.id_episode = er.id_episode or
                                       ei.id_episode = er.id_episode_origin)
                                   AND er.id_exam_req = erd.id_exam_req
                                   AND ei.id_episode = ec.id_episode(+)
                                   AND ei.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
                                   AND EXISTS
                                 (SELECT 1
                                          FROM episode e
                                         WHERE dt_begin_tstz > SYSDATE - 365
                                           AND id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                           AND ei.id_episode = e.id_episode))) res

                ) res1
         GROUP BY id_dep_clin_serv, id_software, id_exam) c_data
 INNER JOIN alert.dep_clin_serv dcs
    ON dcs.id_dep_clin_serv = c_data.id_dep_clin_serv
 INNER JOIN alert.clinical_service cs
    ON cs.id_clinical_service = dcs.id_clinical_service
 INNER JOIN alert.department d
    ON d.id_department = dcs.id_department
 INNER JOIN institution i
    ON i.id_institution = d.id_institution
 INNER JOIN alert.dept dpt
    ON dpt.id_dept = d.id_dept
  LEFT OUTER JOIN alert.software_dept sd
    ON sd.id_dept = dpt.id_dept
  LEFT OUTER JOIN alert.software sw
    ON sw.id_software = sd.id_software
 INNER JOIN alert.exam ex
    ON ex.id_exam = c_data.id_exam
   and ex.flg_type = 'I'
 WHERE      pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      cs.code_clinical_service)  IS NOT NULL AND
 (  (sw.id_software = c_data.id_software)
    OR (dcs.id_dep_clin_serv = -1))
      ORDER BY CNT_REQ DESC;

