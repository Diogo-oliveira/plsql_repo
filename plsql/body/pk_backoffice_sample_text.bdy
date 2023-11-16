/*-- Last Change Revision: $Rev: 2048103 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-20 17:35:23 +0100 (qui, 20 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_sample_text IS

    g_error VARCHAR2(2000);

    /********************************************************************************************
    * Private Procedure. Deletes Sample Text Freq record
    * 
    * @param      i_sample_text               Sample Text ID
    * @param      i_dcs                       Department Clinical Service ID
    *                      
    * @author     BM
    * @version    1.0
    * @since      2008/11/27
    ************************************************************************************************/
    PROCEDURE delete_sample_text_freq
    (
        i_sample_text IN NUMBER,
        i_dcs         IN NUMBER
    ) IS
    BEGIN
        DELETE FROM sample_text_freq stf
         WHERE stf.id_dep_clin_serv = i_dcs
           AND stf.id_sample_text = i_sample_text;
    END delete_sample_text_freq;

    /********************************************************************************************
    * Private Procedure. Creates Sample Text Freq record
    * 
    * @param      i_sample_text               Sample Text ID    
    * @param      i_dcs                       Department Clinical Service ID
    *                      
    * @author     BM
    * @version    1.0
    * @since      2008/11/27
    ************************************************************************************************/
    PROCEDURE create_sample_text_freq
    (
        i_sample_text IN NUMBER,
        i_dcs         IN NUMBER
    ) IS
    BEGIN
        INSERT INTO sample_text_freq
            (id_freq_sample_text, id_sample_text, id_dep_clin_serv)
        VALUES
            (seq_freq_sample_text.nextval, i_sample_text, i_dcs);
    END create_sample_text_freq;

    /********************************************************************************************
    * Private Procedure. Deletes Sample Text Type Category record
    * 
    * @param      i_sample_text_type          Sample Text ID
    * @param      i_category                  Category ID
    *                      
    * @author     BM
    * @version    1.0
    * @since      2008/11/27
    ************************************************************************************************/
    PROCEDURE delete_sample_text_type_cat
    (
        i_sample_text_type IN NUMBER,
        i_category         IN NUMBER
    ) IS
    BEGIN
        DELETE FROM sample_text_type_cat stc
         WHERE stc.id_sample_text_type = i_sample_text_type
           AND stc.id_category = i_category;
    END delete_sample_text_type_cat;

    /********************************************************************************************
    * Private Procedure. Creates Sample Text Type Category record
    * 
    * @param      i_sample_text_type          Sample Text Type ID    
    * @param      i_category                  Category ID
    * @param      i_institution               Institution ID    
    *
    * @author     BM
    * @version    1.0
    * @since      2008/11/27
    ************************************************************************************************/
    PROCEDURE create_sample_text_type_cat
    (
        i_sample_text_type IN NUMBER,
        i_category         IN NUMBER,
        i_institution      IN NUMBER
    ) IS
    BEGIN
        INSERT INTO sample_text_type_cat
            (id_sample_text_type, id_category, id_institution)
        VALUES
            ( i_sample_text_type, i_category, i_institution);
    END create_sample_text_type_cat;

    /********************************************************************************************
    * Public Function. Get Sample Text List
    *
    * @param      I_LANG                     Language identification
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type
    * @param      O_STT_LIST             Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/13
    *******************************************************************************************/
    FUNCTION get_sample_text_list
    (
        i_lang                IN language.id_language%TYPE,
        i_sample_text_type_id IN sample_text.id_sample_text_type%TYPE,
        o_stt_list            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE_TEXT_LIST CURSOR';
        OPEN o_stt_list FOR
            SELECT s.id_sample_text,
                   pk_translation.get_translation(i_lang, s.code_title_sample_text) st_title,
                   pk_translation.get_translation(i_lang, s.code_desc_sample_text) st_desc
              FROM sample_text s
             WHERE s.id_sample_text_type = i_sample_text_type_id
               AND s.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, s.code_desc_sample_text) IS NOT NULL
             ORDER BY st_title;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_text_list;

    /********************************************************************************************
    * Public Function. Get Sample Text Type List
    *
    * @param      I_LANG                     Language identification
    * @param      I_SOFTWARE                 Software
    * @param      I_SEARCH                   String to search for   
    * @param      O_STT_LIST                 Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_software IN sample_text_type.id_software%TYPE,
        i_search   IN VARCHAR2,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE_TEXT_TYPE_LIST CURSOR';
    
        OPEN o_info FOR
            SELECT s.id_sample_text_type,
                   pk_translation.get_translation(i_lang, s.code_sample_text_type) name,
                   s.intern_name_sample_text_type int_name
              FROM sample_text_type s
             WHERE s.id_software = i_software
               AND s.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, s.code_sample_text_type) IS NOT NULL
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_text_type_list;

    /********************************************************************************************
    * Public Function. Get Sample Text Details
    *
    * @param      I_LANG                     Language identification
    * @param      I_SAMPLE_TEXT_ID         Sample Text ID
    * @param      O_STT_LIST             Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/13
    *******************************************************************************************/
    FUNCTION get_sample_text_details
    (
        i_lang                IN language.id_language%TYPE,
        i_sample_text_id      IN sample_text.id_sample_text%TYPE,
        o_sample_text_details OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SAMPLE_TEXT_LIST CURSOR';
        OPEN o_sample_text_details FOR
            SELECT pk_translation.get_translation(i_lang, t.code_sample_text_type) type_desc,
                   pk_translation.get_translation(i_lang, s.code_title_sample_text) st_title,
                   s.rank,
                   pk_sysdomain.get_domain('AOL.LICENSE.FLG_STATUS', s.flg_available, i_lang) desc_status,
                   pk_translation.get_translation(i_lang, s.code_desc_sample_text) st_desc,
                   pk_sysdomain.get_domain('PROFESSIONAL.GENDER', s.gender, i_lang) desc_gender,
                   s.age_min,
                   s.age_max,
                   s.code_icd,
                   pk_translation.get_translation(i_lang, d.code_diagnosis) diagnosis_desc
              FROM sample_text s
              JOIN sample_text_type t
                ON t.id_sample_text_type = s.id_sample_text_type
              LEFT JOIN diagnosis d
                ON s.id_diagnosis = d.id_diagnosis
             WHERE s.id_sample_text = i_sample_text_id
               AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_DETAILS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_text_details;

    /********************************************************************************************
    * Public Function. Get Sample Text By DCS
    *
    * @param      I_LANG                     Language identification
    * @param      I_DCS                      Department Clinical Service ID
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type ID
    * @param      I_SEARCH                   String to search for 
    * @param      O_ST_LIST                  Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_by_dcs
    (
        i_lang                IN language.id_language%TYPE,
        i_dcs                 IN NUMBER,
        i_sample_text_type_id IN NUMBER,
        i_search              IN VARCHAR2,
        o_st_list             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET SAMPLE_TEXT_BY_DCS CURSOR';
    
        OPEN o_st_list FOR
        --Most Frequent Sample Texts
            SELECT st.id_sample_text,
                   htf.escape_sc(pk_translation.get_translation(i_lang, st.code_title_sample_text)) name,
                   pk_alert_constant.g_active flg_status
              FROM sample_text st
              JOIN sample_text_freq stf
                ON st.id_sample_text = stf.id_sample_text
             WHERE stf.id_dep_clin_serv = i_dcs
               AND st.id_sample_text_type = i_sample_text_type_id
               AND st.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, st.code_title_sample_text) IS NOT NULL
            UNION
            --Sample Text not so Frequent
            SELECT st.id_sample_text,
                   htf.escape_sc(pk_translation.get_translation(i_lang, st.code_title_sample_text)) name,
                   pk_alert_constant.g_inactive flg_status
              FROM sample_text st
             WHERE st.id_sample_text_type = i_sample_text_type_id
               AND st.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, st.code_title_sample_text) IS NOT NULL
               AND st.id_sample_text NOT IN
                   (SELECT st.id_sample_text
                      FROM sample_text st
                      JOIN sample_text_freq stf
                        ON st.id_sample_text = stf.id_sample_text
                     WHERE stf.id_dep_clin_serv = i_dcs
                       AND st.id_sample_text_type = i_sample_text_type_id
                       AND st.flg_available = pk_alert_constant.g_yes)
             ORDER BY flg_status, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_BY_DCS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_text_by_dcs;

    /********************************************************************************************
    * Public Function. Get Sample Text Type By Category
    *
    * @param      I_LANG                     Language identification
    * @param      I_INSTITUTION              Institution Identifier
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type ID
    * @param      I_SEARCH                   String to search for
    * @param      O_STT_LIST                 Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_type_by_cat
    (
        i_lang                IN language.id_language%TYPE,
        i_institution         IN NUMBER,
        i_sample_text_type_id IN NUMBER,
        i_search              IN VARCHAR2,
        o_stt_list            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET SAMPLE_TEXT_TYPE_BY_CAT CURSOR';
    
        OPEN o_stt_list FOR
        --This Sample Text Type is associated to these categories
            SELECT sttc.id_category,
                   pk_translation.get_translation(i_lang, cat.code_category) name,
                   pk_alert_constant.g_active flg_status
              FROM sample_text_type_cat sttc
              JOIN category cat
                ON sttc.id_category = cat.id_category
             WHERE sttc.id_sample_text_type = i_sample_text_type_id
               AND sttc.id_institution = i_institution
               AND cat.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, cat.code_category) IS NOT NULL
               AND cat.flg_prof = pk_alert_constant.g_yes
            UNION
            --These categories are not associated to this sample text type
            SELECT cat.id_category,
                   pk_translation.get_translation(i_lang, cat.code_category) name,
                   pk_alert_constant.g_inactive flg_status
              FROM category cat
             WHERE cat.flg_available = pk_alert_constant.g_yes
               AND cat.flg_prof = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, cat.code_category) IS NOT NULL
               AND cat.id_category NOT IN (SELECT sttc.id_category
                                             FROM sample_text_type_cat sttc
                                             JOIN category cat
                                               ON sttc.id_category = cat.id_category
                                            WHERE sttc.id_sample_text_type = i_sample_text_type_id
                                              AND sttc.id_institution = i_institution)
             ORDER BY flg_status, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_SAMPLE_TEXT_TYPE_BY_CAT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_text_type_by_cat;

    /********************************************************************************************
    * Frequent Sample Text Freq Management
    *
    * @param i_lang                  Prefered language ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_sample_text_id        Array of array of Sample Text ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @return                      true on succes, false on error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/13
    ********************************************************************************************/
    FUNCTION set_sample_text_freq
    (
        i_lang           IN language.id_language%TYPE,
        i_dep_clin_serv  IN table_number,
        i_sample_text_id IN table_table_varchar,
        i_select         IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'SET_SAMPLE_TEXT_FREQ';
    
        FOR i IN 1 .. i_dep_clin_serv.count
        LOOP
            FOR j IN 1 .. i_sample_text_id(i).count
            LOOP
            
                IF i_select(i) (j) = pk_alert_constant.g_no
                THEN
                    g_error := 'DELETE FROM SAMPLE_TEXT_FREQ';
                
                    delete_sample_text_freq(i_sample_text => to_number(i_sample_text_id(i) (j)),
                                            i_dcs         => i_dep_clin_serv(i));
                ELSE
                    g_error := 'INSERT INTO SAMPLE_TEXT_FREQ';
                
                    create_sample_text_freq(i_sample_text => to_number(i_sample_text_id(i) (j)),
                                            i_dcs         => i_dep_clin_serv(i));
                END IF;
            END LOOP;
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
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'SET_SAMPLE_TEXT_FREQ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_sample_text_freq;

    /********************************************************************************************
    * Sample Text Category management
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution identifier
    * @param i_sample_text_type_id   Array of Sample Text Type ID's
    * @param i_category_id           Array of array of Category ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @return                      true on succes, false on error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/17
    ********************************************************************************************/
    FUNCTION set_sample_text_cat
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_sample_text_type_id IN table_number,
        i_category_id         IN table_table_number,
        i_select              IN table_table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'SET_SAMPLE_TEXT_CAT';
    
        FOR i IN 1 .. i_sample_text_type_id.count
        LOOP
            FOR j IN 1 .. i_category_id(i).count
            LOOP
            
                IF i_select(i) (j) = pk_alert_constant.g_no
                THEN
                    g_error := 'DELETE FROM SAMPLE_TEXT_TYPE_CAT';
                
                    delete_sample_text_type_cat(i_sample_text_type => i_sample_text_type_id(i),
                                                i_category         => i_category_id(i) (j));
                
                ELSE
                    g_error := 'INSERT INTO SAMPLE_TEXT_TYPE_CAT';
                
                    create_sample_text_type_cat(i_sample_text_type => i_sample_text_type_id(i),
                                                i_category         => i_category_id(i) (j),
                                                i_institution      => i_id_institution);
                
                END IF;
            END LOOP;
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
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'SET_SAMPLE_TEXT_CAT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_sample_text_cat;

    /********************************************************************************************
    * Public Function. Get Software's Sample Text List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      I_ID_DEPT                    Identificação do Departamento
    * @param      I_ID_INSTITUTION             Identificação da Instituição
    * @param      O_DCS_LIST                   Cursor com a Informação da Listagem dos serviços
    * @param      O_ERROR                      Erro
    *
    * @return     boolean                      
    * @author     BM
    * @version    1.0
    * @since      2008/11/18
    ************************************************************************************************/
    FUNCTION get_dept_dcs_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        o_dcs_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET SERVICE_LIST CURSOR';
        OPEN o_dcs_list FOR
            SELECT dcs.id_dep_clin_serv,
                   s.id_department,
                   pk_translation.get_translation(i_lang, s.code_department) service_name,
                   cs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_name,
                   (SELECT COUNT(stf.id_sample_text)
                      FROM sample_text_freq stf
                      JOIN sample_text st
                        ON stf.id_sample_text = st.id_sample_text
                      JOIN sample_text_type stt
                        ON st.id_sample_text_type = stt.id_sample_text_type
                     WHERE stf.id_dep_clin_serv = dcs.id_dep_clin_serv
                       AND st.flg_available = pk_alert_constant.g_yes
                       AND stt.flg_available = pk_alert_constant.g_yes) assoc_number,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T160') assoc_label
              FROM dep_clin_serv dcs
              JOIN department s
                ON s.id_department = dcs.id_department
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE s.id_dept = i_id_dept
               AND s.id_institution = i_id_institution
             ORDER BY service_name, spec_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SAMPLE_TEXT',
                                              'GET_DEPT_DCS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_dept_dcs_list;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_sample_text;
/
