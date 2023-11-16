-->V_PROF_PROFILE_TEMPLATE
CREATE OR REPLACE VIEW V_PROF_PROFILE_TEMPLATE AS
SELECT id_prof_profile_template, id_professional, id_profile_template, id_software
  FROM prof_profile_template;

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-386
CREATE OR REPLACE VIEW V_PROF_PROFILE_TEMPLATE AS
SELECT id_prof_profile_template, id_professional, id_profile_template, id_software,id_institution
  FROM prof_profile_template;
  
-- CHANGE END: Telmo Castro