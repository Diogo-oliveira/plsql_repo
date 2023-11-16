
-->V_PROF_CATEGORY
CREATE OR REPLACE VIEW V_PROF_CATEGORY AS
SELECT pc.id_prof_cat, pc.id_professional, pc.id_institution, pc.id_category
  FROM prof_cat pc;
