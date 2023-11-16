-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 03/11/2014 09:11
-- CHANGE REASON: [ALERT_290969] Nursing Care Plan: NANDA, NIC, NOC - Views
CREATE OR REPLACE VIEW V_INST_NOC_INDICATOR AS
SELECT si.id_institution,
       si.id_software,
       t.id_noc_cfg_indicator,
       t.flg_status,
       t.dt_last_update,
       t.id_noc_indicator,
       t.id_terminology_version,
       t.code_description,
       t.flg_other,
       t.id_noc_outcome,
       t.rank,
       t.id_language
  FROM software_institution si,
       TABLE(pk_noc_cfg.tf_inst_indicator(i_inst => si.id_institution, i_soft => si.id_software)) t;
/
-- CHANGE END: Ariel Machado