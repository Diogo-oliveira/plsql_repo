CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CANCEL_REASON AS
SELECT desc_cancel_reason, id_cnt_cancel_reason, flg_notes_mandatory, rank, desc_reason_type, id_reason_type
  FROM (SELECT DISTINCT tt.desc_translation  AS desc_cancel_reason,
                        t.id_content         AS id_cnt_cancel_reason,
                        flg_notes_mandatory,
                        rank,
                        ttt.desc_translation AS desc_reason_type,
                        t.id_reason_type
          FROM alert.cancel_reason t
          LEFT JOIN alert.reason_type b
            ON t.id_reason_type = b.id_reason_type
           AND b.flg_available = 'Y'
          JOIN alert.v_cmt_translation_can_reas tt
            ON tt.code_translation = t.code_cancel_reason
          LEFT JOIN alert.v_cmt_translation_reason_type ttt
            ON ttt.code_translation = b.code_type)
 WHERE desc_cancel_reason IS NOT NULL
 ORDER BY 1;

