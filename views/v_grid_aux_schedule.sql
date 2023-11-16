CREATE OR REPLACE VIEW V_GRID_AUX_SCHEDULE AS
SELECT epis.id_episode,
       --JM 29/08/08 In case schedule_intervention is used instead of schedule_outp
       --trunc(SP1.DT_TARGET) dt_target,
       --SP1.ID_SOFTWARE,
       nvl(trunc(sp1.dt_target_tstz),
           trunc((SELECT ipp.dt_plan_tstz
                   FROM interv_presc_plan ipp
                  WHERE ipp.id_schedule_intervention = si.id_schedule_intervention))) dt_target,
       nvl(sp1.id_software,
           (SELECT VALUE
              FROM sys_config
             WHERE id_sys_config = 'SOFTWARE_ID_PHISIOTERAPY')) id_software,
       ei1.id_instit_requested,
       gt.drug_transp desc_drug_req,
       gt.harvest desc_harvest,
       gt.movement desc_mov,
       gt.clin_rec_transp desc_cli_rec_req,
       gt.supplies desc_supplies
  FROM epis_info ei1,
       schedule_outp sp1,
       schedule_intervention si,
       grid_task gt,
       (SELECT DISTINCT id_episode
          FROM (SELECT d.id_episode
                  FROM drug_req d, sys_domain s, drug_req_det dt, drug_req_supply ds
                 WHERE d.flg_status NOT IN ('C', 'F')
                   AND dt.id_drug_req = d.id_drug_req
                   AND ds.id_drug_req_det = dt.id_drug_req_det
                   AND ds.flg_status IN ('O', 'T')
                   AND ds.flg_status = s.val
                   AND s.code_domain = 'DRUG_REQ_SUPPLY.FLG_STATUS'
                UNION ALL
                SELECT h.id_episode
                  FROM harvest h, sys_domain s
                 WHERE h.flg_status IN ('H')
                   AND h.flg_status = s.val
                   AND s.code_domain = 'HARVEST.FLG_STATUS'
                UNION
                SELECT mov.id_episode
                  FROM movement mov, sys_domain s
                 WHERE mov.flg_status NOT IN ('C', 'F', 'S')
                   AND mov.flg_status = s.val
                   AND s.code_domain = 'MOVEMENT.FLG_STATUS'
                UNION ALL
                SELECT c.id_episode
                  FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd, cli_rec_req_mov cm
                 WHERE c.flg_status NOT IN ('C', 'F')
                   AND cd.id_cli_rec_req = c.id_cli_rec_req
                   AND cm.id_cli_rec_req_det = cd.id_cli_rec_req_det
                   AND cm.flg_status IN ('O', 'T')
                   AND cm.flg_status = s.val
                   AND s.code_domain = 'CLI_REC_REQ_MOV.FLG_STATUS')) epis
 WHERE ei1.id_episode = epis.id_episode
   AND gt.id_episode(+) = epis.id_episode
   AND ei1.flg_sch_status != 'C'
   AND ei1.id_schedule = sp1.id_schedule(+)
   AND ei1.id_schedule = si.id_schedule(+)
;
/