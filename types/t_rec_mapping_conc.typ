CREATE OR REPLACE TYPE t_rec_mapping_conc AS OBJECT
(
    source_coordinated_expr VARCHAR2(1000 CHAR),
    id_target_map_concept   NUMBER(24),
    target_map_concept_desc VARCHAR2(1000 CHAR),
    map_priority            NUMBER(6)
);
/


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 05/05/2011
-- CHANGE REASON: [ALERT-176623] CDAs: Allergies correction
drop type t_rec_mapping_conc;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 05/05/2011
-- CHANGE REASON: [ALERT-176623] CDAs: Allergies correction
CREATE OR REPLACE TYPE t_rec_mapping_conc AS OBJECT
(
    source_coordinated_expr VARCHAR2(1000 CHAR),
    target_coordinated_expr VARCHAR2(1000 CHAR),
    target_map_concept_desc VARCHAR2(1000 CHAR),
    map_priority            NUMBER(6)
);
/