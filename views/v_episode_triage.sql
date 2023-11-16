-->V_EPISODE_TRIAGE
CREATE OR REPLACE VIEW V_EPISODE_TRIAGE AS
SELECT id_epis_triage,
       id_episode,
       id_professional,
       id_room,
       dt_begin_tstz,
       dt_end_tstz,
       pain_scale,
       et.id_triage_color,
       code_triage_color,
       et.id_triage,
       t.id_triage_board,
       code_triage_board,
       t.id_triage_discriminator,
       code_triage_discriminator,
       fti.id_fast_track,
       fti.id_institution fti_id_institution,
       code_fast_track,
       twr.id_triage_white_reason,
       twr.code_triage_white_reason,
	   et.id_triage_nurse,
       et.flg_letter,
       et.notes,
       et.id_necessity,
       et.id_origin,
       et.id_epis_anamnesis,
       et.desc_origin,
       et.id_triage_color_orig,
       et.id_transp_entity,
       et.flg_selected_option,
       et.emergency_contact
  FROM epis_triage            et,
       triage_color           tc,
       triage                 t,
       triage_board           tb,
       triage_discriminator   td,
       fast_track_institution fti,
       fast_track             ft,
       triage_white_reason    twr
 WHERE et.id_triage_color = tc.id_triage_color
   AND t.id_triage(+) = et.id_triage
   AND t.id_triage_board = tb.id_triage_board(+)
   AND td.id_triage_discriminator(+) = t.id_triage_discriminator
   AND et.id_triage = fti.id_triage(+)
   AND twr.id_triage_white_reason(+) = et.id_triage_white_reason
   AND fti.id_fast_track = ft.id_fast_track(+);
