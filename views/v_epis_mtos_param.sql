CREATE OR REPLACE VIEW V_EPIS_MTOS_PARAM AS
SELECT a.id_epis_mtos_score, a.id_mtos_param, a.registered_value, a.extra_score, a.id_prof_create, a.dt_create  FROM 
EPIS_MTOS_PARAM a;