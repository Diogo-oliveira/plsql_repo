DECLARE

    CURSOR c_pat_notes IS
        SELECT pn.id_pat_notes,
               pn.id_patient,
               pn.flg_status,
               pn.id_prof_writes,
               pn.id_prof_cancel,
               pn.note_cancel,
               pn.id_institution,
               pn.id_episode,
               pn.id_pat_notes_new,
               pn.dt_note_tstz,
               pn.dt_cancel_tstz,
               pn.notes,
               pn.id_cancel_reason,
               v.id_visit
          FROM pat_notes pn
          LEFT JOIN episode e ON e.id_episode = pn.id_episode
          LEFT JOIN visit v ON v.id_visit = e.id_visit
         WHERE pn.id_episode IS NOT NULL;

    l_id_pat_notes     pat_notes.id_pat_notes%TYPE;
    l_id_patient       pat_notes.id_patient%TYPE;
    l_flg_status       pat_notes.flg_status%TYPE;
    l_id_prof_writes   pat_notes.id_prof_writes%TYPE;
    l_id_prof_cancel   pat_notes.id_prof_cancel%TYPE;
    l_note_cancel      pat_notes.note_cancel%TYPE;
    l_id_institution   pat_notes.id_institution%TYPE;
    l_id_episode       pat_notes.id_episode%TYPE;
    l_id_pat_notes_new pat_notes.id_pat_notes_new%TYPE;
    l_dt_note_tstz     pat_notes.dt_note_tstz %TYPE;
    l_dt_cancel_tstz   pat_notes.dt_cancel_tstz%TYPE;
    l_notes            pat_notes.notes%TYPE;
    l_id_cancel_reason pat_notes.id_cancel_reason%TYPE;
    l_visit            visit.id_visit%TYPE;

    l_new_ft_id      pat_past_hist_free_text.id_pat_ph_ft%TYPE;
    l_new_ft_hist_id pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;

    l_relevant_notes_doc_area NUMBER := 49;
    l_flg_type                VARCHAR2(1) := 'M';
BEGIN

    OPEN c_pat_notes;
    LOOP
        --fetch all relevant notes
        FETCH c_pat_notes
            INTO l_id_pat_notes,
                 l_id_patient,
                 l_flg_status,
                 l_id_prof_writes,
                 l_id_prof_cancel,
                 l_note_cancel,
                 l_id_institution,
                 l_id_episode,
                 l_id_pat_notes_new,
                 l_dt_note_tstz,
                 l_dt_cancel_tstz,
                 l_notes,
                 l_id_cancel_reason,
                 l_visit;
        EXIT WHEN c_pat_notes%NOTFOUND;
    
        SELECT seq_pat_past_hist_free_text.nextval
          INTO l_new_ft_id
          FROM dual;
    
        -- inserts current record in free_text table
        INSERT INTO pat_past_hist_free_text
            (id_pat_ph_ft,
             text,
             id_patient,
             id_episode,
             id_visit,
             id_professional,
             dt_register,
             flg_type,
             flg_status,
             id_prof_canceled,
             dt_cancel,
             id_cancel_reason,
             cancel_notes,
             id_doc_area)
        VALUES
            (l_new_ft_id,
             l_notes,
             l_id_patient,
             l_id_episode,
             l_visit,
             l_id_prof_writes,
             l_dt_note_tstz,
             l_flg_type,
             l_flg_status,
             l_id_prof_cancel,
             l_dt_cancel_tstz,
             l_id_cancel_reason,
             l_note_cancel,
             l_relevant_notes_doc_area);
    
        IF l_flg_status = pk_alert_constant.g_cancelled
        THEN
            SELECT seq_pat_past_hist_ft_hist.nextval
              INTO l_new_ft_hist_id
              FROM dual;
        
            -- inserts previous existent record in history table
            INSERT INTO pat_past_hist_ft_hist
                (id_pat_ph_ft_hist,
                 id_pat_ph_ft,
                 text,
                 id_patient,
                 id_episode,
                 id_visit,
                 id_professional,
                 dt_register,
                 flg_type,
                 flg_status,
                 id_prof_canceled,
                 dt_cancel,
                 id_cancel_reason,
                 cancel_notes,
                 id_doc_area)
            VALUES
                (l_new_ft_hist_id,
                 l_new_ft_id,
                 l_notes,
                 l_id_patient,
                 l_id_episode,
                 l_visit,
                 l_id_prof_writes,
                 l_dt_note_tstz,
                 l_flg_type,
                 pk_alert_constant.g_active,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 l_relevant_notes_doc_area);
        END IF;
    
        SELECT seq_pat_past_hist_ft_hist.nextval
          INTO l_new_ft_hist_id
          FROM dual;
    
        -- inserts current record in history table
        INSERT INTO pat_past_hist_ft_hist
            (id_pat_ph_ft_hist,
             id_pat_ph_ft,
             text,
             id_patient,
             id_episode,
             id_visit,
             id_professional,
             dt_register,
             flg_type,
             flg_status,
             id_prof_canceled,
             dt_cancel,
             id_cancel_reason,
             cancel_notes,
             id_doc_area)
        VALUES
            (l_new_ft_hist_id,
             l_new_ft_id,
             l_notes,
             l_id_patient,
             l_id_episode,
             l_visit,
             l_id_prof_writes,
             l_dt_note_tstz,
             l_flg_type,
             l_flg_status,
             l_id_prof_cancel,
             l_dt_cancel_tstz,
             l_id_cancel_reason,
             l_note_cancel,
             l_relevant_notes_doc_area);
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(l_id_pat_notes);
END;
