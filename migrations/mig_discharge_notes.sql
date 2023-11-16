-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 12/02/2016 12:13
-- CHANGE REASON: [ALERT-318449] Discharge instructions - change visit reason field to CLOB
DECLARE
    l_epis_complaint   table_clob;
    l_code_translation table_varchar;
    l_episode          table_number;
    l_patient          table_number;
    l_professional     table_number;
    l_dt_creation      table_varchar;
BEGIN

    dbms_output.put_line('GET COMPLAINT DATA TO IMPORT');
    SELECT 'ALERT.DISCHARGE_NOTES.EPIS_COMPLAINT.' || to_char(t.id_discharge_notes),
           t.epis_complaint,
           t.id_episode,
           t.id_patient,
           t.id_professional,
           t.dt_creation_tstz BULK COLLECT
      INTO l_code_translation, l_epis_complaint, l_episode, l_patient, l_professional, l_dt_creation
      FROM (SELECT d.id_discharge_notes,
                   d.epis_complaint,
                   d.id_episode,
                   d.id_patient,
                   d.id_professional,
                   d.dt_creation_tstz,
                   row_number() over(PARTITION BY id_episode ORDER BY dt_creation_tstz DESC) row_number
              FROM discharge_notes d
             WHERE d.epis_complaint IS NOT NULL
               AND NOT EXISTS (SELECT 1
                      FROM translation_trs tt
                     WHERE tt.code_translation = d.code_epis_complaint)) t
     WHERE t.row_number = 1;

    dbms_output.put_line('IMPORT COMPLAINT DATA INTO TRANSLATION_TRS');
    FOR i IN 1 .. l_code_translation.count
    LOOP
        pk_translation.insert_translation_trs(i_lang         => NULL,
                                              i_code         => l_code_translation(i),
                                              i_desc         => l_epis_complaint(i),
                                              i_module       => 'PFH',
                                              i_episode      => l_episode(i),
                                              i_patient      => l_patient(i),
                                              i_professional => l_professional(i),
                                              i_dt_record    => l_dt_creation(i),
                                              i_task_type    => 5);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('NO DATA TO IMPORT');
    
    WHEN OTHERS THEN
        dbms_output.put_line('THE FOLLOWING ERROR OCCURRED:' || chr(13) || SQLERRM);
END;
/
-- CHANGE END: Vanessa Barsottelli