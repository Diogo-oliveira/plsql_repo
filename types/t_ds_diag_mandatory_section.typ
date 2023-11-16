-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 17/05/2018 11:00
-- CHANGE REASON: [EMR-280]
CREATE OR REPLACE TYPE t_ds_diag_mandatory_section FORCE AS OBJECT
(
    id_diagnosis       NUMBER(24),
    id_alert_diagnosis  NUMBER(24),
    id_ds_cmpt_mkt_rel  NUMBER(24)
)
;
/
-- CHANGE END: Diogo Oliveira