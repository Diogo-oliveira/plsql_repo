/*-- Last Change Revision: $Rev: 2027777 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sysdomain IS

    k_mode_domain_values_id   CONSTANT VARCHAR2(0200 CHAR) := 'MODE_GET_VAL';
    k_mode_domain_values_desc CONSTANT VARCHAR2(0200 CHAR) := 'MODE_GET_DESC';

    k_mode_domain_base_1 CONSTANT VARCHAR2(0050 CHAR) := 'MODE_DMAIN_BASE1';
    k_mode_domain_base_2 CONSTANT VARCHAR2(0050 CHAR) := 'MODE_DMAIN_BASE2';

    k_mode_dmn_rank_per_val     CONSTANT VARCHAR2(0200 CHAR) := 'DMN_RANK_PER_VAL';
    k_mode_dmn_val_per_desc_val CONSTANT VARCHAR2(0200 CHAR) := 'DMN_VAL_PER_DESC_VAL';
    k_mode_dmn_img_per_desc_val CONSTANT VARCHAR2(0200 CHAR) := 'DMN_IMG_NAME_PER_DESC_VAL';

    k_mode_none_option_istrue  VARCHAR2(0050 CHAR) := 'TRUE';
    k_mode_none_option_isfalse VARCHAR2(0050 CHAR) := 'FALSE';

    TYPE t_sd_trl IS TABLE OF sys_domain.desc_val%TYPE INDEX BY VARCHAR2(10); --index -> val
    TYPE t_sd_trl_code IS TABLE OF t_sd_trl INDEX BY VARCHAR2(200); --index -> code_domain
    TYPE t_sd_lang_trl IS TABLE OF t_sd_trl_code INDEX BY PLS_INTEGER; --index -> id_language
    TYPE t_sd_owner_trl IS TABLE OF t_sd_lang_trl INDEX BY VARCHAR2(0100 CHAR); --index -> domain_owner

    --    g_sd_cache t_sd_lang_trl;
    g_sd_cache t_sd_owner_trl;
    k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0001 CHAR) := 'N';

    k_multc_domain      CONSTANT VARCHAR2(0200 CHAR) := 'DOM';
    k_multc_syslist     CONSTANT VARCHAR2(0200 CHAR) := 'SLG';
    k_multc_multichoice CONSTANT VARCHAR2(0200 CHAR) := 'MUL';

    FUNCTION get_first_row_v(i_tbl IN table_varchar) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        END IF;
    
        RETURN l_return;
    
    END get_first_row_v;

    FUNCTION process_error
    (
        i_lang     IN NUMBER,
        i_message  IN VARCHAR2,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                 i_sqlcode  => SQLCODE,
                                                 i_sqlerrm  => SQLERRM,
                                                 i_message  => i_message,
                                                 i_owner    => g_package_owner,
                                                 i_package  => g_package_name,
                                                 i_function => i_function,
                                                 o_error    => o_error);
    
    END process_error;

    FUNCTION get_domain_cached
    (
        i_lang        language.id_language%TYPE,
        i_value       VARCHAR2,
        i_code_domain  sys_domain.code_domain%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.desc_val%TYPE IS
        l_got_translations BOOLEAN;
        l_return           sys_domain.desc_val%TYPE;
        l_bool1            BOOLEAN;
        l_bool2            BOOLEAN;
        l_bool3            BOOLEAN;
    BEGIN
        IF i_lang IS NULL
           OR i_code_domain IS NULL
           OR i_value IS NULL
           OR i_domain_owner IS NULL --
        THEN
            RETURN NULL;
        END IF;
    
        l_bool1 := g_sd_cache.exists(i_domain_owner);
        IF l_bool1
        THEN
            l_bool2 := g_sd_cache(i_domain_owner).exists(i_lang);
        END IF;
    
        IF l_bool2
        THEN
            l_bool3 := g_sd_cache(i_domain_owner)(i_lang).exists(i_code_domain);
        END IF;
    
        IF NOT l_bool1
           OR NOT l_bool2
           OR NOT l_bool3
        THEN
        
            l_got_translations := FALSE;
            <<lup_thru_domains>>
            FOR line IN (SELECT desc_val, val
                           FROM sys_domain sd
                          WHERE sd.code_domain = i_code_domain
                            AND sd.domain_owner = i_domain_owner
                            AND sd.id_language = i_lang)
            LOOP
                g_sd_cache(i_domain_owner)(i_lang)(i_code_domain)(line.val) := line.desc_val;
                l_got_translations := TRUE;
            END LOOP lup_thru_domains;
        
            --if there are no translations, then insert a dummy element just to prevent constant read of translations
            --IF NOT g_sd_cache.exists(i_lang)
            --   OR NOT g_sd_cache(i_lang).exists(i_code_domain)
            IF NOT l_got_translations
            THEN
                g_sd_cache(i_domain_owner)(i_lang)(i_code_domain)('______') := NULL;
            END IF;
        
        END IF;
    
        l_return := NULL;
        IF g_sd_cache(i_domain_owner) (i_lang)(i_code_domain).exists(i_value)
        THEN
            l_return := g_sd_cache(i_domain_owner) (i_lang) (i_code_domain) (i_value);
        END IF;
    
        RETURN l_return;
    
    END get_domain_cached;

    /************************************************************************************************************ 
    * Returns the description for a sys_domain
    *
    * @param      i_code_dom                        domain code
    * @param      i_val                             domain value
    * @param      i_lang                            language ID
    *
    * @return     domain description
    * @author     JD
    * @version    0.1
    * @since      2005/01/25
    ***********************************************************************************************************/
    FUNCTION get_domain_base
    (
        i_mode         IN VARCHAR2,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_val_dom table_varchar;
        l_return  sys_domain.desc_val%TYPE;
        l_flg1    VARCHAR2(0010 CHAR);
        l_flg2    VARCHAR2(0010 CHAR);
    BEGIN
    
        CASE i_mode
            WHEN k_mode_domain_base_1 THEN
                l_flg1 := k_yes;
                l_flg2 := k_yes;
            WHEN k_mode_domain_base_2 THEN
                l_flg1 := k_yes;
                l_flg2 := k_no;
        END CASE;
    
        --Changed to bulk collect to minimize the exceptions number
        SELECT s.desc_val
          BULK COLLECT
          INTO l_val_dom
          FROM sys_domain s
         WHERE s.code_domain = i_code_dom
           AND s.id_language = i_lang
           AND domain_owner = i_domain_owner
           AND s.val = i_val
           AND s.flg_available IN (l_flg1, l_flg2);
    
        l_return := get_first_row_v(l_val_dom);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_domain_base;

    FUNCTION get_domain
    (
        i_code_dom     IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_return sys_domain.desc_val%TYPE;
    BEGIN
    
        l_return := get_domain_base(i_mode         => k_mode_domain_base_1,
                                    i_code_dom     => i_code_dom,
                                    i_val          => i_val,
                                    i_lang         => i_lang,
                                    i_domain_owner => i_domain_owner);
    
        RETURN l_return;
    
    END get_domain;

    /************************************************************************************************************ 
    * Same as get_domain but ignores flg_available
    *
    * @param      i_code_dom                        domain code
    * @param      i_val                             domain value
    * @param      i_lang                            language ID
    *
    * @return     domain description
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/12
    ***********************************************************************************************************/
    FUNCTION get_domain_no_avail
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        --l_val_dom table_varchar;
        l_return  sys_domain.desc_val%TYPE;
    BEGIN
    
        l_return := get_domain_base(i_mode         => k_mode_domain_base_2,
                                    i_code_dom     => i_code_dom,
                                    i_val          => i_val,
                                    i_lang         => i_lang,
                                    i_domain_owner => i_domain_owner);
    
        RETURN l_return;
    
    END get_domain_no_avail;

    /******************************************************************************
       OBJECTIVO:   Retornar um array de descritivos de SYS_DOMAIN
       PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitido o valor
             I_CODE_DOM - Array de códigos
          Saida:

      CRIAÇÃO: cmf 24-11-2014
      NOTAS:
    *********************************************************************************/
    FUNCTION get_values_domain
    (
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_lang          IN sys_domain.id_language%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_vals_included IN table_varchar,
        i_vals_excluded IN table_varchar DEFAULT NULL,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema,
        i_order         IN NUMBER DEFAULT 1
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0030 CHAR) := 'GET_VALUES_DOMAIN';
        tbl_include table_varchar; --table_varchar( 'Y','R'); --table_Varchar(); -- table_varchar( 'Y'); 
        tbl_exclude table_varchar; --table_varchar( 'R');
        l_count     NUMBER(24);
        l_bool      BOOLEAN;
    BEGIN
    
        tbl_include := nvl(i_vals_included, table_varchar());
        tbl_exclude := nvl(i_vals_excluded, table_varchar());
        
        l_count := tbl_include.count;
        
            OPEN o_data FOR --
                SELECT desc_val, val, img_name, rank
              FROM (SELECT desc_val, val, img_name, rank, img_name icon
                  FROM sys_domain s
                 WHERE s.code_domain = i_code_dom
                   AND s.id_language = i_lang
                       AND s.flg_available = k_yes
                       AND s.domain_owner = i_domain_owner
                       AND ((l_count > 0 AND s.val IN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                                                        column_value
                                                         FROM TABLE(tbl_include) t1)) OR (l_count = 0))
                    MINUS
                    SELECT desc_val, val, img_name, rank, img_name icon
                  FROM sys_domain s
                 WHERE s.code_domain = i_code_dom
                   AND s.id_language = i_lang
                       AND s.flg_available = k_yes
                       AND s.domain_owner = i_domain_owner
                       AND s.val IN (SELECT /*+ OPT_ESTIMATE(TABLE t2 ROWS=1) */
                                      column_value
                                       FROM TABLE(tbl_exclude) t2)) xsql
             ORDER BY decode(i_order, 1, rank, 2, desc_val);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_bool := process_error(i_lang     => i_lang,
                                    i_message  => g_error,
                                    i_function => k_func_name,
                                    o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN l_bool;
    END get_values_domain;
        
    FUNCTION get_values_domain
    (
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_lang          IN sys_domain.id_language%TYPE,
        o_data          OUT pk_types.cursor_type,
        i_vals_included IN table_varchar,
        i_vals_excluded IN table_varchar DEFAULT NULL,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_error t_error_out;
    BEGIN
    
        RETURN get_values_domain(i_code_dom      => i_code_dom,
                                 i_lang          => i_lang,
                                 o_data          => o_data,
                                 o_error         => l_error,
                                 i_vals_included => i_vals_included,
                                 i_vals_excluded => i_vals_excluded,
                                 i_domain_owner  => i_domain_owner);
        
    END get_values_domain;

    FUNCTION get_values_domain
    (
        i_code_dom        IN sys_domain.code_domain%TYPE,
        i_lang            IN sys_domain.id_language%TYPE,
        o_data_grid_color OUT pk_types.cursor_type,
        o_error           OUT t_error_out,
        i_domain_owner    IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN get_values_domain(i_code_dom      => i_code_dom,
                                 i_lang          => i_lang,
                                 o_data          => o_data_grid_color,
                                 o_error         => o_error,
                                 i_vals_included => NULL,
                                 i_vals_excluded => NULL,
                                 i_domain_owner  => i_domain_owner);
    
    END get_values_domain;

    FUNCTION get_values_domain
    (
        i_code_dom        IN sys_domain.code_domain%TYPE,
        i_lang            IN sys_domain.id_language%TYPE,
        o_data_grid_color OUT pk_types.cursor_type,
        i_domain_owner    IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN get_values_domain(i_code_dom      => i_code_dom,
                                 i_lang          => i_lang,
                                 o_data          => o_data_grid_color,
                                 i_vals_included => NULL,
                                 i_vals_excluded => NULL,
                                 i_domain_owner  => i_domain_owner);
        
    END get_values_domain;

        /******************************************************************************
           OBJECTIVO:   Retornar rank de um valor do domínio
           PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitido o valor
                       I_CODE_DOM - código do domínio
                     I_VAL - valor do domínio
                  Saida:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/02
          NOTAS:
        *********************************************************************************/
    FUNCTION get_domain_record
    (
        i_lang         IN NUMBER,
        i_mode         IN VARCHAR2,
        i_crit         IN VARCHAR2,
        i_code_dom     IN VARCHAR2,
        i_domain_owner IN VARCHAR2
    ) RETURN table_varchar IS
        tbl_dmn table_varchar;
    BEGIN
    
        SELECT dmn_value
          BULK COLLECT
          INTO tbl_dmn
          FROM (SELECT CASE
                            WHEN val = i_crit
                                 AND i_mode = k_mode_dmn_rank_per_val THEN
                             to_char(rank)
                            WHEN desc_val = i_crit
                                 AND i_mode = k_mode_dmn_val_per_desc_val THEN
                             val
                            WHEN val = i_crit
                                 AND i_mode = k_mode_dmn_img_per_desc_val THEN
                             img_name
                        END dmn_value
                  FROM (SELECT sd.rank, sd.val, img_name, desc_val
            FROM sys_domain sd
           WHERE sd.code_domain = i_code_dom
             AND sd.domain_owner = i_domain_owner
             AND sd.id_language = i_lang
                           AND sd.flg_available = k_yes
                           AND rownum > 0)) xmain
         WHERE dmn_value IS NOT NULL;
    
        RETURN tbl_dmn;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_domain_record;

    FUNCTION get_rank
    (
        i_lang         IN sys_domain.id_language%TYPE,
        i_code_dom     IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.rank%TYPE IS
        l_return sys_domain.rank%TYPE;
        tbl_rank table_varchar;
    BEGIN
    
        tbl_rank := get_domain_record(i_lang         => i_lang,
                                      i_mode         => k_mode_dmn_rank_per_val,
                                      i_crit         => i_val,
                                      i_code_dom     => i_code_dom,
                                      i_domain_owner => i_domain_owner);
    
        l_return := to_number(get_first_row_v(tbl_rank));
    
        RETURN l_return;
    
    END get_rank;

        /******************************************************************************
           OBJECTIVO:   Retornar o valor de um descritivo do domínio
           PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitido o valor
                       I_CODE_DOM - código do domínio
                     I_VAL - descritivo do domínio
                  Saida:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/03/02
          NOTAS:
        *********************************************************************************/
    FUNCTION get_value
    (
        i_lang         IN sys_domain.id_language%TYPE,
        i_code_dom     IN sys_domain.code_domain%TYPE,
        i_desc         IN sys_domain.desc_val%TYPE,
        o_error        OUT t_error_out,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.val%TYPE IS
        l_return  sys_domain.val%TYPE;
        tbl_value table_varchar;
    BEGIN
    
        tbl_value := get_domain_record(i_lang         => i_lang,
                                       i_mode         => k_mode_dmn_val_per_desc_val,
                                       i_crit         => i_desc,
                                       i_code_dom     => i_code_dom,
                                       i_domain_owner => i_domain_owner);
    
        l_return := get_first_row_v(tbl_value);
    
        RETURN l_return;
    
    END get_value;

        /******************************************************************************
           OBJECTIVO:   Retornar nome da imagem de um valor do domínio
           PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitido o valor
                       I_CODE_DOM - código do domínio
                     I_VAL - valor do domínio
                  Saida:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/07
          NOTAS:
        *********************************************************************************/
    FUNCTION get_img
    (
        i_lang         IN sys_domain.id_language%TYPE,
        i_code_dom     IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.img_name%TYPE IS
        l_return sys_domain.img_name%TYPE;
        tbl_img  table_varchar;
    BEGIN
    
        tbl_img := get_domain_record(i_lang         => i_lang,
                                     i_mode         => k_mode_dmn_img_per_desc_val,
                                     i_crit         => i_val,
                                     i_code_dom     => i_code_dom,
                                     i_domain_owner => i_domain_owner);
    
        l_return := get_first_row_v(tbl_img);
    
        RETURN l_return;
    
    END get_img;

        /******************************************************************************
           OBJECTIVO:   Retornar o rank e descritivo de SYS_DOMAIN de forma a permitir fazer ordenações por icon  
           PARAMETROS:  Entrada: I_LANG - Língua
                       I_CODE_DOM - Código do domínio
                     I_VAL - valor do domínio
                  Saida: <rank><img_name> 
        
          CRIAÇÃO: LG 2006-09-19 
          NOTAS:
        *********************************************************************************/
    FUNCTION get_ranked_img
    (
        i_code_dom     IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_val_dom VARCHAR2(300 CHAR);
        l_img     sys_domain.img_name%TYPE;
        l_rank    sys_domain.rank%TYPE;
    BEGIN
    
        l_img  := get_img(i_lang => i_lang, i_code_dom => i_code_dom, i_val => i_val, i_domain_owner => i_domain_owner);
        l_rank := get_rank(i_lang => i_lang, i_code_dom => i_code_dom, i_val => i_val, i_domain_owner => i_domain_owner);
    
        l_val_dom := lpad(to_char(l_rank), 6, '0') || l_img;
    
        RETURN l_val_dom;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ranked_img;

    /**
    * Gets sys_domains info about a code domain. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursur with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   19-09-2006 
    */
    FUNCTION get_domains_base
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_mode        IN VARCHAR2,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_prof         IN profissional,
        
        o_domains     OUT pk_types.cursor_type,
        o_error        OUT t_error_out,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DOMAINS_NONE_OPTION';
		l_bool      boolean;
    BEGIN
    
        OPEN o_domains FOR
            SELECT val, desc_val, rank, img_name, img_name icon
              FROM sys_domain
             WHERE code_domain = i_code_domain
               AND domain_owner = i_domain_owner
               AND id_language = i_lang
               AND flg_available = k_yes
            UNION ALL
            SELECT '-1' val, sm.desc_message AS desc_val, -1 AS rank, sm.img_name, sm.img_name icon
              FROM sys_message sm
             WHERE sm.id_language = i_lang
               AND sm.code_message = g_none_option
               AND sm.flg_available = k_yes
               AND i_mode = k_mode_none_option_istrue
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_bool := process_error(i_lang     => i_lang,
                                    i_message  => g_error,
                                    i_function => k_func_name,
                                    o_error    => o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN l_bool;
    END get_domains_base;

    FUNCTION get_domains
    (
        i_lang         IN sys_domain.id_language%TYPE,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_prof         IN profissional,
        o_domains      OUT pk_types.cursor_type,
        o_error        OUT t_error_out,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
        l_bool := get_domains_base(i_lang         => i_lang, 
                                   i_mode         => k_mode_none_option_isfalse, 
                                   i_code_domain  => i_code_domain,
                                   i_prof         => i_prof, 
                                   o_domains      => o_domains,
                                   o_error        => o_error, 
                                   i_domain_owner => i_domain_owner);
    
        RETURN l_bool;
        
    END get_domains;

    /**
    * Gets sys_domains info about a code domain and includes a none option on top. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursur with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   24-jan-2007 
    */
    FUNCTION get_domains_none_option
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_prof         IN profissional,
        o_domains     OUT pk_types.cursor_type,
        o_error        OUT t_error_out,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := get_domains_base(i_lang         => i_lang,
                                   i_mode         => k_mode_none_option_istrue,
                                   i_code_domain  => i_code_domain,
                                   i_prof         => i_prof,
                                   o_domains      => o_domains,
                                   o_error        => o_error,
                                   i_domain_owner => nvl(i_domain_owner, k_default_schema));
    
        RETURN l_bool;
        
    END get_domains_none_option;

    /**
    * Gets sys_domain info about a code domain and value, but returns n.a. option if the value is null. 
    *
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_VAL  the domain value 
    * @param   I_LANG language associated to the request 
    *
    * @RETURN  The domain description ou the n.a. option if value is null 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   10-Abr-2007 
    */
    FUNCTION get_domain_na_option
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_domain_desc sys_domain.desc_val%TYPE;
    BEGIN
    
        IF (i_val IS NULL)
        THEN
            l_domain_desc := pk_message.get_message(i_lang, g_none_option);
        ELSE
            l_domain_desc := get_domain(i_code_dom     => i_code_dom,
                                        i_val          => i_val,
                                        i_lang         => i_lang,
                                        i_domain_owner => i_domain_owner);
        
        END IF;
    
        RETURN l_domain_desc;
    
    END get_domain_na_option;

    /**
    * Checks if a value is part of a domain.
    * Useful for server-side parameter validation
    *
    * @param i_code_domain the domain
    * @param i_val the value
    * @return true if ok, false otherwise
    */
    FUNCTION check_val_in_domain
    (
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_dom_cnt NUMBER(24);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_dom_cnt
          FROM sys_domain sd
         WHERE sd.code_domain = i_code_domain
           AND sd.domain_owner = i_domain_owner
           AND sd.val = i_val;
    
        RETURN(l_dom_cnt != 0);
    
    END check_val_in_domain;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for code_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_vals                   Element domain values separated by pipe (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_desc_domain_set
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_vals        IN VARCHAR2,
        i_delim_in    IN VARCHAR2 DEFAULT '|',
        i_delim_out    IN VARCHAR2 DEFAULT '; ',
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        k_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DESC_DOMAIN_SET';
        l_vals_tab  table_varchar2;
        l_descs_tab table_varchar;
    BEGIN
    
        g_error := 'REPLACE DELIMITER';
        l_vals_tab := pk_utils.str_split(i_vals, i_delim_in);
    
        g_error := 'GET ELEMENT DOMAIN_';
        SELECT sd.desc_val
          BULK COLLECT
          INTO l_descs_tab
          FROM sys_domain sd
         WHERE sd.flg_available = k_yes
           AND sd.domain_owner = i_domain_owner
           AND sd.code_domain = i_code_domain
           AND sd.val IN (SELECT /*+opt_estimate(table a rows=1)*/
                           column_value
                            FROM TABLE(l_vals_tab) a)
           AND sd.id_language = i_lang;
    
        g_error := 'CONCAT_TABLE';
        RETURN pk_utils.concat_table(i_tab => l_descs_tab, i_delim => i_delim_out, i_start_off => 1, i_length => -1);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(k_func_name, g_package_name, g_error, SQLERRM);
            RETURN NULL;
    END get_desc_domain_set;

    /**************************************************************************
    * Returns a cursor of sys_domain elements valid for a                     *
    * specific institution/software/dep_clin_serv                             *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    * @param o_data_mkt               Output cursor                           *                                                           
    * @param o_error                  Error object                            *                                                          
    *                                                                         *
    *                                                                         *                                                               
    * @return                         Returns boolean value                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/04/06                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data_mkt      OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_dep_clin_serv NUMBER(24);
		l_bool boolean;
    BEGIN
        g_error         := 'PREPARE DATA';
        l_dep_clin_serv := nvl(i_dep_clin_serv, 0);
    
        g_error := 'OPEN O_DATA_MKT';
        OPEN o_data_mkt FOR
            SELECT s.desc_val, s.val, s.img_name, s.rank
              FROM TABLE(get_values_domain_pipelined(i_lang, i_prof, i_code_dom, l_dep_clin_serv, i_domain_owner)) s;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
			l_bool := process_error(i_lang     => i_lang,
                                              i_message  => g_error,
                                              i_function => 'get_values_domain',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data_mkt);
            RETURN l_bool;
        
    END get_values_domain;

    /**************************************************************************
    * Returns a cursor of sys_domain elements valid for a                     *
    * specific institution/software/dep_clin_serv                             *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns Output cursor                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/04/25                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain_pipelined
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN t_coll_values_domain_mkt
        PIPELINED IS
    
        CURSOR c_sysdomain
        (
            l_id_market     IN market.id_market%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT
            --nvl(sdo.desc_val, sd.desc_val) desc_val, sd.val, sd.img_name, sdo.rank
             sd.desc_domain desc_val, sd.domain_value val, sd.img_name, sd.order_rank rank
              FROM TABLE(pk_sysdomain.get_tbl_domain(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_code          => i_code_dom,
                                                     i_dep_clin_serv => i_dep_clin_serv,
                                                     i_domain_owner  => i_domain_owner)) sd;
    
        rec_out         t_rec_values_domain_mkt;
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_market     market.id_market%TYPE;
    BEGIN
        g_error         := 'PREPARE DATA';
        l_dep_clin_serv := nvl(i_dep_clin_serv, 0);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        FOR rec IN c_sysdomain(l_id_market, l_dep_clin_serv)
        LOOP
            rec_out := t_rec_values_domain_mkt(rec.desc_val, rec.val, rec.img_name, rec.rank, i_code_dom);
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    
    END get_values_domain_pipelined;

    /**************************************************************************
    * Returns a sys_domain description for a specific val                     *
    * by institution/software/dep_clin_serv                                   *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_val                    Element domain value                    *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns sys_domain description          *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/05/27                              *                                                                
    **************************************************************************/
    FUNCTION get_domain
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_val           IN sys_domain.val%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_desc_val sys_domain.desc_val%TYPE;
        l_error    t_error_out;
        tbl_desc   table_varchar;
        l_bool     BOOLEAN;
    BEGIN
    
        SELECT s.desc_val
          BULK COLLECT
          INTO tbl_desc
          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, i_code_dom, NULL, i_domain_owner)) s
             WHERE s.val = i_val;
    
        IF tbl_desc.count > 0
        THEN
            l_desc_val := tbl_desc(1);
        ELSE
                l_desc_val := get_domain(i_code_dom => i_code_dom, i_val => i_val, i_lang => i_lang);
        END IF;
    
        RETURN l_desc_val;
    EXCEPTION
        WHEN OTHERS THEN
        
            l_bool := process_error(i_lang     => i_lang,
                                              i_message  => g_error,
                                              i_function => 'get_domain',
                                              o_error    => l_error);
            RETURN NULL;
    END get_domain;

    /**************************************************************************
    * Returns a domain_list_inst_soft description for a specific val          *
    * by marker/institution/software/dep_clin_serv                            *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_domain_list            Element domain                          *
    * @param i_val                    Element domain value                    *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns sys_domain description          *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2010/04/14                              *                                                                
    **************************************************************************/
    FUNCTION get_domain_list_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_domain_list   IN domain_list_inst_soft.domain_list%TYPE,
        i_val           IN domain_list_inst_soft.val%TYPE,
        i_dep_clin_serv IN domain_list_inst_soft.id_dep_clin_serv%TYPE,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2 IS
        l_desc_val pk_translation.t_desc_translation;
        tbl_desc   table_varchar := table_varchar();
        l_error    t_error_out;
    
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_market     market.id_market%TYPE;
        l_bool          BOOLEAN;
    BEGIN
        g_error         := 'PREPARE DATA';
        l_dep_clin_serv := nvl(i_dep_clin_serv, 0);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT pk_translation.get_translation(i_lang, code_domain_list)
          BULK COLLECT
          INTO tbl_desc
              FROM (SELECT dlis.code_domain_list,
                           rank() over(ORDER BY dlis.id_market DESC, dlis.id_institution DESC, dlis.id_software DESC, dlis.id_dep_clin_serv DESC NULLS LAST) origin_rank
                      FROM domain_list_inst_soft dlis
                     WHERE dlis.domain_list = i_domain_list
                       AND dlis.val = i_val
                   AND dlis.domain_owner = i_domain_owner
                       AND dlis.id_market IN (0, l_id_market)
                       AND dlis.id_institution IN (0, i_prof.institution)
                       AND dlis.id_software IN (0, i_prof.software)
                       AND dlis.id_dep_clin_serv IN (0, l_dep_clin_serv))
             WHERE origin_rank = 1;
    
        l_desc_val := get_first_row_v(tbl_desc);
    
        RETURN l_desc_val;
    EXCEPTION
        WHEN OTHERS THEN
            l_bool := process_error(i_lang     => i_lang,
                                              i_message  => g_error,
                                              i_function => 'get_domain_list_desc',
                                              o_error    => l_error);
            RETURN NULL;
    END get_domain_list_desc;

    /**************************************************************************
    * Returns a cursor of domain_list_inst_soft elements valid for a          *
    * specific market/institution/software/dep_clin_serv                      *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_domain_list            Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    * @param o_data                   Output cursor                           *                                                           
    * @param o_error                  Error object                            *                                                          
    *                                                                         *
    *                                                                         *                                                               
    * @return                         Returns boolean value                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2010/04/14                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_domain_list   IN domain_list_inst_soft.domain_list%TYPE,
        i_dep_clin_serv IN domain_list_inst_soft.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN IS
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_market     market.id_market%TYPE;
		l_bool          boolean;
    BEGIN
        g_error         := 'PREPARE DATA';
        l_dep_clin_serv := nvl(i_dep_clin_serv, 0);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'OPEN O_DATA_MKT';
        OPEN o_data FOR
            SELECT pk_translation.get_translation(i_lang, code_domain_list) desc_val, val, rank
              FROM (SELECT dlis.code_domain_list,
                           dlis.val,
                           dlis.rank,
                           rank() over(ORDER BY dlis.id_market DESC, dlis.id_institution DESC, dlis.id_software DESC, dlis.id_dep_clin_serv DESC NULLS LAST) origin_rank
                      FROM domain_list_inst_soft dlis
                     WHERE dlis.domain_list = i_domain_list
                       AND dlis.domain_owner = i_domain_owner
                       AND dlis.id_market IN (0, l_id_market)
                       AND dlis.id_institution IN (0, i_prof.institution)
                       AND dlis.id_software IN (0, i_prof.software)
                       AND dlis.id_dep_clin_serv IN (0, l_dep_clin_serv)
                       AND dlis.flg_available = pk_alert_constant.g_yes)
             WHERE origin_rank = 1
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
			l_bool := process_error(i_lang     => i_lang,
                                              i_message  => g_error,
                                              i_function => 'get_values_domain_list',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
        
            RETURN l_bool;
        
    END get_values_domain_list;

    FUNCTION upd_sys_domain
    (
        i_lang          IN language.id_language%TYPE,
        i_code_domain   IN sys_domain.code_domain%TYPE,
        i_desc_val      IN sys_domain.desc_val%TYPE,
        i_val           IN sys_domain.val%TYPE,
        i_rank          IN sys_domain.rank%TYPE DEFAULT NULL,
        i_img_name      IN sys_domain.img_name%TYPE DEFAULT NULL,
        i_flg_available IN sys_domain.flg_available%TYPE DEFAULT NULL,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN NUMBER IS
    BEGIN
    
        UPDATE sys_domain sd
           SET desc_val      = i_desc_val,
               rank          = coalesce(i_rank, 0),
               img_name      = i_img_name,
               flg_available = coalesce(i_flg_available, k_yes)
         WHERE sd.id_language = i_lang
           AND sd.code_domain = i_code_domain
           AND sd.domain_owner = i_domain_owner
           AND sd.val = i_val;
    
        RETURN SQL%ROWCOUNT;
    
    END upd_sys_domain;

    /*******************************************************************************
    * Merges a record into sys_domain table                                        *
    *                                                                              *     
    * %param i_lang              record language                                   *
    * %param i_code_domain       domain code                                       *
    * %param i_desc_val          description                                       *
    * %param i_val               flag value                                        *
    * %param i_rank              domain value rank                                 *
    * %param i_img_name          image name (optional)                             *
    * %param i_flg_available     flag that indicates availability (default = 'Y') *
    *******************************************************************************/
    PROCEDURE insert_into_sys_domain
    (
        i_lang          IN language.id_language%TYPE,
        i_code_domain   IN sys_domain.code_domain%TYPE,
        i_desc_val      IN sys_domain.desc_val%TYPE,
        i_val           IN sys_domain.val%TYPE,
        i_rank          IN sys_domain.rank%TYPE DEFAULT NULL,
        i_img_name      IN sys_domain.img_name%TYPE DEFAULT NULL,
        i_flg_available IN sys_domain.flg_available%TYPE DEFAULT NULL,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) IS
        l_count NUMBER(24);
    BEGIN
    
        l_count := upd_sys_domain(i_lang          => i_lang,
                                  i_code_domain   => i_code_domain,
                                  i_desc_val      => i_desc_val,
                                  i_val           => i_val,
                                  i_rank          => i_rank,
                                  i_img_name      => i_img_name,
                                  i_flg_available => i_flg_available,
                                  i_domain_owner  => i_domain_owner);
    
        IF l_count = 0
        THEN
        
            INSERT INTO sys_domain
                (domain_owner, code_domain, id_language, desc_val, val, rank, img_name, flg_available)
            VALUES
                (i_domain_owner,
                 i_code_domain,
                 i_lang,
                 i_desc_val,
                 i_val,
                 coalesce(i_rank, 0),
                 i_img_name,
                 coalesce(i_flg_available, k_yes));
        END IF;
    
    END insert_into_sys_domain;

    FUNCTION get_domain_values
    (
        i_lang         IN language.id_language%TYPE,
        i_mode         IN VARCHAR2 DEFAULT k_mode_domain_values_id,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
        
    ) RETURN table_varchar IS
        tbl_value  table_varchar;
        tbl_desc   table_varchar;
        tbl_return table_varchar;
    BEGIN
    
        SELECT desc_val, val
          BULK COLLECT
          INTO tbl_desc, tbl_value
          FROM sys_domain
         WHERE flg_available = k_yes
           AND code_domain = i_code_domain
           AND id_language = i_lang
         ORDER BY nvl(rank, 0), desc_val;
    
        CASE i_mode
            WHEN k_mode_domain_values_id THEN
                tbl_return := tbl_value;
            WHEN k_mode_domain_values_desc THEN
                tbl_return := tbl_desc;
            ELSE
                tbl_return := table_varchar();
        END CASE;
    
        RETURN tbl_return;
    
    END get_domain_values;

    FUNCTION get_domain_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN table_varchar IS
    BEGIN
        RETURN get_domain_values(i_lang => i_lang, i_mode => k_mode_domain_values_desc, i_code_domain => i_code_domain);
    END get_domain_desc;

    FUNCTION get_domain_val
    (
        i_lang         IN language.id_language%TYPE,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN table_varchar IS
    BEGIN
        RETURN get_domain_values(i_lang => i_lang, i_mode => k_mode_domain_values_id, i_code_domain => i_code_domain);
    END get_domain_val;

    --************************************
    /*
    FUNCTION get_tbl_domain
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_code IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        tbl_domain t_tbl_core_domain;
    BEGIN
    
        SELECT t_row_core_domain(sd.code_domain, sd.desc_val, sd.val, sd.rank, sd.img_name)
          BULK COLLECT
          INTO tbl_domain
          FROM sys_domain sd
         WHERE flg_available = k_yes
           AND code_domain = i_code
           AND id_language = i_lang
         ORDER BY nvl(rank, 0), desc_val;
    
        RETURN tbl_domain;
    
    END get_tbl_domain;
    */

    --************************************
    FUNCTION get_tbl_domain
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_code          IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN t_tbl_core_domain IS
        tbl_domain      t_tbl_core_domain;
        l_id_market     NUMBER;
        l_dep_clin_serv NUMBER;
    BEGIN
    
        l_id_market     := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_dep_clin_serv := i_dep_clin_serv;
    
        -- SELECT nvl(sdo.desc_val, sd.desc_val) desc_val, sd.val, sd.img_name, sdo.rank
        SELECT t_row_core_domain(sd.code_domain, nvl(sdo.desc_val, sd.desc_val), sd.val, sdo.rank, sd.img_name)
          BULK COLLECT
          INTO tbl_domain
          FROM sys_domain sd
          JOIN (SELECT MAX(aux.desc_val) desc_val,
                       aux.code_domain,
                       aux.val,
                       MAX(aux.rank) keep(dense_rank FIRST ORDER BY aux.origin DESC, aux.origin_rank) rank
                  FROM (SELECT sd.desc_val,
                               sd.code_domain,
                               sd.val,
                               sd.rank,
                               rank() over(ORDER BY sd.rank) origin_rank,
                               1 origin
                          FROM sys_domain sd
                         WHERE sd.code_domain = i_code
                           AND sd.domain_owner = i_domain_owner
                           AND sd.id_language = i_lang
                           AND NOT EXISTS (SELECT 1
                                  FROM sys_domain_mkt sdm
                                 WHERE sdm.code_domain = sd.code_domain
                                   AND sdm.domain_owner = i_domain_owner
                                   AND sdm.flg_action = pk_alert_constant.g_sdis_flag_add
                                   AND sdm.id_market IN (l_id_market, 0))
                           AND NOT EXISTS (SELECT 1
                                  FROM sys_domain_instit_soft_dcs sdis
                                 WHERE sdis.id_institution IN (i_prof.institution, 0)
                                   AND sdis.id_software IN (i_prof.software, 0)
                                   AND sdis.id_dep_clin_serv IN (l_dep_clin_serv, 0)
                                   AND sdis.domain_owner = i_domain_owner
                                   AND sdis.flg_action = pk_alert_constant.g_sdis_flag_add
                                   AND sdis.code_domain = sd.code_domain)
                        UNION ALL
                        SELECT NULL desc_val,
                               sdm.code_domain,
                               sdm.val,
                               sdm.rank_default rank,
                               rank() over(ORDER BY sdm.id_market DESC NULLS LAST) origin_rank,
                               2 origin
                          FROM sys_domain_mkt sdm
                         WHERE sdm.code_domain = i_code
                           AND sdm.domain_owner = i_domain_owner
                           AND sdm.flg_action = pk_alert_constant.g_sdm_flag_add
                           AND sdm.id_market IN (l_id_market, 0)
                           AND NOT EXISTS (SELECT 1
                                  FROM sys_domain_mkt sdm1
                                 WHERE sdm1.code_domain = sdm.code_domain
                                   AND sdm1.val = sdm.val
                                   AND sdm1.domain_owner = i_domain_owner
                                   AND sdm1.flg_action = pk_alert_constant.g_sdm_flag_rem
                                   AND sdm1.id_market IN (l_id_market, 0))
                           AND NOT EXISTS (SELECT 1
                                  FROM sys_domain_instit_soft_dcs sdis
                                 WHERE sdis.id_institution IN (i_prof.institution, 0)
                                   AND sdis.id_software IN (i_prof.software, 0)
                                   AND sdis.id_dep_clin_serv IN (l_dep_clin_serv, 0)
                                   AND sdis.domain_owner = i_domain_owner
                                   AND sdis.flg_action = pk_alert_constant.g_sdis_flag_rem
                                   AND sdis.code_domain = sdm.code_domain
                                   AND sdis.val = sdm.val)
                        UNION ALL
                        SELECT pk_translation.get_translation(i_lang, sdis.code_sdis) desc_val,
                               sdis.code_domain,
                               sdis.val,
                               sdis.rank,
                               rank() over(ORDER BY sdis.id_institution DESC, sdis.id_software DESC, sdis.id_dep_clin_serv DESC NULLS LAST) origin_rank,
                               3 origin
                          FROM sys_domain_instit_soft_dcs sdis
                         WHERE sdis.id_institution IN (i_prof.institution, 0)
                           AND sdis.id_software IN (i_prof.software, 0)
                           AND sdis.id_dep_clin_serv IN (l_dep_clin_serv, 0)
                           AND sdis.flg_action = pk_alert_constant.g_sdis_flag_add
                           AND sdis.domain_owner = i_domain_owner
                           AND sdis.code_domain = i_code) aux
                 GROUP BY aux.code_domain, aux.val) sdo
            ON (sdo.code_domain = sd.code_domain AND sdo.val = sd.val)
         WHERE sd.code_domain = i_code
           AND sd.domain_owner = i_domain_owner
           AND sd.id_language = i_lang
           AND sd.flg_available = k_yes
         ORDER BY sd.rank;
    
        RETURN tbl_domain;
    
    END get_tbl_domain;

    --************************************
    /*
    * Get content of given domain in multichoice data model
    *
    * @return content of given domain
    *
    * @author Carlos Ferreira
    * @version
    * @since 2019/04
    */
    FUNCTION get_tbl_domain_mc
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_code IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        tbl_domain t_tbl_core_domain;
    BEGIN
    
        SELECT t_row_core_domain(multi_option_column, desc_option, id_multichoice_option, rank, img_name)
          BULK COLLECT
          INTO tbl_domain
          FROM TABLE(pk_multichoice.tf_multichoice_options(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_multichoice_type => i_code));
    
        RETURN tbl_domain;
    
    END get_tbl_domain_mc;

    /*
    * Get content of given domain in sys_list data model
    *
    * @return content of given domain
    *
    * @author Carlos Ferreira
    * @version
    * @since 2019/04
    */
    FUNCTION get_tbl_domain_sl
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_code IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        tbl_domain t_tbl_core_domain;
    BEGIN
    
        SELECT t_row_core_domain(internal_name, desc_list, flg_context, rank, img_name)
          BULK COLLECT
          INTO tbl_domain
          FROM TABLE(pk_sys_list.tf_sys_list_values_int(i_lang => i_lang, i_prof => i_prof, i_internal_name => i_code));
    
        RETURN tbl_domain;
    
    END get_tbl_domain_sl;

    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar
    ) RETURN t_tbl_core_domain IS
        tbl_domain t_tbl_core_domain;
        tbl_total  t_tbl_core_domain := t_tbl_core_domain();
    
    BEGIN
    
        FOR i IN 1 .. i_flg_type.count
        LOOP
        
            CASE i_flg_type(i)
            
                WHEN k_multc_domain THEN
                    tbl_domain := pk_sysdomain.get_tbl_domain(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_code          => i_internal_name(i),
                                                              i_dep_clin_serv => NULL);
                WHEN k_multc_syslist THEN
                    tbl_domain := get_tbl_domain_sl(i_lang => i_lang, i_prof => i_prof, i_code => i_internal_name(i));
                WHEN k_multc_multichoice THEN
                    tbl_domain := get_tbl_domain_mc(i_lang => i_lang, i_prof => i_prof, i_code => i_internal_name(i));
                    /*
                    when k_multc_plsql then
                      tbl_domain := pk_dyn_form_domain.get_data(i_lang => i_lang, i_prof => i_prof, i_code => i_internal_name(i) );
                                */
                ELSE
                    tbl_domain := t_tbl_core_domain();
            END CASE;
        
            tbl_total := tbl_total MULTISET UNION ALL tbl_domain;
        
        END LOOP;
    
        RETURN tbl_total;
    
    END get_multichoice;

    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar,
        o_result        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        OPEN o_result FOR
            SELECT internal_name, desc_domain, domain_value, order_rank, img_name
              FROM TABLE(pk_sysdomain.get_multichoice(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_flg_type      => i_flg_type,
                                                      i_internal_name => i_internal_name))
             ORDER BY internal_name, order_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_bool := process_error(i_lang     => i_lang,
                                    i_message  => SQLERRM,
                                    i_function => 'GET_MULTICHOICE',
                                    o_error    => o_error);
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_multichoice;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);

END pk_sysdomain;
/
