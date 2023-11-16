/*-- Last Change Revision: $Rev: 2000936 $*/
/*-- Last Change by: $Author: luis.fernandes $*/
/*-- Date of last change: $Date: 2021-11-09 11:07:55 +0000 (ter, 09 nov 2021) $*/

CREATE OR REPLACE PACKAGE pk_cmt_content_core IS

    g_default_language NUMBER := 2;
    g_exception EXCEPTION;
    PROCEDURE set_img_exam_freq
    (
        i_action           VARCHAR,
        i_id_cnt_img_exam  VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
        
    );

    FUNCTION format_prepare_for_search(i_field IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION format_field_trim_upper_gmc(i_field IN VARCHAR2) RETURN VARCHAR2;

    PROCEDURE set_response
    (
        i_id_language     NUMBER,
        i_action          VARCHAR,
        i_id_cnt_response VARCHAR,
        i_desc_response   VARCHAR,
        i_gender          VARCHAR,
        i_age_max         VARCHAR,
        i_age_min         VARCHAR,
        i_flg_free_text   VARCHAR
    );

    PROCEDURE set_labtest_sample_type_alias
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_analysis    NUMBER,
        i_id_sample_type NUMBER,
        i_desc_alias     VARCHAR
    );

    PROCEDURE set_lab_test_group_ctlg
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_cnt_lab_test_group VARCHAR,
        i_desc_lab_test_group   VARCHAR,
        i_desc_alias            VARCHAR,
        i_gender                NUMBER,
        i_age_min               NUMBER,
        i_age_max               NUMBER
    );

    PROCEDURE set_lab_test_group_avlb
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_cnt_lab_test_group VARCHAR
    );

    PROCEDURE set_lab_test_group_alias
    (
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_lab_test_group VARCHAR,
        i_desc_alias        VARCHAR
    );

    PROCEDURE set_labtest_sample_type_ctlg
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test             VARCHAR,
        i_id_cnt_sample_type          VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_gender                      VARCHAR,
        i_age_min                     NUMBER,
        i_age_max                     NUMBER,
        i_desc_alias                  VARCHAR
    );

    FUNCTION validate_content
    (
        i_id_language    IN NUMBER,
        i_id_institution IN NUMBER,
        i_id_content     IN table_varchar,
        i_table          IN table_varchar,
        i_show_errors    IN table_number,
        o_results        OUT table_number,
        o_status         OUT table_varchar
    ) RETURN BOOLEAN;

    FUNCTION validate_mandatory_fields
    (
        i_id_language        IN NUMBER,
        i_id_institution     IN NUMBER,
        i_field_number       IN table_number,
        i_field_varchar      IN table_varchar,
        i_field_name_number  IN table_varchar,
        i_field_name_varchar IN table_varchar
    ) RETURN BOOLEAN;

    PROCEDURE validate_description_exists
    (
        i_id_language      NUMBER,
        i_desc_content     VARCHAR,
        i_table            VARCHAR,
        i_table_schema     VARCHAR,
        i_code_translation VARCHAR
    );

    PROCEDURE set_procedure_ctlg
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_desc_procedure   VARCHAR,
        i_age_min          NUMBER,
        i_age_max          NUMBER,
        i_gender           VARCHAR,
        i_rank             NUMBER,
        i_flg_mov_pat      VARCHAR,
        i_cpt_code         VARCHAR,
        i_ref_form_code    VARCHAR,
        i_barcode          VARCHAR,
        i_flg_technical    VARCHAR DEFAULT 'N',
        i_desc_alias       VARCHAR DEFAULT NULL
    );

    PROCEDURE set_procedure_avlb
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_desc_alias           VARCHAR,
        i_id_cnt_procedure     VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_flg_execute          VARCHAR,
        i_flg_timeout          VARCHAR,
        i_flg_chargeable       VARCHAR,
        i_flg_priority         VARCHAR,
        i_rank                 NUMBER
    );

    PROCEDURE set_sr_procedure_ctlg
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_cnt_sr_procedure VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_sr_procedure   VARCHAR,
        i_age_min             NUMBER,
        i_age_max             NUMBER,
        i_gender              VARCHAR,
        i_rank                NUMBER,
        i_flg_mov_pat         VARCHAR,
        i_cpt_code            VARCHAR,
        i_ref_form_code       VARCHAR,
        i_barcode             VARCHAR,
        i_flg_technical       VARCHAR DEFAULT 'N',
        i_desc_alias          VARCHAR DEFAULT NULL
    );

    PROCEDURE set_sr_procedure_avlb
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_desc_alias           VARCHAR,
        i_id_cnt_sr_procedure  VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_flg_execute          VARCHAR,
        i_flg_timeout          VARCHAR,
        i_flg_chargeable       VARCHAR,
        i_flg_priority         VARCHAR,
        i_rank                 NUMBER
    );

    PROCEDURE set_lab_test_sample_type_avlb
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_cnt_lab_test_cat         VARCHAR,
        i_id_cnt_sample_recipient     VARCHAR,
        i_id_room_execution           NUMBER,
        i_id_room_harvest             NUMBER,
        i_id_lab_test_parameter       NUMBER,
        i_flg_fill_type_parameter     VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_flg_priority                VARCHAR,
        i_harvest_instructions        VARCHAR
    );

    PROCEDURE associate_professional
    (
        i_prof                     professional.id_professional%TYPE,
        i_id_language              language.id_language%TYPE,
        i_id_institution           institution.id_institution%TYPE,
        i_id_number_in_institution prof_institution.num_mecan%TYPE,
        i_language                 language.id_language%TYPE,
        i_id_category              category.id_category%TYPE
    );

    PROCEDURE set_complaint_ctlg
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_complaint VARCHAR,
        i_desc_complaint   VARCHAR
    );

    PROCEDURE set_complaint_avlb
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_rank                   NUMBER DEFAULT 10,
        i_gender                 VARCHAR,
        i_age_max                NUMBER,
        i_age_min                NUMBER
    );

    PROCEDURE set_trans_codes_mt
    (
        i_action            VARCHAR,
        i_id_language       NUMBER,
        i_id_institution    NUMBER,
        i_table_translation VARCHAR,
        i_code_translation  VARCHAR,
        i_val               VARCHAR,
        i_portuguese_pt     VARCHAR,
        i_english_us        VARCHAR,
        i_spanish_es        VARCHAR,
        i_italian_it        VARCHAR,
        i_french_fr         VARCHAR,
        i_english_uk        VARCHAR,
        i_english_sa        VARCHAR,
        i_portuguese_br     VARCHAR,
        i_chinese_zh_cn     VARCHAR,
        i_chinese_zh_tw     VARCHAR,
        i_arabic_ar_sa      VARCHAR,
        i_spanish_cl        VARCHAR,
        i_spanish_mx        VARCHAR,
        i_french_ch         VARCHAR,
        i_portuguese_ao     VARCHAR,
        i_czech_cz          VARCHAR,
        i_portuguese_mz     VARCHAR
    );

    PROCEDURE set_lab_test_param
    (
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_lab_test_parameter NUMBER,
        i_id_lab_test           NUMBER,
        i_id_sample_type        NUMBER,
        i_rank                  NUMBER,
        i_flg_fill_type         VARCHAR
    );

    PROCEDURE set_trans_sys_message_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_code_message    VARCHAR,
        i_module          VARCHAR,
        i_target_language VARCHAR
    );

    PROCEDURE set_trans_sys_message_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_code_message   VARCHAR,
        i_module         VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    );

    PROCEDURE set_trans_funct_help_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_code_help       VARCHAR,
        i_target_language VARCHAR
    );

    PROCEDURE set_trans_funct_help_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_code_help      VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    );

    PROCEDURE set_trans_sys_domain_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_code_domain     VARCHAR,
        i_val             VARCHAR,
        i_target_language VARCHAR
    );

    PROCEDURE set_trans_sys_domain_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_code_domain    VARCHAR,
        i_val            VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    );

    PROCEDURE set_trans_translation_cp
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_target_language  VARCHAR
    );

    PROCEDURE set_trans_translation_mt
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_portuguese_pt    VARCHAR,
        i_english_us       VARCHAR,
        i_spanish_es       VARCHAR,
        i_italian_it       VARCHAR,
        i_french_fr        VARCHAR,
        i_english_uk       VARCHAR,
        i_english_sa       VARCHAR,
        i_portuguese_br    VARCHAR,
        i_chinese_zh_cn    VARCHAR,
        i_chinese_zh_tw    VARCHAR,
        i_arabic_ar_sa     VARCHAR,
        i_spanish_cl       VARCHAR,
        i_spanish_mx       VARCHAR,
        i_french_ch        VARCHAR,
        i_portuguese_ao    VARCHAR,
        i_czech_cz         VARCHAR,
        i_portuguese_mz    VARCHAR
    );

    PROCEDURE set_trans_translation_lob_cp
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_target_language  VARCHAR
    );

    PROCEDURE set_trans_translation_lob_mt
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_portuguese_pt    VARCHAR,
        i_english_us       VARCHAR,
        i_spanish_es       VARCHAR,
        i_italian_it       VARCHAR,
        i_french_fr        VARCHAR,
        i_english_uk       VARCHAR,
        i_english_sa       VARCHAR,
        i_portuguese_br    VARCHAR,
        i_chinese_zh_cn    VARCHAR,
        i_chinese_zh_tw    VARCHAR,
        i_arabic_ar_sa     VARCHAR,
        i_spanish_cl       VARCHAR,
        i_spanish_mx       VARCHAR,
        i_french_ch        VARCHAR,
        i_portuguese_ao    VARCHAR,
        i_czech_cz         VARCHAR,
        i_portuguese_mz    VARCHAR
    );

    FUNCTION check_dest_language
    (
        i_username    VARCHAR,
        i_id_language VARCHAR
    ) RETURN NUMBER;

    FUNCTION get_source_language(i_username VARCHAR) RETURN NUMBER;

    PROCEDURE set_question_response
    (
        i_id_language                  NUMBER,
        i_action                       VARCHAR,
        i_id_cnt_clinical_question     VARCHAR,
        i_id_cnt_response              VARCHAR,
        i_id_cnt_question_response     VARCHAR,
        i_rank                         VARCHAR,
        i_id_cnt_question_response_prt VARCHAR
    );
    PROCEDURE set_other_exam_freq
    (
        i_action            VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_dep_clin_serv  NUMBER
    );
    PROCEDURE set_sr_procedure_freq
    (
        i_action              VARCHAR,
        i_id_cnt_sr_procedure VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_dep_clin_serv    NUMBER
    );

    PROCEDURE set_professionals_cl
    (
        i_action                  VARCHAR,
        i_id_language             language.id_language%TYPE,
        i_id_institution          institution.id_institution%TYPE,
        i_titulo                  professional.title%TYPE,
        i_nombre                  professional.first_name%TYPE,
        i_apellido_materno        professional.middle_name%TYPE,
        i_apellido_paterno        professional.last_name%TYPE,
        i_nombre_en_la_fotografia professional.nick_name%TYPE,
        i_iniciales               professional.initials%TYPE,
        i_fecha_de_nacimento      VARCHAR2,
        i_sexo                    professional.gender%TYPE,
        i_estado_civil            professional.marital_status%TYPE,
        i_categoria               category.id_category%TYPE,
        i_especialidad            VARCHAR2,
        i_number_colegiado        professional.num_order%TYPE,
        i_categoria_cirurgia      category.id_category%TYPE,
        i_numero_de_profesional   prof_institution.num_mecan%TYPE,
        i_idioma                  prof_preferences.id_language%TYPE,
        i_estado_en_alert         prof_institution.flg_state%TYPE,
        i_direccion               professional.address%TYPE,
        i_ciudad                  professional.city%TYPE,
        i_provincia               professional.district%TYPE,
        i_codigo_postal           professional.zip_code%TYPE,
        i_pais                    VARCHAR2,
        i_telefono_de_trabajo     professional.work_phone%TYPE,
        i_telefono_de_casa        professional.num_contact%TYPE,
        i_movil                   professional.cell_phone%TYPE,
        i_fax                     professional.fax%TYPE,
        i_e_mail                  professional.email%TYPE,
        i_numero_del_mensafono    professional.bleep_number%TYPE,
        i_run                     VARCHAR,
        i_rut                     VARCHAR
    );

    PROCEDURE set_professionals_sa
    (
        i_action                   VARCHAR,
        i_id_language              language.id_language%TYPE,
        i_id_institution           institution.id_institution%TYPE,
        i_title                    professional.title%TYPE,
        i_first_name_arabic        professional.first_name_sa%TYPE,
        i_father_name_arabic       professional.parent_name_sa%TYPE,
        i_middle_name_arabic       professional.middle_name_sa%TYPE,
        i_last_name_arabic         professional.last_name_sa%TYPE,
        i_first_name               professional.first_name%TYPE,
        i_father_name              professional.parent_name%TYPE,
        i_middle_name              professional.middle_name%TYPE,
        i_last_name                professional.last_name%TYPE,
        i_display_name_over_photo  professional.nick_name%TYPE,
        i_initials                 professional.initials%TYPE,
        i_birth_date               VARCHAR2,
        i_gender                   professional.gender%TYPE,
        i_civil_status             professional.marital_status%TYPE,
        i_prof_category            category.id_category%TYPE,
        i_speciality               VARCHAR2,
        i_gmc                      professional.num_order%TYPE,
        i_surgical_category        category.id_category%TYPE,
        i_id_number_in_institution prof_institution.num_mecan%TYPE,
        i_language                 language.id_language%TYPE,
        i_adress                   professional.address%TYPE,
        i_city                     professional.city%TYPE,
        i_county                   professional.district%TYPE,
        i_postcode                 professional.zip_code%TYPE,
        i_country                  VARCHAR2,
        i_work_phone               professional.work_phone%TYPE,
        i_home_phone               professional.num_contact%TYPE,
        i_mobile_phone             professional.cell_phone%TYPE,
        i_fax                      professional.fax%TYPE,
        i_e_mail                   professional.email%TYPE,
        i_bleep_number             professional.bleep_number%TYPE,
        i_document_type            VARCHAR2,
        i_document_number          prof_doc.value%TYPE,
        i_document_expiration_date VARCHAR2,
        i_username                 VARCHAR2
    );

    PROCEDURE set_clinical_question
    (
        i_id_language              NUMBER,
        i_action                   VARCHAR,
        i_id_cnt_clinical_question VARCHAR,
        i_desc_clinical_question   VARCHAR,
        i_gender                   VARCHAR,
        i_age_max                  VARCHAR,
        i_age_min                  VARCHAR
    );

    PROCEDURE set_lab_test_complaint
    (
        i_action                      VARCHAR,
        i_id_language                 NUMBER,
        i_id_institution              NUMBER,
        i_id_cnt_complaint            VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR
    );

    PROCEDURE set_procedure_freq
    (
        i_action           VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    );

    PROCEDURE insert_credential_reg_user
    (
        i_pass_hash VARCHAR,
        i_id_prof   NUMBER,
        i_username  VARCHAR
        
    );

    FUNCTION check_profile_template
    (
        i_profile_template NUMBER,
        i_institution      NUMBER,
        i_software         NUMBER,
        i_category         NUMBER DEFAULT NULL
        
    ) RETURN BOOLEAN;

    FUNCTION get_profile_template_market
    (
        i_category    NUMBER DEFAULT NULL,
        i_software    NUMBER,
        i_institution NUMBER
    ) RETURN table_number;

    FUNCTION generate_pass_hash(i_username VARCHAR) RETURN VARCHAR;

    PROCEDURE set_map
    (
        action              VARCHAR,
        alert_system        VARCHAR,
        alert_definition    VARCHAR,
        alert_value         VARCHAR,
        external_system     VARCHAR,
        external_definition VARCHAR,
        external_value      VARCHAR,
        id_institution      VARCHAR,
        id_software         VARCHAR
    );

    PROCEDURE set_disch_reason_prof_temp
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_cnt_discharge_reason     VARCHAR,
        i_id_profile_template         NUMBER,
        i_type_of_discharge           VARCHAR,
        i_professionals_accessibility VARCHAR,
        i_rank                        NUMBER,
        i_flg_default                 VARCHAR
    );

    PROCEDURE set_procedure_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_procedure         VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    );

    PROCEDURE set_other_exam_room
    (
        i_action            VARCHAR,
        i_id_institution    NUMBER,
        i_id_language       VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_room           VARCHAR,
        i_rank              NUMBER,
        i_flg_default       VARCHAR,
        i_id_record         NUMBER
    );

    PROCEDURE set_lab_test_group_freq
    (
        i_action                VARCHAR,
        i_id_cnt_lab_test_group VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_dep_clin_serv      NUMBER
    );

    PROCEDURE set_lab_test_room
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_room                     NUMBER,
        i_flg_type                    VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_flg_default                 VARCHAR,
        i_id_record                   NUMBER
    );

    PROCEDURE set_lab_test_room
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_room        NUMBER,
        i_flg_type       VARCHAR,
        i_id_lab_test    NUMBER,
        i_id_sample_type NUMBER,
        i_rank           NUMBER,
        i_flg_default    VARCHAR
    );

    PROCEDURE set_sr_procedure
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_sr_procedure   VARCHAR,
        i_icd                 VARCHAR,
        i_gender              VARCHAR,
        i_age_min             NUMBER,
        i_age_max             NUMBER,
        i_duration            NUMBER,
        i_prev_recovery_time  NUMBER,
        i_flg_coding          VARCHAR,
        i_id_cnt_sr_procedure VARCHAR
    );

    PROCEDURE set_lab_test_recipient
    (
        i_action                       VARCHAR,
        i_id_language                  VARCHAR,
        i_id_institution               NUMBER,
        i_id_software                  NUMBER,
        i_id_cnt_sample_recipient      VARCHAR,
        i_id_cnt_lab_test_sample_type  VARCHAR,
        i_flg_default                  VARCHAR,
        i_id_analysis_instit_recipient VARCHAR
    );

    PROCEDURE set_lab_test_recipient
    (
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_sample_recipient NUMBER,
        i_id_lab_test         NUMBER,
        i_id_sample_type      NUMBER,
        i_flg_default         VARCHAR
    );

    PROCEDURE set_lab_test_parameter
    (
        i_action                    VARCHAR,
        i_id_language               VARCHAR,
        i_desc_lab_test_parameter   VARCHAR,
        i_id_cnt_lab_test_parameter VARCHAR
    );

    PROCEDURE set_lab_test_freq
    (
        i_action                      VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_dep_clin_serv            NUMBER
    );

    PROCEDURE set_img_exam_complaint
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_id_cnt_complaint VARCHAR,
        i_id_cnt_img_exam  VARCHAR
    );

    PROCEDURE set_other_exam_complaint
    (
        i_action            VARCHAR,
        i_id_language       NUMBER,
        i_id_institution    NUMBER,
        i_id_cnt_complaint  VARCHAR,
        i_id_cnt_other_exam VARCHAR
    );

    PROCEDURE set_lab_test_sample_type
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test             VARCHAR,
        i_id_cnt_sample_type          VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_gender                      VARCHAR,
        i_age_min                     NUMBER,
        i_age_max                     NUMBER,
        i_desc_alias                  VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_id_cnt_exam_cat             VARCHAR,
        i_flg_priority                VARCHAR
    );

    PROCEDURE set_discharge_destination
    (
        i_action                       VARCHAR,
        i_id_language                  VARCHAR,
        i_desc_discharge_destination   VARCHAR,
        i_id_cnt_discharge_destination VARCHAR
    );
    PROCEDURE set_disch_reas_dest
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_id_institution          NUMBER,
        i_id_institution_dest     NUMBER DEFAULT NULL,
        i_id_software             NUMBER,
        i_id_cnt_discharge_reason VARCHAR,
        i_id_department           NUMBER DEFAULT NULL,
        i_id_cnt_discharge_dest   VARCHAR DEFAULT NULL,
        i_id_dep_clin_serv        NUMBER DEFAULT NULL,
        i_flg_default             VARCHAR DEFAULT 'N',
        i_flg_diag                VARCHAR,
        i_id_reports              NUMBER DEFAULT NULL,
        i_flg_mcdt                VARCHAR DEFAULT NULL,
        i_rank                    NUMBER DEFAULT 0,
        i_flg_auto_presc_cancel   VARCHAR DEFAULT 'N',
        i_type_screen             VARCHAR,
        i_id_epis_type            NUMBER DEFAULT NULL
    );

    PROCEDURE set_transportation
    (
        i_action                 VARCHAR,
        i_id_language            NUMBER,
        i_id_institution         NUMBER,
        i_desc_transportation    VARCHAR,
        i_id_cnt_transportation  VARCHAR,
        i_flg_doctor_admin       VARCHAR,
        i_flg_arrival_departure  VARCHAR,
        i_flg_discharge_transfer VARCHAR
    );

    PROCEDURE set_lab_test_group
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_desc_lab_test_group   VARCHAR,
        i_id_cnt_lab_test_group VARCHAR,
        i_gender                VARCHAR,
        i_age_min               NUMBER,
        i_age_max               NUMBER
    );
    PROCEDURE set_lab_test_group_assoc
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_lab_test_group       VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER
    );
    PROCEDURE set_lab_test_param
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_parameter   VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_flg_fill_type               VARCHAR
    );

    PROCEDURE set_lab_test
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_desc_lab_test   VARCHAR,
        i_id_cnt_lab_test VARCHAR
    );

    PROCEDURE set_sample_type
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_desc_sample_type   VARCHAR,
        i_id_cnt_sample_type VARCHAR
    );

    PROCEDURE set_sample_recipient
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_desc_sample_recipient   VARCHAR,
        i_id_cnt_sample_recipient VARCHAR
    );
    PROCEDURE set_lab_test_clin_quest
    (
        i_action                      VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_cnt_question_response    VARCHAR,
        i_flg_time                    VARCHAR,
        i_rank                        NUMBER,
        i_flg_type                    VARCHAR,
        i_flg_mandatory               VARCHAR,
        i_flg_copy                    VARCHAR,
        i_flg_validation              VARCHAR,
        i_flg_exterior                VARCHAR,
        i_id_unit_measure             NUMBER,
        i_id_institution              NUMBER
    );
    PROCEDURE set_lab_test_cat
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_cnt_lab_test_cat VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_lab_cat        VARCHAR,
        i_rank                NUMBER
    );

    PROCEDURE set_img_exam_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_img_exam          VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    );

    PROCEDURE set_other_exam_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_other_exam        VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    );

    PROCEDURE set_exam_cat_freq
    (
        i_action           VARCHAR,
        i_id_cnt_exam_cat  VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    );
    PROCEDURE set_supply_sup_area
    (
        i_action         VARCHAR,
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_cnt_supply  VARCHAR,
        i_id_supply_area NUMBER
    );
    PROCEDURE set_supply_relation
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_cnt_supply      VARCHAR,
        i_id_cnt_supply_item VARCHAR,
        i_quantity           NUMBER
    );

    PROCEDURE set_supply
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_desc_supply        VARCHAR,
        i_id_institution     NUMBER,
        i_id_software        NUMBER,
        i_id_cnt_supply      VARCHAR,
        i_id_cnt_supply_type VARCHAR,
        i_flg_type           VARCHAR,
        i_flg_cons_type      VARCHAR DEFAULT 'C',
        i_flg_reusable       VARCHAR DEFAULT 'N',
        i_flg_editable       VARCHAR DEFAULT 'N',
        i_flg_preparing      VARCHAR DEFAULT NULL,
        i_flg_countable      VARCHAR DEFAULT NULL
    );

    PROCEDURE set_supply_loc_default
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_institution     NUMBER,
        i_id_software        NUMBER,
        i_id_cnt_supply      VARCHAR,
        i_flg_default        VARCHAR,
        i_id_supply_location NUMBER
    );
    PROCEDURE set_lab_test_cat_freq
    (
        i_action              VARCHAR,
        i_id_cnt_lab_test_cat VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_dep_clin_serv    NUMBER
    );
    PROCEDURE set_external_cause
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_cnt_external_cause VARCHAR,
        i_desc_external_cause   VARCHAR,
        i_rank                  NUMBER
    );

    PROCEDURE set_hab_characterization
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_hab_characterization VARCHAR,
        i_desc_hab_characterization   VARCHAR
    );

    PROCEDURE set_habit
    (
        i_action         VARCHAR,
        i_id_language    VARCHAR,
        i_id_cnt_habit   VARCHAR,
        i_desc_habit     VARCHAR,
        i_id_institution NUMBER,
        i_rank           NUMBER
    );

    PROCEDURE set_habit_charact_rel
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_habit                VARCHAR,
        i_id_cnt_hab_characterization VARCHAR
    );

    PROCEDURE set_cancel_reason
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_desc_cancel_reason   VARCHAR,
        i_id_cnt_cancel_reason VARCHAR,
        i_flg_notes_mandatory  VARCHAR,
        i_rank                 NUMBER,
        i_id_reason_type       NUMBER
    );

    PROCEDURE set_cancel_reason_soft_inst
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_cancel_reason VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_id_profile_template  NUMBER,
        i_rank                 NUMBER,
        i_id_cancel_rea_area   NUMBER
    );

    PROCEDURE set_hid_charact_rel
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_cnt_way                  VARCHAR,
        i_id_cnt_hidrics              VARCHAR,
        i_id_cnt_hid_characterization VARCHAR,
        i_rank                        VARCHAR
    );

    PROCEDURE set_hid_device_rel
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_cnt_way            VARCHAR,
        i_id_cnt_hidrics        VARCHAR,
        i_id_cnt_hidrics_device VARCHAR,
        i_rank                  VARCHAR
    );

    PROCEDURE set_hid_location_rel
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_institution   NUMBER,
        i_id_cnt_way       VARCHAR,
        i_id_cnt_hidrics   VARCHAR,
        i_id_cnt_body_part VARCHAR,
        i_id_cnt_body_side VARCHAR,
        i_rank             VARCHAR
    );

    PROCEDURE set_hid_occurs_type_rel
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_cnt_hidrics         VARCHAR,
        i_id_cnt_hid_occurs_type VARCHAR,
        i_rank                   VARCHAR
    );

    PROCEDURE set_hidrics
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_hidrics  VARCHAR,
        i_desc_hidrics    VARCHAR,
        i_flg_type        VARCHAR,
        i_flg_free_txt    VARCHAR,
        i_flg_nr_times    VARCHAR,
        i_id_unit_measure VARCHAR,
        i_gender          VARCHAR,
        i_age_max         VARCHAR,
        i_age_min         VARCHAR,
        i_rank            NUMBER
    );

    PROCEDURE set_hidrics_configurations
    (
        i_action                     VARCHAR,
        i_id_language                VARCHAR,
        i_id_institution             NUMBER,
        i_id_hidrics_interval        VARCHAR,
        i_next_balance               VARCHAR,
        i_max_intake_warn_percentage VARCHAR
    );

    PROCEDURE set_hidrics_device
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_cnt_hidrics_device VARCHAR,
        i_desc_hidrics_device   VARCHAR,
        i_flg_free_txt          VARCHAR
    );

    PROCEDURE set_hidrics_occurs_type
    (
        i_action                     VARCHAR,
        i_id_language                VARCHAR,
        i_id_cnt_hidrics_occurs_type VARCHAR,
        i_desc_hidrics_occurs_type   VARCHAR
    );

    PROCEDURE set_hidrics_type
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_id_cnt_hidrics_type     VARCHAR,
        i_desc_hidrics_type       VARCHAR,
        i_flg_ti_type             VARCHAR,
        i_id_cnt_hidrics_type_prt VARCHAR
    );

    PROCEDURE set_hidrics_way_rel
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_cnt_way          VARCHAR,
        i_id_cnt_hidrics      VARCHAR,
        i_id_cnt_hidrics_type VARCHAR,
        i_rank                VARCHAR
    );

    PROCEDURE set_positioning
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_cnt_positioning VARCHAR,
        i_desc_positioning   VARCHAR,
        i_rank               NUMBER
    );

    PROCEDURE set_procedure_category
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_desc_procedure_cat   VARCHAR,
        i_rank                 NUMBER
    );

    PROCEDURE set_way
    (
        i_action       VARCHAR,
        i_id_language  VARCHAR,
        i_id_cnt_way   VARCHAR,
        i_desc_way     VARCHAR,
        i_flg_type     VARCHAR,
        i_flg_way_type VARCHAR
    );

    PROCEDURE set_procedure_by_category
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_procedure     VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_id_cnt_procedure_cat VARCHAR,
        i_rank                 NUMBER
    );

    PROCEDURE set_clinical_service
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_desc_clinical_service   VARCHAR,
        i_id_cnt_clinical_service VARCHAR,
        i_abbreviation            VARCHAR,
        i_id_cnt_clin_serv_parent VARCHAR
    );

    PROCEDURE set_supply_type
    (
        i_action                    VARCHAR,
        i_id_language               VARCHAR,
        i_desc_supply_type          VARCHAR,
        i_id_institution            NUMBER,
        i_id_software               NUMBER,
        i_id_cnt_supply_type        VARCHAR,
        i_id_cnt_supply_type_parent VARCHAR
    );

    PROCEDURE set_diet
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_cnt_diet            VARCHAR,
        i_id_cnt_diet_prt        VARCHAR,
        i_desc_diet              VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_rank                   NUMBER,
        i_id_diet_type           NUMBER,
        i_quantity_default       NUMBER,
        i_id_unit_measure        NUMBER,
        i_energy_quantity_value  NUMBER,
        i_id_unit_measure_energy NUMBER
    );
    PROCEDURE set_procedure
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_desc_procedure   VARCHAR,
        i_age_min          NUMBER,
        i_age_max          NUMBER,
        i_gender           VARCHAR,
        i_rank             NUMBER,
        i_flg_mov_pat      VARCHAR,
        i_cpt_code         VARCHAR,
        i_ref_form_code    VARCHAR,
        i_barcode          VARCHAR,
        i_flg_execute      VARCHAR,
        i_flg_technical    VARCHAR DEFAULT 'N',
        i_flg_priority     VARCHAR,
        i_desc_alias       VARCHAR DEFAULT NULL
    );

    PROCEDURE set_img_exam_room
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_img_exam VARCHAR,
        i_id_room         VARCHAR,
        i_rank            NUMBER,
        i_flg_default     VARCHAR,
        i_id_record       NUMBER
    );

    PROCEDURE set_ultrasound_room
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_ultrasound VARCHAR,
        i_id_room           VARCHAR,
        i_rank              NUMBER,
        i_flg_default       VARCHAR,
        i_id_record         NUMBER
    );

    PROCEDURE set_other_exam_ctlg
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_cnt_other_exam VARCHAR,
        i_desc_other_exam   VARCHAR,
        i_desc_alias        VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N'
    );

    PROCEDURE set_lab_test_sample_type_prp
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_id_cnt_exam_cat             VARCHAR
    );

    PROCEDURE set_other_exam_avlb
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_alias        VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_chargeable    VARCHAR,
        i_flg_priority      VARCHAR,
        i_id_room           NUMBER
    );

    PROCEDURE set_other_exam
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_other_exam   VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_desc_alias        VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N',
        i_flg_priority      VARCHAR
    );

    PROCEDURE set_exam_alias
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_cnt_exam    VARCHAR,
        i_desc_alias     VARCHAR
    );

    PROCEDURE set_img_exam_avlb
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_alias        VARCHAR,
        i_id_cnt_img_exam   VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_chargeable    VARCHAR,
        i_flg_priority      VARCHAR,
        i_id_room           NUMBER
    );

    PROCEDURE set_ultrasound_avlb
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_desc_alias            VARCHAR,
        i_id_cnt_ultrasound     VARCHAR,
        i_flg_first_result      VARCHAR,
        i_flg_execute           VARCHAR,
        i_flg_mov_pat           VARCHAR,
        i_flg_timeout           VARCHAR,
        i_flg_result_notes      VARCHAR,
        i_flg_first_execute     VARCHAR,
        i_flg_chargeable        VARCHAR,
        i_flg_priority          VARCHAR,
        i_flg_bypass_validation VARCHAR,
        i_id_room               NUMBER
    );

    PROCEDURE set_img_exam_ctlg
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_id_cnt_img_exam VARCHAR,
        i_desc_img_exam   VARCHAR,
        i_desc_alias      VARCHAR,
        i_id_cnt_exam_cat VARCHAR,
        i_age_min         NUMBER,
        i_age_max         NUMBER,
        i_gender          VARCHAR,
        i_flg_mov_pat     VARCHAR,
        i_flg_pat_resp    VARCHAR,
        i_flg_pat_prep    VARCHAR,
        i_flg_technical   VARCHAR DEFAULT 'N'
    );

    FUNCTION get_speciality_id_content(i_speciality VARCHAR) RETURN VARCHAR;

    FUNCTION get_speciality_id(i_speciality VARCHAR) RETURN NUMBER;

    PROCEDURE set_img_exam
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_img_exam   VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_img_exam     VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_desc_alias        VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N',
        i_flg_priority      VARCHAR
    );
    PROCEDURE set_exam_cat
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_exam_cat VARCHAR,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_desc_exam_cat   VARCHAR,
        i_rank            NUMBER
    );

    PROCEDURE set_complaint_freq
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_rank                   NUMBER DEFAULT 10,
        i_id_dep_clin_serv       VARCHAR
    );

    PROCEDURE set_complaint_alias
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_desc_complaint_alias   VARCHAR
    );

END pk_cmt_content_core;
/
