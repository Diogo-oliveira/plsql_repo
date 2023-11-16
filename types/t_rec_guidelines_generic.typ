create or replace type T_REC_GUIDELINES_GENERIC as object
(
  id_guideline_criteria_link NUMBER(24),
  link_other_crit            VARCHAR2(200 CHAR),
  link_other_crit_typ        NUMBER(24)
);
/
