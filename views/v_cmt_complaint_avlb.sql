CREATE OR REPLACE VIEW V_CMT_COMPLAINT_AVLB AS
WITH tmp_complaint AS
 (SELECT /*+ MATERIALIZED */
   desc_complaint, id_complaint, id_cnt_complaint
    FROM v_cmt_complaint),
tmp_complaint_alias AS
 (SELECT /*+ MATERIALIZED */
   desc_complaint_alias, id_complaint_alias, id_cnt_complaint_alias, id_complaint
    FROM v_cmt_complaint_alias)
SELECT DISTINCT desc_complaint,
                desc_complaint_alias   AS desc_alias,
                age_min,
                age_max,
                flg_gender             AS gender,
                id_complaint,
                id_cnt_complaint,
                id_complaint_alias,
                id_cnt_complaint_alias,
                rank
  FROM (SELECT c.desc_complaint,
               a.desc_complaint_alias,
               si.age_max,
               si.age_min,
               si.flg_gender,
               c.id_complaint,
               c.id_cnt_complaint,
               a.id_complaint_alias,
               a.id_cnt_complaint_alias,
               si.rank
          FROM tmp_complaint c
          JOIN complaint_inst_soft si
            ON si.id_complaint = c.id_complaint
           AND si.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND si.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
          LEFT JOIN tmp_complaint_alias a
            ON a.id_complaint = si.id_complaint
           AND a.id_complaint_alias = si.id_complaint_alias)
 ORDER BY desc_complaint;
