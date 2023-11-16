/*-- Last Change Revision: $Rev: 2026773 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_disposition IS

    /********************************************************************************************
    * Get an list of external professionals for the institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_category                 Category ID
    * @param i_id_institution              Institution ID
    * @param o_professional_ext            External professional info list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_professional
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_category      IN category.id_category%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        o_professional_ext OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXTERNAL PROFESSIONAL CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_professional_ext FOR
            SELECT pe.id_professional_ext id,
                   pe.name name,
                   pk_translation.get_translation(i_lang, s.code_speciality) specialty,
                   address,
                   zip_code,
                   work_phone,
                   pk_alert_constant.g_inactive flg_select
              FROM professional_ext pe
              JOIN speciality s
                ON pe.id_speciality = s.id_speciality
             WHERE pe.id_institution = i_id_institution
               AND pe.id_category = g_physician_cat
               AND pe.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_professional_ext);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_EXT_PROFESSIONAL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_ext_professional;

    /********************************************************************************************
    * Get an external professional's detail
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_professional_ext         External professional ID
    * @param o_professional_ext            External professional info
    * @param o_prof_ext_accounts           Accounts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_prof_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        o_professional_ext    OUT pk_types.cursor_type,
        o_prof_ext_accounts   OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_accounts BOOLEAN;
    
    BEGIN
        g_error := 'GET EXTERNAL PROFESSIONAL DATA AND HISTORY';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_professional_ext FOR
            SELECT peh.id_professional_ext,
                   peh.name,
                   pk_backoffice.get_prof_title_desc(i_lang, peh.title) desc_title,
                   pk_sysdomain.get_domain('PROFESSIONAL_EXT.TITLE', peh.title, i_lang) desc_title,
                   peh.first_name,
                   peh.middle_name,
                   peh.last_name,
                   peh.initials,
                   pk_backoffice.get_date_to_be_sent(i_lang, peh.dt_birth) date_birth,
                   pk_date_utils.date_chr_extend(i_lang, peh.dt_birth, profissional(0, 0, 0)) string_birth,
                   pk_sysdomain.get_domain('PROFESSIONAL.GENDER', peh.gender, i_lang) desc_gender,
                   peh.gender,
                   pk_sysdomain.get_domain('PROFESSIONAL.MARITAL_STATUS', peh.marital_status, i_lang) desc_marital_status,
                   peh.marital_status,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cat.code_category
                                                     FROM category cat
                                                    WHERE cat.id_category = g_physician_cat
                                                      AND cat.flg_available = pk_alert_constant.g_yes)) flg_clinical,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT s.code_speciality
                                                     FROM speciality s
                                                    WHERE s.id_speciality = peh.id_speciality
                                                      AND s.flg_available = pk_alert_constant.g_yes)) spec,
                   peh.id_speciality,
                   (SELECT pe.id_category_sub
                      FROM professional_ext pe
                     WHERE pe.id_professional_ext = i_id_professional_ext) id_category_in_surgery,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cs.code_category_sub
                                                     FROM category_sub cs
                                                     JOIN professional_ext pe
                                                       ON cs.id_category_sub = pe.id_category_sub
                                                    WHERE pe.id_professional_ext = i_id_professional_ext
                                                      AND cs.flg_available = pk_alert_constant.g_yes)) category_in_surgery,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   peh.id_language id_lang,
                   peh.address,
                   peh.city,
                   peh.district,
                   peh.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = peh.id_country)) country,
                   peh.id_country,
                   peh.work_phone,
                   peh.num_contact,
                   peh.cell_phone,
                   peh.fax,
                   peh.website,
                   peh.email,
                   peh.office_name,
                   pk_alert_constant.g_active flg_status,
                   pk_date_utils.date_hour_chr_extend(i_lang, peh.begin_date, profissional(0, i_id_institution, 26)) bg_date,
                   peh.id_professional,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = peh.id_professional) prof,
                   peh.begin_date
              FROM professional_ext_hist peh
             WHERE peh.id_professional_ext = i_id_professional_ext
               AND peh.end_date IS NULL
            UNION
            SELECT peh.id_professional_ext,
                   peh.name,
                   peh.title,
                   pk_backoffice.get_prof_title_desc(i_lang, peh.title) desc_title,
                   peh.first_name,
                   peh.middle_name,
                   peh.last_name,
                   peh.initials,
                   pk_backoffice.get_date_to_be_sent(i_lang, peh.dt_birth) date_birth,
                   pk_date_utils.date_chr_extend(i_lang, peh.dt_birth, profissional(0, 0, 0)) string_birth,
                   pk_sysdomain.get_domain('PROFESSIONAL.GENDER', peh.gender, i_lang) desc_gender,
                   peh.gender,
                   pk_sysdomain.get_domain('PROFESSIONAL.MARITAL_STATUS', peh.marital_status, i_lang) desc_marital_status,
                   peh.marital_status,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cat.code_category
                                                     FROM category cat
                                                    WHERE cat.id_category = g_physician_cat
                                                      AND cat.flg_available = pk_alert_constant.g_yes)) flg_clinical,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT s.code_speciality
                                                     FROM speciality s
                                                    WHERE s.id_speciality = peh.id_speciality
                                                      AND s.flg_available = pk_alert_constant.g_yes)) spec,
                   peh.id_speciality,
                   (SELECT pcat.id_category_sub
                      FROM prof_cat pcat
                     WHERE pcat.id_professional = i_id_professional_ext
                       AND pcat.id_institution = i_id_institution) id_category_in_surgery,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cs.code_category_sub
                                                     FROM category_sub cs, prof_cat pcat
                                                    WHERE cs.id_category_sub = pcat.id_category_sub
                                                      AND pcat.id_professional = i_id_professional_ext
                                                      AND pcat.id_institution = i_id_institution
                                                      AND cs.flg_available = pk_alert_constant.g_yes)) category_in_surgery,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   peh.id_language id_lang,
                   peh.address,
                   peh.city,
                   peh.district,
                   peh.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = peh.id_country)) country,
                   peh.id_country,
                   peh.work_phone,
                   peh.num_contact,
                   peh.cell_phone,
                   peh.fax,
                   peh.website,
                   peh.email,
                   peh.office_name,
                   pk_alert_constant.g_inactive flg_status,
                   pk_date_utils.date_hour_chr_extend(i_lang, peh.begin_date, profissional(0, i_id_institution, 26)) bg_date,
                   peh.id_professional,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = peh.id_professional) prof,
                   peh.begin_date
              FROM professional_ext_hist peh
             WHERE peh.id_professional_ext = i_id_professional_ext
               AND peh.end_date IS NOT NULL
             ORDER BY flg_status ASC, begin_date DESC;
    
        g_error := 'GET EXTERNAL PROFESSIONAL ACCOUNTS';
        pk_alertlog.log_debug(g_error);
    
        l_accounts := pk_backoffice_disposition.get_prof_ext_cat_affiliations(i_lang                  => i_lang,
                                                                              i_id_professional_ext   => i_id_professional_ext,
                                                                              i_id_category           => g_physician_cat,
                                                                              i_id_institution        => i_id_institution,
                                                                              o_prof_ext_affiliations => o_prof_ext_accounts,
                                                                              o_error                 => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_professional_ext);
                pk_types.open_my_cursor(o_prof_ext_accounts);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_EXT_PROF_DETAIL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_ext_prof_detail;

    /********************************************************************************************
    * Cancel external professional
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_professional_ext            Array of External professional ID
    * @param o_id_professional_ext         External professional canceled ID's list
    * @param o_id_professional_ext_hist    External professional history updated ID's list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION cancel_ext_professional
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_professional_ext         IN table_number,
        o_id_professional_ext      OUT table_number,
        o_id_professional_ext_hist OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_professional_ext_hist professional_ext_hist.id_professional_ext_hist%TYPE;
        l_flg_exists               VARCHAR2(1);
        l_count                    PLS_INTEGER := 0;
    
    BEGIN
        o_id_professional_ext      := table_number();
        o_id_professional_ext_hist := table_number();
    
        IF i_professional_ext.count > 0
        THEN
            FOR i IN i_professional_ext.first .. i_professional_ext.last
            LOOP
                o_id_professional_ext.extend();
            
                g_error := 'CANCEL EXTERNAL PROFESSIONAL';
                pk_alertlog.log_debug(g_error);
            
                UPDATE professional_ext pe
                   SET pe.flg_available = pk_alert_constant.g_no
                 WHERE pe.id_professional_ext = i_professional_ext(i);
            
                o_id_professional_ext(i) := i_professional_ext(i);
            
                g_error := 'GET EXTERNAL PROFESSIONAL HISTORY ID';
                pk_alertlog.log_debug(g_error);
                BEGIN
                
                    SELECT id_professional_ext_hist
                      INTO l_id_professional_ext_hist
                      FROM (SELECT id_professional_ext_hist,
                                   begin_date,
                                   row_number() over(PARTITION BY id_professional_ext ORDER BY begin_date DESC) t
                              FROM professional_ext_hist
                             WHERE id_professional_ext = i_professional_ext(i)) peh
                     WHERE peh.t = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_exists := pk_alert_constant.g_no;
                END;
            
                g_error := 'UPDATE EXTERNAL PROFESSIONAL HISTORY';
                pk_alertlog.log_debug(g_error);
                IF l_flg_exists != pk_alert_constant.g_no
                THEN
                    o_id_professional_ext_hist.extend();
                    l_count := l_count + 1;
                
                    UPDATE professional_ext_hist peh
                       SET peh.end_date = current_timestamp, peh.flg_available = pk_alert_constant.g_no
                     WHERE peh.id_professional_ext_hist = l_id_professional_ext_hist;
                
                    o_id_professional_ext(l_count) := l_id_professional_ext_hist;
                END IF;
            END LOOP;
        
            COMMIT;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'CANCEL_EXT_PROFESSIONAL');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_ext_professional;

    /********************************************************************************************
    * Get an external professional info for editing
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_professional_ext         External professional ID
    * @param o_professional_ext            External professional info to edit
    * @param o_prof_ext_accounts           External professional accounts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION edit_ext_professional
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        o_professional_ext    OUT pk_types.cursor_type,
        o_prof_ext_accounts   OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_accounts BOOLEAN;
    
    BEGIN
        g_error := 'GET EXTERNAL PROFESSIONAL DATA';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_professional_ext FOR
            SELECT pe.id_professional_ext,
                   pe.name,
                   pe.title,
                   pk_backoffice.get_prof_title_desc(i_lang, pe.title) desc_title,
                   pe.first_name,
                   pe.middle_name,
                   pe.last_name,
                   pe.initials,
                   pk_backoffice.get_date_to_be_sent(i_lang, pe.dt_birth) date_birth,
                   pk_date_utils.date_chr_extend(i_lang, pe.dt_birth, profissional(0, 0, 0)) string_birth,
                   pk_sysdomain.get_domain('PROFESSIONAL.GENDER', pe.gender, i_lang) desc_gender,
                   pe.gender,
                   pk_sysdomain.get_domain('PROFESSIONAL.MARITAL_STATUS', pe.marital_status, i_lang) desc_marital_status,
                   pe.marital_status,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cat.code_category
                                                     FROM category cat
                                                    WHERE cat.id_category = g_physician_cat
                                                      AND cat.flg_available = pk_alert_constant.g_yes)) flg_clinical,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT s.code_speciality
                                                     FROM speciality s
                                                    WHERE s.id_speciality = pe.id_speciality
                                                      AND s.flg_available = pk_alert_constant.g_yes)) spec,
                   pe.id_speciality,
                   (SELECT pe.id_category_sub
                      FROM professional_ext pe
                     WHERE pe.id_professional_ext = i_id_professional_ext) id_category_in_surgery,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT cs.code_category_sub
                                                     FROM category_sub cs
                                                     JOIN professional_ext pe
                                                       ON cs.id_category_sub = pe.id_category_sub
                                                    WHERE pe.id_professional_ext = i_id_professional_ext
                                                      AND cs.flg_available = pk_alert_constant.g_yes)) category_in_surgery,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   pe.id_language id_lang,
                   pe.address,
                   pe.city,
                   pe.district,
                   pe.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = pe.id_country)) country,
                   pe.id_country,
                   pe.work_phone,
                   pe.num_contact,
                   pe.cell_phone,
                   pe.fax,
                   pe.website,
                   pe.email,
                   pe.office_name
              FROM professional_ext pe
             WHERE pe.id_professional_ext = i_id_professional_ext;
    
        g_error := 'GET EXTERNAL PROFESSIONAL ACCOUNTS';
        pk_alertlog.log_debug(g_error);
    
        l_accounts := pk_backoffice_disposition.get_prof_ext_cat_affiliations(i_lang                  => i_lang,
                                                                              i_id_professional_ext   => i_id_professional_ext,
                                                                              i_id_category           => g_physician_cat,
                                                                              i_id_institution        => i_id_institution,
                                                                              o_prof_ext_affiliations => o_prof_ext_accounts,
                                                                              o_error                 => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_professional_ext);
                pk_types.open_my_cursor(o_prof_ext_accounts);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'EDIT_EXT_PROFESSIONAL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END edit_ext_professional;

    /********************************************************************************************
    * Set an external professional
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_professional_ext         External professional ID
    * @param i_id_institution              Institution ID
    * @param i_title                       Professional's title
    * @param i_first_name                  First name
    * @param i_last_name                   Last name
    * @param i_gender                      Flag gender
    * @param i_id_speciality               Professional's speciality
    * @param i_id_category                 Professional's category
    * @param i_id_category_sub             Professional's surgery category
    * @param i_id_language                 Professional's prefered language
    * @param i_address                     Address
    * @param i_city                        City
    * @param i_district                    District
    * @param i_zip_code                    Zip code
    * @param i_id_country                  Country ID
    * @param i_work_phone                  Work phone number
    * @param i_fax                         Fax
    * @param i_website                     Website address
    * @param i_email                       E-mail
    * @param i_cell_phone                  Cell phone number
    * @param i_dt_birth                    Birth date
    * @param i_num_contact                 Contact number
    * @param i_marital_status              Marital status flag
    * @param i_initials                    Initials
    * @param i_middle_name                 Middle name
    * @param i_office_name                 Offices name
    * @param o_id_professional_ext         External professional's ID updated/inserted
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION set_ext_professional
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        i_id_institution      IN professional_ext.id_institution%TYPE,
        i_title               IN professional_ext.title%TYPE,
        i_first_name          IN professional_ext.first_name%TYPE,
        i_last_name           IN professional_ext.last_name%TYPE,
        i_gender              IN professional_ext.gender%TYPE,
        i_id_speciality       IN professional_ext.id_speciality%TYPE,
        i_id_category         IN professional_ext.id_category%TYPE,
        i_id_category_sub     IN professional_ext.id_category_sub%TYPE,
        i_id_language         IN professional_ext.id_language%TYPE,
        i_address             IN professional_ext.address%TYPE,
        i_city                IN professional_ext.city%TYPE,
        i_district            IN professional_ext.district%TYPE,
        i_zip_code            IN professional_ext.zip_code%TYPE,
        i_id_country          IN professional_ext.id_country%TYPE,
        i_work_phone          IN professional_ext.work_phone%TYPE,
        i_fax                 IN professional_ext.fax%TYPE,
        i_website             IN professional_ext.website%TYPE,
        i_email               IN professional_ext.email%TYPE,
        i_cell_phone          IN professional_ext.cell_phone%TYPE,
        i_dt_birth            IN professional_ext.dt_birth%TYPE,
        i_num_contact         IN professional_ext.num_contact%TYPE,
        i_marital_status      IN professional_ext.marital_status%TYPE,
        i_initials            IN professional_ext.initials%TYPE,
        i_middle_name         IN professional_ext.middle_name%TYPE,
        i_office_name         IN professional_ext.office_name%TYPE,
        o_id_professional_ext OUT professional_ext.id_professional_ext%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_exists               VARCHAR2(1) := 'Y';
        l_id_professional_ext      professional_ext.id_professional_ext%TYPE;
        l_id_professional_ext_hist professional_ext_hist.id_professional_ext_hist%TYPE;
    
    BEGIN
        g_error := 'SET EXTERNAL PROFESSIONAL DATA';
        pk_alertlog.log_debug(g_error);
    
        IF i_id_professional_ext IS NOT NULL
        THEN
            UPDATE professional_ext pe
               SET pe.title           = i_title,
                   pe.first_name      = i_first_name,
                   pe.last_name       = i_last_name,
                   pe.gender          = i_gender,
                   pe.id_speciality   = i_id_speciality,
                   pe.id_category     = i_id_category,
                   pe.id_category_sub = i_id_category_sub,
                   pe.id_language     = i_id_language,
                   pe.address         = i_address,
                   pe.city            = i_city,
                   pe.district        = i_district,
                   pe.zip_code        = i_zip_code,
                   pe.id_country      = i_id_country,
                   pe.work_phone      = i_work_phone,
                   pe.fax             = i_fax,
                   pe.website         = i_website,
                   pe.email           = i_email,
                   pe.cell_phone      = i_cell_phone,
                   pe.id_institution  = i_id_institution,
                   pe.flg_available   = pk_alert_constant.g_yes,
                   pe.dt_birth        = i_dt_birth,
                   pe.num_contact     = i_num_contact,
                   pe.marital_status  = i_marital_status,
                   pe.initials        = i_initials,
                   pe.middle_name     = i_middle_name,
                   pe.name            = i_first_name || decode(i_middle_name, NULL, '', ' ' || i_middle_name) ||
                                        decode(i_last_name, NULL, '', ' ' || i_last_name),
                   pe.office_name     = i_office_name
             WHERE pe.id_professional_ext = i_id_professional_ext;
        
            l_id_professional_ext := i_id_professional_ext;
        ELSE
            BEGIN
                SELECT seq_professional_ext.nextval
                  INTO l_id_professional_ext
                  FROM dual;
            
                INSERT INTO professional_ext
                    (id_professional_ext,
                     title,
                     first_name,
                     last_name,
                     gender,
                     id_speciality,
                     id_category,
                     id_category_sub,
                     id_language,
                     address,
                     city,
                     district,
                     zip_code,
                     id_country,
                     work_phone,
                     fax,
                     website,
                     email,
                     cell_phone,
                     id_institution,
                     flg_available,
                     dt_birth,
                     num_contact,
                     marital_status,
                     initials,
                     middle_name,
                     name,
                     office_name)
                VALUES
                    (l_id_professional_ext,
                     i_title,
                     i_first_name,
                     i_last_name,
                     i_gender,
                     i_id_speciality,
                     i_id_category,
                     i_id_category_sub,
                     i_id_language,
                     i_address,
                     i_city,
                     i_district,
                     i_zip_code,
                     i_id_country,
                     i_work_phone,
                     i_fax,
                     i_website,
                     i_email,
                     i_cell_phone,
                     i_id_institution,
                     pk_alert_constant.g_yes,
                     i_dt_birth,
                     i_num_contact,
                     i_marital_status,
                     i_initials,
                     i_middle_name,
                     i_first_name || decode(i_middle_name, NULL, '', ' ' || i_middle_name) ||
                     decode(i_last_name, NULL, '', ' ' || i_last_name),
                     i_office_name);
            END;
        
        END IF;
    
        g_error := 'SELECT EXTERNAL PROFESSIONAL HIST LAST RECORD ID';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_professional_ext_hist
              INTO l_id_professional_ext_hist
              FROM (SELECT id_professional_ext_hist,
                           begin_date,
                           row_number() over(PARTITION BY id_professional_ext ORDER BY begin_date DESC) t
                      FROM professional_ext_hist
                     WHERE id_professional_ext = l_id_professional_ext) peh
             WHERE peh.t = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_exists := pk_alert_constant.g_no;
        END;
    
        IF l_flg_exists != pk_alert_constant.g_no
        THEN
            UPDATE professional_ext_hist peh
               SET peh.end_date = current_timestamp
             WHERE peh.id_professional_ext_hist = l_id_professional_ext_hist;
        END IF;
    
        SELECT seq_professional_ext_hist.nextval
          INTO l_id_professional_ext_hist
          FROM dual;
    
        g_error := 'SET EXTERNAL PROFESSIONAL HISTORY DATA';
        pk_alertlog.log_debug(g_error);
        INSERT INTO professional_ext_hist
            (id_professional_ext_hist,
             id_professional_ext,
             title,
             first_name,
             last_name,
             gender,
             id_speciality,
             id_category,
             id_category_sub,
             id_language,
             address,
             city,
             district,
             zip_code,
             id_country,
             work_phone,
             fax,
             website,
             email,
             cell_phone,
             id_institution,
             flg_available,
             dt_birth,
             num_contact,
             marital_status,
             initials,
             middle_name,
             name,
             office_name,
             begin_date,
             end_date,
             id_professional)
        VALUES
            (l_id_professional_ext_hist,
             l_id_professional_ext,
             i_title,
             i_first_name,
             i_last_name,
             i_gender,
             i_id_speciality,
             i_id_category,
             i_id_category_sub,
             i_id_language,
             i_address,
             i_city,
             i_district,
             i_zip_code,
             i_id_country,
             i_work_phone,
             i_fax,
             i_website,
             i_email,
             i_cell_phone,
             i_id_institution,
             pk_alert_constant.g_yes,
             i_dt_birth,
             i_num_contact,
             i_marital_status,
             i_initials,
             i_middle_name,
             i_first_name || decode(i_middle_name, NULL, '', ' ' || i_middle_name) ||
             decode(i_last_name, NULL, '', ' ' || i_last_name),
             i_office_name,
             current_timestamp,
             NULL,
             i_prof.id);
    
        o_id_professional_ext := l_id_professional_ext;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'SET_EXT_PROFESSIONAL');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_ext_professional;

    /********************************************************************************************
    * Get a list of external institutions for the institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_flg_type                    External institution's flag type (O-Office; C-Clinic)
    * @param i_id_institution              Institution ID
    * @param o_institution_ext             External institution's info list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN institution_ext.flg_type%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_institution_ext OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EXTERNAL INSTITUTION CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_institution_ext FOR
            SELECT ie.id_institution_ext id,
                   ie.institution_name name,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                                 FROM instit_ext_clin_serv iecs
                                                 JOIN clinical_service cs
                                                   ON iecs.id_clinical_service = cs.id_clinical_service
                                                WHERE iecs.id_institution_ext = ie.id_institution_ext
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') specialty,
                   ie.address,
                   ie.zip_code,
                   ie.work_phone,
                   pk_alert_constant.g_inactive flg_select
              FROM institution_ext ie
             WHERE ie.id_institution = i_id_institution
               AND ie.flg_type = i_flg_type
               AND ie.flg_available = pk_alert_constant.g_yes;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_institution_ext);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_EXT_INSTITUTION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_ext_institution;

    /********************************************************************************************
    * Get an external institution's detail
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_institution_ext          External institution ID
    * @param o_institution_ext             External institution info
    * @param o_instit_ext_accounts         External institution's accounts info
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_ext_inst_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_institution_ext  IN institution_ext.id_institution_ext%TYPE,
        o_institution_ext     OUT pk_types.cursor_type,
        o_instit_ext_accounts OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_accounts   BOOLEAN;
        l_id_country country.id_country%TYPE;
    
    BEGIN
        g_error := 'GET EXTERNAL INSTITUTION DATA AND HISTORY';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_institution_ext FOR
            SELECT ieh.id_institution_ext,
                   ieh.institution_name,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                                 FROM instit_ext_clin_serv iecs
                                                 JOIN clinical_service cs
                                                   ON iecs.id_clinical_service = cs.id_clinical_service
                                                WHERE iecs.id_institution_ext = ieh.id_institution_ext
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') spec,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT cs.id_clinical_service
                                                 FROM instit_ext_clin_serv iecs
                                                 JOIN clinical_service cs
                                                   ON iecs.id_clinical_service = cs.id_clinical_service
                                                WHERE iecs.id_institution_ext = ieh.id_institution_ext
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') id_spec,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   ieh.id_language id_lang,
                   ieh.address,
                   ieh.location,
                   ieh.district,
                   ieh.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = ieh.id_country)) country,
                   ieh.id_country,
                   ieh.work_phone,
                   ieh.fax,
                   ieh.website,
                   ieh.email,
                   pk_alert_constant.g_active flg_status,
                   pk_date_utils.date_hour_chr_extend(i_lang, ieh.begin_date, profissional(0, i_id_institution, 26)) bg_date,
                   ieh.id_professional,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = ieh.id_professional) prof,
                   ieh.begin_date
              FROM institution_ext_hist ieh
             WHERE ieh.id_institution_ext = i_id_institution_ext
               AND ieh.end_date IS NULL
            UNION
            SELECT ieh.id_institution_ext,
                   ieh.institution_name,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                                 FROM instit_ext_clin_serv_hist icsh
                                                 JOIN clinical_service cs
                                                   ON icsh.id_clinical_service = cs.id_clinical_service
                                                WHERE icsh.id_institution_ext_hist = ieh.id_institution_ext_hist
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') spec,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT cs.id_clinical_service
                                                 FROM instit_ext_clin_serv_hist icsh
                                                 JOIN clinical_service cs
                                                   ON icsh.id_clinical_service = cs.id_clinical_service
                                                WHERE icsh.id_institution_ext_hist = ieh.id_institution_ext_hist
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') id_spec,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   ieh.id_language id_lang,
                   ieh.address,
                   ieh.location,
                   ieh.district,
                   ieh.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = ieh.id_country)) country,
                   ieh.id_country,
                   ieh.work_phone,
                   ieh.fax,
                   ieh.website,
                   ieh.email,
                   pk_alert_constant.g_inactive flg_status,
                   pk_date_utils.date_hour_chr_extend(i_lang, ieh.begin_date, profissional(0, i_id_institution, 26)) bg_date,
                   ieh.id_professional,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = ieh.id_professional) prof,
                   ieh.begin_date
              FROM institution_ext_hist ieh
              LEFT OUTER JOIN instit_ext_clin_serv_hist icsh
                ON ieh.id_institution_ext_hist = icsh.id_institution_ext_hist
             WHERE ieh.id_institution_ext = i_id_institution_ext
               AND ieh.end_date IS NOT NULL
             ORDER BY flg_status ASC, begin_date DESC;
    
        g_error := 'GET EXTERNAL INSTITUTION COUNTRY';
        pk_alertlog.log_debug(g_error);
        SELECT ie.id_country
          INTO l_id_country
          FROM institution_ext ie
         WHERE ie.id_institution_ext = i_id_institution_ext;
    
        g_error := 'GET EXTERNAL INSTITUTION ACCOUNTS';
        pk_alertlog.log_debug(g_error);
        l_accounts := pk_backoffice_disposition.get_inst_ext_ctry_affiliations(i_lang                  => i_lang,
                                                                               i_id_institution_ext    => i_id_institution_ext,
                                                                               i_id_country            => l_id_country,
                                                                               o_inst_ext_affiliations => o_instit_ext_accounts,
                                                                               o_error                 => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_institution_ext);
                pk_types.open_my_cursor(o_instit_ext_accounts);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_EXT_INST_DETAIL');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_ext_inst_detail;

    /********************************************************************************************
    * Cancel external institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_institution_ext             Array of external institution ID's
    * @param o_id_institution_ext          Array of canceled external institution's ID
    * @param o_id_institution_ext_hist     Array of external institution history updated ID's list
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION cancel_ext_institution
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_institution_ext         IN table_number,
        o_id_institution_ext      OUT table_number,
        o_id_institution_ext_hist OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_institution_ext_hist institution_ext_hist.id_institution_ext_hist%TYPE;
        l_flg_exists              VARCHAR2(1);
        l_count                   PLS_INTEGER := 0;
    
    BEGIN
        o_id_institution_ext      := table_number();
        o_id_institution_ext_hist := table_number();
    
        IF i_institution_ext.count > 0
        THEN
            FOR i IN i_institution_ext.first .. i_institution_ext.last
            LOOP
                o_id_institution_ext.extend();
            
                g_error := 'CANCEL EXTERNAL INSTITUTION';
                pk_alertlog.log_debug(g_error);
            
                UPDATE institution_ext ie
                   SET ie.flg_available = pk_alert_constant.g_no
                 WHERE ie.id_institution_ext = i_institution_ext(i);
            
                o_id_institution_ext(i) := i_institution_ext(i);
            
                g_error := 'GET EXTERNAL INSTITUTION HISTORY ID';
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT id_institution_ext_hist
                      INTO l_id_institution_ext_hist
                      FROM (SELECT id_institution_ext_hist,
                                   begin_date,
                                   row_number() over(PARTITION BY id_institution_ext ORDER BY begin_date DESC) t
                              FROM institution_ext_hist
                             WHERE id_institution_ext = i_institution_ext(i)) ieh
                     WHERE ieh.t = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_exists := pk_alert_constant.g_no;
                END;
            
                g_error := 'UPDATE EXTERNAL INSTITUTION HISTORY';
                pk_alertlog.log_debug(g_error);
                IF l_flg_exists != pk_alert_constant.g_no
                THEN
                    o_id_institution_ext_hist.extend();
                    l_count := l_count + 1;
                
                    UPDATE institution_ext_hist peh
                       SET peh.end_date = current_timestamp, peh.flg_available = pk_alert_constant.g_no
                     WHERE peh.id_institution_ext_hist = l_id_institution_ext_hist;
                
                    o_id_institution_ext(l_count) := l_id_institution_ext_hist;
                END IF;
            END LOOP;
        
            COMMIT;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'CANCEL_EXT_INSTITUTION');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_ext_institution;

    /********************************************************************************************
    * Get an external institution info for editing
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution              Institution ID
    * @param i_id_institution_ext          External institution ID
    * @param o_institution_ext             External institution info
    * @param o_instit_ext_accounts         External institution acccounts info
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION edit_ext_institution
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_institution_ext  IN institution_ext.id_institution_ext%TYPE,
        o_institution_ext     OUT pk_types.cursor_type,
        o_instit_ext_accounts OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_accounts   BOOLEAN;
        l_id_country country.id_country%TYPE;
    
    BEGIN
        g_error := 'GET EXTERNAL INSTITUTION DATA';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_institution_ext FOR
            SELECT ie.id_institution_ext,
                   ie.institution_name,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                                 FROM instit_ext_clin_serv iecs
                                                 JOIN clinical_service cs
                                                   ON iecs.id_clinical_service = cs.id_clinical_service
                                                WHERE iecs.id_institution_ext = ie.id_institution_ext
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ', ') spec,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT cs.id_clinical_service
                                                 FROM instit_ext_clin_serv iecs
                                                 JOIN clinical_service cs
                                                   ON iecs.id_clinical_service = cs.id_clinical_service
                                                WHERE iecs.id_institution_ext = ie.id_institution_ext
                                                ORDER BY pk_translation.get_translation(i_lang, cs.code_clinical_service)) AS
                                              table_varchar),
                                         ',') id_spec,
                   pk_backoffice.get_institution_language(i_lang, i_id_institution) desc_lang,
                   ie.id_language id_lang,
                   ie.address,
                   ie.location,
                   ie.district,
                   ie.zip_code,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT c.code_country
                                                     FROM country c
                                                    WHERE c.id_country = ie.id_country)) country,
                   ie.id_country,
                   ie.work_phone,
                   ie.fax,
                   ie.website,
                   ie.email
              FROM institution_ext ie
             WHERE ie.id_institution_ext = i_id_institution_ext;
    
        g_error := 'GET EXTERNAL INSTITUTION ACCOUNTS';
        pk_alertlog.log_debug(g_error);
    
        g_error := 'GET EXTERNAL INSTITUTION COUNTRY';
        pk_alertlog.log_debug(g_error);
        SELECT ie.id_country
          INTO l_id_country
          FROM institution_ext ie
         WHERE ie.id_institution_ext = i_id_institution_ext;
    
        g_error := 'GET EXTERNAL INSTITUTION ACCOUNTS';
        pk_alertlog.log_debug(g_error);
        l_accounts := pk_backoffice_disposition.get_inst_ext_ctry_affiliations(i_lang                  => i_lang,
                                                                               i_id_institution_ext    => i_id_institution_ext,
                                                                               i_id_country            => l_id_country,
                                                                               o_inst_ext_affiliations => o_instit_ext_accounts,
                                                                               o_error                 => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_institution_ext);
                pk_types.open_my_cursor(o_instit_ext_accounts);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'EDIT_EXT_INSTITUTION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END edit_ext_institution;

    /********************************************************************************************
    * Set an external institution
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_id_institution_ext          External institution ID
    * @param i_id_institution              Institution ID
    * @param i_flg_type                    External institution flag type
    * @param i_institution_name            External institution name
    * @param i_id_language                 External institution prefered language
    * @param i_address                     Address
    * @param i_location                    Location
    * @param i_district                    District
    * @param i_zip_code                    Zip code
    * @param i_id_country                  Country ID
    * @param i_work_phone                  Work phone number
    * @param i_fax                         Fax number
    * @param i_website                     Website address
    * @param i_email                       E-mail
    * @param i_specialities                Array of clinical services
    * @param o_id_institution_ext          External institution ID inserted/updated
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION set_ext_institution
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_institution_ext IN institution_ext.id_institution_ext%TYPE,
        i_id_institution     IN institution_ext.id_institution%TYPE,
        i_flg_type           IN institution_ext.flg_type%TYPE,
        i_institution_name   IN institution_ext.institution_name%TYPE,
        i_id_language        IN institution_ext.id_language%TYPE,
        i_address            IN institution_ext.address%TYPE,
        i_location           IN institution_ext.location%TYPE,
        i_district           IN institution_ext.district%TYPE,
        i_zip_code           IN institution_ext.zip_code%TYPE,
        i_id_country         IN institution_ext.id_country%TYPE,
        i_work_phone         IN institution_ext.work_phone%TYPE,
        i_fax                IN institution_ext.fax%TYPE,
        i_website            IN institution_ext.website%TYPE,
        i_email              IN institution_ext.email%TYPE,
        i_specialities       IN table_number,
        o_id_institution_ext OUT institution_ext.id_institution_ext%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_exists              VARCHAR2(1) := 'Y';
        l_id_institution_ext      institution_ext.id_institution_ext%TYPE;
        l_id_institution_ext_hist institution_ext_hist.id_institution_ext_hist%TYPE;
    
    BEGIN
        g_error := 'SET EXTERNAL INSTITUTION DATA';
        pk_alertlog.log_debug(g_error);
    
        IF i_id_institution_ext IS NOT NULL
        THEN
            UPDATE institution_ext ie
               SET ie.flg_type         = i_flg_type,
                   ie.institution_name = i_institution_name,
                   ie.id_language      = i_id_language,
                   ie.address          = i_address,
                   ie.location         = i_location,
                   ie.district         = i_district,
                   ie.zip_code         = i_zip_code,
                   ie.id_country       = i_id_country,
                   ie.work_phone       = i_work_phone,
                   ie.fax              = i_fax,
                   ie.website          = i_website,
                   ie.email            = i_email,
                   ie.id_institution   = i_id_institution,
                   ie.flg_available    = pk_alert_constant.g_yes
             WHERE ie.id_institution_ext = i_id_institution_ext;
        
            l_id_institution_ext := i_id_institution_ext;
        ELSE
            BEGIN
                SELECT seq_institution_ext.nextval
                  INTO l_id_institution_ext
                  FROM dual;
            
                INSERT INTO institution_ext
                    (id_institution_ext,
                     flg_type,
                     institution_name,
                     id_language,
                     address,
                     location,
                     district,
                     zip_code,
                     id_country,
                     work_phone,
                     fax,
                     website,
                     email,
                     id_institution,
                     flg_available)
                VALUES
                    (l_id_institution_ext,
                     i_flg_type,
                     i_institution_name,
                     i_id_language,
                     i_address,
                     i_location,
                     i_district,
                     i_zip_code,
                     i_id_country,
                     i_work_phone,
                     i_fax,
                     i_website,
                     i_email,
                     i_id_institution,
                     pk_alert_constant.g_yes);
            END;
        
        END IF;
    
        g_error := 'SELECT EXTERNAL INSTITUTION HIST LAST RECORD ID';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_institution_ext_hist
              INTO l_id_institution_ext_hist
              FROM (SELECT id_institution_ext_hist,
                           begin_date,
                           row_number() over(PARTITION BY id_institution_ext ORDER BY begin_date DESC) t
                      FROM institution_ext_hist
                     WHERE id_institution_ext = l_id_institution_ext) ieh
             WHERE ieh.t = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_exists := pk_alert_constant.g_no;
        END;
    
        IF l_flg_exists != pk_alert_constant.g_no
        THEN
            UPDATE institution_ext_hist ieh
               SET ieh.end_date = current_timestamp
             WHERE ieh.id_institution_ext_hist = l_id_institution_ext_hist;
        END IF;
    
        SELECT seq_institution_ext_hist.nextval
          INTO l_id_institution_ext_hist
          FROM dual;
    
        g_error := 'SET EXTERNAL INSTITUTION HISTORY DATA';
        pk_alertlog.log_debug(g_error);
        INSERT INTO institution_ext_hist
            (id_institution_ext_hist,
             id_institution_ext,
             flg_type,
             institution_name,
             id_language,
             address,
             location,
             district,
             zip_code,
             id_country,
             work_phone,
             fax,
             website,
             email,
             id_institution,
             flg_available,
             begin_date,
             end_date,
             id_professional)
        VALUES
            (l_id_institution_ext_hist,
             l_id_institution_ext,
             i_flg_type,
             i_institution_name,
             i_id_language,
             i_address,
             i_location,
             i_district,
             i_zip_code,
             i_id_country,
             i_work_phone,
             i_fax,
             i_website,
             i_email,
             i_id_institution,
             pk_alert_constant.g_yes,
             current_timestamp,
             NULL,
             i_prof.id);
    
        -- DELETE OLD SPECIALITIES AND CREATE THE NEW ONES
        g_error := 'SET EXTERNAL INSTITUTION SPECIALITIES';
        pk_alertlog.log_debug(g_error);
        IF i_specialities IS NOT NULL
        THEN
            DELETE instit_ext_clin_serv iecs
             WHERE iecs.id_institution_ext = l_id_institution_ext;
        
            FOR i IN i_specialities.first .. i_specialities.last
            LOOP
                INSERT INTO instit_ext_clin_serv
                    (id_institution_ext, id_clinical_service)
                VALUES
                    (l_id_institution_ext, i_specialities(i));
            
                INSERT INTO instit_ext_clin_serv_hist
                    (id_institution_ext_hist, id_clinical_service)
                VALUES
                    (l_id_institution_ext_hist, i_specialities(i));
            
            END LOOP;
        END IF;
    
        o_id_institution_ext := l_id_institution_ext;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'SET_EXT_INSTITUTION');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_ext_institution;

    /********************************************************************************************
    * Set external institution affiliations values
    *
    * @param i_lang                        Language
    * @param i_id_institution_ext          External institution ID
    * @param i_accounts                    Affiliations ID's
    * @param i_values                      Affiliations Values
    * @param o_error                       Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   SC
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_inst_ext_affiliations
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution_ext IN institution.id_institution%TYPE,
        i_accounts           IN table_number,
        i_values             IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_accounts.count
        LOOP
        
            g_error := 'MERGE INTO INSTITUTION_EXT_ACCOUNTS';
            MERGE INTO institution_ext_accounts iea
            USING (SELECT i_accounts(i) acc, i_values(i) val
                     FROM dual) t
            ON (iea.id_account = t.acc AND iea.id_institution_ext = i_id_institution_ext)
            WHEN MATCHED THEN
                UPDATE
                   SET iea.value = t.val
            WHEN NOT MATCHED THEN
                INSERT
                    (id_institution_ext, id_account, VALUE)
                VALUES
                    (i_id_institution_ext, t.acc, t.val);
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'SET_INST_EXT_AFFILIATIONS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_inst_ext_affiliations;

    /********************************************************************************************
    * Set external professional affiliations values
    *
    * @param i_lang                        Language
    * @param i_id_professional_ext         Professional ID
    * @param i_id_institution              Institution ID
    * @param i_accounts                    Affiliations ID's
    * @param i_values                      Affiliations Values
    * @param o_error                       Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   SC
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_prof_ext_affiliations
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional_ext IN professional_ext.id_professional_ext%TYPE,
        i_institution         IN table_number,
        i_accounts            IN table_number,
        i_values              IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_accounts.count
        LOOP
        
            g_error := 'MERGE INTO PROF_EXT_ACCOUNTS';
            MERGE INTO prof_ext_accounts pea
            USING (SELECT i_accounts(i) acc, i_values(i) val, i_institution(i) inst
                     FROM dual) t
            ON (pea.id_account = t.acc AND pea.id_professional_ext = i_id_professional_ext AND pea.id_institution = t.inst)
            WHEN MATCHED THEN
                UPDATE
                   SET pea.value = t.val
            WHEN NOT MATCHED THEN
                INSERT
                    (id_professional_ext, id_account, VALUE, id_institution)
                VALUES
                    (i_id_professional_ext, t.acc, t.val, t.inst);
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'SET_PROF_EXT_AFFILIATIONS');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_prof_ext_affiliations;

    /********************************************************************************************
    * Get external institutions country affiliations
    *
    * @param i_lang                        Language
    * @param i_id_institution_ext          Institution ID
    * @param i_id_country                  Country ID
    * @param o_inst_ext_affiliations       Affiliations cursor
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_inst_ext_ctry_affiliations
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_institution_ext    IN institution_ext.id_institution_ext%TYPE,
        i_id_country            IN country.id_country%TYPE,
        o_inst_ext_affiliations OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET INSTITUTION COUNTRY AFFILIATIONS CURSOR';
        OPEN o_inst_ext_affiliations FOR
            SELECT a.id_account,
                   pk_translation.get_translation(i_lang, a.code_account) account_name,
                   a.fill_type,
                   a.sys_domain_identifier,
                   (SELECT iea.value
                      FROM institution_ext_accounts iea
                     WHERE iea.id_account = a.id_account
                       AND iea.id_institution_ext = i_id_institution_ext) VALUE,
                   decode(a.fill_type,
                          'M',
                          nvl((pk_sysdomain.get_domain(a.sys_domain_identifier,
                                                       (SELECT iea.value
                                                          FROM institution_ext_accounts iea
                                                         WHERE iea.id_account = a.id_account
                                                           AND iea.id_institution_ext = i_id_institution_ext),
                                                       i_lang)),
                              NULL),
                          (SELECT iea.value
                             FROM institution_ext_accounts iea
                            WHERE iea.id_account = a.id_account
                              AND iea.id_institution_ext = i_id_institution_ext)) value_desc
              FROM accounts a, accounts_country ac
             WHERE a.flg_available = 'Y'
               AND a.flg_type IN ('I', 'B')
               AND pk_translation.get_translation(i_lang, a.code_account) IS NOT NULL
               AND a.id_account = ac.id_account
               AND ac.id_country = i_id_country;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_inst_ext_affiliations);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_INST_EXT_CTRY_AFFILIATIONS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_inst_ext_ctry_affiliations;

    /********************************************************************************************
    * Get external professional category affiliations
    *
    * @param i_lang                        Language
    * @param i_id_professional_ext         Professional ID
    * @param i_id_category                 Category ID
    * @param i_id_institution              Institution ID
    * @param o_prof_ext_affiliations       Affiliations cursor
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_prof_ext_cat_affiliations
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_professional_ext   IN professional.id_professional%TYPE,
        i_id_category           IN category.id_category%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        o_prof_ext_affiliations OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROFESSIONAL_EXT AFFILIATIONS CURSOR';
        OPEN o_prof_ext_affiliations FOR
            SELECT a.id_account,
                   pk_translation.get_translation(i_lang, a.code_account) account_name,
                   a.fill_type,
                   a.sys_domain_identifier,
                   decode(acat.flg_institution,
                          'Y',
                          (SELECT pea.value
                             FROM prof_ext_accounts pea
                            WHERE pea.id_account = a.id_account
                              AND pea.id_professional_ext = i_id_professional_ext
                              AND pea.id_institution = i_id_institution),
                          (SELECT pea.value
                             FROM prof_ext_accounts pea
                            WHERE pea.id_account = a.id_account
                              AND pea.id_professional_ext = i_id_professional_ext
                              AND pea.id_institution = 0)) VALUE,
                   decode(a.fill_type,
                          'M',
                          nvl((pk_sysdomain.get_domain(a.sys_domain_identifier,
                                                       (decode(acat.flg_institution,
                                                               'Y',
                                                               (SELECT pea.value
                                                                  FROM prof_ext_accounts pea
                                                                 WHERE pea.id_account = a.id_account
                                                                   AND pea.id_professional_ext = i_id_professional_ext
                                                                   AND pea.id_institution = i_id_institution),
                                                               (SELECT pea.value
                                                                  FROM prof_ext_accounts pea
                                                                 WHERE pea.id_account = a.id_account
                                                                   AND pea.id_professional_ext = i_id_professional_ext
                                                                   AND pea.id_institution = 0))),
                                                       i_lang)),
                              NULL),
                          (decode(acat.flg_institution,
                                  'Y',
                                  (SELECT pea.value
                                     FROM prof_ext_accounts pea
                                    WHERE pea.id_account = a.id_account
                                      AND pea.id_professional_ext = i_id_professional_ext
                                      AND pea.id_institution = i_id_institution),
                                  (SELECT pea.value
                                     FROM prof_ext_accounts pea
                                    WHERE pea.id_account = a.id_account
                                      AND pea.id_professional_ext = i_id_professional_ext
                                      AND pea.id_institution = 0)))) value_desc,
                   decode(acat.flg_institution, 'N', 0, i_id_institution) id_institution
              FROM accounts a, accounts_category acat
             WHERE a.flg_available = 'Y'
               AND a.flg_type IN ('P', 'B')
               AND pk_translation.get_translation(i_lang, a.code_account) IS NOT NULL
               AND a.id_account = acat.id_account
               AND acat.id_category = i_id_category;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_prof_ext_affiliations);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_PROF_EXT_CAT_AFFILIATIONS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_prof_ext_cat_affiliations;

    /********************************************************************************************
    * Get title list
    *
    * @param i_lang                        Language
    * @param o_title                       Title list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_prof_ext_title_list
    (
        i_lang  IN language.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_title FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = 'PROFESSIONAL_EXT.TITLE'
               AND flg_available = pk_alert_constant.g_yes
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_title);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_PROF_EXT_TITLE_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_prof_ext_title_list;

    /********************************************************************************************
    * Get gender list
    *
    * @param i_lang                        Language
    * @param o_gender                      Gender list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET GENDER CURSOR';
        RETURN pk_sysdomain.get_values_domain('PROFESSIONAL.GENDER', i_lang, o_gender);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_gender);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_GENDER_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_gender_list;

    /********************************************************************************************
    * Get country list
    *
    * @param i_lang                        Language
    * @param o_country                     Country list
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_country_list
    (
        i_lang    IN language.id_language%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET COUNTRY CURSOR';
        OPEN o_country FOR
            SELECT id_country, pk_translation.get_translation(i_lang, code_country) country
              FROM country
             WHERE flg_available = pk_alert_constant.g_yes
             ORDER BY country;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_country);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_DISPOSITION',
                                   'GET_COUNTRY_LIST');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_country_list;

END pk_backoffice_disposition;
/
