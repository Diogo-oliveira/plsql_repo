-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-25
-- CHANGED REASON: ALERT-327582
CREATE OR REPLACE VIEW V_CNT_CDR_INSTANCE AS
SELECT i.id_cdr_definition,
       pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_description) AS description_instance,
       (SELECT s.internal_name
          FROM alert.cdr_severity s
         WHERE s.id_cdr_severity = i.id_cdr_severity) AS severity,
       --i.flg_origin, usually not relevant, default = D
       i.id_content,
       i.flg_available,
       ip1.cc_name                  AS cc_name_1,
       ip1.id_element               AS id_element_1,
       ip1.validity                 AS validity_1,
       ip1.id_validity_umea         AS id_validity_umea_1,
       ip1.val_min                  AS val_min_1,
       ip1.val_max                  AS val_max_1,
       ip1.id_domain_umea           AS id_domain_umea_1,
       ip1.cdr_action               AS cdr_action_1,
       ip1.inst_param_values        AS inst_param_values_1,
       ip1.flg_first_time           AS flg_first_time_1,
       ip1.id_cdr_message           AS id_cdr_message_1,
       ip1.inst_param_action_values AS inst_param_action_values_1,
       ip2.cc_name                  AS cc_name_2,
       ip2.id_element               AS id_element_2,
       ip2.validity                 AS validity_2,
       ip2.id_validity_umea         AS id_validity_umea_2,
       ip2.val_min                  AS val_min_2,
       ip2.val_max                  AS val_max_2,
       ip2.id_domain_umea           AS id_domain_umea_2,
       ip2.cdr_action               AS cdr_action_2,
       ip2.inst_param_values        AS inst_param_values_2,
       ip2.flg_first_time           AS flg_first_time_2,
       ip2.id_cdr_message           AS id_cdr_message_2,
       ip2.inst_param_action_values AS inst_param_action_values_2,
       ip3.cc_name                  AS cc_name_3,
       ip3.id_element               AS id_element_3,
       ip3.validity                 AS validity_3,
       ip3.id_validity_umea         AS id_validity_umea_3,
       ip3.val_min                  AS val_min_3,
       ip3.val_max                  AS val_max_3,
       ip3.id_domain_umea           AS id_domain_umea_3,
       ip3.cdr_action               AS cdr_action_3,
       ip3.inst_param_values        AS inst_param_values_3,
       ip3.flg_first_time           AS flg_first_time_3,
       ip3.id_cdr_message           AS id_cdr_message_3,
       ip3.inst_param_action_values AS inst_param_action_values_3,
       ip4.cc_name                  AS cc_name_4,
       ip4.id_element               AS id_element_4,
       ip4.validity                 AS validity_4,
       ip4.id_validity_umea         AS id_validity_umea_4,
       ip4.val_min                  AS val_min_4,
       ip4.val_max                  AS val_max_4,
       ip4.id_domain_umea           AS id_domain_umea_4,
       ip4.cdr_action               AS cdr_action_4,
       ip4.inst_param_values        AS inst_param_values_4,
       ip4.flg_first_time           AS flg_first_time_4,
       ip4.id_cdr_message           AS id_cdr_message_4,
       ip4.inst_param_action_values AS inst_param_action_values_4,
       i.id_cdr_instance,
       ip1.id_cdr_inst_param        AS id_cdr_inst_param_1,
       ip1.id_cdr_inst_par_action   AS id_cdr_inst_par_action_1,
       ip2.id_cdr_inst_param        AS id_cdr_inst_param_2,
       ip2.id_cdr_inst_par_action   AS id_cdr_inst_par_action_2,
       ip3.id_cdr_inst_param        AS id_cdr_inst_param_3,
       ip3.id_cdr_inst_par_action   AS id_cdr_inst_par_action_3,
       ip4.id_cdr_inst_param        AS id_cdr_inst_param_4,
       ip4.id_cdr_inst_par_action   AS id_cdr_inst_par_action_4
  FROM alert.cdr_instance i
  LEFT OUTER JOIN alert.v_cnt_cdr_instance_parameter ip1
    ON ip1.id_cdr_instance = i.id_cdr_instance
   AND ip1.parameter_position = 1
  LEFT OUTER JOIN alert.v_cnt_cdr_instance_parameter ip2
    ON ip2.id_cdr_instance = i.id_cdr_instance
   AND ip2.parameter_position = 2
  LEFT OUTER JOIN alert.v_cnt_cdr_instance_parameter ip3
    ON ip3.id_cdr_instance = i.id_cdr_instance
   AND ip3.parameter_position = 3
  LEFT OUTER JOIN alert.v_cnt_cdr_instance_parameter ip4
    ON ip4.id_cdr_instance = i.id_cdr_instance
   AND ip4.parameter_position = 4;
-- CHANGE END: Humberto Cardoso
