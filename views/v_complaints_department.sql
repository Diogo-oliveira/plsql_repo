CREATE OR REPLACE VIEW V_COMPLAINTS_DEPARTMENT AS 
SELECT a.*,
       row_number() over(PARTITION BY a.id_complaint, id_complaint_alias, a.id_department ORDER BY a.id_complaint) rid --,    
  FROM (SELECT DISTINCT c.id_complaint,
                        c.code_complaint,
                        c.rank,
                        cis.flg_gender,
                        cis.age_min,
                        cis.age_max,
                        cdcs.rank rank2,
                        d.id_institution,
                        cdcs.id_software,
                        dcs.id_department,
                        dcs.id_clinical_service,
                        cdcs.id_dep_clin_serv,
                        NULL id_complaint_alias,
                        NULL code_complaint_alias,
                        sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
                        sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
                        sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
                        sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software --,
        -- row_number() over(PARTITION BY c.id_complaint, d.id_institution, cdcs.id_software ORDER BY cdcs.rank) rid --,       
        -- profissional( ALERT_CONTEXT( 'l_prof_id'), ALERT_CONTEXT( 'l_prof_institution'), ALERT_CONTEXT( 'l_prof_software')) i_prof       
          FROM complaint c
          JOIN complaint_dep_clin_serv cdcs
            ON cdcs.id_complaint = c.id_complaint
          JOIN dep_clin_serv dcs
            ON cdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
          JOIN dept da
            ON d.id_dept = da.id_dept
          JOIN software_dept sa
            ON sa.id_dept = da.id_dept
          JOIN complaint_inst_soft cis
            ON cdcs.id_complaint = cis.id_complaint
           AND cdcs.id_software = cis.id_software
         WHERE c.flg_available = 'Y'
           AND cdcs.flg_available = 'Y'
           AND cis.flg_available = 'Y'
           AND d.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
           AND sa.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')
        UNION ALL
        SELECT DISTINCT c.id_complaint,
                        ca.code_complaint_alias,
                        c.rank,
                        cis.flg_gender,
                        cis.age_min,
                        cis.age_max,
                        cdcs.rank rank2,
                        d.id_institution,
                        cdcs.id_software,
                        dcs.id_department,
                        dcs.id_clinical_service,
                        cdcs.id_dep_clin_serv,
                        ca.id_complaint_alias id_complaint_alias,
                        ca.code_complaint_alias code_complaint_alias,
                        sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
                        sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
                        sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
                        sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software --,
        --    row_number() over(PARTITION BY c.id_complaint, cdcs.id_complaint_alias, d.id_institution, cdcs.id_software ORDER BY cdcs.rank) rid --,       
        --    profissional( ALERT_CONTEXT( 'l_prof_id'), ALERT_CONTEXT( 'l_prof_institution'), ALERT_CONTEXT( 'l_prof_software')) i_prof       
          FROM complaint c
          JOIN complaint_dep_clin_serv cdcs
            ON cdcs.id_complaint = c.id_complaint
          JOIN dep_clin_serv dcs
            ON cdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
          JOIN dept da
            ON d.id_dept = da.id_dept
          JOIN software_dept sa
            ON sa.id_dept = da.id_dept
          JOIN complaint_inst_soft cis
            ON cdcs.id_complaint = cis.id_complaint
           AND cdcs.id_software = cis.id_software
          JOIN complaint_alias ca
            ON ca.id_complaint_alias = cdcs.id_complaint_alias
           AND ca.id_complaint = c.id_complaint
         WHERE c.flg_available = 'Y'
           AND cdcs.flg_available = 'Y'
           AND cis.flg_available = 'Y'
           AND d.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
           AND sa.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')) a;
