-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 03/11/2014 09:11
-- CHANGE REASON: [ALERT_290969] Nursing Care Plan: NANDA, NIC, NOC - Views
CREATE OR REPLACE VIEW V_INST_NOC_OUTCOME AS
SELECT si.id_institution,
       si.id_software,
       t.id_noc_cfg_outcome,
       t.flg_status,
       t.dt_last_update,
       t.id_noc_outcome,
       t.id_terminology_version,
       t.outcome_code,
       t.code_name,
       t.code_definition,
       t.references,
       t.id_noc_class,
       t.id_language
  FROM software_institution si,
       TABLE(pk_noc_cfg.tf_inst_outcome(i_inst => si.id_institution, i_soft => si.id_software)) t;
/
-- CHANGE END: Ariel Machado