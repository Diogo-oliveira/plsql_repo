

  GRANT SELECT ON ALERT.SOFTWARE TO ALERT_VIEWER;
  grant all on alert.software to aol;

  GRANT REFERENCES ON software TO alert_default;

GRANT SELECT ON ALERT.SOFTWARE TO ALERT_AT_VIEWER;


-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-07-2010
-- CHANGE REASON: APS-518
grant select on ALERT.SOFTWARE to alert_basecomp;
-- CHANGE END: Telmo Castro

-- cmf 29-03-2012
grant select on alert.software to public;