/*-- Last Change Revision: $Rev: 2027369 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_message IS

    k_lf CONSTANT VARCHAR2(0010) := chr(10);

    /******************************************************************************
       OBJECTIVO:   Retornar um texto de SYS_MESSAGE, quando se dá entrada do código
              e da língua
       PARAMETROS:  Entrada: I_LANG - Língua
                   I_CODE_MESS - Código da mensagem
              Saida:
    
      CRIAÇÃO: CRS 2005/01/25
      NOTAS:
    **********************************************************************************/
    FUNCTION get_message
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN sys_message.code_message%TYPE
    ) RETURN VARCHAR2 IS
        l_mess sys_message.desc_message%TYPE;
    BEGIN
        l_mess := get_message(i_lang, profissional(0, 0, 0), i_code_mess);
        RETURN l_mess;
    END get_message;

    /******************************************************************************
       OBJECTIVO:   Retornar um texto de SYS_MESSAGE, quando se dá entrada do código
              e da língua
       PARAMETROS:  Entrada: I_LANG - Língua
               I_CODE_MESS - Código da mensagem
              Saida:   O_DESC_MESS - Descritivo da msg
    
      CRIAÇÃO: CRS 2005/01/25
      NOTAS:
    *********************************************************************************/
    FUNCTION get_message
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      profissional,
        i_code_mess IN sys_message.code_message%TYPE
    ) RETURN VARCHAR2 IS
        tbl_msg table_varchar;
        l_mess  sys_message.desc_message%TYPE;
        l_id_market NUMBER(24);
    BEGIN
    
        IF i_code_mess IS NOT NULL
        THEN
        
            l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            SELECT  /*+ index(sm SME_LANGCODE_UI) */
			desc_message BULK COLLECT
              INTO tbl_msg
                      FROM sys_message sm
                     WHERE sm.code_message = i_code_mess
                       AND sm.id_language = i_lang
                       AND sm.flg_available = g_yes
               AND sm.id_market IN (l_id_market, 0)
                       AND sm.id_institution IN (i_prof.institution, 0)
                       AND sm.id_software IN (i_prof.software, 0)
             ORDER BY sm.id_market DESC, sm.id_institution DESC, sm.id_software DESC;
        
            IF tbl_msg.count > 0
            THEN
                l_mess := tbl_msg(1);
            END IF;
        
        END IF;
    
        RETURN l_mess;
    
        --The exception was removed because it could cause loops and in case of error the calling function will trigger the error
    END get_message;

        /******************************************************************************
           OBJECTIVO:   Retornar um array de mensagens, correspondentes aos códigos 
                  do array de entrada 
           PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitida a mensagem 
                       I_CODE_MESG_ARR - Array de códigos de mensagens 
                  Saida:   
          
          CRIAÇÃO: CRS 2005/01/26 
          NOTAS: 
        *********************************************************************************/
    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN get_message_array(i_lang         => i_lang,
                                 i_code_msg_arr => i_code_msg_arr,
                                 i_prof         => profissional(0, 0, 0),
                                 o_desc_msg_arr => o_desc_msg_arr);
    
    END get_message_array;

        /******************************************************************************
           OBJECTIVO:   Retornar um array de mensagens, correspondentes aos códigos 
                  do array de entrada 
           PARAMETROS:  Entrada: I_LANG - Língua em que deve ser transmitida a mensagem 
                   I_CODE_MESG_ARR - Array de códigos de mensagens 
                  Saida:   
          
          CRIAÇÃO: CRS 2005/01/26 
          ALTERAÇÃO: SS 2005/12/12
          NOTAS: 
        *********************************************************************************/
    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        l_id_market NUMBER(24);
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        -- ORDER BY sm.id_market DESC, sm.id_institution DESC, sm.id_software DESC;
        --row_number() over(PARTITION BY sm.code_message ORDER BY sm.id_software DESC, sm.id_institution DESC) rn
        OPEN o_desc_msg_arr FOR
            SELECT code_message, desc_message, img_name
              FROM (SELECT sm.code_message,
                           sm.desc_message,
                           sm.img_name,
                           row_number() over(PARTITION BY sm.code_message ORDER BY sm.id_market DESC, sm.id_institution DESC, sm.id_software DESC) rn
                      FROM sys_message sm
                     WHERE sm.id_language = i_lang
                       AND sm.code_message IN (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
                                                t.column_value
                                                 FROM TABLE(i_code_msg_arr) t)
                       AND sm.flg_available = g_yes
                       AND sm.id_market IN (l_id_market, 0)
                       AND sm.id_software IN (i_prof.software, 0)
                       AND sm.id_institution IN (i_prof.institution, 0))
             WHERE rn <= 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_desc_msg_arr);
            pk_alert_exceptions.error_handling('GET_HELP_MESSAGE', 'PK_MESSAGE', g_error, SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_message_array;

    FUNCTION get_message_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_code_msg_arr        IN table_varchar,
        io_desc_msg_hashtable IN OUT NOCOPY pk_types.vc2_hash_table
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_message_array';
        l_cursor       pk_types.cursor_type;
        l_code_message table_varchar;
        l_desc_message table_varchar;
        l_img_name     table_varchar;
        l_limit        PLS_INTEGER := 1000;
        e_call_error EXCEPTION;
    BEGIN
        g_error := 'Init hash table';
        FOR i IN 1 .. i_code_msg_arr.count
        LOOP
            io_desc_msg_hashtable(i_code_msg_arr(i)) := NULL;
        END LOOP;
    
        g_error := 'Call pk_message.get_message_array';
        IF NOT get_message_array(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_code_msg_arr => i_code_msg_arr,
                                            o_desc_msg_arr => l_cursor)
        THEN
            RAISE e_call_error;
        END IF;
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_code_message, l_desc_message, l_img_name LIMIT l_limit;
            FOR idx IN 1 .. l_code_message.count
            LOOP
                io_desc_msg_hashtable(l_code_message(idx)) := l_desc_message(idx);
            END LOOP;
        
            EXIT WHEN l_code_message.count < l_limit;
        END LOOP;
        CLOSE l_cursor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(k_function_name, 'PK_MESSAGE', g_error, SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_message_array;

        /******************************************************************************
           OBJECTIVO: Retornar um texto de ajuda de SYS_MESSAGE, quando se dá entrada do código 
                  e da língua 
           PARAMETROS:  Entrada: I_LANG - Língua 
                       I_CODE_MESS - Código da mensagem
                  Saida: O_TITLE - título 
                     O_MESG - mensagem 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/08/11 
          NOTAS: 
        *********************************************************************************/
    FUNCTION get_help_message
    (
        i_lang        IN language.id_language%TYPE,
        i_code_mess   IN sys_message.code_message%TYPE,
        o_title       OUT VARCHAR2,
        o_mesg        OUT VARCHAR2,
        o_button_desc OUT VARCHAR2, -- LG 2007-Jan-26
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN get_help_message(i_lang        => i_lang,
                                i_code_mess   => i_code_mess,
                                i_prof        => profissional(0, 0, 0),
                                o_title       => o_title,
                                o_mesg        => o_mesg,
                                o_button_desc => o_button_desc,
                                o_error       => o_error);
    
    END get_help_message;

        /******************************************************************************
           OBJECTIVO: Retornar um texto de ajuda de SYS_MESSAGE, quando se dá entrada do código 
                  e da língua 
           PARAMETROS:  Entrada: I_LANG - Língua 
                   I_CODE_MESS - Código da mensagem
                  Saida: O_TITLE - título 
                     O_MESG - mensagem 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/08/11 
          ALTERAÇÃO: SS 2005/12/12
          NOTAS: 
        *********************************************************************************/
    FUNCTION get_help_message
    (
        i_lang        IN language.id_language%TYPE,
        i_code_mess   IN sys_message.code_message%TYPE,
        i_prof        IN profissional,
        o_title       OUT VARCHAR2,
        o_mesg        OUT VARCHAR2,
        o_button_desc OUT VARCHAR2, -- LG 2007-Jan-26
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --tbl_msg table_varchar;
        l_mesg VARCHAR2(4000);
    BEGIN
        g_error := 'GET TITLE';
        o_title := get_message(i_lang, i_prof, 'COMMON_T007');
    
        g_error       := 'GET BUTTON';
        o_button_desc := nvl(get_message(i_lang, 'HELP_T001'), 'HELP_T001');
    
        l_mesg := get_message(i_lang, i_prof, upper(i_code_mess));
        l_mesg := REPLACE(l_mesg, k_lf, k_lf || k_lf);
        o_mesg := nvl(l_mesg, i_code_mess);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MESSAGE',
                                              'GET_HELP_MESSAGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_help_message;

    /**
    * Formats message with the passed parameters in I_PARAMS.
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_MSG the message to format
    * @param I_PARAMS the parameters to format the message 
    * @param O_FORMATED_MSG The formated message
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   02-11-2006 
    */
    FUNCTION format
    (
        i_lang         IN language.id_language%TYPE,
        i_msg          IN sys_message.desc_message%TYPE,
        i_params       IN table_varchar,
        o_formated_msg OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg sys_message.desc_message%TYPE;
    BEGIN
        g_error        := 'FORMATING MESSAGE';
        l_msg   := i_msg;
        FOR i IN 1 .. i_params.count
        LOOP
            l_msg := REPLACE(l_msg, '@' || i, i_params(i));
        END LOOP;
    
        o_formated_msg := l_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_MESSAGE',
                                                     'FORMAT',
                                                     o_error);
    END format;

    /************************************************************************************
    * Merges a record into sys_message table                                            *
    *                                                                                   *
    * @param i_lang           record language                                           *     
    * @param i_code_message   message code                                              *
    * @param i_desc_message   description                                               *
    * @param i_flg_type       message type (optional)                                   *
    * @param i_software       software where the message is to be used (default = 0)    *
    * @param i_institution    institution where the message is to be used (default = 0) *
    * @param i_img_name       image name (optional)                                     *
    * @param i_id_sys_message message unique identifier (optional)                      *
    * @param i_module         module (optional)                                         * 
    * @param i_market         market (optional)                                         * 
    *                                                                                   *
    ************************************************************************************/
    PROCEDURE insert_into_sys_message
    (
        i_lang           language.id_language%TYPE,
        i_code_message   sys_message.code_message%TYPE,
        i_desc_message   sys_message.desc_message%TYPE,
        i_flg_type       sys_message.flg_type%TYPE DEFAULT NULL,
        i_software       software.id_software%TYPE DEFAULT 0,
        i_institution    institution.id_institution%TYPE DEFAULT 0,
        i_img_name       sys_message.img_name%TYPE DEFAULT NULL,
        i_id_sys_message sys_message.id_sys_message%TYPE DEFAULT NULL,
        i_module         sys_message.module%TYPE DEFAULT NULL,
        i_market         sys_message.id_market%TYPE DEFAULT 0
    ) IS
    BEGIN
        MERGE INTO sys_message t
        USING (SELECT i_code_message code_message, --
                      i_desc_message desc_message, --
                      i_flg_type flg_type,
                      i_lang id_language,
                      'Y' flg_available,
                      i_img_name img_name,
                      i_software id_software,
                      i_institution id_institution,
                      i_module module,
                      i_market id_market
                 FROM dual) args
        ON (t.id_language = args.id_language AND t.code_message = args.code_message --
        AND t.id_market = args.id_market AND t.id_institution = args.id_institution AND t.id_software = args.id_software)
        WHEN MATCHED THEN
            UPDATE
               SET t.desc_message = args.desc_message,
                   t.img_name     = nvl(args.img_name, t.img_name),
                   t.flg_type     = nvl(args.flg_type, t.flg_type),
                   t.module       = nvl(args.module, t.module)
        WHEN NOT MATCHED THEN
            INSERT
                (code_message,
                 desc_message,
                 flg_type,
                 id_language,
                 flg_available,
                 img_name,
                 id_sys_message,
                 id_software,
                 id_institution,
                 module,
                 id_market,
                 adw_last_update)
            VALUES
                (args.code_message,
                 args.desc_message,
                 coalesce(args.flg_type,
                          (SELECT flg_type
                             FROM (SELECT s.flg_type
                                     FROM sys_message s
                                    WHERE s.flg_type IS NOT NULL
                                      AND s.code_message = i_code_message
                                      AND s.id_software = i_software
                                      AND s.id_institution = i_institution
                                      AND s.id_market = i_market
                                    ORDER BY s.id_language ASC)
                            WHERE rownum < 2),
                          'A'),
                 args.id_language,
                 args.flg_available,
                 nvl(args.img_name,
                     (SELECT img_name
                        FROM (SELECT s.img_name
                                FROM sys_message s
                               WHERE s.img_name IS NOT NULL
                                 AND s.code_message = i_code_message
                                 AND s.id_software = i_software
                                 AND s.id_market = i_market
                                 AND s.id_institution = i_institution
                               ORDER BY s.id_language ASC)
                       WHERE rownum < 2)),
                 --se i_id_sys_message não é fornecido tem-se que colocar algo
                 nvl(i_id_sys_message, seq_sys_message.nextval),
                 args.id_software,
                 args.id_institution,
                 args.module,
                 args.id_market,
                 SYSDATE);
    END insert_into_sys_message;

END pk_message;
/