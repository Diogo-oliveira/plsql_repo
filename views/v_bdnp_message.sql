CREATE OR REPLACE VIEW V_BDNP_MESSAGE AS
SELECT id_bdnp_message, code_bdnp_message, flg_type, flg_presc_type, flg_available
  FROM bdnp_message;
