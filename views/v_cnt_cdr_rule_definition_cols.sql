-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-25
-- CHANGED REASON: ALERT-327582
CREATE OR REPLACE VIEW V_CNT_CDR_RULE_DEFINITION_COLS AS
SELECT d.id_cdr_definition,
       d.internal_name,
       pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      d.code_name) AS NAME,
       pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      d.code_name) AS description,
       (SELECT ct.internal_name
          FROM alert.cdr_type ct
         WHERE ct.id_cdr_type = d.id_cdr_type) AS cdr_type,
       d.flg_generic,
       d.id_content,
       d.flg_available,
       alert.pk_cnt_cdr.get_rule_cc_name(d.id_cdr_definition, 1) AS cc_name_1,
       alert.pk_cnt_cdr.get_rule_cc_name(d.id_cdr_definition, 2) AS cc_name_2,
       alert.pk_cnt_cdr.get_rule_cc_name(d.id_cdr_definition, 3) AS cc_name_3,
       alert.pk_cnt_cdr.get_rule_cc_name(d.id_cdr_definition, 4) AS cc_name_4
  FROM alert.cdr_definition d
 ORDER BY id_cdr_definition;
-- CHANGE END: Humberto Cardoso
