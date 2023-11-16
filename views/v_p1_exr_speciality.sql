
CREATE OR REPLACE VIEW v_p1_exr_speciality AS 
SELECT p.id_speciality,
       p.code_speciality,
       rsm.id_market,
       rsm.flg_available,
       rsm.standard_code barcodde,
       pk_ref_core.get_mcdt_nature(p.id_speciality, 'C') natureza_prest,
       rsm.standard_desc desc_orig,
       rsm.standard_type spec_type
  FROM ref_spec_market rsm
  JOIN p1_speciality p
    ON p.id_speciality = rsm.id_speciality
 WHERE rsm.flg_available = 'Y'
   AND p.flg_available = 'Y';