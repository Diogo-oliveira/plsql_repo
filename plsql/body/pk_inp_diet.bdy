/*-- Last Change Revision: $Rev: 2027248 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_diet AS

    FUNCTION get_diet_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_diet  IN diet.id_diet%TYPE,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar os vários tipos de dieta
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_DIET - ID da dieta.Para visualizar as sub dietas, este parâmetro tem que estar preenchido 
                          SAIDA: O_DIET - Lista dos tipos de dietas
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
        aux_sql   VARCHAR2(2000);
        aux_u_sql VARCHAR2(2000);
    
        --
    BEGIN
        aux_sql := 'SELECT ID_DIET,Pk_Translation.GET_TRANSLATION(' || i_lang || ', CODE_DIET) DESC_DIET, RANK' ||
                   ' FROM DIET' || ' WHERE FLG_AVAILABLE=''' || g_flg_available || '''' ||
                   ' AND ID_DIET_PARENT IS NULL' || ' UNION ' || 'SELECT -1 ID_DIET,Pk_Message.GET_MESSAGE(' || i_lang ||
                   ', ''OPINION_M007'') DESC_DIET ,-1 RANK' || ' FROM DUAL ' || ' ORDER BY RANK, DESC_DIET ASC';
    
        aux_u_sql := 'SELECT ID_DIET,Pk_Translation.GET_TRANSLATION(' || i_lang || ', CODE_DIET) DESC_DIET, RANK' ||
                     ' FROM DIET' || ' WHERE FLG_AVAILABLE=''' || g_flg_available || '''' || ' AND ID_DIET_PARENT = ' ||
                     i_diet || ' ORDER BY RANK, DESC_DIET ASC';
    
        --
        g_error := 'GET CURSOR O_DIET';
        --
        IF i_diet IS NOT NULL
        THEN
            OPEN o_diet FOR aux_u_sql;
        ELSE
            OPEN o_diet FOR aux_sql;
        END IF;
        --
        /*IF I_PATIENT IS NOT NULL THEN
          OPEN O_PATIENT FOR AUX_SQL || ' AND PAT.ID_PATIENT = '||I_PATIENT || ' ORDER BY EPIS.DT_BEGIN' ;
        ELSE
          OPEN O_PATIENT FOR AUX_SQL || ' ORDER BY EPIS.DT_BEGIN' ;
        END IF; */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_DIET_LIST',
                                                       o_error);
        
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
        
    END get_diet_list;

    FUNCTION get_diet_sched_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_diet_sched OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar os horários disponiveis para prescrever uma dieta
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 
                          SAIDA: O_DIET_SCHED - Listar os horários disponiveis para prescrever uma dieta
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR O_DIET_SCHED';
        OPEN o_diet_sched FOR
            SELECT id_diet_schedule val,
                   rank,
                   pk_translation.get_translation(i_lang, code_diet_schedule) desc_diet_sched
              FROM diet_schedule
             WHERE flg_available = g_flg_available
            UNION
            SELECT -1 val, -1 rank, pk_message.get_message(i_lang, 'OPINION_M001') desc_diet_sched
              FROM dual
             ORDER BY rank, desc_diet_sched ASC;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_DIET_SCHED_LIST',
                                                       o_error);
            pk_types.open_my_cursor(o_diet_sched);
            RETURN FALSE;
    END get_diet_sched_list;

    FUNCTION get_epis_diet_status_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar todos os estados de cada estado dos episódios de dieta
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 
                          SAIDA: O_STATUS - Listar todos os estados de cada estado dos episódios de dieta
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR O_STATUS';
        OPEN o_status FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_epis_diet_status
               AND flg_available = g_flg_available
             ORDER BY rank, desc_val;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EPIS_DIET_STATUS_LIST',
                                                       o_error);
        
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
        
    END get_epis_diet_status_list;

    FUNCTION create_epis_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN diet.id_diet%TYPE,
        i_epis_diet      IN epis_diet.id_epis_diet%TYPE,
        i_desc_diet      IN epis_diet.desc_diet%TYPE,
        i_notes          IN epis_diet.notes%TYPE,
        i_diet_schedule  IN diet_schedule.id_diet_schedule%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_flg_help       IN epis_diet.flg_help%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Registar os pedidos de dieta para um paciente
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPISODE - ID do episódio
                                 I_ID_DIET - ID da dieta
                                 I_EPIS_DIET - ID do episódio da dieta
                                 I_DESC_DIET - Outro tipo de dieta 
                                 I_NOTES  - Notas da dieta  
                                 I_ID_DIET_SCHEDULE - Horário da dieta 
                                 I_DT_INITIAL  - Data inicio 
                                 I_DT_END - Data fim 
                                 I_FLG_HELP - Necessidade de apoio ao doente: Y - Sim; N- Não
                                 
                          SAIDA: O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
        l_char       VARCHAR2(1);
        l_next       epis_diet.id_epis_diet%TYPE;
        l_epis_pos   epis_diet.id_epis_diet%TYPE;
        i_dt_initial TIMESTAMP WITH LOCAL TIME ZONE;
        i_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowids     table_varchar;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_episode
               AND flg_status = g_epis_active;
        --
        CURSOR c_epis_diet IS
            SELECT id_epis_diet
              FROM epis_diet
             WHERE id_episode = i_episode
               AND flg_status = g_diet_status_r;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        i_dt_initial := pk_date_utils.trunc_insttimezone(i_prof,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       i_dt_initial_str,
                                                                                       NULL),
                                                         'DD');
        i_dt_end     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_str, NULL);
    
        -- verificar se o episódio está activo
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
        --
        IF g_found
        THEN
            --
            IF i_epis_diet IS NOT NULL
            THEN
                -- cancelar a última receita 
                g_error := 'UPDATE EPIS_DIET (1)';
            
                UPDATE epis_diet
                   SET flg_status = g_diet_status_i, id_prof_inter = i_prof.id, dt_inter_tstz = g_sysdate_tstz
                 WHERE id_epis_diet = i_epis_diet;
            
            END IF;
            --
            g_error := 'GET CURSOR C_EPIS_DIET';
            OPEN c_epis_diet;
            FETCH c_epis_diet
                INTO l_epis_pos;
            g_found := c_epis_diet%FOUND;
            CLOSE c_epis_diet;
            --
            IF g_found
            THEN
                -- cancelar a última receita 
                g_error := 'UPDATE EPIS_DIET (2)';
                UPDATE epis_diet
                   SET flg_status = g_diet_status_c, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                 WHERE id_epis_diet = l_epis_pos;
            END IF;
            --
            g_error := 'GET SEQ_EPIS_DIET.NEXTVAL (G1)';
            SELECT seq_epis_diet.nextval
              INTO l_next
              FROM dual;
            --
            g_error := 'INSERT EPIS_DIET';
            /* <DENORM Fábio> */
            ts_epis_diet.ins(id_diet_in          => i_id_diet,
                             id_episode_in       => i_episode,
                             id_professional_in  => i_prof.id,
                             dt_creation_tstz_in => g_sysdate_tstz,
                             desc_diet_in        => i_desc_diet,
                             flg_status_in       => g_diet_status_r,
                             notes_in            => i_notes,
                             id_diet_schedule_in => i_diet_schedule,
                             dt_initial_tstz_in  => i_dt_initial,
                             dt_end_tstz_in      => i_dt_end,
                             flg_help_in         => i_flg_help,
                             rows_out            => l_rowids);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_DIET', l_rowids, o_error);
            g_error  := 'UPDATE EPIS_INFO';
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in => i_episode,
                             desc_info_in  => i_desc_diet,
                             desc_info_nin => FALSE,
                             rows_out      => l_rowids);
        
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_DIET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_epis_diet;

    FUNCTION set_epis_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_epis_diet  IN diet.id_diet%TYPE,
        i_notes      IN epis_diet.notes%TYPE,
        i_flg_status IN epis_diet.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Alterar as dietas prescritas a um paciente (Cancelar e interromper) 
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPISODE - ID do episódio
                                 I_EPIS_DIET - ID do episódio da dieta
                                 I_NOTES  - Notas ao cancelar/interromper uma dieta
                                 I_FLG_STATUS - Status do episódio da dieta: C - Cancelar
                                                                             I - Interromper 
                                 
                          SAIDA: O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
    
        l_count NUMBER;
        --
        CURSOR c_epis_diet IS
            SELECT 'X'
              FROM epis_diet
             WHERE id_epis_diet = i_epis_diet
               AND flg_status = g_diet_status_r;
        --    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se o episódio da dieta está requisitado
        g_error := 'GET CURSOR C_EPIS_DIET';
        SELECT COUNT(id_epis_diet)
          INTO l_count
          FROM epis_diet
         WHERE id_epis_diet = i_epis_diet
           AND flg_status = g_diet_status_r;
        --    
    
        --
        IF l_count > 0
        THEN
            IF i_flg_status = g_diet_status_c
            THEN
                -- cancelar episódio da dieta 
                g_error := 'UPDATE EPIS_DIET - C';
                --
                UPDATE epis_diet
                   SET dt_cancel_tstz = g_sysdate_tstz,
                       flg_status     = i_flg_status,
                       id_prof_cancel = i_prof.id,
                       notes_cancel   = i_notes
                 WHERE id_epis_diet = i_epis_diet;
            
            ELSIF i_flg_status = g_diet_status_i
            THEN
                -- interromper episódio da dieta
                g_error := 'UPDATE EPIS_DIET - I';
                --
                UPDATE epis_diet
                   SET flg_status    = i_flg_status,
                       id_prof_inter = i_prof.id,
                       dt_inter_tstz = g_sysdate_tstz,
                       notes_inter   = i_notes
                 WHERE id_epis_diet = i_epis_diet;
            END IF;
        END IF;
        --      
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_DIET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_diet;

    FUNCTION get_epis_diet
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar todas as dietas prescritas ao paciente(epiósodio)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPISODE - ID do episódio
                                 
                          SAIDA: O_EPIS_DIET - Listar as dietas prescritas para um dado episódio
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
        --
    BEGIN
        g_error := 'GET CURSOR O_EPIS_DIET';
        OPEN o_epis_diet FOR
            SELECT ed.id_epis_diet,
                   ed.id_diet,
                   d.id_diet_parent,
                   ed.flg_status,
                   nvl(pk_translation.get_translation(i_lang, d.code_diet), ed.desc_diet) desc_diet,
                   decode(ed.flg_status,
                          g_diet_status_r,
                          pk_message.get_message(i_lang, 'DIET_M001'),
                          g_diet_status_c,
                          pk_message.get_message(i_lang, 'DIET_M002'),
                          pk_message.get_message(i_lang, 'DIET_M003')) diet_status,
                   decode(ed.notes, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                   decode(ed.notes_inter, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_inter,
                   decode(ed.notes_cancel, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M017')) title_cancel,
                   pk_sysdomain.get_domain(g_yes_no, ed.flg_help, i_lang) desc_help,
                   pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_schedule
              FROM epis_diet ed, diet d, diet_schedule ds
             WHERE ed.id_episode = i_episode
               AND ed.id_diet = d.id_diet(+)
               AND ds.id_diet_schedule(+) = ed.id_diet_schedule
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_DIET.FLG_STATUS', ed.flg_status), ed.id_epis_diet DESC;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EPIS_DIET',
                                                       o_error);
            pk_types.open_my_cursor(o_epis_diet);
            RETURN FALSE;
    END get_epis_diet;

    FUNCTION get_epis_diet_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_diet IN epis_diet.id_epis_diet%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar o detalhe do episódio da dieta
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_DIET - ID do episódio da dieta
                                 
                          SAIDA: O_EPIS_DIET - Listar o detalhe do episódio da dieta
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR O_EPIS_DIET';
        OPEN o_epis_diet FOR
            SELECT ed.id_epis_diet,
                   ed.id_diet,
                   nvl(pk_translation.get_translation(i_lang, d.code_diet), ed.desc_diet) desc_diet,
                   decode(ed.flg_status,
                          g_diet_status_r,
                          pk_message.get_message(i_lang, 'DIET_M001'),
                          g_diet_status_c,
                          pk_message.get_message(i_lang, 'DIET_M002'),
                          pk_message.get_message(i_lang, 'DIET_M003')) diet_status,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_initial_tstz, i_prof) date_target_ini,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_end_tstz, i_prof) date_target_end,
                   pk_sysdomain.get_domain(g_yes_no, ed.flg_help, i_lang) desc_help,
                   p.nick_name name_prof,
                   pc.nick_name name_prof_c,
                   pi.nick_name name_prof_i,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_creation_tstz, i_prof) date_target_r,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target_r,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_cancel_tstz, i_prof) date_target_c,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_c,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_inter_tstz, i_prof) date_target_i,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_inter_tstz, i_prof.institution, i_prof.software) hour_target_i,
                   ed.notes notes,
                   decode(ed.flg_status, g_diet_status_i, ed.notes_inter, g_diet_status_c, ed.notes_cancel) notes_end,
                   pk_message.get_message(i_lang, 'DIET_M007') title_notes,
                   decode(ed.flg_status,
                          g_diet_status_i,
                          pk_message.get_message(i_lang, 'DIET_M011'),
                          g_diet_status_c,
                          pk_message.get_message(i_lang, 'DIET_M008')) title_notes_end
              FROM epis_diet ed, diet d, professional p, professional pc, professional pi
             WHERE ed.id_epis_diet = i_epis_diet
               AND ed.id_diet = d.id_diet(+)
               AND p.id_professional(+) = ed.id_professional
               AND pc.id_professional(+) = ed.id_prof_cancel
               AND pi.id_professional(+) = ed.id_prof_inter
            
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_DIET.FLG_STATUS', ed.flg_status), ed.id_epis_diet DESC;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EPIS_DIET_DET',
                                                       o_error);
            pk_types.open_my_cursor(o_epis_diet);
            RETURN FALSE;
    END get_epis_diet_det;

    FUNCTION get_epis_diet_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diet      IN diet.id_diet%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listagem de todas as dietas, indicando a dieta do episódio.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_DIET - ID do episódio da dieta
                                 
                          SAIDA: O_EPIS_DIET - Listagem de todas as dietas, indicando a dieta do episódio.
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/14
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR O_EPIS_DIET';
        OPEN o_epis_diet FOR
            SELECT d.id_diet, pk_translation.get_translation(i_lang, d.code_diet) desc_diet, ed.id_diet diet_epis
              FROM diet d, epis_diet ed
             WHERE d.flg_available = g_flg_available
               AND ed.id_epis_diet = i_diet
               AND ed.id_diet(+) = d.id_diet;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EPIS_DIET_LIST',
                                                       o_error);
        
            pk_types.open_my_cursor(o_epis_diet);
            RETURN FALSE;
    END get_epis_diet_list;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
    g_flg_available := 'Y';
    --
    g_epis_active      := 'A';
    g_diet_status_r    := 'R';
    g_diet_status_i    := 'I';
    g_diet_status_c    := 'C';
    g_yes_no           := 'YES_NO';
    g_epis_diet_status := 'EPIS_DIET.FLG_STATUS';

END pk_inp_diet;
/
