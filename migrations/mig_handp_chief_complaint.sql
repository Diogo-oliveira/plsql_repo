-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/10/2013 
-- CHANGE REASON: [ALERT-262351 INP Nurse simplified profile
DECLARE
    l_id_epis_anamnesis   epis_anamnesis.id_epis_anamnesis%TYPE;
    l_rows_out            table_varchar;
    l_error               t_error_out;
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
BEGIN
    FOR rec IN (SELECT e.*, epn.id_episode, epi.id_institution, epn.id_software, nvl(il.id_language, 2) id_language
                  FROM epis_pn_det e
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = e.id_epis_pn
                  JOIN episode epi
                    ON epi.id_episode = epn.id_episode
                  LEFT OUTER JOIN institution_language il
                    ON epi.id_institution = il.id_institution
                 WHERE e.id_pn_data_block = 48
                   AND e.flg_status = 'A'
                   AND NOT EXISTS (SELECT 1
                          FROM epis_anamnesis ea
                         WHERE dbms_lob.compare(ea.desc_epis_anamnesis, e.pn_note) = 0
                           AND ea.id_episode = epn.id_episode
                           AND ea.dt_epis_anamnesis_tstz = e.dt_pn))
    LOOP
        BEGIN
            SELECT seq_epis_anamnesis.nextval
              INTO l_id_epis_anamnesis
              FROM dual;
        
            INSERT INTO epis_anamnesis
                (id_epis_anamnesis,
                 dt_epis_anamnesis_tstz,
                 id_episode,
                 id_professional,
                 flg_type,
                 flg_temp,
                 id_institution,
                 id_software,
                 id_diagnosis,
                 flg_class,
                 flg_status,
                 id_epis_anamnesis_parent,
                 flg_edition_type,
                 desc_epis_anamnesis)
            VALUES
                (l_id_epis_anamnesis,
                 rec.dt_pn,
                 rec.id_episode,
                 rec.id_professional,
                 'C',
                 'D',
                 rec.id_institution,
                 rec.id_software,
                 NULL,
                 NULL,
                 'A',
                 NULL,
                 'N',
                 rec.pn_note)
            RETURNING ROWID BULK COLLECT INTO l_rows_out;
        
            t_data_gov_mnt.process_insert(rec.id_language,
                                          profissional(rec.id_professional, rec.id_institution, rec.id_software),
                                          'EPIS_ANAMNESIS',
                                          l_rows_out,
                                          l_error);
        
            SELECT seq_epis_pn_det_task.nextval
              INTO l_id_epis_pn_det_task
              FROM dual;
        
            INSERT INTO epis_pn_det_task
                (id_epis_pn_det_task,
                 id_epis_pn_det,
                 id_task,
                 id_task_type,
                 flg_status,
                 pn_note,
                 dt_last_update,
                 id_prof_task,
                 flg_table_origin,
                 dt_task,
                 dt_group_import,
                 flg_action,
                 dt_req_task
                 
                 )
            VALUES
                (l_id_epis_pn_det_task,
                 rec.id_epis_pn_det,
                 l_id_epis_anamnesis,
                 57,
                 'A',
                 rec.pn_note,
                 rec.dt_pn,
                 rec.id_professional,
                 NULL,
                 rec.dt_pn,
                 rec.dt_pn,
                 'S',
                 rec.dt_pn)
            RETURNING ROWID BULK COLLECT INTO l_rows_out;
        
            t_data_gov_mnt.process_insert(i_lang       => rec.id_language,
                                          i_prof       => profissional(rec.id_professional,
                                                                       rec.id_institution,
                                                                       rec.id_software),
                                          i_table_name => 'EPIS_PN_DET_TASK',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('mig_handp chief complaint l_id_epis_pn: ' || rec.id_epis_pn);
        END;
    END LOOP;
END;
/
--Change end: Sofia Mendes
