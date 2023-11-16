-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-25
-- CHANGED REASON: ALERT-327582
CREATE OR REPLACE VIEW V_CNT_CDR_RULE_DEFINITION_ROWS AS
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
       --Gets the relative position of CONDITION/CONCEPT in the rule
       --RETURNS -1 if the conceiton or concept are not available
       CASE
         WHEN c.flg_available = 'N' THEN
          -1
         WHEN cc.flg_available = 'N' THEN
          -1
         ELSE
          row_number()
          over(PARTITION BY dc.id_cdr_definition ORDER BY dc.rank,
               dc.id_cdr_def_cond)
       END AS position,
       dc.rank AS condition_rank,
       dc.id_cdr_def_cond,
       dc.flg_condition,
       dc.flg_deny,
       c.internal_name AS condition_internal_name,
       c.flg_available AS condition_flg_available,
       p.rank AS parameter_rank,
       p.id_cdr_parameter,
       cc.internal_name AS concept_internal_name,
       cc.flg_available AS concept_flg_available
  FROM alert.cdr_definition d
  JOIN alert.cdr_def_cond dc
    ON dc.id_cdr_definition = d.id_cdr_definition
  JOIN alert.cdr_condition c
    ON c.id_cdr_condition = dc.id_cdr_condition
  JOIN alert.cdr_parameter p
    ON p.id_cdr_def_cond = dc.id_cdr_def_cond
  JOIN alert.cdr_concept cc
    ON cc.id_cdr_concept = p.id_cdr_concept
 ORDER BY d.id_cdr_definition, position, condition_rank;
-- CHANGE END: Humberto Cardoso
