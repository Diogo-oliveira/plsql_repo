CREATE OR REPLACE VIEW V_COMPLAINTS AS 
SELECT a.*,
       row_number() over(PARTITION BY a.id_complaint, id_complaint_alias, a.id_institution, id_software ORDER BY a.id_complaint) rid --,    
  FROM (
SELECT DISTINCT c.id_complaint,
                c.code_complaint,
                c.rank,
                cis.flg_gender,
                cis.age_min,
                cis.age_max,
                cis.rank rank2,
                cis.id_institution,
                cis.id_software,
                NULL id_department,
                NULL id_clinical_service,
                NULL id_dep_clin_serv,
                NULL id_complaint_alias,
                NULL code_complaint_alias,
                sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
                sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
                sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
                sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software--,
             --   row_number() over(PARTITION BY c.id_complaint, cis.id_institution, cis.id_software ORDER BY cis.rank) rid ----,
--  profissional( ALERT_CONTEXT( 'l_prof_id'), ALERT_CONTEXT( 'l_prof_institution'), ALERT_CONTEXT( 'l_prof_software')) i_prof
  FROM complaint c
  JOIN complaint_inst_soft cis
    ON cis.id_complaint = c.id_complaint
 WHERE c.flg_available = 'Y'
   AND cis.flg_available = 'Y'
UNION ALL
SELECT DISTINCT c.id_complaint,
                ca.code_complaint_alias,
                c.rank,
                cis.flg_gender,
                cis.age_min,
                cis.age_max,
                cis.rank rank2,
                cis.id_institution,
                cis.id_software,
                NULL id_department,
                NULL id_clinical_service,
                NULL id_dep_clin_serv,
                ca.id_complaint_alias id_complaint_alias,
                ca.code_complaint_alias,
                sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
                sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
                sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
                sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software--,
            --    row_number() over(PARTITION BY c.id_complaint, cis.id_complaint_alias, cis.id_institution, cis.id_software ORDER BY cis.rank) rid ----,
--  profissional( ALERT_CONTEXT( 'l_prof_id'), ALERT_CONTEXT( 'l_prof_institution'), ALERT_CONTEXT( 'l_prof_software')) i_prof
  FROM complaint c
  JOIN complaint_inst_soft cis
    ON cis.id_complaint = c.id_complaint
  JOIN complaint_alias ca
    ON cis.id_complaint_alias = ca.id_complaint_alias
   AND ca.id_complaint = c.id_complaint
 WHERE c.flg_available = 'Y'
   AND cis.flg_available = 'Y') a ;
