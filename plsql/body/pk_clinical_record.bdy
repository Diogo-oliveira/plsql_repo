/*-- Last Change Revision: $Rev: 2026879 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_clinical_record IS

    FUNCTION create_clinical_rec_req
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN cli_rec_req.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof_req       IN profissional,
        i_dt_begin       IN VARCHAR2,
        i_notes          IN cli_rec_req.notes%TYPE,
        i_flg_time       IN cli_rec_req.flg_time%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_id_clin_record IN table_number,
        i_notes_det      IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Criar requisições de processos clínicos 
           PARAMETROS:  Entrada:  I_LANG - Língua registada como preferência do profissional 
                      I_EPISODE - ID do Episódio 
                      I_PATIENT - ID do doente 
                          I_PROF_REQ - Profissional que requisita 
                      I_DT_BEGIN - Data de início  
                      I_NOTES - Notas da requisição 
                      I_FLG_TIME - Realização: E - neste episódio; 
                                       N - próximo episódio; 
                                   B - entre episódios 
                          Por defeito, = E 
                      I_PROF_CAT_TYPE - Categoria do profissional 
                      I_ID_CLIN_RECORD - Array de IDs de registos clínicos 
                                   Não está a ser utilizado 
                      I_NOTES_DET - Array de notas de detalhe 
                              Não está a ser utilizado 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: RB 2005/05/25 
          CORRECÇÕES: CRS 2005/06/03 
          NOTAS: 
        *********************************************************************************/
        l_flg_cab_status cli_rec_req.flg_status%TYPE;
        l_flg_det_status cli_rec_req_det.flg_status%TYPE;
        l_prox_id        cli_rec_req.id_cli_rec_req%TYPE;
        l_error          VARCHAR2(2000);
        l_flg_time       cli_rec_req.flg_time%TYPE;
        l_id_clin_record cli_rec_req_det.id_clin_record%TYPE;
        l_dt_begin_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_char           VARCHAR2(1);
        str              VARCHAR2(100);
        str1             VARCHAR2(100);
    
        CURSOR c_clin_rec IS
            SELECT cr.id_clin_record
              FROM clin_record cr
             WHERE cr.id_patient = i_patient
               AND cr.id_institution = i_prof_req.institution;
    
        CURSOR c_req IS
            SELECT 'X'
              FROM cli_rec_req
             WHERE id_episode = i_episode
               AND flg_status NOT IN (g_cli_rec_canc, g_cli_rec_det_term);
    
        CURSOR c_grid IS
            SELECT 'X'
              FROM grid_task
             WHERE id_episode = i_episode;
        l_grid VARCHAR2(1);
    
    BEGIN
        g_sysdate_tstz  := current_timestamp;
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof_req, i_dt_begin, NULL);
        l_flg_time      := nvl(i_flg_time, g_flg_time_epis);
    
        g_error := 'OPEN C_REQ';
        OPEN c_req;
        FETCH c_req
            INTO l_char;
        g_found := c_req%FOUND;
        CLOSE c_req;
        IF g_found
        THEN
            raise_application_error(-20001, pk_message.get_message(i_lang, 'CLI_REC_M002'));
        END IF;
    
        g_error := 'SET STATUS';
        IF i_dt_begin IS NOT NULL
           OR i_flg_time != g_flg_time_epis
        THEN
            l_flg_cab_status := g_cli_rec_pend;
        ELSE
            l_flg_cab_status := g_cli_rec_req;
        END IF;
        l_flg_det_status := l_flg_cab_status;
    
        g_error := 'GET NEXT ID_CLI_REC_REQ';
        SELECT seq_cli_rec_req.nextval
          INTO l_prox_id
          FROM dual;
    
        g_error := 'INSERT CLI_REC_REQ';
        INSERT INTO cli_rec_req
            (id_cli_rec_req, dt_cli_rec_req_tstz, id_prof_req, id_episode, flg_status, notes, flg_time, dt_begin_tstz)
        VALUES
            (l_prox_id,
             g_sysdate_tstz,
             i_prof_req.id,
             i_episode,
             l_flg_cab_status,
             i_notes,
             l_flg_time,
             l_dt_begin_tstz);
    
        g_error := 'OPEN C_CLIN_REC';
        OPEN c_clin_rec;
        FETCH c_clin_rec
            INTO l_id_clin_record;
        g_found := c_clin_rec%NOTFOUND;
        CLOSE c_clin_rec;
        IF g_found
        THEN
            raise_application_error(-20001, pk_message.get_message(i_lang, 'COMMON_M001'));
        END IF;
    
        --  FOR I IN 1 .. I_ID_CLIN_RECORD.COUNT LOOP   
        g_error := 'INSERT CLI_REC_REQ_DET';
        INSERT INTO cli_rec_req_det
            (id_cli_rec_req_det, id_cli_rec_req, flg_status, id_clin_record)
        VALUES
            (seq_cli_rec_req_det.nextval, l_prox_id, l_flg_det_status, l_id_clin_record);
        --        I_ID_CLIN_RECORD(I), I_NOTES_DET(I));
        --  END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof_req,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'CALL TO PK_GRID.UPDATE_CLIN_REC_REQ_TASK';
        IF NOT pk_clinical_record.insert_clin_rec_req_task(i_lang          => i_lang,
                                                           i_episode       => i_episode,
                                                           i_prof          => i_prof_req,
                                                           i_prof_cat_type => i_prof_cat_type,
                                                           o_error         => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_RECORD',
                                              'CREATE_CLINICAL_REC_REQ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_cli_rec_req_det
    (
        i_lang               IN language.id_language%TYPE,
        i_id_cli_rec_req_det IN cli_rec_req_mov.id_cli_rec_req_det%TYPE,
        i_notes              IN cli_rec_req_mov.notes%TYPE,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Alterar o estado do movimento da requisição: 
                     em processamento => pronto para transporte 
                   pronto para transporte => em transporte 
                   em transporte => concluído 
           PARAMETROS:  Entrada:  I_LANG - Língua registada como preferência do profissional 
                        I_ID_CLI_REC_REQ_MOV - ID do movimento da requisição a alterar
                      I_NOTES - Notas 
                      I_PROF - prof q regista 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: RB 2005/05/27 
          CORRECÇÕES: CRS 2005/06/03 
          NOTAS: 
        *********************************************************************************/
        l_old_mov_status cli_rec_req_mov.flg_status%TYPE;
        l_new_mov_status cli_rec_req_mov.flg_status%TYPE;
        l_old_det_status cli_rec_req_det.flg_status%TYPE;
        l_new_det_status cli_rec_req_det.flg_status%TYPE;
        l_id             cli_rec_req_mov.id_cli_rec_req_mov%TYPE;
        l_new_cab_status cli_rec_req.flg_status%TYPE;
        l_id_cab         cli_rec_req.id_cli_rec_req%TYPE;
        l_error          VARCHAR2(2000);
        l_id_episode     cli_rec_req.id_episode%TYPE;
    
        CURSOR c_stat_mov IS
            SELECT flg_status, id_cli_rec_req_mov
              FROM cli_rec_req_mov
             WHERE id_cli_rec_req_det = i_id_cli_rec_req_det
               AND flg_status != g_cli_rec_mov_canc;
    
        /*CURSOR C_STAT_DET IS 
        SELECT FLG_STATUS, ID_CLI_REC_REQ
        FROM CLI_REC_REQ_DET 
        WHERE ID_CLI_REC_REQ_DET = I_ID_CLI_REC_REQ_DET;*/
    
        CURSOR c_stat_det IS
            SELECT crrd.flg_status, crrd.id_cli_rec_req, crr.id_episode
              FROM cli_rec_req_det crrd, cli_rec_req crr
             WHERE crrd.id_cli_rec_req_det = i_id_cli_rec_req_det
               AND crr.id_cli_rec_req = crrd.id_cli_rec_req;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_STAT_DET';
        OPEN c_stat_det;
        FETCH c_stat_det
            INTO l_old_det_status, l_id_cab, l_id_episode;
        g_found := c_stat_det%FOUND;
        CLOSE c_stat_det;
    
        IF l_old_det_status IN (g_cli_rec_det_canc, g_cli_rec_det_term)
        THEN
            raise_application_error(-20001,
                                    REPLACE(pk_message.get_message(i_lang, 'CLI_REC_M001'),
                                            '@1',
                                            pk_sysdomain.get_domain('CLI_REC_REQ_DET.FLG_STATUS',
                                                                    l_old_det_status,
                                                                    i_lang)));
        END IF;
    
        g_error := 'OPEN C_STAT_MOV';
        OPEN c_stat_mov;
        FETCH c_stat_mov
            INTO l_old_mov_status, l_id;
        g_found := c_stat_mov%FOUND;
        CLOSE c_stat_mov;
        l_new_det_status := g_cli_rec_det_exec;
        l_new_cab_status := g_cli_rec_exec;
    
        g_error := 'VALIDATE';
        IF g_found
        THEN
            -- Existe req ñ cancelada do proc clínico 
            g_error := 'GET NEW STATUS';
            IF l_old_mov_status = g_cli_rec_mov_exec
            THEN
                l_new_mov_status := g_cli_rec_mov_ppt;
            ELSIF l_old_mov_status = g_cli_rec_mov_ppt
            THEN
                l_new_mov_status := g_cli_rec_mov_trans;
            ELSIF l_old_mov_status = g_cli_rec_mov_trans
            THEN
                l_new_mov_status := g_cli_rec_mov_term;
                l_new_det_status := g_cli_rec_det_term;
                l_new_cab_status := g_cli_rec_term;
            END IF;
        
            g_error := 'UPDATE CLI_REC_REQ_MOV';
            UPDATE cli_rec_req_mov
               SET flg_status         = l_new_mov_status,
                   dt_req_transp_tstz = decode(l_new_mov_status, g_cli_rec_mov_ppt, g_sysdate_tstz, dt_req_transp_tstz),
                   id_prof_req_transp = decode(l_new_mov_status, g_cli_rec_mov_ppt, i_prof.id, id_prof_req_transp),
                   dt_begin_mov_tstz  = decode(l_new_mov_status, g_cli_rec_mov_trans, g_sysdate_tstz, dt_begin_mov_tstz),
                   id_prof_begin_mov  = decode(l_new_mov_status, g_cli_rec_mov_trans, i_prof.id, id_prof_begin_mov),
                   dt_end_mov_tstz    = decode(l_new_mov_status, g_cli_rec_mov_term, g_sysdate_tstz, dt_end_mov_tstz),
                   id_prof_end_mov    = decode(l_new_mov_status, g_cli_rec_mov_term, i_prof.id, id_prof_end_mov)
             WHERE id_cli_rec_req_mov = l_id;
        
        ELSE
            g_error := 'INSERT CLI_REC_REQ_MOV';
            INSERT INTO cli_rec_req_mov
                (id_cli_rec_req_mov, id_cli_rec_req_det, flg_status, notes, dt_get_file_tstz, id_prof_get_file)
            VALUES
                (seq_cli_rec_req_mov.nextval,
                 i_id_cli_rec_req_det,
                 g_cli_rec_mov_exec,
                 i_notes,
                 g_sysdate_tstz,
                 i_prof.id);
        END IF;
    
        g_error := 'UPDATE CLI_REC_REQ_DET';
        UPDATE cli_rec_req_det
           SET flg_status = l_new_det_status
         WHERE id_cli_rec_req_det = i_id_cli_rec_req_det;
    
        g_error := 'UPDATE CLI_REC_REQ';
        UPDATE cli_rec_req
           SET flg_status = l_new_cab_status
         WHERE id_cli_rec_req = l_id_cab
           AND flg_status != l_new_cab_status;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'CALL TO PK_CLINICAL_RECORD.UPDATE_CLIN_REC_REQ_TASK';
        IF NOT pk_clinical_record.update_clin_rec_req_task(i_lang          => i_lang,
                                                           i_episode       => l_id_episode,
                                                           i_prof          => i_prof,
                                                           i_prof_cat_type => NULL,
                                                           o_error         => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'CALL TO PK_GRID.DELETE_EPIS_GRID_TASK';
        IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => l_id_episode, o_error => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_RECORD',
                                              'SET_CLI_REC_REQ_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_cli_rec_req
    (
        i_lang               IN language.id_language%TYPE,
        i_id_cli_rec_req     IN cli_rec_req.id_cli_rec_req%TYPE,
        i_id_cli_rec_req_det IN cli_rec_req_det.id_cli_rec_req_det%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Alterar o estado da requisição:
                    pendente => requisitado 
           PARAMETROS:  Entrada:  I_LANG - Língua registada como preferência do profissional 
                I_ID_CLI_REC_REQ - ID da requisição a alterar 
                I_ID_CLI_REC_REQ_DET - ID do detalhe da requisição a alterar 
                I_PROF - prof. q regista  
                I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
                Saida:    O_ERROR - erro 
          
          CRIAÇÃO: AA 2005/09/27 
          NOTAS: 
        *********************************************************************************/
        l_old_flg_status cli_rec_req.flg_status%TYPE;
        l_req            cli_rec_req_det.id_cli_rec_req%TYPE;
        l_error          VARCHAR2(2000);
        l_episode        cli_rec_req.id_episode%TYPE;
    
        CURSOR c_stat IS
            SELECT crrd.flg_status, crrd.id_cli_rec_req, crr.id_episode
              FROM cli_rec_req_det crrd, cli_rec_req crr
             WHERE crrd.id_cli_rec_req = nvl(i_id_cli_rec_req, crrd.id_cli_rec_req)
               AND crrd.id_cli_rec_req_det = nvl(i_id_cli_rec_req_det, crrd.id_cli_rec_req_det)
               AND crr.id_cli_rec_req = crrd.id_cli_rec_req;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET OLD STATUS';
        OPEN c_stat;
        FETCH c_stat
            INTO l_old_flg_status, l_req, l_episode;
        g_found := c_stat%FOUND;
        CLOSE c_stat;
    
        IF l_old_flg_status IN (g_cli_rec_canc, g_cli_rec_exec)
        THEN
            raise_application_error(-20001,
                                    REPLACE(pk_message.get_message(i_lang, 'CLI_REC_M004'),
                                            '@1',
                                            pk_sysdomain.get_domain('CLI_REC_REQ.FLG_STATUS', l_old_flg_status, i_lang)));
        END IF;
    
        UPDATE cli_rec_req_det
           SET flg_status = g_cli_rec_det_req
         WHERE id_cli_rec_req = nvl(i_id_cli_rec_req, id_cli_rec_req)
           AND id_cli_rec_req_det = nvl(i_id_cli_rec_req_det, id_cli_rec_req_det);
    
        UPDATE cli_rec_req
           SET flg_status = g_cli_rec_req
         WHERE id_cli_rec_req = l_req;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'CALL TO PK_CLINICAL_RECORD.UPDATE_CLIN_REC_REQ_TASK';
        IF NOT pk_clinical_record.update_clin_rec_req_task(i_lang          => i_lang,
                                                           i_episode       => l_episode,
                                                           i_prof          => i_prof,
                                                           i_prof_cat_type => i_prof_cat_type,
                                                           o_error         => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        g_error := 'CALL TO PK_GRID.DELETE_EPIS_GRID_TASK';
        IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => l_episode, o_error => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_RECORD',
                                              'SET_CLI_REC_REQ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION insert_clin_rec_req_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar a coluna de requisições de proc.clinico da tabela GRID_TASK  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro 
          CRIAÇÃO: SS 2006/01/23  
          NOTAS:
        *********************************************************************************/
        CURSOR c_req IS
            SELECT s.rank,
                   c.dt_cli_rec_req_tstz,
                   c.flg_status,
                   (SELECT cm.flg_status
                      FROM cli_rec_req_mov cm
                     WHERE cm.id_cli_rec_req_det = cd.id_cli_rec_req_det) mov_stat, --CM.FLG_STATUS MOV_STAT, 
                   nvl(c.dt_begin_tstz, c.dt_cli_rec_req_tstz) dt_begin_tstz
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd
             WHERE c.id_episode = i_episode
               AND c.flg_status NOT IN (g_cli_rec_canc, g_cli_rec_term)
               AND c.flg_status = s.val
               AND s.code_domain = 'CLI_REC_REQ.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND cd.id_cli_rec_req = c.id_cli_rec_req
             ORDER BY rank;
    
        CURSOR c_transp IS
            SELECT s.rank, cm.dt_req_transp_tstz, cm.flg_status mov_stat
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd, cli_rec_req_mov cm
             WHERE c.id_episode = i_episode
               AND c.flg_status NOT IN (g_cli_rec_canc, g_cli_rec_term)
               AND cd.id_cli_rec_req = c.id_cli_rec_req
               AND cm.id_cli_rec_req_det = cd.id_cli_rec_req_det
               AND cm.flg_status IN (g_cli_rec_mov_ppt, g_cli_rec_mov_trans)
               AND cm.flg_status = s.val
               AND s.code_domain = 'CLI_REC_REQ_MOV.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = 'Y'
             ORDER BY rank;
    
        l_task          VARCHAR2(1);
        l_rank          sys_domain.rank%TYPE;
        l_dt_req_tstz   cli_rec_req.dt_cli_rec_req_tstz%TYPE;
        l_dt_begin_tstz cli_rec_req.dt_begin_tstz%TYPE;
        l_status        cli_rec_req.flg_status%TYPE;
        l_mov_stat      cli_rec_req_mov.flg_status%TYPE;
        l_out_r         VARCHAR2(100);
        l_out_t         VARCHAR2(100);
        l_elapsed_time  VARCHAR2(100);
        l_error         VARCHAR2(4000);
        l_grid_task     grid_task%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'OPEN C_REQ';
        OPEN c_req;
        FETCH c_req
            INTO l_rank, l_dt_req_tstz, l_dt_begin_tstz, l_status, l_mov_stat;
        g_found := c_req%FOUND;
        CLOSE c_req;
    
        g_error := 'GET L_OUT';
        IF g_found
        THEN
            IF l_status = g_cli_rec_exec
            THEN
                l_out_r := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                           pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            
            ELSE
                -- JS, 2007-09-08 - Timezone
                -- l_out_r := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS') || '|' ||
                l_out_r := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS TZR') || '|' ||
                           g_date || '|' || g_no_color;
            END IF;
        END IF;
    
        g_error := 'GET SHORTCUT';
        IF l_out_r IS NOT NULL
        THEN
            l_out_r := '0' || '|' || l_out_r;
        END IF;
    
        g_error := 'OPEN C_REQ';
        OPEN c_transp;
        FETCH c_transp
            INTO l_rank, l_dt_req_tstz, l_mov_stat;
        g_found := c_transp%FOUND;
        CLOSE c_transp;
    
        g_error := 'GET L_OUT';
        IF g_found
        THEN
            IF l_mov_stat = g_cli_rec_mov_ppt
            THEN
                -- JS, 2007-09-08 - Timezone
                -- l_out_t := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS') || '|' ||
                l_out_t := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS TZR') || '|' ||
                           g_date || '|' || g_no_color;
            ELSIF l_mov_stat = g_cli_rec_mov_trans
            THEN
                l_out_t := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                           pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            END IF;
        END IF;
    
        g_error := 'GET SHORTCUT';
        IF l_out_t IS NOT NULL
        THEN
            l_out_t := '0' || '|' || l_out_t;
        END IF;
    
        l_grid_task.id_episode      := i_episode;
        l_grid_task.clin_rec_req    := l_out_r;
        l_grid_task.clin_rec_transp := l_out_t;
    
        --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
        IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => l_grid_task, o_error => o_error)
        THEN
            g_error := l_error;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_RECORD',
                                              'INSERT_CLIN_REC_REQ_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION update_clin_rec_req_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar a coluna de requisições de proc.clinico da tabela GRID_TASK  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro 
          CRIAÇÃO: SS 2006/01/23  
          NOTAS:
        *********************************************************************************/
        CURSOR c_req IS
            SELECT s.rank,
                   c.dt_cli_rec_req_tstz,
                   c.flg_status,
                   (SELECT cm.flg_status
                      FROM cli_rec_req_mov cm
                     WHERE cm.id_cli_rec_req_det = cd.id_cli_rec_req_det) mov_stat, --CM.FLG_STATUS MOV_STAT, 
                   nvl(c.dt_begin_tstz, c.dt_cli_rec_req_tstz) dt_begin_tstz
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd --, CLI_REC_REQ_MOV CM
             WHERE c.id_episode = i_episode
               AND c.flg_status NOT IN (g_cli_rec_canc, g_cli_rec_term)
               AND c.flg_status = s.val
               AND s.code_domain = 'CLI_REC_REQ.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND cd.id_cli_rec_req = c.id_cli_rec_req
             ORDER BY rank;
    
        CURSOR c_transp IS
            SELECT s.rank, cm.dt_req_transp_tstz, cm.flg_status mov_stat
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd, cli_rec_req_mov cm
             WHERE c.id_episode = i_episode
               AND c.flg_status NOT IN (g_cli_rec_canc, g_cli_rec_term)
               AND cd.id_cli_rec_req = c.id_cli_rec_req
               AND cm.id_cli_rec_req_det = cd.id_cli_rec_req_det
               AND cm.flg_status IN (g_cli_rec_mov_ppt, g_cli_rec_mov_trans)
               AND cm.flg_status = s.val
               AND s.code_domain = 'CLI_REC_REQ_MOV.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
               AND s.flg_available = 'Y'
             ORDER BY rank;
    
        l_task          VARCHAR2(1);
        l_rank          sys_domain.rank%TYPE;
        l_dt_req_tstz   cli_rec_req.dt_cli_rec_req_tstz%TYPE;
        l_dt_begin_tstz cli_rec_req.dt_begin_tstz%TYPE;
        l_status        cli_rec_req.flg_status%TYPE;
        l_mov_stat      cli_rec_req_mov.flg_status%TYPE;
        l_out_r         VARCHAR2(100);
        l_out_t         VARCHAR2(100);
        l_elapsed_time  VARCHAR2(100);
        l_error         VARCHAR2(4000);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'OPEN C_REQ';
        OPEN c_req;
        FETCH c_req
            INTO l_rank, l_dt_req_tstz, l_dt_begin_tstz, l_status, l_mov_stat;
        g_found := c_req%FOUND;
        CLOSE c_req;
    
        g_error := 'GET L_OUT_R';
        IF g_found
        THEN
            IF l_status = g_cli_rec_exec
            THEN
                l_out_r := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                           pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            
            ELSE
                -- JS, 2007-09-08 - Timezone
                -- l_out_r := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS') || '|' ||
                l_out_r := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS TZR') || '|' ||
                           g_date || '|' || g_no_color;
            END IF;
        END IF;
    
        g_error := 'GET SHORTCUT';
        IF l_out_r IS NOT NULL
        THEN
            l_out_r := '0' || '|' || l_out_r;
        END IF;
    
        g_error := 'OPEN C_TRANSP';
        OPEN c_transp;
        FETCH c_transp
            INTO l_rank, l_dt_req_tstz, l_mov_stat;
        g_found := c_transp%FOUND;
        CLOSE c_transp;
    
        g_error := 'GET L_OUT_T';
        IF g_found
        THEN
            IF l_mov_stat = g_cli_rec_mov_ppt
            THEN
                -- JS, 2007-09-08 - Timezone
                -- l_out_t := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS') || '|' ||
                l_out_t := pk_date_utils.to_char_insttimezone(i_prof, l_dt_req_tstz, 'YYYYMMDDHH24MISS TZR') || '|' ||
                           g_date || '|' || g_no_color;
            ELSIF l_mov_stat = g_cli_rec_mov_trans
            THEN
                l_out_t := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                           pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            END IF;
        END IF;
    
        g_error := 'GET SHORTCUT';
        IF l_out_t IS NOT NULL
        THEN
            l_out_t := '0' || '|' || l_out_t;
        END IF;
    
        g_error := 'UPDATE GRID_TASK';
        UPDATE grid_task
           SET clin_rec_req = l_out_r, clin_rec_transp = l_out_t
         WHERE id_episode = i_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_RECORD',
                                              'UPDATE_CLIN_REC_REQ_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

BEGIN
    g_cli_rec_canc := 'C';
    g_cli_rec_pend := 'D';
    g_cli_rec_req  := 'R';
    g_cli_rec_exec := 'E';
    g_cli_rec_par  := 'P';
    g_cli_rec_term := 'F';

    g_cli_rec_det_canc := 'C';
    g_cli_rec_det_pend := 'D';
    g_cli_rec_det_req  := 'R';
    g_cli_rec_det_exec := 'E';
    g_cli_rec_det_par  := 'P';
    g_cli_rec_det_term := 'F';

    g_cli_rec_mov_exec  := 'E';
    g_cli_rec_mov_ppt   := 'O';
    g_cli_rec_mov_trans := 'T';
    g_cli_rec_mov_term  := 'F';
    g_cli_rec_mov_canc  := 'C';

    g_flg_time_epis := 'E';
    --G_FLG_TIME_NEXT   := 'N';

    g_icon     := 'I';
    g_date     := 'D';
    g_no_color := 'X';

END;
/
