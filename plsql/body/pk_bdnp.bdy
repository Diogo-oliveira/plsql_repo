/*-- Last Change Revision: $Rev: 1988924 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2021-05-13 11:17:29 +0100 (qui, 13 mai 2021) $*/
CREATE OR REPLACE PACKAGE BODY pk_bdnp IS

    -- Private type declarations

    -- Private constant declarations
    g_referral_type   CONSTANT VARCHAR2(1) := 'R';
    g_medication_type CONSTANT VARCHAR2(1) := 'M';

    -- Private variable declarations
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_retval BOOLEAN;
    g_error  VARCHAR2(4000);
    g_exception EXCEPTION;
    g_found BOOLEAN;

    g_hp_type_profdecease CONSTANT VARCHAR2(2 CHAR) := 'P'; -- profdecease_hp_type

    -- Function and procedure implementations

    FUNCTION check_referral_home
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_type        IN p1_external_request.flg_type%TYPE,
        o_home_active OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
        g_error          := 'Call pk_sysconfig.get_config ' || pk_ref_constant.g_ref_mcdt_bdnp;
        l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                pk_alert_constant.g_no);
    
        pk_alertlog.log_info('l_bdnp_available=' || l_bdnp_available);
        IF l_bdnp_available = pk_alert_constant.g_yes
        THEN
            IF i_type = pk_ref_constant.g_p1_type_a
            THEN
                o_home_active := pk_alert_constant.g_yes;
            ELSE
                o_home_active := pk_alert_constant.g_no;
            END IF;
        ELSE
            o_home_active := pk_alert_constant.g_no;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END check_referral_home;

    /*******************************************************************************************************************************************
    * Returns the information of the prescription light license of an user/institution                                                         *
    *                                                                                                                                          *
    * @param i_lang            LANGUAGE                                                                                                        *
    * @param i_prof            PROFESSIONAL ARRAY                                                                                              *
    * @param o_licenses_left   Licenses remaining (for PRE only)                                                                               *
    *                                                                                                                                          *
    * @param o_error           Message error to be shown to the user.                                                                          *
    *                                                                                                                                          *
    * @return  TRUE if succeeded. FALSE otherwise.                                                                                             *
    *                                                                                                                                          *
    * @author                         Nuno Antunes                                                                                             *
    * @version                        1.0                                                                                                      *
    * @since                          2011/03/23                                                                                               *
    *                                                                                                                                          *
    ********************************************************************************************************************************************/
    FUNCTION presc_light_get_license_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_licenses_left         OUT NUMBER,
        o_flg_show_almost_empty OUT VARCHAR2,
        o_almost_empty_msg      OUT VARCHAR2,
        o_flg_show_warning      OUT VARCHAR2,
        o_warning_msg           OUT VARCHAR2,
        o_header_msg            OUT VARCHAR2,
        o_show_warnings         OUT VARCHAR2,
        o_shortcut              OUT NUMBER,
        o_buttons               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_payment_plan          VARCHAR2(40);
        l_entity                VARCHAR2(800);
        l_flg_show_almost_empty VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_show_warning      VARCHAR2(1) := pk_alert_constant.g_no;
        l_almost_empty          NUMBER := 20; --TODO read the configuration (it's not created yet)
    BEGIN
    
        o_shortcut := 700182; -- Shortcut (portal de compras);
    
        o_header_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PRESC_LIGHT_HEADER_MSG');
    
        o_show_warnings := nvl(pk_sysconfig.get_config(i_code_cf => 'PRESC_LIGHT_SHOW_WARNINGS', i_prof => i_prof),
                               pk_alert_constant.g_no);
    
        g_error := 'pk_prescription.pres_light_get_license_info';
        /*IF NOT pk_presc_light.get_license_info(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   o_payment_plan  => l_payment_plan,
                                                   o_entity        => l_entity,
                                                   o_licenses_left => o_licenses_left,
                                                   o_show_warning  => l_flg_show_warning,
                                                   o_almost_empty  => l_flg_show_almost_empty,
                                                   o_error         => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        */
        o_licenses_left := nvl(o_licenses_left, 0);
    
        IF o_show_warnings = pk_alert_constant.g_yes
        THEN
            --For testing
            --o_licenses_left := 10;
            --l_flg_show_warning := pk_alert_constant.g_yes;    
            IF o_licenses_left <= 0
               AND l_flg_show_warning = pk_alert_constant.g_yes
            THEN
                o_flg_show_warning := pk_alert_constant.g_yes;
                o_warning_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PRESC_LIGHT_EMPTY_MSG');
            ELSE
                o_flg_show_warning := pk_alert_constant.g_no;
            END IF;
        
            --For testing
            --l_flg_show_almost_empty := 'Y';
            IF l_flg_show_almost_empty = pk_alert_constant.g_yes
            THEN
                o_flg_show_almost_empty := pk_alert_constant.g_yes;
                o_almost_empty_msg      := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                                          i_code_mess => 'PRESC_LIGHT_ALMOST_EMPTY_MSG'),
                                                   '@1',
                                                   l_almost_empty);
            ELSE
                o_flg_show_almost_empty := pk_alert_constant.g_no;
            END IF;
        
            OPEN o_buttons FOR
                SELECT 'BT_GOTO' AS id_button, pk_message.get_message(i_lang, 'PRESC_LIGHT_BT_GOTO') AS label
                  FROM dual
                UNION ALL
                SELECT 'BT_PROCEED' AS id_button,
                       pk_message.get_message(i_lang,
                                               CASE
                                                   WHEN o_licenses_left > 0 THEN
                                                    'PRESC_LIGHT_BT_PROCEED_LICENSES'
                                                   ELSE
                                                    'PRESC_LIGHT_BT_PROCEED_NO_LICENSES'
                                               END) AS label
                  FROM dual
                
                UNION ALL
                SELECT 'BT_CANCEL' AS id_button, pk_message.get_message(i_lang, 'PRESC_LIGHT_BT_CANCEL') AS label
                  FROM dual;
        ELSE
            OPEN o_buttons FOR
                SELECT '' AS id_button, '' AS label
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_buttons);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'pres_light_get_license_info',
                                                     o_error    => o_error);
    END presc_light_get_license_info;
    /*********************************************************************************************
    * Set table set_bdnp_presc_detail
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode
    * @param i_type                   M - Medication, R - Referral
    * @param i_presc                  Referral Id or Medication Id
    * @param i_flg_isencao            Y- Insento, N - Não isento (Just for referral)
    * @param i_mcdt_nature            MCDT_NATURE (Just for referral)
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/11/16    
    **********************************************************************************************/

    FUNCTION set_bdnp_presc_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_type        IN bdnp_presc_detail.flg_presc_type%TYPE,
        i_presc       IN bdnp_presc_detail.id_presc%TYPE,
        i_flg_isencao IN VARCHAR2 DEFAULT NULL,
        i_mcdt_nature IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sns                   pat_health_plan.num_health_plan%TYPE; --Numero SNS
        l_num_health_plan       pat_health_plan.num_health_plan%TYPE; --Numero sns/seguro saude/etc
        l_pat_name              patient.name%TYPE; --Nome paciente
        l_pat_dt_birth          VARCHAR2(200); --Data de nascimento
        l_pat_gender            patient.gender%TYPE; --Género
        l_pat_birth_place       country.alpha2_code%TYPE; --Nacionalidade
        l_id_health_plan        pat_health_plan.id_health_plan%TYPE;
        l_hp_entity             VARCHAR2(4000);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_flg_occ_disease       VARCHAR2(1);
        l_flg_independent       VARCHAR2(1);
        l_exist_migrator_doc    VARCHAR2(1);
        l_dummy                 VARCHAR2(4000);
        l_dt_expire             doc_external.dt_expire%TYPE;
        l_num_doc               doc_external.num_doc%TYPE;
        l_flg_indfess           VARCHAR2(1 CHAR);
        l_doc_type              VARCHAR2(4000);
        l_hp_alpha2_code        VARCHAR2(4000);
        l_hp_national_ident_nbr VARCHAR2(4000);
        l_pat_dt_birth_tstz     TIMESTAMP WITH TIME ZONE;
        l_hp_dt_effective_tstz  TIMESTAMP WITH TIME ZONE;
        l_hp_dt_effective       VARCHAR2(200);
        l_dt_expire_tstz        TIMESTAMP;
        l_valid_sns             VARCHAR2(1);
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error    := 'Call pk_sysconfig.get_config ID_DOC_TYPE_MIGRANT';
        l_doc_type := pk_sysconfig.get_config('ID_DOC_TYPE_MIGRANT', i_prof);
    
        g_error := 'Call pk_adt.get_pat_info i_id_patient=' || i_patient || ' i_id_episode=' || i_episode;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_adt.get_pat_info(i_lang              => i_lang,
                                        i_id_patient        => i_patient,
                                        i_prof              => i_prof,
                                        i_id_episode        => i_episode,
                                        o_name              => l_pat_name,
                                        o_gender            => l_pat_gender,
                                        o_desc_gender       => l_dummy,
                                        o_dt_birth          => l_pat_dt_birth,
                                        o_dt_deceased       => l_dummy,
                                        o_flg_migrator      => l_flg_migrator,
                                        o_id_country_nation => l_pat_birth_place,
                                        o_sns               => l_sns,
                                        o_valid_sns         => l_valid_sns,
                                        o_flg_occ_disease   => l_flg_occ_disease, --Doente profissional : CNPRP
                                        o_flg_independent   => l_flg_independent, --EFR "Independente"
                                        o_num_health_plan   => l_num_health_plan,
                                        o_hp_entity         => l_hp_entity,
                                        o_id_health_plan    => l_id_health_plan,
                                        o_flg_recm          => l_dummy,
                                        o_main_phone        => l_dummy,
                                        --o_flg_indfess           => l_flg_indfess,
                                        o_hp_alpha2_code        => l_hp_alpha2_code,
                                        o_hp_country_desc       => l_dummy,
                                        o_hp_national_ident_nbr => l_hp_national_ident_nbr,
                                        o_hp_dt_effective       => l_hp_dt_effective,
                                        o_valid_hp              => l_dummy,
                                        o_flg_type_hp           => l_dummy,
                                        o_hp_id_content         => l_dummy,
                                        o_hp_inst_ident_nbr     => l_dummy,
                                        o_hp_inst_ident_desc    => l_dummy,
                                        o_hp_dt_valid           => l_dummy,
                                        o_error                 => o_error);
    
        IF NOT g_retval
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_pat_dt_birth IS NOT NULL
        THEN
            g_error := 'Call pk_date_utils.get_string_tstz l_pat_dt_birth is not null';
            pk_alertlog.log_debug(g_error);
        
            g_retval := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => l_pat_dt_birth,
                                                      i_timezone  => NULL,
                                                      i_mask      => pk_sysconfig.get_config('DATE_FORMAT', i_prof),
                                                      o_timestamp => l_pat_dt_birth_tstz,
                                                      o_error     => o_error);
        
            IF NOT g_retval
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_pat_dt_birth_tstz := NULL;
        END IF;
    
        IF l_hp_dt_effective IS NOT NULL
        THEN
            g_error := 'Call pk_date_utils.get_string_tstz l_hp_dt_effective is not null';
            pk_alertlog.log_debug(g_error);
        
            g_retval := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => l_hp_dt_effective,
                                                      i_timezone  => NULL,
                                                      i_mask      => pk_sysconfig.get_config('DATE_FORMAT', i_prof),
                                                      o_timestamp => l_hp_dt_effective_tstz,
                                                      o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_hp_dt_effective_tstz := NULL;
        END IF;
    
        g_error := 'Call pk_doc.get_migrant_doc i_id_patient=' || i_patient;
        pk_alertlog.log_debug(g_error);
        /* IF NOT pk_doc.get_migrant_doc(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_patient => i_patient,
                                          o_num_doc    => l_num_doc,
                                          o_exist_doc  => l_exist_migrator_doc,
                                          o_dt_expire  => l_dt_expire,
                                          o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        */
        IF l_dt_expire IS NOT NULL
        THEN
            g_error := 'Call pk_date_utils.get_string_tstz l_dt_expire =' || l_dt_expire;
            pk_alertlog.log_debug(g_error);
        
            g_retval := pk_date_utils.get_string_tstz(i_lang      => 1,
                                                      i_prof      => i_prof,
                                                      i_timestamp => to_char(l_dt_expire,
                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                      i_timezone  => NULL,
                                                      o_timestamp => l_dt_expire_tstz,
                                                      o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE l_exception;
            END IF;
        
        ELSE
            l_dt_expire_tstz := NULL;
        END IF;
    
        IF nvl(l_exist_migrator_doc, pk_alert_constant.g_no) = pk_alert_constant.g_no
        THEN
            l_doc_type := NULL;
        END IF;
    
        l_flg_indfess     := nvl(l_flg_indfess, pk_alert_constant.g_no);
        l_flg_migrator    := nvl(l_flg_migrator, pk_alert_constant.g_no);
        l_flg_occ_disease := nvl(l_flg_occ_disease, pk_alert_constant.g_no);
    
        g_error := 'INSERT INTO bdnp_presc_detail';
        pk_alertlog.log_debug(g_error);
        INSERT INTO bdnp_presc_detail
            (flg_presc_type,
             id_presc,
             id_patient,
             name,
             gender,
             dt_birth,
             flg_migrator,
             id_country_nation,
             sns,
             flg_occ_disease,
             flg_independent,
             id_health_plan,
             num_health_plan,
             migrator_num_doc,
             dt_mig_doc_expire,
             id_mig_doc_type,
             flg_indfess,
             hp_alpha2_code,
             hp_national_ident_nbr,
             hp_dt_effective,
             flg_isencao,
             mcdt_nature)
        VALUES
            (i_type,
             i_presc,
             i_patient,
             l_pat_name,
             l_pat_gender,
             l_pat_dt_birth_tstz,
             l_flg_migrator,
             l_pat_birth_place,
             l_sns,
             l_flg_occ_disease,
             l_flg_independent,
             l_id_health_plan,
             l_num_health_plan,
             l_num_doc,
             l_dt_expire_tstz,
             NULL,
             l_flg_indfess,
             l_hp_alpha2_code,
             l_hp_national_ident_nbr,
             l_hp_dt_effective_tstz,
             i_flg_isencao,
             i_mcdt_nature);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_BDNP',
                                                     i_function => 'SET_BDNP_PRESC_DETAIL',
                                                     o_error    => o_error);
        
    END set_bdnp_presc_detail;

    FUNCTION set_bdnp_presc_tracking
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_bdnp_presc_tracking IN bdnp_presc_tracking%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INSERT INTO bdnp_presc_tracking';
        INSERT INTO bdnp_presc_tracking
            (id_presc_tracking,
             id_presc,
             flg_presc_type,
             dt_presc_tracking,
             dt_event,
             flg_event_type,
             id_prof_event,
             id_bdnp_message,
             flg_message_type,
             desc_interf_message,
             id_institution)
        VALUES
            (seq_bdnp_presc_tracking.nextval,
             i_bdnp_presc_tracking.id_presc,
             i_bdnp_presc_tracking.flg_presc_type,
             nvl(i_bdnp_presc_tracking.dt_presc_tracking, current_timestamp),
             nvl(i_bdnp_presc_tracking.dt_event, current_timestamp),
             i_bdnp_presc_tracking.flg_event_type,
             nvl(i_bdnp_presc_tracking.id_prof_event, i_prof.id),
             i_bdnp_presc_tracking.id_bdnp_message,
             i_bdnp_presc_tracking.flg_message_type,
             i_bdnp_presc_tracking.desc_interf_message,
             i_bdnp_presc_tracking.id_institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_BDNP_PRESC_TRACKING',
                                                     o_error    => o_error);
    END set_bdnp_presc_tracking;

    FUNCTION check_patient_rules
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN alert.profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_type           IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sns                   pat_health_plan.num_health_plan%TYPE; --Numero SNS
        l_num_health_plan       pat_health_plan.num_health_plan%TYPE; --Numero sns/seguro saude/etc
        l_pat_name              patient.name%TYPE; --Nome paciente
        l_pat_dt_birth          VARCHAR2(200); --Data de nascimento
        l_pat_gender            patient.gender%TYPE; --Género
        l_pat_birth_place       country.alpha2_code%TYPE; --Nacionalidade
        l_id_health_plan        pat_health_plan.id_health_plan%TYPE;
        l_hp_entity             VARCHAR2(4000);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_flg_occ_disease       VARCHAR2(1);
        l_flg_independent       VARCHAR2(1);
        l_exist_migrator_doc    VARCHAR2(1);
        l_dummy                 VARCHAR2(4000);
        l_new_line              VARCHAR2(20) := '<br><br>';
        l_dt_expire             doc_external.dt_expire%TYPE;
        l_num_doc               doc_external.num_doc%TYPE;
        l_flg_indfess           VARCHAR2(1 CHAR);
        l_hp_alpha2_code        VARCHAR2(4000);
        l_hp_national_ident_nbr VARCHAR2(4000);
        l_check_date            VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_hp_dt_effective   VARCHAR2(200); --Data de nascimento
        l_hp_dt_health_plan DATE;
        l_valid_hp          VARCHAR2(200);
        l_doc_type          doc_type.id_doc_type%TYPE;
    
        CURSOR c_inst_type(x_inst institution.id_institution%TYPE) IS
            SELECT i.flg_type
              FROM institution i
             WHERE i.id_institution = x_inst;
    
        l_inst_type c_inst_type%ROWTYPE;
    
        l_o_id_doc_type doc_type.id_content%TYPE;
    BEGIN
        pk_alertlog.log_debug('INIT pk_bdnp.check_patient_rules i_type=' || i_type);
        -- build cancellation confirmation messsage
        o_flg_show := pk_alert_constant.g_no;
        -- get institution type
    
        g_error := 'OPEN c_inst_type';
        OPEN c_inst_type(i_prof.institution);
        FETCH c_inst_type
            INTO l_inst_type;
        CLOSE c_inst_type;
    
        g_error := 'Call pk_adt.get_pat_info i_patient=' || i_patient;
        IF NOT pk_adt.get_pat_info(i_lang              => i_lang,
                                   i_id_patient        => i_patient,
                                   i_prof              => i_prof,
                                   i_id_episode        => i_episode,
                                   o_name              => l_pat_name,
                                   o_gender            => l_pat_gender,
                                   o_desc_gender       => l_dummy,
                                   o_dt_birth          => l_pat_dt_birth,
                                   o_dt_deceased       => l_dummy,
                                   o_flg_migrator      => l_flg_migrator,
                                   o_id_country_nation => l_pat_birth_place,
                                   o_sns               => l_sns,
                                   o_valid_sns         => l_dummy,
                                   o_flg_occ_disease   => l_flg_occ_disease, --Doente profissional : CNPRP
                                   o_flg_independent   => l_flg_independent, --EFR "Independente"
                                   o_num_health_plan   => l_num_health_plan,
                                   o_hp_entity         => l_hp_entity,
                                   o_id_health_plan    => l_id_health_plan,
                                   o_flg_recm          => l_dummy,
                                   o_main_phone        => l_dummy,
                                   --o_flg_indfess           => l_flg_indfess,
                                   o_hp_alpha2_code        => l_hp_alpha2_code,
                                   o_hp_country_desc       => l_dummy,
                                   o_hp_national_ident_nbr => l_hp_national_ident_nbr,
                                   o_hp_dt_effective       => l_hp_dt_effective,
                                   --o_hp_dt_health_plan     => l_hp_dt_health_plan,
                                   o_valid_hp          => l_valid_hp,
                                   o_flg_type_hp       => l_dummy,
                                   o_hp_id_content     => l_dummy,
                                   o_hp_inst_ident_nbr => l_dummy,
                                   o_hp_inst_ident_desc => l_dummy,
                                   o_hp_dt_valid       => l_dummy,
                                   o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --Obter informação de documento de migrante. Se tem doc ou não, e o número do doc se for necessário
        g_error := 'Call pk_doc.get_migrant_doc i_patient=' || i_patient;
        IF NOT pk_doc.get_migrant_doc(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_patient          => i_patient,
                                      o_num_doc             => l_num_doc,
                                      o_exist_doc           => l_exist_migrator_doc,
                                      o_dt_expire           => l_dt_expire,
                                      o_doc_type            => l_doc_type,
                                      o_id_content_doc_type => l_o_id_doc_type,
                                      o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Call pk_date_utils.compare_dates_tsz i_date1=' || l_dt_expire || ' i_date2=' || current_timestamp;
        pk_alertlog.log_debug(g_error);
    
        l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                        i_date1 => l_dt_expire,
                                                        i_date2 => current_timestamp);
    
        --Validate data >>>
        --Caso 1 - Nacional só SNS - não obriga a ter nº beneficiário
        IF l_sns IS NOT NULL --Nº utente SNS
           AND l_pat_name IS NOT NULL --Nome
           AND l_pat_dt_birth IS NOT NULL --data nascimento
           AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) -- Masculino ou Feminio
           AND l_pat_birth_place IS NOT NULL --Nacionalidade
          --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
           AND l_id_health_plan = pk_sysconfig.get_config('IDENT_ID_HEALTH_PLAN', i_prof) --é só SNS
           AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional só SNS - não obriga a ter nº beneficiário');
            RETURN TRUE;
            --Caso 5 - Nacional com numero de beneficiário
        ELSIF l_sns IS NOT NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL --Sexo
              /*AND ((l_pat_gender IN ('F', 'M') AND l_inst_type.flg_type != 'H') OR
                                                                                                                                                                                       (l_pat_gender IN ('F', 'M', 'I') AND l_inst_type.flg_type = 'H'))*/
              OR l_pat_gender NOT IN ('F', 'M'))
              AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional com numero de beneficiário');
            RETURN TRUE;
            --Caso 2 - Migrante com documento
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL --Sexo
              /*  AND ((l_pat_gender IN ('F', 'M') AND l_inst_type.flg_type != 'H') OR
                                                                                                                                                                                       (l_pat_gender IN ('F', 'M', 'I') AND l_inst_type.flg_type = 'H'))*/
              OR l_pat_gender NOT IN ('F', 'M'))
              AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
              AND l_flg_migrator = pk_alert_constant.g_yes --é migrante
              AND l_exist_migrator_doc = pk_alert_constant.g_yes --tem documento
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_hp_national_ident_nbr IS NOT NULL
              AND l_dt_expire IS NOT NULL
              AND l_num_doc IS NOT NULL
              AND l_hp_alpha2_code IS NOT NULL
              AND l_check_date <> 'L'
        THEN
            pk_alertlog.log_info('Migrante com documento');
            RETURN TRUE;
            --Caso 3 - Nacional sem SNS, nem é doente profissional, mas outra entidade financeira
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL
              /*AND ((l_pat_gender IN ('F', 'M') AND l_inst_type.flg_type != 'H') OR
                                                                                                                                                                                       (l_pat_gender IN ('F', 'M', 'I') AND l_inst_type.flg_type = 'H'))*/
              OR l_pat_gender NOT IN ('F', 'M')) --Sexo
              AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
              AND l_id_health_plan <> pk_sysconfig.get_config('IDENT_ID_HEALTH_PLAN', i_prof) --entidade fin não é SNS
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional sem SNS, nem é doente profissional, mas outra entidade financeira');
            RETURN TRUE;
            --Caso 4 - Migrante sem documento mas com EFR Independente
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL
              /* AND ((l_pat_gender IN ('F', 'M') AND l_inst_type.flg_type != 'H') OR
                                                                                                                                                                                       (l_pat_gender IN ('F', 'M', 'I') AND l_inst_type.flg_type = 'H'))*/
              OR l_pat_gender NOT IN ('F', 'M')) --Sexo
              AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
             --AND l_flg_migrator = pk_alert_constant.g_yes --é migrante
              AND l_flg_independent = pk_alert_constant.g_yes --tem EFR independente
        THEN
            pk_alertlog.log_info('Migrante sem documento mas com EFR Independente');
            RETURN TRUE;
            -- caso doente profissional
        ELSIF l_sns IS NOT NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) --Sexo
             /* AND ((l_pat_gender IN ('F', 'M') AND l_inst_type.flg_type != 'H') OR
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              (l_pat_gender IN ('F', 'M', 'I') AND l_inst_type.flg_type = 'H'))*/
              AND l_pat_birth_place IS NOT NULL --Nacionalidade
              AND l_id_health_plan = pk_sysconfig.get_config('HEALTH_PLAN_OCCUP_DISEASE', i_prof) --entidade fin não é SNS
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_flg_occ_disease = pk_alert_constant.g_yes
        THEN
            pk_alertlog.log_info('caso doente profissional');
            RETURN TRUE;
        ELSE
        
            o_flg_show := pk_alert_constant.g_yes;
        
            g_error          := 'get_messages for missing health plan number';
            o_message_title  := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M015');
            o_forward_button := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M017');
            o_back_button    := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M016');
        
            --Se não ten n. SNS
            IF l_sns IS NULL
            --AND l_num_health_plan IS NULL --l_hp_entity IS NULL --l_pat_entity IN ('SNS', 'CNPRP')
            THEN
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T015'); --Mensagem utente SNS não foi preenchido
            END IF;
            --Se não tem outro número (seg. saúde por exemplo)
            IF l_num_health_plan IS NULL --l_hp_entity IS NULL
            THEN
                pk_alertlog.log_info('l_num_health_plan IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T016'); --Mensagem entidade financeira não foi preenchido
            END IF;
            --Se não tem nome
            IF l_pat_name IS NULL
            THEN
                pk_alertlog.log_info('l_pat_name IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T017'); --Mensagem nome paciente não foi preenchido
            END IF;
            --Se não tem género
            IF l_pat_gender IS NULL
            THEN
                pk_alertlog.log_info('l_pat_gender IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T018'); --Mensagem sexo não foi preenchido
            END IF;
        
            IF l_pat_gender NOT IN ('F', 'M')
            THEN
                pk_alertlog.log_info('l_pat_gender IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T024'); -- Género deve ser Masculino ou Fiminino
            END IF;
            --Se não tem data de nascimento
            IF l_pat_dt_birth IS NULL
            THEN
                pk_alertlog.log_info('l_pat_dt_birth IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T019'); --Mensagem data nascimento não foi preenchido
            END IF;
            --Se não tem nacionalidade
            IF l_pat_birth_place IS NULL
            THEN
                pk_alertlog.log_info('l_pat_birth_place IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T020'); --Mensagem nacionalidade não foi preenchido
            END IF;
        
            IF l_dt_expire IS NULL
               AND l_exist_migrator_doc = pk_alert_constant.g_yes
            THEN
                pk_alertlog.log_info('l_dt_expire IS NULL and l_exist_migrator_doc = Y');
                IF o_message_text IS NOT NULL
                   AND l_exist_migrator_doc = pk_alert_constant.g_yes
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T021'); --Mensagem da data de validade do CESD ou CPS não foi preenchida
            END IF;
        
            IF l_num_doc IS NULL
               AND l_exist_migrator_doc = pk_alert_constant.g_yes
            THEN
                pk_alertlog.log_info('l_num_doc IS NULL and l_exist_migrator_doc = Y');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T022'); --Mensagem O número do CESD ou CPS não foi preenchido.
            END IF;
        
            IF l_check_date = 'L'
            THEN
                pk_alertlog.log_info('l_check_date = L');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T023'); --Mensagem data de validade do CESD ou CPS esprirou.
            END IF;
        
            o_message_text := '<b>' || o_message_text || '</b>';
        
        END IF;
    
        --Validate data <<<
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_flg_show := 'N';
            RETURN FALSE;
        
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_BDNP',
                                                     i_function => 'CHECK_PATIENT_RULES',
                                                     o_error    => o_error);
        
    END check_patient_rules;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_bdnp;
/
