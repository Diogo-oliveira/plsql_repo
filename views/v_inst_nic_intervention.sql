-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 03/11/2014 09:11
-- CHANGE REASON: [ALERT_290969] Nursing Care Plan: NANDA, NIC, NOC - Views
CREATE OR REPLACE VIEW V_INST_NIC_INTERVENTION AS
SELECT si.id_institution,
       si.id_software,
       t.id_nic_cfg_intervention,
       t.flg_status,
       t.dt_last_update,
       t.id_nic_intervention,
       t.id_terminology_version,
       t.intervention_code,
       t.code_name,
       t.code_definition,
       t.references,
       t.id_language
  FROM software_institution si,
       TABLE(pk_nic_cfg.tf_inst_intervention(i_inst => si.id_institution, i_soft => si.id_software, i_ignore_parent_class => 'Y')) t;
/
-- CHANGE END: Ariel Machado