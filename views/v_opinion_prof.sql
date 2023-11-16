
CREATE OR REPLACE view v_opinion_prof AS
  SELECT op.id_opinion_prof,
         op.id_opinion,
         op.flg_type,
         op.id_professional,
         op.desc_reply,
         op.dt_opinion_prof_tstz,
         op.flg_face_to_face,
         op.id_cancel_reason,
         op.flg_co_sign,
         op.id_prof_co_sign,
         op.id_order_type,
         op.dt_co_sign,
         op.notes_co_sign
    FROM opinion_prof op;
