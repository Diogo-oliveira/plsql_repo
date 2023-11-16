
CREATE OR REPLACE VIEW v_p1_exr_analysis AS 
    SELECT pea.id_exr_analysis,
       pea.id_external_request,
       pea.id_analysis,
       pea.id_analysis_req_det,
       pea.id_codification,
           pea.id_sample_type,
       st.code_sample_type,
       st.id_content id_content_st,
       nvl2((SELECT id_mcdt
              FROM mcdt_nisencao
             WHERE id_mcdt = pea.id_analysis
               AND flg_mcdt = 'A'),
            'Y',
            'N') isencao,
       pk_ref_core.get_mcdt_nature(pea.id_analysis, 'A') natureza_prest,
           ac.standard_code barcode,
           'ANALYSIS.CODE_ANALYSIS.' || pea.id_analysis code_analysis,
       pea.amount
  FROM p1_exr_analysis pea
      JOIN sample_type st
        ON (st.id_sample_type = pea.id_sample_type)
      LEFT JOIN analysis_codification ac
        ON (ac.id_codification = pea.id_codification AND ac.id_analysis = pea.id_analysis)
       AND ac.flg_available = 'Y';



