 CREATE OR REPLACE VIEW V_DEATH_PATIENT_PIVOT AS
SELECT *
  FROM TABLE(pivot('select id_Death_registry,  d.internal_name, xvalue
        FROM V_DEATH_PATIENT_RAW  d'));
