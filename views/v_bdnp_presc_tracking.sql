CREATE OR REPLACE VIEW V_BDNP_PRESC_TRACKING AS
SELECT id_presc_tracking,
       id_presc,
       flg_presc_type,
       dt_presc_tracking,
       dt_event,
       flg_event_type,
       id_prof_event,
       id_bdnp_message,
       flg_message_type,
       desc_interf_message,
       id_institution
  FROM bdnp_presc_tracking;
