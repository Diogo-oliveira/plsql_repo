CREATE OR REPLACE PACKAGE BODY pk_backoffice_api_ui IS

    -- Author  : MAURO.SOUSA
    -- Created : 29-06-2010 15:57:45
    -- Purpose : To be facilitate Java Service Generation Request for UX layer

    --------------> STATIC VARIABLES
    g_error VARCHAR2(1000 CHAR);
    -- Package info
    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE_API_UI';
    g_function_name VARCHAR(30);
    ---- END of STATIC VARIABLES --<
    /********************************************************************************************
    * Shows all available Languages
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_language               Languages list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Mauro.Sousa
    * @version                        2.6.0.4
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_language OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_LANGUAGE_LIST';
        pk_alertlog.log_debug(g_error);
    
        RETURN pk_backoffice.get_language_list(i_lang, i_prof, o_language, o_error);
    
    END get_language_list;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param i_id_professional       Professional to search
    * @param o_def_lang              default id_language to return
    * @param o_def_cat               default id_category to return
    * @param o_error               error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/09/12
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_wizard_defvals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_def_lang        OUT language.id_language%TYPE,
        o_def_cat         OUT category.id_category%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(100 CHAR) := 'get_wizard_defvals';
    
        l_def_cat  category.id_category%TYPE;
        l_def_lang language.id_language%TYPE;
    BEGIN
        -- get default most frequent category
        SELECT nvl((SELECT counter.id_category
                     FROM (SELECT COUNT(*) res, x.id_category
                             FROM prof_cat x
                            WHERE x.id_professional = i_id_professional
                            GROUP BY x.id_category
                           HAVING COUNT(*) > 0
                            ORDER BY 1 DESC) counter
                    WHERE rownum = 1),
                   0)
          INTO l_def_cat
          FROM dual;
        -- get default most frequent languge
        SELECT nvl((SELECT counter.id_language
                     FROM (SELECT COUNT(*) res, pp.id_language
                             FROM prof_preferences pp
                            WHERE pp.id_professional = i_id_professional
                            GROUP BY pp.id_language
                           HAVING COUNT(*) > 0) counter
                    WHERE rownum = 1),
                   (SELECT il.id_language
                      FROM institution_language il
                     WHERE il.id_institution = i_prof.institution
                       AND rownum = 1))
          INTO l_def_lang
          FROM dual;
    
        IF l_def_lang IS NULL
        THEN
            o_def_lang := NULL;
        ELSE
            o_def_lang := l_def_lang;
        END IF;
        IF (l_def_cat IS NULL OR l_def_cat = 0)
        THEN
            o_def_cat := NULL;
        ELSE
            o_def_cat := l_def_cat;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_wizard_defvals;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param o_title               default id_category to return
    * @param o_error               error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/11/21
    * @version                       2.6.1.5.1
    ********************************************************************************************/
    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*21/11/2011: ALERT-205187 get values by market using pipelined method */
        l_domain_title CONSTANT sys_domain.code_domain%TYPE := 'PROFESSIONAL.TITLE';
    BEGIN
        g_function_name := upper('get_prof_title_list');
        g_error         := 'GET CURSOR';
        OPEN o_title FOR
            SELECT tl.val, tl.desc_val, 0 AS rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_title, NULL)) tl
            UNION
            SELECT '-1' AS val, sm.desc_message, 10 AS rank
              FROM sys_message sm
             WHERE sm.code_message = 'COMMON_M041'
               AND sm.id_language = i_lang
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_title);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_prof_title_list;
    /********************************************************************************************
    * Returns bollean (true or false)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional identifier
    * @param o_at_list               returns adress type list
    * @param o_error                 error to process
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/01/24
    * @version                       2.6.2.0.6
    ********************************************************************************************/
    FUNCTION get_adress_type_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_profinst IN VARCHAR2,
        o_at_list      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*24/01/2012: ALERT-214329 get values by market using pipelined method values to institution same to professional*/
        l_domain_title sys_domain.code_domain%TYPE;
    BEGIN
        g_function_name := upper('get_adress_type_list');
        IF i_flg_profinst = 'P'
        THEN
            l_domain_title := 'PROFESSIONAL.ADRESS_TYPE';
            g_error        := 'GET CURSOR';
            OPEN o_at_list FOR
                SELECT tl.val, tl.desc_val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_title, NULL)) tl
                 ORDER BY tl.desc_val;
        ELSIF i_flg_profinst = 'I'
        THEN
            l_domain_title := 'AB_INSTITUTION.ADRESS_TYPE';
            g_error        := 'GET CURSOR';
            OPEN o_at_list FOR
                SELECT tl.val, tl.desc_val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_title, NULL)) tl
                 ORDER BY tl.desc_val;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_at_list);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_adress_type_list;
    /********************************************************************************************
    * Returns the professional id created or updated
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_PROF                  Identificação do Profissional
    * @param      --I_NAME                     Nome
    * @param      I_TITLE                    Título
    * @param      I_FIRST_NAME               Primeiro nome
    * @param      I_MIDDLE_NAME              Nomes do meio
    * @param      I_LAST_NAME                Último nome
    * @param      I_NICK_NAME                Nome abreviado
    * @param      I_INITIALS                 Iniciais do nome
    * @param      I_DT_BIRTH                 Data de nascimento
    * @param      I_GENDER                   Sexo
    * @param      I_MARITAL_STATUS           Estado civil
    * @param      I_ID_CATEGORY              Identificador da categoria
    * @param      I_ID_SPECIALITY            Identificador da especialidade
    * @param      I_NUM_ORDER                Número da ordem
    * @param      I_UPIN                     UPIN
    * @param      I_DEA                      DEA
    * @param      I_ID_CAT_SURGERY           Identificador da categoria em cirurgia
    * @param      I_NUM_MECAN                Número mecanográfico
    * @param      I_ID_LANG                  Identificador da língua
    * @param      I_FLG_STATE                Estado
    * @param      I_ADDRESS                  Morada
    * @param      I_CITY                     Localidade
    * @param      I_DISTRICT                 Concelho
    * @param      I_ZIP_CODE                 Código postal
    * @param      I_ID_COUNTRY               Identificador do país
    * @param      I_WORK_PHONE               Telefone do trabalho
    * @param      I_NUM_CONTACT              Telefone de casa
    * @param      I_CELL_PHONE               Telemóvel
    * @param      I_FAX                      Fax
    * @param      I_EMAIL                    E-mail
    * @param      I_ADRESS_TYPE              Adress_type
    * @param      O_ERROR                    Erro
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/01/24
    * @version                       2.6.2.0.6
    ********************************************************************************************/
    FUNCTION set_professional
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_prof           IN professional.id_professional%TYPE,
        i_title             IN professional.title%TYPE,
        i_first_name        IN professional.first_name%TYPE,
        i_middle_name       IN professional.middle_name%TYPE,
        i_last_name         IN professional.last_name%TYPE,
        i_nick_name         IN professional.nick_name%TYPE,
        i_initials          IN professional.initials%TYPE,
        i_dt_birth          IN VARCHAR2,
        i_gender            IN professional.gender%TYPE,
        i_marital_status    IN professional.marital_status%TYPE,
        i_id_category       IN category.id_category%TYPE,
        i_id_speciality     IN professional.id_speciality%TYPE,
        i_num_order         IN professional.num_order%TYPE,
        i_upin              IN professional.upin%TYPE,
        i_dea               IN professional.dea%TYPE,
        i_id_cat_surgery    IN category.id_category%TYPE,
        i_num_mecan         IN prof_institution.num_mecan%TYPE,
        i_id_lang           IN prof_preferences.id_language%TYPE,
        i_flg_state         IN prof_institution.flg_state%TYPE,
        i_address           IN professional.address%TYPE,
        i_city              IN professional.city%TYPE,
        i_district          IN professional.district%TYPE,
        i_zip_code          IN professional.zip_code%TYPE,
        i_id_country        IN professional.id_country%TYPE,
        i_work_phone        IN professional.work_phone%TYPE,
        i_num_contact       IN professional.num_contact%TYPE,
        i_cell_phone        IN professional.cell_phone%TYPE,
        i_fax               IN professional.fax%TYPE,
        i_email             IN professional.email%TYPE,
        i_adress_type       IN professional.adress_type%TYPE,
        i_id_scholarship    IN professional.id_scholarship%TYPE,
        i_agrupacion        IN professional.id_agrupacion%TYPE,
        i_id_road           IN professional.id_road%TYPE,
        i_entity            IN professional.id_entity%TYPE,
        i_jurisdiction      IN professional.id_jurisdiction%TYPE,
        i_municip           IN professional.id_municip%TYPE,
        i_localidad         IN professional.id_localidad%TYPE,
        i_id_postal_code_rb IN professional.id_postal_code_rb%TYPE,
        i_bleep_num         IN professional.bleep_number%TYPE,
        i_suffix            IN professional.suffix%TYPE,
        i_contact_det       IN prof_institution.contact_detail%TYPE,
        i_county            IN professional.county%TYPE,
        i_other_adress      IN professional.address_other_name%TYPE,
        i_commit_at_end     IN BOOLEAN,
        i_parent_name       IN professional.parent_name%TYPE,
        i_first_name_sa     IN professional.first_name_sa%TYPE,
        i_parent_name_sa    IN professional.parent_name_sa%TYPE,
        i_middle_name_sa    IN professional.middle_name_sa%TYPE,
        i_last_name_sa      IN professional.last_name_sa%TYPE,
        i_doc_ident_type    IN prof_doc.id_doc_type%TYPE,
        i_doc_ident_num     IN prof_doc.value%TYPE,
        i_doc_ident_val     IN VARCHAR2,
        o_id_prof           OUT professional.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_prof_inst_pk prof_institution.id_prof_institution%TYPE := 0;
        -- ALERT-308439
        l_hist_op  professional_hist.id_operation%TYPE := 0;
        l_rows_upd table_varchar := table_varchar();
    BEGIN
        g_function_name := upper('set_professional');
        g_error         := 'INSERT PROFESSIONAL';
        IF NOT pk_backoffice.set_professional(i_lang,
                                              i_id_institution,
                                              i_id_prof,
                                              i_title,
                                              i_first_name,
                                              i_middle_name,
                                              i_last_name,
                                              i_nick_name,
                                              i_initials,
                                              i_dt_birth,
                                              i_gender,
                                              i_marital_status,
                                              i_id_category,
                                              i_id_speciality,
                                              i_id_scholarship,
                                              i_num_order,
                                              i_upin,
                                              i_dea,
                                              i_id_cat_surgery,
                                              i_num_mecan,
                                              i_id_lang,
                                              i_flg_state,
                                              i_address,
                                              i_city,
                                              i_district,
                                              i_zip_code,
                                              i_id_country,
                                              i_work_phone,
                                              i_num_contact,
                                              i_cell_phone,
                                              i_fax,
                                              i_email,
                                              i_commit_at_end,
                                              i_id_road,
                                              i_entity,
                                              i_jurisdiction,
                                              i_municip,
                                              i_localidad,
                                              i_id_postal_code_rb,
                                              i_parent_name,
                                              i_first_name_sa,
                                              i_parent_name_sa,
                                              i_middle_name_sa,
                                              i_last_name_sa,
                                              i_agrupacion,
                                              i_adress_type,
                                              i_bleep_num,
                                              i_suffix,
                                              i_county,
                                              i_other_adress,
                                              i_contact_det,
                                              i_doc_ident_type,
                                              i_doc_ident_num,
                                              i_doc_ident_val,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              o_id_prof,
                                              o_error)
        THEN
            g_error := 'ERROR INSERT PROFESSIONAL';
            RAISE l_exception;
        ELSE
            g_error := 'UPDATE PROFESSIONAL' || nvl(o_id_prof, i_id_prof);
            -- ALERT-308439
            l_hist_op := pk_backoffice.get_prof_hist_pk(o_id_prof);
            IF l_hist_op > 0
            THEN
                ts_professional_hist.upd(id_operation_in        => l_hist_op,
                                         adress_type_in         => i_adress_type,
                                         adress_type_nin        => FALSE,
                                         bleep_number_in        => i_bleep_num,
                                         bleep_number_nin       => FALSE,
                                         suffix_in              => i_suffix,
                                         suffix_nin             => FALSE,
                                         county_in              => i_county,
                                         county_nin             => FALSE,
                                         address_other_name_in  => i_other_adress,
                                         address_other_name_nin => FALSE,
                                         rows_out               => l_rows_upd);
            END IF;
        END IF;
    
        IF i_commit_at_end
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_professional;

    FUNCTION set_professional
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_prof                 IN professional.id_professional%TYPE,
        i_title                   IN professional.title%TYPE,
        i_first_name              IN professional.first_name%TYPE,
        i_middle_name             IN professional.middle_name%TYPE,
        i_last_name               IN professional.last_name%TYPE,
        i_nick_name               IN professional.nick_name%TYPE,
        i_initials                IN professional.initials%TYPE,
        i_dt_birth                IN VARCHAR2,
        i_gender                  IN professional.gender%TYPE,
        i_marital_status          IN professional.marital_status%TYPE,
        i_id_category             IN category.id_category%TYPE,
        i_id_speciality           IN professional.id_speciality%TYPE,
        i_num_order               IN professional.num_order%TYPE,
        i_upin                    IN professional.upin%TYPE,
        i_dea                     IN professional.dea%TYPE,
        i_id_cat_surgery          IN category.id_category%TYPE,
        i_num_mecan               IN prof_institution.num_mecan%TYPE,
        i_id_lang                 IN prof_preferences.id_language%TYPE,
        i_flg_state               IN prof_institution.flg_state%TYPE,
        i_address                 IN professional.address%TYPE,
        i_city                    IN professional.city%TYPE,
        i_district                IN professional.district%TYPE,
        i_zip_code                IN professional.zip_code%TYPE,
        i_id_country              IN professional.id_country%TYPE,
        i_work_phone              IN professional.work_phone%TYPE,
        i_num_contact             IN professional.num_contact%TYPE,
        i_cell_phone              IN professional.cell_phone%TYPE,
        i_fax                     IN professional.fax%TYPE,
        i_email                   IN professional.email%TYPE,
        i_adress_type             IN professional.adress_type%TYPE,
        i_id_scholarship          IN professional.id_scholarship%TYPE,
        i_agrupacion              IN professional.id_agrupacion%TYPE,
        i_id_road                 IN professional.id_road%TYPE,
        i_entity                  IN professional.id_entity%TYPE,
        i_jurisdiction            IN professional.id_jurisdiction%TYPE,
        i_municip                 IN professional.id_municip%TYPE,
        i_localidad               IN professional.id_localidad%TYPE,
        i_id_postal_code_rb       IN professional.id_postal_code_rb%TYPE,
        i_bleep_num               IN professional.bleep_number%TYPE,
        i_suffix                  IN professional.suffix%TYPE,
        i_contact_det             IN prof_institution.contact_detail%TYPE,
        i_county                  IN professional.county%TYPE,
        i_other_adress            IN professional.address_other_name%TYPE,
        i_commit_at_end           IN BOOLEAN,
        i_parent_name             IN professional.parent_name%TYPE,
        i_first_name_sa           IN professional.first_name_sa%TYPE,
        i_parent_name_sa          IN professional.parent_name_sa%TYPE,
        i_middle_name_sa          IN professional.middle_name_sa%TYPE,
        i_last_name_sa            IN professional.last_name_sa%TYPE,
        i_doc_ident_type          IN prof_doc.id_doc_type%TYPE,
        i_doc_ident_num           IN prof_doc.value%TYPE,
        i_doc_ident_val           IN VARCHAR2,
        i_tin                     IN professional.taxpayer_number%TYPE,
        i_clinical_name           IN professional.clinical_name%TYPE,
        i_prof_spec_id            IN table_number,
        i_prof_spec_ballot        IN table_varchar,
        i_prof_spec_id_university IN table_number,
        i_agrupacion_instit_id    IN professional.id_agrupacion_instit%TYPE,
        o_id_prof                 OUT professional.id_professional%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_prof_inst_pk prof_institution.id_prof_institution%TYPE := 0;
        -- ALERT-308439
        l_hist_op  professional_hist.id_operation%TYPE := 0;
        l_rows_upd table_varchar := table_varchar();
    BEGIN
        g_function_name := upper('set_professional');
        g_error         := 'INSERT PROFESSIONAL';
        IF NOT pk_backoffice.set_professional(i_lang,
                                              i_id_institution,
                                              i_id_prof,
                                              i_title,
                                              i_first_name,
                                              i_middle_name,
                                              i_last_name,
                                              i_nick_name,
                                              i_initials,
                                              i_dt_birth,
                                              i_gender,
                                              i_marital_status,
                                              i_id_category,
                                              i_id_speciality,
                                              i_id_scholarship,
                                              i_num_order,
                                              i_upin,
                                              i_dea,
                                              i_id_cat_surgery,
                                              i_num_mecan,
                                              i_id_lang,
                                              i_flg_state,
                                              i_address,
                                              i_city,
                                              i_district,
                                              i_zip_code,
                                              i_id_country,
                                              i_work_phone,
                                              i_num_contact,
                                              i_cell_phone,
                                              i_fax,
                                              i_email,
                                              i_commit_at_end,
                                              i_id_road,
                                              i_entity,
                                              i_jurisdiction,
                                              i_municip,
                                              i_localidad,
                                              i_id_postal_code_rb,
                                              i_parent_name,
                                              i_first_name_sa,
                                              i_parent_name_sa,
                                              i_middle_name_sa,
                                              i_last_name_sa,
                                              i_agrupacion,
                                              i_adress_type,
                                              i_bleep_num,
                                              i_suffix,
                                              i_county,
                                              i_other_adress,
                                              i_contact_det,
                                              i_doc_ident_type,
                                              i_doc_ident_num,
                                              i_doc_ident_val,
                                              i_tin,
                                              i_clinical_name,
                                              i_prof_spec_id,
                                              i_prof_spec_ballot,
                                              i_prof_spec_id_university,
                                              i_agrupacion_instit_id,
                                              o_id_prof,
                                              o_error)
        THEN
            g_error := 'ERROR INSERT PROFESSIONAL';
            RAISE l_exception;
        ELSE
            g_error := 'UPDATE PROFESSIONAL' || nvl(o_id_prof, i_id_prof);
            -- ALERT-308439
            l_hist_op := pk_backoffice.get_prof_hist_pk(o_id_prof);
            IF l_hist_op > 0
            THEN
                ts_professional_hist.upd(id_operation_in        => l_hist_op,
                                         adress_type_in         => i_adress_type,
                                         adress_type_nin        => FALSE,
                                         bleep_number_in        => i_bleep_num,
                                         bleep_number_nin       => FALSE,
                                         suffix_in              => i_suffix,
                                         suffix_nin             => FALSE,
                                         county_in              => i_county,
                                         county_nin             => FALSE,
                                         address_other_name_in  => i_other_adress,
                                         address_other_name_nin => FALSE,
                                         rows_out               => l_rows_upd);
            END IF;
        END IF;
    
        IF i_commit_at_end
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_professional;

    /********************************************************************************************
    * Insert New Institution OR Update Institution Information
     *
     * @param      I_LANG                               Language identification
     * @param      I_ID_INSTITUTION                     Institution identification
     * @param      i_id_inst_att                        Institution attributes
     * @param      i_id_inst_lang                       Institution language
     * @param      I_DESC                               Institution description
     * @param      i_id_parent                          Institution parent
     * @param      I_FLG_TYPE                           Institution type: H - Hospital, C - Primary Care, P - Private Practice
     * @param      i_tax                                Social security number
     * @param      I_ABBREVIATION                       Abreviation
     * @param      i_pref_lang                          Institution language
     * @param      i_currency                           Currency
     * @param      I_PHONE_NUMBER                       Phone number
     * @param      i_fax                                Fax
     * @param      i_email                              Email
     * @param      i_adress                             Adress
     * @param      I_LOCATION                           Location
     * @param      i_geo_state                          District
     * @param      i_zip_code                           Zip code
     * @param      i_country                            Country
     * @param      i_location_tax                       Location tax
     * @param      i_lic_model                          Licence model
     * @param      i_pay_sched                          Payment schedule
     * @param      i_pay_opt                            Payment options
     * @param      I_FLG_AVAILABLE                      Flag available
     * @param      I_ADRESS_TYPE                        Adress_type
     * @param      i_id_tz_region                       id timezone region
     * @param      i_commit_at_end                      Commit at end
     * @param      O_ID_INSTITUTION                     Institution identification
     * @param      o_id_inst_attributes                 Institution attributes id
     * @param      o_id_inst_lang                       Institution Language identification
     * @param      O_ERROR
     *
     * @return                        true (sucess), false (error)
     *
     * @author                        RMGM
     * @since                         2012/01/24
     * @version                       2.6.2.0.6
     ********************************************************************************************/
    FUNCTION set_institution_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang   IN institution_language.id_institution_language%TYPE,
        i_desc           IN VARCHAR2,
        i_id_parent      IN institution.id_parent%TYPE,
        i_flg_type       IN institution.flg_type%TYPE,
        i_tax            IN inst_attributes.social_security_number%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_pref_lang      IN institution_language.id_language%TYPE,
        i_currency       IN inst_attributes.id_currency%TYPE,
        i_phone_number   IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_adress         IN institution.address%TYPE,
        i_location       IN institution.location%TYPE,
        i_geo_state      IN institution.district%TYPE,
        i_zip_code       IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_location_tax   IN inst_attributes.id_location_tax%TYPE,
        i_lic_model      IN inst_attributes.license_model%TYPE,
        i_pay_sched      IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt        IN inst_attributes.payment_options%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_id_tz_region   IN institution.id_timezone_region%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_adress_type    IN institution.adress_type%TYPE,
        i_contact_det    IN ab_institution.contact_detail%TYPE,
        
        i_county       IN ab_institution.county%TYPE,
        i_other_adress IN ab_institution.address_other_name%TYPE,
        
        i_commit_at_end IN BOOLEAN,
        
        i_clues              IN inst_attributes.clues%TYPE,
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE,
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE,
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_website            IN inst_attributes.website%TYPE,
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_institution_data');
        g_error         := 'INSERT INSTITUTION';
        IF NOT pk_backoffice.set_institution_data(i_lang,
                                                  i_id_institution,
                                                  i_id_inst_att,
                                                  i_id_inst_lang,
                                                  i_desc,
                                                  i_id_parent,
                                                  i_flg_type,
                                                  i_tax,
                                                  i_abbreviation,
                                                  i_pref_lang,
                                                  i_currency,
                                                  i_phone_number,
                                                  i_fax,
                                                  i_email,
                                                  i_adress,
                                                  i_location,
                                                  i_geo_state,
                                                  i_zip_code,
                                                  i_country,
                                                  i_location_tax,
                                                  i_lic_model,
                                                  i_pay_sched,
                                                  i_pay_opt,
                                                  i_flg_available,
                                                  i_id_tz_region,
                                                  i_id_market,
                                                  i_contact_det,
                                                  i_commit_at_end,
                                                  i_clues,
                                                  i_health_license,
                                                  i_flg_street_type,
                                                  i_street_name,
                                                  i_outdoor_number,
                                                  i_indoor_number,
                                                  i_id_settlement_type,
                                                  i_id_settlement_name,
                                                  i_id_entity,
                                                  i_id_municip,
                                                  i_id_localidad,
                                                  i_id_postal_code,
                                                  i_jurisdiction,
                                                  i_website,
                                                  o_id_institution,
                                                  o_id_inst_attributes,
                                                  o_id_inst_lang,
                                                  o_error)
        THEN
            g_error := 'ERROR set_institution_data';
            RAISE l_exception;
        END IF;
        g_error := 'update adress_type';
        pk_api_ab_tables.upd_ab_institution(id_ab_institution_in   => o_id_institution,
                                            adress_type_nin        => FALSE,
                                            adress_type_in         => i_adress_type,
                                            county_nin             => FALSE,
                                            address_other_name_nin => FALSE,
                                            county_in              => i_county,
                                            address_other_name_in  => i_other_adress);
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_institution_data;
    /********************************************************************************************
    * Insert New Institution OR Update Institution Information
     *
     * @param      I_LANG                               Language identification
     * @param      I_ID_INSTITUTION                     Institution identification
     * @param      i_id_inst_att                        Institution attributes
     * @param      i_id_inst_lang                       Institution language
     * @param      I_DESC                               Institution description
     * @param      i_id_parent                          Institution parent
     * @param      I_FLG_TYPE                           Institution type: H - Hospital, C - Primary Care, P - Private Practice
     * @param      i_tax                                Social security number
     * @param      I_ABBREVIATION                       Abreviation
     * @param      i_pref_lang                          Institution language
     * @param      i_currency                           Currency
     * @param      I_PHONE_NUMBER                       Phone number
     * @param      i_fax                                Fax
     * @param      i_email                              Email
     * @param      i_adress                             Adress
     * @param      I_LOCATION                           Location
     * @param      i_geo_state                          District
     * @param      i_zip_code                           Zip code
     * @param      i_country                            Country
     * @param      i_location_tax                       Location tax
     * @param      i_lic_model                          Licence model
     * @param      i_pay_sched                          Payment schedule
     * @param      i_pay_opt                            Payment options
     * @param      I_FLG_AVAILABLE                      Flag available
     * @param      I_ADRESS_TYPE                        Adress_type
     * @param      i_id_tz_region                       id timezone region
     * @param      i_commit_at_end                      Commit at end
     * @param      O_ID_INSTITUTION                     Institution identification
     * @param      o_id_inst_attributes                 Institution attributes id
     * @param      o_id_inst_lang                       Institution Language identification
     * @param      O_ERROR
     *
     * @return                        true (sucess), false (error)
     *
     * @author                        RMGM
     * @since                         2012/01/24
     * @version                       2.6.2.0.6
     ********************************************************************************************/
    FUNCTION set_inst_and_admin
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_clues              IN inst_attributes.clues%TYPE,
        i_id_inst_att        IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang       IN institution_language.id_institution_language%TYPE, --5
        i_desc               IN VARCHAR2,
        i_id_parent          IN institution.id_parent%TYPE,
        i_flg_type           IN institution.flg_type%TYPE,
        i_tax                IN inst_attributes.social_security_number%TYPE,
        i_abbreviation       IN institution.abbreviation%TYPE, --10
        i_pref_lang          IN institution_language.id_language%TYPE,
        i_currency           IN inst_attributes.id_currency%TYPE,
        i_phone_number       IN institution.phone_number%TYPE,
        i_fax                IN institution.fax_number%TYPE,
        i_email              IN inst_attributes.email%TYPE, --15
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_adress_type        IN institution.adress_type%TYPE,
        i_address            IN institution.address%TYPE,
        i_location           IN institution.location%TYPE,
        i_geo_state          IN institution.district%TYPE, --20
        i_zip_code           IN institution.zip_code%TYPE,
        i_country            IN inst_attributes.id_country%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE, --25
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE, --30
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_location_tax       IN inst_attributes.id_location_tax%TYPE,
        i_lic_model          IN inst_attributes.license_model%TYPE, --35
        i_pay_sched          IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt            IN inst_attributes.payment_options%TYPE,
        i_flg_available      IN institution.flg_available%TYPE,
        i_id_tz_region       IN institution.id_timezone_region%TYPE,
        i_id_market          IN market.id_market%TYPE, --40
        i_contact_det        IN ab_institution.contact_detail%TYPE,
        
        i_county       IN ab_institution.county%TYPE,
        i_other_adress IN ab_institution.address_other_name%TYPE,
        
        i_software    IN software.id_software%TYPE,
        i_id_prof     IN professional.id_professional%TYPE, --45
        i_id_inst     IN institution.id_institution%TYPE,
        i_name        IN professional.name%TYPE,
        i_title       IN professional.title%TYPE,
        i_nick_name   IN professional.nick_name%TYPE,
        i_gender      IN professional.gender%TYPE, -- 50
        i_dt_birth    IN VARCHAR2,
        i_prof_email  IN professional.email%TYPE,
        i_work_phone  IN professional.num_contact%TYPE,
        i_cell_phone  IN professional.cell_phone%TYPE,
        i_prof_fax    IN professional.fax%TYPE, -- 55
        i_first_name  IN professional.first_name%TYPE,
        i_middle_name IN professional.middle_name%TYPE,
        i_last_name   IN professional.last_name%TYPE,
        i_id_cat      IN category.id_category%TYPE,
        
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_id_prof            OUT professional.id_professional%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_inst_and_admin');
        g_error         := 'SET INST AND ADMIN';
        IF NOT pk_backoffice.set_inst_and_admin(i_lang,
                                                i_id_institution,
                                                i_clues,
                                                i_id_inst_att,
                                                i_id_inst_lang,
                                                i_desc,
                                                i_id_parent,
                                                i_flg_type,
                                                i_tax,
                                                i_abbreviation,
                                                i_pref_lang,
                                                i_currency,
                                                i_phone_number,
                                                i_fax,
                                                i_email,
                                                i_health_license,
                                                i_address,
                                                i_location,
                                                i_geo_state,
                                                i_flg_street_type,
                                                i_street_name,
                                                i_outdoor_number,
                                                i_indoor_number,
                                                i_id_settlement_type,
                                                i_id_settlement_name,
                                                i_id_entity,
                                                i_id_municip,
                                                i_id_localidad,
                                                i_id_postal_code,
                                                i_zip_code,
                                                i_country,
                                                i_jurisdiction,
                                                i_location_tax,
                                                i_lic_model,
                                                i_pay_sched,
                                                i_pay_opt,
                                                i_flg_available,
                                                i_id_tz_region,
                                                i_id_market,
                                                i_contact_det,
                                                
                                                i_software,
                                                i_id_prof,
                                                i_id_inst,
                                                i_name,
                                                i_title,
                                                i_nick_name,
                                                i_gender,
                                                i_dt_birth,
                                                i_prof_email,
                                                i_work_phone,
                                                i_cell_phone,
                                                i_prof_fax,
                                                i_first_name,
                                                NULL,
                                                i_middle_name,
                                                i_last_name,
                                                i_id_cat,
                                                
                                                o_id_institution,
                                                o_id_inst_attributes,
                                                o_id_inst_lang,
                                                o_id_prof,
                                                o_error)
        THEN
            g_error := 'ERROR set_inst_and_admin';
            RAISE l_exception;
        END IF;
        g_error := 'update adress_type';
        pk_api_ab_tables.upd_ab_institution(id_ab_institution_in   => o_id_institution,
                                            adress_type_nin        => FALSE,
                                            adress_type_in         => i_adress_type,
                                            county_nin             => FALSE,
                                            address_other_name_nin => FALSE,
                                            county_in              => i_county,
                                            address_other_name_in  => i_other_adress);
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_inst_and_admin;
    /********************************************************************************************
    * Get Professional Names
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_prof_name           Cursor with profissional NAME
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.1.6
    * @since                       2011/12/19
    ********************************************************************************************/
    FUNCTION get_prof_names
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_name       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET PROFESSIONAL NAME CURSOR';
        OPEN o_prof_name FOR
            SELECT p.id_professional, p.first_name, p.middle_name, p.last_name
              FROM professional p
             INNER JOIN prof_institution pi
                ON (pi.id_professional = p.id_professional AND pi.id_institution = i_id_institution AND
                   pi.dt_end_tstz IS NULL AND pi.flg_state = 'A')
             WHERE p.flg_state = 'A'
               AND nvl(p.flg_prof_test, pk_alert_constant.get_no) = pk_alert_constant.get_no
               AND p.id_professional = i_id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE',
                                              'GET_PROF_NAMES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_prof_names;
    /********************************************************************************************
    * Get Institution Software List (with available functionality map)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_context             Screen Context
    * @param o_software            Software List Output Cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.2.1
    * @since                       2012/03/29
    ********************************************************************************************/
    FUNCTION get_institution_software
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_context  IN VARCHAR2,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_generic_val NUMBER(24) := 0;
    BEGIN
        g_function_name := upper('get_institution_software');
    
        g_error := 'OPEN CURSOR FOR AREAS CONFIGURATION ' || i_context;
        IF i_context = 'A'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_labtest = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_labtest = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'I'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imaging = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imaging = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'O'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_exam = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_exam = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'P'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_interv = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_interv = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'M'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_mfr = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_mfr = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'D'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_diagnosis = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_diagnosis = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'MI'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_medication = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_medication = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        
            /*ELSIF i_context = 'ST'
            THEN
                OPEN o_software FOR
                    SELECT s.id_software id,
                           s.name name,
                           pk_translation.get_translation(i_lang, s.code_software) subtitle,
                           REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                      FROM software_institution si
                     INNER JOIN software s
                        ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                     WHERE si.id_institution = i_prof.institution
                       AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                            WHERE sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                           WHERE sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software)) ORDER BY name;*/
        ELSIF i_context = 'IM'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imunization = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imunization = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'H'
        THEN
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si
                 INNER JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_hidrics = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_hidrics = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSE
            OPEN o_software FOR
                SELECT s.id_software id,
                       s.name name,
                       pk_translation.get_translation(i_lang, s.code_software) subtitle,
                       REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
                  FROM software_institution si, software s
                 WHERE s.flg_mni = pk_alert_constant.get_available
                   AND si.id_software = s.id_software
                   AND si.id_institution = i_prof.institution
                   AND s.id_software != 26
                 ORDER BY name;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_institution_software;
    /********************************************************************************************
    * Get Department configured Software List (with available functionality map)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_professional     Professional ID
    * @param i_context             Screen Context
    * @param o_software              Software List Output Cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.2.1
    * @since                       2012/03/29
    ********************************************************************************************/
    FUNCTION get_software_dcs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_context  IN VARCHAR2,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_generic_val NUMBER(24) := 0;
    BEGIN
        g_function_name := upper('get_software_dcs');
    
        g_error := 'OPEN CURSOR FOR AREAS CONFIGURATION';
        IF i_context = 'A'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_labtest = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_labtest = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'I'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imaging = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imaging = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'O'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_exam = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_exam = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'P'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_interv = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_interv = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'M'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_mfr = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_mfr = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'D'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_diagnosis = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_diagnosis = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'MI'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_medication = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_medication = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        
            /*ELSIF i_context = 'ST'
            THEN
                OPEN o_software FOR
                    SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                       AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software)) ORDER BY name;*/
        ELSIF i_context = 'IM'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imunization = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_imunization = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSIF i_context = 'H'
        THEN
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                   AND s.id_software IN (SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_hidrics = pk_alert_constant.get_available
                                            AND sfc.id_institution = i_prof.institution
                                         UNION ALL
                                         SELECT sfc.id_software
                                           FROM software_funct_content sfc
                                          WHERE sfc.flg_hidrics = pk_alert_constant.get_available
                                            AND sfc.id_institution = l_generic_val
                                            AND NOT EXISTS (SELECT 0
                                                   FROM software_funct_content sfc1
                                                  WHERE sfc1.id_institution = i_prof.institution
                                                    AND sfc1.id_software = sfc.id_software))
                 ORDER BY name;
        ELSE
            OPEN o_software FOR
                SELECT DISTINCT s.id_software id, s.name name
                  FROM software_institution si
                  JOIN software s
                    ON (s.id_software = si.id_software AND s.flg_mni = pk_alert_constant.get_available AND
                       s.id_software != 26)
                  JOIN software_dept sd
                    ON (sd.id_software = s.id_software)
                  JOIN dept d
                    ON (d.id_dept = sd.id_dept AND d.flg_available = pk_alert_constant.get_available AND
                       d.id_institution = si.id_institution)
                 WHERE si.id_institution = i_prof.institution
                 ORDER BY name;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_software_dcs;
    /********************************************************************************************
    * Save Service Information
    *
    * @param i_lang                Prefered language ID
    * @param i_id_department       Service ID
    * @param i_id_institution      Institution ID
    * @param i_desc                Service description
    * @param i_abbreviation        Service abbreviation
    * @param i_flg_type            Type of service
    * @param i_id_dept             Department ID
    * @param i_flg_default         Default service in a department
    * @param i_def_priority        Lab Tests priority
    * @param i_collection_by       Collection by
    * @param i_floors_institution  Floors where the service is located
    * @param i_change              Flg signaling changed
    * @param i_commit_stg          Flg showing to save data previous stored in staging area
    * @param i_change_profs        Flg indicating if all professional alert list must be reset
    * @param o_id_department       Service Id
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION set_department
    (
        i_lang               IN language.id_language%TYPE,
        i_id_department      IN department.id_department%TYPE,
        i_id_institution     IN department.id_institution%TYPE,
        i_desc               IN VARCHAR2,
        i_abbreviation       IN department.abbreviation%TYPE,
        i_flg_type           IN department.flg_type%TYPE,
        i_id_dept            IN department.id_dept%TYPE,
        i_flg_default        IN department.flg_default%TYPE,
        i_def_priority       IN department.flg_priority%TYPE,
        i_collection_by      IN department.flg_collection_by%TYPE,
        i_floors_institution IN table_number,
        i_change             IN table_varchar,
        i_id_admission_type  IN admission_type.id_admission_type%TYPE,
        i_admission_time     IN VARCHAR2,
        i_commit_stg         IN VARCHAR,
        i_change_profs       IN VARCHAR,
        i_template_list      IN table_number,
        i_phone_number       IN VARCHAR2,
        i_fax_number         IN VARCHAR2,
        i_prof_resp_add      IN table_number,
        i_prof_resp_rem      IN table_number,
        i_prof_service_add   IN table_number,
        i_prof_service_rem   IN table_number,
        o_id_department      OUT department.id_department%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_serv_exception EXCEPTION;
    BEGIN
        g_error := 'SET SERVICE USING COMMON METHOD';
        IF NOT pk_backoffice.set_department(i_lang,
                                            i_id_department,
                                            i_id_institution,
                                            i_desc,
                                            i_abbreviation,
                                            i_flg_type,
                                            i_id_dept,
                                            i_flg_default,
                                            i_def_priority,
                                            i_collection_by,
                                            i_floors_institution,
                                            i_change,
                                            i_id_admission_type,
                                            i_admission_time,
                                            o_id_department,
                                            o_error)
        THEN
            RAISE l_serv_exception;
        END IF;
        g_error := 'UPDATE DEPARTMENT ' || o_id_department || ' INFO';
        UPDATE department d
           SET d.phone_number = i_phone_number, d.fax_number = i_fax_number
         WHERE d.id_department = o_id_department;
    
        g_error := 'REMOVE PROFESSIONAL RESPONSIBLE ASSOCIATION';
        IF NOT
            pk_backoffice.delete_serv_prof_resp(i_lang, o_id_department, i_prof_resp_rem, i_prof_service_rem, o_error)
        THEN
            RAISE l_serv_exception;
        END IF;
    
        g_error := 'ADD PROFESSIONAL RESPONSIBLE ASSOCIATION';
        IF NOT pk_backoffice.set_serv_prof_resp(i_lang, o_id_department, i_prof_resp_add, i_prof_service_add, o_error)
        THEN
            RAISE l_serv_exception;
        END IF;
    
        IF i_commit_stg = g_flg_available
        THEN
            g_error := 'SET ALERT LIST SERVICE CONFIGURATION';
            IF NOT pk_backoffice_alert.set_serv_alert_conf(i_lang,
                                                           i_id_department,
                                                           i_id_institution,
                                                           i_template_list,
                                                           o_error)
            THEN
                RAISE l_serv_exception;
            END IF;
        END IF;
        IF i_change_profs = 'A'
        THEN
            g_error := 'RESET ALL PROFESSIONALS ALERT LIST MATCHING BY PROFILE';
            IF NOT pk_backoffice_alert.reset_all_prof_alert(i_lang, i_id_department, i_id_institution, i_template_list)
            THEN
                RAISE l_serv_exception;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_serv_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'SET_DEPARTMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'SET_DEPARTMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_department;
    /********************************************************************************************
    * Get software list filtered by profile and category
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_institution            Institution ID
    * @param i_id_professional        Professional ID
    * @param o_list                   Cursor with software information
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/14
    **********************************************************************************************/
    FUNCTION get_software_instit_w_pt
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cat category.id_category%TYPE;
    BEGIN
    
        g_error := 'GET PROFESSIONAL ' || i_id_professional || ' CATEGORY IN INTSTITUTION ' || i_institution;
        SELECT pc.id_category
          INTO l_cat
          FROM prof_cat pc
         WHERE pc.id_professional = i_id_professional
           AND pc.id_institution = i_institution;
    
        g_error := 'RETURN PROFESSIONAL SOFTWARE LIST FOR PROFESSIONAL ' || i_id_professional || ' AND INSTUTION' ||
                   i_institution;
        OPEN o_list FOR
            SELECT si.id_software id,
                   s.name name,
                   pk_translation.get_translation(i_lang, s.code_software) subtitle,
                   REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
              FROM software_institution si
             INNER JOIN software s
                ON (s.id_software = si.id_software)
             WHERE si.id_institution = i_institution
               AND s.flg_mni = g_flg_available
               AND s.id_software != 26
               AND EXISTS (SELECT 0
                      FROM profile_template pt
                     INNER JOIN profile_template_category ptc
                        ON (ptc.id_profile_template = pt.id_profile_template)
                     WHERE pt.id_software = si.id_software
                       AND ptc.id_category = l_cat
                       AND pt.flg_available = g_flg_available)
             ORDER BY name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_software_instit_w_pt;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param o_inst_type             List of values for institution type field
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/05/29
    * @version                       2.5.2
    ********************************************************************************************/
    FUNCTION get_institution_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_inst_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_dom sys_domain.code_domain%TYPE := 'INSTITUTION.FLG_TYPE';
    BEGIN
        g_function_name := upper('get_institution_type_list');
        g_error         := 'GET INSTITUTION TYPE CURSOR';
        OPEN o_inst_type FOR
            SELECT s.val, s.desc_val
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_code_dom, NULL)) s;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_institution_type_list;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param o_geo_stat_list         List of states filtered by country
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/12/14
    * @version                       2.5.1
    ********************************************************************************************/
    FUNCTION get_geo_state_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_country        IN country.id_country%TYPE,
        o_geo_state_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- local attributes vars
        l_market  market.id_market%TYPE;
        l_country country.id_country%TYPE;
    BEGIN
        g_function_name := upper('get_geo_state_list');
    
        g_error := 'RETURN GEO STATE LIST ' || l_market;
    
        IF i_country = g_id_country_br
        THEN
            OPEN o_geo_state_list FOR
                SELECT all_states.s_id,
                       all_states.account_value,
                       all_states.s_desc,
                       all_states.rank,
                       all_states.id_account
                  FROM (SELECT r.id_rb_regional_classifier s_id,
                               r.reg_classifier_abbreviation account_value,
                               pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) s_desc,
                               0 rank,
                               53 id_account
                          FROM alert_adtcod_cfg.rb_regional_classifier r
                         WHERE r.id_rb_reg_class_desc_ctry = 76000
                           AND r.flg_available = 'Y'
                           AND pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) IS NOT NULL) all_states
                 ORDER BY all_states.rank, all_states.s_desc;
        ELSE
            OPEN o_geo_state_list FOR
                SELECT all_states.s_id,
                       all_states.account_value,
                       all_states.s_desc,
                       all_states.rank,
                       all_states.id_account
                  FROM (SELECT -1 s_id, NULL account_value, s.desc_message s_desc, 10 rank, NULL id_account
                          FROM sys_message s
                         WHERE s.id_language = i_lang
                           AND s.flg_available = pk_alert_constant.get_available
                           AND s.code_message = g_others_message) all_states
                 ORDER BY all_states.rank, all_states.s_desc;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_geo_state_list;
    /********************************************************************************************
    * Returns Boolean
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    * @param i_id_country            Country identifier (mandatory)
    * @param i_geo_state             Geo State identifier
    * @param o_geo_stat_list         List of states filtered by country
    * @param o_error                 Error Id
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/02/04
    * @version                       2.5.2
    ********************************************************************************************/

    FUNCTION get_city_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_country   IN country.id_country%TYPE,
        i_geo_state IN geo_state.id_geo_state%TYPE,
        o_city_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- local attributes vars
        l_geo_state geo_state.id_geo_state%TYPE;
    BEGIN
        g_function_name := upper('get_city_list');
        SELECT decode(i_geo_state, -1, NULL, i_geo_state)
          INTO l_geo_state
          FROM dual;
    
        IF (i_country = g_id_country_br AND l_geo_state IS NOT NULL)
        THEN
            OPEN o_city_list FOR
                SELECT all_cities.c_id,
                       all_cities.account_value,
                       all_cities.c_desc,
                       all_cities.rank,
                       all_cities.id_account
                  FROM (SELECT r.id_rb_regional_classifier c_id,
                               r.reg_classifier_code account_value,
                               pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) c_desc,
                               0 rank,
                               54 id_account
                          FROM alert_adtcod_cfg.rb_regional_classifier r
                         WHERE r.id_rb_reg_class_desc_ctry = 76005
                           AND r.flg_available = 'Y'
                           AND r.id_rb_regional_class_parent = l_geo_state
                           AND pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) IS NOT NULL) all_cities
                 ORDER BY all_cities.rank, all_cities.c_desc;
        
        ELSE
            OPEN o_city_list FOR
                SELECT -1 c_id, NULL account_value, s.desc_message c_desc, 10 rank, NULL id_account
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.flg_available = pk_alert_constant.get_available
                   AND s.code_message = g_others_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_city_list;
    /********************************************************************************************
    * Get Professional Bond domain BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional array ID
    * @param o_res_list         cursor with ordered results
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/14
    ********************************************************************************************/
    FUNCTION get_bond_value
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_level    IN NUMBER DEFAULT 1,
        i_bond_id  IN NUMBER DEFAULT NULL,
        o_res_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_function_name := upper('get_bond_value');
        g_error         := 'GET BOND VALUES';
        IF NOT pk_backoffice.get_bond_values(i_lang, i_prof, i_level, i_bond_id, o_res_list, l_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bond_value;
    /********************************************************************************************
    * Set Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION set_professional_br
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nick_name      IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN VARCHAR2,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_id_scholarship IN professional.id_scholarship%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_upin           IN professional.upin%TYPE,
        i_dea            IN professional.dea%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        i_num_mecan      IN prof_institution.num_mecan%TYPE,
        i_id_lang        IN prof_preferences.id_language%TYPE,
        i_flg_state      IN prof_institution.flg_state%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_commit_at_end  IN BOOLEAN,
        i_adress_type    IN professional.adress_type%TYPE,
        -- professional BR fields
        i_id_cpf             IN professional.id_cpf%TYPE,
        i_id_cns             IN professional.id_cns%TYPE,
        i_mother_name        IN professional.mother_name%TYPE,
        i_father_name        IN professional.father_name%TYPE,
        i_id_gstate_birth    IN professional.id_geo_state_birth%TYPE,
        i_id_city_birth      IN professional.id_district_birth%TYPE,
        i_code_race          IN professional.code_race%TYPE,
        i_code_school        IN professional.code_scoolarship%TYPE,
        i_flg_in_school      IN professional.flg_in_school%TYPE,
        i_code_logr          IN professional.code_logr_type%TYPE,
        i_door_num           IN professional.door_number%TYPE,
        i_address_ext        IN professional.address_extension%TYPE,
        i_id_gstate_adress   IN professional.id_geo_state_adress%TYPE,
        i_id_city_adress     IN professional.id_district_adress%TYPE,
        i_adress_area        IN professional.adress_area%TYPE,
        i_code_banq          IN professional.code_banq%TYPE,
        i_desc_agency        IN professional.desc_banq_ag%TYPE,
        i_banq_account       IN professional.id_banq_account%TYPE,
        i_code_certif        IN professional.code_certificate%TYPE,
        i_balcon_certif      IN professional.desc_balcony%TYPE,
        i_book_certif        IN professional.desc_book%TYPE,
        i_page_certif        IN professional.desc_page%TYPE,
        i_term_certif        IN professional.desc_term%TYPE,
        i_date_certif        IN VARCHAR2,
        i_id_document        IN professional.id_document%TYPE,
        i_balcon_doc         IN professional.code_emitant_cert%TYPE,
        i_id_gstate_doc      IN professional.id_geo_state_doc%TYPE,
        i_date_doc           IN VARCHAR2,
        i_code_crm           IN professional.code_emitant_crm%TYPE,
        i_id_gstate_crm      IN professional.id_geo_state_crm%TYPE,
        i_code_family_status IN professional.code_family_status%TYPE,
        i_code_doc_type      IN professional.code_doc_type%TYPE,
        i_prof_ocp           IN professional.id_prof_formation%TYPE,
        -- prof_institution fields
        i_bond     IN prof_institution.id_professional_bond%TYPE,
        i_work_amb IN prof_institution.work_schedule_amb%TYPE,
        i_work_inp IN prof_institution.work_schedule_inp%TYPE,
        o_work_oth IN prof_institution.work_schedule_other%TYPE,
        i_flg_sus  IN prof_institution.flg_sus_app%TYPE,
        -- end prof_institution fields
        i_other_doc_desc IN professional.other_doc_desc%TYPE,
        i_healht_plan    IN professional.id_health_plan%TYPE,
        --end br fields
        i_bleep_num    IN professional.bleep_number%TYPE,
        i_suffix       IN professional.suffix%TYPE,
        i_contact_det  IN prof_institution.contact_detail%TYPE,
        i_county       IN professional.county%TYPE,
        i_other_adress IN professional.address_other_name%TYPE,
        o_id_prof      OUT professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_inst_pk prof_institution.id_prof_institution%TYPE := 0;
        l_error        t_error_out;
        l_dup_data_found  EXCEPTION;
        l_prof_not_set    EXCEPTION;
        l_prof_br_not_set EXCEPTION;
    
    BEGIN
    
        g_error := 'SET PROFESSIONAL MAIN FIELDS';
        IF NOT set_professional(i_lang,
                                i_id_institution,
                                i_id_prof,
                                i_title,
                                i_first_name,
                                i_middle_name,
                                i_last_name,
                                i_nick_name,
                                i_initials,
                                i_dt_birth,
                                i_gender,
                                i_marital_status,
                                i_id_category,
                                i_id_speciality,
                                i_num_order,
                                i_upin,
                                i_dea,
                                i_id_cat_surgery,
                                i_num_mecan,
                                i_id_lang,
                                i_flg_state,
                                i_address,
                                i_city,
                                i_district,
                                i_zip_code,
                                i_id_country,
                                i_work_phone,
                                i_num_contact,
                                i_cell_phone,
                                i_fax,
                                i_email,
                                i_adress_type,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                i_bleep_num,
                                i_suffix,
                                i_contact_det,
                                i_county,
                                i_other_adress,
                                FALSE,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                o_id_prof,
                                l_error)
        THEN
            RAISE l_prof_not_set;
        ELSE
            -- VALIDATIONS CRM (Nº CONSELHO+CRM CODE+UF CRM)
            -- VALIDATION ON CPF
            -- VALIDATION ON RG (identity number)
            IF NOT pk_backoffice.check_prof_br_uk_data(i_lang,
                                                       o_id_prof,
                                                       i_id_cpf,
                                                       i_id_document,
                                                       i_balcon_doc,
                                                       i_id_gstate_doc,
                                                       i_code_crm,
                                                       i_id_gstate_crm,
                                                       i_num_order,
                                                       l_error)
            THEN
                RAISE l_dup_data_found;
            END IF;
        
            g_error := 'SET PROFESSIONAL BRASILIAN FIELDS FOR ' || o_id_prof;
            IF NOT pk_backoffice.set_professional_br(i_lang,
                                                     o_id_prof,
                                                     i_id_cpf,
                                                     i_id_cns,
                                                     i_mother_name,
                                                     i_father_name,
                                                     i_id_gstate_birth,
                                                     i_id_city_birth,
                                                     i_code_race,
                                                     i_code_school,
                                                     i_flg_in_school,
                                                     i_code_logr,
                                                     i_door_num,
                                                     i_address_ext,
                                                     i_id_gstate_adress,
                                                     i_id_city_adress,
                                                     i_adress_area,
                                                     i_code_banq,
                                                     i_desc_agency,
                                                     i_banq_account,
                                                     i_code_certif,
                                                     i_balcon_certif,
                                                     i_book_certif,
                                                     i_page_certif,
                                                     i_term_certif,
                                                     i_date_certif,
                                                     i_id_document,
                                                     i_balcon_doc,
                                                     i_id_gstate_doc,
                                                     i_date_doc,
                                                     i_code_crm,
                                                     i_id_gstate_crm,
                                                     i_code_family_status,
                                                     i_code_doc_type,
                                                     i_prof_ocp,
                                                     i_other_doc_desc,
                                                     i_healht_plan,
                                                     l_error)
            THEN
                RAISE l_prof_br_not_set;
            END IF;
        
            SELECT nvl((SELECT pi.id_prof_institution
                         FROM prof_institution pi
                        WHERE pi.id_professional = o_id_prof
                          AND pi.id_institution = i_id_institution
                          AND pi.flg_state = i_flg_state
                          AND pi.dt_end_tstz IS NULL),
                       NULL)
              INTO l_prof_inst_pk
              FROM dual;
        
            --update bond and work fields
            pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_prof_inst_pk,
                                                           i_id_professional     => o_id_prof,
                                                           i_id_institution      => i_id_institution,
                                                           i_flg_state           => i_flg_state,
                                                           i_code_bond           => nvl(i_bond, NULL),
                                                           i_work_schedule_amb   => nvl(i_work_amb, NULL),
                                                           i_work_schedule_inp   => nvl(i_work_inp, NULL),
                                                           i_work_schedule_other => nvl(o_work_oth, NULL),
                                                           i_flg_sus_app         => nvl(i_flg_sus, NULL),
                                                           o_id_prof_institution => l_prof_inst_pk);
        
        END IF;
    
        IF i_commit_at_end
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_dup_data_found THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN l_prof_not_set THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN l_prof_br_not_set THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        
    END set_professional_br;
    /********************************************************************************************
    * Get Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION get_professional_br
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_br         OUT pk_types.cursor_type,
        o_prof_inst_br    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PROFESSIONAL ' || i_id_professional || ' (BR FIELDS) DATA FOR INSTITUTION ' || i_id_institution;
        IF NOT pk_backoffice.get_professional_br(i_lang,
                                                 i_id_professional,
                                                 i_id_institution,
                                                 o_prof_br,
                                                 o_prof_inst_br,
                                                 o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_professional_br;
    -- get list of occupations to professional formation
    FUNCTION get_occupation_list
    (
        i_lang  IN language.id_language%TYPE,
        o_occup OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET OCCUPATION LIST';
        IF NOT pk_social.get_occup_list(i_lang, 'N', o_occup, o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_occupation_list;
    /********************************************************************************************
    * Get a list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_serv_physician_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        o_prof_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_serv_physician_list(i_lang, i_id_institution, i_id_department, o_prof_list, o_error);
    END get_serv_physician_list;
    /********************************************************************************************
    * Get list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_service_responsible_map
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        i_id_professional IN department.id_department%TYPE,
        o_result_list     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_service_responsible_map(i_lang, i_id_dept, i_id_professional, o_result_list, o_error);
    END get_service_responsible_map;
    /********************************************************************************************
    * Set list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION set_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_serv_prof_resp(i_lang, i_id_department, i_prof_id, o_error);
    END set_serv_prof_resp;
    /********************************************************************************************
    * Delete responsible professional in a service context
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION delete_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.delete_serv_prof_resp(i_lang, i_id_department, i_prof_id, o_error);
    END delete_serv_prof_resp;

    /********************************************************************************************
    * Get detailed CDA request detory
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param o_results
    * @param o_results_prof
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_id_cda_req   IN cda_req.id_cda_req%TYPE,
        o_results      OUT pk_types.cursor_type,
        o_results_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_backoffice_cda.get_cda_req_det(i_lang, i_id_cda_req, o_results, o_results_prof, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ_det',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
    END get_cda_req_det;
    /********************************************************************************************
    * Get detailed CDA request table
    *
    * @param i_lang
    * @param i_id_institution
    * @param o_results
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_results        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_cda.get_cda_req(i_lang, i_id_institution, o_results, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CDA_REQ',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_results);
            RETURN FALSE;
    END get_cda_req;
    /********************************************************************************************
    * Set a Complete CDA request
    *
    * @param i_lang
    * @param i_prof
    * @param i_id_institution
    * @param i_flg_type
    * @param i_dt_start
    * @param i_dt_end
    * @param i_qrda_type
    * @param i_qrda_stype
    * @param i_sw_list
    * @param o_cda_req
    * @param o_cda_req_det
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_qrda_type      IN cda_req_det.id_report%TYPE,
        i_qrda_stype     IN cda_req_det.qrda_type%TYPE,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_backoffice_cda.set_cda_req(i_lang,
                                             i_prof,
                                             i_id_institution,
                                             i_flg_type,
                                             i_dt_start,
                                             i_dt_end,
                                             i_qrda_type,
                                             i_qrda_stype,
                                             i_sw_list,
                                             o_cda_req,
                                             o_cda_req_det,
                                             o_error)
        THEN
            ROLLBACK;
            RAISE l_exception;
        ELSE
            COMMIT;
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CDA_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_cda_req;
    /********************************************************************************************
    * Get Measures list
    *
    * @param i_lang
    * @param i_prof
    * @param o_tab_emeasure
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_qrda_measures
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_tab_emeasure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_backoffice_cda.get_qrda_measures(i_lang, i_prof, o_tab_emeasure, o_error);
    
    END get_qrda_measures;
    /********************************************************************************************
    * Get software CDA request list
    *
    * @param i_lang
    * @param i_flg_cda_req_type
    * @param i_flg_type_qrda
    * @param o_result_sw
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_software_list
    (
        i_lang             IN language.id_language%TYPE,
        i_flg_cda_req_type IN cda_req.flg_type%TYPE,
        i_flg_type_qrda    IN cda_req_det.qrda_type%TYPE,
        o_result_sw        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_cda.get_cda_software_list(i_lang,
                                                       i_flg_cda_req_type,
                                                       i_flg_type_qrda,
                                                       o_result_sw,
                                                       o_error);
    END get_cda_software_list;
    /********************************************************************************************
    * Get CDA Report ID
    *
    * @param o_id_report
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_report_id
    (
        i_id_software IN software.id_software%TYPE,
        o_id_report   OUT report_software.id_report%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_cda.get_cda_report_id(i_id_software, o_id_report);
    END get_cda_report_id;
    /********************************************************************************************
    * Retrieve file to servlet in order to be sent to ux for download
    *
    * @param i_cda_req
    * @param o_file
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_file
    (
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_file    OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice_cda.get_cda_req_file(i_cda_req, o_file, o_error);
    END get_cda_req_file;
    /********************************************************************************************
    * Set report next logical status
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param i_id_institution
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_next_status
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET_CDA_NEXT_STATUS FOR REQUEST: ' || i_id_cda_req;
        pk_backoffice_cda.set_cda_next_status(i_lang, i_id_cda_req, i_id_institution);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CDA_NEXT_STATUS',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_cda_next_status;
    /********************************************************************************************
    * Cancel CDA requests
    *
    * @param i_lang
    * @param i_id_cda_req
    * @param o_error
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION cancel_cda_req
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_status cda_req.flg_status%TYPE;
    BEGIN
        g_error := 'CANCEL REQUEST ' || i_id_cda_req;
        IF pk_backoffice_cda.cancel_cda_req(i_lang, i_id_cda_req, o_error)
        THEN
            COMMIT;
            RETURN TRUE;
        ELSE
            ROLLBACK;
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_CDA_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_cda_req;
    FUNCTION get_scholarship_mkt
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_scholarship_mkt(i_lang, i_id_institution, o_list, o_error);
    END get_scholarship_mkt;

    FUNCTION get_scholarship_group
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_scholarship_group IN professional.id_agrupacion%TYPE,
        o_list                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_backoffice.get_scholarship_group(i_lang                 => i_lang,
                                                   i_id_institution       => i_id_institution,
                                                   i_id_scholarship_group => i_id_scholarship_group,
                                                   o_list                 => o_list,
                                                   o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'GET_SCHOLARSHIP_GROUP',
                                              o_error);
            RETURN FALSE;
        
    END get_scholarship_group;

    /********************************************************************************************
    * Get CDA requests Detail or History
    *
    * @param i_lang                 Application current language
    * @param i_prof                 Professional Information array
    * @param i_id_cda_req           CDA request identified
    * @param i_screen_flg           Flg showing the screen request (H or D)
    * @param o_results              Cursor with returned information
    * @param o_error                Error information type
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/07/15
    * @version                       2.6.4.1
    ********************************************************************************************/
    FUNCTION get_cda_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_screen_flg IN VARCHAR2,
        o_results    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_backoffice_cda.get_cda_det(i_lang, i_prof, i_id_cda_req, i_screen_flg, o_results, o_error);
    END get_cda_det;
    /********************************************************************************************
    * Get Inbox number of unread messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_inbox                                   P (patient) or F (facility professionals)
    * @param i_id_receiver                                Patient or professional context id
    *
    * @return                  Number of unread messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_inbox_count
    (
        i_lang        IN language.id_language%TYPE,
        i_id_receiver IN pending_issue.id_professional%TYPE,
        o_count       OUT NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        o_count := pk_backoffice_pending_issues.get_inbox_count(i_lang, 'F', i_id_receiver);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_inbox_count;
    /********************************************************************************************
    * Get message thread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_thread                                 Thread message identifier
    * @param i_thread_level                               maximum thread level (message being seen)
    *
    * @return                 table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_message_thread
    (
        i_lang         IN language.id_language%TYPE,
        i_id_thread    IN pending_issue_message.id_pending_issue%TYPE,
        i_thread_level IN pending_issue_message.thread_level%TYPE,
        o_messages     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_messages FOR
            SELECT msg.id_sender id_sender,
                   decode(msg.flg_sender, 'P', concat(msg.name_sender, msg.repr_str), msg.name_sender) name_sender,
                   msg.id_receiver id_to,
                   msg.name_receiver name_to,
                   msg.msg_subject msg_title,
                   msg.msg_body msg_body,
                   pk_backoffice.get_date_to_be_sent(i_lang, msg.msg_date) dt_msg,
                   msg.thread_status thread_status,
                   msg.msg_status_sender msg_status_sender,
                   msg.msg_status_receiver msg_status_receiver,
                   msg.thread_level thread_level,
                   msg.flg_sender flg_sender,
                   msg.thread_id thread_id,
                   msg.msg_id msg_id
              FROM TABLE(pk_backoffice_pending_issues.get_message_thread(i_lang, i_id_thread, i_thread_level)) msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'GET_MESSAGE_THREAD',
                                              o_error);
            RETURN FALSE;
    END get_message_thread;
    /********************************************************************************************
    * Set New Messages messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_from                                     DEfinition for message sender (F - facility professional or P - patient)
    * @param i_rep_str                                     Legal representative text
    * @param i_id_prof                                     profissional type
    * @param i_id_patient                                  Patient ID
    * @param i_msg_subject                                 Mesage title or subject
    * @param i_msg_body                                    MEssage body or text max 1000 char
    * @param i_id_msg_rep                                  If reply need message parent id
    * @param i_id_thread                                   If reply need message thread id
    * @param o_new_msg_id                                  New message identification
    * @param o_error                                     Error type identifier
    *
    *
    * @return                  Boolean (true or false)
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/17
    ********************************************************************************************/
    FUNCTION set_message
    (
        i_lang        IN language.id_language%TYPE,
        i_id_prof     IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_msg_subject IN VARCHAR2,
        i_msg_body    IN CLOB,
        i_id_msg_rep  IN pending_issue_message.id_pending_issue_message%TYPE,
        i_id_thread   IN OUT pending_issue_message.id_pending_issue%TYPE,
        i_commit      IN VARCHAR2,
        o_new_msg_id  OUT pending_issue_message.id_pending_issue_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_backoffice_pending_issues.set_message(i_lang,
                                                        'F',
                                                        NULL,
                                                        i_id_prof,
                                                        i_id_patient,
                                                        i_msg_subject,
                                                        i_msg_body,
                                                        i_id_msg_rep,
                                                        i_id_thread,
                                                        i_commit,
                                                        o_new_msg_id,
                                                        o_error);
    END set_message;
    /********************************************************************************************
    * Set message as cancelled
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_sender   pending_issue_sender.flg_sender%TYPE := NULL;
        l_msg_location VARCHAR2(1 CHAR) := NULL;
    BEGIN
        FOR i IN 1 .. i_id_message.count
        LOOP
            IF NOT pk_backoffice_pending_issues.get_message_sender(i_id_message(i), l_msg_sender)
            THEN
                RETURN FALSE;
            ELSE
                SELECT decode(l_msg_sender, 'F', 'O', 'I')
                  INTO l_msg_location
                  FROM dual;
                IF NOT pk_backoffice_pending_issues.set_status_cancel(i_lang, i_id_message(i), l_msg_location, o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
        COMMIT;
        RETURN TRUE;
    END set_status_cancel;
    /********************************************************************************************
    * Set message as Read
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_read
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_sender   pending_issue_sender.flg_sender%TYPE := NULL;
        l_msg_location VARCHAR2(1 CHAR) := NULL;
    BEGIN
        FOR i IN 1 .. i_id_message.count
        LOOP
            IF NOT pk_backoffice_pending_issues.get_message_sender(i_id_message(i), l_msg_sender)
            THEN
                RETURN FALSE;
            ELSE
                SELECT decode(l_msg_sender, 'F', 'O', 'I')
                  INTO l_msg_location
                  FROM dual;
                IF NOT pk_backoffice_pending_issues.set_status_read(i_lang, i_id_message(i), l_msg_location, o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
        COMMIT;
        RETURN TRUE;
    END set_status_read;
    /* Method to return message domains*/
    FUNCTION get_message_domain
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_res_cur OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_res_cur FOR
            SELECT desc_val, val, img_name, rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                  i_prof,
                                                                  'PENDING_ISSUE_SENDER.FLG_STATUS_SENDER',
                                                                  NULL)) dmn_send
            UNION
            SELECT desc_val, val, img_name, rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                  i_prof,
                                                                  'PENDING_ISSUE_SENDER.FLG_STATUS_RECEIVER',
                                                                  NULL)) dmn_receive;
        RETURN TRUE;
    END get_message_domain;
    /********************************************************************************************
    * Set message in previous status
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.2
    * @since                   2014/10/27
    ********************************************************************************************/
    FUNCTION set_msg_prev_status
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_sender   pending_issue_sender.flg_sender%TYPE := NULL;
        l_msg_location VARCHAR2(1 CHAR) := NULL;
    BEGIN
        FOR i IN 1 .. i_id_message.count
        LOOP
            IF NOT pk_backoffice_pending_issues.get_message_sender(i_id_message(i), l_msg_sender)
            THEN
                RETURN FALSE;
            ELSE
                SELECT decode(l_msg_sender, 'F', 'O', 'I')
                  INTO l_msg_location
                  FROM dual;
                IF NOT
                    pk_backoffice_pending_issues.set_msg_prev_status(i_lang, i_id_message(i), l_msg_location, o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PAPI_UI',
                                              'SET_MSG_PREV_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_msg_prev_status;

    FUNCTION set_professional
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_prof           IN professional.id_professional%TYPE,
        i_title             IN professional.title%TYPE,
        i_first_name        IN professional.first_name%TYPE,
        i_middle_name       IN professional.middle_name%TYPE,
        i_last_name         IN professional.last_name%TYPE,
        i_nick_name         IN professional.nick_name%TYPE,
        i_initials          IN professional.initials%TYPE,
        i_dt_birth          IN VARCHAR2,
        i_gender            IN professional.gender%TYPE,
        i_marital_status    IN professional.marital_status%TYPE,
        i_id_category       IN category.id_category%TYPE,
        i_id_speciality     IN professional.id_speciality%TYPE,
        i_id_scholarship    IN professional.id_scholarship%TYPE,
        i_num_order         IN professional.num_order%TYPE,
        i_upin              IN professional.upin%TYPE,
        i_dea               IN professional.dea%TYPE,
        i_id_cat_surgery    IN category.id_category%TYPE,
        i_num_mecan         IN prof_institution.num_mecan%TYPE,
        i_id_lang           IN prof_preferences.id_language%TYPE,
        i_flg_state         IN prof_institution.flg_state%TYPE,
        i_address           IN professional.address%TYPE,
        i_city              IN professional.city%TYPE,
        i_district          IN professional.district%TYPE,
        i_zip_code          IN professional.zip_code%TYPE,
        i_id_country        IN professional.id_country%TYPE,
        i_work_phone        IN professional.work_phone%TYPE,
        i_num_contact       IN professional.num_contact%TYPE,
        i_cell_phone        IN professional.cell_phone%TYPE,
        i_fax               IN professional.fax%TYPE,
        i_email             IN professional.email%TYPE,
        i_commit_at_end     IN BOOLEAN,
        i_id_road           IN professional.id_road%TYPE,
        i_entity            IN professional.id_entity%TYPE,
        i_jurisdiction      IN professional.id_jurisdiction%TYPE,
        i_municip           IN professional.id_municip%TYPE,
        i_localidad         IN professional.id_localidad%TYPE,
        i_id_postal_code_rb IN professional.id_postal_code_rb%TYPE,
        o_id_prof           OUT professional.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_backoffice.set_professional(i_lang                    => i_lang,
                                              i_id_institution          => i_id_institution,
                                              i_id_prof                 => i_id_prof,
                                              i_title                   => i_title,
                                              i_first_name              => i_first_name,
                                              i_middle_name             => i_middle_name,
                                              i_last_name               => i_last_name,
                                              i_nick_name               => i_nick_name,
                                              i_initials                => i_initials,
                                              i_dt_birth                => i_dt_birth,
                                              i_gender                  => i_gender,
                                              i_marital_status          => i_marital_status,
                                              i_id_category             => i_id_category,
                                              i_id_speciality           => i_id_speciality,
                                              i_id_scholarship          => i_id_scholarship,
                                              i_num_order               => i_num_order,
                                              i_upin                    => i_upin,
                                              i_dea                     => i_dea,
                                              i_id_cat_surgery          => i_id_cat_surgery,
                                              i_num_mecan               => i_num_mecan,
                                              i_id_lang                 => i_id_lang,
                                              i_flg_state               => i_flg_state,
                                              i_address                 => i_address,
                                              i_city                    => i_city,
                                              i_district                => i_district,
                                              i_zip_code                => i_zip_code,
                                              i_id_country              => i_id_country,
                                              i_work_phone              => i_work_phone,
                                              i_num_contact             => i_num_contact,
                                              i_cell_phone              => i_cell_phone,
                                              i_fax                     => i_fax,
                                              i_email                   => i_email,
                                              i_commit_at_end           => i_commit_at_end,
                                              i_id_road                 => i_id_road,
                                              i_entity                  => i_entity,
                                              i_jurisdiction            => i_jurisdiction,
                                              i_municip                 => i_municip,
                                              i_localidad               => i_localidad,
                                              i_id_postal_code_rb       => i_id_postal_code_rb,
                                              i_parent_name             => NULL,
                                              i_first_name_sa           => NULL,
                                              i_parent_name_sa          => NULL,
                                              i_middle_name_sa          => NULL,
                                              i_last_name_sa            => NULL,
                                              i_agrupacion              => NULL,
                                              i_doc_ident_type          => NULL,
                                              i_doc_ident_num           => NULL,
                                              i_doc_ident_val           => NULL,
                                              i_tin                     => NULL,
                                              i_clinical_name           => NULL,
                                              i_prof_spec_id            => NULL,
                                              i_prof_spec_ballot        => NULL,
                                              i_prof_spec_id_university => NULL,
                                              i_agrupacion_instit_id    => NULL,
                                              o_id_prof                 => o_id_prof,
                                              o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'SET_PROFESSIONAL',
                                              o_error);
            RETURN FALSE;
    END set_professional;

    FUNCTION get_name_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_name       IN name_translation.ocidental_name%TYPE,
        i_type       IN NUMBER,
        o_name_trans OUT name_translation.ocidental_name%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_backoffice.get_name_translation(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_name       => i_name,
                                                  i_type       => i_type,
                                                  o_name_trans => o_name_trans,
                                                  o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'GET_NAME_TRANSLATION',
                                              o_error);
            RETURN FALSE;
    END get_name_translation;

    FUNCTION get_agrupacion
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_backoffice.get_agrupacion(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_institution => i_id_institution,
                                            o_list           => o_list,
                                            o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'GET_AGRUPACION',
                                              o_error);
            RETURN FALSE;
    END get_agrupacion;

    FUNCTION get_prof_doc_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_backoffice.get_prof_doc_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_API_UI',
                                              'GET_PROF_DOC_LIST',
                                              o_error);
            RETURN FALSE;
    END get_prof_doc_list;

BEGIN
    -- Initializes log context
    -- Package info
    g_package_owner := 'ALERT';
    g_package_name  := 'PK_BACKOFFICE_API_UI';

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_flg_available := pk_alert_constant.get_available;

END pk_backoffice_api_ui;
/
