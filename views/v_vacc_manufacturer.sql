CREATE OR REPLACE VIEW V_VACC_MANUFACTURER  AS
SELECT id_vacc_manufacturer, code_vacc_manufacturer, code_mvx, flg_available, rank, id_content
  FROM vacc_manufacturer vm;
