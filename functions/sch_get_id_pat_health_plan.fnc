CREATE OR REPLACE FUNCTION sch_get_id_pat_health_plan
(
    i_id_schedule    sch_group.id_schedule%TYPE,
    i_id_patient     sch_group.id_patient%TYPE,
    i_id_health_plan sch_group.id_health_plan%TYPE
) RETURN pat_health_plan.id_pat_health_plan%TYPE DETERMINISTIC IS
    l_ret pat_health_plan.id_pat_health_plan%TYPE;
    -- 08-04-2014 Telmo 
    -- Esta funcao calcula o id_pat_health_plan a partir de id_schedule, id_patient e id_health_plan.
    -- Criada para ser usada pela nova coluna virtual sch_group.id_pat_health_plan.
BEGIN
    -- optimization. No point running the main query without this value. 
    --The other 2 param values are guaranteed to exist due to sch_group constraints.
    IF i_id_health_plan IS NULL
    THEN
        RETURN NULL;
    END IF;

    SELECT id_pat_health_plan
      INTO l_ret
      FROM (SELECT id_pat_health_plan, decode(p.flg_default, 'Y', 0, 1) in_use
              FROM pat_health_plan p
             WHERE p.id_patient = i_id_patient
               AND p.id_health_plan = i_id_health_plan
               AND p.id_institution = (SELECT id_instit_requested
                                         FROM schedule s
                                        WHERE s.id_schedule = i_id_schedule)
                  
               AND p.flg_status = 'A'
             ORDER BY in_use)
     WHERE rownum = 1;

    RETURN l_ret;

EXCEPTION
    WHEN no_data_found THEN
        RETURN NULL;
END;
/
