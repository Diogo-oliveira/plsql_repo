CREATE OR REPLACE VIEW ME_MED_PHARM_GROUP_PT AS 
SELECT DISTINCT
       TO_CHAR(IE.EMB_ID) EMB_ID,
       DECODE(IC.LEVEL_NUM,
              4,
              pk_prescription.GET_ID_PARENT(1, IC.CFT_ID),
              5,
              pk_prescription.GET_ID_PARENT(1, pk_prescription.GET_ID_PARENT(1, IC.CFT_ID)),
              IC.CFT_ID) GROUP_ID,
       DECODE(IC.LEVEL_NUM,
              3,
              pk_prescription.GET_ID_PARENT(1, IC.CFT_ID),
              4,
              pk_prescription.GET_ID_PARENT(1, pk_prescription.GET_ID_PARENT(1, IC.CFT_ID)),
              5,
              pk_prescription.GET_ID_PARENT(1, pk_prescription.GET_ID_PARENT(1, pk_prescription.GET_ID_PARENT(1, IC.CFT_ID))),
              IC.CFT_ID) GROUP_ID_L2,
			 'PT' VERS
  FROM INF_EMB IE, INF_CFT_LNK ICL, INF_CFT IC
 WHERE IE.MED_ID = ICL.MED_ID
   AND IC.CODE = ICL.CODE
   AND IC.FLG_PHARM = 'Y'
UNION ALL --PROTOCOLO DIABETES 
SELECT TO_CHAR(IE.EMB_ID) EMB_ID, 0 GROUP_ID,0 GROUP_ID_L2,
			 'PT' VERS
  FROM INF_EMB IE, INF_MED IM
 WHERE IE.MED_ID = IM.MED_ID
   AND IM.TIPO_PROD_ID = 13;