CREATE OR REPLACE VIEW V_SINGLE_PAGE_INDICATORS AS
SELECT e.id_episode,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 1, 'S') flg_has_hp_sign,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 1, 'D') flg_has_hp_draft,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 2, 'S') flg_has_ppn_sign,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 2, 'D') flg_has_ppn_draft,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 4, 'S') flg_has_ds_sign,
       pk_prog_notes_utils.get_single_page_indicators(e.id_episode, 4, 'D') flg_has_ds_draft,
       pk_prog_notes_utils.get_ds_dt_signoff(e.id_episode) dt_ds_signoff,
       pk_prog_notes_utils.get_ds_id_prof_signoff(e.id_episode) id_prof_ds_signoff
  FROM episode e;


