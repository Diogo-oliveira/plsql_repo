-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 29/11/2012 16:49
-- CHANGE REASON: [ALERT-246082] 
DECLARE
    -- Local variables here
    i              INTEGER;
    t_concept_code table_varchar;
    l_id_axis      icnp_term.id_axis%TYPE;
BEGIN
    -- Test statements here
    SELECT i.concept_code BULK COLLECT
      INTO t_concept_code
      FROM icnp_term i
     WHERE i.parent_code IS NOT NULL;

    FOR x IN 1 .. t_concept_code.count
    LOOP
        l_id_axis := NULL;
        SELECT it.id_axis
          INTO l_id_axis
          FROM icnp_term it
         WHERE it.concept_code = t_concept_code(x);
    
        UPDATE icnp_term it
           SET it.id_axis_parent = l_id_axis
         WHERE it.parent_code = t_concept_code(x);
    END LOOP;
END;
/
-- CHANGE END:  Nuno Neves

-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 30/11/2012 10:17
-- CHANGE REASON: [ALERT-246082] 
DECLARE
    -- Local variables here
    i              INTEGER;
    t_concept_code table_varchar;
    l_id_axis      icnp_term.id_axis%TYPE;
BEGIN
    -- Test statements here
    SELECT i.concept_code BULK COLLECT
      INTO t_concept_code
      FROM icnp_term i
     WHERE i.parent_code IS NOT NULL;

    FOR x IN 1 .. t_concept_code.count
    LOOP
        l_id_axis := NULL;
        SELECT it.id_axis
          INTO l_id_axis
          FROM icnp_term it
         WHERE it.concept_code = t_concept_code(x);
    
        UPDATE icnp_term it
           SET it.id_axis_parent = l_id_axis
         WHERE it.parent_code = t_concept_code(x);
    END LOOP;
END;
/
-- CHANGE END:  Nuno Neves