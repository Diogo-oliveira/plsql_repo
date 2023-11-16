-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2009-JUN-26
-- CHANGED REASON: ALERT-32888
CREATE OR REPLACE VIEW V_REF_PAT AS
SELECT distinct exr.id_patient,
       php.num_health_plan n_sns,
       m.sequential_number,
       cr.num_clin_record, 
			 exr.id_inst_dest,
       p.name,
       p.gender,
       p.dt_birth,
			 psa.marital_status,			 
			 pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, 1) desc_marital_status,
       cn.ALPHA2_CODE code_country_nation,
       pk_translation.get_translation(1, cn.code_country) desc_country_nation,
       psa.address,
       psa.zip_code,
       psa.location,
       psa.district,
       ca.ALPHA2_CODE code_country_address,
       pk_translation.get_translation(1, ca.code_country) desc_country_address,
       NULL nics,	
			 pca.id_recm,
			 pk_translation.get_translation(1, recm.code_recm) desc_recm,
			 i.id_isencao,
			 pk_translation.get_translation(1, i.code_isencao) desc_isencao
  FROM p1_external_request exr  
  JOIN patient p ON (exr.id_patient = p.id_patient)
	left join pat_cli_attributes pca on (pca.id_patient = p.id_patient and  pca.id_institution = exr.id_inst_orig)
  left join recm on (recm.id_recm = pca.id_recm)
  LEFT JOIN pat_soc_attributes psa ON (psa.id_patient = p.id_patient AND psa.id_institution = 0)
  LEFT join isencao i on (i.id_isencao = psa.id_isencao)
  LEFT JOIN country cn ON (cn.id_country = psa.id_country_nation AND cn.flg_available = 'Y')
  LEFT JOIN country ca ON (ca.id_country = psa.id_country_address AND ca.flg_available = 'Y')
  LEFT JOIN pat_health_plan php ON (php.id_patient = p.id_patient AND php.id_institution IS NULL AND
                                   php.flg_status = 'A' AND
                                   php.id_health_plan =
                                   to_number(pk_sysconfig.get_config('IDENT_ID_HEALTH_PLAN',
                                                                      profissional(NULL, exr.id_inst_dest, NULL))))
  LEFT JOIN clin_record cr ON (cr.id_patient = p.id_patient AND cr.id_institution = exr.id_inst_dest AND
                              cr.flg_status = 'A')
  LEFT JOIN p1_match m ON (p.id_patient = m.id_patient AND m.id_institution = exr.id_inst_dest AND m.flg_status = 'A');
-- CHANGE END: Ana Monteiro

COMMENT ON TABLE V_REF_PAT IS 'Patient data of referrals processed by SIGLIC'
/

COMMENT ON COLUMN V_REF_PAT.ID_PATIENT IS 'Chave primaria'
/

COMMENT ON COLUMN V_REF_PAT.N_SNS IS 'Nº do plano de saúde'
/

COMMENT ON COLUMN V_REF_PAT.NUM_CLIN_RECORD IS 'Nº processo clínico na instituição'
/

COMMENT ON COLUMN V_REF_PAT.NAME IS 'Nome do paciente'
/

COMMENT ON COLUMN V_REF_PAT.GENDER IS 'Sexo. F - feminino, M - masculino, NULL - deconhecido, I - indeterminado'
/

COMMENT ON COLUMN V_REF_PAT.DT_BIRTH IS 'Data de nascimento'
/

COMMENT ON COLUMN V_REF_PAT.LOCATION IS 'Localidade'
/