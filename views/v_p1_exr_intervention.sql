CREATE OR REPLACE VIEW V_P1_EXR_INTERVENTION AS      
SELECT pei.id_exr_intervention,
       pei.id_external_request,
       pei.id_intervention,
       pei.id_interv_presc_det,
       rp.id_rehab_presc,
       pei.id_codification,
       decode(per.flg_type,'P',ipd.flg_laterality,'F', rp.flg_laterality) flg_laterality,
       nvl2((SELECT id_mcdt
              FROM mcdt_nisencao
             WHERE id_mcdt = ipd.id_intervention
               AND flg_mcdt = per.flg_type),
            'Y',
            'N') isencao,
       pk_ref_core.get_mcdt_nature(pei.id_intervention, per.flg_type) natureza_prest,
       i.barcode,
       i.code_intervention,
       pei.amount
  FROM p1_exr_intervention pei
  JOIN p1_external_request per
    ON (per.id_external_request = pei.id_external_request)
  LEFT JOIN interv_presc_det ipd
    ON (ipd.id_interv_presc_det = pei.id_interv_presc_det and per.flg_type = 'P') -- PROCEDURE
  LEFT JOIN rehab_presc rp
    ON (rp.id_rehab_presc = pei.id_rehab_presc  and per.flg_type = 'F') -- REHAB
  JOIN intervention i
    ON (i.id_intervention = ipd.id_intervention);
