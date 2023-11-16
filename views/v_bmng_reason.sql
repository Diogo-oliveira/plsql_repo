CREATE OR REPLACE VIEW v_bmng_reason AS
SELECT br.id_bmng_reason,
       br.id_bmng_reason_type,
       br.code_bmng_reason,
       br.id_institution,
       br.flg_available,
       br.flg_realocate_patient,
       br.rank
  FROM bmng_reason br;
