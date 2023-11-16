grant select on alert.inst_attributes to alert_viewer;

-- CHANGED BY: Nuno Gomes
-- CHANGE DATE: 18-02-2014
-- CHANGE REASON: CODING-1830
grant select on alert.inst_attributes to alert_coding_tr;
-- CHANGED ENDED: Nuno Gomes

-- CHANGED BY: André Silva
-- CHANGE DATE: 24-05-2017
-- CHANGE REASON: ALERT-331158
GRANT SELECT ON inst_attributes TO alert_hie;
-- CHANGED ENDED: André Silva