CREATE OR REPLACE VIEW V_DIAGNOSIS_TRANSLATE_US AS
SELECT dx.id_diagnosis,
       dx.id_diagnosis_parent,
       dx.code_diagnosis,
       dx.code_icd,
       dx.flg_select,
       dx.flg_available,
       dx.flg_type,
       dx.flg_other,
       dx.mdm_coding,
       dx.id_content,
       tr.id_translation,
       tr.id_language,
       tr.code_translation,
       tr.desc_translation
       FROM DIAGNOSIS dx JOIN TRANSLATION tr
 ON tr.CODE_TRANSLATION = dx.CODE_DIAGNOSIS
 AND tr.ID_LANGUAGE = 2
 AND tr.CODE_TRANSLATION LIKE 'DIAGNOSIS.CODE_DIAGNOSIS%'
 WHERE dx.FLG_TYPE = 'U' AND dx.FLG_AVAILABLE = 'Y';

-- CHANGED BY: Cláudio Vieira
-- CHANGE DATE: 20-10-2010
-- CHANGE REASON: ALERT-133376

CREATE OR REPLACE VIEW alert.V_DIAGNOSIS_TRANSLATE_US AS
SELECT dx.id_diagnosis,
       dx.id_diagnosis_parent,
       dx.code_diagnosis,
       dx.code_icd,
       dx.flg_select,
       dx.flg_available,
       dx.flg_type,
       dx.flg_other,
       dx.mdm_coding,
       dx.id_content,
       tr.id_translation,
       2 as id_language,
       tr.code_translation,
       tr.desc_lang_2 as desc_translation
       FROM DIAGNOSIS dx JOIN TRANSLATION tr
 ON tr.CODE_TRANSLATION = dx.CODE_DIAGNOSIS
 AND tr.DESC_LANG_2 is not null
 AND tr.CODE_TRANSLATION LIKE 'DIAGNOSIS.CODE_DIAGNOSIS%'
 WHERE dx.FLG_TYPE = 'U' AND dx.FLG_AVAILABLE = 'Y';

-- CHANGE END: Cláudio Vieira

-- CHANGED BY: Ricardo Caetano Ferreira
-- CHANGED DATE: 2012-11-05
-- CHANGE REASON: ALERT-243902

CREATE OR REPLACE VIEW V_DIAGNOSIS_TRANSLATE_US AS
SELECT dx.id_diagnosis,
       dx.id_diagnosis_parent,
       dx.code_diagnosis,
       dx.code_icd,
       dx.flg_select,
       dx.flg_available,
       dx.flg_type,
       dx.flg_other,
       dx.mdm_coding,
       dx.id_content,
       2 as id_language,
       dx.code_diagnosis as code_translation,
       pk_translation.get_translation(2, dx.code_diagnosis ) as desc_translation
       FROM DIAGNOSIS dx 
WHERE dx.FLG_TYPE = 'U' AND dx.FLG_AVAILABLE = 'Y';

-- CHANGE END