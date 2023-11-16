-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 16/05/2011
-- CHANGE REASON: [ALERT-179277] Print tool - CDA - one allergy is not appearing correctly, we have two allergies with the same name and in the report we can see 3
CREATE OR REPLACE TYPE t_tab_allergies_cdas IS TABLE OF t_rec_allergies_cdas;
/

drop type t_tab_allergies_cdas;
/
CREATE OR REPLACE TYPE t_tab_allergies_cdas IS TABLE OF t_rec_allergies_cdas;
/