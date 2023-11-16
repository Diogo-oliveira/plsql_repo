
CREATE OR REPLACE VIEW V_PRINTED_MCDT_PRESCRIPTION AS
SELECT per.id_external_request id_external_request, -- id da p1_esternal_request
       per.num_req num_req, -- num da  requisição
       per.id_prof_requested id_prof_requested, -- profissional que fez o pedido
       per.flg_type flg_type, -- tipo de referral
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_TYPE', per.flg_type, 1) type_desc,
       per.id_inst_orig id_institution, -- id da institução
       pt.dt_tracking_tstz dt_printed, -- Data do acto (impressão)
       pt.id_tracking id_tracking, --Identificador do registo transaccional ALERT
       plp.flg_payment_plan payment_plan --Tipo de pagamento (PRE,POS)
  FROM p1_external_request per
  JOIN presc_light_license plp
    ON (per.id_inst_orig = plp.id_institution AND plp.id_professional IN (0, per.id_prof_requested))
  JOIN p1_tracking pt
    ON (pt.id_external_request = per.id_external_request AND pt.flg_type = 'S' AND pt.ext_req_status = per.flg_status)
 WHERE per.id_workflow IS NULL
   AND (per.id_inst_dest = 999998 OR per.id_inst_dest IS NULL)
   AND per.flg_status = 'P';
