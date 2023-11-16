CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CANCEL_REA_SOFT_INST AS
SELECT desc_cancel_reason,
       id_cnt_cancel_reason,
       desc_profile_template,
       id_profile_template,
       rank,
       desc_cancel_area,
       id_cancel_rea_area
  FROM (SELECT DISTINCT t.desc_translation    AS desc_cancel_reason,
                        b.id_content          AS id_cnt_cancel_reason,
                        tt.desc_translation   AS desc_profile_template,
                        a.id_profile_template,
                        a.rank,
                        d.intern_name         AS desc_cancel_area,
                        d.id_cancel_rea_area
          FROM alert.cancel_rea_soft_inst a
          JOIN alert.cancel_reason b
            ON a.id_cancel_reason = b.id_cancel_reason
          JOIN alert.profile_template c
            ON a.id_profile_template = c.id_profile_template
          JOIN alert.cancel_rea_area d
            ON a.id_cancel_rea_area = d.id_cancel_rea_area
          JOIN alert.v_cmt_translation_can_reas t
            ON t.code_translation = b.code_cancel_reason
          JOIN alert.v_cmt_translation_prof_temp tt
            ON tt.code_translation = c.code_profile_template
         WHERE a.id_software IN (0, sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
           AND a.id_institution IN (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND a.flg_available = 'Y'
           AND (c.id_profile_template IN
               ((SELECT DISTINCT pt.id_profile_template
                   FROM alert.profile_template pt
                   JOIN alert.profile_template_market ptm
                     ON ptm.id_profile_template = pt.id_profile_template
                  WHERE pt.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
                    AND ptm.id_market IN ((SELECT id_market
                                            FROM alert.institution
                                           WHERE id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')),
                                          0)
                    AND pt.flg_available = 'Y')) OR c.id_profile_template = 0))
 WHERE desc_cancel_reason IS NOT NULL
 ORDER BY id_cancel_rea_area, rank, desc_cancel_reason;

