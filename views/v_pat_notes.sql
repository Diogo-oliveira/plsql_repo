CREATE OR REPLACE VIEW V_PAT_NOTES AS
SELECT ft.id_pat_ph_ft id_pat_notes,
       ft.id_patient id_patient,
       ft.flg_status flg_status,
       ft.id_professional id_prof_writes,
       ft.id_prof_canceled id_prof_cancel,
       ft.cancel_notes note_cancel,
       e.id_institution,
       ft.id_episode,
       null id_pat_notes_new,
       ft.dt_register dt_note_tstz,
       dt_cancel_tstz,
       ft.text notes,
       ft.id_cancel_reason
  FROM pat_past_hist_free_text ft
  LEFT JOIN episode e ON e.id_episode = ft.id_episode
  WHERE ft.id_doc_area = 49;