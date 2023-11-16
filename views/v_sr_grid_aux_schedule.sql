CREATE OR REPLACE VIEW ALERT.V_SR_GRID_AUX_SCHEDULE AS
SELECT EPIS.ID_EPISODE, trunc(SP1.DT_TARGET_TSTZ) dt_target,  2 ID_SOFTWARE , S1.ID_INSTIT_REQUESTED,
GT.DRUG_TRANSP DESC_DRUG_REQ,
GT.HARVEST desc_harvest,
GT.MOVEMENT DESC_MOV,
GT.CLIN_REC_TRANSP DESC_CLI_REC_REQ
FROM SCHEDULE S1, EPIS_INFO EI1,  SCHEDULE_sr SP1, GRID_TASK GT, 
         (select distinct id_episode from (
                                           SELECT D.ID_EPISODE
                                           FROM DRUG_REQ D, SYS_DOMAIN S, DRUG_REQ_DET DT, DRUG_REQ_SUPPLY DS
                                           WHERE D.FLG_STATUS NOT IN ('C', 'F')
                                           AND DT.ID_DRUG_REQ = D.ID_DRUG_REQ
                                           AND DS.ID_DRUG_REQ_DET = DT.ID_DRUG_REQ_DET
                                           AND DS.FLG_STATUS IN ('O', 'T')
                                           AND DS.FLG_STATUS = S.VAL
                                           AND S.CODE_DOMAIN = 'DRUG_REQ_SUPPLY.FLG_STATUS'
                                           union all
                                           SELECT H.ID_EPISODE
                                           FROM HARVEST H, SYS_DOMAIN S
                                           WHERE H.FLG_STATUS IN ('H')
                                           AND H.FLG_STATUS = S.VAL
                                           AND S.CODE_DOMAIN = 'HARVEST.FLG_STATUS'
                                           union
                                           SELECT MOV.ID_EPISODE
                                           FROM MOVEMENT MOV, SYS_DOMAIN S
                                           WHERE MOV.FLG_STATUS NOT IN ('C', 'F', 'S')
                                           AND MOV.FLG_STATUS = S.VAL
                                           AND S.CODE_DOMAIN = 'MOVEMENT.FLG_STATUS'
                                           union all
                                           SELECT C.ID_EPISODE
                                           FROM CLI_REC_REQ C, SYS_DOMAIN S, CLI_REC_REQ_DET CD, CLI_REC_REQ_MOV CM
                                           WHERE C.FLG_STATUS NOT IN ('C', 'F')
                                           AND CD.ID_CLI_REC_REQ = C.ID_CLI_REC_REQ
                                           AND CM.ID_CLI_REC_REQ_DET = CD.ID_CLI_REC_REQ_DET
                                           AND CM.FLG_STATUS IN ('O', 'T')
                                            AND CM.FLG_STATUS = S.VAL
                                           AND S.CODE_DOMAIN = 'CLI_REC_REQ_MOV.FLG_STATUS'  )) epis
WHERE EI1.ID_EPISODE = EPIS.ID_EPISODE
AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE
AND SP1.ID_EPISODE = EPIS.ID_EPISODE
AND ei1.FLG_SCH_STATUS != 'C'
AND S1.ID_SCHEDULE = SP1.ID_SCHEDULE;
/
