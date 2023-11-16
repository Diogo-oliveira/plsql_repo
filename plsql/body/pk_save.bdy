/*-- Last Change Revision: $Rev: 2027648 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_save AS

    /******************************************************************************
    * Same as SET_TEMP_DEFINITIVE. Just for INTERNAL USE by database.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2009/01/09
    *
    ******************************************************************************/
    FUNCTION call_set_temp_definitive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_observ IS
            SELECT id_episode, id_epis_observation
              FROM epis_observation
             WHERE flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_obs_exam IS
            SELECT id_episode, id_epis_obs_exam
              FROM epis_obs_exam
             WHERE flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_complaint IS
            SELECT id_episode, id_epis_anamnesis
              FROM epis_anamnesis
             WHERE flg_type = 'C'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_anamnesis IS
            SELECT id_episode, id_epis_anamnesis
              FROM epis_anamnesis
             WHERE flg_type = 'A'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_p IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'P'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_d IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'D'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_a IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'A'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_l IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'L'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_s IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'S'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_recomend_b IS
            SELECT id_episode, id_epis_recomend
              FROM epis_recomend
             WHERE flg_type = 'B'
               AND flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        CURSOR c_nurse_disch IS
            SELECT id_episode, id_nurse_discharge
              FROM nurse_discharge
             WHERE flg_temp = g_flg_temp
               AND (id_episode = i_id_episode OR i_id_episode IS NULL);
    
        l_func_name VARCHAR2(30) := 'CALL_SET_TEMP_DEFINITIVE';
        l_rows      table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        --FLG_TEMP
        -- Actualiza registos temporários da tabela EPIS_OBSERVATION
        g_error := 'UPD EPIS_OBSERVATION';
        FOR r_observ IN c_observ
        LOOP
            UPDATE epis_observation
               SET flg_temp = g_flg_def
             WHERE id_epis_observation = r_observ.id_epis_observation;
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_OBS_EXAM
        g_error := 'UPD EPIS_OBS_EXAM';
        FOR r_obs_exam IN c_obs_exam
        LOOP
            UPDATE epis_obs_exam
               SET flg_temp = g_flg_def
             WHERE id_epis_obs_exam = r_obs_exam.id_epis_obs_exam;
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_ANAMNESIS
        g_error := 'UPD EPIS_ANAMNESIS';
        FOR r_complaint IN c_complaint
        LOOP
            ts_epis_anamnesis.upd(flg_temp_in          => g_flg_def,
                                  id_epis_anamnesis_in => r_complaint.id_epis_anamnesis,
                                  rows_out             => l_rows);
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_ANAMNESIS
        g_error := 'UPD EPIS_ANAMNESIS';
        FOR r_anamnesis IN c_anamnesis
        LOOP
            ts_epis_anamnesis.upd(flg_temp_in          => g_flg_def,
                                  id_epis_anamnesis_in => r_anamnesis.id_epis_anamnesis,
                                  rows_out             => l_rows);
        END LOOP;
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_TEMP'));
    
        l_rows := table_varchar();
        -- Actualiza registos temporários da tabela EPIS_RECOMEND
        g_error := 'UPD EPIS_RECOMEND P';
        FOR r_recomend_p IN c_recomend_p
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_p.id_epis_recomend,
                                 rows_out    => l_rows);
        
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_RECOMEND
        g_error := 'UPD EPIS_RECOMEND D';
        FOR r_recomend_d IN c_recomend_d
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_d.id_epis_recomend,
                                 rows_out    => l_rows);
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_RECOMEND
        g_error := 'UPD EPIS_RECOMEND A';
        FOR r_recomend_a IN c_recomend_a
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_a.id_epis_recomend,
                                 rows_out    => l_rows);
        END LOOP;
    
        -- Actualiza registos temporários da tabela EPIS_RECOMEND
        g_error := 'UPD EPIS_RECOMEND A';
        FOR r_recomend_l IN c_recomend_l
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_l.id_epis_recomend,
                                 rows_out    => l_rows);
        END LOOP;
    
        -- Progress notes (SOAP) subjective
        g_error := 'FOR c_recomend_s';
        FOR r_recomend_s IN c_recomend_s
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_s.id_epis_recomend,
                                 rows_out    => l_rows);
        END LOOP;
    
        -- Progress notes (SOAP) objective
        g_error := 'FOR c_recomend_b';
        FOR r_recomend_b IN c_recomend_b
        LOOP
            g_error := 'CALL ts_epis_recomend.upd';
            ts_epis_recomend.upd(flg_temp_in => g_flg_def,
                                 where_in    => ' id_epis_recomend = ' || r_recomend_b.id_epis_recomend,
                                 rows_out    => l_rows);
        
        END LOOP;
    
        --call process update for all rows updated for epis_recomend
        IF l_rows.count > 0
        THEN
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_RECOMEND',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_TEMP'));
        END IF;
    
        -- Actualiza registos temporários da tabela NURSE_DISCHARGE
        g_error := 'UPD NURSE_DISCHARGE';
        FOR r_nurse_disch IN c_nurse_disch
        LOOP
            UPDATE nurse_discharge
               SET flg_temp = g_flg_def
             WHERE id_nurse_discharge = r_nurse_disch.id_nurse_discharge;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END call_set_temp_definitive;

    /******************************************************************************
    * Alterar flags de registos Temporários (T) para Definitvos (D) para um determinado episódio
    * e determinado professional. Um profissional só pode passar para definitivos os temporários
    * que lhe pertençam.
    * Se o parâmetro I_ID_EPISODE não estiver preenchido, altera para todos os episódios do profissional.
    *
    * ALTER: não verificar por profissional. Ao passar para definitivos passa todos mesmo que
    * tenham sido registados por outro profissional. UPDATE para as tabelas EPIS_RECOMEND e NURSE_DISCHARGE.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  RB
    * @version                 0.1
    * @since                   2005/04/05
    *
    * @alter                   SS
    * @version                 0.2
    * @since                   2006/10/12
    *
    * @alter                   José Brito
    * @version                 0.3
    * @since                   2009/01/09
    *
    ******************************************************************************/
    FUNCTION set_temp_definitive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_err EXCEPTION;
        l_sysdate   TIMESTAMP WITH LOCAL TIME ZONE;
        l_func_name VARCHAR2(30) := 'SET_TEMP_DEFINITIVE';
    
    BEGIN
        l_sysdate := current_timestamp;
    
        g_error := 'CALL TO PK_SAVE.call_set_temp_definitive';
        IF NOT call_set_temp_definitive(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        o_error      => o_error)
        THEN
            RAISE l_err;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_sysdate,
                                      i_dt_first_obs        => l_sysdate,
                                      o_error               => o_error)
        THEN
            RAISE l_err;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_err THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_temp_definitive;

    --
    PROCEDURE set_temp_definitive IS
        /******************************************************************************
          OBJECTIVO: Procedimento para correr à noite, chamado por um job, para gravar
                como definitivos os registos temporários de todos os profissionais
          PARAMETROS:  Entrada:
                       Saida: 
        
         CRIAÇÃO: CRS 2006/02/24
         NOTAS:
        *******************************************************************************/
    
        l_rows  table_varchar := table_varchar();
        l_error t_error_out;
    BEGIN
        -- Actualiza registos temporários da tabela EPIS_OBSERVATION  
        g_error := 'UPD EPIS_OBSERVATION';
        UPDATE epis_observation
           SET flg_temp = g_flg_def
         WHERE flg_temp = g_flg_temp;
    
        -- Actualiza registos temporários da tabela EPIS_OBS_EXAM  
        g_error := 'UPD EPIS_OBS_EXAM';
        UPDATE epis_obs_exam
           SET flg_temp = g_flg_def
         WHERE flg_temp = g_flg_temp;
    
        -- Actualiza registos temporários da tabela EPIS_ANAMNESIS  
        g_error := 'UPD EPIS_ANAMENSIS';
        ts_epis_anamnesis.upd(flg_temp_in => g_flg_def,
                              where_in    => 'flg_temp = ''' || g_flg_temp || '''',
                              rows_out    => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => 1,
                                      i_prof         => profissional(0, 0, 0),
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => l_error,
                                      i_list_columns => table_varchar('FLG_TEMP'));
    
        COMMIT;
    END set_temp_definitive;

    FUNCTION check_temp_definitive
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_id       OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_exist    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verificar se os registos já passaram de temporários para definitivos 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                 I_FLG_TYPE - C: queixa 
                      A: anamnese 
                      O: exame físico 
                      P: recomendações ao doente,
                      D: recomendações a outro médico,
                                              N: alta de enfermagem
                                              V: notas de avaliação
           
                  Saida: O_ID: ID do último registo definitivo registado antes da passagem de temporários para definitivos
                 O_EXIST - Y: se já passaram a definitivos
                       N: caso contrário 
                 O_ERROR - erro 
          
          CRIAÇÃO: SS 2006/10/12 
          NOTAS: 
        *********************************************************************************/
    
        CURSOR c_anamn IS
            SELECT id_epis_anamnesis
              FROM epis_anamnesis
             WHERE flg_temp = g_flg_def
               AND id_episode = i_episode
               AND flg_type = i_flg_type;
    
        CURSOR c_observ IS
            SELECT id_epis_observation
              FROM epis_observation
             WHERE flg_temp = g_flg_def
               AND id_episode = i_episode;
    
        CURSOR c_recomend IS
            SELECT id_epis_recomend
              FROM epis_recomend
             WHERE flg_temp = g_flg_def
               AND id_episode = i_episode
               AND flg_type = i_flg_type;
    
        CURSOR c_recomend_a IS
            SELECT id_epis_recomend
              FROM epis_recomend
             WHERE flg_temp = g_flg_def
               AND id_episode = i_episode
               AND flg_type = 'A';
    
        CURSOR c_nurse_disch IS
            SELECT id_nurse_discharge
              FROM nurse_discharge
             WHERE flg_temp = g_flg_def
               AND id_episode = i_episode;
    
        l_func_name VARCHAR2(30) := 'CHECK_TEMP_DEFINITIVE';
    
    BEGIN
    
        g_error := 'I_FLG_TYPE';
    
        IF i_flg_type IN (g_complaint, g_anamnesis)
        THEN
            -- Queixa/história
            g_error := 'OPEN C_ANAMN';
            OPEN c_anamn;
            FETCH c_anamn
                INTO o_id;
            g_found := c_anamn%FOUND;
            CLOSE c_anamn;
        ELSIF i_flg_type = 'O'
        THEN
            --Exame físico
            g_error := 'OPEN C_OBSERV';
            OPEN c_observ;
            FETCH c_observ
                INTO o_id;
            g_found := c_observ%FOUND;
            CLOSE c_observ;
        ELSIF i_flg_type = 'N'
        THEN
            --Alta de enfermagem
            g_error := 'OPEN C_NURSE_DISCH';
            OPEN c_nurse_disch;
            FETCH c_nurse_disch
                INTO o_id;
            g_found := c_nurse_disch%FOUND;
            CLOSE c_nurse_disch;
        ELSIF i_flg_type = 'V'
        THEN
            --Avaliação
            g_error := 'OPEN C_RECOMEND_A';
            OPEN c_recomend_a;
            FETCH c_recomend_a
                INTO o_id;
            g_found := c_recomend_a%FOUND;
            CLOSE c_recomend_a;
        ELSE
            g_error := 'OPEN C_RECOMEND'; --avaliação, rec. ao doente, rec. a outro médico
            OPEN c_recomend;
            FETCH c_recomend
                INTO o_id;
            g_found := c_recomend%FOUND;
            CLOSE c_recomend;
        END IF;
    
        IF NOT g_found
        THEN
            o_exist := 'N';
        ELSE
            o_exist := 'Y';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END check_temp_definitive;

    FUNCTION get_exist_rec_temp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO:   Procura existência de registos Temporários  para um dado episódio e profissional. Se o parâmetro que indica qual o
                              profissional não estiver preechido, procura para todos.
                         Retorna os valores Y se existir algum e N se não existir
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_ID_EPISODE - ID do episódio
                            Saida:   O_MESSAGE - mensagem de aviso no caso de existirem temporários para o profissional/episódio
                         O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        v_id_epis_observation epis_observation.id_epis_observation%TYPE;
        v_id_epis_obs_exam    epis_obs_exam.id_epis_obs_exam%TYPE;
        v_id_epis_anamnesis   epis_anamnesis.id_epis_anamnesis%TYPE;
        l_func_name           VARCHAR2(30) := 'GET_EXIST_REC_TEMP';
    
        CURSOR c_obs IS
            SELECT id_episode
              FROM epis_observation
             WHERE (id_episode = i_id_episode OR i_id_episode IS NULL)
               AND flg_temp = g_flg_temp
               AND id_professional = i_prof.id;
    
        CURSOR c_obs_exam IS
            SELECT id_epis_obs_exam
              FROM epis_obs_exam
             WHERE (id_episode = i_id_episode OR i_id_episode IS NULL)
               AND flg_temp = g_flg_temp
               AND id_professional = i_prof.id;
    
        CURSOR c_anamnesys IS
            SELECT id_epis_anamnesis
              FROM epis_anamnesis
             WHERE (id_episode = i_id_episode OR i_id_episode IS NULL)
               AND flg_temp = g_flg_temp
               AND id_professional = i_prof.id;
    
    BEGIN
    
        --procura registos temporários na tabela EPIS_OBSERVATION
        OPEN c_obs;
        FETCH c_obs
            INTO v_id_epis_observation;
        g_found := c_obs%FOUND;
        CLOSE c_obs;
    
        --procura registos temporários na tabela EPIS_OBS_EXAM
        IF NOT g_found
        THEN
            OPEN c_obs_exam;
            FETCH c_obs_exam
                INTO v_id_epis_obs_exam;
            g_found := c_obs_exam%FOUND;
            CLOSE c_obs_exam;
        END IF;
    
        --procura registos temporários na tabela EPIS_ANAMNESIS
        IF NOT g_found
        THEN
            OPEN c_anamnesys;
            FETCH c_anamnesys
                INTO v_id_epis_anamnesis;
            g_found := c_anamnesys%FOUND;
            CLOSE c_anamnesys;
        END IF;
    
        IF g_found
        THEN
            o_message := pk_message.get_message(i_lang, 'COMMON_M011');
            RETURN g_found_true;
        ELSE
            RETURN g_found_false;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN g_found_false;
        
    END get_exist_rec_temp;

    FUNCTION check_exist_rec_temp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Procura existência de registos Temporários  para um dado episódio e profissional. Se o parâmetro que indica qual o
                              profissional não estiver preechido, procura para todos.
                         Retorna os valores Y se existir algum e N se não existir
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_ID_EPISODE - ID do episódio
                             I_PROF - ID do profissional
                            Saida:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/15
          NOTAS:
        *********************************************************************************/
        l_found NUMBER;
    BEGIN
    
        --procura registos temporários nas tabelas EPIS_OBSERVATION, EPIS_OBS_EXAM e EPIS_ANAMNESIS
        SELECT decode((SELECT 1
                        FROM dual
                       WHERE EXISTS (SELECT 0
                                FROM epis_observation
                               WHERE (id_episode = i_id_episode) -- or i_id_episode is null)
                                 AND flg_temp = g_flg_temp
                                 AND id_professional = i_prof)
                         AND EXISTS (SELECT id_epis_obs_exam
                                FROM epis_obs_exam
                               WHERE (id_episode = i_id_episode) -- or i_id_episode is null)
                                 AND flg_temp = g_flg_temp
                                 AND id_professional = i_prof)
                         AND EXISTS (SELECT id_epis_anamnesis
                                FROM epis_anamnesis
                               WHERE (id_episode = i_id_episode) -- or i_id_episode is null)
                                 AND flg_temp = g_flg_temp
                                 AND id_professional = i_prof)),
                      NULL,
                      0,
                      1)
          INTO l_found
          FROM dual;
    
        IF l_found = 1
        THEN
            RETURN g_found_true;
        ELSE
            RETURN g_found_false;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_found_false;
        
    END;

    FUNCTION get_exist_temp_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO:   Procura existência de registos Temporários para o profissional na EPIS_ANAMNESIS , para um dado episódio.
                               Retorna os valores Y se existir algum e N se não existir
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                           I_ID_EPISODE - ID do episódio
                         I_PROF - ID do profissional
                            Saida:   O_MESSAGE - mensagem de aviso no caso de existirem temporários para o profissional/episódio
                         O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        v_id_epis_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE;
        v_existe            VARCHAR2(1) := 'N';
        l_func_name         VARCHAR2(30) := 'GET_EXIST_TEMP_ANAMNESIS';
    
        CURSOR c_exist_temp IS
            SELECT id_epis_anamnesis
              FROM epis_anamnesis
             WHERE id_professional = i_prof.id
               AND (id_epis_anamnesis != i_id_epis_anamnesis OR i_id_epis_anamnesis IS NULL)
               AND flg_temp = g_flg_temp
               AND id_episode = i_id_episode
               AND flg_type = i_flg_type;
    
    BEGIN
    
        g_error := 'GET EXISTS TEMPORARY ANAMNESIS';
        --Valida se para o profissional já existe algum registo temporário
        OPEN c_exist_temp;
        FETCH c_exist_temp
            INTO v_id_epis_anamnesis;
        g_found := c_exist_temp%FOUND;
        CLOSE c_exist_temp;
        IF g_found
        THEN
            v_existe := g_found_true;
        END IF;
    
        RETURN v_existe;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN g_found_false;
    END;

    FUNCTION get_exist_temp_observation
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO:   Procura existência de registos Temporários para o profissional na EPIS_OBSERVATION , para um dado episódio.
                               Retorna os valores Y se existir algum e N se não existir
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                           I_ID_EPISODE - ID do episódio
                         I_PROF - ID do profissional
                            Saida:   O_MESSAGE - mensagem de aviso no caso de existirem temporários para o profissional/episódio
                         O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        v_id_epis_observation epis_observation.id_epis_observation%TYPE;
        v_existe              VARCHAR2(1) := g_found_false;
        l_func_name           VARCHAR2(30) := 'GET_EXIST_TEMP_OBSERVATION';
    
        CURSOR c_exist_temp IS
            SELECT id_epis_observation
              FROM epis_observation
             WHERE id_professional = i_prof.id
               AND flg_temp = g_flg_temp
               AND (id_epis_observation != i_id_epis_observation OR i_id_epis_observation IS NULL)
               AND id_episode = i_id_episode;
    
    BEGIN
    
        g_error := 'GET EXISTS TEMPORARY OBSERVATION';
        --Valida se para o profissional já existe algum registo temporário
        OPEN c_exist_temp;
        FETCH c_exist_temp
            INTO v_id_epis_observation;
        IF c_exist_temp%FOUND
        THEN
            v_existe := g_found_true;
        END IF;
        CLOSE c_exist_temp;
    
        RETURN v_existe;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN g_found_false;
    END;

    FUNCTION get_exist_temp_obs_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO:   Procura existência de registos Temporários para o profissional na EPIS_OBS_EXAM , para um dado episódio.
                               Retorna os valores Y se existir algum e N se não existir
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                           I_ID_EPISODE - ID do episódio
                         I_PROF - ID do profissional
                            Saida:   O_MESSAGE - mensagem de aviso no caso de existirem temporários para o profissional/episódio
                         O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        v_id_epis_obs_exam epis_obs_exam.id_epis_obs_exam%TYPE;
        v_existe           VARCHAR2(1) := g_found_false;
        l_func_name        VARCHAR2(30) := 'GET_EXIST_TEMP_OBS_EXAM';
    
        CURSOR c_exist_temp IS
            SELECT id_epis_obs_exam
              FROM epis_obs_exam
             WHERE id_professional = i_prof.id
               AND flg_temp = g_flg_temp
               AND id_episode = i_id_episode;
    
    BEGIN
    
        g_error := 'GET EXISTS TEMPORARY EPIS_OBS_EXAM';
        --Valida se para o profissional já existe algum registo temporário
        OPEN c_exist_temp;
        FETCH c_exist_temp
            INTO v_id_epis_obs_exam;
        IF c_exist_temp%FOUND
        THEN
            v_existe := g_found_true;
        END IF;
        CLOSE c_exist_temp;
    
        RETURN v_existe;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN g_found_false;
    END;

    FUNCTION upd_temp_epis_observation
    (
        i_lang             IN language.id_language%TYPE,
        i_epis_observation IN epis_observation%ROWTYPE,
        i_dt_str           IN VARCHAR2,
        i_prof             IN profissional,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Altera ou elimina registos temporários da tabela EPIS_OBSERVATION
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_EPIS_OBSERVATION - registo a apagar/alterar
                     I_DT - data de registo 
                     I_PROF - ID do profissional
                               Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05 
          NOTAS:
        *********************************************************************************/
        l_func_name VARCHAR2(30) := 'UPD_TEMP_EPIS_OBSERVATION';
    
    BEGIN
        --Verifica se os dados a actualizar estão preenchidos. Se não, apaga o registo, se sim, actualiza-o
        IF i_epis_observation.desc_epis_observation IS NULL
        THEN
            --o registo não está totalmente preenchido, logo será eliminado
            g_error := 'DEL EPIS_OBSERVATION';
            DELETE FROM epis_observation
             WHERE id_epis_observation = i_epis_observation.id_epis_observation
               AND flg_temp = g_flg_temp;
        ELSE
            g_error := 'UPD EPIS_OBSERVATION';
            UPDATE epis_observation
               SET desc_epis_observation    = i_epis_observation.desc_epis_observation,
                   dt_epis_observation_tstz = pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL)
             WHERE id_epis_observation = i_epis_observation.id_epis_observation
               AND flg_temp = g_flg_temp
               AND desc_epis_observation != i_epis_observation.desc_epis_observation;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION upd_flg_temp_epis_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Actualiza registo temporário para definitvo da tabela EPIS_OBSERVATION
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                               I_ID_EPIS_OBSERVATION - ID do registo a alterar
                               Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        l_func_name VARCHAR2(30) := 'UPD_FLG_TEMP_EPIS_OBS';
    BEGIN
    
        g_error := 'UPD EPIS_OBSERVATION';
    
        UPDATE epis_observation
           SET flg_temp = g_flg_def
         WHERE id_epis_observation = i_id_epis_observation
           AND flg_temp = g_flg_temp;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION upd_temp_epis_obs_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_obs_exam IN epis_obs_exam%ROWTYPE,
        i_dt_str        IN VARCHAR2,
        i_prof          IN profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Altera ou elimina registos temporários da tabela EPIS_OBSERVATION
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_EPIS_OBS_EXAM - registo a apagar/alterar
                     I_DT - data de registo 
                     I_PROF - ID do profissional
                               Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        l_func_name VARCHAR2(30) := 'UPD_TEMP_EPIS_OBS_EXAM';
    BEGIN
        --Verifica se os dados a actualizar estão preenchidos. Se não, apaga o registo, se sim, actualiza-o
        IF i_epis_obs_exam.desc_epis_obs_exam IS NULL
        THEN
            --o registo não está totalmente preenchido, logo será eliminado
            g_error := 'DEL EPIS_OBS_EXAM';
            DELETE FROM epis_obs_exam
             WHERE id_epis_obs_exam = i_epis_obs_exam.id_epis_obs_exam
               AND flg_temp = g_flg_temp;
        ELSE
            g_error := 'UPD EPIS_OBS_EXAM';
            UPDATE epis_obs_exam
               SET desc_epis_obs_exam    = i_epis_obs_exam.desc_epis_obs_exam,
                   dt_epis_obs_exam_tstz = pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL)
             WHERE id_epis_obs_exam = i_epis_obs_exam.id_epis_obs_exam
               AND flg_temp = g_flg_temp
               AND desc_epis_obs_exam != i_epis_obs_exam.desc_epis_obs_exam;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    FUNCTION upd_flg_temp_epis_obs_exam
    (
        i_lang             IN language.id_language%TYPE,
        i_id_epis_obs_exam IN epis_obs_exam.id_epis_obs_exam%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Actualiza registo temporário para definitvo da tabela EPIS_OBS_EXAM
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                               I_ID_EPIS_OBS_EXAM - ID do registo a alterar
                               Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        l_func_name VARCHAR2(30) := 'UPD_FLG_TEMP_EPIS_OBS_EXAM';
    BEGIN
    
        g_error := 'UPD EPIS_OBS_EXAM';
    
        UPDATE epis_obs_exam
           SET flg_temp = g_flg_def
         WHERE id_epis_obs_exam = i_id_epis_obs_exam
           AND flg_temp = g_flg_temp;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    FUNCTION upd_temp_epis_anamnesis
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_anamnesis IN epis_anamnesis%ROWTYPE,
        i_dt_str         IN VARCHAR2,
        i_prof           IN profissional,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Altera ou elimina registos temporários da tabela EPIS_ANAMNESIS
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                               I_EPIS_ANAMNESIS - registo a apagar/alterar
                     I_DT - data de registo 
                     I_PROF - ID do profissional
                        Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
    
        l_func_name      VARCHAR2(30) := 'UPD_TEMP_EPIS_ANAMNESIS';
        l_has_difference VARCHAR2(1 CHAR);
        l_rows           table_varchar := table_varchar();
    BEGIN
        --Verifica se os dados a actualizar estão preenchidos. Se não, apaga o registo, se sim, actualiza-o
        IF i_epis_anamnesis.desc_epis_anamnesis IS NULL
        THEN
            --o registo não está totalmente preenchido, logo será eliminado
            BEGIN
                g_error := 'Check if it is to delete';
                SELECT 1
                  INTO l_has_difference
                  FROM epis_anamnesis ea
                 WHERE id_epis_anamnesis = i_epis_anamnesis.id_epis_anamnesis
                   AND flg_temp = g_flg_temp;
            
                IF l_has_difference IS NOT NULL
                THEN
                    g_error := 'DEL EPIS_ANAMNESIS';
                    ts_epis_anamnesis.del(id_epis_anamnesis_in => i_epis_anamnesis.id_epis_anamnesis,
                                          rows_out             => l_rows);
                
                    g_error := 't_data_gov_mnt.process_delete ts_epis_anamnesis';
                    t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_ANAMNESIS',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            l_has_difference := NULL;
        ELSE
            BEGIN
                g_error := 'Check if it is to update';
                SELECT 1
                  INTO l_has_difference
                  FROM epis_anamnesis ea
                 WHERE id_epis_anamnesis = i_epis_anamnesis.id_epis_anamnesis
                   AND flg_temp = g_flg_temp
                   AND dbms_lob.compare(desc_epis_anamnesis, i_epis_anamnesis.desc_epis_anamnesis) != 0;
            
                IF l_has_difference IS NOT NULL
                THEN
                    g_error := 'UPD EPIS_ANAMNESIS';
                    ts_epis_anamnesis.upd(desc_epis_anamnesis_in    => i_epis_anamnesis.desc_epis_anamnesis,
                                          dt_epis_anamnesis_tstz_in => pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_str,
                                                                                                     NULL),
                                          id_epis_anamnesis_in      => i_epis_anamnesis.id_epis_anamnesis,
                                          rows_out                  => l_rows);
                
                    g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPIS_ANAMNESIS',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('DT_EPIS_ANAMNESIS_TSTZ',
                                                                                  'DESC_EPIS_ANAMNESIS'));
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    FUNCTION upd_flg_temp_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Actualiza registo temporário para definitvo da tabela EPIS_ANAMNESIS
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                               I_ID_EPIS_ANAMNESIS - ID do registo a alterar
                               Saida:   O_ERROR - erro
        
          CRIAÇÃO: RB 2005/04/05
          NOTAS:
        *********************************************************************************/
        l_func_name VARCHAR2(30) := 'UPD_FLG_TEMP_EPIS_ANAMNESIS';
        l_rows      table_varchar := table_varchar();
        l_error     t_error_out;
    BEGIN
    
        g_error := 'UPD EPIS_ANAMNESIS';
        ts_epis_anamnesis.upd(flg_temp_in => g_flg_def,
                              where_in    => 'id_epis_anamnesis = ' || i_id_epis_anamnesis || ' and flg_temp = ''' ||
                                             g_flg_temp || '''',
                              rows_out    => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => profissional(0, 0, 0),
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => l_error,
                                      i_list_columns => table_varchar('FLG_TEMP'));
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

--Construtor
BEGIN
    g_flg_temp    := 'T';
    g_flg_def     := 'D';
    g_found_true  := 'Y';
    g_found_false := 'N';

    g_complaint := 'C';
    g_anamnesis := 'A';

    pk_alertlog.who_am_i(g_package_owner, g_package_name);

END;
/
