-->V_PROF_PREFERENCES
CREATE OR REPLACE VIEW V_PROF_PREFERENCES AS
SELECT pp.id_prof_preferences, pp.id_professional, pp.id_institution, pp.id_software, pp.id_language
  FROM prof_preferences pp;
