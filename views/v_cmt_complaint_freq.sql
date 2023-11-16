CREATE OR REPLACE VIEW V_CMT_COMPLAINT_FREQ AS
WITH tmp_dep_clin_serv AS
     (SELECT /*+ MATERIALIZED */
      DISTINCT c.id_dep_clin_serv, a.id_content, a.code_clinical_service, d.id_department, d.code_department
        FROM clinical_service a
        JOIN dep_clin_serv c
          ON c.id_clinical_service = a.id_clinical_service
        JOIN department d
          ON d.id_department = c.id_department
        JOIN dept de
          ON de.id_dept = d.id_dept
        JOIN software_dept sd
          ON sd.id_dept = de.id_dept
        JOIN institution i
          ON i.id_institution = d.id_institution
         AND i.id_institution = de.id_institution
       WHERE d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
         AND sd.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
         AND d.flg_available = 'Y'
         AND c.flg_available = 'Y'
         AND a.flg_available = 'Y'
         AND de.flg_available = 'Y'),
    tmp_complaint_avlb AS
     (SELECT /*+ MATERIALIZED */
       desc_complaint, desc_alias, age_min, age_max, gender, id_complaint, id_cnt_complaint
        FROM v_cmt_complaint_avlb),
    tmp_complaint_freq AS
     (SELECT /*+ MATERIALIZED */
       id_complaint, id_dep_clin_serv, id_complaint_alias, rank
        FROM complaint_dep_clin_serv
       WHERE flg_available = 'Y'
         AND id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
    tmp_complaint_alias AS
     (SELECT /*+ MATERIALIZED */
       desc_complaint_alias, id_complaint_alias, id_cnt_complaint_alias, id_complaint
        FROM v_cmt_complaint_alias)
    SELECT DISTINCT desc_complaint,
                    desc_alias,
                    id_complaint,
                    id_cnt_complaint,
                    id_complaint_alias,
                    id_cnt_complaint_alias,
                    desc_service,
                    id_service,
                    desc_clinical_service,
                    id_cnt_clinical_service,
                    id_dep_clin_serv,
                    rank
      FROM (SELECT DISTINCT c.desc_complaint,
                            a.desc_complaint_alias desc_alias,
                            c.id_complaint,
                            c.id_cnt_complaint,
                            a.id_complaint_alias,
                            a.id_cnt_complaint_alias,
                            (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                   s.code_department)
                               FROM dual) AS desc_service,
                            to_char(s.id_department) AS id_service,
                            (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                   s.code_clinical_service)
                               FROM dual) AS desc_clinical_service,
                            s.id_content AS id_cnt_clinical_service,
                            to_char(s.id_dep_clin_serv) AS id_dep_clin_serv,
                            f.rank
              FROM tmp_complaint_avlb c
              JOIN tmp_complaint_freq f
                ON f.id_complaint = c.id_complaint
              JOIN tmp_dep_clin_serv s
                ON s.id_dep_clin_serv = f.id_dep_clin_serv
              LEFT JOIN tmp_complaint_alias a
                ON a.id_complaint = f.id_complaint
               AND a.id_complaint_alias = f.id_complaint_alias)
     ORDER BY desc_complaint, desc_service, desc_clinical_service;
