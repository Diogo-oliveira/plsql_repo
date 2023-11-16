-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 18/02/2013
-- CHANGE REASON: [ALERT-251739]
DECLARE

    -- cursor to get all lab tests of care plan task history
    CURSOR c_care_plan_labs_hist IS
        SELECT cpth.dt_care_plan_task_hist, cpth.id_care_plan_task, cpth.id_item
          FROM care_plan_task_hist cpth
         WHERE cpth.id_task_type = 11 -- lab tests
           AND instr(cpth.id_item, '|') = 0
         ORDER BY cpth.dt_care_plan_task_hist;

    l_new_id_analysis analysis.id_analysis%TYPE;
    l_id_sample_type  sample_type.id_sample_type%TYPE;

    -- get new lab test id and corresponding specimen/sample type
    PROCEDURE get_mig_lab_test
    (
        in_old_lab_test  IN analysis.id_analysis%TYPE,
        out_new_lab_test OUT analysis.id_analysis%TYPE,
        out_sample_type  OUT sample_type.id_sample_type%TYPE
    ) IS
    BEGIN
    
        BEGIN
        
            -- migrated lab tests
            SELECT id_analysis, id_sample_type
              INTO out_new_lab_test, out_sample_type
              FROM analysis_sample_type_mig
             WHERE id_analysis_legacy = in_old_lab_test;
        
        EXCEPTION
            WHEN no_data_found THEN
            
                -- not migrated lab tests
                SELECT id_analysis, id_sample_type
                  INTO out_new_lab_test, out_sample_type
                  FROM analysis
                 WHERE id_analysis = in_old_lab_test;
        END;
    
    END get_mig_lab_test;
BEGIN

    -- update all care plan lab test tasks history records
    FOR rec IN c_care_plan_labs_hist
    LOOP
    
        dbms_output.put_line('Processing care plan task history [dt_care_plan_task_hist=' ||
                             rec.dt_care_plan_task_hist || ', id_care_plan_task=' || rec.id_care_plan_task ||
                             ', id_item=' || rec.id_item || ']...');
    
        -- get new lab test id and corresponding specimen/sample type
        get_mig_lab_test(in_old_lab_test  => to_number(rec.id_item),
                         out_new_lab_test => l_new_id_analysis,
                         out_sample_type  => l_id_sample_type);
    
        -- update care plan task history record with id_item = '<new_analysis_id>|<id_sample_type>'
        UPDATE care_plan_task_hist cpth
           SET cpth.id_item = to_char(l_new_id_analysis) || '|' || to_char(l_id_sample_type)
         WHERE cpth.dt_care_plan_task_hist = rec.dt_care_plan_task_hist
           AND cpth.id_care_plan_task = rec.id_care_plan_task;
    
    END LOOP;

END;
/
-- CHANGE END: Tiago Silva
