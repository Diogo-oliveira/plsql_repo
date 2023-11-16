CREATE OR REPLACE VIEW v_p1_exr_exam (
  id_exr_exam,
  id_external_request,
  id_exam,
  id_exam_req_det,
  id_codification,
  flg_laterality,
  isencao,
  natureza_prest,
  barcode,
  code_exam,
  amount
) AS
SELECT pee.id_exr_exam,
       pee.id_external_request,
       pee.id_exam,
       pee.id_exam_req_det,
       pee.id_codification,
       erd.flg_laterality,
       nvl2((SELECT id_mcdt
              FROM mcdt_nisencao
             WHERE id_mcdt = pee.id_exam
               AND flg_mcdt = per.flg_type),
            'Y',
            'N') isencao,
       pk_ref_core.get_mcdt_nature(pee.id_exam, per.flg_type) natureza_prest,
       ec.standard_code barcode,
       'EXAM.CODE_EXAM.' || pee.id_exam code_exam,
       pee.amount
  FROM p1_exr_exam pee
  JOIN exam_req_det erd
    ON (pee.id_exam_req_det = erd.id_exam_req_det)
  JOIN p1_external_request per
    ON (per.id_external_request = pee.id_external_request)
  LEFT JOIN exam_codification ec
    ON (ec.id_codification = pee.id_codification AND ec.id_exam = pee.id_exam)
   AND ec.flg_available = 'Y';
