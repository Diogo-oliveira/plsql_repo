/*-- Last Change Revision: $Rev: 2027536 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:31 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_prof_utils IS

    k_no  CONSTANT VARCHAR2(0001 CHAR) := 'N';
    k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';

    k_get_nick        CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_NICK_NAME';
    k_get_name        CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_PROF_NAME';
    k_get_name_arabic CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_PROF_NAME_ARABIC';
    k_get_title       CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_PROF_TITLE';
    k_get_num_order   CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_NUM_ORDER';
    k_get_dea         CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_DEA';
    k_get_upin        CONSTANT VARCHAR2(0050 CHAR) := 'MODE_GET_UPIN';

    k_cat_flg_type CONSTANT VARCHAR2(0050 CHAR) := 'MODE_CAT_FLG_TYPE';
    k_cat_desc     CONSTANT VARCHAR2(0050 CHAR) := 'MODE_CAT_DESC';
    k_cat_id       CONSTANT VARCHAR2(0050 CHAR) := 'MODE_CAT_ID';

    k_proc_specialty_id      CONSTANT VARCHAR2(0100 CHAR) := 'MODE_SPECIALTY_ID';
    k_proc_specialty_desc    CONSTANT VARCHAR2(0100 CHAR) := 'MODE_SPECIALTY_DESC';
    k_proc_specialty_content CONSTANT VARCHAR2(0100 CHAR) := 'MODE_SPECIALTY_CONTENT';

    k_reg_prof_dcs_desc CONSTANT VARCHAR2(0050 CHAR) := 'MODE_REG_PROF_DCS_DESC';
    k_reg_prof_dcs_id   CONSTANT VARCHAR2(0050 CHAR) := 'MODE_REG_PROF_DCS_ID';

    CURSOR r_prf(i_prof_id IN NUMBER) IS
        SELECT *
          FROM professional p
         WHERE p.id_professional = i_prof_id;
    TYPE typ_tbl_prf IS TABLE OF r_prf%ROWTYPE;

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    FUNCTION return_row_n(i_tbl IN table_number) RETURN NUMBER IS
        l_return NUMBER(24);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        END IF;
    
        RETURN l_return;
    
    END return_row_n;

    FUNCTION return_row_v
    (
        i_tbl  IN table_varchar,
        i_else IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        ELSE
        
            IF i_else IS NOT NULL
            THEN
                l_return := i_else;
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END return_row_v;

    PROCEDURE log_debug
    (
        i_func_name IN VARCHAR2,
        i_text      IN VARCHAR2
    ) IS
    BEGIN
    
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    
    END log_debug;

    PROCEDURE process_error
    (
        i_lang     IN NUMBER,
        i_sqlcode  IN NUMBER,
        i_sqlerrm  IN VARCHAR2,
        i_message  IN VARCHAR2,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) IS
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => i_sqlcode,
                                          i_sqlerrm  => i_sqlerrm,
                                          i_message  => i_message,
                                          i_owner    => g_pk_owner,
                                          i_package  => g_package_name,
                                          i_function => i_function,
                                          o_error    => o_error);
    END process_error;

    /*******************************************************************************************************************************************
    * Returns an array of names corresponding to the given array of professional IDs (ignoring repeated entries)
    *                                                                                                                                          *    
    * @param I_LANG                   language identifier                                                                                      *
    * @param I_ID_PROF                array of professional IDs                                                                                *
    *                                                                                                                                          *
    * @return                         Array of Professional Names                                                                            *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Luís Ramos                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_names
    (
        i_lang      IN language.id_language%TYPE,
        i_prof_id   IN table_number,
        o_prof_name OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_NAMES';
        SELECT name
          BULK COLLECT
          INTO o_prof_name
          FROM professional
         WHERE id_professional IN (SELECT column_value
                                     FROM TABLE(CAST(i_prof_id AS table_number)));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => SQLERRM,
                          i_function => 'GET_NAMES',
                          o_error    => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_names;

    /*******************************************************************************************************************************************
    *GET_MAIN_PROF Returns the professional nick name responsible for the episode (only for oris software)                                                             *
    *                                                                                                                                          *
    * @param I_LANG                   language identifier                                                                                      *
    * @param I_EPISODE                episode identifier                                                                                       *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Nick name of the professional                                                                            *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/08/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_main_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(200 CHAR);
        --tbl_epis_type table_number;
        tbl_name table_varchar;
    
    BEGIN
    
        SELECT get_name_signature(i_lang, i_prof, s.id_professional)
          BULK COLLECT
          INTO tbl_name
          FROM episode e
          LEFT JOIN sr_prof_team_det s
            ON e.id_episode = s.id_episode
         WHERE e.id_epis_type = g_oris
           AND s.id_category_sub = g_catg_surg_resp
           AND s.flg_status != g_cancel
           AND e.id_episode = i_episode;
    
        l_return := return_row_v(i_tbl => tbl_name);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_main_prof;

    /**
    * Get the professional information
    *
    * @param i_prof_id     professional id
    *
    * @return the professional record
    * @created Jan-2015
    * @author Carlos Ferreira
    */
    FUNCTION get_professional_record(i_prof_id IN NUMBER) RETURN typ_tbl_prf IS
        tbl_prf typ_tbl_prf;
    BEGIN
    
        OPEN r_prf(i_prof_id => i_prof_id);
        FETCH r_prf BULK COLLECT
            INTO tbl_prf;
        CLOSE r_prf;
    
        RETURN tbl_prf;
    
    END get_professional_record;

    FUNCTION get_profinfo_base
    (
        i_lang    IN language.id_language%TYPE,
        i_mode    IN VARCHAR2,
        i_prof_id IN professional.id_professional%TYPE -- input professional id
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        tbl_prf  typ_tbl_prf := typ_tbl_prf();
    BEGIN
    
        tbl_prf := get_professional_record(i_prof_id => i_prof_id);
    
        <<lup_thru_professional>>
        FOR i IN 1 .. tbl_prf.count
        LOOP
        
            CASE i_mode
                WHEN k_get_nick THEN
                    l_return := tbl_prf(i).nick_name;
                WHEN k_get_name THEN
                    l_return := tbl_prf(i).name;
                WHEN k_get_title THEN
                    l_return := tbl_prf(i).title;
                WHEN k_get_num_order THEN
                    l_return := tbl_prf(i).num_order;
                WHEN k_get_dea THEN
                    l_return := tbl_prf(i).dea;
                WHEN k_get_upin THEN
                    l_return := tbl_prf(i).upin;
                WHEN k_get_name_arabic THEN
                    l_return := tbl_prf(i).first_name_sa || ' ' || tbl_prf(i).parent_name_sa || ' ' || tbl_prf(i).middle_name_sa || ' ' || tbl_prf(i).last_name_sa;
            END CASE;
        
            -- only one iteration
            EXIT lup_thru_professional;
        
        END LOOP lup_thru_professional;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_profinfo_base;

    /**
    * Get the professional nickname
    *
    * @param i_lang        language
    * @param i_prof_id     professional id
    *
    * @return the professional nickname 
    * @created 17-Apr-2008
    * @author Sérgio Santos
    */
    FUNCTION get_nickname
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE -- input professional id
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_profinfo_base(i_lang => i_lang, i_mode => k_get_nick, i_prof_id => i_prof_id);
    
    END get_nickname;

    /**
    * Return the name's professional
    *
    * @param   i_lang             language
    * @param   i_prof_id          professional id
    *
    * @author  Nuno Ferreira
    * @version 2.4.3
    * @since   2008/08/21
    */
    FUNCTION get_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_profinfo_base(i_lang => i_lang, i_mode => k_get_name, i_prof_id => i_prof_id);
    
    END get_name;

    /********************************************************************************************
    * Get category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  category of active professional
    * @author  José Silva
    * @version 1.0
    * @since   22/04/2008
    *
    **********************************************************************************************/
    FUNCTION get_category_base
    (
        i_mode        IN VARCHAR2,
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(1000 CHAR);
        tbl_cat  table_varchar;
        tbl_desc table_varchar;
        tbl_id   table_varchar;
    BEGIN
    
        SELECT cat.flg_type, pk_translation.get_translation(i_lang, cat.code_category) desc_cat, cat.id_category
          BULK COLLECT
          INTO tbl_cat, tbl_desc, tbl_id
          FROM prof_cat prc
          JOIN category cat
            ON cat.id_category = prc.id_category
          JOIN professional prf
            ON prc.id_professional = prf.id_professional
         WHERE prf.id_professional = i_prof_id
           AND prc.id_institution = i_institution;
    
        CASE i_mode
            WHEN k_cat_flg_type THEN
                l_return := return_row_v(i_tbl => tbl_cat);
            WHEN k_cat_desc THEN
                l_return := return_row_v(i_tbl => tbl_desc);
            WHEN k_cat_id THEN
                l_return := return_row_v(i_tbl => tbl_id);
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_category_base;

    FUNCTION get_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        --l_cat   category.flg_type%TYPE;
        --tbl_cat table_varchar;
    BEGIN
    
        RETURN get_category_base(i_mode        => k_cat_flg_type,
                                 i_lang        => i_lang,
                                 i_prof_id     => i_prof.id,
                                 i_institution => i_prof.institution);
    
    END get_category;

    /********************************************************************************************
    * Get category of active professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_inst                 Institution where professional made the record
    *
    * @RETURN  category of active professional
    * @author  Jorge Silva
    * @version 1.0
    * @since   13/02/2014
    *
    **********************************************************************************************/
    FUNCTION get_category
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_category_base(i_mode        => k_cat_flg_type,
                                 i_lang        => i_lang,
                                 i_prof_id     => i_prof_id,
                                 i_institution => i_prof_inst);
    
    END get_category;

    /********************************************************************************************
    * Get category description of given professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_inst                 Institution where professional made the record
    * @return                            Category description
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    **********************************************************************************************/
    FUNCTION get_desc_category
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
        
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_category_base(i_mode        => k_cat_desc,
                                 i_lang        => i_lang,
                                 i_prof_id     => i_prof_id,
                                 i_institution => i_prof_inst);
    
    END get_desc_category;

    /********************************************************************************************
    * Get id_category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  category of active professional
    * @author  José Silva
    * @version 1.0
    * @since   22/04/2008
    *
    **********************************************************************************************/
    FUNCTION get_id_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN get_category_base(i_mode        => k_cat_id,
                                 i_lang        => i_lang,
                                 i_prof_id     => i_prof.id,
                                 i_institution => i_prof.institution);
    
    END get_id_category;

    /********************************************************************************************
    * Get the selected dep_clin_serv of a given professional
    *
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional dep_clin_serv (ID)
    * @author  José Silva
    * @version 1.0
    * @since   18/05/2008
    *
    **********************************************************************************************/
    FUNCTION get_prof_dcs(i_prof IN profissional) RETURN NUMBER IS
        l_id_dcs dep_clin_serv.id_dep_clin_serv%TYPE;
        tbl_dcs  table_number;
    BEGIN
    
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO tbl_dcs
          FROM dep_clin_serv dcs
          JOIN department dpt
            ON dpt.id_department = dcs.id_department
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN software_dept sdt
            ON sdt.id_dept = dpt.id_dept
         WHERE pdcs.flg_default = g_dcs_default
           AND sdt.id_software = i_prof.software
           AND pdcs.flg_status = g_dcs_selected
           AND pdcs.id_professional = i_prof.id
           AND dpt.id_institution = i_prof.institution
         ORDER BY dcs.id_department;
    
        l_id_dcs := return_row_n(i_tbl => tbl_dcs);
    
        RETURN l_id_dcs;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_dcs;

    /**********************************************************************************************
    * GET_PROF_MARKET                 Returns professional market
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         professional market identifier
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.5 
    * @since                          12-Feb-2011
    **********************************************************************************************/
    FUNCTION get_prof_market(i_prof IN profissional) RETURN NUMBER IS
        l_id_market market.id_market%TYPE;
    BEGIN
        -- old code was wrong ( prof dont have markets, institution have )..
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        RETURN l_id_market;
    END get_prof_market;

    /********************************************************************************************
    * Get the selected dep_clin_serv of a given professional (description)
    *
    * @param   I_LANG  language ID
    * @param   I_PROF  professional, institution and software ids                
    *
    * @RETURN  professional dep_clin_serv (description)
    *
    * @author  José Silva
    * @version 1.0
    * @since   26/02/2009
    **********************************************************************************************/
    FUNCTION get_desc_prof_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_spec   VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          BULK COLLECT
          INTO tbl_desc
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
          JOIN department dpt
            ON dpt.id_department = dcs.id_department
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN software_dept sdt
            ON sdt.id_dept = dpt.id_dept
         WHERE pdcs.flg_default = g_dcs_default
           AND sdt.id_software = i_prof.software
           AND dpt.id_institution = i_prof.institution
           AND pdcs.flg_status = g_dcs_selected
           AND pdcs.id_professional = i_prof.id
         ORDER BY dcs.id_department;
    
        l_spec := return_row_v(i_tbl => tbl_desc);
    
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_prof_dcs;

    FUNCTION add_some_time(i_dt_reg IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
    
        RETURN(i_dt_reg + numtodsinterval(4, 'SECOND'));
    
    END add_some_time;

    /********************************************************************************************
    * Gets the selected dep_clin_serv of a given professional (description) when he made a record
    *
    * @param   I_LANG  language ID
    * @param   I_PROF professional, institution and software ids        
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID        
    *
    * @RETURN  professional dep_clin_serv (ID)
    * @author  José Silva
    * @version 1.0
    * @since   18/05/2008
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_dcs_base
    (
        i_mode    IN VARCHAR2,
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_reg TIMESTAMP WITH LOCAL TIME ZONE;
    
        tbl_desc table_varchar;
        tbl_dcs  table_varchar;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        -- remove small differences
        l_dt_reg := add_some_time(i_dt_reg);
    
        SELECT dcs.id_dep_clin_serv,
               decode(i_lang, 0, NULL, pk_translation.get_translation(i_lang, cs.code_clinical_service))
          BULK COLLECT
          INTO tbl_dcs, tbl_desc
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
          JOIN epis_prof_dcs edcs
            ON edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
         WHERE edcs.id_professional = i_prof_id
           AND edcs.id_episode = i_episode
           AND edcs.dt_reg < l_dt_reg
         ORDER BY edcs.dt_reg DESC;
    
        CASE i_mode
            WHEN k_reg_prof_dcs_desc THEN
                l_return := return_row_v(i_tbl => tbl_desc);
            WHEN k_reg_prof_dcs_id THEN
                l_return := return_row_v(i_tbl => tbl_dcs);
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_reg_prof_dcs_base;

    FUNCTION get_reg_prof_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN get_reg_prof_dcs_base(i_mode    => k_reg_prof_dcs_desc,
                                     i_lang    => i_lang,
                                     i_prof_id => i_prof_id,
                                     i_dt_reg  => i_dt_reg,
                                     i_episode => i_episode);
    
    END get_reg_prof_dcs;

    /********************************************************************************************
    * Gets the selected dep_clin_serv of a given professional (ID) when he made a record
    *
    * @param   I_LANG  language ID
    * @param   I_PROF professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional id_dep_clin_serv
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_id_dcs
    (
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
    
        k_no_lang CONSTANT NUMBER(24) := 0;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        l_return := get_reg_prof_dcs_base(i_mode    => k_reg_prof_dcs_id,
                                          i_lang    => k_no_lang,
                                          i_prof_id => i_prof_id,
                                          i_dt_reg  => i_dt_reg,
                                          i_episode => i_episode);
    
        RETURN to_number(l_return);
    
    END get_reg_prof_id_dcs;

    /********************************************************************************************
    * Gets the selected dep_clin_serv of a given professional (description) when he made a record
    *
    * @param   I_LANG  language ID
    * @param   I_PROF professional, institution and software ids        
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID        
    *
    * @RETURN  professional dep_clin_serv (ID)
    * @author  Sofia Mendes
    * @version 2.6.0.1
    * @since   30/04/2010
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_dcs_visit
    (
        i_lang     IN language.id_language%TYPE,
        i_prof_id  IN professional.id_professional%TYPE,
        i_dt_reg   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_visit IN visit.id_visit%TYPE
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_spec   VARCHAR2(4000);
        l_dt_reg TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        -- remove small differences
        l_dt_reg := add_some_time(i_dt_reg);
    
        SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
          BULK COLLECT
          INTO tbl_desc
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
          JOIN epis_prof_dcs edcs
            ON edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN episode e
            ON e.id_episode = edcs.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE edcs.id_professional = i_prof_id
           AND e.id_visit = i_id_visit
           AND edcs.dt_reg < l_dt_reg
         ORDER BY edcs.dt_reg DESC;
    
        l_spec := return_row_v(i_tbl => tbl_desc);
    
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_reg_prof_dcs_visit;

    /********************************************************************************************
    * Get the active speciality of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   18/05/2008
    *
    **********************************************************************************************/
    FUNCTION get_prof_speciality_base
    (
        i_mode IN VARCHAR2,
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return    VARCHAR2(4000);
        tbl_desc    table_varchar;
        tbl_id      table_varchar;
        tbl_content table_varchar;
    BEGIN
    
        SELECT p.id_speciality, pk_translation.get_translation(i_lang, sp.code_speciality), sp.id_content
          BULK COLLECT
          INTO tbl_id, tbl_desc, tbl_content
          FROM speciality sp
          JOIN professional p
            ON sp.id_speciality = p.id_speciality
         WHERE p.id_professional = i_prof.id;
    
        CASE i_mode
            WHEN k_proc_specialty_id THEN
                l_return := return_row_v(i_tbl => tbl_id);
            WHEN k_proc_specialty_desc THEN
                l_return := return_row_v(i_tbl => tbl_desc);
            WHEN k_proc_specialty_content THEN
                l_return := return_row_v(i_tbl => tbl_content);
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_speciality_base;

    FUNCTION get_prof_speciality
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_prof_speciality_base(i_mode => k_proc_specialty_desc, i_lang => i_lang, i_prof => i_prof);
    
    END get_prof_speciality;

    /*
    * Get the active speciality of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional speciality id
    * @author  Alexandre Santos
    * @version v2.6
    * @since   09/12/2009
    *
    */
    FUNCTION get_prof_speciality_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN speciality.id_speciality%TYPE IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := get_prof_speciality_base(i_mode => k_proc_specialty_id, i_lang => i_lang, i_prof => i_prof);
    
        RETURN to_number(l_return);
    
    END get_prof_speciality_id;

    FUNCTION get_prof_speciality_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_prof_speciality_base(i_mode => k_proc_specialty_content, i_lang => i_lang, i_prof => i_prof);
    
    END get_prof_speciality_content;
    /********************************************************************************************
    * Returns the professional name to place in the documentation records
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    *
    * @author  José Silva
    * @version 2.5
    * @since   2009/02/26
    **********************************************************************************************/
    FUNCTION get_name_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    
        l_prof_signature     professional.name%TYPE;
        l_config_prof_name   sys_config.value%TYPE;
        l_config_name_format sys_config.value%TYPE;
    
        l_prof_name         professional.name%TYPE;
        l_prof_title        professional.title%TYPE;
        l_prof_order_number professional.num_order%TYPE;
    
        --        l_cfg_show_mec_number CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_MEC_NUMBER';
        l_show_mec_number   sys_config.value%TYPE;
        l_show_order_number sys_config.value%TYPE;
        l_mec_number        prof_institution.num_mecan%TYPE;
    BEGIN
    
        l_config_prof_name  := pk_sysconfig.get_config('SHOW_PROF_FULL_NAME', i_prof);
        l_show_mec_number   := pk_sysconfig.get_config('SHOW_MEC_NUMBER', i_prof);
        l_show_order_number := pk_sysconfig.get_config('SHOW_ORDER_NUMBER', i_prof);
    
        l_prof_name  := get_profinfo_base(i_lang => i_lang, i_mode => k_get_name, i_prof_id => i_prof_id);
        l_prof_title := get_profinfo_base(i_lang => i_lang, i_mode => k_get_title, i_prof_id => i_prof_id);
    
        IF l_config_prof_name = k_yes
        THEN
            IF l_prof_title IS NOT NULL
            THEN
                l_config_name_format := pk_sysconfig.get_config('FORMAT_PROF_NAME', i_prof);
            
                l_prof_signature := REPLACE(l_config_name_format,
                                            '@T',
                                            pk_backoffice.get_prof_title_desc(i_lang, l_prof_title));
                l_prof_signature := REPLACE(l_prof_signature, '@N', l_prof_name);
            ELSE
                l_prof_signature := l_prof_name;
            END IF;
        
        ELSE
            l_prof_signature := get_nickname(i_lang, i_prof_id);
        END IF;
    
        IF (l_show_order_number = k_yes AND l_prof_signature IS NOT NULL)
        THEN
            l_prof_order_number := get_profinfo_base(i_lang    => i_lang,
                                                     i_mode    => k_get_num_order,
                                                     i_prof_id => i_prof_id);
            IF nvl(length(l_prof_order_number), 0) != 0
            THEN
                l_prof_signature := l_prof_signature || '; ' ||
                                    pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'COMMON_M157') || ' ' || l_prof_order_number;
            END IF;
        END IF;
    
        IF l_show_mec_number = k_yes
           AND l_prof_signature IS NOT NULL
        THEN
            l_mec_number := get_prof_inst_mec_num(i_lang => i_lang, i_prof => i_prof);
        
            IF nvl(length(l_mec_number), 0) != 0
            THEN
                l_prof_signature := l_prof_signature || ' (' || l_mec_number || ')';
            END IF;
        END IF;
    
        RETURN l_prof_signature;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_name_signature;

    /********************************************************************************************
    * Gets the speciality of a given professional within a certain date
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   26/02/2009
    **********************************************************************************************/
    FUNCTION get_spec_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_spec VARCHAR2(200);
        l_spec_p CONSTANT sys_config.value%TYPE := 'P';
        l_spec_s CONSTANT sys_config.value%TYPE := 'S';
        l_config_spec sys_config.value%TYPE;
    
        l_id_institution institution.id_institution%TYPE;
        l_software       software.id_software%TYPE;
        l_prof           profissional; -- user to get specialty from
    BEGIN
        -- get episode's institution and software
        l_id_institution := i_prof.institution;
        l_software       := i_prof.software;
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_institution, ei.id_software
              INTO l_id_institution, l_software
              FROM episode e
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_episode = i_episode;
        END IF;
    
        l_prof := profissional(i_prof_id, l_id_institution, l_software);
    
        --the administrative don't have speciality in signature
        IF get_category(i_lang => i_lang, i_prof => l_prof) != pk_alert_constant.g_cat_type_registrar
        THEN
            l_config_spec := pk_sysconfig.get_config('SHOW_PROF_SPEC', i_prof);
        
            IF l_config_spec = l_spec_p
            THEN
                IF i_dt_reg IS NOT NULL
                   AND i_episode IS NOT NULL
                THEN
                    l_spec := get_reg_prof_dcs(i_lang, i_prof_id, i_dt_reg, i_episode);
                
                    IF l_spec IS NULL
                    THEN
                        l_spec := get_desc_prof_dcs(i_lang, l_prof);
                    END IF;
                ELSE
                    l_spec := get_desc_prof_dcs(i_lang, l_prof);
                END IF;
            END IF;
        
            IF l_config_spec = l_spec_s
               OR l_spec IS NULL
            THEN
                l_spec := get_prof_speciality(i_lang, l_prof);
            END IF;
        
        END IF;
    
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_spec_signature;

    /********************************************************************************************
    * Gets the speciality of a given professional within a certain date associated to a given visit
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Sofia Mendes
    * @version 2.6.0.1
    * @since   30/04/2010
    **********************************************************************************************/
    FUNCTION get_spec_sign_by_visit
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_id  IN professional.id_professional%TYPE,
        i_dt_reg   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_visit IN visit.id_visit%TYPE
    ) RETURN VARCHAR2 IS
    
        l_spec VARCHAR2(200);
        l_spec_p CONSTANT sys_config.value%TYPE := 'P';
        l_spec_s CONSTANT sys_config.value%TYPE := 'S';
        l_config_spec sys_config.value%TYPE;
    
        l_id_institution institution.id_institution%TYPE;
    
    BEGIN
    
        l_config_spec := pk_sysconfig.get_config('SHOW_PROF_SPEC', i_prof);
    
        IF i_id_visit IS NOT NULL
        THEN
            SELECT e.id_institution
              INTO l_id_institution
              FROM visit e
             WHERE e.id_visit = i_id_visit;
        ELSE
            l_id_institution := i_prof.institution;
        END IF;
    
        IF l_config_spec = l_spec_p
        THEN
            IF i_dt_reg IS NOT NULL
               AND i_id_visit IS NOT NULL
            THEN
                l_spec := get_reg_prof_dcs_visit(i_lang, i_prof_id, i_dt_reg, i_id_visit);
            
                IF l_spec IS NULL
                THEN
                    l_spec := get_desc_prof_dcs(i_lang, profissional(i_prof_id, l_id_institution, i_prof.software));
                END IF;
            ELSE
                l_spec := get_desc_prof_dcs(i_lang, profissional(i_prof_id, l_id_institution, i_prof.software));
            END IF;
        END IF;
    
        IF l_config_spec = l_spec_s
           OR l_spec IS NULL
        THEN
            l_spec := get_prof_speciality(i_lang, profissional(i_prof_id, i_prof.institution, i_prof.software));
        END IF;
    
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_spec_sign_by_visit;

    /********************************************************************************************
    * Gets the speciality of a given professional (to be used in P1)
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   18/03/2009
    **********************************************************************************************/
    FUNCTION get_spec_signature
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
    
        l_spec VARCHAR2(200);
        l_spec_p CONSTANT sys_config.value%TYPE := 'P';
        l_spec_s CONSTANT sys_config.value%TYPE := 'S';
        l_config_spec sys_config.value%TYPE;
    
    BEGIN
    
        --the administrative don't have speciality in signature
        IF get_category(i_lang => i_lang, i_prof => profissional(i_prof_id, i_prof_inst, i_prof.software)) !=
           pk_alert_constant.g_cat_type_registrar
        THEN
            l_config_spec := pk_sysconfig.get_config('SHOW_PROF_SPEC', i_prof);
        
            IF l_config_spec = l_spec_p
            THEN
                l_spec := get_desc_prof_dcs(i_lang, profissional(i_prof_id, i_prof_inst, i_prof.software));
            END IF;
        
            IF l_config_spec = l_spec_s
               OR l_spec IS NULL
            THEN
                l_spec := get_prof_speciality(i_lang, profissional(i_prof_id, i_prof_inst, i_prof.software));
            END IF;
        END IF;
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_spec_signature;

    /**********************************************************************************************
    * Return professional's PROFILE_TEMPLATE within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         ID_PROFILE_TEMPLATE from PROFILE_TEMPLATE table
    *                        
    * @author                         Sérgio Santos
    * @version                        1.0 
    * @since                          2009/06/18
    **********************************************************************************************/
    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN profile_template.id_profile_template%TYPE IS
    BEGIN
        RETURN pk_tools.get_prof_profile_template(i_prof => i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_profile_template;

    /********************************************************************************************
    * Returns an array with all softwares that are being used by the professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_institution             current institution ID
    *
    *
    * @author                          José Silva
    * @version                         2.5.1.9
    * @since                           2011/11/10
    **********************************************************************************************/
    FUNCTION get_prof_softwares
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_number IS
        l_prof_softwares table_number;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'GET PROF SOFTWARES';
        SELECT ppt.id_software
          BULK COLLECT
          INTO l_prof_softwares
          FROM prof_profile_template ppt
          JOIN profile_template pt
            ON ppt.id_profile_template = pt.id_profile_template
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_institution
           AND ppt.id_software = pt.id_software
           AND pt.flg_available = pk_alert_constant.g_available;
    
        RETURN l_prof_softwares;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_PROF_SOFTWARES',
                          o_error    => l_error);
            RETURN NULL;
    END get_prof_softwares;

    /**********************************************************************************************
    * Retorna o numero da ordem do profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_num_order              numero da ordem do profissional pretendido
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/

    FUNCTION get_num_order
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        o_num_order OUT professional.num_order%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_num_order := get_profinfo_base(i_lang => i_lang, i_mode => k_get_num_order, i_prof_id => i_prof_id);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => SQLERRM,
                          i_function => 'GET_NUM_ORDER',
                          o_error    => o_error);
            RETURN FALSE;
    END get_num_order;

    /**
    * Sets the professional profile_template (without commit)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_new_pt             New profile_template
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION set_prof_profile_template_nc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_new_pt IN profile_template.id_profile_template%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_PROF_PROFILE_TEMPLATE_NC';
    
        l_prof_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    BEGIN
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_prof IS NULL
           OR i_lang IS NULL
           OR i_new_pt IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- update the profile_template of the given professional
        g_error := 'UPDATE PROF_PROFILE_TEMPLATE';
        UPDATE prof_profile_template ppt
           SET ppt.id_profile_template = i_new_pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_profile_template = l_prof_profile_template;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_prof_profile_template_nc;

    /**********************************************************************************************
    * Get PROFESSIONAL DEA info
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_dea                  DEA info
    * @param o_error                  Error message
    *
    * @author                         Pedro Albuquerque
    * @version                        1.0 
    * @since                          2010/05/06
    **********************************************************************************************/

    FUNCTION get_dea
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        o_dea     OUT professional.dea%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_DEA';
        --l_dea       professional.dea%TYPE;
        --l_return    BOOLEAN := TRUE;
    BEGIN
    
        g_error := l_func_name || ' -> get dea info';
        o_dea   := get_profinfo_base(i_lang => i_lang, i_mode => k_get_dea, i_prof_id => i_prof_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => l_func_name,
                          o_error    => o_error);
            RETURN FALSE;
    END get_dea;

    /**********************************************************************************************
    * Get PROFESSIONAL UPIN info
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_upin                 UPIN info
    * @param o_error                  Error message
    *
    * @author                         Pedro Albuquerque
    * @version                        1.0 
    * @since                          2010/05/06
    **********************************************************************************************/

    FUNCTION get_upin
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        o_upin    OUT professional.upin%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_UPIN';
    BEGIN
    
        o_upin := get_profinfo_base(i_lang => i_lang, i_mode => k_get_upin, i_prof_id => i_prof_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => l_func_name,
                          o_error    => o_error);
        
            RETURN FALSE;
    END get_upin;

    /**************************************************************************
    * Retorna se um determinado profissional não é um profissional externo ou *
    * de teste da aplicação.                                                  *
    *                                                                         *
    * @param i_lang                the id language                            *
    * @param i_prof                professional, software and institution ids *
    * @param i_prof_id             profissional que queremos validar          *      
    * @param i_institution_id      instituição sujeita a validação            *
    *                                                                         *
    * @author                      Gustavo Serrano                            *
    * @version                     1.0                                        *
    * @since                       2009/12/16                                 *
    **************************************************************************/
    FUNCTION is_internal_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_id        IN professional.id_professional%TYPE,
        i_institution_id IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_aux   NUMBER(1) := 0;
        l_error t_error_out;
        internal_exception EXCEPTION;
        l_return VARCHAR2(0050 CHAR);
    BEGIN
        g_error := 'Validate internal profissional';
        SELECT COUNT(*)
          INTO l_aux
          FROM professional p
          JOIN prof_institution pi
            ON pi.id_professional = p.id_professional
         WHERE p.id_professional = i_prof_id
           AND pi.id_institution = i_institution_id
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_external = k_no
           AND (p.flg_prof_test = k_no OR p.flg_prof_test IS NULL);
    
        l_return := k_no;
        IF l_aux > 0
        THEN
            l_return := k_yes;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'IS_INTERNAL_PROF',
                          o_error    => l_error);
            RAISE internal_exception;
    END is_internal_prof;
    --
    /*
    * Get the clinical service of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional clinical service id
    * @author  Alexandre Santos
    * @version v2.6
    * @since   19/02/2009
    *
    */
    FUNCTION get_prof_clin_serv_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN clinical_service.id_clinical_service%TYPE IS
        l_prof_clin_serv clinical_service.id_clinical_service%TYPE;
        tbl_cls          table_number;
    BEGIN
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO tbl_cls --l_prof_clin_serv
          FROM dep_clin_serv dcs
          JOIN clinical_service cli
            ON cli.id_clinical_service = dcs.id_clinical_service
          JOIN department dpt
            ON dpt.id_department = dcs.id_department
          JOIN prof_dep_clin_serv pdc
            ON pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN software_dept sdt
            ON sdt.id_dept = dpt.id_dept
         WHERE pdc.id_professional = i_prof.id
           AND pdc.flg_default = g_dcs_default
           AND pdc.flg_status = g_dcs_selected
           AND dcs.flg_available = pk_alert_constant.g_yes
           AND cli.flg_available = pk_alert_constant.g_yes
           AND sdt.id_software = i_prof.software
           AND dpt.id_institution = i_prof.institution;
    
        l_prof_clin_serv := return_row_n(tbl_cls);
    
        RETURN l_prof_clin_serv;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_clin_serv_id;
    --
    /*
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    *
    * @RETURN  Return the clinical services list to which the current professional is allocated
    * @author  Alexandre Santos
    * @version 1.0
    * @since   02-03-2010
    *
    */
    FUNCTION tf_prof_clin_serv_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_table_prof_clin_serv IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_PROF_CLIN_SERV_LIST';
        --
        l_tbl t_table_prof_clin_serv;
    BEGIN
        --Get list of values of the list group
        g_error := 'FILL SYS_LIST TABLE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t_rec_prof_clin_serv(t.id_clinical_service,
                                    t.desc_clin_serv,
                                    (SELECT decode(COUNT(*), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
                                       FROM prof_dep_clin_serv pdc2
                                       JOIN dep_clin_serv dcs2
                                         ON pdc2.id_dep_clin_serv = dcs2.id_dep_clin_serv
                                       JOIN department dpt2
                                         ON dpt2.id_department = dcs2.id_department
                                       JOIN software_dept sdt2
                                         ON sdt2.id_dept = dpt2.id_dept
                                      WHERE pdc2.id_professional = i_prof.id
                                        AND dcs2.id_clinical_service = t.id_clinical_service
                                        AND pdc2.flg_status = pk_tools.g_status_pdcs_s
                                        AND pdc2.flg_default = pk_alert_constant.g_yes
                                        AND sdt2.id_software = i_prof.software),
                                    t.rank)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT DISTINCT cli.id_clinical_service,
                                pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_clin_serv,
                                cli.rank
                  FROM dep_clin_serv dcs
                  JOIN clinical_service cli
                    ON cli.id_clinical_service = dcs.id_clinical_service
                  JOIN prof_dep_clin_serv pdc
                    ON pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                  JOIN department dpt
                    ON dpt.id_department = dcs.id_department
                 WHERE pdc.id_professional = i_prof.id
                   AND pdc.flg_status = pk_tools.g_status_pdcs_s
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND cli.flg_available = pk_alert_constant.g_yes
                   AND dpt.id_institution = i_prof.institution) t
         ORDER BY t.rank, t.desc_clin_serv;
    
        RETURN l_tbl;
    END tf_prof_clin_serv_list;
    --
    /********************************************************************************************
    * get clinical flag for current professional
    *
    * @param   i_lang                  language associated to the professional executing the request
    * @param   i_prof                  professional, institution and software ids  
    *
    * @return                          clinical flag: (Y) clinical category (N) non-clinical category
    *
    * @author                          Carlos Loureiro
    * @since                           11/11/2010
    **********************************************************************************************/
    FUNCTION get_clinical_cat
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_flg_clinical category.flg_clinical%TYPE;
        tbl_flg        table_varchar;
    BEGIN
        SELECT c.flg_clinical
          BULK COLLECT
          INTO tbl_flg --l_flg_clinical
          FROM prof_cat pc
          JOIN category c
            ON c.id_category = pc.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        l_flg_clinical := return_row_v(tbl_flg, k_no);
    
        RETURN l_flg_clinical;
    
    END get_clinical_cat;

    /********************************************************************************************
    * Returns the professional signature.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param O_PROF_SIGNATURE        Professional signature    
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         15-Feb-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_name_signature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_prof_signature OUT professional.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_prof_signature := get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_prof.id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'get_name_signature',
                          o_error    => o_error);
            RETURN FALSE;
    END get_name_signature;
    --

    /********************************************************************************************
    * get_detail_signature      get the signature with specific format:
    *                           professional name (speciality) dd/mm/aaaa hh:mmh 
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, software and institution ids
    * @param i_id_episode              Episode ID
    * @param i_date_last_change        Last date changed
    * @param i_id_prof_last_change     Last prof ID changed
    *
    * Return signature format with detail conventions
    *
    * @author                          Filipe Silva
    * @version                         2.6.1.1
    * @since                           06-Jun-2011
    *
    **********************************************************************************************/
    FUNCTION get_detail_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date_last_change    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE,
        i_show_contact_info   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_date           VARCHAR2(200 CHAR);
        l_spec_signature pk_translation.t_desc_translation;
        l_prof_signature professional.name%TYPE;
        l_contact_info   VARCHAR2(4000);
    
        l_work_phone  professional.work_phone%TYPE;
        l_home_phone  professional.num_contact%TYPE;
        l_cell_phone  professional.cell_phone%TYPE;
        l_fax         professional.fax%TYPE;
        l_email       professional.email%TYPE;
        l_bleep       professional.bleep_number%TYPE;
        l_contact_det prof_institution.contact_detail%TYPE;
    
        l_bleep_lbl           sys_message.desc_message%TYPE;
        l_work_phone_lbl      sys_message.desc_message%TYPE;
        l_cell_phone_lbl      sys_message.desc_message%TYPE;
        l_bleep_lbl_code      sys_message.code_message%TYPE := 'ADMINISTRATOR_IDENT_T178';
        l_work_phone_lbl_code sys_message.code_message%TYPE := 'ADMINISTRATOR_IDENT_T117';
        l_cell_phone_lbl_code sys_message.code_message%TYPE := 'ADMINISTRATOR_IDENT_T111';
    
        l_error t_error_out;
    BEGIN
    
        g_error := 'CALL GET_NAME_SIGNATURE FUNCTION';
        pk_alertlog.log_debug(g_error);
    
        l_prof_signature := get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_id_prof_last_change);
    
        g_error := 'CALL GET_SPEC_SIGNATURE FUNCTION';
        pk_alertlog.log_debug(g_error);
        l_spec_signature := get_spec_signature(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_prof_id => i_id_prof_last_change,
                                               i_dt_reg  => i_date_last_change,
                                               i_episode => i_id_episode);
    
        IF l_spec_signature IS NOT NULL
        THEN
            l_spec_signature := g_open_parenthesis || l_spec_signature || g_close_parenthesis;
        ELSE
            l_spec_signature := g_chr_space;
        END IF;
    
        g_error := 'CALL PK_DATE_UTILS.DATE_CHAR_TSZ FUNCTION';
        pk_alertlog.log_debug(g_error);
        l_date := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                              i_date => i_date_last_change,
                                              i_inst => i_prof.institution,
                                              i_soft => i_prof.software);
    
        IF i_show_contact_info = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL PK_PROF_UTILS.GET_PROF_CONTACTS';
            IF NOT get_prof_contacts(i_lang           => i_lang,
                                     i_id_prof        => i_id_prof_last_change,
                                     i_id_institution => i_prof.institution,
                                     i_req_date       => i_date_last_change,
                                     o_work_phone     => l_work_phone,
                                     o_home_phone     => l_home_phone,
                                     o_cell_phone     => l_cell_phone,
                                     o_fax            => l_fax,
                                     o_email          => l_email,
                                     o_bleep          => l_bleep,
                                     o_contact_det    => l_contact_det,
                                     o_error          => l_error)
            THEN
                RETURN l_prof_signature || l_spec_signature || l_date;
            ELSE
                l_bleep_lbl      := pk_message.get_message(i_lang => i_lang, i_code_mess => l_bleep_lbl_code);
                l_work_phone_lbl := pk_message.get_message(i_lang => i_lang, i_code_mess => l_work_phone_lbl_code);
                l_cell_phone_lbl := pk_message.get_message(i_lang => i_lang, i_code_mess => l_cell_phone_lbl_code);
            
                IF l_bleep IS NOT NULL
                THEN
                    l_contact_info := l_bleep_lbl || g_chr_colon || g_chr_space || l_bleep || g_chr_semi_colon ||
                                      g_chr_space;
                END IF;
            
                IF l_work_phone IS NOT NULL
                THEN
                    l_contact_info := l_contact_info || l_work_phone_lbl || g_chr_colon || g_chr_space || l_work_phone ||
                                      g_chr_semi_colon || g_chr_space;
                END IF;
            
                IF l_cell_phone IS NOT NULL
                THEN
                    l_contact_info := l_contact_info || l_cell_phone_lbl || g_chr_colon || g_chr_space || l_cell_phone ||
                                      g_chr_semi_colon || g_chr_space;
                END IF;
            END IF;
        END IF;
    
        RETURN l_prof_signature || l_spec_signature || l_contact_info || l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_detail_signature;

    /********************************************************************************************
    * check_has_functionality        return if the professional has a determinate functionality (Y) or not (N)
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Internal name of sys functionality
    *
    * Return if the professional has a functionality (Y) or not (N)
    *
    * @author                          Filipe Silva
    * @version                         2.6.1.1
    * @since                           02-Jun-2011
    *
    **********************************************************************************************/
    FUNCTION check_has_functionality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_functionality.intern_name_func%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0050 CHAR);
        --l_function_name           VARCHAR2(30 CHAR) := 'CHECK_HAS_FUNCTIONALITY';
        l_has_sys_func_permission NUMBER(24);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_has_sys_func_permission
          FROM prof_func pf
         INNER JOIN sys_functionality sf
            ON sf.id_functionality = pf.id_functionality
         WHERE pf.id_professional = i_prof.id
           AND pf.id_institution = i_prof.institution
           AND sf.id_software = i_prof.software
           AND sf.intern_name_func = i_intern_name;
    
        l_return := iif(l_has_sys_func_permission > 0, k_yes, k_no);
    
        RETURN l_return;
    
    END check_has_functionality;

    FUNCTION check_has_functionality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_functionality.intern_name_func%TYPE,
        o_flag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return VARCHAR2(0050 CHAR);
    BEGIN
    
        l_return := check_has_functionality(i_lang => i_lang, i_prof => i_prof, i_intern_name => i_intern_name);
        o_flag   := l_return;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'check_has_functionality',
                          o_error    => o_error);
            RETURN FALSE;
    END check_has_functionality;

    /********************************************************************************************
    * Returns an array with all professsional from the same dep_clin_serv of the current professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Elisabete Bugalho
    * @version                         2.6.1.2
    * @since                           2011/10/10
    *
    **********************************************************************************************/
    FUNCTION get_prof_dcs_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
        l_prof_dcs table_number;
        l_error    t_error_out;
    BEGIN
    
        g_error := 'GET PROFISSIONAL LIST';
        SELECT p1.id_professional
          BULK COLLECT
          INTO l_prof_dcs
          FROM prof_dep_clin_serv p1
         WHERE p1.flg_status = g_dcs_selected
           AND p1.id_institution = i_prof.institution
           AND p1.id_dep_clin_serv IN (SELECT p2.id_dep_clin_serv
                                         FROM prof_dep_clin_serv p2
                                        WHERE p2.flg_status = g_dcs_selected
                                          AND p2.id_professional = i_prof.id
                                          AND p2.id_institution = i_prof.institution);
    
        RETURN l_prof_dcs;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_PROF_DCS_LIST',
                          o_error    => l_error);
            RETURN NULL;
        
    END get_prof_dcs_list;

    /********************************************************************************************
    * Gets the name (speciality) of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Pedro Santos
    * @version 1.0
    * @since   05/01/2012
    **********************************************************************************************/
    FUNCTION get_prof_name_spec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_last_change IN professional.id_professional%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_ret       VARCHAR2(200 CHAR);
        l_prof_spec VARCHAR2(200 CHAR);
        l_error     t_error_out;
    BEGIN
        g_error := 'GET_PROF_NAME_SPEC';
        l_ret   := get_name(i_lang, i_id_prof_last_change);
    
        l_prof_spec := get_spec_signature(i_lang, i_prof, i_id_prof_last_change, i_date, i_id_episode);
    
        IF l_prof_spec IS NOT NULL
        THEN
            l_ret := l_ret || ' (' || l_prof_spec || ')';
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_PROF_NAME_SPEC',
                          o_error    => l_error);
        
            RETURN NULL;
        
    END get_prof_name_spec;

    /********************************************************************************************
    * Gets the name (speciality) of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Pedro Santos
    * @version 1.0
    * @since   05/01/2012
    **********************************************************************************************/
    FUNCTION get_epis_type_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(200 CHAR);
        --l_prof_spec VARCHAR2(200 CHAR);
        tbl_desc table_varchar;
    BEGIN
        g_error := 'GET_EPIS_TYPE_DESC';
    
        SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
          BULK COLLECT
          INTO tbl_desc
          FROM episode e
          JOIN epis_type et
            ON e.id_epis_type = et.id_epis_type
         WHERE e.id_episode = i_id_episode;
    
        l_ret := return_row_v(tbl_desc);
    
        RETURN l_ret;
    
    END get_epis_type_desc;
    ----
    /********************************************************************************************
    * Returns a table_number with all clinical services associated to a professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Sergio Dias
    * @version                         2.6.2.1.4
    * @since                           3-Jul-2012
    **********************************************************************************************/
    FUNCTION get_list_prof_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN table_number IS
        l_prof_clin_serv table_number;
    BEGIN
    
        g_error := 'GET PROF CLINICAL SERVICES';
        SELECT pdcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_prof_clin_serv
          FROM prof_dep_clin_serv pdcs
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
          JOIN department d
            ON d.id_department = dcs.id_department
          JOIN software_dept sd
            ON d.id_dept = sd.id_dept
         WHERE pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = g_dcs_selected
           AND d.id_institution = i_prof.institution
           AND sd.id_software = i_prof.software;
    
        RETURN l_prof_clin_serv;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_LIST_PROF_DEP_CLIN_SERV',
                          o_error    => o_error);
            RETURN NULL;
    END get_list_prof_dep_clin_serv;
    /********************************************************************************************
    * Get Professional CAB CONV (FR Market)
    *
    * @param i_lang                Preferred language ID
    * @param i_prof                Professional Data Type
    * @param o_prof_title          Professional title 
    * @param o_prof_adress         Professional adress        
    * @param o_prof_state          Professional state (district) 
    * @param o_prof_city           Professional City
    * @param o_prof_zip            Professional Zip Code 
    * @param o_prof_country        Professional Country 
    * @param o_prof_phone_off      Professional Office Phone 
    * @param o_prof_phone_home     Professional Home Phone                            
    * @param o_prof_cellphone      Professional cellphone 
    * @param o_prof_fax            Professional fax  
    * @param o_prof_mail           Professional mail        
    *
    * @return                      True or False
    * 
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/09/24
    ********************************************************************************************/
    FUNCTION get_prof_presc_details
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_prof_title         OUT sys_domain.val%TYPE,
        o_prof_adress        OUT professional.address%TYPE,
        o_prof_state         OUT professional.district%TYPE,
        o_prof_city          OUT professional.city%TYPE,
        o_prof_zip           OUT professional.zip_code%TYPE,
        o_prof_country       OUT pk_translation.t_desc_translation,
        o_prof_phone_off     OUT professional.work_phone%TYPE,
        o_prof_phone_home    OUT professional.num_contact%TYPE,
        o_prof_cellphone     OUT professional.cell_phone%TYPE,
        o_prof_fax           OUT professional.fax%TYPE,
        o_prof_mail          OUT professional.email%TYPE,
        o_prof_tin           OUT professional.taxpayer_number%TYPE,
        o_prof_clinical_name OUT professional.clinical_name%TYPE,
        o_agrupacion_instit  OUT VARCHAR2,
        o_agrupacion_abbr    OUT VARCHAR2,
        o_scholarship        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tmp    VARCHAR2(4000);
        tbl_code table_varchar;
        tbl_prf  typ_tbl_prf := typ_tbl_prf();
        --k_code_country CONSTANT VARCHAR2(0050 CHAR) := 'COUNTRY.CODE_COUNTRY.';
    BEGIN
    
        tbl_prf := get_professional_record(i_prof_id => i_prof.id);
    
        g_error := 'GET PROF INFO DETAILS (CONTACTS + ADRESS) ';
        <<lup_thru_prof_info>>
        FOR i IN 1 .. tbl_prf.count
        LOOP
            o_prof_title  := pk_backoffice.get_prof_title_desc(i_lang, tbl_prf(i).title);
            o_prof_adress := tbl_prf(i).address;
            o_prof_state  := tbl_prf(i).district;
            o_prof_city   := tbl_prf(i).city;
            o_prof_zip    := tbl_prf(i).zip_code;
        
            o_prof_phone_off     := tbl_prf(i).work_phone;
            o_prof_phone_home    := tbl_prf(i).num_contact;
            o_prof_cellphone     := tbl_prf(i).cell_phone;
            o_prof_fax           := tbl_prf(i).fax;
            o_prof_mail          := tbl_prf(i).email;
            o_prof_tin           := tbl_prf(i).taxpayer_number;
            o_prof_clinical_name := tbl_prf(i).clinical_name;
        
            BEGIN
                SELECT ie.institution_name, ie.shortname, pk_translation.get_translation(i_lang, s.code_scholarship)
                  INTO o_agrupacion_instit, o_agrupacion_abbr, o_scholarship
                  FROM professional p
                  LEFT JOIN alert_adtcod_cfg.scholarship s
                    ON p.id_scholarship = s.id_scholarship
                 INNER JOIN institution_ext ie
                    ON p.id_agrupacion_instit = ie.id_institution_ext
                 WHERE p.id_professional = i_prof.id;
            EXCEPTION
                WHEN OTHERS THEN
                    o_agrupacion_instit := NULL;
                    o_agrupacion_abbr   := NULL;
            END;
        
            SELECT code_country
              BULK COLLECT
              INTO tbl_code
              FROM country
             WHERE id_country = tbl_prf(i).id_country;
        
            l_tmp          := return_row_v(tbl_code);
            o_prof_country := pk_translation.get_translation(i_lang, l_tmp);
        
        END LOOP lup_thru_prof_info;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_PROF_PRESC_DETAILS',
                          o_error    => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_presc_details;

    -- #################################################################

    FUNCTION check_blob(i_prof IN profissional) RETURN VARCHAR2 IS
        l_bool   BOOLEAN;
        l_return VARCHAR2(4000);
    BEGIN
    
        l_bool := (pk_profphoto.check_blob(i_prof.id) = k_no);
    
        IF l_bool
        THEN
            l_return := pk_profphoto.get_prof_photo(i_prof);
        END IF;
    
        RETURN l_return;
    
    END check_blob;

    -- *************************************************************************************
    FUNCTION get_prof_info(i_prof IN profissional) RETURN t_prof_info IS
        l_prf t_prof_info;
    BEGIN
    
        SELECT id_language,
               desc_language,
               timeout,
               first_screen,
               pk_prof_utils.check_blob(i_prof) profphoto,
               name,
               nick_name
          INTO l_prf.id_language,
               l_prf.desc_language,
               l_prf.timeout,
               l_prf.first_screen,
               l_prf.profphoto,
               l_prf.name,
               l_prf.nick_name
          FROM (SELECT rownum r_num,
                       pp.id_language,
                       l.desc_language,
                       pp.timeout,
                       pp.first_screen,
                       prof.name,
                       prof.nick_name
                  FROM prof_preferences pp
                  JOIN LANGUAGE l
                    ON pp.id_language = l.id_language
                  JOIN professional prof
                    ON prof.id_professional = pp.id_professional
                 WHERE pp.id_professional = i_prof.id
                   AND pp.id_professional = prof.id_professional
                   AND pp.id_software IN (i_prof.software, 0)
                   AND pp.id_institution = nvl(i_prof.institution, 0) -- JS 01/11/2006 SS 15/12/2006 DESCOMENTEI
                 ORDER BY pp.id_software DESC)
         WHERE r_num = 1;
    
        RETURN l_prf;
    
    END get_prof_info;

    -- #################################################################
    FUNCTION get_prof_username(i_prof_id IN NUMBER) RETURN VARCHAR2 IS
        l_user table_varchar;
        --l_bool   BOOLEAN;
        l_return VARCHAR2(1000 CHAR);
        k_func_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_PROF_USERNAME FNC';
    BEGIN
    
        log_debug(i_text => 'GET RECORD ID_PROF:' || to_char(i_prof_id), i_func_name => k_func_name);
        SELECT login
          BULK COLLECT
          INTO l_user
          FROM ab_user_info
         WHERE id_ab_user_info = i_prof_id;
    
        l_return := return_row_v(l_user);
    
        RETURN l_return;
    
    END get_prof_username;
    -- ******************************************************

    FUNCTION get_prf_login_n_lang
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        o_user_name   OUT VARCHAR2,
        o_id_prf_lang OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_PRF_LOGIN_N_LANG PRC';
        l_prf t_prof_info;
    BEGIN
    
        log_debug(i_text => 'Call username function ID_PROF:' || to_char(i_prof.id), i_func_name => k_func_name);
        o_user_name := get_prof_username(i_prof.id);
    
        l_prf         := get_prof_info(i_prof);
        o_id_prf_lang := l_prf.id_language;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => SQLERRM,
                          i_function => k_func_name,
                          o_error    => o_error);
            RETURN FALSE;
    END get_prf_login_n_lang;

    /********************************************************************************************
    * Get detailed prof dep_clin_serv information
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Professional Array   
    * @param i_id_prof                Id professional to search
    * @param o_list                   Cursor with colected information details
    * @param o_error                  error process
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/06
    **********************************************************************************************/

    FUNCTION get_prof_dcs_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_list FOR
            SELECT pdcs.id_dep_clin_serv,
                   d.id_dept id_dept,
                   pk_translation.get_translation(i_lang, dt.code_dept) desc_dept,
                   dcs.id_department id_service,
                   pk_translation.get_translation(i_lang, d.code_department) desc_service,
                   dcs.id_clinical_service id_speciality,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_speciality
              FROM prof_dep_clin_serv pdcs
             INNER JOIN dep_clin_serv dcs
                ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_yes)
             INNER JOIN department d
                ON (d.id_department = dcs.id_department AND d.id_institution = i_prof.institution AND
                   d.flg_available = g_yes)
             INNER JOIN dept dt
                ON (dt.id_dept = d.id_dept AND dt.flg_available = g_yes)
             INNER JOIN clinical_service cs
                ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_yes)
             WHERE pdcs.id_professional = i_id_prof
               AND pdcs.id_institution = i_prof.institution
               AND pdcs.flg_status = g_dcs_selected
             ORDER BY desc_dept, desc_service, desc_speciality;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PROF_UTILS',
                                              'get_prof_dcs_det',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_dcs_det;

    /* Method that return professional work phone */
    FUNCTION get_work_phone
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_contact_num   professional.work_phone%TYPE;
        tbl_contact_num table_varchar;
    BEGIN
    
        SELECT p.work_phone
          BULK COLLECT
          INTO tbl_contact_num
          FROM professional p
         WHERE p.id_professional = i_prof_id;
    
        l_contact_num := return_row_v(tbl_contact_num);
    
        RETURN l_contact_num;
    
    END get_work_phone;

    /********************************************************************************************
    * Returns the professional identifier for a given username.
    *
    * @param i_username               Username
    * @param o_id_professional        Professional identifier
    * @param o_error                  Error message
    
    * @return                         true or false on success or error
    *
    * @author                         Joao Sa
    * @since                          2014/03/19
    **********************************************************************************************/
    FUNCTION get_prof_id_by_username
    (
        i_username        IN VARCHAR2,
        o_id_professional OUT ab_user_info.id_ab_user_info%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_id_prof table_number;
    BEGIN
    
        SELECT u.id_ab_user_info
          BULK COLLECT
          INTO tbl_id_prof
          FROM ab_user_info u
         WHERE upper(i_username) = upper(u.login);
    
        o_id_professional := return_row_n(tbl_id_prof);
    
        RETURN TRUE;
    END get_prof_id_by_username;

    /**********************************************************************************************
    * Get PROFESSIONAL Bleep number
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem
    *
    * @author                         RMGM
    * @version                        2.6.4.0 
    * @since                          2014/06/13
    **********************************************************************************************/

    FUNCTION get_bleep_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_BLEEP_NUM';
        l_bleep_num professional.bleep_number%TYPE;
        tbl_bleep   table_varchar;
        l_error     t_error_out;
    
    BEGIN
    
        g_error := l_func_name || ' -> get bleep info';
        SELECT p.bleep_number
          BULK COLLECT
          INTO tbl_bleep --l_bleep_num
          FROM professional p
         WHERE p.id_professional = i_prof_id;
    
        l_bleep_num := return_row_v(tbl_bleep);
    
        RETURN l_bleep_num;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => l_func_name,
                          o_error    => l_error);
            RETURN NULL;
    END get_bleep_num;
    /********************************************************************************************
    * Returns the Professional facility IDentifier (Mecanografic number)
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_mec_num                  Identifier output
    * @param      o_error                    Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Rui Gomes
    * @version                         2.6.4.1
    * @since                           2014/07/08
    **********************************************************************************************/
    FUNCTION get_prof_inst_mec_num
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_prof_mec_num prof_institution.num_mecan%TYPE;
        l_ret          BOOLEAN;
        l_error        t_error_out;
    BEGIN
    
        l_ret := pk_backoffice.get_prof_inst_mec_num(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_flg_active => i_flg_active,
                                                     o_mec_num    => l_prof_mec_num,
                                                     o_error      => l_error);
        RETURN l_prof_mec_num;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_sqlcode  => l_error.ora_sqlcode,
                          i_sqlerrm  => l_error.ora_sqlerrm,
                          i_message  => g_error,
                          i_function => 'GET_PROF_INST_MEC_NUM',
                          o_error    => l_error);
            RETURN NULL;
    END get_prof_inst_mec_num;

    FUNCTION get_sys_config_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_config   IN sys_config.id_sys_config%TYPE,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool        BOOLEAN;
        l_value       table_number := table_number();
        l_id_prof_cat NUMBER(24);
    BEGIN
    
        o_have_permission := k_no;
    
        BEGIN
            l_id_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
            l_value       := pk_utils.str_split_n(i_list  => pk_sysconfig.get_config(i_id_sys_config, i_prof),
                                                  i_delim => '|');
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        -- Validate if button should be active or not by sys_config
        -- sys config is by category pipelined        
        l_bool := pk_utils.search_table_number(i_table => l_value, i_search => l_id_prof_cat) != -1;
    
        o_have_permission := iif(l_bool, k_yes, k_no);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            process_error(i_lang     => i_lang,
                          i_sqlcode  => SQLCODE,
                          i_sqlerrm  => SQLERRM,
                          i_message  => g_error,
                          i_function => 'GET_SYS_CONFIG_CAT',
                          o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sys_config_cat;
    /********************************************************************************************
    * Get contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    * @param o_work_phone      Work phone Number value
    * @param o_home_phone      Home phone Number value
    * @param o_cell_phone      Celular phone Number value
    * @param o_fax             Fax Number value
    * @param o_email           Email adress value
    * @param o_bleep           Bleep number value
    * @param o_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION get_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_req_date       IN professional_hist.dt_operation%TYPE DEFAULT NULL,
        o_work_phone     OUT professional.work_phone%TYPE,
        o_home_phone     OUT professional.num_contact%TYPE,
        o_cell_phone     OUT professional.cell_phone%TYPE,
        o_fax            OUT professional.fax%TYPE,
        o_email          OUT professional.email%TYPE,
        o_bleep          OUT professional.bleep_number%TYPE,
        o_contact_det    OUT prof_institution.contact_detail%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.get_prof_contacts(i_lang           => i_lang,
                                               i_id_prof        => i_id_prof,
                                               i_id_institution => i_id_institution,
                                               i_req_date       => i_req_date,
                                               o_work_phone     => o_work_phone,
                                               o_home_phone     => o_home_phone,
                                               o_cell_phone     => o_cell_phone,
                                               o_fax            => o_fax,
                                               o_email          => o_email,
                                               o_bleep          => o_bleep,
                                               o_contact_det    => o_contact_det,
                                               o_error          => o_error);
    END get_prof_contacts;
    /********************************************************************************************
    * Set contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_work_phone      Work phone Number value
    * @param i_home_phone      Home phone Number value
    * @param i_cell_phone      Celular phone Number value
    * @param i_fax             Fax Number value
    * @param i_email           Email adress value
    * @param i_bleep           Bleep number value
    * @param i_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION set_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_home_phone     IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_bleep          IN professional.bleep_number%TYPE,
        i_contact_det    IN prof_institution.contact_detail%TYPE,
        i_commit_trs     IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_backoffice.set_prof_contacts(i_lang           => i_lang,
                                               i_id_prof        => i_id_prof,
                                               i_id_institution => i_id_institution,
                                               i_work_phone     => i_work_phone,
                                               i_home_phone     => i_home_phone,
                                               i_cell_phone     => i_cell_phone,
                                               i_fax            => i_fax,
                                               i_email          => i_email,
                                               i_bleep          => i_bleep,
                                               i_contact_det    => i_contact_det,
                                               i_commit_trs     => i_commit_trs,
                                               o_error          => o_error);
    END set_prof_contacts;

    /********************************************************************************************
    * Check if bleep popup is to be shown
    *
    * @param i_lang                   Application language
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_show_bleep_popup       'Y' or 'N'
    * @param o_error                  Error object 
    * @return                         True or False
    *
    * @author                         Nuno Alves
    * @version                        2.6.4
    * @since                          2015/03/04
    ********************************************************************************************/
    FUNCTION get_show_bleep_popup
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE,
        o_show_bleep_popup       OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(30 CHAR) := 'GET_SHOW_BLEEP_POPUP';
        l_is_bleep_valid     BOOLEAN;
        l_bleep_popup_syscfg sys_config.value%TYPE;
        l_flg_needs_cosign   VARCHAR2(1);
        l_med_task_types     table_number;
        l_action             action.id_action%TYPE := nvl(i_action, pk_alert_constant.g_action_presc_for_local);
    BEGIN
    
        IF i_episode IS NULL
        THEN
            o_show_bleep_popup := pk_alert_constant.g_no;
        ELSE
        
            -- Client sys_config for showing the popup if bleep is invalid
            l_bleep_popup_syscfg := pk_sysconfig.get_config(i_code_cf   => 'BLEEP_VALIDATION',
                                                            i_prof_inst => i_prof.institution,
                                                            i_prof_soft => i_prof.software);
        
            -- Bleep popup pops up only if it is a medication task_type
            SELECT DISTINCT tt.id_task_type
              BULK COLLECT
              INTO l_med_task_types
              FROM task_type tt
             WHERE tt.id_task_type_parent = pk_alert_constant.g_task_med_parent
               AND tt.id_task_type IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                                        column_value
                                         FROM TABLE(i_tbl_id_task_type) t);
        
            IF l_bleep_popup_syscfg = pk_alert_constant.g_no
               OR l_med_task_types.count = 0
            THEN
                o_show_bleep_popup := pk_alert_constant.g_no;
            ELSE
                -- Backoffice team API that checks bleep validation
                l_is_bleep_valid := pk_backoffice.is_bleep_valid(i_lang => i_lang, i_prof => i_prof);
            
                IF NOT pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                              i_prof                   => i_prof,
                                                              i_episode                => i_episode,
                                                              i_tbl_id_task_type       => l_med_task_types,
                                                              i_cosign_def_action_type => i_cosign_def_action_type,
                                                              i_action                 => l_action,
                                                              o_flg_prof_need_cosign   => l_flg_needs_cosign,
                                                              o_error                  => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_flg_needs_cosign = pk_alert_constant.g_no
                   AND NOT l_is_bleep_valid
                THEN
                    o_show_bleep_popup := pk_alert_constant.g_yes;
                ELSE
                    o_show_bleep_popup := pk_alert_constant.g_no;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_show_bleep_popup;

    /********************************************************************************************
    * Get work phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.work_phone
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/
    FUNCTION get_prof_work_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.work_phone%TYPE IS
    
        l_func_name VARCHAR2(30 CHAR) := 'GET_PROF_WORK_PHONE_CONTACT';
        l_error     t_error_out;
    BEGIN
        g_error := 'Call pk_backoffice.get_prof_work_phone_contact / I_PROF.ID=' || i_prof.id;
        RETURN pk_backoffice.get_prof_work_phone_contact(i_lang => i_lang, i_prof => i_prof, i_req_date => i_req_date);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_prof_work_phone_contact;

    /********************************************************************************************
    * Get home phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.work_phone
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/
    FUNCTION get_prof_home_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.num_contact%TYPE IS
    
        l_func_name VARCHAR2(30 CHAR) := 'GET_PROF_HOME_PHONE_CONTACT';
        l_error     t_error_out;
    BEGIN
        g_error := 'Call pk_backoffice.get_prof_home_phone_contact / I_PROF.ID=' || i_prof.id;
        RETURN pk_backoffice.get_prof_home_phone_contact(i_lang => i_lang, i_prof => i_prof, i_req_date => i_req_date);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_prof_home_phone_contact;

    /********************************************************************************************
    * Get bleep number   contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_bleep_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.bleep_number%TYPE
    
     IS
    
        l_func_name VARCHAR2(30 CHAR) := 'GET_PROF_BLEEP_NUMBER_CONTACT';
        l_error     t_error_out;
    BEGIN
        g_error := 'Call pk_backoffice.get_prof_bleep_number_contact / I_PROF.ID=' || i_prof.id;
        RETURN pk_backoffice.get_prof_bleep_number_contact(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_req_date => i_req_date);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_prof_bleep_number_contact;

    /********************************************************************************************
    * Get bleep number   contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_cell_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.bleep_number%TYPE IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PROF_CELL_NUMBER_CONTACT';
        l_error     t_error_out;
    BEGIN
        g_error := 'Call pk_backoffice.get_prof_cell_number_contact / I_PROF.ID=' || i_prof.id;
        RETURN pk_backoffice.get_prof_cell_number_contact(i_lang => i_lang, i_prof => i_prof, i_req_date => i_req_date);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_prof_cell_number_contact;

    /*********************************************************************************************
    * Get professional department ids
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             Current professional
    *
    * @author                   rui.mendonca
    * @version                  2.6.5.2
    * @since                    2016/06/06
    **********************************************************************************************/
    FUNCTION get_prof_dept_ids
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PROF_DEPT_IDS';
        l_dept_ids  table_number := table_number();
        l_error     t_error_out;
    BEGIN
        SELECT DISTINCT d.id_department
          BULK COLLECT
          INTO l_dept_ids
          FROM prof_dep_clin_serv pdcs
          JOIN dep_clin_serv dcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = pk_alert_constant.g_status_selected
           AND d.id_institution = i_prof.institution
           AND pdcs.id_institution = i_prof.institution
           AND d.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_dept_ids;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_prof_dept_ids;

    /*********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_inst_dept_ids
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_department_flg_type IN department.flg_type%TYPE
    ) RETURN table_number IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_INST_DEPT_IDS';
        l_dept_ids  table_number := table_number();
        l_error     t_error_out;
    BEGIN
        SELECT DISTINCT d.id_department
          BULK COLLECT
          INTO l_dept_ids
          FROM prof_dep_clin_serv pdcs
          JOIN dep_clin_serv dcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
           AND (instr(d.flg_type, i_department_flg_type) > 0 OR i_department_flg_type IS NULL)
         WHERE pdcs.flg_status = pk_alert_constant.g_status_selected
           AND d.id_institution = i_prof.institution
           AND pdcs.id_institution = i_prof.institution
           AND d.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_dept_ids;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_inst_dept_ids;

    FUNCTION get_preferencial_department
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_id_dcs NUMBER;
        l_return VARCHAR2(4000);
    BEGIN
    
        l_id_dcs := get_prof_dcs(i_prof => i_prof);
    
        SELECT pk_translation.get_translation(i_lang, d.code_department) desc_department
          BULK COLLECT
          INTO tbl_desc
          FROM department d
          JOIN dep_clin_serv dcs
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = l_id_dcs;
    
        IF tbl_desc.count > 0
        THEN
            l_return := tbl_desc(1);
        END IF;
    
        RETURN l_return;
    
    END get_preferencial_department;

    -----
    FUNCTION get_profile_info(i_prof IN profissional) RETURN profile_template%ROWTYPE IS
        l_id_profile_template NUMBER;
        l_row                 profile_template%ROWTYPE;
    BEGIN
    
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        IF l_id_profile_template IS NOT NULL
        THEN
            SELECT pt.*
              INTO l_row
              FROM profile_template pt
             WHERE pt.id_profile_template = l_id_profile_template;
        END IF;
    
        RETURN l_row;
    
    END get_profile_info;

    FUNCTION get_arabic_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_profinfo_base(i_lang => i_lang, i_mode => k_get_name_arabic, i_prof_id => i_prof_id);
    
    END get_arabic_name;

    /********************************************************************************************
    * Returns the Professional order numbet
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_error                    Error
    *
    * @return                         Order number
    *
    * @author                          Elisabete Bugalho
    * @version                         2.5.3
    * @since                           2017/02/13
    **********************************************************************************************/
    FUNCTION get_prof_num_order
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_prof_num_order prof_institution.num_mecan%TYPE;
        l_ret            BOOLEAN;
        l_error          t_error_out;
    BEGIN
        l_ret := get_num_order(i_lang, i_prof, i_prof.id, l_prof_num_order, l_error);
        RETURN l_prof_num_order;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_NUM_ORDER',
                                              l_error);
            RETURN NULL;
    END get_prof_num_order;

    FUNCTION get_flg_mrp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_profile      profile_template.flg_profile%TYPE;
        l_flg_mrp          profile_template.flg_mrp%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        l_profile_template := i_profile_template;
    
        IF i_profile_template IS NULL
        THEN
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        END IF;
    
        SELECT flg_mrp
          INTO l_flg_mrp
          FROM (SELECT flg_mrp, row_number() over(ORDER BY rank DESC) rn
                  FROM (SELECT pti.flg_mrp, decode(i_prof.institution, 0, 2, 3) rank
                          FROM profile_template_inst pti
                         WHERE pti.id_profile_template = l_profile_template
                           AND pti.id_institution IN (i_prof.institution, 0)
                           AND pti.flg_mrp IS NOT NULL
                        UNION ALL
                        SELECT pt.flg_mrp, 1 rank
                          FROM profile_template pt
                         WHERE pt.id_profile_template = l_profile_template))
         WHERE rn = 1;
    
        --  RETURN nvl(l_flg_mrp, pk_alert_constant.g_yes);
        -- shouldnt be Y by omission
        RETURN nvl(l_flg_mrp, pk_alert_constant.g_no);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_flg_mrp;

    FUNCTION get_prof_sub_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    
        l_sub_cat category_sub.flg_type%TYPE;
    
    BEGIN
        BEGIN
            SELECT cs.flg_type
              INTO l_sub_cat
              FROM professional p
             INNER JOIN prof_cat pc
                ON pc.id_professional = p.id_professional
             INNER JOIN category_sub cs
                ON cs.id_category_sub = pc.id_category_sub
             WHERE p.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        EXCEPTION
            WHEN OTHERS THEN
                l_sub_cat := NULL;
        END;
    
        RETURN l_sub_cat;
    
    END get_prof_sub_category;

    /********************************************************************************************
    * Returns the Professional default dep_clin_serv (ID_dep_clin_sev/ID_department/ID_clinical_service)
    *
    * @param      i_prof                     Professional identification Array
    * @param      o_error                    Error
    *
    * @return                         Order number
    *
    * @author                          Elisabete Bugalho
    * @version                         2.7.4.3
    * @since                           2019/021/09
    **********************************************************************************************/
    FUNCTION get_prof_default_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN software.id_software%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_department       OUT department.id_department%TYPE,
        o_clinical_service OUT clinical_service.id_clinical_service%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_dcs              table_number;
        tbl_department       table_number;
        tbl_clinical_service table_number;
    BEGIN
    
        SELECT dcs.id_dep_clin_serv, dcs.id_department, dcs.id_clinical_service
          BULK COLLECT
          INTO tbl_dcs, tbl_department, tbl_clinical_service
          FROM dep_clin_serv dcs
          JOIN department dpt
            ON dpt.id_department = dcs.id_department
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN software_dept sdt
            ON sdt.id_dept = dpt.id_dept
         WHERE pdcs.flg_default = g_dcs_default
           AND sdt.id_software = i_software
           AND pdcs.flg_status = g_dcs_selected
           AND pdcs.id_professional = i_prof.id
           AND dpt.id_institution = i_prof.institution
         ORDER BY dcs.id_department;
    
        o_id_dep_clin_serv := return_row_n(i_tbl => tbl_dcs);
        o_department       := return_row_n(i_tbl => tbl_department);
        o_clinical_service := return_row_n(i_tbl => tbl_clinical_service);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'get_prof_default_dcs',
                                              o_error);
        
            RETURN FALSE;
    END get_prof_default_dcs;

    /**
    * Returns the Professional order numbet
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_error                    Error
    *
    * @return                                Professional preferential rool
    *
    * @author                          Ana Moita
    * @version                         2.8.0
    * @since                           2019/05/16
    */
    FUNCTION get_prof_pref_room
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_prof_pref_room table_number;
        l_error          t_error_out;
        l_room           room.id_room%TYPE;
    
    BEGIN
    
        SELECT id_room
          BULK COLLECT
          INTO l_prof_pref_room
          FROM prof_room
         WHERE id_professional = i_prof.id
           AND id_room IN (SELECT r.id_room
                             FROM room r, department d, software_dept sd
                            WHERE d.id_department = r.id_department
                              AND d.id_institution = i_prof.institution
                              AND sd.id_dept = d.id_dept
                              AND sd.id_software = i_prof.software)
           AND flg_pref = pk_visit.g_room_pref;
    
        IF l_prof_pref_room.count > 0
        THEN
            l_room := l_prof_pref_room(1);
        END IF;
        RETURN l_room;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_PREF_ROOM',
                                              l_error);
            RETURN NULL;
    END get_prof_pref_room;
    /**
    * Returns the Professionals associate to a sys functionality
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      i_intern_name_func         Sys functionality internal name
    *
    * @return                                table number of id professinals
    *
    * @author                          Ana Moita
    * @version                         2.8.0
    * @since                           2019/12/10
    */
    FUNCTION get_prof_by_functionality
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_intern_name_func IN sys_functionality.intern_name_func%TYPE
    ) RETURN table_number IS
        l_id_profs    table_number;
        l_id_sys_func NUMBER;
    
    BEGIN
        SELECT sf.id_functionality
          INTO l_id_sys_func
          FROM sys_functionality sf
         WHERE sf.intern_name_func = i_intern_name_func;
    
        SELECT pf.id_professional
          BULK COLLECT
          INTO l_id_profs
          FROM prof_func pf
         WHERE pf.id_functionality = l_id_sys_func
           AND pf.id_institution = i_prof.institution;
        RETURN l_id_profs;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_prof_by_functionality;

    /**
    * Get profissional all functionalities from all softwares
    *
    * @param      I_LANG                               Language identification
    * @param      I_PROF                               professional, software and institution ids
    *
    * @return     table_varchar
    * @author     Anna Kurowska
    * @version    2.8
    * @since      2019/12/19
    */
    FUNCTION get_prof_func_all
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar IS
        l_prof_func table_varchar := table_varchar();
    BEGIN
    
        g_error := 'GET PROF_FUNC CURSOR';
    
        SELECT sf.intern_name_func
          BULK COLLECT
          INTO l_prof_func
          FROM prof_func pf, sys_functionality sf
         WHERE pf.id_professional = i_prof.id
           AND pf.id_institution = i_prof.institution
           AND sf.id_functionality = pf.id_functionality
           AND sf.flg_available = pk_alert_constant.g_available;
    
        RETURN l_prof_func;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_prof_func_all;

    -- concatenates profile_templates of all professionals from same schedules
    -- Used in alerts  
    FUNCTION get_sch_profiles
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2 IS
        l_templates   VARCHAR2(10000);
        tbl_templates table_varchar;
        l_sep CONSTANT VARCHAR2(0010 CHAR) := ',';
    BEGIN
    
        SELECT listagg(xsql.xdesc_template, l_sep) within GROUP(ORDER BY xsql.xdesc_template)
          BULK COLLECT
          INTO tbl_templates
          FROM (SELECT pk_translation.get_translation(i_lang, pt.code_profile_template) xdesc_template
                  FROM profile_template pt
                 WHERE pt.id_profile_template IN (SELECT pk_tools.get_prof_profile_template(i_prof => profissional(sr.id_professional,
                                                                                                                   i_prof.institution,
                                                                                                                   i_prof.software)) id_profile_template
                                                    FROM sch_resource sr
                                                   WHERE sr.id_schedule = i_id_schedule)) xsql;
    
        IF tbl_templates.count > 0
        THEN
            l_templates := tbl_templates(1);
        END IF;
    
        RETURN l_templates;
    
    END get_sch_profiles;

    FUNCTION get_prof_data
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dcs_default dep_clin_serv.id_dep_clin_serv%TYPE;
        l_prof_title  professional.title%TYPE;
    BEGIN
    
        l_dcs_default := pk_prof_utils.get_prof_dcs(i_prof);
        l_prof_title  := get_profinfo_base(i_lang => i_lang, i_mode => k_get_title, i_prof_id => i_prof.id);
    
        OPEN o_data FOR
            SELECT l_prof_title || ' ' || p.first_name || ' ' || p.last_name name,
                   pk_utils.get_service_desc(i_lang, l_dcs_default, 'DEPT_DESC_BY_DCS') default_dcs,
                   pk_profphoto.get_prof_photo(i_prof) prof_photo
              FROM professional p
             WHERE p.id_professional = i_prof.id;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_DATA',
                                              o_error);
            RETURN FALSE;
    END get_prof_data;

BEGIN

    g_yes := k_yes;
    g_no  := k_no;

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_prof_utils;
/
