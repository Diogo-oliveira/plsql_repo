-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-25
-- CHANGED REASON: ALERT-327582
CREATE OR REPLACE VIEW V_CNT_CDR_INSTANCE_PARAMETER AS
SELECT ip.id_cdr_instance,
       pk_cnt_cdr.get_parameter_cc_name(ip.id_cdr_parameter) AS cc_name,
       pk_cnt_cdr.get_parameter_position(ip.id_cdr_parameter) AS parameter_position,
       ip.id_element,
       ip.validity,
       ip.id_validity_umea,
       ip.val_min,
       ip.val_max,
       ip.id_domain_umea,
       (SELECT a.internal_name
          FROM alert.cdr_action a
         WHERE a.id_cdr_action = ipa.id_cdr_action) AS cdr_action,
       --Gets the list of values associated with this INST_PARAM in table CDR_INST_PAR_VAL
       pk_cnt_cdr.get_inst_par_values(ip.id_cdr_inst_param) AS inst_param_values,
       ipa.flg_first_time,
       ipa.id_cdr_message,
       pk_cnt_cdr.get_inst_par_action_values(ipa.id_cdr_inst_par_action) AS inst_param_action_values,
       --Mandatory ID's for configuration and versioning
       ip.id_cdr_inst_param,
       ipa.id_cdr_inst_par_action
  FROM alert.cdr_inst_param ip
  LEFT OUTER JOIN alert.cdr_inst_par_action ipa
    ON ipa.id_cdr_inst_param = ip.id_cdr_inst_param;
-- CHANGE END: Humberto Cardoso
