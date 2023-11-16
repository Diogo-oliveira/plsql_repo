CREATE OR REPLACE VIEW v_cdr_event AS
SELECT ce.id_cdr_call,
       ce.id_cdr_inst_par_action,
       ce.flg_hidden,
       ce.flg_session,
       ce.id_prof_answer,
       ce.dt_answer,
       ce.flg_answer,
       ce.notes_answer,
       ce.id_cdr_answer,
       ce.id_cdr_event,
       ce.id_cdr_external,
       ce.domain_value,
       ce.domain_free_text
  FROM cdr_event ce;
