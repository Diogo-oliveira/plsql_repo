-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 18/02/2013
-- CHANGE REASON: [ALERT-251739]
DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    PROCEDURE do_my_validation IS
        /* Declarations */
        e_has_findings EXCEPTION;
        l_not_mig_care_plan_task table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_CARE_PLAN_TASK = ' || mig_data.id_care_plan_task || ' ID_ITEM = ' || mig_data.id_item BULK COLLECT
          INTO l_not_mig_care_plan_task
          FROM (SELECT cpt.id_care_plan_task,
                       cpt.id_item,
                       to_number(substr(cpt.id_item, 1, instr(cpt.id_item, '|') - 1)) AS id_analysis,
                       to_number(substr(cpt.id_item, instr(cpt.id_item, '|') + 1)) AS id_sample_type
                  FROM care_plan_task cpt
                 WHERE id_task_type = 11) mig_data
         WHERE instr(mig_data.id_item, '|') = 0
            OR (NOT EXISTS (SELECT *
                   FROM analysis_sample_type_mig astm
                  WHERE astm.id_analysis = mig_data.id_analysis
                    AND astm.id_sample_type = mig_data.id_sample_type) AND NOT EXISTS
                (SELECT *
                   FROM analysis a
                  WHERE a.id_analysis = mig_data.id_analysis
                    AND nvl(a.id_sample_type, -1) = nvl(mig_data.id_sample_type, -1)));
    
        IF l_not_mig_care_plan_task.exists(1)
           AND l_not_mig_care_plan_task.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_not_mig_care_plan_task.first .. l_not_mig_care_plan_task.last
            LOOP
            
                log_error('BAD VALUE: ' || l_not_mig_care_plan_task(i));
            END LOOP;
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
-- CHANGE END: Tiago Silva
