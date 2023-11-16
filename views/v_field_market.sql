CREATE OR REPLACE VIEW v_field_market AS
SELECT id_field_market, id_field, id_market, fill_type, flg_available
  FROM field_market;