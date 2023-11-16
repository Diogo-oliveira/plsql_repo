CREATE OR REPLACE VIEW PGS_NEW_PATIENT
AS
SELECT DISTINCT ps.social_security_number curp,
                p.last_name primer_apellido,
                p.middle_name segundo_appelido,
                p.first_name nombre,
                p.dt_birth fecnac,
                camx.id_rb_regional_classifier,
                DECODE(camx.id_country, NULL, '00', 484,(r3.reg_classifier_abbreviation || ' - ' || r3.reg_classifier_code),'NE') edonac,
                DECODE(p.gender,'F','M','M','H',NULL) sexo,
                ct.id_content nacorigen,
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 5)  edo,
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 10)  mun,
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 15)  loc,
                php.benefeciary_type tipobeneficiario,
                pk_translation.get_translation(17,hp.code_health_plan) clave_programa,
                php.num_health_plan folioprograma,
                php.dependency clave_dependencia,
                p.institution_key institution,
                p.create_time
  FROM patient p
 INNER JOIN person ps
    ON p.id_person = ps.id_person
  LEFT JOIN person_hist psh
    ON psh.id_person = ps.id_person
 INNER JOIN pat_soc_attributes psa
    ON psa.id_patient = p.id_patient
  LEFT JOIN rb_regional_classifier rbrcln
    ON rbrcln.id_rb_regional_classifier = p.id_place_of_birth
  LEFT JOIN country ct
    ON ct.id_country = psa.id_country_nation
  LEFT JOIN contact c
    ON c.id_contact_entity = ps.id_person
  LEFT JOIN contact_address ca
    ON ca.id_contact_address = c.id_contact
  LEFT JOIN alert_adtcod.pat_birthplace pb
    ON pb.id_patient = p.id_patient
  LEFT JOIN alert_adtcod.contact c1
    ON c1.id_contact_entity = pb.id_pat_birthplace
  LEFT JOIN alert_adtcod.contact_address camx
    ON camx.id_contact_address = c1.id_contact
  LEFT JOIN rb_regional_classifier r1
    ON r1.id_rb_regional_classifier = camx.id_rb_regional_classifier
  LEFT JOIN rb_regional_classifier r2
    ON r1.id_rb_regional_class_parent = r2.id_rb_regional_classifier
  LEFT JOIN rb_regional_classifier r3
    ON r2.id_rb_regional_class_parent = r3.id_rb_regional_classifier
  LEFT JOIN pat_health_plan php
    ON php.id_patient = p.id_patient
  LEFT JOIN health_plan hp
    ON php.id_health_plan = hp.id_health_plan
  INNER JOIN alert_adtcod.pat_health_plan_hist phph 
    on phph.id_pat_health_plan = php.id_pat_health_plan
	INNER JOIN epis_health_plan ehp
	  on ehp.id_pat_health_plan = php.id_pat_health_plan
WHERE phph.operation_type = 'C'
      AND ehp.flg_primary = 'Y';
			

