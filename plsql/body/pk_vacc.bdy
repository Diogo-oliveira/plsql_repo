/*-- Last Change Revision: $Rev: 2027845 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_vacc IS

    g_exception EXCEPTION;

    /*---------------------------------------------------------------------------------------------
          Esta fun��o cria a mensagem de erro a ser retorna para o utilizador.
          %param i_lang L�ngua na qual a mensagem deve ser apresentada
          %param i_function_name Nome da fun��o onde ocorreu o erro
          %param i_package_error Indica��o do passo que provoucou o erro
          %param i_oracle_error_msg Erro retornado pelo Oracle
    
          %author OAntunes - orlando.antunes@mni.pt
          %version 2.3.6.
          %return TRUE se a fun��o termina com sucesso e FALSE caso contr�rio
    ---------------------------------------------------------------------------------------------*/
    FUNCTION build_error_msg
    (
        i_lang             IN language.id_language%TYPE,
        i_function_name    VARCHAR2,
        i_package_error    VARCHAR2,
        i_oracle_error_msg VARCHAR2
    ) RETURN VARCHAR2 IS
        l_error VARCHAR2(30000) := '';
    BEGIN
    
        l_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || i_function_name || ' / ' ||
                   i_package_error || ' / ' || i_oracle_error_msg;
        --log do erro
        pk_alertlog.log_error(i_function_name || ': ' || i_package_error || ' -- ' || i_oracle_error_msg,
                              g_package_name);
        RETURN l_error;
    END build_error_msg;

    FUNCTION get_gap_between_doses
    (
        i_lang   IN language.id_language%TYPE,
        i_n_dose IN vacc_dose.n_dose%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN NUMBER IS
        /******************************************************************************
           OBJECTIVO:   Retornar os intervalos das doses entre vacinas
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                       I_N_DOSE- Numero da dose
                       I_VACC - ID da vacina
                  Saida:   O_ERROR - erro
        
          CRIA��O: Teresa Coutinho
          ALTERA��O :Teresa Coutinho
          NOTAS:
        *********************************************************************************/
    
        CURSOR c_gap IS
            SELECT val_min
              FROM vacc_dose vd, TIME t
             WHERE vd.id_vacc = i_vacc
               AND vd.id_time = t.id_time
               AND vd.n_dose = i_n_dose;
    
        CURSOR c_gap1 IS
            SELECT val_min
              FROM vacc_dose vd, TIME t
             WHERE vd.id_vacc = i_vacc
               AND vd.id_time = t.id_time
               AND vd.n_dose = i_n_dose;
    
        l_stat NUMBER;
    BEGIN
        IF i_n_dose = 1
        THEN
            OPEN c_gap;
            FETCH c_gap
                INTO l_stat;
            CLOSE c_gap;
        
        ELSE
        
            OPEN c_gap1;
            FETCH c_gap1
                INTO l_stat;
            CLOSE c_gap1;
        END IF;
        RETURN l_stat;
    END;

    FUNCTION get_dose_age
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_datetake_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO:   Retorna a diferen�a entre a data de nascimento do paciente e a data de entrada, se a vacina tiver sido tomada
                        Retorna o tempo de atraso, ou o que falta, se ainda n�o tiver sido tomada
        
                        Se a diferenca < 36 ent�o retorna em meses, s nao em anos
           PARAMETROS:  ENTRADA: i_lang
                                 i_prof
                                 i_id_pat
                                 i_date
        
        
          CRIA��O: Rita Lopes 2007/07/26
          NOTAS:
        *********************************************************************************/
        CURSOR c_age IS
            SELECT get_age_recommend(i_lang, abs((CAST(i_datetake_tstz AS DATE) - pat1.dt_birth))), pat1.id_patient
            --get_age_recommend(i_lang, abs((i_datetake - pat1.dt_birth))), pat1.id_patient
              FROM patient pat1
             WHERE pat1.id_patient = i_id_pat
               AND pat1.flg_status != pk_alert_constant.g_inactive;
    
        l_patient patient.id_patient%TYPE;
    
        l_age_return VARCHAR2(20);
    
    BEGIN
    
        g_months_sign := pk_sysconfig.get_config('MONTHS_SIGN', i_prof);
        g_days_sign   := pk_sysconfig.get_config('DAYS_SIGN', i_prof);
    
        g_error := 'GET AGE';
        OPEN c_age;
        FETCH c_age
            INTO l_age_return, l_patient;
        CLOSE c_age;
    
        RETURN l_age_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_vacc_ndose
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN vacc.id_vacc%TYPE
    ) RETURN NUMBER IS
    
        /******************************************************************************
           OBJECTIVO:   Retorna o numero de doses de uma vacina
           PARAMETROS:  ENTRADA: i_lang
                                 i_vaccine
        
          CRIA��O: Rita Lopes 2007/07/26
          NOTAS:
        *********************************************************************************/
        CURSOR c_dose IS
            SELECT MAX(v.n_dose) n_dose
              FROM vacc_dose v
             WHERE v.id_vacc = i_vaccine;
    
        n_dose NUMBER;
    
    BEGIN
    
        IF i_vaccine IS NOT NULL
        THEN
            OPEN c_dose;
            FETCH c_dose
                INTO n_dose;
            CLOSE c_dose;
        
        END IF;
    
        RETURN n_dose;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /************************************************************************************************************
    * Retornar os medicamentos para a vacina escolhida
    *
    * @param      i_lang          L�ngua registada como prefer�ncia do profissional
    * @param      i_prof          ID do profissional
    * @param      i_vacc          ID do profissional
    * @param      i_orig          Origem (R - Relato, O - Outros)
    *
    * @param      o_vacc_med_ext  Lista dos medicamentos para a vacina
    * @param      o_error              error message
    *
    * @return     TRUE se a fun��o termina com sucesso e FALSE caso contr�rio
    * @author     Teresa Coutinho
    *
    * @version    0.1
    * @since      2007/07/31
    ***********************************************************************************************************/
    FUNCTION get_vacc_med_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_orig         IN VARCHAR2,
        o_vacc_med_ext OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
    BEGIN
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_vacc_med_ext);
            RETURN TRUE;
        END IF;
    
        g_error := 'GET CURSOR O_VACC_MED_EXT';
        IF i_orig IN (g_orig_r, g_orig_i)
        THEN
            -- a origem � um relato
            OPEN o_vacc_med_ext FOR
                SELECT data, label, med_descr, qt_dos_comp, id_unit_measure
                  FROM (SELECT mim.id_drug data,
                               pk_translation.get_translation(i_lang, v.code_vacc) || ' / ' || mim.med_descr || ' (' ||
                               mim.route_abrv || ')' label,
                               mim.med_descr,
                               mim.qt_dos_comp,
                               mim.id_unit_measure
                          FROM vacc v
                          JOIN vacc_group vg
                            ON vg.id_vacc = v.id_vacc
                           AND vg.id_vacc_type_group = l_vacc_type_group
                          JOIN vacc_group_soft_inst vgsi
                            ON vgsi.id_vacc_group = vg.id_vacc_group
                           AND vgsi.id_institution = i_prof.institution
                           AND vgsi.id_software = i_prof.software
                          JOIN vacc_dci vd
                            ON v.id_vacc = vd.id_vacc
                          JOIN mi_med mim
                            ON vd.id_dci = mim.dci_id
                           AND mim.vers = l_version
                           AND mim.flg_available = pk_alert_constant.g_yes
                         WHERE v.id_vacc = i_vacc
                        UNION ALL
                        SELECT '-1' data,
                               pk_message.get_message(i_lang, 'COMMON_M041') label,
                               NULL med_descr,
                               NULL qt_dos_comp,
                               NULL id_unit_measure
                          FROM dual)
                 ORDER BY med_descr;
            RETURN TRUE;
        ELSE
            OPEN o_vacc_med_ext FOR
                SELECT mim.id_drug data,
                       pk_translation.get_translation(i_lang, v.code_vacc) || ' / ' || mim.med_descr || ' (' ||
                       mim.route_abrv || ')' label,
                       mim.med_descr,
                       mim.qt_dos_comp,
                       mim.id_unit_measure
                  FROM vacc v
                  JOIN vacc_group vg
                    ON vg.id_vacc = v.id_vacc
                   AND vg.id_vacc_type_group = l_vacc_type_group
                  JOIN vacc_group_soft_inst vgsi
                    ON vgsi.id_vacc_group = vg.id_vacc_group
                   AND vgsi.id_institution = i_prof.institution
                   AND vgsi.id_software = i_prof.software
                  JOIN vacc_dci vd
                    ON v.id_vacc = vd.id_vacc
                  JOIN mi_med mim
                    ON vd.id_dci = mim.dci_id
                   AND mim.vers = l_version
                   AND mim.flg_available = pk_alert_constant.g_yes
                 WHERE v.id_vacc = i_vacc
                 ORDER BY mim.med_descr;
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_MED_EXT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_med_ext);
            RETURN FALSE;
    END get_vacc_med_ext;

    FUNCTION get_application_spot_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de TIPO DE LOCAIS DE ADMINSITRA��O NAS VACINAS
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                  Saida:   O_SCHEDULE - TIPO
                     O_ERROR - erro
        
          CRIA��O: Teresa Coutinho 2007/08/01
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'OPEN o_ap_spot';
        OPEN o_ap_spot FOR
            SELECT t.data, t.label, t.rank
              FROM (SELECT sd.val data, sd.desc_val label, sd.rank
                      FROM sys_domain sd
                     WHERE sd.id_language = i_lang
                       AND sd.code_domain = g_domain_application_spot
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.flg_available = pk_alert_constant.g_yes
                     ORDER BY sd.rank) t
            UNION ALL
            SELECT '-1' data, pk_message.get_message(i_lang, 'COMMON_M041') label, 0 rank
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_APPLICATION_SPOT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_ap_spot);
            RETURN FALSE;
    END;

    FUNCTION get_notes_advers_react_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de Reac��es adversas �s vacinas administradas
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                  Saida:   O_SCHEDULE - TIPO
                     O_ERROR - erro
        
          CRIA��O: Teresa Coutinho 2007/08/01
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_ap_spot FOR
            SELECT '-2' data, pk_message.get_message(i_lang, 'COMMON_M043') label, pk_alert_constant.g_active rank
              FROM dual
            UNION ALL
            SELECT val data, desc_val label, desc_val rank
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_notes_adv_react_list
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = pk_alert_constant.g_yes
            UNION ALL
            SELECT '-1' data, pk_message.get_message(i_lang, 'COMMON_M042') label, 'zzzzz' rank
              FROM dual
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_NOTES_ADVERS_REACT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_ap_spot);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    *  Criar prescri��es de medicamentos (vacinas)
    *
    * @param i_lang                   the id language
    * @param i_episode                id_do epis�dio
    * @param i_prof                   Profissional que requisita
    * @param i_pat                    id do paciente
    * @param i_flg_time               Realiza��o: E - neste epis�dio; N - pr�ximo epis�dio; B - entre epis�dios
    * @param i_dt_begin               Data a partir da qual � pedida a realiza��o do exame
    * @param i_notes                  Notas de prescri��o no plano
    * @param i_take_type              Tipo de plano de tomas: N - normal, S - SOS,  U - unit�rio, C - cont�nuo, A - ad eternum
    * @param i_drug                   array de medicamentos
    * @param i_dt_end                 data fim. � indicada em CHECK_PRESC_PARAM; se for 'n�o aplic�vel', I_DT_END = NULL
    * @param i_interval               intervalo entre tomas
    * @param i_dosage                 dosagem
    * @param i_prof_cat_type          Tipo de categoria do profissional, tal como � retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_justif                 Se a escolha do medicamento foi feita por + frequentes, I_JUSTIF = N. Sen�o, I_JUSTIF = Y.
    * @param i_justif_valid           Se esta fun��o � chamada a partir do ecr� de justifica��o, I_JUSTIF_VALID = Y. Sen�o, I_JUSTIF_VALID = N.
    * @param i_test                   indica��o se testa a exist�ncia de exames com resultados ou j� requisitados (se a msg O_MSG_REQ ou O_MSG_RESULT j� foram apresentadas e o user continuou, I_TEST = pk_alert_constant.g_no)
    
    * @param  o_msg_req               mensagem com exames q foram requisitados recentemente
    * @param o_msg_result             mensagem com exames q foram requisitados recentemente e t�m resultado
    * @param o_msg_title              T�tulo da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param  o_button                Bot�es a mostrar: N - n�o, R - lido, C - confirmado Tb pode mostrar combina��es destes, qd � p/ mostrar + do q 1 bot�o
    * @param o_justif                 Indica��o de q precisa de mostrar o ecr� de justifica��o: NULL - � mostra not NULL - cont�m o t�tulo do ecr� de msg
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/03
    **********************************************************************************************/

    FUNCTION create_presc_vacc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN drug_prescription.id_episode%TYPE,
        i_prof                IN profissional,
        i_pat                 IN patient.id_patient%TYPE,
        i_flg_time            IN drug_prescription.flg_time%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_notes               IN drug_presc_plan.notes%TYPE,
        i_interval            IN VARCHAR2,
        i_dosage              IN drug_presc_det.dosage%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_id_drug             IN drug_presc_det.id_drug%TYPE,
        i_id_vacc             IN vacc.id_vacc%TYPE DEFAULT NULL,
        i_flg_advers_react    IN VARCHAR2, --NUMBER,
        i_notes_advers_react  IN drug_presc_plan.notes_advers_react%TYPE,
        i_application_spot    IN drug_presc_plan.application_spot%TYPE,
        i_lot_number          IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp              IN VARCHAR2,
        i_dos_comp            IN mi_med.qt_dos_comp%TYPE, --not used
        i_unit_measure        IN mi_med.id_unit_measure%TYPE, --not used
        i_dt_predicted        IN VARCHAR2,
        i_test                IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE,
        i_flg_type_date       IN VARCHAR2,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        o_drug_presc_plan     OUT NUMBER,
        o_drug_presc_det      OUT NUMBER,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_result          OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_type_admin          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_advers_react drug_presc_plan.flg_advers_react%TYPE;
    BEGIN
    
        IF i_flg_advers_react = '-2' --none
        THEN
            l_flg_advers_react := pk_alert_constant.g_no;
        ELSE
            l_flg_advers_react := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'SET_PAT_ADMINISTRATION_INTERN';
        IF NOT set_pat_administration_intern(i_lang       => i_lang,
                                             i_episode    => i_episode,
                                             i_prof       => i_prof,
                                             i_pat        => i_pat,
                                             i_drug_presc => NULL,
                                             i_flg_time   => i_flg_time,
                                             i_dt_begin   => i_dt_begin,
                                             
                                             i_prof_cat_type => i_prof_cat_type,
                                             i_id_drug       => i_id_drug,
                                             i_id_vacc       => i_id_vacc,
                                             
                                             i_flg_advers_react   => l_flg_advers_react,
                                             i_advers_react       => NULL,
                                             i_notes_advers_react => i_notes_advers_react,
                                             
                                             i_application_spot      => '',
                                             i_application_spot_desc => i_application_spot,
                                             
                                             i_lot_number => i_lot_number,
                                             i_dt_exp     => i_dt_exp,
                                             
                                             i_vacc_manuf      => i_vacc_manuf,
                                             i_vacc_manuf_desc => code_mvx,
                                             
                                             i_flg_type_date       => '',
                                             i_dosage_admin        => i_dosage_admin,
                                             i_dosage_unit_measure => i_dosage_unit_measure,
                                             
                                             i_adm_route => '',
                                             
                                             i_vacc_origin      => NULL,
                                             i_vacc_origin_desc => '',
                                             
                                             i_doc_vis      => NULL,
                                             i_doc_vis_desc => NULL,
                                             
                                             i_dt_doc_delivery => '',
                                             i_doc_cat         => NULL,
                                             i_doc_source      => NULL,
                                             i_doc_source_desc => NULL,
                                             
                                             i_order_by   => NULL,
                                             i_order_desc => '',
                                             
                                             i_administer_by   => NULL,
                                             i_administer_desc => '',
                                             
                                             i_dt_predicted => i_dt_predicted,
                                             i_test         => i_test,
                                             
                                             i_notes => i_notes,
                                             
                                             o_drug_presc_plan => o_drug_presc_plan,
                                             o_drug_presc_det  => o_drug_presc_det,
                                             o_flg_show        => o_flg_show,
                                             o_msg             => o_msg,
                                             o_msg_result      => o_msg_result,
                                             o_msg_title       => o_msg_title,
                                             o_type_admin      => o_type_admin,
                                             o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'CREATE_PRESC_VACC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc_vacc;

    FUNCTION get_age_recommend
    (
        i_lang IN language.id_language%TYPE,
        i_val  IN NUMBER
    ) RETURN VARCHAR2 IS
    
        /******************************************************************************
           OBJECTIVO: Enviar um valor (dias) para retorna, os dias, semanas, meses e anos
           PARAMETROS:  ENTRADA: i_lang
                                 i_val
        
        
          CRIA��O: Teresa Coutinho 2007/08/08
          NOTAS:
        *********************************************************************************/
    
        l_age_return sys_message.desc_message%TYPE := 'x';
    
    BEGIN
        IF i_val > 1095 --365
        THEN
            l_age_return := trunc(i_val / 365.2425, 0);
            IF l_age_return = 1
            THEN
                l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T034');
            ELSE
                l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T030');
            END IF;
        
        ELSIF i_val >= 30
        THEN
            IF l_age_return = 'x'
            THEN
                l_age_return := trunc(i_val / 30);
                IF l_age_return = 1
                THEN
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T033');
                ELSE
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T029');
                END IF;
            ELSE
                l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T016') || trunc(i_val / 30) || ' ' ||
                                pk_message.get_message(i_lang, 'VACC_T029');
            END IF;
        ELSIF i_val >= 7
        THEN
            IF l_age_return = 'x'
            THEN
                l_age_return := trunc(i_val / 7);
                IF l_age_return = 1
                THEN
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T035');
                ELSE
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T028');
                END IF;
            ELSE
                l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T016') || trunc(i_val / 7) || ' ' ||
                                pk_message.get_message(i_lang, 'VACC_T028');
            END IF;
        ELSE
            IF l_age_return = 'x'
            THEN
                l_age_return := trunc(i_val);
                IF l_age_return = 1
                THEN
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T034');
                ELSE
                    l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T031');
                END IF;
            ELSE
                l_age_return := l_age_return || ' ' || pk_message.get_message(i_lang, 'VACC_T016') || i_val || ' ' ||
                                pk_message.get_message(i_lang, 'VACC_T031');
            END IF;
        END IF;
    
        RETURN l_age_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END;

    /***********************************************************************************************************
    *  Esta fun��o permite criar um novo episodio gen�rico e de qualquer tipo. Como cada episodio est�
    *   associado a uma visita, � necess�rio criar em primeiro lugar uma visita.
    *
    * @param      i_lang               L�ngua registada como prefer�ncia do profissional
    * @param      i_prof               ID do profissional
    * @param      i_id_patient         ID do paciente
    * @param      o_id_episode         ID do episodio
    * @param      o_error              mensagem de erro
    *
    * @return     se a fun��o termina com sucesso e FALSE caso contr�rio
    * @author     Orlando Antunes
    * @version    2.3.6.
    * @since
    ***********************************************************************************************************/
    FUNCTION create_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cs      IN clinical_service.id_clinical_service%TYPE,
        i_id_patient IN NUMBER,
        o_id_episode OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --id para o novo epis�dio
        l_seq_epis NUMBER;
        --id do tipo de epis�dio que vai corresponder a uma consulta de enfermagem
        l_id_epis_type NUMBER;
        --Estado do epis�dio
        l_flg_status VARCHAR2(1);
        --Id da nova visita
        l_id_visit NUMBER;
    
        l_id_department department.id_department%TYPE;
        l_id_dept       dept.id_dept%TYPE;
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
        l_id_software     software.id_software%TYPE;
        l_no_triage_color triage_color.id_triage_color%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --Cria��o da visita a que o novo episodio vai estar associado
        IF NOT create_visit(i_lang, i_prof, i_id_patient, g_sysdate_tstz, l_id_visit, o_error)
        THEN
            --o_error := build_error_msg(i_lang, 'CREATE_EPISODE', l_error, '');
            RETURN FALSE;
        END IF;
    
        --Selec��o do tipo de epis�dio: Consulta de Enfermagem
        SELECT et.id_epis_type
          INTO l_id_epis_type
          FROM epis_type et
         WHERE et.code_epis_type = 'EPIS_TYPE.CODE_EPIS_TYPE.14';
    
        --O epis�dio est� inactivo na cria��o!
        l_flg_status := pk_alert_constant.g_inactive;
    
        --Cria��o do Episodio
        g_error := 'INSERT INTO EPISODE';
        ts_episode.ins(id_visit_in                => l_id_visit,
                       id_patient_in              => i_id_patient,
                       id_clinical_service_in     => nvl(i_id_cs, -1),
                       id_department_in           => nvl(l_id_department, -1),
                       id_dept_in                 => nvl(l_id_dept, -1),
                       id_epis_type_in            => l_id_epis_type,
                       flg_status_in              => l_flg_status,
                       dt_begin_tstz_in           => g_sysdate_tstz,
                       dt_end_tstz_in             => g_sysdate_tstz,
                       dt_creation_in             => g_sysdate_tstz,
                       id_institution_in          => i_prof.institution,
                       id_episode_out             => l_seq_epis,
                       id_cs_requested_in         => -1,
                       id_department_requested_in => -1,
                       id_dept_requested_in       => -1,
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_patient     => i_id_patient,
                                                      i_new_episode => l_seq_epis,
                                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        -- END ALERT-41412
    
        g_error := 'INSERT INTO EPIS_INFO';
    
        l_id_software := pk_episode.get_soft_by_epis_type(l_id_epis_type, i_prof.institution);
        g_error       := 'GET NO TRIAGE COLOR';
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_prof, l_seq_epis)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_VACC',
                                                  'CREATE_EPISODE',
                                                  o_error);
                RETURN FALSE;
        END;
    
        ts_epis_info.ins(id_episode_in               => l_seq_epis,
                         id_schedule_in              => -1,
                         id_room_in                  => NULL,
                         id_professional_in          => i_prof.id,
                         flg_unknown_in              => pk_alert_constant.g_no,
                         desc_info_in                => NULL,
                         flg_status_in               => l_flg_status,
                         id_dep_clin_serv_in         => NULL,
                         id_first_dep_clin_serv_in   => NULL,
                         id_patient_in               => i_id_patient,
                         id_dcs_requested_in         => -1,
                         id_software_in              => l_id_software,
                         dt_last_interaction_tstz_in => g_sysdate_tstz,
                         triage_acuity_in            => pk_alert_constant.g_color_gray,
                         triage_color_text_in        => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in       => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in          => l_no_triage_color,
                         rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_id_episode := l_seq_epis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'CREATE_EPISODE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END create_episode;

    /***********************************************************************************************************
    *  Esta fun��o permite criar uma nova visita gen�rica que vai estar associada a uma determinada institui��o.
    *
    * @param      i_lang               L�ngua registada como prefer�ncia do profissional
    * @param      i_prof               ID do profissional
    * @param      i_id_patient         ID do paciente
    * @param      o_id_visit           ID da visita
    * @param      o_error              mensagem de erro
    *
    * @return     se a fun��o termina com sucesso e FALSE caso contr�rio
    * @author     Orlando Antunes
    * @version    2.3.6.
    * @since
    ***********************************************************************************************************/
    FUNCTION create_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_dt_begin   IN episode.dt_begin_tstz%TYPE,
        o_id_visit   OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --id para o novo epis�dio
        l_seq_visit NUMBER;
        --Estado do epis�dio
        l_flg_status VARCHAR2(1);
    BEGIN
        --Sequ�ncia das visitas...
        g_error := 'GET CURSOR C_VISIT_SEQ';
        SELECT seq_visit.nextval
          INTO l_seq_visit
          FROM dual;
    
        --A visita est� activa na cria��o!
        l_flg_status := pk_alert_constant.g_yes;
    
        --Cria��o da visita
        g_error := 'INSERT INTO VISIT';
        INSERT INTO visit
            (id_visit, dt_begin_tstz, flg_status, id_patient, id_institution, dt_creation)
        VALUES
            (l_seq_visit, g_sysdate_tstz, l_flg_status, i_id_patient, i_prof.institution, current_timestamp);
    
        o_id_visit := l_seq_visit;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'CREATE_VISIT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END create_visit;

    /************************************************************************************************************
    * This function checks whether the taking was made in the same episode
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/

    FUNCTION has_recorded_this_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_take_id IN NUMBER,
        i_flg     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_ret       VARCHAR2(4000) := NULL;
        l_epis_orig episode.id_episode%TYPE;
        l_prof_resp professional.id_professional%TYPE;
    BEGIN
    
        IF (i_flg = g_vacc_dose_int)
        THEN
            l_ret := pk_alert_constant.g_inactive;
        ELSIF (i_flg = g_vacc_dose_report)
        THEN
            SELECT pva.id_episode, pva.id_prof_writes
              INTO l_epis_orig, l_prof_resp
              FROM pat_vacc_adm pva
             WHERE pva.id_pat_vacc_adm = i_take_id;
        
        ELSIF (i_flg = g_vacc_dose_adm)
        THEN
            SELECT dp.id_episode, dp.id_professional
              INTO l_epis_orig, l_prof_resp
              FROM drug_prescription dp
             WHERE dp.id_drug_prescription = i_take_id;
        ELSE
            l_ret := pk_alert_constant.g_inactive;
        END IF;
    
        IF (l_ret IS NULL)
        THEN
            IF (l_epis_orig = i_episode AND l_prof_resp = i_prof.id)
            THEN
                l_ret := pk_alert_constant.g_active;
            ELSE
                l_ret := pk_alert_constant.g_inactive;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END has_recorded_this_episode;

    /**********************************************************************************************
    *    Op��o (+) da Vacina��o V.2.4.2
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_type                   Se � para o multichoice de escolha entre a vacina e a prova � tuberculina ou a prescri��o
    * @param i_orig                   multichoice : i_orig: R-Relato, D-Administrar dose
    * @param i_patient                id_patient
    
    * @param o_val                    cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/11/22
    **********************************************************************************************/

    FUNCTION get_vacc_add
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        i_orig       IN VARCHAR2,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_type_vacc  IN VARCHAR2,
        i_id_reg     IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_val        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_type   category.flg_type%TYPE;
        l_add_restriction table_varchar := table_varchar();
        l_add_action_rest table_number := table_number();
        l_id_reg          NUMBER;
        l_vacc_status     pat_vacc.flg_status%TYPE;
        l_active_adm      VARCHAR2(1) := pk_alert_constant.g_active;
        l_dose_status     VARCHAR2(1);
    BEGIN
        SELECT flg_type
          INTO l_prof_cat_type
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_prof.id
           AND id_institution = i_prof.institution
           AND c.id_category = pc.id_category;
    
        IF i_type = 'ADD'
        THEN
            -- novo c�digo que define a visualiza��o de acordo com os grupos dispon�veis por software e institution
            IF get_group_available(i_lang, i_prof, g_flg_presc_tuberculin) = pk_alert_constant.g_no -- Tuberculinas n�o parametrizadas
            THEN
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'T';
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'AT';
            END IF;
            ------------------------
            IF get_group_available(i_lang, i_prof, g_flg_presc_other_vacc) = pk_alert_constant.g_no -- Outras vacinas n�o parametrizadas
            THEN
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'N';
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'AN';
            END IF;
            ------------------------
        
            g_error := 'OPEN CURSOR O_VAL VACC_TYPE.FLG_ADD';
            IF l_prof_cat_type = g_cat_type_nurse -- O enfermeiro n�o pode prescrever
            THEN
                -- acrescentar restri��es espec�ficas
                -------------------------------------------
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'T'; -- n�o pode: Requisitar prova tubercul�nica
                l_add_restriction.extend;
                l_add_restriction(l_add_restriction.last) := 'N'; -- n�o pode: Prescrever vacina
            
                l_add_action_rest.extend;
                l_add_action_rest(l_add_action_rest.last) := 2340726;
            
                -------------------------------------------
            END IF;
        
            OPEN o_val FOR
                SELECT id_action,
                       id_parent,
                       nivel AS "level",
                       from_state,
                       to_state,
                       desc_action,
                       icon,
                       flg_default,
                       flg_active,
                       action
                  FROM (SELECT id_action,
                               id_parent,
                               LEVEL nivel, --used to manage the shown' items by Flash
                                from_state,
                                to_state,
                                pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                               icon,
                               flg_default,
                               pk_alert_constant.g_active flg_active,
                               internal_name action
                          FROM action a
                         WHERE subject = 'ADD_VACCINES'
                           AND a.id_action NOT IN (SELECT *
                                                     FROM TABLE(l_add_action_rest))
                        CONNECT BY PRIOR id_action = id_parent
                         START WITH id_parent IS NULL
                        UNION ALL
                        SELECT sd.rank id_action,
                               decode(sd.val,
                                      pk_alert_constant.g_no,
                                      2340726,
                                      'T',
                                      2340726,
                                      'AN',
                                      2340725,
                                      'AT',
                                      2340725,
                                      'RV',
                                      2340733,
                                      NULL) id_parent,
                               2 nivel,
                               NULL from_state,
                               NULL to_state,
                               sd.desc_val desc_action,
                               sd.img_name icon,
                               pk_alert_constant.g_no flg_default,
                               pk_alert_constant.g_active flg_active,
                               sd.val action
                          FROM sys_domain sd
                         WHERE code_domain = 'VACC_TYPE.FLG_ADD'
                           AND id_language = i_lang
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND flg_available = pk_alert_constant.g_yes
                           AND val NOT IN (SELECT *
                                             FROM TABLE(l_add_restriction)))
                 ORDER BY nivel, desc_action;
        ELSIF i_type = 'REPORT'
        THEN
            IF (i_id_reg > 0)
            THEN
                l_id_reg := i_id_reg;
            ELSE
                l_id_reg := 0;
            END IF;
        
            IF i_type_vacc = 'T' -- Tuberculinas
            THEN
                OPEN o_val FOR
                    SELECT id_action,
                           id_parent,
                           nivel AS "level",
                           from_state,
                           to_state,
                           desc_action,
                           icon,
                           flg_default,
                           flg_active,
                           action
                      FROM (SELECT a.id_action,
                                   a.id_parent,
                                   a.rank nivel,
                                   a.from_state,
                                   a.to_state,
                                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                                   a.icon,
                                   a.flg_default,
                                   a.flg_status flg_active,
                                   a.internal_name action
                              FROM action a
                             WHERE a.subject = 'TUBERCULIN_ACTIONS'
                               AND a.from_state = i_flg_status)
                     ORDER BY nivel;
            ELSE
                l_vacc_status := get_vacc_status(i_patient => i_patient, i_vacc => i_vacc);
                l_dose_status := has_discontinue_dose(i_patient, i_vacc);
            
                IF l_vacc_status = g_status_s
                THEN
                    l_active_adm := pk_alert_constant.g_inactive;
                ELSIF l_id_reg <> 0
                THEN
                    l_active_adm := pk_alert_constant.g_inactive;
                ELSIF l_dose_status = pk_alert_constant.g_yes
                THEN
                    l_active_adm := pk_alert_constant.g_inactive;
                END IF;
            
                g_error := 'OPEN CURSOR O_VAL VACC_TYPE.FLG_ADM';
                IF i_orig IS NULL
                THEN
                    OPEN o_val FOR -- multichoice do tipo de administra��o (vacinas)
                        SELECT id_action,
                               id_parent,
                               nivel AS "level",
                               from_state,
                               to_state,
                               desc_action,
                               icon,
                               flg_default,
                               flg_active,
                               action
                          FROM (SELECT sd.rank                id_action,
                                       NULL                   id_parent,
                                       2                      nivel,
                                       NULL                   from_state,
                                       NULL                   to_state,
                                       sd.desc_val            desc_action,
                                       sd.img_name            icon,
                                       pk_alert_constant.g_no flg_default,
                                       l_active_adm           flg_active,
                                       sd.val                 action
                                  FROM sys_domain sd
                                 WHERE code_domain = 'VACC_TYPE.FLG_ADM'
                                   AND id_language = i_lang
                                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                                   AND flg_available = pk_alert_constant.g_yes
                                UNION
                                SELECT a.id_action,
                                       a.id_parent,
                                       a.rank nivel,
                                       a.from_state,
                                       a.to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       a.icon,
                                       a.flg_default,
                                       a.flg_status flg_active,
                                       a.internal_name action
                                  FROM action a
                                 WHERE a.subject = 'VACC_ADVERSE_REACTIONS'
                                   AND a.from_state = i_flg_status
                                UNION
                                SELECT a.id_action,
                                       a.id_parent,
                                       a.rank nivel,
                                       a.from_state,
                                       a.to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       a.icon,
                                       a.flg_default,
                                       a.flg_status flg_active,
                                       a.internal_name action
                                  FROM action a
                                 WHERE a.subject IN ('VACC_EDIT', 'VACC_CANCEL')
                                   AND a.from_state = decode(i_vacc, g_vacc_tetano, g_vacc_dose_report, i_flg_status)
                                UNION
                                SELECT a.id_action,
                                       a.id_parent,
                                       a.rank nivel,
                                       a.from_state,
                                       a.to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       a.icon,
                                       a.flg_default,
                                       has_active_option(l_vacc_status, a.subject) flg_active,
                                       a.internal_name action
                                  FROM action a
                                 WHERE a.subject IN ('VACC_RESUME', 'VACC_DISCONTINUE')
                                   AND i_type_vacc = 'P'
                                   AND a.from_state = nvl(i_flg_status, g_vaccine_title))
                         ORDER BY nivel, desc_action;
                ELSE
                    OPEN o_val FOR -- multichoice : i_orig: R-Relato, D-Administrar dose
                        SELECT id_action,
                               id_parent,
                               nivel AS "level",
                               from_state,
                               to_state,
                               desc_action,
                               icon,
                               flg_default,
                               flg_active,
                               action
                          FROM (SELECT sd.rank id_action,
                                       NULL id_parent,
                                       2 nivel,
                                       NULL from_state,
                                       NULL to_state,
                                       sd.desc_val desc_action,
                                       sd.img_name icon,
                                       pk_alert_constant.g_no flg_default,
                                       decode(i_flg_status,
                                              pk_alert_constant.g_active,
                                              pk_alert_constant.g_inactive,
                                              pk_alert_constant.g_active) flg_active,
                                       sd.val action
                                  FROM sys_domain sd
                                 WHERE code_domain = 'VACC_TYPE.FLG_ADM'
                                   AND id_language = i_lang
                                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                                   AND flg_available = pk_alert_constant.g_yes
                                   AND val = i_orig
                                UNION
                                SELECT a.id_action,
                                       a.id_parent,
                                       a.rank nivel,
                                       a.from_state,
                                       a.to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       a.icon,
                                       a.flg_default,
                                       decode(a.subject,
                                              'VACC_ADVERSE_REACTIONS',
                                              a.flg_status,
                                              has_recorded_this_episode(i_lang, i_prof, i_episode, i_id_reg, i_orig)) flg_active,
                                       a.internal_name action
                                  FROM action a
                                 WHERE a.subject IN ('VACC_EDIT', 'VACC_ADVERSE_REACTIONS', 'VACC_CANCEL')
                                   AND a.from_state = i_flg_status
                                UNION
                                SELECT a.id_action,
                                       a.id_parent,
                                       a.rank nivel,
                                       a.from_state,
                                       a.to_state,
                                       pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                                       a.icon,
                                       a.flg_default,
                                       a.flg_status flg_active,
                                       a.internal_name action
                                  FROM action a
                                 WHERE a.subject IN ('VACC_RESUME', 'VACC_DISCONTINUE')
                                   AND a.from_state = nvl(i_flg_status, g_vaccine_title))
                         ORDER BY nivel, desc_action;
                END IF;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_val);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ADD',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_val);
        
            RETURN FALSE;
    END get_vacc_add;

    /**********************************************************************************************
    *    Mais frequentes para as vacinas fora do PNV V.2.4.2
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_type                   tipo : T - Tuberculina, V - Vacinas
    * @param i_button                 tipo : A - Todos, S - Mais frequentes
    *
    * @param o_med_freq_label         label (mais frequentes/todos)
    * @param o_med_sel_label          label  (registos selecionados)
    * @param o_search_label           label  (pesquisa)
    * @param o_med_freq               cursor
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/12/05
    **********************************************************************************************/

    FUNCTION get_vacc_out_me_freq
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version             mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_nl_version          mi_med.vers%TYPE := 'NL';
        l_us_version          mi_med.vers%TYPE := 'USA_MS';
        l_ovgi_config         sys_config.value%TYPE;
        l_other_vacc_group_id table_varchar;
    
    BEGIN
    
        o_med_sel_label := pk_message.get_message(i_lang, 'VACC_T052');
    
        o_search_label := pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_T008');
    
        l_ovgi_config         := pk_sysconfig.get_config('OTHER_VACC_GROUP_ID', i_prof);
        l_other_vacc_group_id := table_varchar(l_ovgi_config);
    
        IF l_other_vacc_group_id IS NULL
        THEN
            IF l_version = l_nl_version
            THEN
                l_other_vacc_group_id := table_varchar('630');
            ELSIF l_version = l_us_version
            THEN
                l_other_vacc_group_id := table_varchar('1720000000',
                                                       '2170000000',
                                                       '1910000000',
                                                       '1899000000',
                                                       '1710000000',
                                                       '1710990000',
                                                       '1799000000',
                                                       '1800000000');
            ELSE
                l_other_vacc_group_id := table_varchar('185');
            END IF;
        END IF;
    
        --labels para o ecr�:
        IF i_button = pk_alert_constant.g_active -- Todas
        THEN
            o_med_freq_label := pk_message.get_message(i_lang, 'VACC_T054') || '|' ||
                                pk_message.get_message(i_lang, 'VACC_T051');
        
            OPEN o_med_freq FOR
            
            --SELECT DISTINCT NULL id_vacc,
            --                m.med_descr_formated pharm,
            --                m.dci_descr,
            --                m.generico,
            --                otc_descr desc_generico,
            --                price_pvp preco,
            --                NULL flg_status,
            --                NULL id_prescription_pharm,
            --                m.emb_id,
            --                decode(NULL,
            --                       NULL,
            --                       NULL,
            --                       pk_message.get_message(i_lang, 'PRESCRIPTION_HISTORY_T004') || NULL) dosage,
            --                NULL qty,
            --                NULL exist_cheaper,
            --                m.med_descr rank_1,
            --                m.form_farm_descr rank_2,
            --                m.qt_dos_comp rank_3,
            --                m.med_descr rank_4,
            --                m.n_units rank_5,
            --                m.qt_per_unit rank_6,
            --                med_name comerc_name
            --  FROM me_med_pharm_group mpg, me_med m, emb_dep_clin_serv edcs
            -- WHERE mpg.group_id = l_other_vacc_group_id
            --   AND mpg.vers = l_version
            --   AND mpg.emb_id = m.emb_id
            --   AND m.flg_comerc = pk_alert_constant.g_yes
            --   AND m.flg_available = pk_alert_constant.g_yes
            --   AND nvl(m.disp_id, 0) NOT IN (g_msrm_e, g_msrm_ra, g_msrm_r_ea, g_msrm_r_ec, g_emb_hosp, g_disp_in_v) --excluir medicamentos de uso exclusivo hospitalar
            --   AND m.vers = l_version
            --   AND NOT EXISTS (SELECT 1
            --          FROM vacc_other_freq vof
            --         WHERE vof.emb_id = m.emb_id)
            --   AND edcs.vers = l_version
            --   AND edcs.emb_id = m.emb_id
            --   AND edcs.id_institution = i_prof.institution
            --UNION ALL
                SELECT DISTINCT vof.id_vacc,
                                m.med_descr_formated pharm,
                                m.dci_descr,
                                m.generico,
                                otc_descr desc_generico,
                                price_pvp preco,
                                NULL flg_status,
                                NULL id_prescription_pharm,
                                m.emb_id,
                                decode(NULL,
                                       NULL,
                                       NULL,
                                       pk_message.get_message(i_lang, 'PRESCRIPTION_HISTORY_T004') || NULL) dosage,
                                NULL qty,
                                NULL exist_cheaper,
                                m.med_descr rank_1,
                                m.form_farm_descr rank_2,
                                m.qt_dos_comp rank_3,
                                m.med_descr rank_4,
                                m.n_units rank_5,
                                m.qt_per_unit rank_6,
                                med_name comerc_name
                  FROM me_med_pharm_group mpg, me_med m, vacc_other_freq vof, emb_dep_clin_serv edcs
                 WHERE mpg.group_id IN (SELECT *
                                          FROM TABLE(l_other_vacc_group_id))
                   AND mpg.vers = l_version
                   AND mpg.emb_id = m.emb_id
                   AND m.emb_id = vof.emb_id
                   AND m.flg_comerc = pk_alert_constant.g_yes
                   AND m.flg_available = pk_alert_constant.g_yes
                   AND nvl(m.disp_id, 0) NOT IN
                       (g_msrm_e, g_msrm_ra, g_msrm_r_ea, g_msrm_r_ec, g_emb_hosp, g_disp_in_v) --excluir medicamentos de uso exclusivo hospitalar
                   AND m.vers = l_version
                   AND edcs.vers = l_version
                   AND edcs.emb_id = m.emb_id
                   AND edcs.id_institution = i_prof.institution
                 ORDER BY rank_1, rank_2, rank_3, rank_4, rank_5, rank_6, preco;
        
        ELSE
            -- mais frequentes
            o_med_freq_label := pk_message.get_message(i_lang, 'VACC_T050');
        
            OPEN o_med_freq FOR
            
                SELECT DISTINCT vof.id_vacc,
                                m.med_descr_formated pharm,
                                m.dci_descr,
                                m.generico,
                                otc_descr desc_generico,
                                price_pvp preco,
                                NULL flg_status,
                                NULL id_prescription_pharm,
                                m.emb_id,
                                decode(NULL,
                                       NULL,
                                       NULL,
                                       pk_message.get_message(i_lang, 'PRESCRIPTION_HISTORY_T004') || NULL) dosage,
                                NULL qty,
                                NULL exist_cheaper,
                                m.med_descr rank_1,
                                m.form_farm_descr rank_2,
                                m.qt_dos_comp rank_3,
                                m.med_descr rank_4,
                                m.n_units rank_5,
                                m.qt_per_unit rank_6,
                                med_name comerc_name
                  FROM me_med_pharm_group mpg, me_med m, vacc_other_freq vof, emb_dep_clin_serv edcs
                 WHERE --((l_version != l_nl_version AND mpg.group_id IN (185, 184)) OR -- group_id gen�rico para PT
                --(l_version = l_nl_version AND mpg.group_id = 630)) -- group_id especifico para NL
                 mpg.group_id IN (SELECT *
                                    FROM TABLE(l_other_vacc_group_id))
                 AND mpg.vers = l_version
                 AND mpg.emb_id = m.emb_id
                 AND m.emb_id = vof.emb_id
                 AND m.flg_comerc = pk_alert_constant.g_yes
                 AND m.flg_available = pk_alert_constant.g_yes
                 AND nvl(m.disp_id, 0) NOT IN (g_msrm_e, g_msrm_ra, g_msrm_r_ea, g_msrm_r_ec, g_emb_hosp, g_disp_in_v) --excluir medicamentos de uso exclusivo hospitalar
                 AND l_version = m.vers
                 AND edcs.vers = l_version
                 AND edcs.emb_id = m.emb_id
                 AND edcs.id_institution = i_prof.institution
                 ORDER BY rank_1, rank_2, rank_3, rank_4, rank_5, rank_6, preco;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_OUT_ME_FREQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_med_freq);
        
            RETURN FALSE;
        
    END get_vacc_out_me_freq;

    /*
     * =================================
     * -- Tuberculin developement
     * =================================
    
    /**######################################################
      Private functions
    ######################################################**/

    /************************************************************************************************************
    * Returns the value of the specified parameters for the tuberculin test details. Each parameter corresponds
    * to a message in the SYS_MESSAGE table.
    *
    * @param      i_lang               default language
    * @param      i_prof               profisisonal
    * @param      i_test_id            tubeculin test
    * @param      i_key                key for the detail parameter
    *
    * @return     The value that corresponds to the specified parameter for the tuberculin test.
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2007/12/10
    ***********************************************************************************************************/
    FUNCTION get_value_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_key     IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_result  VARCHAR2(100);
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
        l_result := '--';
    
        CASE i_key
            WHEN 'TUBERCULIN_TEST_T004' THEN
                BEGIN
                    SELECT DISTINCT nvl(mim.med_descr, '--') det_name
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpd.id_drug = mim.id_drug
                          -- and dpp.flg_status!='C' -- tomas canceladas
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND mim.vers = l_version;
                END;
            WHEN 'TUBERCULIN_TEST_T005' THEN
                BEGIN
                    SELECT DISTINCT decode(dpp.id_prof_writes,
                                           NULL,
                                           '--',
                                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
                                              FROM professional p
                                             WHERE p.id_professional = dpp.id_prof_writes))
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp --, professional p
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          -- and dpp.flg_status!='C' -- tomas canceladas
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T006' THEN
                BEGIN
                    SELECT nvl(dpd.notes_justif, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T007' THEN
                BEGIN
                    SELECT DISTINCT --nvl(format_tuberculin_test_date(i_lang, i_prof, dp.dt_drug_prescription_tstz), '--')
                                    decode(to_char(dp.dt_drug_prescription_tstz, 'HH24MISS'),
                                           '000000',
                                           (ltrim(nvl(format_tuberculin_test_date(i_lang,
                                                                                  i_prof,
                                                                                  to_date(to_char(dp.dt_drug_prescription_tstz,
                                                                                                  'YYYYMMDD'),
                                                                                          'YYYYMMDD'),
                                                                                  NULL),
                                                      '--'),
                                                  '00:00h ')),
                                           (nvl(format_tuberculin_test_date(i_lang,
                                                                            i_prof,
                                                                            dp.dt_drug_prescription_tstz,
                                                                            NULL),
                                                '--')))
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T008' THEN
                BEGIN
                    l_result := '--';
                END;
            WHEN 'TUBERCULIN_TEST_T009' THEN
                BEGIN
                    SELECT DISTINCT nvl(dpd.notes, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          -- and dpp.flg_status!='C' -- tomas canceladas
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
                --administration
            WHEN 'TUBERCULIN_TEST_T013' THEN
                BEGIN
                    SELECT DISTINCT nvl(format_tuberculin_test_date(i_lang, i_prof, dpp.dt_take_tstz, dpp.flg_type_date),
                                        '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T014' THEN
                BEGIN
                    SELECT DISTINCT nvl(dpp.lot_number, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T015' THEN
                BEGIN
                    SELECT DISTINCT nvl(format_dt_expiration_test_date(i_lang, i_prof, dpp.dt_expiration), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T016' THEN
                BEGIN
                    SELECT DISTINCT nvl(dpp.application_spot, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'VACC_T086' THEN
                BEGIN
                    SELECT ': ' || nvl(TRIM(pk_utils.to_str(dpp.dosage) || ' ' ||
                                            pk_translation.get_translation(i_lang, um.code_unit_measure_abrv)),
                                       '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, unit_measure um
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.dosage_unit_measure = um.id_unit_measure;
                END;
            WHEN 'TUBERCULIN_TEST_T017' THEN
                BEGIN
                    SELECT nvl(dpp.notes, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T018' THEN
                BEGIN
                    SELECT DISTINCT nvl(decode(dpp.id_prof_writes,
                                               NULL,
                                               '',
                                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                                        '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, professional p
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_prof_writes = p.id_professional;
                END;
                --results
            WHEN 'TUBERCULIN_TEST_T021' THEN
                BEGIN
                    SELECT nvl(dpr.value, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan;
                END;
            
            WHEN 'TUBERCULIN_TEST_T022' THEN
                BEGIN
                    SELECT nvl(dpr.evaluation, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan;
                END;
            WHEN 'TUBERCULIN_TEST_T023' THEN
                BEGIN
                    SELECT nvl(dpr.notes_advers_react, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan;
                END;
            WHEN 'TUBERCULIN_TEST_T024' THEN
                --xx
                BEGIN
                    SELECT nvl(pk_date_utils.get_elapsed(i_lang,
                                                         CAST(dpr.dt_drug_presc_result AS DATE),
                                                         CAST(dpp.dt_take_tstz AS DATE)),
                               '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan;
                END;
            
            WHEN 'TUBERCULIN_TEST_T025' THEN
                BEGIN
                    SELECT nvl(dpr.notes, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan;
                END;
            WHEN 'TUBERCULIN_TEST_T026' THEN
                BEGIN
                    SELECT DISTINCT nvl(decode(dpr.id_prof_resp,
                                               NULL,
                                               '',
                                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                                        '--')
                      INTO l_result
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           drug_presc_plan   dpp,
                           drug_presc_result dpr,
                           professional      p
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan
                       AND dpr.id_prof_resp = p.id_professional;
                END;
                --cancel
            WHEN 'TUBERCULIN_TEST_T056' THEN
                BEGIN
                    SELECT DISTINCT nvl(format_tuberculin_test_date(i_lang, i_prof, dp.dt_cancel_tstz, NULL), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T057' THEN
                BEGIN
                    SELECT DISTINCT nvl(dpd.notes_cancel, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T058' THEN
                BEGIN
                    SELECT DISTINCT nvl(decode(dp.id_prof_cancel,
                                               NULL,
                                               '',
                                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                                        '--')
                      INTO l_result
                      FROM drug_prescription dp,
                           drug_presc_det    dpd, --drug_presc_plan dpp,
                           professional      p
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          --  AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                          -- AND dpp.id_prof_cancel = p.id_professional;
                       AND dp.id_prof_cancel = p.id_professional;
                END;
            WHEN 'VACC_T005' THEN
                BEGIN
                    SELECT DISTINCT nvl(mm.med_descr, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mm
                     WHERE dp.id_drug_prescription = i_test_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpd.id_drug = mm.id_drug
                       AND mm.vers = l_version;
                END;
            ELSE
                BEGIN
                    l_result := '--';
                END;
        END CASE;
    
        IF l_result IS NULL
        THEN
            l_result := '--';
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '--';
    END get_value_det;
    --

    /************************************************************************************************************
    * Returns the value of the specified parameters, for the vaccines or reports of vaccines adimistrations
    * Each parameter corresponds to a message in the SYS_MESSAGE table.
    *
    * @param      i_lang               default language
    * @param      i_prof               profisisonal
    * @param      i_vacc_take_id            tubeculin test
    * @param      i_key                key for the detail parameter
    *
    * @return     The value that corresponds to the specified parameter for the vaccines or reports of
    *             vaccines adimistrations.
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2007/12/10
    ***********************************************************************************************************/

    FUNCTION get_oth_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_result  sys_message.desc_message%TYPE;
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        CASE i_key
            WHEN 'TUBERCULIN_TEST_T004' THEN
                BEGIN
                    SELECT nvl(mem.short_med_descr, '--') det_name
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, me_med mem
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pvad.emb_id = mem.emb_id
                       AND pva.id_episode_destination IS NULL
                       AND mem.vers = l_version;
                END;
            WHEN 'VACC_T057' THEN
                BEGIN
                    SELECT nvl(decode(pva.prof_presc,
                                      NULL,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                      pva.prof_presc),
                               '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_prof_writes = p.id_professional;
                END;
            WHEN 'TUBERCULIN_TEST_T006' THEN
                BEGIN
                    l_result := '--';
                END;
            WHEN 'VACC_T056' THEN
                BEGIN
                    SELECT nvl(format_tuberculin_test_date(i_lang, i_prof, pva.dt_presc, NULL), '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T008' THEN
                BEGIN
                    SELECT nvl(decode(pva.flg_time,
                                      'E',
                                      pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T061'), --
                                      pk_alert_constant.g_no,
                                      pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T062'), --
                                      'B',
                                      pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T062')),
                               '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T009' THEN
                BEGIN
                    SELECT nvl(pva.notes_presc, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm;
                END;
                --administration
            WHEN 'TUBERCULIN_TEST_T013' THEN
                BEGIN
                    SELECT decode(pva.flg_orig,
                                  g_orig_r,
                                  nvl(decode(pvad.flg_type_date,
                                             pk_alert_constant.g_yes,
                                             get_year_from_timestamp(pvad.dt_take),
                                             g_month,
                                             pk_date_utils.get_month_year(i_lang, i_prof, pvad.dt_take),
                                             --        g_day,
                                             --                                             pk_date_utils.date_char_tsz(i_lang,
                                             --                                                                         pvad.dt_take,
                                             --                                                                         i_prof.institution,
                                             --                                                                         i_prof.software),
                                             --format_dt_expiration_test_date(i_lang, i_prof, pvad.dt_take)),
                                             format_tuberculin_test_date(i_lang, i_prof, pvad.dt_take, pvad.flg_type_date)),
                                      '--'),
                                  g_orig_i,
                                  nvl(format_dt_expiration_test_date(i_lang, i_prof, pvad.dt_take), '--'),
                                  nvl(format_tuberculin_test_date(i_lang, i_prof, pvad.dt_take, pva.flg_type_date), '--'))
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'VACC_T036' THEN
                BEGIN
                    SELECT nvl(pvad.report_orig, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T016' THEN
                BEGIN
                    SELECT nvl(pvad.application_spot, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'VACC_T086' THEN
                BEGIN
                    SELECT nvl(TRIM(pk_utils.to_str(pva.dosage_admin) || ' ' ||
                                    pk_translation.get_translation(i_lang, um.code_unit_measure_abrv)),
                               '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, unit_measure um
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.dosage_unit_measure = um.id_unit_measure
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T023' THEN
                BEGIN
                    SELECT nvl(pvad.notes_advers_react, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T014' THEN
                BEGIN
                    SELECT nvl(pvad.lot_number, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T015' THEN
                BEGIN
                    SELECT decode(pvad.dt_expiration,
                                  NULL,
                                  '--', --
                                  --formata a data segundo Mon-DD-YYYY
                                  pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof))
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            
            WHEN 'TUBERCULIN_TEST_T017' THEN
                BEGIN
                    SELECT nvl(pvad.notes, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
                --cancel
            WHEN 'TUBERCULIN_TEST_T056' THEN
                BEGIN
                    SELECT nvl(format_tuberculin_test_date(i_lang, i_prof, pva.dt_cancel, NULL), '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T057' THEN
                BEGIN
                    SELECT nvl(pvad.notes_cancel, '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'TUBERCULIN_TEST_T058' THEN
                BEGIN
                    SELECT nvl(decode(pva.id_prof_cancel,
                                      NULL,
                                      '',
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                               '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND p.id_professional = pvad.id_prof_writes
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'VACC_T005' THEN
                BEGIN
                    SELECT DISTINCT nvl(pvad.desc_vaccine, '--')
                      INTO l_result
                      FROM pat_vacc_adm_det pvad, pat_vacc_adm pva
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
                END;
            WHEN 'VACC_T085' THEN
                BEGIN
                    SELECT DISTINCT nvl(pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer), '--')
                      INTO l_result
                      FROM pat_vacc_adm pva, vacc_manufacturer vm
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_vacc_manufacturer = vm.id_vacc_manufacturer;
                END;
            ELSE
                BEGIN
                    l_result := '--';
                END;
        END CASE;
    
        IF l_result IS NULL
        THEN
            l_result := '--';
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '--';
    END get_oth_vacc_value_det;
    --

    /************************************************************************************************************
    * Returns the value of the specified parameters, for the PNV vaccines details.
    * Each parameter corresponds to a message in the SYS_MESSAGE table.
    *
    * @param      i_lang               default language
    * @param      i_prof               profisisonal
    * @param      i_vacc_take_id       vaccine's ID
    * @param      i_key                key for the detail parameter
    *
    * @return     The value that corresponds to the specified parameter for the PNV vaccines.
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2007/12/10
    ***********************************************************************************************************/
    FUNCTION get_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_result  VARCHAR2(100);
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
        CASE i_key
            WHEN 'TUBERCULIN_TEST_T004' THEN
                BEGIN
                    SELECT nvl(mim.med_descr, '--') det_name
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpd.id_drug = mim.id_drug
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'VACC_T057' THEN
                BEGIN
                    SELECT decode(dpd.id_prof_order,
                                  NULL,
                                  '--',
                                  (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
                                     FROM professional p
                                    WHERE p.id_professional = dpd.id_prof_order))
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp --, professional p
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T006' THEN
                BEGIN
                    l_result := '--';
                END;
            WHEN 'VACC_T056' THEN
                BEGIN
                    SELECT nvl(format_tuberculin_test_date(i_lang, i_prof, dp.dt_drug_prescription_tstz, NULL), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T008' THEN
                BEGIN
                    BEGIN
                        SELECT nvl(decode(dp.flg_time,
                                          'E',
                                          pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T061'), --
                                          pk_alert_constant.g_no,
                                          pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T062'), --
                                          'B',
                                          pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T062')),
                                   '--')
                          INTO l_result
                          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                         WHERE dp.id_drug_prescription = i_vacc_take_id
                           AND dp.id_drug_prescription = dpd.id_drug_prescription
                           AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                    END;
                END;
            WHEN 'TUBERCULIN_TEST_T009' THEN
                BEGIN
                    l_result := '--';
                END;
                --administration
            WHEN 'TUBERCULIN_TEST_T013' THEN
                BEGIN
                    SELECT nvl(format_tuberculin_test_date(i_lang, i_prof, dpp.dt_take_tstz, dpp.flg_type_date), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                
                END;
            WHEN 'TUBERCULIN_TEST_T016' THEN
                BEGIN
                    SELECT nvl(dpp.application_spot, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                
                END;
            WHEN 'VACC_T086' THEN
                BEGIN
                    SELECT nvl(TRIM(pk_utils.to_str(dpp.dosage) || ' ' ||
                                    pk_translation.get_translation(i_lang, um.code_unit_measure_abrv)),
                               '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, unit_measure um
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.dosage_unit_measure = um.id_unit_measure;
                END;
            WHEN 'TUBERCULIN_TEST_T023' THEN
                BEGIN
                    SELECT nvl(dpp.notes_advers_react, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                
                END;
            
            WHEN 'TUBERCULIN_TEST_T014' THEN
                BEGIN
                    SELECT nvl(dpp.lot_number, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T015' THEN
                BEGIN
                    SELECT nvl(format_dt_expiration_test_date(i_lang, i_prof, dpp.dt_expiration), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T017' THEN
                BEGIN
                    SELECT nvl(dpp.notes, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
                --cancel
            WHEN 'TUBERCULIN_TEST_T056' THEN
                BEGIN
                    SELECT nvl(format_tuberculin_test_date(i_lang, i_prof, dp.dt_cancel_tstz, NULL), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T057' THEN
                BEGIN
                    SELECT nvl(dp.notes_cancel, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det;
                END;
            WHEN 'TUBERCULIN_TEST_T058' THEN
                BEGIN
                    SELECT nvl(decode(dp.id_prof_cancel,
                                      NULL,
                                      '',
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                               '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, professional p
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.id_prof_writes = p.id_professional;
                END;
            WHEN 'VACC_T005' THEN
                BEGIN
                    SELECT DISTINCT nvl(mm.med_descr, '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mm
                     WHERE dp.id_drug_prescription = i_vacc_take_id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpd.id_drug = mm.id_drug
                       AND mm.vers = l_version;
                END;
            WHEN 'VACC_T085' THEN
                BEGIN
                    SELECT DISTINCT nvl(pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer), '--')
                      INTO l_result
                      FROM drug_prescription dp, drug_presc_det dpd, vacc_manufacturer vm
                     WHERE dpd.id_drug_prescription = i_vacc_take_id
                       AND dpd.id_vacc_manufacturer = vm.id_vacc_manufacturer;
                END;
            ELSE
                BEGIN
                    l_result := '--';
                END;
        END CASE;
    
        IF l_result IS NULL
        THEN
            l_result := '--';
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '--';
    END get_vacc_value_det;
    --

    /************************************************************************************************************
    * Builds a list of pamaretres (SYS_MESSAGE records) that is to be shown in each detail screen.
    *
    * @param      i_lang               language
    * @param      i_op_screen          screen detail identification
    *
    * @param      o_error              error message
    *
    * @return     nested table with the SYS_MESSAGE codes for the parameters that will be presented in
    *             each detail screen.
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2008/12/20
    ***********************************************************************************************************/

    FUNCTION format_screen_info
    (
        i_lang      IN language.id_language%TYPE,
        i_op_screen VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN table_info IS
    
        l_adm_det_info table_info := table_info();
    
    BEGIN
    
        IF i_op_screen = 'PRESC_VACC'
        THEN
            --formata os dados para o ecr� de detalhes da precri��o de vacinas:
            l_adm_det_info.extend;
            l_adm_det_info(1) := info(1, 'VACC_T056', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(2) := info(2, 'TUBERCULIN_TEST_T004', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(3) := info(3, 'TUBERCULIN_TEST_T008', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(4) := info(4, 'TUBERCULIN_TEST_T009', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(5) := info(5, 'VACC_T057', NULL);
            --
            --            l_adm_det_info.EXTEND;
            --            l_adm_det_info(6) := info(6, 'VACC_T085');
        
        ELSIF i_op_screen = 'ADM_VACC'
        THEN
            --formata os dados para o ecr� de detalhes da administra��o de vacinas:
            -- acrescentado nome da vacina
            l_adm_det_info.extend;
            l_adm_det_info(1) := info(1, 'VACC_T005', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(2) := info(2, 'TUBERCULIN_TEST_T013', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(3) := info(3, 'VACC_T036', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(4) := info(4, 'TUBERCULIN_TEST_T016', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(5) := info(5, 'VACC_T086', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(6) := info(6, 'TUBERCULIN_TEST_T023', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(7) := info(7, 'TUBERCULIN_TEST_T014', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(8) := info(8, 'TUBERCULIN_TEST_T015', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(9) := info(9, 'TUBERCULIN_TEST_T017', NULL);
            --
            --            l_adm_det_info.extend;
            --            l_adm_det_info(9) := info(9, 'TUBERCULIN_TEST_T018');
            --
            l_adm_det_info.extend;
            l_adm_det_info(10) := info(10, 'VACC_T085', NULL);
        
        END IF;
    
        RETURN l_adm_det_info;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'FORMAT_SCREEN_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
        
    END format_screen_info;
    --

    /************************************************************************************************************
    * This function returns the prescription details for the specified tuberculin test if any or else
    * the prescription details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_patient            patient's ID
    * @param      i_prof               profisisonal
    * @param      i_test_id            tuberculin test ID
    * @param      i_to_add             if is to be used in screens that allows to add information
    *
    * @param      o_presc_title        title for the prescription details
    * @param      o_presc_det          cursor with the prescription details information
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_presc_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tests_ids         table_info := table_info();
        l_tests_ids_pos     NUMBER(3) := 1;
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        --procura todos os ids de testes
        CURSOR c_tests IS
        
            SELECT DISTINCT dp.id_drug_prescription id --, d.code_drug desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id
             ORDER BY id;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        --title
        SELECT pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T003')
          INTO o_presc_title
          FROM dual;
    
        --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
        -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
        g_error := 'OPEN CURSOR o_presc_det TO GET THE PRESCRIPTION DETAILS';
    
        IF i_test_id IS NOT NULL
        THEN
            OPEN o_presc_det FOR
            
                SELECT det_name, det_value, desc_resp, flg_show, id_test
                  FROM (SELECT s.desc_message det_name,
                               get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                               '' desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               i_test_id id_test
                          FROM sys_message s
                         WHERE s.code_message IN ('TUBERCULIN_TEST_T004', /*'TUBERCULIN_TEST_T005',*/
                                                  'TUBERCULIN_TEST_T006',
                                                  'TUBERCULIN_TEST_T007',
                                                  'TUBERCULIN_TEST_T009')
                           AND s.id_language = i_lang
                         ORDER BY s.code_message)
                UNION ALL
                --Adicionar informa��o sobre o profissional respons�vel
                SELECT '' det_name,
                       '' det_value,
                       get_prof_resp_info(i_lang,
                                          i_prof,
                                          dp.id_professional,
                                          dp.dt_drug_prescription_tstz,
                                          dp.id_episode) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       i_test_id id_test
                  FROM drug_prescription dp
                 WHERE dp.id_drug_prescription = i_test_id;
        
        ELSE
        
            FOR l_test_cur IN c_tests
            LOOP
                l_tests_ids.extend;
                l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            OPEN o_presc_det FOR
                SELECT det_name, det_value, desc_resp, flg_show, id_test
                  FROM (SELECT s.desc_message det_name,
                               get_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                               '' desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               test_ids.id id_test
                          FROM sys_message s, TABLE(l_tests_ids) test_ids
                         WHERE s.code_message IN ('TUBERCULIN_TEST_T004', /*'TUBERCULIN_TEST_T005',*/
                                                  'TUBERCULIN_TEST_T006',
                                                  'TUBERCULIN_TEST_T007',
                                                  'TUBERCULIN_TEST_T009')
                           AND s.id_language = i_lang
                         ORDER BY id_test, s.code_message)
                UNION ALL
                SELECT '' det_name,
                       '' det_value,
                       get_prof_resp_info(i_lang,
                                          i_prof,
                                          dp.id_professional,
                                          dp.dt_drug_prescription_tstz,
                                          dp.id_episode) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       test_ids.id id_test
                  FROM drug_prescription dp, TABLE(l_tests_ids) test_ids
                 WHERE dp.id_drug_prescription = test_ids.id;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_TEST_PRESC_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_presc_det);
                RETURN FALSE;
            END;
    END get_tuberculin_test_presc_det;
    --

    /************************************************************************************************************
    * This function returns the adverse reaction 
    * details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Rita Lopes
    * @version    0.1
    * @since      2011/03/28
    ***********************************************************************************************************/
    FUNCTION get_tub_advers_react_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- vari�vel para verifica��o de exist�ncia de Respons�vel pela administra��o
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        l_tests_ids     table_info := table_info();
        l_tests_ids_pos NUMBER(3) := 1;
    
        --procura todos os ids de testes
        CURSOR c_tests IS
            SELECT dp.id_drug_prescription id --, d.code_drug desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id;
    
    BEGIN
    
        --title
        o_advers_react_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T063');
    
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        FOR l_test_cur IN c_tests
        LOOP
            l_tests_ids.extend;
            l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
            l_tests_ids_pos := l_tests_ids_pos + 1;
        END LOOP;
    
        OPEN o_advers_react_det FOR
            SELECT det_name, det_value, desc_resp, flg_show, id_test, dt
              FROM (SELECT pk_message.get_message(i_lang, 'TUBERCULIN_TEST_M005') det_name,
                           var.notes_advers_react det_value,
                           NULL desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           test_ids.id id_test,
                           var.dt_prof_write dt
                      FROM drug_prescription dp,
                           TABLE(l_tests_ids) test_ids,
                           drug_presc_det dpd,
                           drug_presc_plan dpp,
                           vacc_advers_react var
                     WHERE dp.id_drug_prescription = test_ids.id
                       AND dpd.id_drug_prescription = dp.id_drug_prescription
                       AND dpd.id_drug_presc_det = dpp.id_drug_presc_det
                       AND get_tuberculin_test_state(test_ids.id) IN
                           (g_tuberculin_test_state_adm, g_tuberculin_test_state_res, g_tuberculin_test_state_canc)
                       AND var.id_reg = dpp.id_drug_presc_plan
                       AND var.flg_type = 'V'
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           get_prof_resp_info(i_lang, i_prof, var.id_prof_write, var.dt_prof_write, dp.id_episode) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           test_ids.id id_test,
                           var.dt_prof_write dt
                      FROM drug_prescription dp,
                           TABLE(l_tests_ids) test_ids,
                           drug_presc_det dpd,
                           drug_presc_plan dpp,
                           vacc_advers_react var
                     WHERE dp.id_drug_prescription = test_ids.id
                       AND dpd.id_drug_prescription = dp.id_drug_prescription
                       AND dpd.id_drug_presc_det = dpp.id_drug_presc_det
                       AND get_tuberculin_test_state(test_ids.id) IN
                           (g_tuberculin_test_state_adm, g_tuberculin_test_state_res, g_tuberculin_test_state_canc)
                       AND var.id_reg = dpp.id_drug_presc_plan
                       AND var.flg_type = 'V')
             ORDER BY dt DESC, det_name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_TUB_ADVERS_REACT_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_advers_react_det);
                RETURN FALSE;
            END;
    END get_tub_advers_react_det;

    /************************************************************************************************************
    * This function returns the administration details for the specified vaccine take, if any, or else
    * the administration details for all vaccines for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_vacc_presc_det
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_vacc_id      IN vacc.id_vacc%TYPE,
        i_vacc_take_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_to_add       IN BOOLEAN,
        --OUT
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_vacc_ids table_info := table_info();
    
        l_adm_det_info table_info := table_info();
    
        l_vaccs_ids_pos NUMBER(3) := 1;
    
        --procura todos os ids de vacinas fora do PNV ou relatos (gravados nas tabelas pat_vacc_adm*)
        CURSOR c_vaccs IS
            SELECT pva.id_pat_vacc_adm id, '' desc_info
              FROM pat_vacc_adm pva, vacc_group vg, vacc_type_group vtg
             WHERE pva.id_vacc = i_vacc_id
               AND pva.id_patient = i_patient
               AND vg.id_vacc = pva.id_vacc
               AND vtg.flg_pnv = pk_alert_constant.g_no
               AND vg.id_vacc_type_group = vtg.id_vacc_type_group
               AND pva.id_episode_destination IS NULL;
    
    BEGIN
    
        --if i_to_add is false indica que estamos num ecr� de resumo
        --if i_to_add is true indica que estamos nun ecr� de registo de informa��o.
        --se o estado � administra��o vamos adicionar resultados
        IF NOT i_to_add
        --OR l_vacc_state = g_tuberculin_vacc_state_adm
        THEN
            --title
            SELECT pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T003')
              INTO o_presc_title
              FROM dual;
        
            l_adm_det_info := format_screen_info(i_lang, 'PRESC_VACC', o_error);
        
            IF i_vacc_take_id IS NOT NULL
            THEN
                --j� sabemos qual � a dose da vacina
                OPEN o_presc_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT rtrim(s.desc_message, ':') || ':' det_name,
                                   get_oth_vacc_value_det(i_lang, i_prof, i_vacc_take_id, s.code_message) det_value,
                                   '' desc_resp,
                                   --a label 'Notas da prescri��o' apenas � apresentada para os vacinas trazidas pelo paciente...
                                   decode(s.code_message,
                                          'TUBERCULIN_TEST_T009',
                                          decode(pva.prof_presc, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes), --
                                          pk_alert_constant.g_yes) flg_show,
                                   i_vacc_take_id id_test
                              FROM sys_message s, pat_vacc_adm pva, TABLE(l_adm_det_info) adm_info
                             WHERE s.code_message = adm_info.desc_info
                               AND s.id_language = i_lang
                                  --apenas se o estado � Administrado
                               AND pva.id_pat_vacc_adm = i_vacc_take_id
                                  --estados: N - n�o administrado(relato), A - administrado, R - requisistado
                               AND pva.flg_status IN (pk_alert_constant.g_no, pk_alert_constant.g_active, 'R', g_day)
                               AND pva.id_episode_destination IS NULL
                             ORDER BY id_test, adm_info.id)
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           get_prof_resp_info(i_lang, i_prof, pvad.id_prof_writes, pvad.dt_reg, pvad.id_episode) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           i_vacc_take_id id_test
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
                     WHERE pva.id_pat_vacc_adm = i_vacc_take_id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
            
            ELSE
                --queremos todos os registos desta vacina para o paciente
                FOR l_vacc_cur IN c_vaccs
                LOOP
                    l_vacc_ids.extend;
                    l_vacc_ids(l_vaccs_ids_pos) := info(l_vacc_cur.id, NULL, NULL);
                    l_vaccs_ids_pos := l_vaccs_ids_pos + 1;
                END LOOP;
            
                OPEN o_presc_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT rtrim(s.desc_message, ':') || ':' det_name,
                                   get_oth_vacc_value_det(i_lang, i_prof, vacc_ids.id, s.code_message) det_value,
                                   '' desc_resp,
                                   --a label 'Notas da prescri��o' apenas � apresentada para os vacinas trazidas pelo paciente...
                                   decode(s.code_message,
                                          'TUBERCULIN_TEST_T009',
                                          decode(pva.prof_presc, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes), --
                                          pk_alert_constant.g_yes) flg_show,
                                   vacc_ids.id id_test
                              FROM sys_message s,
                                   pat_vacc_adm pva,
                                   TABLE(l_vacc_ids) vacc_ids,
                                   TABLE(l_adm_det_info) adm_info
                             WHERE s.code_message = adm_info.desc_info
                               AND s.id_language = i_lang
                               AND pva.id_pat_vacc_adm = vacc_ids.id
                                  --estados: N - n�o administrado(relato), A - administrado, R - requisistado, C -cancelado
                               AND pva.flg_status IN
                                   (pk_alert_constant.g_no, pk_alert_constant.g_active, 'R', 'C', g_day)
                               AND pva.id_episode_destination IS NULL
                             ORDER BY id_test, adm_info.id)
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           get_prof_resp_info(i_lang, i_prof, pvad.id_prof_writes, pvad.dt_reg, pvad.id_episode) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           vacc_ids.id id_test
                      FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, TABLE(l_vacc_ids) vacc_ids
                     WHERE pva.id_pat_vacc_adm = vacc_ids.id
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL;
            
            END IF;
        ELSE
            --title
            o_presc_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T019');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_adm_det TO GET THE ADMINISTRATION DETAILS';
            pk_types.open_my_cursor(o_presc_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_VACC_PRESC_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_presc_det);
                RETURN FALSE;
            END;
    END get_vacc_presc_det;
    --

    /************************************************************************************************************
    * This function returns the administration details for the specified tuberculin test if any or else
    * the administration details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_adm_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_test_state VARCHAR2(1);
    
        l_tests_ids     table_info := table_info();
        l_tests_ids_pos NUMBER(3) := 1;
    
        -- vari�vel para verifica��o de exist�ncia de Respons�vel pela administra��o
        l_reading_res       VARCHAR2(100) := get_value_det(i_lang, i_prof, i_test_id, 'TUBERCULIN_TEST_T018');
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        --procura todos os ids de testes
        CURSOR c_tests IS
            SELECT dp.id_drug_prescription id --, d.code_drug desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        l_test_state := get_tuberculin_test_state(i_test_id);
        --if i_to_add is false indica que estamos num ecr� de resumo
        --if i_to_add is true indica que estamos nun ecr� de registo de informa��o.
        --se o estado � administra��o vamos adicionar resultados
        IF NOT i_to_add
           OR l_test_state IN (g_tuberculin_test_state_adm, g_tuberculin_test_state_res)
        THEN
        
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T012');
            IF i_test_id IS NOT NULL
            THEN
                --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
                -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
                g_error := 'OPEN CURSOR o_adm_det TO GET THE ADMINISTRATION DETAILS';
                IF l_reading_res = '--'
                THEN
                    OPEN o_adm_det FOR
                        SELECT det_name, det_value, desc_resp, flg_show, id_test
                          FROM (SELECT s.desc_message det_name,
                                       --get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                                       REPLACE(get_value_det(i_lang, i_prof, i_test_id, s.code_message),
                                               'TUBERCULIN_TEST_T018',
                                               pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T018')) det_value,
                                       '' desc_resp,
                                       pk_alert_constant.g_yes flg_show,
                                       i_test_id id_test
                                  FROM sys_message s
                                 WHERE s.code_message IN ('TUBERCULIN_TEST_T013',
                                                          'TUBERCULIN_TEST_T014',
                                                          'TUBERCULIN_TEST_T015',
                                                          'TUBERCULIN_TEST_T016',
                                                          'VACC_T086',
                                                          'TUBERCULIN_TEST_T017',
                                                          'VACC_T085')
                                   AND s.id_language = i_lang
                                      --apenas se o estado � Lido
                                   AND l_test_state = g_tuberculin_test_state_adm
                                 ORDER BY s.code_message)
                        UNION ALL
                        --Adicionar informa��o sobre o profissional respons�vel
                        SELECT '' det_name,
                               '' det_value,
                               decode(dpp.id_prof_adm,
                                      NULL,
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dp.id_professional,
                                                         dp.dt_drug_prescription_tstz,
                                                         dp.id_episode),
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dpp.id_prof_adm,
                                                         dpp.dt_take_tstz,
                                                         dpp.id_episode)) desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               i_test_id id_test
                          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp -- p2, dpd, dpp : NEW
                         WHERE dp.id_drug_prescription = i_test_id
                           AND dpd.id_drug_prescription = dp.id_drug_prescription -- NEW
                           AND dpd.id_drug_presc_det = dpp.id_drug_presc_det -- NEW
                              --apenas se o estado � Administrado
                           AND l_test_state = g_tuberculin_test_state_adm;
                ELSE
                    OPEN o_adm_det FOR
                        SELECT det_name, det_value, desc_resp, flg_show, id_test
                          FROM (SELECT s.desc_message det_name,
                                       get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                                       '' desc_resp,
                                       pk_alert_constant.g_yes flg_show,
                                       i_test_id id_test
                                  FROM sys_message s
                                 WHERE s.code_message IN ('TUBERCULIN_TEST_T013',
                                                          'TUBERCULIN_TEST_T014',
                                                          'TUBERCULIN_TEST_T015',
                                                          'TUBERCULIN_TEST_T016',
                                                          'VACC_T086',
                                                          'TUBERCULIN_TEST_T017',
                                                          'TUBERCULIN_TEST_T018',
                                                          'VACC_T085')
                                   AND s.id_language = i_lang
                                      --apenas se o estado � Lido
                                   AND l_test_state = g_tuberculin_test_state_adm
                                 ORDER BY s.code_message)
                        UNION ALL
                        --Adicionar informa��o sobre o profissional respons�vel
                        SELECT '' det_name,
                               '' det_value,
                               decode(dpp.id_prof_adm,
                                      NULL,
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dp.id_professional,
                                                         dp.dt_drug_prescription_tstz,
                                                         dp.id_episode),
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dpp.id_prof_adm,
                                                         dpp.dt_take_tstz,
                                                         dpp.id_episode)) desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               i_test_id id_test
                          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp -- p2, dpd, dpp : NEW
                         WHERE dp.id_drug_prescription = i_test_id
                           AND dpd.id_drug_prescription = dp.id_drug_prescription -- NEW
                           AND dpd.id_drug_presc_det = dpp.id_drug_presc_det -- NEW
                              --apenas se o estado � Administrado
                           AND l_test_state = g_tuberculin_test_state_adm;
                END IF;
            
            ELSE
            
                FOR l_test_cur IN c_tests
                LOOP
                    l_tests_ids.extend;
                    l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                    l_tests_ids_pos := l_tests_ids_pos + 1;
                END LOOP;
            
                OPEN o_adm_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT s.desc_message det_name,
                                   --get_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                                   REPLACE(get_value_det(i_lang, i_prof, test_ids.id, s.code_message),
                                           'TUBERCULIN_TEST_T018',
                                           pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T018')) det_value,
                                   '' desc_resp,
                                   pk_alert_constant.g_yes flg_show,
                                   test_ids.id id_test
                              FROM sys_message s, TABLE(l_tests_ids) test_ids
                             WHERE ((s.code_message IN ('TUBERCULIN_TEST_T013',
                                                        'TUBERCULIN_TEST_T014',
                                                        'TUBERCULIN_TEST_T015',
                                                        'TUBERCULIN_TEST_T016',
                                                        'VACC_T086',
                                                        'TUBERCULIN_TEST_T017',
                                                        'TUBERCULIN_TEST_T018',
                                                        'VACC_T085') AND
                                   get_value_det(i_lang, i_prof, test_ids.id, s.code_message) != '--') OR
                                   (s.code_message IN ('TUBERCULIN_TEST_T013',
                                                        'TUBERCULIN_TEST_T014',
                                                        'TUBERCULIN_TEST_T015',
                                                        'TUBERCULIN_TEST_T016',
                                                        'VACC_T086',
                                                        'TUBERCULIN_TEST_T017',
                                                        'VACC_T085') AND
                                   get_value_det(i_lang, i_prof, test_ids.id, s.code_message) = '--'))
                               AND s.id_language = i_lang
                                  --apenas se o estado � Administrado
                               AND get_tuberculin_test_state(test_ids.id) IN
                                   (g_tuberculin_test_state_adm,
                                    g_tuberculin_test_state_res,
                                    g_tuberculin_test_state_canc)
                             ORDER BY id_test, s.code_message)
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           decode(dpp.id_prof_adm,
                                  NULL,
                                  get_prof_resp_info(i_lang,
                                                     i_prof,
                                                     dp.id_professional,
                                                     dp.dt_drug_prescription_tstz,
                                                     dp.id_episode),
                                  get_prof_resp_info(i_lang, i_prof, dpp.id_prof_adm, dpp.dt_take_tstz, dpp.id_episode)) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           test_ids.id id_test
                      FROM drug_prescription dp, TABLE(l_tests_ids) test_ids, drug_presc_det dpd, drug_presc_plan dpp -- p2, dpd, dpp : NEW
                     WHERE dp.id_drug_prescription = test_ids.id
                       AND dpd.id_drug_prescription = dp.id_drug_prescription -- NEW
                       AND dpd.id_drug_presc_det = dpp.id_drug_presc_det -- NEW
                       AND get_tuberculin_test_state(test_ids.id) IN
                           (g_tuberculin_test_state_adm, g_tuberculin_test_state_res, g_tuberculin_test_state_canc);
            
            END IF;
        ELSE
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T019');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_adm_det TO GET THE ADMINISTRATION DETAILS';
            OPEN o_adm_det FOR
                SELECT rtrim(det_name, ':') det_name
                  FROM (SELECT s.desc_message det_name, s.code_message code_message
                          FROM sys_message s
                         WHERE s.code_message IN ('TUBERCULIN_TEST_T013',
                                                  'TUBERCULIN_TEST_T014',
                                                  'TUBERCULIN_TEST_T015',
                                                  'TUBERCULIN_TEST_T016',
                                                  'VACC_T086',
                                                  'TUBERCULIN_TEST_T018',
                                                  'VACC_T085')
                           AND s.id_language = i_lang
                         ORDER BY code_message)
                UNION ALL -- o Union separado � para manter a ordem desejada
                SELECT rtrim(s.desc_message, ':') det_name
                  FROM sys_message s
                 WHERE s.code_message IN ('TUBERCULIN_TEST_T017')
                   AND s.id_language = i_lang;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_TEST_ADM_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_adm_det);
                RETURN FALSE;
            END;
    END get_tuberculin_test_adm_det;
    --
    FUNCTION get_vacc_advers_react_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_test_state VARCHAR2(1);
    
        l_tests_ids table_info := table_info();
    
        l_vacc_adm_ids table_info := table_info();
    
        l_tests_ids_pos NUMBER(3) := 1;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        --procura todos os ids de vacinas fora do PNV ou relatos (gravados nas tabelas pat_vacc_adm*)
        --apenas para vacinas que tenham j� sido administradas
        CURSOR c_tests IS
            SELECT pva.id_pat_vacc_adm id, '' desc_info
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_vacc = i_test_id
               AND pva.id_patient = i_patient
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND (pvad.dt_take IS NOT NULL AND pva.flg_orig = 'V' OR pva.flg_orig IN ('R', 'I'))
               AND pva.id_episode_destination IS NULL;
    
        --procura todos os ids de vacinas do PNV administradas
        CURSOR c_vacc_adm IS
            SELECT dpp.id_drug_presc_plan id, '' desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_dci vd, vacc v
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug = mim.id_drug
               AND vd.id_vacc = i_test_id
               AND v.id_vacc = vd.id_vacc
               AND vd.id_dci = mim.dci_id
               AND mim.vers = l_version
            UNION ALL
            -- vacinas do PNV antigas
            SELECT dp.id_drug_prescription id, '' desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_med_ext vme -- drug d
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_test_id;
    
    BEGIN
    
        --title
        o_advers_react_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T063');
    
        FOR l_test_cur IN c_tests
        LOOP
            l_tests_ids.extend;
            l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
            l_tests_ids_pos := l_tests_ids_pos + 1;
        END LOOP;
    
        --set a 1
        l_tests_ids_pos := 1;
        FOR l_vacc_adm_cur IN c_vacc_adm
        LOOP
            l_vacc_adm_ids.extend;
            l_vacc_adm_ids(l_tests_ids_pos) := info(l_vacc_adm_cur.id, NULL, NULL);
            l_tests_ids_pos := l_tests_ids_pos + 1;
        END LOOP;
    
        --Explica��o:
        -- A nested table 'l_tests_ids' tem os id dos v�rios registos nas tabelas pat_vacc_adm (relatos e vacinas fora do PNV)
        -- A nested table 'l_vacc_adm_ids' tem os id dos v�rios registos nas tabelas drug_prescription (vacinas do PNV)
        -- 1 � necess�rio fazer um union destes dois casos.
    
        -- A nested table 'l_adm_det_info' tem os uma lista com a informa��o que vai ser apresentada no ecr�, e com a sua ordena��o
        -- � necess�rio cruzar com esta nested table para saber quais os campos a apresentar!
        OPEN o_advers_react_det FOR
            SELECT det_name, det_value, desc_resp, flg_show, id_test, dt, first_show
              FROM (
                    --vacinas fora do PNV e relatos
                    SELECT pk_message.get_message(i_lang, 'TUBERCULIN_TEST_M005') det_name,
                            var.notes_advers_react det_value,
                            '' desc_resp,
                            --a label Origem do relato apenas � apresentada para os relatos...
                            pk_alert_constant.g_yes flg_show,
                            test_ids.id             id_test,
                            var.dt_prof_write       dt,
                            1                       first_show
                      FROM vacc_advers_react var, TABLE(l_tests_ids) test_ids
                     WHERE var.id_reg = test_ids.id
                       AND var.flg_type = 'O'
                    UNION ALL
                    --vacinas do plano
                    SELECT pk_message.get_message(i_lang, 'TUBERCULIN_TEST_M005') det_name,
                            var.notes_advers_react det_value,
                            '' desc_resp,
                            --a label Origem do relato apenas � apresentada para os relatos...
                            pk_alert_constant.g_yes  flg_show,
                            dpd.id_drug_prescription id_test,
                            var.dt_prof_write        dt,
                            1                        first_show
                      FROM vacc_advers_react var,
                            TABLE(l_vacc_adm_ids) vacc_adm_ids,
                            drug_presc_plan dpp,
                            drug_presc_det dpd
                     WHERE var.id_reg = vacc_adm_ids.id
                       AND var.flg_type = 'V'
                       AND var.id_reg = dpp.id_drug_presc_plan
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                     ORDER BY id_test, dt)
            UNION ALL
            SELECT '' det_name,
                   '' det_value,
                   get_prof_resp_info(i_lang, i_prof, var.id_prof_write, var.dt_prof_write, NULL) desc_resp,
                   pk_alert_constant.g_yes flg_show,
                   test_ids.id id_test,
                   var.dt_prof_write dt,
                   2 first_show
              FROM vacc_advers_react var, TABLE(l_tests_ids) test_ids
             WHERE var.id_reg = test_ids.id
               AND var.flg_type = 'O'
            UNION ALL
            SELECT '' det_name,
                   '' det_value,
                   get_prof_resp_info(i_lang, i_prof, var.id_prof_write, var.dt_prof_write, NULL) desc_resp,
                   pk_alert_constant.g_yes flg_show,
                   dpd.id_drug_prescription id_test,
                   var.dt_prof_write dt,
                   2 first_show
              FROM vacc_advers_react var, TABLE(l_vacc_adm_ids) vacc_adm_ids, drug_presc_plan dpp, drug_presc_det dpd
             WHERE var.id_reg = vacc_adm_ids.id
               AND var.flg_type = 'V'
               AND var.id_reg = dpp.id_drug_presc_plan
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
             ORDER BY id_test, dt, first_show;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_VACC_ADVERS_REACT_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_advers_react_det);
                RETURN FALSE;
            END;
    END get_vacc_advers_react_det;

    /************************************************************************************************************
    * This function returns the administration details for the specified vaccine take, if any, or else
    * the administration details for all vaccines for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_vacc_adm_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT p_adm_det_cur,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_test_state VARCHAR2(1);
    
        l_tests_ids table_info := table_info();
    
        l_vacc_adm_ids table_info := table_info();
    
        l_adm_det_info table_info := table_info();
    
        l_tests_ids_pos NUMBER(3) := 1;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        --procura todos os ids de vacinas fora do PNV ou relatos (gravados nas tabelas pat_vacc_adm*)
        --apenas para vacinas que tenham j� sido administradas
        CURSOR c_tests IS
            SELECT pva.id_pat_vacc_adm id, '' desc_info
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_vacc = i_test_id
               AND pva.id_patient = i_patient
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND (pvad.dt_take IS NOT NULL AND pva.flg_orig = 'V' OR pva.flg_orig IN ('R', 'I'))
               AND pva.id_episode_destination IS NULL;
    
        --procura todos os ids de vacinas do PNV administradas
        CURSOR c_vacc_adm IS
            SELECT dp.id_drug_prescription id, '' desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_dci vd, vacc v
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug = mim.id_drug
               AND vd.id_vacc = i_test_id
               AND v.id_vacc = vd.id_vacc
               AND vd.id_dci = mim.dci_id
               AND mim.vers = l_version
            UNION ALL
            -- vacinas do PNV antigas
            SELECT dp.id_drug_prescription id, '' desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_med_ext vme -- drug d
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_test_id;
    
    BEGIN
    
        IF NOT i_to_add
        THEN
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T012');
        
            FOR l_test_cur IN c_tests
            LOOP
                l_tests_ids.extend;
                l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            --set a 1
            l_tests_ids_pos := 1;
            FOR l_vacc_adm_cur IN c_vacc_adm
            LOOP
                l_vacc_adm_ids.extend;
                l_vacc_adm_ids(l_tests_ids_pos) := info(l_vacc_adm_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            l_adm_det_info := format_screen_info(i_lang, 'ADM_VACC', o_error);
        
            --Explica��o:
            -- A nested table 'l_tests_ids' tem os id dos v�rios registos nas tabelas pat_vacc_adm (relatos e vacinas fora do PNV)
            -- A nested table 'l_vacc_adm_ids' tem os id dos v�rios registos nas tabelas drug_prescription (vacinas do PNV)
            -- 1 � necess�rio fazer um union destes dois casos.
        
            -- A nested table 'l_adm_det_info' tem os uma lista com a informa��o que vai ser apresentada no ecr�, e com a sua ordena��o
            -- � necess�rio cruzar com esta nested table para saber quais os campos a apresentar!
        
            OPEN o_adm_det FOR
                SELECT det_name, det_value, desc_resp, flg_show, id_test
                  FROM (
                        --vacinas fora do PNV e relatos
                        SELECT rtrim(s.desc_message, ':') || ':' det_name, --garante que todas as labels terminam em :
                                get_oth_vacc_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                                '' desc_resp,
                                --a label Origem do relato apenas � apresentada para os relatos...
                                decode(s.code_message,
                                       'VACC_T036', -- 'Origem do relato', apenas dispon�vel para relatos
                                       decode(pva.flg_reported,
                                              pk_alert_constant.g_yes,
                                              pk_alert_constant.g_yes,
                                              decode(pva.flg_orig, g_orig_r, pk_alert_constant.g_yes, pk_alert_constant.g_no)),
                                       'TUBERCULIN_TEST_T018', -- 'Respons�vel pela administra��o', nas importa��es do SINUS n�o h�
                                       decode(pva.flg_orig, g_orig_i, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                       pk_alert_constant.g_yes) flg_show,
                                test_ids.id id_test,
                                adm_info.id id_label
                          FROM sys_message s,
                                pat_vacc_adm pva,
                                TABLE(l_tests_ids) test_ids,
                                TABLE(l_adm_det_info) adm_info
                         WHERE s.code_message IN (SELECT adm_info.desc_info
                                                    FROM TABLE(l_adm_det_info) adm_info)
                           AND s.id_language = i_lang
                           AND pva.id_pat_vacc_adm = test_ids.id
                           AND s.code_message = adm_info.desc_info
                           AND pva.id_episode_destination IS NULL
                        UNION ALL
                        --vacinas do plano
                        SELECT rtrim(s.desc_message, ':') || ':' det_name, --garante que todas as labels terminam em :
                                get_vacc_value_det(i_lang, i_prof, vacc_adm_ids.id, s.code_message) det_value,
                                '' desc_resp,
                                --a label Origem do relato apenas � apresentada para os relatos...
                                decode(s.code_message, 'VACC_T036', pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_show,
                                vacc_adm_ids.id id_test,
                                adm_info.id id_label
                          FROM sys_message s,
                                drug_prescription dp,
                                TABLE(l_vacc_adm_ids) vacc_adm_ids,
                                TABLE(l_adm_det_info) adm_info
                         WHERE s.code_message IN (SELECT adm_info.desc_info
                                                    FROM TABLE(l_adm_det_info) adm_info)
                           AND s.id_language = i_lang
                           AND dp.id_drug_prescription = vacc_adm_ids.id
                           AND s.code_message = adm_info.desc_info
                         ORDER BY id_test, id_label)
                UNION ALL
                SELECT '' det_name,
                       '' det_value,
                       decode(pva.flg_orig,
                              g_orig_i,
                              pk_date_utils.date_char_tsz(i_lang,
                                                          nvl(pvad.dt_reg, pvad.dt_take),
                                                          i_prof.institution,
                                                          i_prof.software),
                              pk_tools.get_prof_description(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            decode(pva.flg_orig, g_orig_r, pvad.dt_reg, pvad.dt_take),
                                                            pva.id_episode) || ' / ' ||
                              pk_date_utils.date_char_tsz(i_lang,
                                                          decode(pva.flg_orig,
                                                                 g_orig_r,
                                                                 pvad.dt_reg,
                                                                 g_orig_v,
                                                                 pvad.dt_reg,
                                                                 pvad.dt_take),
                                                          i_prof.institution,
                                                          i_prof.software)) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       test_ids.id id_test
                  FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p, TABLE(l_tests_ids) test_ids
                 WHERE pva.id_pat_vacc_adm = test_ids.id
                   AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
                   AND p.id_professional = pvad.id_prof_writes
                   AND pva.id_episode_destination IS NULL
                UNION ALL
                SELECT '' det_name,
                       '' det_value,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     p.id_professional,
                                                     dp.dt_drug_prescription_tstz,
                                                     dp.id_episode) || ' / ' ||
                       pk_date_utils.date_char_tsz(i_lang,
                                                   dp.dt_drug_prescription_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       vacc_adm_ids.id id_test
                  FROM drug_prescription dp, professional p, TABLE(l_vacc_adm_ids) vacc_adm_ids
                 WHERE dp.id_drug_prescription = vacc_adm_ids.id
                   AND p.id_professional = dp.id_professional;
        
        ELSE
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T019');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_adm_det TO GET THE ADMINISTRATION DETAILS';
            pk_types.open_my_cursor(o_adm_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_VACC_ADM_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_adm_det);
                RETURN FALSE;
            END;
    END get_vacc_adm_det;
    --

    /************************************************************************************************************
    * This function returns the result details for the specified tuberculin test if any or else
    * the result details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_res_title        title for the prescription details
    * @param      o_res_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_res_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_test_state VARCHAR2(1);
    
        l_tests_ids     table_info := table_info();
        l_tests_ids_pos NUMBER(3) := 1;
    
        -- vari�vel para verifica��o de exist�ncia de Respons�vel pela leitura
        l_reading_res       VARCHAR2(100) := get_value_det(i_lang, i_prof, i_test_id, 'TUBERCULIN_TEST_T026');
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        --procura todos os ids de testes
        CURSOR c_tests IS
            SELECT dp.id_drug_prescription id --, d.code_drug desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        l_test_state := get_tuberculin_test_state(i_test_id);
        --if false indica que estamos num ecr� de resumo
        --if true indica que estamos nun ecr� de registo de informa��o.
        IF NOT i_to_add
        THEN
            --title
            BEGIN
                o_res_title := rtrim(pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T020'), ':');
            EXCEPTION
                WHEN OTHERS THEN
                    o_res_title := '';
            END;
        
            IF i_test_id IS NOT NULL
            THEN
            
                --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
                -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
                g_error := 'OPEN CURSOR o_res_det TO GET THE RESULT DETAILS';
                IF l_reading_res = '--'
                THEN
                    OPEN o_res_det FOR
                        SELECT det_name, det_value, desc_resp, flg_show, id_test
                          FROM (SELECT s.desc_message det_name,
                                       --get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                                       REPLACE(get_value_det(i_lang, i_prof, i_test_id, s.code_message),
                                               'TUBERCULIN_TEST_T026',
                                               pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T026')) det_value,
                                       '' desc_resp,
                                       pk_alert_constant.g_yes flg_show,
                                       i_test_id id_test
                                  FROM sys_message s
                                 WHERE s.code_message IN ('TUBERCULIN_TEST_T021',
                                                          'TUBERCULIN_TEST_T022',
                                                          'TUBERCULIN_TEST_T023',
                                                          'TUBERCULIN_TEST_T024',
                                                          'TUBERCULIN_TEST_T025')
                                   AND s.id_language = i_lang
                                      --apenas se o estado � Lido
                                   AND l_test_state = g_tuberculin_test_state_res
                                 ORDER BY s.code_message)
                        UNION ALL
                        --Adicionar informa��o sobre o profissional respons�vel
                        SELECT '' det_name,
                               '' det_value,
                               decode(dpr.id_prof_resp_adm,
                                      NULL,
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dp.id_professional,
                                                         dp.dt_drug_prescription_tstz,
                                                         dp.id_episode),
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dpr.id_prof_resp_adm,
                                                         dpr.dt_drug_presc_result,
                                                         NULL)) desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               i_test_id id_test
                          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr -- p2, dpd, dpp, dpr: NEW
                         WHERE dp.id_drug_prescription = i_test_id
                           AND dp.id_drug_prescription = dpd.id_drug_prescription -- NEW
                           AND dpp.id_drug_presc_det = dpd.id_drug_presc_det -- NEW
                           AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan -- NEW
                              --apenas se o estado � Lido
                           AND l_test_state = g_tuberculin_test_state_res;
                ELSE
                    OPEN o_res_det FOR
                        SELECT det_name, det_value, desc_resp, flg_show, id_test
                          FROM (SELECT s.desc_message det_name,
                                       get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                                       '' desc_resp,
                                       pk_alert_constant.g_yes flg_show,
                                       i_test_id id_test
                                  FROM sys_message s
                                 WHERE s.code_message IN ('TUBERCULIN_TEST_T021',
                                                          'TUBERCULIN_TEST_T022',
                                                          'TUBERCULIN_TEST_T023',
                                                          'TUBERCULIN_TEST_T024',
                                                          'TUBERCULIN_TEST_T025',
                                                          'TUBERCULIN_TEST_T026')
                                   AND s.id_language = i_lang
                                      --apenas se o estado � Lido
                                   AND l_test_state = g_tuberculin_test_state_res
                                 ORDER BY s.code_message)
                        UNION ALL
                        --Adicionar informa��o sobre o profissional respons�vel
                        SELECT '' det_name,
                               '' det_value,
                               decode(dpr.id_prof_resp_adm,
                                      NULL,
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dp.id_professional,
                                                         dp.dt_drug_prescription_tstz,
                                                         dp.id_episode),
                                      get_prof_resp_info(i_lang,
                                                         i_prof,
                                                         dpr.id_prof_resp_adm,
                                                         dpr.dt_drug_presc_result,
                                                         NULL)) desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               i_test_id id_test
                          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr -- p2, dpd, dpp, dpr: NEW
                         WHERE dp.id_drug_prescription = i_test_id
                           AND dp.id_drug_prescription = dpd.id_drug_prescription -- NEW
                           AND dpp.id_drug_presc_det = dpd.id_drug_presc_det -- NEW
                           AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan -- NEW
                              --apenas se o estado � Lido
                           AND l_test_state = g_tuberculin_test_state_res;
                END IF;
            ELSE
            
                FOR l_test_cur IN c_tests
                LOOP
                    l_tests_ids.extend;
                    l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                    l_tests_ids_pos := l_tests_ids_pos + 1;
                END LOOP;
            
                g_error := 'OPEN CURSOR o_res_det TO GET THE RESULT DETAILS';
                OPEN o_res_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT s.desc_message det_name,
                                   --get_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                                   REPLACE(get_value_det(i_lang, i_prof, test_ids.id, s.code_message),
                                           'TUBERCULIN_TEST_T026',
                                           pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T026')) det_value,
                                   '' desc_resp,
                                   pk_alert_constant.g_yes flg_show,
                                   test_ids.id id_test
                              FROM sys_message s, TABLE(l_tests_ids) test_ids
                             WHERE ((s.code_message IN ('TUBERCULIN_TEST_T021',
                                                        'TUBERCULIN_TEST_T022',
                                                        'TUBERCULIN_TEST_T023',
                                                        'TUBERCULIN_TEST_T024',
                                                        'TUBERCULIN_TEST_T025',
                                                        'TUBERCULIN_TEST_T026') AND
                                   get_value_det(i_lang, i_prof, test_ids.id, s.code_message) != '--') OR
                                   (s.code_message IN ('TUBERCULIN_TEST_T021',
                                                        'TUBERCULIN_TEST_T022',
                                                        'TUBERCULIN_TEST_T023',
                                                        'TUBERCULIN_TEST_T024',
                                                        'TUBERCULIN_TEST_T025') AND
                                   get_value_det(i_lang, i_prof, test_ids.id, s.code_message) = '--'))
                               AND s.id_language = i_lang
                                  --apenas se o estado � Lido
                               AND get_tuberculin_test_state(test_ids.id) = g_tuberculin_test_state_res
                             ORDER BY id_test, s.code_message)
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           decode(dpr.id_prof_resp_adm,
                                  NULL,
                                  get_prof_resp_info(i_lang,
                                                     i_prof,
                                                     dp.id_professional,
                                                     dp.dt_drug_prescription_tstz,
                                                     dp.id_episode),
                                  get_prof_resp_info(i_lang,
                                                     i_prof,
                                                     dpr.id_prof_resp_adm,
                                                     dpr.dt_drug_presc_result,
                                                     NULL)) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           test_ids.id id_test
                      FROM drug_prescription dp,
                           TABLE(l_tests_ids) test_ids,
                           drug_presc_det dpd,
                           drug_presc_plan dpp,
                           drug_presc_result dpr -- p2, dpd, dpp, dpr: NEW
                     WHERE dp.id_drug_prescription = test_ids.id
                       AND dp.id_drug_prescription = dpd.id_drug_prescription -- NEW
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det -- NEW
                       AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan -- NEW
                          --apenas se o estado � Lido
                       AND get_tuberculin_test_state(test_ids.id) = g_tuberculin_test_state_res;
            END IF;
        
        ELSIF l_test_state = g_tuberculin_test_state_adm
        THEN
            --title
            o_res_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T027');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_res_det TO GET THE RESULT DETAILS';
            OPEN o_res_det FOR
                SELECT rtrim(det_name, ':') det_name
                  FROM (SELECT s.desc_message det_name
                          FROM sys_message s
                         WHERE s.code_message IN ('TUBERCULIN_TEST_T010',
                                                  'TUBERCULIN_TEST_T020',
                                                  'TUBERCULIN_TEST_T022',
                                                  'TUBERCULIN_TEST_T023',
                                                  'TUBERCULIN_TEST_T026')
                           AND s.id_language = i_lang
                         ORDER BY s.code_message)
                UNION ALL -- o Union separada � para manter a ordem desejada
                SELECT rtrim(s.desc_message, ':') det_name
                  FROM sys_message s
                 WHERE s.code_message IN ('TUBERCULIN_TEST_T025')
                   AND s.id_language = i_lang;
        ELSE
            --Neste caso estamos a adicionar valores de administra��o, pelo que n�o h� dados para os resultados.
            --title
            o_res_title := '';
        
            g_error := 'OPEN CURSOR o_res_det TO GET THE RESULT DETAILS';
            pk_types.open_my_cursor(o_res_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_TEST_RES_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_res_det);
                RETURN FALSE;
            END;
    END get_tuberculin_test_res_det;
    --

    /************************************************************************************************************
    * This function returns the result details for the specified tuberculin test if any or else
    * the result details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_res_title        title for the prescription details
    * @param      o_res_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_can_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_test_state VARCHAR2(1);
    
        l_tests_ids         table_info := table_info();
        l_tests_ids_pos     NUMBER(3) := 1;
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        --procura todos os ids de testes
        CURSOR c_tests IS
        
            SELECT DISTINCT dp.id_drug_prescription id --, d.code_drug desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id
             ORDER BY id;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        l_test_state := get_tuberculin_test_state(i_test_id);
        --if false indica que estamos num ecr� de resumo
        --if true indica que estamos nun ecr� de registo de informa��o.
        IF NOT i_to_add
        THEN
            --title
            BEGIN
                o_can_title := rtrim(pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T055'), ':');
            EXCEPTION
                WHEN OTHERS THEN
                    o_can_title := '';
            END;
        
            IF i_test_id IS NOT NULL
            THEN
            
                --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
                -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
                g_error := 'OPEN CURSOR o_res_det TO GET THE CANCEL DETAILS';
                OPEN o_can_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT s.desc_message || ':' det_name,
                                   get_value_det(i_lang, i_prof, i_test_id, s.code_message) det_value,
                                   '' desc_resp,
                                   pk_alert_constant.g_yes flg_show,
                                   i_test_id id_test
                              FROM sys_message s
                             WHERE s.code_message IN
                                   ('TUBERCULIN_TEST_T056', 'TUBERCULIN_TEST_T057', 'TUBERCULIN_TEST_T058')
                               AND s.id_language = i_lang
                                  --apenas se o estado � Lido
                               AND l_test_state = g_tuberculin_test_state_canc
                             ORDER BY s.code_message)
                    UNION ALL
                    --Adicionar informa��o sobre o profissional respons�vel
                    SELECT '' det_name,
                           '' det_value,
                           get_prof_resp_info(i_lang,
                                              i_prof,
                                              dp.id_professional,
                                              dp.dt_drug_prescription_tstz,
                                              dp.id_episode) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           i_test_id id_test
                      FROM drug_prescription dp
                     WHERE dp.id_drug_prescription = i_test_id
                          --apenas se o estado � Lido
                       AND l_test_state = g_tuberculin_test_state_canc;
            
            ELSE
            
                FOR l_test_cur IN c_tests
                LOOP
                    l_tests_ids.extend;
                    l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                    l_tests_ids_pos := l_tests_ids_pos + 1;
                END LOOP;
            
                OPEN o_can_det FOR
                    SELECT det_name, det_value, desc_resp, flg_show, id_test
                      FROM (SELECT s.desc_message || ':' det_name,
                                   get_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                                   '' desc_resp,
                                   pk_alert_constant.g_yes flg_show,
                                   test_ids.id id_test
                              FROM sys_message s, TABLE(l_tests_ids) test_ids
                             WHERE s.code_message IN
                                   ('TUBERCULIN_TEST_T056', 'TUBERCULIN_TEST_T057', 'TUBERCULIN_TEST_T058')
                               AND s.id_language = i_lang
                                  --apenas se o estado � Cancelado
                               AND get_tuberculin_test_state(test_ids.id) = g_tuberculin_test_state_canc
                             ORDER BY id_test, s.code_message)
                    UNION ALL
                    SELECT '' det_name,
                           '' det_value,
                           get_prof_resp_info(i_lang,
                                              i_prof,
                                              dp.id_professional,
                                              dp.dt_drug_prescription_tstz,
                                              dp.id_episode) desc_resp,
                           pk_alert_constant.g_yes flg_show,
                           test_ids.id id_test
                      FROM drug_prescription dp, TABLE(l_tests_ids) test_ids
                     WHERE dp.id_drug_prescription = test_ids.id
                          --apenas se o estado � Lido
                       AND get_tuberculin_test_state(test_ids.id) = g_tuberculin_test_state_canc;
            
            END IF;
        ELSE
            --Neste caso estamos a adicionar valores de administra��o, pelo que n�o h� dados para os resultados.
            --title
            o_can_title := '';
        
            g_error := 'OPEN CURSOR o_res_det  TO GET THE RESULT DETAILS';
            pk_types.open_my_cursor(o_can_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_TEST_CAN_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_can_det);
                RETURN FALSE;
            END;
    END get_tuberculin_test_can_det;
    --

    /************************************************************************************************************
    * This function returns the cancel details for the specified vaccine take, if any, or else
    * the administration details for all vaccines for the patient
    *
    * @param      i_lang               language
    * @param      i_patient            patient's identifier
    * @param      i_prof               profisisonal
    * @param      i_test_id            vaccine ID
    * @param      i_to_add             true if it is a screen to add information
    *
    * @param      o_can_title        title for the cancel details
    * @param      o_can_det          cursor with record cancelation details
    * @param      o_error            error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/15
    ***********************************************************************************************************/
    FUNCTION get_vacc_canc_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tests_ids table_info := table_info();
    
        l_vacc_adm_ids table_info := table_info();
    
        l_adm_det_info table_info := table_info();
    
        l_tests_ids_pos NUMBER(3) := 1;
    
        --procura todos os ids de vacinas fora do PNV ou relatos (gravados nas tabelas pat_vacc_adm*)
        --apenas para vacinas que tenham j� sido administradas
        CURSOR c_tests IS
            SELECT pva.id_pat_vacc_adm id, '' desc_info
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_vacc = i_test_id
               AND pva.id_patient = i_patient
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.dt_cancel IS NOT NULL
               AND pva.id_episode_destination IS NULL;
    
        --procura todos os ids de vacinas do PNV administradas
        CURSOR c_vacc_adm IS
            SELECT dp.id_drug_prescription id, '' desc_info
              FROM drug_prescription dp,
                   drug_presc_det    dpd,
                   drug_presc_plan   dpp,
                   mi_med            mim,
                   --drug              d,
                   drug_pharma dph,
                   vacc_dci    vd
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
                  --AND d.id_drug_pharma = dph.id_drug_pharma
               AND dph.id_drug_pharma = vd.id_dci
               AND vd.id_vacc = i_test_id
            --AND mim.flg_type = 'V'
            UNION ALL
            -- vacinas do PNV antigas
            SELECT dp.id_drug_prescription id, '' desc_info
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_med_ext vme -- drug d
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_test_id;
    
    BEGIN
    
        IF NOT i_to_add
        THEN
            --title
            o_can_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T055');
        
            FOR l_test_cur IN c_tests
            LOOP
                l_tests_ids.extend;
                l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            --set a 1
            l_tests_ids_pos := 1;
            FOR l_vacc_adm_cur IN c_vacc_adm
            LOOP
                l_vacc_adm_ids.extend;
                l_vacc_adm_ids(l_tests_ids_pos) := info(l_vacc_adm_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            --formata os dados para o ecr�:
            l_adm_det_info.extend;
            l_adm_det_info(1) := info(1, 'TUBERCULIN_TEST_T056', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(2) := info(2, 'TUBERCULIN_TEST_T057', NULL);
            --
            l_adm_det_info.extend;
            l_adm_det_info(3) := info(3, 'TUBERCULIN_TEST_T058', NULL);
            --
        
            --Explica��o:
            -- A nested table 'l_tests_ids' tem os id dos v�rios registos nas tabelas pat_vacc_adm (relatos e vacinas fora do PNV)
            -- A nested table 'l_vacc_adm_ids' tem os id dos v�rios registos nas tabelas drug_prescription (vacinas do PNV)
            -- 1 � necess�rio fazer um union destes dois casos.
        
            -- A nested table 'l_adm_det_info' tem os uma lista com a informa��o que vai ser apresentada no ecr�, e com a sua ordena��o
            -- � necess�rio cruzar com esta nested table para saber quais os campos a apresentar!
        
            OPEN o_can_det FOR
                SELECT det_name, det_value, desc_resp, flg_show, id_test
                  FROM (SELECT s.desc_message || ':' det_name,
                               get_oth_vacc_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                               '' desc_resp,
                               pk_alert_constant.g_yes flg_show,
                               test_ids.id id_test,
                               adm_info.id id_label
                          FROM sys_message s,
                               pat_vacc_adm pva,
                               TABLE(l_tests_ids) test_ids,
                               TABLE(l_adm_det_info) adm_info
                         WHERE s.code_message IN (SELECT adm_info.desc_info
                                                    FROM TABLE(l_adm_det_info) adm_info)
                           AND s.id_language = i_lang
                           AND pva.id_pat_vacc_adm = test_ids.id
                           AND s.code_message = adm_info.desc_info
                           AND pva.id_episode_destination IS NULL)
                
                UNION ALL
                SELECT '' det_name,
                       '' det_value,
                       get_prof_resp_info(i_lang, i_prof, pva.id_prof_cancel, pva.dt_cancel, pva.id_episode) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       test_ids.id id_test
                  FROM pat_vacc_adm pva, TABLE(l_tests_ids) test_ids
                 WHERE pva.id_pat_vacc_adm = test_ids.id
                   AND pva.id_episode_destination IS NULL;
        
        ELSE
            --title
            o_can_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T055');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_adm_det TO GET THE CANCEL DETAILS';
            pk_types.open_my_cursor(o_can_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_VACC_CANC_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_can_det);
                RETURN FALSE;
            END;
    END get_vacc_canc_det;
    --

    /************************************************************************************************************
    * This function returns a string with the year for a specified TIMESTAMP
    *
    * @param      i_dt             date as a timestamp
    *
    * @return     year as a string
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_year_from_timestamp(i_dt TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR IS
    BEGIN
        --devolve o ano como uma string
        RETURN extract(YEAR FROM i_dt);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_year_from_timestamp;
    --

    /************************************************************************************************************
    * This function returns a string with the day for a specified TIMESTAMP
    *
    * @param      i_dt             date as a timestamp
    *
    * @return     day as string
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_day_from_timestamp(i_dt TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR IS
    BEGIN
        --devolve o ano como uma string
        RETURN extract(DAY FROM i_dt);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_day_from_timestamp;

    /************************************************************************************************************
    * This function returns a string with the month(abbreviation) for a specified TIMESTAMP (e.g. Nov)
    *
    * @param      i_lang           language
    * @param      i_dt             date as a timestamp
    *
    * @return     day and month(abbreviation) as a string
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_month_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR IS
    
    BEGIN
        --devolve o m�s como uma string
        RETURN substr(pk_date_utils.date_chr_space_tsz(i_lang, i_dt, 0, 0), 4, 3);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_month_from_timestamp;
    --

    /************************************************************************************************************
    * This function returns a string with the month(abbreviation) and year  separated by a space,
    *  for a specified TIMESTAMP (e.g. Nov 2007)
    *
    * @param      i_lang           language
    * @param      i_dt             date as a timestamp
    *
    * @return      month(abbreviation) and year as a string
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/17
    ***********************************************************************************************************/
    FUNCTION get_month_year_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR IS
    
    BEGIN
        --devolve o m�s como uma string
        RETURN get_month_from_timestamp(i_lang, i_dt) || ' ' || get_year_from_timestamp(i_dt);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_month_year_from_timestamp;
    --
    /************************************************************************************************************
    * Returns the timestamp that corresponds to the current tuberculin test state.
    *
    * @param      i_dt_presc              prescription date as a timestamp
    * @param      i_dt_take               administration date as a timestamp
    * @param      i_dt_result             results date as a timestamp
    *
    * @return     tuberculin test's state
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/30
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_timestamp
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    
    BEGIN
    
        IF i_dt_result IS NOT NULL
        THEN
            --j� existe resultado!
            l_timestamp := i_dt_result;
        ELSIF i_dt_take IS NOT NULL
        THEN
            --j� foi administrada a drug!
            l_timestamp := i_dt_take;
        ELSE
            --apenas foi prescrita
            l_timestamp := i_dt_presc;
        END IF;
    
        --apenas um local de return da fun��o (best practice)
        RETURN l_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_tuberculin_test_timestamp;
    --

    /************************************************************************************************************
    * Returns the tuberculin test's state: P - prescription; A - administration; R - results, for the
    * specified data details.
    *
    * @param      i_dt_presc              prescription date as a timestamp
    * @param      i_dt_take               administration date as a timestamp
    * @param      i_dt_result             results date as a timestamp
    *
    * @return     tuberculin test's state
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/30
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_state
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_state VARCHAR2(1) := '';
    BEGIN
    
        IF i_dt_cancel IS NOT NULL
        THEN
            --o registo foi cancelado
            l_state := g_tuberculin_test_state_canc;
        ELSIF i_dt_result IS NOT NULL
        THEN
            --j� existe resultado!
            l_state := g_tuberculin_test_state_res;
        ELSIF i_dt_take IS NOT NULL
        THEN
            --j� foi administrada a drug!
            l_state := g_tuberculin_test_state_adm;
        ELSE
            --apenas foi prescrita
            l_state := g_tuberculin_test_state_presc;
        END IF;
    
        --apenas um local de return da fun��o (best practice)
        RETURN l_state;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_tuberculin_test_state;
    --

    /************************************************************************************************************
    * Returns the tuberculin test's state: P - prescription; A - administration; R - results, for the specified
    * test id.
    *
    * @param      i_test_id
    *
    * @return     tuberculin test's state
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/10
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_state(i_test_id IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2 IS
    
        l_state VARCHAR2(1) := '';
    
        l_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_take   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_result TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_cancel TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        --get das datas para o teste indicado!
        SELECT DISTINCT dp.dt_drug_prescription_tstz, dpp.dt_take_tstz, dpr.dt_drug_presc_result, dp.dt_cancel_tstz
          INTO l_dt_presc, l_dt_take, l_dt_result, l_dt_cancel
          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, drug_presc_result dpr
         WHERE dp.id_drug_prescription = i_test_id
           AND dp.id_drug_prescription = dpd.id_drug_prescription
           AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
              -- and dpp.flg_status!='C' -- tomas canceladas
           AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan(+);
    
        l_state := get_tuberculin_test_state(i_dt_presc  => l_dt_presc,
                                             i_dt_take   => l_dt_take,
                                             i_dt_result => l_dt_result,
                                             i_dt_cancel => l_dt_cancel);
    
        --apenas um local de return da fun��o (best practice)
        RETURN l_state;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_tuberculin_test_state;
    --

    /************************************************************************************************************
    * Returns the minutes between two specified timestamps
    *
    * @param      i_current_dt       current date as a timestamp
    * @param      i_dt               date of thew previous state as a timestamp
    *
    * @return     string with the minutes
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_time_min
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_minutes VARCHAR2(100);
    
    BEGIN
    
        l_minutes := substr((i_current_dt - i_dt), instr((i_current_dt - i_dt), ' ') + 4, 2);
        RETURN l_minutes;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_time_min;
    --

    /************************************************************************************************************
    * Returns the hours between two specified timestamps
    *
    * @param      i_current_dt       current date as a timestamp
    * @param      i_dt               date of thew previous state as a timestamp
    *
    * @return     string with the hours
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_time_hour
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_hours VARCHAR2(100);
    
    BEGIN
        l_hours := substr((i_current_dt - i_dt), instr((i_current_dt - i_dt), ' ') + 1, 2);
        RETURN l_hours;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_time_hour;
    --

    /************************************************************************************************************
    * Returns the days between two specified timestamps
    *
    * @param      i_current_dt       current date as a timestamp
    * @param      i_dt               date of thew previous state as a timestamp
    *
    * @return     string with the days
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_time_day
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_days VARCHAR2(100);
    BEGIN
    
        l_days := trunc(to_number(substr((i_current_dt - i_dt), 1, instr(i_current_dt - i_dt, ' '))));
        RETURN l_days;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_time_day;
    --

    /************************************************************************************************************
    * Returns the icon to be shown in the summary screen
    *
    * @param      i_minutes     minutes after the previous state
    * @param      i_hours       hours after the previous state
    * @param      i_days        days after the previous state
    * @param      i_state       tuberculin test's state (P - prescription; A - administration; R - results)
    *
    * @return
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_value_icon
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2,
        i_result  IN drug_presc_result.id_evaluation%TYPE
    ) RETURN VARCHAR IS
    
        --icons
        l_icon_name VARCHAR2(100) := '';
    
        l_presc_icon  CONSTANT VARCHAR2(50) := 'TherapeuticIcon';
        l_wait_icon   CONSTANT VARCHAR2(50) := 'WaitingIcon';
        l_alert_icon  CONSTANT VARCHAR2(50) := 'AttencionIcon';
        l_cancel_icon CONSTANT VARCHAR2(50) := 'CancelIcon';
        --reading
        l_add_icon   CONSTANT VARCHAR2(50) := 'AddIcon';
        l_steal_icon CONSTANT VARCHAR2(50) := 'StealIcon';
        --Parametrizado na sys_domain
        l_result_id_positive CONSTANT VARCHAR(1) := pk_alert_constant.g_yes;
    
        --Exceptions
        cannot_find_icon EXCEPTION;
    
    BEGIN
    
        /*
        |=====================|
        | States:             |
        | P - prescription    |
        | A - administration  |
        | R - result          |
        | C - cancel          |          |
        |=====================|
        */
    
        CASE i_state
            WHEN g_tuberculin_test_state_canc THEN
                BEGIN
                    l_icon_name := l_cancel_icon;
                END;
            WHEN g_tuberculin_test_state_presc THEN
                BEGIN
                    l_icon_name := l_presc_icon;
                END;
            WHEN g_tuberculin_test_state_adm THEN
                BEGIN
                    IF i_days < 2 -- 48 horas
                    THEN
                        l_icon_name := l_wait_icon;
                    ELSE
                        l_icon_name := l_alert_icon;
                    END IF;
                END;
            WHEN g_tuberculin_test_state_res THEN
                BEGIN
                    --TODO : Apenas para efeitos de teste - Tem de ser corrigido [OA]
                    IF i_result = l_result_id_positive
                    THEN
                        l_icon_name := l_add_icon;
                    ELSE
                        l_icon_name := l_steal_icon;
                    END IF;
                END;
            ELSE
                BEGIN
                    RAISE cannot_find_icon;
                END;
        END CASE;
        RETURN l_icon_name;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_value_icon;
    --

    /************************************************************************************************************
    * Returns the label to be shown in the summary screen
    *
    * @param      i_minutes     minutes after the previous state
    * @param      i_hours       hours after the previous state
    * @param      i_days        days after the previous state
    * @param      i_state       tuberculin test's state (P - prescription; A - administration; R - results)
    *
    * @return     a label
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_value_label
    (
        i_lang      IN language.id_language%TYPE,
        i_minutes   IN VARCHAR2,
        i_hours     IN VARCHAR2,
        i_days      IN VARCHAR2,
        i_state     IN VARCHAR2,
        i_dt_cancel IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_value     IN drug_presc_result.value%TYPE
    ) RETURN VARCHAR IS
    
        --label
        l_label VARCHAR2(100) := '';
        l_label_sep CONSTANT VARCHAR2(1) := ':';
    
        --valor m�ximo do tempo para os testes � tuberculina
        l_max_test_time    CONSTANT NUMBER := 96;
        l_adm_ok_test_time CONSTANT NUMBER := 48;
        l_minutes          CONSTANT NUMBER := 60;
    
        l_minutes_temp VARCHAR2(2);
        l_hours_temp   VARCHAR2(2);
        --Exceptions
        cannot_find_label EXCEPTION;
    
    BEGIN
    
        --valor m�ximo das horas
        CASE i_state
            WHEN g_tuberculin_test_state_presc THEN
                BEGIN
                    IF to_number((i_hours + (24 * i_days))) > l_max_test_time
                    THEN
                        l_label := '> ' || to_char(l_max_test_time) || l_label_sep || '00';
                    ELSE
                        l_label := (i_hours + (24 * i_days)) || l_label_sep || i_minutes;
                    END IF;
                END;
            
            WHEN g_tuberculin_test_state_adm THEN
                BEGIN
                    IF to_number((i_hours + (24 * i_days))) > l_max_test_time
                    THEN
                        l_label := '> ' || to_char(l_max_test_time) || l_label_sep || '00';
                    ELSIF to_number((i_hours + (24 * i_days))) < l_adm_ok_test_time
                    THEN
                        -- 48 - n� horas - 1|| 60 - n� minutos
                        --formata as horas
                        l_hours_temp := (l_adm_ok_test_time - (i_hours + (24 * i_days)) - 1);
                        IF length(l_hours_temp) = 1
                        THEN
                            l_hours_temp := '0' || l_hours_temp;
                        END IF;
                    
                        --formata os minutos
                        l_minutes_temp := (l_minutes - i_minutes);
                        IF length(l_minutes_temp) = 1
                        THEN
                            l_minutes_temp := '0' || l_minutes_temp;
                        END IF;
                        --label final
                        l_label := l_hours_temp || l_label_sep || l_minutes_temp;
                    ELSE
                        l_hours_temp := ((i_hours + (24 * i_days)) - l_adm_ok_test_time);
                        IF length(l_hours_temp) = 1
                        THEN
                            l_hours_temp := '0' || l_hours_temp;
                        END IF;
                        l_label := l_hours_temp || l_label_sep || i_minutes;
                    END IF;
                END;
            
            WHEN g_tuberculin_test_state_res THEN
                BEGIN
                    l_label := i_value || ' mm';
                END;
            WHEN g_tuberculin_test_state_canc THEN
                BEGIN
                    IF i_dt_cancel IS NOT NULL
                    THEN
                        l_label := get_month_year_from_timestamp(i_lang, i_dt_cancel);
                    ELSE
                        --isto nunca pode acontecer, mas podem existir dados incorrectos???
                        l_label := 'N.A.';
                    END IF;
                END;
            ELSE
                BEGIN
                    RAISE cannot_find_label;
                END;
        END CASE;
        RETURN l_label;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_value_label;
    --

    /************************************************************************************************************
    * Returns the label that corresponds to the state
    *
    * @param      i_lang        Language ID
    * @param      i_state       tuberculin test's or vaccine state (P - prescription; A - administration; R - results; C - canceled)
    *
    * @return     a label
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_state_label
    (
        i_lang  IN language.id_language%TYPE,
        i_state VARCHAR2
    ) RETURN VARCHAR IS
    
        --label
        l_label VARCHAR2(100) := '';
    
        --Exceptions
        cannot_find_label EXCEPTION;
    
    BEGIN
        CASE i_state
            WHEN g_tuberculin_test_state_presc THEN
                BEGIN
                    l_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T051');
                END;
            WHEN g_tuberculin_test_state_adm THEN
                BEGIN
                    l_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T052');
                END;
            
            WHEN g_tuberculin_test_state_res THEN
                BEGIN
                    l_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T053');
                END;
            WHEN g_tuberculin_test_state_canc THEN
                BEGIN
                    l_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T054');
                END;
            ELSE
                BEGIN
                    RAISE cannot_find_label;
                END;
        END CASE;
        RETURN l_label;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_state_label;
    --

    /************************************************************************************************************
    * Returns the background color to be used in the summary screen
    *
    * @param      i_minutes     minutes after the previous state
    * @param      i_hours       hours after the previous state
    * @param      i_days        days after the previous state
    * @param      i_state       tuberculin test's state (P - prescription; A - administration; R - results)
    *
    * @return     background color
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_value_bg_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR IS
    
        --label
        l_bg_color VARCHAR2(100) := '';
    
        l_green_color CONSTANT VARCHAR2(50) := '0x829664';
        l_red_color   CONSTANT VARCHAR2(50) := '0xC86464';
        --Exceptions
        cannot_find_bg_color EXCEPTION;
    
    BEGIN
    
        CASE i_state
            WHEN g_tuberculin_test_state_presc THEN
                BEGIN
                    l_bg_color := l_red_color;
                END;
            WHEN g_tuberculin_test_state_adm THEN
                BEGIN
                    IF i_days < 2 -- 48 horas
                    THEN
                        l_bg_color := l_green_color;
                    ELSE
                        l_bg_color := l_red_color;
                    END IF;
                END;
            WHEN g_tuberculin_test_state_res THEN
                BEGIN
                    l_bg_color := '';
                END;
            ELSE
                BEGIN
                    RAISE cannot_find_bg_color;
                END;
        END CASE;
        RETURN l_bg_color;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_value_bg_color;
    --

    /************************************************************************************************************
    * Returns the icon's color to be used in the summary screen
    *
    * @param      i_minutes     minutes after the previous state
    * @param      i_hours       hours after the previous state
    * @param      i_days        days after the previous state
    * @param      i_state       tuberculin test's state (P - prescription; A - administration; R - results)
    *
    * @return     icon's color
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/29
    ***********************************************************************************************************/
    FUNCTION get_summary_value_icon_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR IS
    
        --label
        l_bg_color VARCHAR2(100) := '';
    
        l_red_color         CONSTANT VARCHAR2(50) := '0xC86464';
        l_normal_color      CONSTANT VARCHAR2(50) := '0xEBEBC8';
        l_normal_read_color CONSTANT VARCHAR2(50) := '0x787864';
    
        l_max_time_result CONSTANT NUMBER := 48;
        --Exceptions
        cannot_find_bg_color EXCEPTION;
    
    BEGIN
    
        CASE i_state
            WHEN g_tuberculin_test_state_presc THEN
                BEGIN
                    l_bg_color := l_normal_color;
                END;
            WHEN g_tuberculin_test_state_adm THEN
                BEGIN
                    l_bg_color := l_normal_color;
                END;
            WHEN g_tuberculin_test_state_res THEN
                BEGIN
                    IF to_number((i_hours + (24 * i_days))) < l_max_time_result
                    THEN
                        l_bg_color := l_normal_read_color;
                    ELSE
                        l_bg_color := l_red_color;
                    END IF;
                END;
            ELSE
                BEGIN
                    RAISE cannot_find_bg_color;
                END;
        END CASE;
        RETURN l_bg_color;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summary_value_icon_color;
    --

    /************************************************************************************************************
    * This function returns the values for each tuberculin test.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_tuberculin_val     cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_value
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        o_tuberculin_val OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sysdate_timestamp CONSTANT TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
        --get do estado
        -- 1 - prescrito
        -- 2 - administrado
        -- 3 - lido
    
        g_error := 'OPEN CURSOR o_tuberculin_val TO GET VALUES';
        --TODO: complete this function...
        OPEN o_tuberculin_val FOR
            SELECT --pk_date_utils.date_send_tsz(i_lang, dp.dt_drug_prescription, i_prof) time_var,
             pk_date_utils.date_send_tsz(i_lang, dp.dt_drug_prescription_tstz, i_prof) time_var,
             g_tuberculin_test_id par_var, --
             dp.id_drug_prescription id_value, --
             get_summary_value_label(i_lang,
                                     get_summary_time_min(l_sysdate_timestamp,
                                                          get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                        dpp.dt_take_tstz,
                                                                                        dpr.dt_drug_presc_result)),
                                     get_summary_time_hour(l_sysdate_timestamp,
                                                           get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                         dpp.dt_take_tstz,
                                                                                         dpr.dt_drug_presc_result)),
                                     get_summary_time_day(l_sysdate_timestamp,
                                                          get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                        dpp.dt_take_tstz,
                                                                                        dpr.dt_drug_presc_result)),
                                     get_tuberculin_test_state(dp.dt_drug_prescription_tstz,
                                                               dpp.dt_take_tstz,
                                                               dpr.dt_drug_presc_result,
                                                               dp.dt_cancel_tstz),
                                     dp.dt_cancel_tstz,
                                     dpr.value) text_message, --
             get_summary_value_icon(get_summary_time_min(l_sysdate_timestamp,
                                                         get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                       dpp.dt_take_tstz,
                                                                                       dpr.dt_drug_presc_result)),
                                    get_summary_time_hour(l_sysdate_timestamp,
                                                          get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                        dpp.dt_take_tstz,
                                                                                        dpr.dt_drug_presc_result)),
                                    get_summary_time_day(l_sysdate_timestamp,
                                                         get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                       dpp.dt_take_tstz,
                                                                                       dpr.dt_drug_presc_result)),
                                    get_tuberculin_test_state(dp.dt_drug_prescription_tstz,
                                                              dpp.dt_take_tstz,
                                                              dpr.dt_drug_presc_result,
                                                              dp.dt_cancel_tstz),
                                    dpr.id_evaluation) icon_name,
             get_summary_value_bg_color(get_summary_time_min(l_sysdate_timestamp,
                                                             get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                           dpp.dt_take_tstz,
                                                                                           dpr.dt_drug_presc_result)),
                                        get_summary_time_hour(l_sysdate_timestamp,
                                                              get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                            dpp.dt_take_tstz,
                                                                                            dpr.dt_drug_presc_result)),
                                        get_summary_time_day(l_sysdate_timestamp,
                                                             get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                           dpp.dt_take_tstz,
                                                                                           dpr.dt_drug_presc_result)),
                                        get_tuberculin_test_state(dp.dt_drug_prescription_tstz,
                                                                  dpp.dt_take_tstz,
                                                                  dpr.dt_drug_presc_result,
                                                                  dp.dt_cancel_tstz)) bg_color, --
             get_summary_value_icon_color(get_summary_time_min(l_sysdate_timestamp,
                                                               get_tuberculin_test_timestamp(dp.dt_drug_prescription_tstz,
                                                                                             dpp.dt_take_tstz,
                                                                                             dpr.dt_drug_presc_result)),
                                          get_summary_time_hour(dpr.dt_drug_presc_result, dpp.dt_take_tstz),
                                          get_summary_time_day(dpr.dt_drug_presc_result, dpp.dt_take_tstz),
                                          get_tuberculin_test_state(dp.dt_drug_prescription_tstz,
                                                                    dpp.dt_take_tstz,
                                                                    dpr.dt_drug_presc_result,
                                                                    dp.dt_cancel_tstz)) icon_color,
             'TI' display_type,
             get_tuberculin_test_state(dp.id_drug_prescription) val_state,
             'V' type_vacc,
             decode(get_tuberculin_test_state(dp.id_drug_prescription),
                    'A',
                    pk_alert_constant.g_yes,
                    'P',
                    pk_alert_constant.g_yes,
                    pk_alert_constant.g_no) flg_cancel
              FROM drug_prescription dp,
                   drug_presc_det dpd,
                   (SELECT *
                      FROM drug_presc_plan dpp1
                     WHERE dpp1.flg_status IN
                           (g_presc_plan_stat_req, g_presc_plan_stat_pend, pk_alert_constant.g_active)
                       AND dpp1.id_drug_presc_plan IN
                           (SELECT MAX(id_drug_presc_plan)
                              FROM drug_presc_plan dpp2
                             WHERE dpp2.id_drug_presc_det = dpp1.id_drug_presc_det)) dpp,
                   drug_presc_result dpr,
                   mi_med mim
             WHERE dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpp.id_drug_presc_det(+) = dpd.id_drug_presc_det
                  --pode ainda n�o ter sido inserido o resultado
               AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan(+)
               AND dp.id_patient = i_patient
                  --filtro do grupo das vacinas
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id
               AND dpd.id_drug = mim.id_drug;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_TUBERCULIN_TEST_VALUE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_tuberculin_val);
                RETURN FALSE;
            END;
    END get_tuberculin_test_value;
    --

    /************************************************************************************************************
    * Validate the input date and return the respective TIMESTMAP
    *
    * @param      i_dt                date
    * @param      o_sysdate           timestamp
    * @param      o_sysdate_tstz      timestamp tstz
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/28
    ***********************************************************************************************************/
    FUNCTION validate_input_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dt           IN VARCHAR2,
        o_sysdate      OUT TIMESTAMP WITH TIME ZONE,
        o_sysdate_tstz OUT TIMESTAMP WITH TIME ZONE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_dt IS NULL
        THEN
            o_sysdate      := SYSDATE;
            o_sysdate_tstz := current_timestamp;
        ELSE
            o_sysdate      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL);
            o_sysdate_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validate_input_date;
    --

    /************************************************************************************************************
    * Return the TIMESTAMP as a string in the correct format
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_date               TIMESTAMP
    *
    * @return     a string with the date in the the correct format
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2008/01/10
    ***********************************************************************************************************/
    FUNCTION format_tuberculin_test_date
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type_date IN VARCHAR2
    ) RETURN VARCHAR IS
    
        l_str_date VARCHAR2(100);
    BEGIN
    
        IF i_date IS NOT NULL
        THEN
            IF i_flg_type_date IS NULL
            THEN
                l_str_date := pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
            ELSE
            
                SELECT decode(i_flg_type_date,
                              pk_alert_constant.g_yes,
                              get_year_from_timestamp(i_date),
                              g_month,
                              get_month_year_from_timestamp(i_lang, i_date),
                              g_day,
                              pk_date_utils.date_chr_short_read_tsz(i_lang, i_date, i_prof.institution, i_prof.software),
                              pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software))
                  INTO l_str_date
                  FROM dual;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
        RETURN l_str_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_tuberculin_test_date;
    --
    /**######################################################
      End of private functions
    ######################################################**/

    /************************************************************************************************************
    * This function returns all information about tuberculin skin tests for the specified patient.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_group_name         label with the name of the group
    * @param      o_tuberculin_time    cursor with
    * @param      o_tuberculin_par     cursor with
    * @param      o_tuberculin_val     cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        o_group_name      OUT VARCHAR2,
        o_tuberculin_time OUT pk_types.cursor_type,
        o_tuberculin_par  OUT pk_types.cursor_type,
        o_tuberculin_val  OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_vacc_type_group   vacc_type_group.id_vacc_type_group%TYPE;
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        CURSOR c_group_name IS
            SELECT pk_translation.get_translation(i_lang, vtg.code_vacc_type_group)
              FROM vacc_type_group vtg
             WHERE vtg.id_vacc_type_group = l_vacc_type_group
               AND rownum = 1;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_tuberculin,
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_tuberculin_time);
            pk_types.open_my_cursor(o_tuberculin_par);
            pk_types.open_my_cursor(o_tuberculin_val);
            RETURN TRUE;
        END IF;
    
        OPEN c_group_name;
        FETCH c_group_name
            INTO o_group_name;
        g_found := c_group_name%FOUND;
        CLOSE c_group_name;
        IF NOT g_found
        THEN
            o_group_name := '';
        END IF;
    
        --Este cursor calcula o tempos em que houve prescri��es de teste de tuberculina
        --Essas prescri��es foram criadas para o respectivo SYSDATE
        g_error := 'OPEN CURSOR o_tuberculin_time TO GET the times';
        OPEN o_tuberculin_time FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, dp.dt_drug_prescription_tstz, i_prof) time_var,
                   get_year_from_timestamp(dp.dt_drug_prescription_tstz) year_read,
                   get_day_month_from_timestamp(i_lang, dp.dt_drug_prescription_tstz, i_prof) short_dt
              FROM drug_prescription dp, drug_presc_det dpd, mi_med mim
             WHERE dp.id_drug_prescription = dpd.id_drug_prescription
               AND dp.id_patient = i_patient
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id
               AND dpd.id_drug = mim.id_drug
             ORDER BY dp.dt_drug_prescription_tstz ASC;
    
        --apenas existe uma tipo de prova � tuberculina!
        g_error := 'OPEN CURSOR o_tuberculin_par TO GET the parameters';
        OPEN o_tuberculin_par FOR
            SELECT v.id_vacc par_var, --
                   NULL par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det
              FROM vacc_type_group vtg, vacc_group vg, vacc v
             WHERE vtg.flg_presc_type = g_flg_presc_tuberculin
               AND vtg.id_vacc_type_group = vg.id_vacc_type_group
               AND vg.id_vacc = v.id_vacc
               AND EXISTS (SELECT 1
                      FROM vacc_type_group_soft_inst vtgsi
                     WHERE vtgsi.id_vacc_type_group = vtg.id_vacc_type_group
                       AND vtgsi.id_institution IN (i_prof.institution, 0)
                       AND vtgsi.id_software IN (i_prof.software, 0));
    
        --get the values
        g_error := 'CALL FUNCTION GET_TUBERCULIN_TEST_VALUE';
        IF NOT get_tuberculin_test_value(i_lang           => i_lang,
                                         i_patient        => i_patient,
                                         i_prof           => i_prof,
                                         o_tuberculin_val => o_tuberculin_val,
                                         o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_TEST_SUMMARY');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_tuberculin_time);
                pk_types.open_my_cursor(o_tuberculin_par);
                pk_types.open_my_cursor(o_tuberculin_val);
                RETURN FALSE;
            END;
    END get_tuberculin_test_summary;
    --

    /************************************************************************************************************
    * This function returns the details for all tuberculin tests
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_res_title          title for result details
    * @param      o_res_det            cursor with the result details
    * @param      o_adm_title          title for administration details
    * @param      o_admdet             cursor with the administration details
    * @param      o_presc_title        title for prescription details
    * @param      o_presc_det          cursor with the prescription details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_tests_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        -- Adverses React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
        CURSOR c_detail_info IS
            SELECT v.desc_html
              FROM vacc_info v
             WHERE v.id_vacc = g_tuberculin_test_id
               AND v.id_language = i_lang;
    
    BEGIN
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        --main title
        o_main_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T040');
    
        --this take title
        o_this_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T042');
    
        --takes history title
        o_history_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T041');
    
        --detail information
        g_error := 'OPEN C_DETAIL_INFO';
        OPEN c_detail_info;
        FETCH c_detail_info
            INTO o_detail_info;
        g_found := c_detail_info%FOUND;
        CLOSE c_detail_info;
    
        -- if so, an alert message must be shown
        IF NOT g_found
           OR o_detail_info IS NULL
        THEN
            o_detail_info := '--';
        END IF;
    
        --responsible:
        OPEN o_test_info FOR
            SELECT DISTINCT dp.id_drug_prescription id_test,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                            decode(pk_date_utils.get_hour_short(i_lang, i_prof, dp.dt_drug_prescription_tstz),
                                   '00:00',
                                   pk_date_utils.date_chr_short_read(i_lang, dp.dt_drug_prescription_tstz, i_prof),
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               dp.dt_drug_prescription_tstz,
                                                               i_prof.institution,
                                                               i_prof.software)) dt_last,
                            '' desc_other,
                            pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T050') desc_state,
                            get_summary_state_label(i_lang, get_tuberculin_test_state(dp.id_drug_prescription)) state,
                            get_tuberculin_test_state(dp.id_drug_prescription) flg_state
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, professional p
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.dci_id = l_tuberculin_dci_id
                  -- and dpp.flg_status!='C' -- tomas canceladas
               AND p.id_professional = dp.id_professional
             ORDER BY id_test;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_can_det TO GET THE CANCEL DETAILS';
        IF NOT get_tuberculin_test_can_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => NULL,
                                           i_to_add    => FALSE,
                                           o_can_title => o_can_title,
                                           o_can_det   => o_can_det,
                                           o_error     => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_res_det TO GET THE RESULT DETAILS';
        IF NOT get_tuberculin_test_res_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => NULL,
                                           i_to_add    => FALSE,
                                           o_res_title => o_res_title,
                                           o_res_det   => o_res_det,
                                           o_error     => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_tuberculin_test_adm_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => NULL,
                                           i_to_add    => FALSE,
                                           o_adm_title => o_adm_title,
                                           o_adm_det   => o_adm_det,
                                           o_error     => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_tuberculin_test_presc_det(i_lang        => i_lang,
                                             i_patient     => i_patient,
                                             i_prof        => i_prof,
                                             i_test_id     => NULL,
                                             i_to_add      => FALSE,
                                             o_presc_title => o_presc_title,
                                             o_presc_det   => o_presc_det,
                                             o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_tub_advers_react_det(i_lang               => i_lang,
                                        i_patient            => i_patient,
                                        i_prof               => i_prof,
                                        i_test_id            => NULL,
                                        i_to_add             => FALSE,
                                        o_advers_react_title => o_advers_react_title,
                                        o_advers_react_det   => o_advers_react_det,
                                        o_error              => o_error)
        THEN
            pk_utils.undo_changes;
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
                                              'PK_VACC',
                                              'GET_TUBERCULIN_TESTS_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_test_info);
            pk_types.open_my_cursor(o_can_det);
            pk_types.open_my_cursor(o_res_det);
            pk_types.open_my_cursor(o_adm_det);
            pk_types.open_my_cursor(o_presc_det);
            pk_types.open_my_cursor(o_advers_react_det);
            RETURN FALSE;
    END get_tuberculin_tests_detail;
    --
    /************************************************************************************************************
    * Returns the data needed to build the screens that allows the set of either administration or result values
    * for the specified tuberculin test.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_res_title          title for result details
    * @param      o_res_det            cursor with the result details
    * @param      o_adm_title          title for administration details
    * @param      o_admdet             cursor with the administration details
    * @param      o_presc_title        title for prescription details
    * @param      o_presc_det          cursor with the prescription details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_add
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        --OUT
        o_main_title OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --main title
        o_main_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T030');
    
        --responsible:
        OPEN o_test_info FOR
            SELECT dp.id_drug_prescription id_test, 'todo' desc_resp, 'todo' dt_last
              FROM drug_prescription dp
             WHERE dp.id_drug_prescription = i_test_id;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_res_det TO GET THE RESULT DETAILS';
        IF NOT get_tuberculin_test_res_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => i_test_id,
                                           i_to_add    => TRUE,
                                           o_res_title => o_res_title,
                                           o_res_det   => o_res_det,
                                           o_error     => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_tuberculin_test_adm_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => i_test_id,
                                           i_to_add    => TRUE,
                                           o_adm_title => o_adm_title,
                                           o_adm_det   => o_adm_det,
                                           o_error     => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_tuberculin_test_presc_det(i_lang        => i_lang,
                                             i_patient     => i_patient,
                                             i_prof        => i_prof,
                                             i_test_id     => i_test_id,
                                             i_to_add      => TRUE,
                                             o_presc_title => o_presc_title,
                                             o_presc_det   => o_presc_det,
                                             o_error       => o_error)
        THEN
            pk_utils.undo_changes;
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
                                              'PK_VACC',
                                              'GET_TUBERCULIN_TEST_ADD',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_test_info);
            pk_types.open_my_cursor(o_res_det);
            pk_types.open_my_cursor(o_adm_det);
            pk_types.open_my_cursor(o_presc_det);
            RETURN FALSE;
    END get_tuberculin_test_add;

    /************************************************************************************************************
    * This function returns the most frequent drugs used in tuberculin tests. It returns as well the
    * labels to build the screen that presents the most frequent drugs for tuberculin tests.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_med_freq_label     title for the most frequent drugs
    * @param      o_med_sel_label      title for the most frequent drugs selected
    * @param      o_med_freq           cursor with most frequent drugs for tuberculin tests
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_local_med_freq
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_button IN VARCHAR2,
        --OUT
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version           mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_tuberculin_dci_id mi_med.dci_id%TYPE;
    
    BEGIN
        --
        o_med_sel_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T002');
        o_search_label  := pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_T008');
    
        --
        l_tuberculin_dci_id := pk_sysconfig.get_config('TUBERCULIN_DCI_ID', i_prof);
        IF l_tuberculin_dci_id IS NULL
        THEN
            l_tuberculin_dci_id := g_tuberculin_default_dci_id;
        END IF;
    
        --labels para o ecr�:
        IF i_button = pk_alert_constant.g_active -- Todas
        THEN
            o_med_freq_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T028');
        
            -- para j� retorna n�o existe distin��o de query pelo i_button!
            --cursor com as tuberculinas (ainda est�o a ser enviadas todas as tuberculinas!)
            OPEN o_med_freq FOR
                SELECT
                --Estes par�metros s�o necess�rios para passar os dados para o ecr� da prescri��o!
                 mim.id_drug         drug, --
                 mim.dosagem         dosage, --
                 mim.id_unit_measure unit_measure,
                 mim.route_id        admin_via, --
                 mim.flg_justify     flg_justify, --
                 --descritivos
                 mim.med_descr          desc_drug, --
                 mim.short_med_descr    short_desc_drug, --
                 mim.dci_descr          desc_drug_pharm, --
                 mim.form_farm_descr    desc_drug_form, --
                 mim.med_descr_formated short_pharm, --
                 mim.med_descr_formated html --
                  FROM mi_med mim
                 WHERE --mim.chnm_id IS NOT NULL
                 mim.dci_id = l_tuberculin_dci_id
                 AND mim.flg_available = pk_alert_constant.g_yes
                 AND mim.vers = l_version;
        
        ELSE
            -- mais frequentes
            o_med_freq_label := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T001');
            -- para j� retorna n�o existe distin��o de query pelo i_button!
            --cursor com as tuberculinas (ainda est�o a ser enviadas todas as tuberculinas!)
            OPEN o_med_freq FOR
                SELECT
                --Estes par�metros s�o necess�rios para passar os dados para o ecr� da prescri��o!
                 mim.id_drug         drug, --
                 mim.dosagem         dosage, --
                 mim.id_unit_measure unit_measure,
                 mim.route_id        admin_via, --
                 mim.flg_justify     flg_justify, --
                 --descritivos
                 mim.med_descr          desc_drug, --
                 mim.short_med_descr    short_desc_drug, --
                 mim.dci_descr          desc_drug_pharm, --
                 mim.form_farm_descr    desc_drug_form, --
                 mim.med_descr_formated short_pharm, --
                 mim.med_descr_formated html --
                  FROM mi_med mim
                 WHERE --mim.chnm_id IS NOT NULL
                 mim.dci_id = l_tuberculin_dci_id
                 AND mim.flg_available = pk_alert_constant.g_yes
                 AND mim.vers = l_version;
        
            -- pk_types.open_my_cursor(o_med_freq);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_VACC',
                                   'GET_TUBERCULIN_LOCAL_MED_FREQ');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_med_freq);
                RETURN FALSE;
            END;
    END get_tuberculin_local_med_freq;
    --

    /************************************************************************************************************
    * Creates the tuberculin test prescription.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_episode            episode's ID
    * @param      i_patient            patient's identifier
    
    * @param      i_drug               drug unique identifier
    * @param      i_dosage             dosage
    * @param      i_unit_measure       unit measure
    * @param      i_admin_via          administration
    * @param      i_prof_write         professional that creates the prescription
    * @param      i_notes              notes
    
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/05
    ***********************************************************************************************************/
    FUNCTION set_tuberculin_test_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_drug         IN drug_presc_det.id_drug%TYPE, --mi_med.id_drug%TYPE,
        i_dosage       IN drug_presc_det.dosage_description%TYPE,
        i_unit_measure IN drug_presc_det.id_unit_measure%TYPE,
        i_admin_via    IN drug_presc_det.route_id%TYPE,
        --
        i_prof_write          IN professional.id_professional%TYPE,
        i_notes_justif        IN drug_presc_det.notes_justif%TYPE,
        i_notes               IN drug_presc_det.notes%TYPE,
        i_presc_date          IN VARCHAR2,
        i_requested_by        IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --OUT
        o_test_id    OUT drug_prescription.id_drug_prescription%TYPE,
        o_id_admin   OUT drug_presc_plan.id_drug_presc_plan%TYPE,
        o_type_admin OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --drug_prescription pk
        dp_pk drug_prescription.id_drug_prescription%TYPE;
        --drug_presc_det pk
        dpd_pk drug_presc_det.id_drug_presc_det%TYPE;
        --drug_presc_plan pk
        dpp_pk drug_presc_plan.id_drug_presc_plan%TYPE;
    
        --
        l_notes drug_presc_det.notes%TYPE;
        --Exception
        unexpected_error EXCEPTION;
    
        l_rowids_1 table_varchar;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        --valida��o da data de entrada
        g_error := 'VALIDATE INPUT PRESCRIPTION DATE';
        IF NOT validate_input_date(i_lang, i_prof, i_presc_date, g_sysdate, g_sysdate_tstz)
        THEN
            RAISE unexpected_error;
        END IF;
    
        IF i_requested_by IS NOT NULL
        THEN
            l_notes := i_notes || '<br><b>' || pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T005') || '</b> ' ||
                       i_requested_by;
        ELSE
            l_notes := i_notes;
        END IF;
    
        -- *********************************
        -- PT 26/09/2008 2.4.3.d
        g_error := 'INSERT INTO DRUG_PRESCRIPTION';
        ts_drug_prescription.ins(id_drug_prescription_out     => dp_pk,
                                 id_episode_in                => i_episode,
                                 id_professional_in           => i_prof.id,
                                 flg_type_in                  => 'I',
                                 flg_time_in                  => 'E',
                                 flg_status_in                => 'R',
                                 dt_drug_prescription_tstz_in => g_sysdate_tstz,
                                 id_patient_in                => i_patient,
                                 rows_out                     => l_rowids_1);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DRUG_PRESCRIPTION',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
        -- *********************************
    
        pk_alertlog.log_info('INSERT_INTO DRUG_PRESC_DET (1): dp_pk = ' || to_char(dp_pk) || '; i_episode = ' ||
                             to_char(i_episode) || '; o_error.ora_sqlerrm = ' || o_error.ora_sqlerrm);
        pk_alertlog.log_info('INSERT_INTO DRUG_PRESC_DET (2): i_notes_justif = ' || i_notes_justif || '; i_dosage = ' ||
                             i_dosage || '; i_unit_measure = ' || to_char(i_unit_measure));
        pk_alertlog.log_info('INSERT_INTO DRUG_PRESC_DET (3): i_drug = ' || i_drug || '; l_version = ' || l_version ||
                             '; i_admin_via = ' || i_admin_via);
    
        -- 2 - insere registo na tabela drug_presc_det
        g_error := 'INSERT_INTO DRUG_PRESC_DET';
        dpd_pk  := ins_drug_presc_det(i_lang,
                                      i_prof,
                                      dp_pk,
                                      l_notes, --notes_in,
                                      'U', -- unit�rio
                                      NULL,
                                      NULL,
                                      'R',
                                      NULL,
                                      NULL,
                                      i_notes_justif,
                                      NULL,
                                      1, --takes_in,
                                      NULL, --dosage,
                                      NULL,
                                      NULL,
                                      i_dosage, --dosage_description_in
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      i_unit_measure, --id_unit_measure_in,
                                      g_sysdate_tstz,
                                      g_sysdate_tstz,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      pk_alert_constant.g_no,
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
                                      i_drug, --id_drug_in,
                                      l_version,
                                      i_admin_via,
                                      NULL,
                                      pk_alert_constant.g_no,
                                      pk_alert_constant.g_no,
                                      i_vacc_manuf,
                                      code_mvx);
    
        pk_alertlog.log_info('INSERT_INTO DRUG_PRESC_DET (4): dpd_pk = ' || to_char(dpd_pk));
    
        -- 3 - insere registo na tabela drug_presc_plan
        g_error := 'INSERT_INTO DRUG_PRESC_PLAN';
    
        dpp_pk := ins_drug_presc_plan(i_lang,
                                      i_prof,
                                      dpd_pk,
                                      NULL,
                                      NULL,
                                      NULL,
                                      'R', -- Requisitado pk_alert_constant.g_no, --n�o administrado
                                      NULL,
                                      NULL,
                                      NULL,
                                      i_episode,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      g_sysdate_tstz,
                                      NULL,
                                      NULL,
                                      NULL,
                                      i_flg_type_date,
                                      i_dosage_admin,
                                      i_dosage_unit_measure);
    
        o_id_admin   := dpp_pk;
        o_type_admin := g_day;
    
        --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
        --Checklist - 16
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --grava as altera��es
        COMMIT;
        --retorna o id do teste criado
        o_test_id := dp_pk;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_TUBERCULIN_TEST_PRESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_tuberculin_test_presc;
    --

    /************************************************************************************************************
    * Cancel the vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_vacc_presc_id      vaccine prescrition id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION get_cancel_tuberculin_test
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_test_id IN drug_prescription.id_drug_prescription%TYPE,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --main title
        o_main_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T060');
    
        --notes title
        o_notes_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T057');
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_tuberculin_test_adm_det(i_lang      => i_lang,
                                           i_patient   => i_patient,
                                           i_prof      => i_prof,
                                           i_test_id   => i_test_id,
                                           i_to_add    => FALSE,
                                           o_adm_title => o_adm_title,
                                           o_adm_det   => o_adm_det,
                                           o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_tuberculin_test_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_tuberculin_test_presc_det(i_lang        => i_lang,
                                             i_patient     => i_patient,
                                             i_prof        => i_prof,
                                             i_test_id     => i_test_id,
                                             i_to_add      => FALSE,
                                             o_presc_title => o_presc_title,
                                             o_presc_det   => o_presc_det,
                                             o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_CANCEL_TUBERCULIN_TEST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_adm_det);
                pk_types.open_my_cursor(o_presc_det);
                RETURN FALSE;
            END;
    END get_cancel_tuberculin_test;
    --

    /************************************************************************************************************
    * Cancel the vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_vacc_presc_id      vaccine prescrition id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION get_cancel_other_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_vacc_take_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --main title
        o_main_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T059');
    
        --notes title
        o_notes_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T057');
    
        pk_types.open_my_cursor(o_adm_det);
        --apenas para vacinas fora do PNV
        g_error := 'CALL THE FUNCTION get_vaccine_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_vacc_presc_det(i_lang         => i_lang,
                                  i_patient      => i_patient,
                                  i_prof         => i_prof,
                                  i_vacc_id      => NULL,
                                  i_vacc_take_id => i_vacc_take_id,
                                  i_to_add       => FALSE,
                                  o_presc_title  => o_presc_title,
                                  o_presc_det    => o_presc_det,
                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VACC', 'GET_CANCEL_OTHER_VACC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_types.open_my_cursor(o_adm_det);
                pk_types.open_my_cursor(o_presc_det);
                RETURN FALSE;
            END;
    END get_cancel_other_vacc;
    --

    /************************************************************************************************************
    * Cancel the vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_vacc_presc_id      vaccine prescrition id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION get_cancel_info
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_cancel_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op IN VARCHAR,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --verifica qual � o tipo de registo para obter a informa��o!
        IF i_cancel_op = 'T'
        THEN
            g_error := 'CALL GET_CANCEL_TUBERCULIN_TEST FUNCTION';
            IF NOT get_cancel_tuberculin_test(i_lang,
                                              i_patient,
                                              i_prof,
                                              i_cancel_id,
                                              o_main_title,
                                              o_notes_title,
                                              o_adm_title,
                                              o_adm_det,
                                              o_presc_title,
                                              o_presc_det,
                                              o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSE
            g_error := 'CALL GET_CANCEL_OTHER_VACC FUNCTION';
            IF NOT get_cancel_other_vacc(i_lang,
                                         i_patient,
                                         i_prof,
                                         i_cancel_id,
                                         o_main_title,
                                         o_notes_title,
                                         o_adm_title,
                                         o_adm_det,
                                         o_presc_title,
                                         o_presc_det,
                                         o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_CANCEL_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_adm_det);
            pk_types.open_my_cursor(o_presc_det);
            RETURN FALSE;
    END get_cancel_info;
    --

    /************************************************************************************************************
    * Cancel the tuberculin test prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_test_id            tuberculin test id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION set_cancel_tuberculin_test
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_test_id      IN drug_prescription.id_drug_prescription%TYPE,
        i_notes_cancel IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_drug_prescription drug_prescription%ROWTYPE;
        l_drug_prescription_det NUMBER;
    
        --Exception
        unexpected_error EXCEPTION;
    
    BEGIN
    
        --cria��o da prescri��o:
        -- 1 - insere dt_cancel na tabela drug_prescription
        g_error := 'UPDATE DRUG_PRESCRIPTION';
    
        --select do registo actual:
    
        SELECT dpd.id_drug_presc_det
          INTO l_drug_prescription_det
          FROM drug_presc_det dpd
         WHERE dpd.id_drug_prescription = i_test_id;
    
        IF NOT pk_prescription_int.cancel_presc(i_lang, l_drug_prescription_det, i_prof, i_notes_cancel, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --grava as altera��es
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_CANCEL_TUBERCULIN_TEST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_cancel_tuberculin_test;

    /************************************************************************************************************
    * Cancel the vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_vacc_presc_id      vaccine prescrition id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION set_cancel_other_vacc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel     IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --timestamp
        l_sysdate_timestamp CONSTANT TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        l_pat     pat_vacc_adm.id_patient%TYPE;
        l_episode pat_vacc_adm.id_episode%TYPE;
    
    BEGIN
    
        --cria��o da prescri��o:
        -- 1 - insere dt_cancel na tabela drug_prescription
        g_error := 'UPDATE PAT_VACC_ADM';
    
        --Faz o update da data de cancelamento
        --Create a function to do this
        UPDATE pat_vacc_adm pva
           SET pva.flg_status = 'C', pva.dt_cancel = l_sysdate_timestamp, pva.id_prof_cancel = i_prof.id
         WHERE pva.id_pat_vacc_adm = i_vacc_presc_id;
    
        g_error := 'UPDATE PAT_VACC_ADM_DET';
    
        --Faz o update da data de cancelamento
        --Create a function to do this
        UPDATE pat_vacc_adm_det pvad
           SET pvad.flg_status       = 'C',
               pvad.dt_cancel        = l_sysdate_timestamp,
               pvad.id_prof_cancel   = i_prof.id,
               pvad.notes_cancel     = i_notes_cancel,
               pvad.id_cancel_reason = i_id_cancel_reason
         WHERE pvad.id_pat_vacc_adm = i_vacc_presc_id;
    
        --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
        SELECT pva.id_patient, pva.id_episode
          INTO l_pat, l_episode
          FROM pat_vacc_adm pva
         WHERE pva.id_pat_vacc_adm = i_vacc_presc_id;
    
        --Checklist - 16
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => l_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            --o_error := g_error;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --grava as altera��es
        --COMMIT; -- Jos� Brito 12/03/2010 ALERT-26489 Avoid commit when cancelling reported medication.
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_CANCEL_OTHER_VACC',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END set_cancel_other_vacc;
    /************************************************************************************************************
    * Cancel the specified vaccine or tuberculine test. The type of record to cancel is specifief in
    * the 'i_cancel_op' input parameter.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    *
    * @param      i_cancel_id          record's id to cancel
    * @param      i_cancel_op          record's type to cancel (V - vaccines, T - tuberculin tests)
    * @param      i_notes_cancel       cancelation notes
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION set_cancel_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_cancel_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op    IN VARCHAR,
        i_notes_cancel IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --verifica qual � o tipo de regista a cancelar!
        IF i_cancel_op IN ('T', 'V')
        THEN
            g_error := 'CALL SET_CANCEL_TUBERCULIN_TEST FUNCTION';
            IF NOT set_cancel_tuberculin_test(i_lang, i_prof, i_cancel_id, i_notes_cancel, o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL SET_CANCEL_OTHER_VACC FUNCTION';
            IF NOT set_cancel_other_vacc(i_lang, i_prof, i_cancel_id, NULL, i_notes_cancel, o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_CANCEL_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cancel_info;
    --

    /************************************************************************************************************
    * This function sets the tuberculin test's administration.
    *
    * @param      i_lang               language
    * @param      i_patient            patient's identifier
    * @param      i_prof               profisisonal
    * @param      i_episode            episode's ID
    * @param      i_test_id            tuberculin test ID
    * @param      i_dt_adm             administration date
    * @param      i_lote_adm           lot Id
    * @param      i_dt_valid           expiration date
    * @param      i_app_place          application place
    * @param      i_prof_write         profisisonal's ID that makes the registration
    * @param      i_notes              administration notes
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION set_tuberculin_test_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_test_id             IN NUMBER,
        i_dt_adm              IN VARCHAR2,
        i_lote_adm            IN VARCHAR2,
        i_dt_valid            IN VARCHAR2,
        i_app_place           IN VARCHAR2,
        i_prof_write          professional.id_professional%TYPE,
        i_notes               IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --valores actuais das colunas que n�o s�o actualizadas!
        l_id_drug_presc_plan drug_presc_plan.id_drug_presc_plan%TYPE;
        l_id_drug_presc_det  drug_presc_det.id_drug_presc_det%TYPE;
        l_dt_plan_tstz       drug_presc_plan.dt_plan_tstz%TYPE;
        l_dosage             drug_presc_plan.dosage%TYPE;
    
        l_dt_valid             drug_presc_plan.dt_expiration%TYPE;
        l_prof_write           professional.id_professional%TYPE;
        l_dt_prescription_tstz drug_prescription.dt_drug_prescription_tstz%TYPE;
        l_dt_take_tstz         drug_presc_plan.dt_take_tstz%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_dt_adm IS NULL
        THEN
            g_sysdate      := SYSDATE;
            l_dt_take_tstz := current_timestamp;
        ELSE
            g_sysdate      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_adm, NULL);
            l_dt_take_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_adm, NULL);
        END IF;
    
        IF i_dt_valid IS NOT NULL
        THEN
            l_dt_valid := CAST(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_valid, NULL) AS DATE);
        ELSE
            --fica a NULL - n�o foi inserida data de validade
            l_dt_valid := i_dt_valid;
        END IF;
    
        --nesta fun��o vai ser actulizado o registo da tabela drug_presc_plan correspondente
    
        --select do registo actual:
    
        SELECT dpp.id_drug_presc_plan,
               dpd.id_drug_presc_det,
               dpp.dt_plan_tstz,
               dpp.dosage,
               dp.dt_drug_prescription_tstz
          INTO l_id_drug_presc_plan, l_id_drug_presc_det, l_dt_plan_tstz, l_dosage, l_dt_prescription_tstz
          FROM drug_prescription dp,
               drug_presc_det dpd,
               (SELECT *
                  FROM drug_presc_plan dpp1
                 WHERE dpp1.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend, pk_alert_constant.g_active)
                   AND dpp1.id_drug_presc_plan IN
                       (SELECT MAX(id_drug_presc_plan)
                          FROM drug_presc_plan dpp2
                         WHERE dpp2.id_drug_presc_det = dpp1.id_drug_presc_det)) dpp
         WHERE dp.id_drug_prescription = i_test_id
           AND dp.id_drug_prescription = dpd.id_drug_prescription
           AND dpp.id_drug_presc_det(+) = dpd.id_drug_presc_det;
    
        --Actuliza a tabela drug_presc_plan com a administra��o do teste
        --1 - Insere os dados na tabela
    
        upd_drug_presc_det(l_id_drug_presc_det, i_vacc_manuf, code_mvx);
    
        IF i_prof_write = -1
        THEN
            l_prof_write := NULL;
        ELSE
            l_prof_write := i_prof_write;
        END IF;
    
        --[OA] DQ
        --A data da toma nunca pode ser inferior � data da prescri��o j� registada!
        IF l_dt_take_tstz < l_dt_prescription_tstz
        THEN
            l_dt_take_tstz := g_sysdate_tstz;
        END IF;
        --
    
        upd_drug_presc_plan(i_lang,
                            i_prof,
                            l_id_drug_presc_plan,
                            l_id_drug_presc_det,
                            NULL,
                            l_prof_write,
                            l_dosage,
                            pk_alert_constant.g_active,
                            i_notes,
                            NULL,
                            NULL,
                            i_episode,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            i_app_place,
                            i_lote_adm,
                            l_dt_valid, --data de validade
                            NULL,
                            l_dt_plan_tstz,
                            l_dt_take_tstz,
                            NULL,
                            i_flg_type_date,
                            i_dosage_admin,
                            i_dosage_unit_measure);
    
        --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
        --Checklist - 16
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --grava as altera��es
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_TUBERCULIN_TEST_ADM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_tuberculin_test_adm;
    --

    /************************************************************************************************************
    * This function sets the tuberculin test's results.
    *
    * @param      i_lang               language
    * @param      i_patient            patient's identifier
    * @param      i_prof               profisisonal
    * @param      i_test_id            tuberculin test ID
    * @param      i_dt_read            read date
    * @param      i_value              value
    * @param      i_evaluation         evaluation details
    * @param      i_evaluation_id      evaluation's ID
    * @param      i_reactions          adverse reactions
    * @param      i_prof_write         profisisonal's ID that makes the registration
    * @param      i_notes              results notes
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION set_tuberculin_test_res
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_test_id       IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_read       IN VARCHAR2,
        i_value         IN drug_presc_result.value%TYPE,
        i_evaluation    IN drug_presc_result.evaluation%TYPE,
        i_evaluation_id IN drug_presc_result.id_evaluation%TYPE,
        i_reactions     IN drug_presc_result.notes_advers_react%TYPE,
        i_prof_write    IN professional.id_professional%TYPE,
        i_notes         IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Exceptions
        cannot_insert_drug_presc_res EXCEPTION;
    
        --drug_presc_plan id
        l_id_drug_presc_plan drug_presc_plan.id_drug_presc_plan%TYPE;
    
        --drug_presc_result pk
        l_dpr_pk drug_presc_result.id_drug_presc_result%TYPE;
    BEGIN
        IF i_dt_read IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        ELSE
            g_sysdate_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_read, NULL);
        END IF;
    
        --select do registo actual:
        SELECT dpp.id_drug_presc_plan
          INTO l_id_drug_presc_plan
          FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp
         WHERE dp.id_drug_prescription = i_test_id
           AND dp.id_drug_prescription = dpd.id_drug_prescription
           AND dpd.id_drug_presc_det = dpp.id_drug_presc_det;
    
        --nesta fun��o vai ser criado um registo na tabela drug_presc_result
        --1 - Insere os dados na tabela
        l_dpr_pk := ins_drug_presc_result(i_prof,
                                          l_id_drug_presc_plan,
                                          g_sysdate_tstz,
                                          i_value,
                                          i_evaluation,
                                          i_evaluation_id,
                                          i_reactions,
                                          i_prof_write,
                                          i_notes,
                                          SYSDATE);
    
        --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
        --Checklist - 16
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        END IF;
        --grava as altera��es
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_TUBERCULIN_TEST_RES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_tuberculin_test_res;
    --

    /**********************************************************************************************
    * Get tuberculin tests evaluation values
    *
    * @param i_lang                  the id language
    * @param i_prof                  Profissional que requisita
    *
    * @param o_param                 cursor with the evaluation values
    *
    * @param      o_error            error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2008/01/10
    **********************************************************************************************/
    FUNCTION get_evaluation_values
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EVALUATION_VALUES';
        OPEN o_param FOR
            SELECT s.val data, s.desc_val label, s.rank rank
              FROM sys_domain s
             WHERE s.code_domain = 'POSITIVE_NEGATIVE'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_EVALUATION_VALUES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_evaluation_values;

    /*
     * =================================
     * -- End of Tuberculin developement
     * =================================
    */

    /************************************************************************************************************
    * Esta fun��o retorna o resumo das Vacinas fora do PNV (Plano Nacional de Vacina��o)
    *
    * @param      i_lang               language
    * @param      i_prof               profissional
    * @param      i_patient            patient's identifier
    *
    * @param      o_group_name         label with the name of the group
    * @param      o_vacc_time          cursor
    * @param      o_vacc_time          cursor
    * @param      o_vacc_val           cursor
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    FUNCTION get_other_vacc_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_group_name OUT VARCHAR2,
        o_vacc_time  OUT pk_types.cursor_type,
        o_vacc_par   OUT pk_types.cursor_type,
        o_vacc_val   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --Dose max - 1 por default
        l_max_dose NUMBER := 1;
        l_times    table_info := table_info();
        l_version  mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
    BEGIN
        -- Outras vacinas (label)
        o_group_name := pk_message.get_message(i_lang, 'VACC_T059');
    
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_other_vacc, -- outras vacinas
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_vacc_time);
            pk_types.open_my_cursor(o_vacc_par);
            pk_types.open_my_cursor(o_vacc_val);
            RETURN TRUE;
        END IF;
    
        g_error := 'GET_MAX_DOSE';
        SELECT nvl(MAX(count_vacc_take(i_lang,
                                       i_patient,
                                       decode(pva.id_vacc, -1, pva.id_vacc, v.id_vacc),
                                       pvad.dt_reg,
                                       i_prof)),
                   1) time_var
          INTO l_max_dose
          FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, vacc v, vacc_group vg
         WHERE pva.id_patient = i_patient
           AND (pva.id_vacc = v.id_vacc OR pva.id_vacc = -1)
           AND vg.id_vacc = v.id_vacc
           AND vg.id_vacc_type_group = l_vacc_type_group
           AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
           AND pva.id_episode_destination IS NULL;
    
        --preenche o array dos tempos
        g_error := 'SET_TIME_ARRAY ';
        FOR i IN 1 .. l_max_dose
        LOOP
            l_times.extend;
            l_times(i) := info(i, pk_message.get_message(i_lang, 'VACC_T017'), NULL);
        END LOOP;
    
        -- Datas das prescri��es
        g_error := 'OPEN CURSOR O_VACC_TIME';
        OPEN o_vacc_time FOR
            SELECT times.id time_var, times.desc_info dt_desc
              FROM TABLE(l_times) times;
    
        -- vacinas
        g_error := 'OPEN CURSOR O_VACC_PAR';
        OPEN o_vacc_par FOR
            SELECT DISTINCT decode(pva.id_vacc, -1, pva.id_pat_vacc_adm, pva.id_vacc) par_var,
                            decode(mem.dci_descr,
                                   NULL,
                                   decode(v.desc_vacc_ext, NULL, pvad.desc_vaccine, v.desc_vacc_ext),
                                   mem.dci_descr) par_desc, -- decode(mem.med_descr, NULL, desc_vaccine, mem.med_descr) par_desc,
                            NULL par_desc_det,
                            decode(pva.id_vacc, -1, pk_alert_constant.g_yes, pk_alert_constant.g_no) par_free_text
              FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad, vacc v, vacc_group vg
             WHERE pva.id_patient = i_patient
               AND pvad.emb_id = mem.emb_id(+)
               AND pva.id_vacc = v.id_vacc(+)
               AND vg.id_vacc = v.id_vacc
               AND vg.id_vacc_type_group = l_vacc_type_group
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.id_episode_destination IS NULL
               AND mem.vers(+) = l_version
            UNION
            SELECT DISTINCT decode(pva.id_vacc, -1, pva.id_pat_vacc_adm, pva.id_vacc) par_var,
                            decode(mem.dci_descr,
                                   NULL,
                                   decode(v.desc_vacc_ext, NULL, pvad.desc_vaccine, v.desc_vacc_ext),
                                   mem.dci_descr) par_desc, -- decode(mem.med_descr, NULL, desc_vaccine, mem.med_descr) par_desc,
                            NULL par_desc_det,
                            decode(pva.id_vacc, -1, pk_alert_constant.g_yes, pk_alert_constant.g_no) par_free_text
              FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad, vacc v
             WHERE pva.id_patient = i_patient
               AND pvad.emb_id = mem.emb_id(+)
               AND pva.id_vacc = v.id_vacc(+)
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.id_episode_destination IS NULL
               AND mem.vers(+) = l_version
               AND NOT EXISTS (SELECT vg.id_vacc
                      FROM vacc_group vg
                     WHERE --vg.id_vacc_type_group = 15 and 
                     vg.id_vacc = pva.id_vacc)
               AND pva.id_vacc = -1;
    
        -- valores
        g_error := 'OPEN CURSOR O_VACC_VAL';
        OPEN o_vacc_val FOR
            SELECT decode(pva.flg_orig, 'R', 'R', g_day) flg_orig,
                   decode(pva.id_vacc, -1, 1, row_number() over(PARTITION BY pva.id_vacc ORDER BY pvad.dt_reg)) time_var,
                   decode(pva.id_vacc, -1, pva.id_pat_vacc_adm, pva.id_vacc) par_var,
                   pva.id_pat_vacc_adm id_value, --identifica o registo desta vacina
                   NULL par_value,
                   pvad.emb_id emb_id,
                   decode(pva.flg_status,
                          'C',
                          g_cancel_icon,
                          decode(pva.flg_orig,
                                 'R',
                                 g_vacc_icon_report_take,
                                 decode(pva.flg_reported,
                                        pk_alert_constant.g_yes,
                                        g_vacc_icon_report_take,
                                        decode(pva.flg_status, g_day, g_presc_prescribed_icon, g_vacc_icon_check_take)))) icon_name, /*-- -> nome do �cone*/
                   decode(pva.flg_status,
                          pk_alert_constant.g_active,
                          decode(pva.flg_orig,
                                 'R',
                                 decode(pvad.dt_take,
                                        NULL,
                                        get_month_year_from_timestamp(i_lang, pvad.dt_reg),
                                        get_month_year_from_timestamp(i_lang, pvad.dt_take)),
                                 'V',
                                 get_month_year_from_timestamp(i_lang, pvad.dt_take),
                                 get_month_year_from_timestamp(i_lang, pvad.dt_take)),
                          'R', -- requisitado
                          decode(flg_time,
                                 'E',
                                 pk_date_utils.date_char_hour_tsz(i_lang,
                                                                  pvad.dt_reg,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                 pk_message.get_message(i_lang, 'VACC_T072')),
                          g_day, -- pendente
                          decode(flg_time, 'E', pk_message.get_message(i_lang, 'VACC_T072'), NULL),
                          'C', -- cancelado
                          get_month_year_from_timestamp(i_lang, pva.dt_cancel)) text_message, /*-- -> texto a apresentar na c�lula*/
                   decode(pva.flg_status,
                          pk_alert_constant.g_active,
                          'TI',
                          'R',
                          'T',
                          pk_alert_constant.g_no,
                          'T',
                          'C',
                          'TI',
                          g_day,
                          decode(flg_time, 'E', 'T', 'I')) display_type, /*-- -> pode ter seguintes valores:TI � Com texto e �cone I � apenas com �cone  T � apenas com texto*/
                   NULL icon_color, /*-- -> apenas necess�rio quando � uma cor diferente da normal*/
                   decode(pva.flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          pk_alert_constant.g_no,
                          l_green_color,
                          g_day,
                          NULL,
                          'R',
                          decode(flg_time, 'E', l_red_color, l_green_color)) bg_color,
                   decode(pva.flg_status, g_day, decode(flg_time, 'E', 'R', g_day), pva.flg_status) val_state,
                   nvl(pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software),
                       pk_date_utils.date_char_tsz(i_lang, pvad.dt_reg, i_prof.institution, i_prof.software)) dt,
                   'O' type_vacc
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, vacc v, vacc_group vg
             WHERE pva.id_patient = i_patient
               AND pva.id_vacc = v.id_vacc(+)
               AND vg.id_vacc = v.id_vacc
               AND vg.id_vacc_type_group = l_vacc_type_group
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.id_episode_destination IS NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_OTHER_VACC_SUMMARY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            pk_types.open_my_cursor(o_vacc_time);
            pk_types.open_my_cursor(o_vacc_par);
            pk_types.open_my_cursor(o_vacc_val);
            RETURN FALSE;
        
    END get_other_vacc_summary;

    /************************************************************************************************************
    * Esta fun��o retorna os conteudos para os mais frequentes e para a lupa + das Vacinas fora do PNV (Plano Nacional de Vacina��o)
    e para as provas � tuberculina
    *
    * @param      i_lang               language
    * @param      i_prof               profissional
    * @param      i_type               tipo : T - Tuberculina, V - Vacinas
    * @param      i_button             tipo : A - Todos, S - Mais frequentes
    *
    * @param      o_med_freq_label     label (mais frequentes/todos)
    * @param      o_med_sel_label      label  (registos selecionados)
    * @param      o_search_label       label  (pesquisa)
    * @param      o_med_freq           cursor
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/05
    ***********************************************************************************************************/

    FUNCTION get_most_freq_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_type           IN VARCHAR2,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_type = 'T'
        THEN
            -- Tuberculinas
            g_error := 'CALL FUNCTION GET_TUBERCULIN_LOCAL_MED_FREQ';
            IF NOT get_tuberculin_local_med_freq(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_button         => i_button,
                                                 o_med_freq_label => o_med_freq_label,
                                                 o_med_sel_label  => o_med_sel_label,
                                                 o_search_label   => o_search_label,
                                                 o_med_freq       => o_med_freq,
                                                 o_error          => o_error)
            
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
        ELSE
            -- vacinas fora do PNV
            g_error := 'CALL FUNCTION GET_VACC_OUT_ME_FREQ';
            IF NOT get_vacc_out_me_freq(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_button         => i_button,
                                        o_med_freq_label => o_med_freq_label,
                                        o_med_sel_label  => o_med_sel_label,
                                        o_search_label   => o_search_label,
                                        o_med_freq       => o_med_freq,
                                        o_error          => o_error)
            
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_MOST_FREQ_ALL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_med_freq);
            RETURN FALSE;
    END;

    /*
     * =================================
     * -- Vaccines developement
     * =================================
    */

    /************************************************************************************************************
    * Returns all information about PNV vaccines for the specified patient.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_group             label with the name of the group
    * @param      o_vaccine_time      cursor with
    * @param      o_vaccine_par       cursor with
    * @param      o_vaccine_val       cursor with
    * @param      o_error              error message
    *
    * @return     "True" if success and "False" otherwise
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    FUNCTION get_vacc_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_group_name   OUT VARCHAR2,
        o_vaccine_time OUT pk_types.cursor_type,
        o_vaccine_par  OUT pk_types.cursor_type,
        o_vaccine_val  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --id do grupo das tuberculinas
        l_type_group_vaccines CONSTANT NUMBER := 2;
    
        --Ids dos tempos
        l_times table_info := table_info();
    
        --Dose max - 1 por default
        l_max_dose NUMBER := 1;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
        --configuracao - Aparecer a cor das vacinas em falta
        l_pnv_color_display sys_config.value%TYPE;
    
    BEGIN
        --validate input data
        validate_input_parameters(i_lang, i_prof, i_patient);
    
        --nome do grupo das vacinas
        SELECT pk_translation.get_translation(i_lang, vtg.code_vacc_type_group)
          INTO o_group_name
          FROM vacc_type_group vtg
         WHERE vtg.id_vacc_type_group = l_type_group_vaccines;
    
        --configuracao - Aparecer a cor das vacinas em falta
        l_pnv_color_display := pk_sysconfig.get_config('PNV_COLOR_DISPLAY', i_prof);
    
        --
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_vaccine_time);
            pk_types.open_my_cursor(o_vaccine_par);
            pk_types.open_my_cursor(o_vaccine_val);
            RETURN TRUE;
        END IF;
    
        --
        o_group_name := o_group_name || ' ' || pk_message.get_message(i_lang, 'VACC_T080');
        --lista de episodios
    
        g_error := 'GET_MAX_DOSE';
        SELECT nvl(max_value, 1) + 1 time_var
          INTO l_max_dose
          FROM (SELECT MAX(take) max_value
                  FROM (SELECT count_vacc_take(i_lang, i_patient, vme.id_vacc, dpp.dt_take_tstz, i_prof) take
                          FROM drug_prescription dp, drug_presc_det dpt, drug_presc_plan dpp, vacc_med_ext vme
                         WHERE dp.id_patient = i_patient
                           AND dp.id_drug_prescription = dpt.id_drug_prescription
                           AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                           AND dpt.id_drug_presc_det = dpp.id_drug_presc_det
                        UNION
                        --Novos registos que n�o usam a vacc_med_ext
                        SELECT count_vacc_take(i_lang, i_patient, vd.id_vacc, dpp.dt_take_tstz, i_prof) take
                          FROM drug_prescription dp
                          JOIN drug_presc_det dpd
                            ON dp.id_drug_prescription = dpd.id_drug_prescription
                          JOIN drug_presc_plan dpp
                            ON dpd.id_drug_presc_det = dpp.id_drug_presc_det
                          JOIN mi_med mim
                            ON dpd.id_drug = mim.id_drug
                           AND mim.flg_type = g_month
                          JOIN vacc_dci vd
                            ON mim.dci_id = vd.id_dci
                          LEFT JOIN pat_vacc pv
                            ON pv.id_vacc = vd.id_vacc
                         WHERE dp.id_patient = i_patient
                           AND get_has_adm_canceled(nvl(dp.id_parent, dp.id_drug_prescription)) = pk_alert_constant.g_no
                           AND dp.flg_status = g_presc_fin
                        --Altera��o End [OA]
                        UNION
                        --relatos
                        SELECT count_vacc_take(i_lang, i_patient, pva.id_vacc, nvl(pvad.dt_take, pvad.dt_reg), i_prof) take
                          FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad, pat_vacc pv
                         WHERE pva.id_patient = i_patient
                           AND pvad.emb_id = mem.emb_id(+)
                           AND pva.flg_orig IN ('R', 'I') -- relatos e importadas do SINUS
                           AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                           AND pva.id_vacc = pv.id_vacc
                           AND pva.flg_status NOT IN (g_status_s, g_status_r)
                           AND pva.id_episode_destination IS NULL
                           AND get_has_rep_canceled(nvl(pva.id_parent, pva.id_pat_vacc_adm)) = pk_alert_constant.g_no
                        UNION
                        --discontinue
                        SELECT get_vacc_ndose(i_lang, pv.id_vacc) take
                          FROM vacc v
                          JOIN pat_vacc pv
                            ON v.id_vacc = pv.id_vacc
                           AND pv.id_patient = i_patient
                           AND pv.flg_status = g_status_s
                          JOIN vacc_group vg
                            ON vg.id_vacc = v.id_vacc
                          JOIN vacc_dose vd
                            ON vd.id_vacc = v.id_vacc
                          JOIN TIME t
                            ON vd.id_time = t.id_time));
    
        g_error := 'SET_TIME_ARRAY ';
        --preenche o array dos tempos
    
        FOR i IN 1 .. l_max_dose
        LOOP
            l_times.extend;
            l_times(i) := info(i, pk_message.get_message(i_lang, 'VACC_T017'), NULL);
        END LOOP;
    
        --Cursor com os tempos:
        --No caso das vacinas o cursor dos tempos vai ter as doses em que cada vacina � administrada.
        --Para preencher este cursor � calculado o n� da dose m�xima de todas as vacinas e s�o retornados
        --os valores at� essa dose como os ids dos tempos.
        --S�o usados aqui tempos, apesar de estarmos a falar de doses, para manter a generalidade com outros pedidos semelhantes
        g_error := 'OPEN o_vaccine_time';
        OPEN o_vaccine_time FOR
            SELECT times.id time_var, times.desc_info dt_desc
              FROM TABLE(l_times) times;
    
        g_error := 'OPEN o_vaccine_par';
        --cursor com os parametros
        OPEN o_vaccine_par FOR
            SELECT par_var, par_desc, par_desc_det, ndoses, available
              FROM (SELECT v.id_vacc par_var,
                           pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                           pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                           get_vacc_ndose(i_lang, v.id_vacc) ndoses,
                           pk_alert_constant.g_yes available,
                           nvl(decode(pv.flg_status, g_status_s, 1, 0), 0) order_by
                      FROM vacc_group vg
                      JOIN vacc_group_soft_inst vgsi
                        ON vgsi.id_vacc_group = vg.id_vacc_group
                       AND vgsi.id_institution = i_prof.institution
                       AND vgsi.id_software = i_prof.software
                      JOIN vacc v
                        ON vg.id_vacc = v.id_vacc
                      LEFT JOIN pat_vacc pv
                        ON pv.id_vacc = v.id_vacc
                       AND pv.id_patient = i_patient
                     WHERE vg.id_vacc_type_group = l_vacc_type_group
                     ORDER BY order_by ASC, v.rank DESC, par_desc ASC);
    
        g_error := 'OPEN o_vaccine_val';
        --cursor com os valores
        OPEN o_vaccine_val FOR
            SELECT count_vacc_take(i_lang, i_patient, vme.id_vacc, dpp.dt_take_tstz, i_prof) time_var,
                   vme.id_vacc par_var,
                   dp.id_drug_prescription id_value,
                   dpp.dt_take_tstz dt_take,
                   g_vacc_icon_check_take icon_name,
                   get_dose_age(i_lang, i_prof, i_patient, dpp.dt_take_tstz) text_message,
                   'TI' display_type,
                   NULL icon_color,
                   NULL bg_color,
                   pk_alert_constant.g_active val_state,
                   g_vacc_dose_adm type_vacc,
                   g_vacc_dose_adm flg_orig,
                   decode(i_prof.id, dpp.id_prof_writes, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel
              FROM drug_prescription dp
              JOIN drug_presc_det dpt
                ON dp.id_drug_prescription = dpt.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpt.id_drug_presc_det
              JOIN vacc_med_ext vme
                ON dpp.id_vacc_med_ext = vme.id_vacc_med_ext
             WHERE dp.id_patient = i_patient
               AND dp.id_parent IS NULL
               AND dp.flg_status <> pk_alert_constant.g_cancelled
            -- AND DP.flg_status = g_presc_fin
            UNION
            -- relatos
            SELECT count_vacc_take(i_lang, i_patient, pva.id_vacc, nvl(pvad.dt_take, pvad.dt_reg), i_prof) time_var,
                   pva.id_vacc par_var,
                   pva.id_pat_vacc_adm id_value,
                   pvad.dt_take dt_take,
                   --g_vacc_icon_report_take icon_name,
                   decode(pva.flg_orig, g_vacc_dose_report, g_vacc_icon_report_take, g_vacc_icon_check_take) icon_name,
                   decode(pvad.dt_take,
                          NULL,
                          decode(pvad.flg_type_date,
                                 pk_alert_constant.g_yes,
                                 get_year_from_timestamp(pvad.dt_reg),
                                 get_month_year_from_timestamp(i_lang, pvad.dt_reg)),
                          decode(pvad.flg_type_date,
                                 pk_alert_constant.g_yes,
                                 get_year_from_timestamp(pvad.dt_take),
                                 get_month_year_from_timestamp(i_lang, pvad.dt_take))) text_message,
                   'TI' display_type,
                   NULL icon_color,
                   NULL bg_color,
                   pk_alert_constant.g_active val_state,
                   'O' type_vacc,
                   pva.flg_orig flg_orig,
                   decode(i_prof.id, pvad.id_prof_writes, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_patient = i_patient
               AND pva.flg_orig IN (g_vacc_dose_report, 'I') -- relatos e importadas do SINUS
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.flg_status NOT IN (g_status_s, g_status_r)
               AND pva.id_episode_destination IS NULL
               AND pva.flg_status = pk_alert_constant.g_active
               AND get_has_rep_canceled(nvl(pva.id_parent, pva.id_pat_vacc_adm)) = pk_alert_constant.g_no
            UNION
            --Novos registos que n�o usam a vacc_med_ext
            SELECT count_vacc_take(i_lang, i_patient, vd.id_vacc, dpp.dt_take_tstz, i_prof) time_var,
                   vd.id_vacc par_var,
                   dp.id_drug_prescription id_value,
                   dpp.dt_take_tstz dt_take,
                   g_vacc_icon_check_take icon_name,
                   decode(abs(CAST(dpp.dt_take_tstz AS DATE) -
                              (SELECT p.dt_birth
                                 FROM patient p
                                WHERE p.id_patient = i_patient)),
                          NULL,
                          pk_message.get_message(i_lang, 'COMMON_M036'),
                          get_dose_age(i_lang, i_prof, i_patient, dpp.dt_take_tstz)) text_message,
                   'TI' display_type,
                   NULL icon_color,
                   NULL bg_color,
                   pk_alert_constant.g_active val_state,
                   g_vacc_dose_adm type_vacc,
                   g_vacc_dose_adm flg_orig,
                   decode(i_prof.id, dpp.id_prof_writes, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel
              FROM drug_prescription dp
              JOIN drug_presc_det dpt
                ON dp.id_drug_prescription = dpt.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpt.id_drug_presc_det
              JOIN mi_med mim
                ON dpt.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND mim.flg_type = g_month
              JOIN vacc_dci vd
                ON mim.dci_id = vd.id_dci
             WHERE dp.id_patient = i_patient
               AND dpt.id_drug_presc_det = dpp.id_drug_presc_det
               AND dp.flg_status = g_presc_fin
               AND get_has_adm_canceled(nvl(dp.id_parent, dp.id_drug_prescription)) = pk_alert_constant.g_no
            UNION
            --next takes
            SELECT count_vacc_take(i_lang, i_patient, v.id_vacc, NULL, i_prof) time_var,
                   v.id_vacc par_var,
                   --para o flash ter uma refer�ncia para a c�lula correspondente
                   -1 id_value,
                   get_last_date(i_lang, i_prof, i_patient, v.id_vacc) dt_take,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, g_waitingicon, NULL) icon_name,
                   decode(l_pnv_color_display,
                          pk_alert_constant.g_no,
                          '',
                          decode(abs((get_last_date(i_lang, i_prof, i_patient, v.id_vacc) + t.val_min) - SYSDATE),
                                 NULL,
                                 pk_message.get_message(i_lang, 'COMMON_M036'),
                                 get_age_recommend(i_lang,
                                                   abs((get_last_date(i_lang, i_prof, i_patient, v.id_vacc) + t.val_min) -
                                                       SYSDATE)))) text_message,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, 'I', 'T') display_type,
                   NULL icon_color,
                   decode(l_pnv_color_display,
                          pk_alert_constant.g_no,
                          '',
                          get_vacc_last_take_icon(get_last_date(i_lang, i_prof, i_patient, v.id_vacc) + t.val_min)) bg_color,
                   NULL val_state,
                   '' type_vacc,
                   NULL flg_orig,
                   pk_alert_constant.g_no flg_cancel
              FROM vacc_dose vd
              JOIN TIME t
                ON vd.id_time = t.id_time
              JOIN vacc v
                ON v.id_vacc = vd.id_vacc
              JOIN vacc_group vg
                ON vg.id_vacc = v.id_vacc
             WHERE vd.n_dose = count_vacc_take(i_lang, i_patient, v.id_vacc, NULL, i_prof)
               AND has_discontinue_vacc(i_patient, v.id_vacc) = pk_alert_constant.g_no --((pv.id_patient = i_patient AND pv.flg_status <> g_status_s) OR pv.flg_status IS NULL)
               AND vg.id_vacc_type_group = l_vacc_type_group
            UNION
            -- discontinue dose
            SELECT count_vacc_take(i_lang, i_patient, pva.id_vacc, nvl(pvad.dt_take, pvad.dt_reg), i_prof) time_var,
                   pva.id_vacc par_var,
                   pva.id_pat_vacc_adm id_value,
                   pvad.dt_suspended dt_take,
                   g_not_icon icon_name,
                   '' text_message,
                   'I' display_type,
                   NULL icon_color,
                   NULL bg_color,
                   g_status_s val_state,
                   '' type_vacc,
                   g_status_s flg_orig,
                   pk_alert_constant.g_no flg_cancel
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_patient = i_patient
               AND pva.flg_orig IN (g_vacc_dose_report, 'I') -- relatos e importadas do SINUS
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.flg_status IN (g_status_s)
               AND pva.id_episode_destination IS NULL
               AND has_discontinue_dose(pva.id_patient, pva.id_vacc) = pk_alert_constant.g_yes
               AND get_has_rep_canceled(nvl(pva.id_parent, pva.id_pat_vacc_adm)) = pk_alert_constant.g_no
            UNION ALL
            SELECT vd.n_dose time_var,
                   v.id_vacc par_var,
                   --para o flash ter uma refer�ncia para a c�lula correspondente
                   -1 id_value,
                   get_last_date(i_lang, i_prof, i_patient, v.id_vacc) dt_take,
                   g_not_icon icon_name,
                   '' text_message,
                   'I' display_type,
                   NULL icon_color,
                   '' bg_color,
                   -----
                   'I' val_state, --state of discontinue vaccine  
                   '' type_vacc,
                   g_status_s flg_orig,
                   pk_alert_constant.g_no flg_cancel
              FROM vacc_dose vd
              JOIN TIME t
                ON vd.id_time = t.id_time
              JOIN vacc v
                ON v.id_vacc = vd.id_vacc
              JOIN vacc_group vg
                ON vg.id_vacc = v.id_vacc
              JOIN pat_vacc pv
                ON pv.id_vacc = v.id_vacc
               AND pv.id_patient = i_patient
               AND pv.flg_status = g_status_s
             WHERE vd.n_dose >= count_vacc_take(i_lang, i_patient, v.id_vacc, NULL, i_prof)
            UNION
            -- tomas da vacina do T�tano, � especifico porque tem num. de tomas ilimitado
            SELECT count_vacc_take(i_lang, i_patient, v.id_vacc, NULL, i_prof) time_var,
                   v.id_vacc par_var,
                   -1 id_value,
                   get_last_date(i_lang, i_prof, i_patient, v.id_vacc) dt_take,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, g_waitingicon, NULL) icon_name,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, '', pk_message.get_message(i_lang, 'VACC_T083')) text_message,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, 'I', 'T') display_type,
                   NULL icon_color,
                   decode(l_pnv_color_display, pk_alert_constant.g_no, '', l_green_color) bg_color,
                   pk_alert_constant.g_no val_state,
                   '' type_vacc,
                   NULL flg_orig,
                   pk_alert_constant.g_no flg_cancel
              FROM vacc_dose vd, TIME t, vacc v, vacc_group vg
             WHERE vd.id_vacc = 15 -- 15 : vacina do t�tano
               AND vd.id_time = t.id_time
               AND v.id_vacc = vd.id_vacc
                  --AND vg.id_vacc_group = 2
               AND vg.id_vacc_type_group = l_vacc_type_group
               AND vg.id_vacc = v.id_vacc
               AND vd.id_time = t.id_time
             ORDER BY dt_take;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_SUMMARY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            pk_types.open_my_cursor(o_vaccine_time);
            pk_types.open_my_cursor(o_vaccine_par);
            pk_types.open_my_cursor(o_vaccine_val);
            RETURN FALSE;
        
    END get_vacc_summary;
    --

    /************************************************************************************************************
    * Returns the number of the dose taken at a specified date, for the specified vaccine. If the
    * date is null, then the function returns the number for the next dose.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            vaccine's ID
    * @param      i_lasttake           dose's administration date
    *
    * @return
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    FUNCTION count_vacc_take
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_lasttake IN drug_presc_plan.dt_take_tstz%TYPE,
        i_prof     IN profissional
    ) RETURN NUMBER IS
    
        l_episode_list table_number := table_number();
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_count_take IS
        --Doses j� administradas
            SELECT COUNT(COUNT)
              FROM (SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           vacc_med_ext      vme,
                           drug_presc_plan   dpp,
                           vacc              v,
                           visit             vi,
                           episode           e
                     WHERE dpd.id_drug = mm.id_drug
                       AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                       AND vme.id_vacc = v.id_vacc
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                       AND dpp.dt_take_tstz < i_lasttake
                    UNION ALL
                    --Novas vacinas que n�o usam a vacc_med_ext
                    SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           --vacc_med_ext      vme,
                           drug_presc_plan dpp,
                           vacc            v,
                           visit           vi,
                           episode         e,
                           vacc_dci        vd
                     WHERE dpd.id_drug = mm.id_drug
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          --AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                          --AND vme.id_vacc = v.id_vacc
                          --Novas vacinas
                       AND dpd.id_drug = mm.id_drug
                       AND mm.dci_id = vd.id_dci
                       AND vd.id_vacc = v.id_vacc
                       AND mm.vers = l_version
                       AND mm.flg_type = g_month
                          --
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                       AND dpp.dt_take_tstz < i_lasttake
                    UNION ALL
                    -- relatos e vacinas fora do PNV
                    SELECT 1 COUNT
                      FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad
                     WHERE pva.id_patient = i_id_pat
                       AND pvad.emb_id = mem.emb_id(+)
                       AND pva.id_vacc = i_vacc
                       AND pva.flg_status NOT IN
                           (g_status_s, g_status_r, pk_alert_constant.g_cancelled, g_vacc_status_edit)
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND ((pva.flg_orig IN ('R', 'I') AND nvl(pvad.dt_take, pvad.dt_reg) < i_lasttake) OR
                           (pva.flg_orig = 'V' AND pvad.dt_reg < i_lasttake))
                       AND pva.id_episode_destination IS NULL
                       AND mem.vers(+) = l_version);
    
        CURSOR c_count_take_2 IS
        --Doses j� administradas
            SELECT COUNT(COUNT)
              FROM (SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           vacc_med_ext      vme,
                           drug_presc_plan   dpp,
                           vacc              v,
                           visit             vi,
                           episode           e
                     WHERE dpd.id_drug = mm.id_drug
                       AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                       AND vme.id_vacc = v.id_vacc
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND dp.id_patient = i_id_pat
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    --Novas vacinas que n�o usam a vacc_med_ext
                    SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           --vacc_med_ext      vme,
                           drug_presc_plan dpp,
                           vacc            v,
                           visit           vi,
                           episode         e,
                           vacc_dci        vd
                     WHERE dpd.id_drug = mm.id_drug
                          --AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          --AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                          --AND vme.id_vacc = v.id_vacc
                          --Novas vacinas
                       AND dpd.id_drug = mm.id_drug
                       AND mm.dci_id = vd.id_dci
                       AND vd.id_vacc = v.id_vacc
                       AND mm.vers = l_version
                       AND mm.flg_type = g_month
                          --
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND dp.id_patient = i_id_pat
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    -- relatos
                    SELECT 1 COUNT
                      FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad
                     WHERE pva.id_patient = i_id_pat
                       AND pvad.emb_id = mem.emb_id(+)
                       AND pva.id_vacc = i_vacc
                       AND pva.flg_orig IN (g_orig_r, g_orig_i)
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL
                       AND pva.flg_status NOT IN
                           (g_status_s, g_status_r, pk_alert_constant.g_cancelled, g_vacc_status_edit)
                       AND mem.vers(+) = l_version);
    
        l_count_take NUMBER;
    
    BEGIN
    
        IF i_vacc = -1
        THEN
            RETURN 1;
        END IF;
    
        IF i_lasttake IS NOT NULL
        THEN
            --n� da dose administrada na data
            g_error := 'OPEN C_COUNT_TAKE';
            OPEN c_count_take;
            FETCH c_count_take
                INTO l_count_take;
        
            CLOSE c_count_take;
        ELSE
            --n� da pr�xima dose
            g_error := 'OPEN C_COUNT_TAKE';
            OPEN c_count_take_2;
            FETCH c_count_take_2
                INTO l_count_take;
        
            CLOSE c_count_take_2;
        
        END IF;
        l_count_take := l_count_take + 1;
        RETURN l_count_take;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END count_vacc_take;
    --

    /************************************************************************************************************
    * Returns the date of the last administration for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient's ID
    * @param      i_vacc               vaccine's ID
    *
    * @return     date for the last vaccine administration
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    FUNCTION get_last_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_date_1 IS
            SELECT pat1.dt_birth
              FROM patient pat1
             WHERE pat1.id_patient = i_id_pat
               AND pat1.flg_status != pk_alert_constant.g_inactive;
    
        --Este cursor retorna a data mais recente de uma administra��o de vacinas ou relatos
        CURSOR c_date_2 IS
            SELECT CAST(MAX(dt_adm) AS DATE)
              FROM (
                    --registo de vacinas antigas
                    SELECT dpp.dt_take_tstz dt_adm
                      FROM drug_prescription dp,
                            drug_presc_det    dpd,
                            mi_med            mm,
                            vacc_med_ext      vme,
                            drug_presc_plan   dpp,
                            vacc              v,
                            visit             vi,
                            episode           e
                     WHERE dpd.id_drug = mm.id_drug
                       AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                       AND vme.id_vacc = v.id_vacc
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    --Novas vacinas que n�o usam a vacc_med_ext
                    SELECT dpp.dt_take_tstz dt_adm
                      FROM drug_prescription dp,
                            drug_presc_det    dpd,
                            mi_med            mm,
                            drug_presc_plan   dpp,
                            vacc              v,
                            visit             vi,
                            episode           e,
                            vacc_dci          vd
                     WHERE dpd.id_drug = mm.id_drug
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          --Novas vacinas
                       AND dpd.id_drug = mm.id_drug
                       AND mm.dci_id = vd.id_dci
                       AND vd.id_vacc = v.id_vacc
                       AND mm.vers = l_version
                       AND mm.flg_type = g_month
                          --
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    -- relatos e vacinas fora do PNV
                    SELECT nvl(pvad.dt_take, pvad.dt_reg) dt_adm
                      FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad
                     WHERE pva.id_patient = i_id_pat
                       AND pvad.emb_id = mem.emb_id(+)
                       AND pva.id_vacc = i_vacc
                       AND pva.flg_orig IN ('R', 'I') -- relatos e importadas do SINUS
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL);
    
        l_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_2 TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        OPEN c_date_1;
        FETCH c_date_1
            INTO l_date;
    
        CLOSE c_date_1;
    
        OPEN c_date_2;
        FETCH c_date_2
            INTO l_date_2;
    
        CLOSE c_date_2;
    
        IF l_date_2 IS NULL
        THEN
            RETURN l_date;
        ELSE
            RETURN l_date_2;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_date;

    /************************************************************************************************************
    * Returns all information needed to build the Vaccines summary screen page, including vaccines outside the PNV,
    * vaccines inside PNV and tuberculin tests.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * --Other Vaccines (outside PNV)
    * @param      o_oth_vaccine_group_name label with the name of the group
    * @param      o_oth_vaccine_time      cursor with
    * @param      o_oth_vaccine_par       cursor with
    * @param      o_oth_vaccine_val       cursor with
    *
    * --PNV Vaccines
    * @param      o_vaccine_group_name label with the name of the group
    * @param      o_vaccine_time      cursor with
    * @param      o_vaccine_par       cursor with
    * @param      o_vaccine_val       cursor with
    *
    * -- Tuberculin tests
    * @param      o_tuberculin_group_name   label with the name of the group
    * @param      o_tuberculin_time    cursor with
    * @param      o_tuberculin_par     cursor with
    * @param      o_tuberculin_val     cursor with
    *
    * @param      o_error              error message
    *
    * @return     "True" if success and "False" otherwise
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    FUNCTION get_vacc_summary_all
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        --OUT
        o_vacc_header_title    OUT VARCHAR2,
        o_vacc_header_subtitle OUT VARCHAR2,
        --Other Vaccines (outside PNV)
        o_oth_vaccine_group_name OUT VARCHAR2,
        o_oth_vaccine_time       OUT pk_types.cursor_type,
        o_oth_vaccine_par        OUT pk_types.cursor_type,
        o_oth_vaccine_val        OUT pk_types.cursor_type,
        --PNV Vaccines
        o_vaccine_group_name OUT VARCHAR2,
        o_vaccine_time       OUT pk_types.cursor_type,
        o_vaccine_par        OUT pk_types.cursor_type,
        o_vaccine_val        OUT pk_types.cursor_type,
        --Tuberculin tests
        o_tuberculin_group_name OUT VARCHAR2,
        o_tuberculin_time       OUT pk_types.cursor_type,
        o_tuberculin_par        OUT pk_types.cursor_type,
        o_tuberculin_val        OUT pk_types.cursor_type,
        o_create                OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Exceptions
        local_error EXCEPTION;
    
        l_val      pk_types.cursor_type;
        l_dummy_1  table_varchar;
        l_dummy_2  table_varchar;
        l_dummy_3  table_varchar2;
        l_dummy_4  table_varchar2;
        l_dummy_5  table_varchar2;
        l_dummy_6  table_varchar2;
        l_dummy_7  table_varchar2;
        l_dummy_8  table_varchar2;
        l_dummy_9  table_varchar2;
        l_dummy_10 table_varchar2;
    
    BEGIN
        --validate input data
        validate_input_parameters(i_lang, i_prof, i_patient);
    
        --t�tulo gen�rico da grelha e Cabe�alho das Vacinas
        o_vacc_header_title    := pk_message.get_message(i_lang, 'VACC_T060');
        o_vacc_header_subtitle := initcap(pk_message.get_message(i_lang, 'VACC_T018'));
    
        --Other Vaccines (outside PNV)
        IF NOT get_other_vacc_summary(i_lang       => i_lang,
                                      i_patient    => i_patient,
                                      i_prof       => i_prof,
                                      o_group_name => o_oth_vaccine_group_name,
                                      o_vacc_time  => o_oth_vaccine_time,
                                      o_vacc_par   => o_oth_vaccine_par,
                                      o_vacc_val   => o_oth_vaccine_val,
                                      o_error      => o_error)
        
        THEN
            pk_alert_exceptions.reset_error_state;
            RAISE local_error;
        END IF;
    
        --PNV Vaccines
        IF NOT get_vacc_summary(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_patient      => i_patient,
                                o_group_name   => o_vaccine_group_name,
                                o_vaccine_time => o_vaccine_time,
                                o_vaccine_par  => o_vaccine_par,
                                o_vaccine_val  => o_vaccine_val,
                                o_error        => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RAISE local_error;
        END IF;
    
        --Tuberculin tests
        IF NOT get_tuberculin_test_summary(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_patient         => i_patient,
                                           o_group_name      => o_tuberculin_group_name,
                                           o_tuberculin_time => o_tuberculin_time,
                                           o_tuberculin_par  => o_tuberculin_par,
                                           o_tuberculin_val  => o_tuberculin_val,
                                           o_error           => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RAISE local_error;
        END IF;
    
        --Determines if (+) button should be active or not
        o_create := pk_alert_constant.g_no;
        IF NOT get_vacc_add(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_type       => 'ADD',
                            i_orig       => NULL,
                            i_patient    => i_patient,
                            i_episode    => NULL,
                            i_vacc       => NULL,
                            i_type_vacc  => NULL,
                            i_id_reg     => NULL,
                            i_flg_status => NULL,
                            o_val        => l_val,
                            o_error      => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RAISE local_error;
        ELSE
            FETCH l_val BULK COLLECT
                INTO l_dummy_1,
                     l_dummy_2,
                     l_dummy_3,
                     l_dummy_4,
                     l_dummy_5,
                     l_dummy_6,
                     l_dummy_7,
                     l_dummy_8,
                     l_dummy_9,
                     l_dummy_10;
        
            IF l_dummy_1.count > 0
            THEN
                o_create := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_SUMMARY_ALL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --Other Vaccines (outside PNV)
            pk_types.open_my_cursor(o_oth_vaccine_time);
            pk_types.open_my_cursor(o_oth_vaccine_par);
            pk_types.open_my_cursor(o_oth_vaccine_val);
            --PNV Vaccines
            pk_types.open_my_cursor(o_vaccine_time);
            pk_types.open_my_cursor(o_vaccine_par);
            pk_types.open_my_cursor(o_vaccine_val);
            --Tuberculin tests
            pk_types.open_my_cursor(o_tuberculin_time);
            pk_types.open_my_cursor(o_tuberculin_par);
            pk_types.open_my_cursor(o_tuberculin_val);
            RETURN FALSE;
    END get_vacc_summary_all;
    --

    /************************************************************************************************************
    * Verifies if all input parameters are valid. If not raise an Exception.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's ID
    *
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/04
    ***********************************************************************************************************/
    PROCEDURE validate_input_parameters
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) IS
        --Exceptions
        invalid_input_parameters EXCEPTION;
    BEGIN
    
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_patient IS NULL
        THEN
            --this expection will be propageted to the caller functions.
            raise_application_error(-20001, g_error_message_20001);
        END IF;
    END validate_input_parameters;
    --

    /*
     * =================================
     * -- End of Vaccines developement
     * =================================
    */

    /*
     * =================================
     * -- DML procedures
     * =================================
    */

    FUNCTION ins_drug_presc_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_drug_prescription_in  IN drug_presc_det.id_drug_prescription%TYPE,
        notes_in                 IN drug_presc_det.notes%TYPE,
        flg_take_type_in         IN drug_presc_det.flg_take_type%TYPE,
        qty_in                   IN drug_presc_det.qty%TYPE,
        rate_in                  IN drug_presc_det.rate%TYPE,
        flg_status_in            IN drug_presc_det.flg_status%TYPE,
        id_prof_cancel_in        IN drug_presc_det.id_prof_cancel%TYPE,
        notes_cancel_in          IN drug_presc_det.notes_cancel%TYPE,
        notes_justif_in          IN drug_presc_det.notes_justif%TYPE,
        interval_in              IN drug_presc_det.interval%TYPE,
        takes_in                 IN drug_presc_det.takes%TYPE,
        dosage_in                IN drug_presc_det.dosage%TYPE,
        value_bolus_in           IN drug_presc_det.value_bolus%TYPE,
        value_drip_in            IN drug_presc_det.value_drip%TYPE,
        dosage_description_in    IN drug_presc_det.dosage_description%TYPE,
        flg_ci_in                IN drug_presc_det.flg_ci%TYPE,
        flg_cheaper_in           IN drug_presc_det.flg_cheaper%TYPE,
        flg_justif_in            IN drug_presc_det.flg_justif%TYPE,
        flg_attention_in         IN drug_presc_det.flg_attention%TYPE,
        flg_attention_print_in   IN drug_presc_det.flg_attention_print%TYPE,
        id_drug_despachos_in     IN drug_presc_det.id_drug_despachos%TYPE,
        id_unit_measure_bolus_in IN drug_presc_det.id_unit_measure_bolus%TYPE,
        id_unit_measure_drip_in  IN drug_presc_det.id_unit_measure_drip%TYPE,
        id_unit_measure_in       IN drug_presc_det.id_unit_measure%TYPE,
        dt_begin_tstz_in         IN drug_presc_det.dt_begin_tstz%TYPE,
        dt_end_tstz_in           IN drug_presc_det.dt_end_tstz%TYPE,
        dt_cancel_tstz_in        IN drug_presc_det.dt_cancel_tstz%TYPE,
        dt_end_presc_tstz_in     IN drug_presc_det.dt_end_presc_tstz%TYPE,
        dt_end_bottle_tstz_in    IN drug_presc_det.dt_end_bottle_tstz%TYPE,
        dt_order_in              IN drug_presc_det.dt_order%TYPE,
        id_prof_order_in         IN drug_presc_det.id_prof_order%TYPE,
        id_order_type_in         IN drug_presc_det.id_order_type%TYPE,
        flg_co_sign_in           IN drug_presc_det.flg_co_sign%TYPE,
        dt_co_sign_in            IN drug_presc_det.dt_co_sign%TYPE,
        notes_co_sign_in         IN drug_presc_det.notes_co_sign%TYPE,
        id_prof_co_sign_in       IN drug_presc_det.id_prof_co_sign%TYPE,
        frequency_in             IN drug_presc_det.frequency%TYPE,
        id_unit_measure_freq_in  IN drug_presc_det.id_unit_measure_freq%TYPE,
        duration_in              IN drug_presc_det.duration%TYPE,
        id_unit_measure_dur_in   IN drug_presc_det.id_unit_measure_dur%TYPE,
        dt_start_presc_tstz_in   IN drug_presc_det.dt_start_presc_tstz%TYPE,
        refill_in                IN drug_presc_det.refill%TYPE,
        qty_inst_in              IN drug_presc_det.qty_inst%TYPE,
        unit_measure_inst_in     IN drug_presc_det.unit_measure_inst%TYPE,
        id_drug_in               IN drug_presc_det.id_drug%TYPE,
        vers_in                  IN drug_presc_det.vers%TYPE,
        route_id_in              IN drug_presc_det.route_id%TYPE,
        id_justification_in      IN drug_presc_det.id_justification%TYPE,
        flg_interac_med_in       IN drug_presc_det.flg_interac_med%TYPE,
        flg_interac_allergy_in   IN drug_presc_det.flg_interac_allergy%TYPE,
        i_vacc_manuf             IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx                 IN vacc_manufacturer.code_mvx%TYPE
    ) RETURN PLS_INTEGER IS
        l_pky PLS_INTEGER;
    
        l_rowids table_varchar;
    
        o_error t_error_out;
    BEGIN
        ts_drug_presc_det.ins(id_drug_presc_det_out    => l_pky,
                              id_drug_prescription_in  => id_drug_prescription_in,
                              notes_in                 => notes_in,
                              flg_take_type_in         => flg_take_type_in,
                              qty_in                   => qty_in,
                              rate_in                  => rate_in,
                              flg_status_in            => flg_status_in,
                              id_prof_cancel_in        => id_prof_cancel_in,
                              notes_cancel_in          => notes_cancel_in,
                              notes_justif_in          => notes_justif_in,
                              interval_in              => interval_in,
                              takes_in                 => takes_in,
                              dosage_in                => dosage_in,
                              value_bolus_in           => value_bolus_in,
                              value_drip_in            => value_drip_in,
                              dosage_description_in    => dosage_description_in,
                              flg_ci_in                => flg_ci_in,
                              flg_cheaper_in           => flg_cheaper_in,
                              flg_justif_in            => flg_justif_in,
                              flg_attention_in         => flg_attention_in,
                              flg_attention_print_in   => flg_attention_print_in,
                              id_drug_despachos_in     => id_drug_despachos_in,
                              id_unit_measure_bolus_in => id_unit_measure_bolus_in,
                              id_unit_measure_drip_in  => id_unit_measure_drip_in,
                              id_unit_measure_in       => id_unit_measure_in,
                              dt_begin_tstz_in         => dt_begin_tstz_in,
                              dt_end_tstz_in           => dt_end_tstz_in,
                              dt_cancel_tstz_in        => dt_cancel_tstz_in,
                              dt_end_presc_tstz_in     => dt_end_presc_tstz_in,
                              dt_end_bottle_tstz_in    => dt_end_bottle_tstz_in,
                              dt_order_in              => dt_order_in,
                              id_prof_order_in         => id_prof_order_in,
                              id_order_type_in         => id_order_type_in,
                              flg_co_sign_in           => flg_co_sign_in,
                              dt_co_sign_in            => dt_co_sign_in,
                              notes_co_sign_in         => notes_co_sign_in,
                              id_prof_co_sign_in       => id_prof_co_sign_in,
                              frequency_in             => frequency_in,
                              id_unit_measure_freq_in  => id_unit_measure_freq_in,
                              duration_in              => duration_in,
                              id_unit_measure_dur_in   => id_unit_measure_dur_in,
                              dt_start_presc_tstz_in   => dt_start_presc_tstz_in,
                              refill_in                => refill_in,
                              qty_inst_in              => qty_inst_in,
                              unit_measure_inst_in     => unit_measure_inst_in,
                              id_drug_in               => id_drug_in,
                              vers_in                  => vers_in,
                              route_id_in              => route_id_in,
                              id_justification_in      => id_justification_in,
                              flg_interac_med_in       => flg_interac_med_in,
                              flg_interac_allergy_in   => flg_interac_allergy_in,
                              id_vacc_manufacturer_in  => i_vacc_manuf,
                              code_mvx_in              => code_mvx,
                              rows_out                 => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DRUG_PRESC_DET',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        RETURN l_pky;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'INS_DRUG_PRESC_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END ins_drug_presc_det;

    FUNCTION ins_drug_presc_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_drug_presc_det_in     IN drug_presc_plan.id_drug_presc_det%TYPE,
        id_drug_take_time_in     IN drug_presc_plan.id_drug_take_time%TYPE,
        id_prof_writes_in        IN drug_presc_plan.id_prof_writes%TYPE,
        dosage_in                IN drug_presc_plan.dosage%TYPE,
        flg_status_in            IN drug_presc_plan.flg_status%TYPE,
        notes_in                 IN drug_presc_plan.notes%TYPE,
        id_prof_cancel_in        IN drug_presc_plan.id_prof_cancel%TYPE,
        notes_cancel_in          IN drug_presc_plan.notes_cancel%TYPE,
        id_episode_in            IN drug_presc_plan.id_episode%TYPE,
        rate_in                  IN drug_presc_plan.rate%TYPE,
        dosage_exec_in           IN drug_presc_plan.dosage_exec%TYPE,
        flg_advers_react_in      IN drug_presc_plan.flg_advers_react%TYPE,
        notes_advers_react_in    IN drug_presc_plan.notes_advers_react%TYPE,
        application_spot_in      IN drug_presc_plan.application_spot%TYPE,
        lot_number_in            IN drug_presc_plan.lot_number%TYPE,
        dt_expiration_in         IN drug_presc_plan.dt_expiration%TYPE,
        id_vacc_med_ext_in       IN drug_presc_plan.id_vacc_med_ext%TYPE,
        dt_plan_tstz_in          IN drug_presc_plan.dt_plan_tstz%TYPE,
        dt_take_tstz_in          IN drug_presc_plan.dt_take_tstz%TYPE,
        dt_cancel_tstz_in        IN drug_presc_plan.dt_cancel_tstz%TYPE,
        dt_next_take_in          IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_type_date_in         IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin_in        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure_in IN drug_presc_plan.dosage_unit_measure%TYPE,
        i_vacc_funding_cat_in    IN drug_presc_plan.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source_in IN drug_presc_plan.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc_in IN drug_presc_plan.funding_source_desc%TYPE DEFAULT NULL,
        i_vacc_doc_vis_in        IN drug_presc_plan.id_vacc_doc_vis%TYPE DEFAULT NULL,
        i_vacc_doc_vis_str       IN drug_presc_plan.doc_vis_desc%TYPE DEFAULT '',
        i_vacc_origin_in         IN drug_presc_plan.id_vacc_origin%TYPE DEFAULT NULL,
        i_origin_desc_in         IN drug_presc_plan.origin_desc%TYPE DEFAULT '',
        i_ordered_desc_in        IN drug_presc_plan.ordered_desc%TYPE DEFAULT '',
        i_administred_desc_in    IN drug_presc_plan.administred_desc%TYPE DEFAULT '',
        i_vacc_route_in          IN drug_presc_plan.vacc_route_data%TYPE DEFAULT '',
        i_ordered_in             IN drug_presc_plan.id_ordered%TYPE DEFAULT NULL,
        i_administred_in         IN drug_presc_plan.id_administred%TYPE DEFAULT NULL,
        dt_doc_delivery_in       IN drug_presc_plan.dt_doc_delivery_tstz%TYPE DEFAULT NULL,
        i_vacc_adv_reaction_in   IN drug_presc_plan.id_vacc_adv_reaction%TYPE DEFAULT NULL,
        i_application_spot_in    IN drug_presc_plan.application_spot_code%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER IS
        l_pky  PLS_INTEGER := ts_drug_presc_plan.next_key;
        l_rows table_varchar;
    
        o_error t_error_out;
    
    BEGIN
    
        /* <DENORM F�bio> */
        ts_drug_presc_plan.ins(id_drug_presc_plan_in     => l_pky,
                               id_drug_presc_det_in      => id_drug_presc_det_in,
                               id_drug_take_time_in      => id_drug_take_time_in,
                               id_prof_writes_in         => id_prof_writes_in,
                               dosage_in                 => i_dosage_admin_in,
                               flg_status_in             => flg_status_in,
                               notes_in                  => notes_in,
                               id_prof_cancel_in         => id_prof_cancel_in,
                               notes_cancel_in           => notes_cancel_in,
                               id_episode_in             => id_episode_in,
                               rate_in                   => rate_in,
                               dosage_exec_in            => dosage_exec_in,
                               flg_advers_react_in       => flg_advers_react_in,
                               notes_advers_react_in     => notes_advers_react_in,
                               application_spot_in       => application_spot_in,
                               application_spot_code_in  => i_application_spot_in,
                               lot_number_in             => lot_number_in,
                               dt_expiration_in          => dt_expiration_in,
                               id_vacc_med_ext_in        => id_vacc_med_ext_in,
                               dt_plan_tstz_in           => dt_plan_tstz_in,
                               dt_take_tstz_in           => dt_take_tstz_in,
                               dt_cancel_tstz_in         => dt_cancel_tstz_in,
                               dt_next_take_in           => dt_next_take_in,
                               flg_type_date_in          => flg_type_date_in,
                               dosage_unit_measure_in    => i_dosage_unit_measure_in,
                               id_vacc_funding_cat_in    => i_vacc_funding_cat_in,
                               id_vacc_funding_source_in => i_vacc_funding_source_in,
                               funding_source_desc_in    => i_funding_source_desc_in,
                               id_vacc_doc_vis_in        => i_vacc_doc_vis_in,
                               id_vacc_origin_in         => i_vacc_origin_in,
                               origin_desc_in            => i_origin_desc_in,
                               ordered_desc_in           => i_ordered_desc_in,
                               administred_desc_in       => i_administred_desc_in,
                               vacc_route_data_in        => i_vacc_route_in,
                               id_ordered_in             => i_ordered_in,
                               id_administred_in         => i_administred_in,
                               id_vacc_adv_reaction_in   => i_vacc_adv_reaction_in,
                               dt_doc_delivery_tstz_in   => dt_doc_delivery_in,
                               doc_vis_desc_in           => i_vacc_doc_vis_str,
                               rows_out                  => l_rows);
    
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'DRUG_PRESC_PLAN', l_rows, o_error);
    
        RETURN l_pky;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'INS_DRUG_PRESC_PLAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END ins_drug_presc_plan;

    FUNCTION ins_drug_presc_result
    (
        i_prof                  IN profissional,
        id_drug_presc_plan_in   IN drug_presc_result.id_drug_presc_plan%TYPE,
        dt_drug_presc_result_in IN drug_presc_result.dt_drug_presc_result%TYPE,
        value_in                IN drug_presc_result.value%TYPE,
        evaluation_in           IN drug_presc_result.evaluation%TYPE,
        evaluation_id_in        IN drug_presc_result.id_evaluation%TYPE,
        notes_advers_react_in   IN drug_presc_result.notes_advers_react%TYPE,
        id_prof_resp_in         IN drug_presc_result.id_prof_resp%TYPE,
        notes_in                IN drug_presc_result.notes%TYPE,
        adw_last_update_in      IN drug_presc_result.adw_last_update%TYPE
    ) RETURN PLS_INTEGER IS
        l_pky PLS_INTEGER;
    
        FUNCTION next_key RETURN PLS_INTEGER IS
            retval PLS_INTEGER;
        BEGIN
            SELECT seq_drug_presc_result.nextval
              INTO retval
              FROM dual;
        
            RETURN retval;
        END next_key;
    BEGIN
        l_pky := next_key;
    
        INSERT INTO drug_presc_result
            (id_drug_presc_result,
             id_drug_presc_plan,
             dt_drug_presc_result,
             VALUE,
             evaluation,
             id_evaluation,
             notes_advers_react,
             id_prof_resp,
             notes,
             adw_last_update,
             id_prof_resp_adm)
        VALUES
            (l_pky,
             id_drug_presc_plan_in,
             dt_drug_presc_result_in,
             value_in,
             evaluation_in,
             evaluation_id_in,
             notes_advers_react_in,
             id_prof_resp_in,
             notes_in,
             adw_last_update_in,
             i_prof.id);
    
        RETURN l_pky;
    EXCEPTION
        WHEN OTHERS THEN
            --this expection will be propageted to the caller functions.
            raise_application_error(-20002, g_error_message_20002 || '/' || SQLERRM);
    END ins_drug_presc_result;
    --

    PROCEDURE upd_drug_presc_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_drug_presc_plan_in IN drug_presc_plan.id_drug_presc_plan%TYPE,
        id_drug_presc_det_in  IN drug_presc_plan.id_drug_presc_det%TYPE,
        id_drug_take_time_in  IN drug_presc_plan.id_drug_take_time%TYPE,
        id_prof_writes_in     IN drug_presc_plan.id_prof_writes%TYPE,
        dosage_in             IN drug_presc_plan.dosage%TYPE,
        flg_status_in         IN drug_presc_plan.flg_status%TYPE,
        notes_in              IN drug_presc_plan.notes%TYPE,
        id_prof_cancel_in     IN drug_presc_plan.id_prof_cancel%TYPE,
        notes_cancel_in       IN drug_presc_plan.notes_cancel%TYPE,
        id_episode_in         IN drug_presc_plan.id_episode%TYPE,
        rate_in               IN drug_presc_plan.rate%TYPE,
        dosage_exec_in        IN drug_presc_plan.dosage_exec%TYPE,
        flg_advers_react_in   IN drug_presc_plan.flg_advers_react%TYPE,
        notes_advers_react_in IN drug_presc_plan.notes_advers_react%TYPE,
        application_spot_in   IN drug_presc_plan.application_spot%TYPE,
        lot_number_in         IN drug_presc_plan.lot_number%TYPE,
        dt_expiration_in      IN drug_presc_plan.dt_expiration%TYPE,
        id_vacc_med_ext_in    IN drug_presc_plan.id_vacc_med_ext%TYPE,
        dt_plan_tstz_in       IN drug_presc_plan.dt_plan_tstz%TYPE,
        dt_take_tstz_in       IN drug_presc_plan.dt_take_tstz%TYPE,
        dt_cancel_tstz_in     IN drug_presc_plan.dt_cancel_tstz%TYPE,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE
    ) IS
        l_rows table_varchar;
    
        o_error t_error_out;
    BEGIN
        /* <DENORM F�bio> */
        ts_drug_presc_plan.upd(id_drug_presc_plan_in   => id_drug_presc_plan_in,
                               id_drug_presc_det_in    => id_drug_presc_det_in,
                               id_drug_take_time_in    => id_drug_take_time_in,
                               id_prof_writes_in       => id_prof_writes_in,
                               dosage_in               => i_dosage_admin,
                               flg_status_in           => flg_status_in,
                               notes_in                => notes_in,
                               id_prof_cancel_in       => id_prof_cancel_in,
                               notes_cancel_in         => notes_cancel_in,
                               id_episode_in           => id_episode_in,
                               rate_in                 => rate_in,
                               dosage_exec_in          => dosage_exec_in,
                               flg_advers_react_in     => flg_advers_react_in,
                               notes_advers_react_in   => notes_advers_react_in,
                               application_spot_in     => application_spot_in,
                               lot_number_in           => lot_number_in,
                               dt_expiration_in        => dt_expiration_in,
                               id_vacc_med_ext_in      => id_vacc_med_ext_in,
                               dt_plan_tstz_in         => dt_plan_tstz_in,
                               dt_take_tstz_in         => dt_take_tstz_in,
                               dt_cancel_tstz_in       => dt_cancel_tstz_in,
                               id_prof_adm_in          => i_prof.id,
                               id_drug_presc_det_nin   => FALSE,
                               id_drug_take_time_nin   => FALSE,
                               id_prof_writes_nin      => FALSE,
                               dosage_nin              => FALSE,
                               flg_status_nin          => FALSE,
                               notes_nin               => FALSE,
                               id_prof_cancel_nin      => FALSE,
                               notes_cancel_nin        => FALSE,
                               id_episode_nin          => FALSE,
                               rate_nin                => FALSE,
                               dosage_exec_nin         => FALSE,
                               flg_advers_react_nin    => FALSE,
                               notes_advers_react_nin  => FALSE,
                               application_spot_nin    => FALSE,
                               lot_number_nin          => FALSE,
                               dt_expiration_nin       => FALSE,
                               id_vacc_med_ext_nin     => FALSE,
                               dt_plan_tstz_nin        => FALSE,
                               dt_take_tstz_nin        => FALSE,
                               dt_cancel_tstz_nin      => FALSE,
                               id_prof_adm_nin         => FALSE,
                               flg_type_date_in        => i_flg_type_date,
                               dosage_unit_measure_nin => FALSE,
                               dosage_unit_measure_in  => i_dosage_unit_measure,
                               rows_out                => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'DRUG_PRESC_PLAN', l_rows, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'UPD_DRUG_PRESC_PLAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END upd_drug_presc_plan;
    --
    --

    /*
     * =================================
     * -- End of DML procedures
     * =================================
    */

    FUNCTION get_vacc_dose_info_detail_new
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_emb      IN me_med.emb_id%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_info_age OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retorna informa��o sobre a vacina
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                       I_EPISODE - ID do epis�dio
                       I_VACC- ID da vacina
                       I_PAT - ID do paciente
                  Saida: O_INFO - retorna se a vacina � do PNV e as contra-indica��es.
                         O_INFO_AGE - retorna as idades minimas para as doses e os intervalos
                         O_ERROR - erro
        
          CRIA��O: Teresa Coutinho
          ALTERA��O :Teresa Coutinho
          NOTAS:
        *********************************************************************************/
    
        l_flg_vacc_show_age sys_config.value%TYPE := pk_sysconfig.get_config('FLG_VACC_SHOW_AGE', i_prof);
    
    BEGIN
    
        g_error := 'OPEN O_INFO'; -- retorna se a vacina � do PNV e as contra-indica��es.
        IF i_vacc IS NOT NULL
        THEN
            OPEN o_info FOR
                SELECT '<b>' || pk_message.get_message(i_lang, 'VACC_T010') || '</b>' || ' ' ||
                       pk_sysdomain.get_domain('VACC_TYPE_GROUP.FLG_PNV', flg_pnv, i_lang) || --
                       '<br>' || --
                       '<b>' || pk_message.get_message(i_lang, 'VACC_T013') || '</b>' || ' ' || vi.advers_react_descr text
                  FROM vacc v, vacc_group vg, vacc_info vi, vacc_type_group vtg
                 WHERE v.id_vacc = vg.id_vacc
                   AND vg.id_vacc_type_group = vtg.id_vacc_type_group
                   AND vi.id_language(+) = i_lang
                   AND v.id_vacc = i_vacc
                   AND v.id_vacc = vi.id_vacc(+);
        
            IF l_flg_vacc_show_age = pk_alert_constant.g_no
            THEN
                pk_types.open_my_cursor(o_info_age);
            ELSE
                g_error := 'OPEN O_INFO_AGE'; -- retorna as idades minimas para as doses e os intervalos
                IF i_vacc = 15 -- vacina do T�tano (15) precisa de tratamento especifico por ter numero ilimitado de tomas
                THEN
                    OPEN o_info_age FOR
                        SELECT label_dose || gap_between_dose text
                          FROM (SELECT '<b>' || pk_message.get_message(i_lang, 'VACC_T015') || ' ' ||
                                       pk_message.get_message(i_lang, 'VACC_T018') || ': ' || '</b>' label_dose,
                                       get_age_recommend(i_lang, get_gap_between_doses(i_lang, n_dose, 15)) gap_between_dose,
                                       n_dose
                                  FROM vacc_dose vd, TIME t
                                 WHERE vd.id_vacc = i_vacc
                                   AND vd.id_time = t.id_time
                                 ORDER BY n_dose ASC);
                ELSE
                    OPEN o_info_age FOR
                        SELECT label_dose || gap_between_dose text
                          FROM (SELECT decode((n_dose - 1),
                                              0,
                                              '<b>' || pk_message.get_message(i_lang, 'VACC_T014') || ' ' ||
                                              pk_message.get_message(i_lang, 'VACC_T012') || ' ' || n_dose ||
                                              vacc_ordinal(n_dose, i_lang) || ' ' ||
                                              pk_message.get_message(i_lang, 'VACC_T017'),
                                              '<b>' || pk_message.get_message(i_lang, 'VACC_T015') || ' ' || (n_dose - 1) ||
                                              vacc_ordinal(n_dose - 1, i_lang) || ' ' ||
                                              pk_message.get_message(i_lang, 'VACC_T016') || ' ' || n_dose ||
                                              vacc_ordinal(n_dose, i_lang) || ' ' ||
                                              pk_message.get_message(i_lang, 'VACC_T018')) || ': ' || '</b>' label_dose,
                                       decode((get_gap_between_doses(i_lang, (n_dose - 1), i_vacc)),
                                              NULL,
                                              decode(n_dose,
                                                     1,
                                                     to_char(get_age_recommend(i_lang,
                                                                               get_gap_between_doses(i_lang, n_dose, i_vacc))),
                                                     NULL),
                                              get_age_recommend(i_lang, get_gap_between_doses(i_lang, (n_dose), i_vacc))) gap_between_dose,
                                       n_dose
                                  FROM vacc_dose vd, TIME t
                                 WHERE vd.id_vacc = i_vacc
                                   AND vd.id_time = t.id_time
                                 ORDER BY n_dose ASC);
                END IF;
            END IF;
        ELSE
            OPEN o_info FOR
                SELECT NULL vacc_descr,
                       pk_message.get_message(i_lang, 'VACC_T010') || ' ' || '--' || '<br>' ||
                       pk_message.get_message(i_lang, 'VACC_T013') || ' ' ||
                       pk_message.get_message(i_lang, 'COMMON_M002') text
                  FROM dual;
        
            pk_types.open_my_cursor(o_info_age);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_DOSE_INFO_DETAIL_NEW',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_info_age);
            RETURN FALSE;
    END get_vacc_dose_info_detail_new;

    /************************************************************************************************************
    * Returns the information for the correct icon for the vaccines summary
    *
    * @param      i_dt           dose's administration date
    *
    * @return     String with the icon information
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/19
    ***********************************************************************************************************/
    FUNCTION get_vacc_last_take_icon(i_dt IN drug_presc_plan.dt_plan_tstz%TYPE) RETURN VARCHAR2 IS
    
        l_icon VARCHAR2(100) := '';
    BEGIN
    
        --IF i_dt > SYSDATE
        IF i_dt > current_timestamp
        THEN
            l_icon := l_green_color;
        ELSE
            l_icon := l_red_color;
        END IF;
    
        RETURN l_icon;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vacc_last_take_icon;

    /************************************************************************************************************
    * Returns the list of professionals for the institution, that can make the tubterculin test administration,
    * and an option that identifies an external professional
    *
    * @param      i_lang             id language
    * @param      i_prof             id professional
    * @param      o_prof_list        array with all professionals working in the institution, and 'other' option
    * @param      o_error            error message
    *
    * @return
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/08
    ***********************************************************************************************************/
    FUNCTION get_adm_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Lista de profissionais que podem fazer a administra��o das tuberculinas.
        l_prof_cat table_varchar := table_varchar(pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_nurse);
    
    BEGIN
    
        g_error := 'CALL get_prof_inst_and_other_list';
    
        IF NOT pk_list.get_prof_inst_and_other_list(i_lang, i_prof, l_prof_cat, o_prof_list, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'GET_ADM_PROF_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_prof_list);
            RETURN FALSE;
    END get_adm_prof_list;

    /********************************************************************************************
    * Informa��o sobre o profissional respons�vel
    *
    * @param i_lang                language id
    * @param i_prof                array do profissional
    * @param i_id_prof             professional who made change
    * @param i_date                date of change
    * @param i_episode             episode of change
    *
    * @return                      <signature> [(<specialty>)] / <date>
    *
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/10
    **********************************************************************************************/
    FUNCTION get_prof_resp_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_resp_info pk_translation.t_desc_translation;
    BEGIN
        IF i_date IS NOT NULL
           AND to_char(i_date, 'HH24MISS') = '000000'
        THEN
            l_prof_resp_info := pk_tools.get_prof_description(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_prof_id => i_id_prof,
                                                              i_date    => i_date,
                                                              i_episode => i_episode) || ' / ' ||
                                pk_date_utils.date_chr_short_read(i_lang, i_date, i_prof);
        ELSE
            l_prof_resp_info := pk_tools.get_prof_description(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_prof_id => i_id_prof,
                                                              i_date    => i_date,
                                                              i_episode => i_episode) || ' / ' ||
                                pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
        END IF;
    
        RETURN l_prof_resp_info;
    END get_prof_resp_info;

    /********************************************************************************************
    * Informa��o sobre a medica��o (ecr� de administra��o)
    *
    * @param i_lang                language id
    * @param i_prof                array do profissional
    * @param i_emb                id_do medicamento
    * @param i_med                'E' Externo , 'I' Interno
    *
    * @return                      Nome do medicamento
    *
    * @author                      Teresa Coutinho
    * @version                     1.0
    * @since                       2008/01/08
    **********************************************************************************************/

    FUNCTION get_med_descr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_emb       IN me_med.emb_id%TYPE,
        i_med       IN VARCHAR2,
        o_med_descr OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_desc    pat_vacc_adm_det.desc_vaccine%TYPE;
    
    BEGIN
        g_error := 'GET CURSOR O_ME_MED_DESCR';
    
        IF i_med = g_med_e
        THEN
            BEGIN
                SELECT b.desc_vaccine
                  INTO l_desc
                  FROM pat_vacc_adm a
                 INNER JOIN pat_vacc_adm_det b
                    ON a.id_pat_vacc_adm = b.id_pat_vacc_adm
                 WHERE a.id_pat_vacc_adm = i_emb
                   AND a.id_vacc = -1;
            
                OPEN o_med_descr FOR
                    SELECT l_desc med_descr
                      FROM dual;
            
            EXCEPTION
                WHEN no_data_found THEN
                
                    OPEN o_med_descr FOR
                        SELECT mm.med_descr_formated med_descr
                          FROM me_med mm
                         WHERE mm.emb_id = i_emb
                           AND mm.vers = l_version;
                
            END;
        ELSE
            OPEN o_med_descr FOR
                SELECT mm.med_descr_formated med_descr
                  FROM mi_med mm
                 WHERE mm.id_drug = i_emb
                   AND mm.vers = l_version;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_ME_MED_DESCR',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_med_descr;

    /**********************************************************************************************
    * Registar as administra��es das vacinas, relatos e provas � tuberculina V.2.4.2
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_vacc                   id da vacina
    * @param i_id_patient             id do paciente
    * @param i_id_episode             id do episodio
    * @param i_dt_begin               Data de registo
    * @param i_drug_presc_plan        Id da prescri��o
    * @param i_flg_status             Estado da Administra��o (pk_alert_constant.g_active - Administrado)
    * @param i_flg_orig               Origem ('V' - vacinas, 'T'- Tuberculina, 'R' - relato)
    * @param i_desc_vaccine           descri��o da vacina (utilizado para os relatos)
    * @param i_flg_advers_react       Se a administra��o teve reac��es adversas
    * @param i_application_spot       local de aplica��o
    * @param i_lot_number             Numero de lote
    * @param i_dt_expiration          Data que expira o medicamento
    * @param i_report_orig            Origem do relato
    * @param i_notes                  Notas
    * @param i_flg_time               Realiza��o: E - neste epis�dio; N - pr�ximo epis�dio; B - at� ao pr�ximo epis�dio
    * @param i_takes                  Numero de Tomas
    * @param i_dosage                 Dose
    * @param i_unit_measure           Unidade de medida
    * @param i_dt_presc               Data da prescri��o (vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_notes_presc            Notas da Prescri��o (vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_prof_presc             Profissional que prescreveu( texto livre vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_test                   Indica��o se testa a exist�ncia de vacinas administradas ou j� requisitadas (se a msg O_MSG_REQ ou O_MSG_RESULT j� foram apresentadas e o user continuou, I_TEST = pk_alert_constant.g_no)
    * @param i_prof_cat_type          categoria profissional
    
    * @param o_flg_show               Y - existe msg para mostrar; N - � existe
    * @param o_msg                    Mensagem com vacinas q foram requisitados recentemente ou que j� tinham sido administradas
    * @param o_msg_req                Mensagem com vacinas q foram requisitados recentemente
    * @param o_msg_title              T�tulo da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Bot�es a mostrar: N - n�o, R - lido, C - confirmado Tb pode mostrar combina��es destes, qd � p/ mostrar + do q 1 bot�o
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/11/28
    **********************************************************************************************/

    FUNCTION set_pat_vacc_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_vacc                IN table_number,
        i_emb                 IN table_varchar,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_presc               IN prescription.id_prescription%TYPE,
        i_flg_status          IN pat_vacc_adm.flg_status%TYPE,
        i_flg_orig            IN pat_vacc_adm.flg_orig%TYPE,
        i_desc_vaccine        IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_flg_advers_react    IN VARCHAR2,
        i_notes_advers_react  IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot    IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number          IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str   IN VARCHAR2,
        i_report_orig         IN pat_vacc_adm_det.report_orig%TYPE,
        i_notes               IN pat_vacc_adm_det.notes%TYPE,
        i_flg_time            IN table_varchar,
        i_takes               IN table_number,
        i_dosage              IN table_number,
        i_unit_measure        IN table_number,
        i_dt_presc            IN VARCHAR2,
        i_notes_presc         IN pat_vacc_adm.notes_presc%TYPE,
        i_prof_presc          IN pat_vacc_adm.prof_presc%TYPE,
        i_test                IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_flg_reported        IN VARCHAR2 DEFAULT NULL,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN pat_vacc_adm.flg_type_date%TYPE,
        i_dosage_admin        IN table_number,
        i_dosage_unit_measure IN table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_id_admin            OUT NUMBER,
        o_type_admin          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT set_pat_vacc_adm(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_vacc                => i_vacc,
                                i_emb                 => i_emb,
                                i_id_patient          => i_id_patient,
                                i_id_episode          => i_id_episode,
                                i_dt_begin_str        => i_dt_begin_str,
                                i_presc               => i_presc,
                                i_flg_status          => i_flg_status,
                                i_flg_orig            => i_flg_orig,
                                i_desc_vaccine        => i_desc_vaccine,
                                i_flg_advers_react    => i_flg_advers_react,
                                i_notes_advers_react  => i_notes_advers_react,
                                i_application_spot    => i_application_spot,
                                i_lot_number          => i_lot_number,
                                i_dt_expiration_str   => i_dt_expiration_str,
                                i_report_orig         => i_report_orig,
                                i_notes               => i_notes,
                                i_flg_time            => i_flg_time,
                                i_takes               => i_takes,
                                i_dosage              => i_dosage,
                                i_unit_measure        => i_unit_measure,
                                i_dt_presc            => i_dt_presc,
                                i_notes_presc         => i_notes_presc,
                                i_prof_presc          => i_prof_presc,
                                i_test                => i_test,
                                i_prof_cat_type       => i_prof_cat_type,
                                i_dt_predicted        => i_dt_predicted,
                                i_flg_reported        => i_flg_reported,
                                i_vacc_manuf          => i_vacc_manuf,
                                code_mvx              => code_mvx,
                                i_flg_type_date       => i_flg_type_date,
                                i_dosage_admin        => i_dosage_admin,
                                i_dosage_unit_measure => i_dosage_unit_measure,
                                o_flg_show            => o_flg_show,
                                o_msg                 => o_msg,
                                o_msg_req             => o_msg_req,
                                o_msg_title           => o_msg_title,
                                o_button              => o_button,
                                o_id_admin            => o_id_admin,
                                o_type_admin          => o_type_admin,
                                o_error               => o_error,
                                i_id_drug             => NULL)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'SET_PAT_VACC_ADM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    --------------------------------------
    -- ***********************************
    --------------------------------------
    FUNCTION set_pat_vacc_adm_pfh
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_dt_begin_str IN VARCHAR2,
        i_desc_vaccine IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_lot_number   IN pat_vacc_adm_det.lot_number%TYPE,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_flg_show  VARCHAR2(2000);
        l_msg       VARCHAR2(2000);
        l_msg_req   VARCHAR2(2000);
        l_msg_title VARCHAR2(2000);
        l_button    VARCHAR2(2000);
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_vacc_dup_count     NUMBER;
        l_dt_predicted_array table_varchar := table_varchar();
        l_dummy_1            table_varchar := table_varchar();
        l_dummy_2            table_varchar := table_varchar();
        l_predicted_take     pk_types.cursor_type;
    
        l_dt_predicted VARCHAR2(200);
    
        l_id_admin   pat_vacc_adm.id_pat_vacc_adm%TYPE;
        l_type_admin VARCHAR2(1);
    
    BEGIN
        IF pk_immunization_core.get_vacc_predicted_take(i_lang                => i_lang,
                                                        i_vacc                => i_vacc,
                                                        i_pat                 => i_id_patient,
                                                        i_prof                => NULL,
                                                        o_info_predicted_take => l_predicted_take,
                                                        o_error               => o_error)
        
        THEN
            FETCH l_predicted_take BULK COLLECT
                INTO l_dummy_1, l_dt_predicted_array, l_dummy_2;
        
            IF l_dt_predicted_array.count = 0
            THEN
                l_dt_predicted := NULL;
            ELSE
                l_dt_predicted := l_dt_predicted_array(l_dt_predicted_array.first);
            END IF;
        ELSE
            l_dt_predicted := NULL;
        END IF;
    
        ---------------------------------------
        -- valida��o da exist�ncia de um relato, importa��o ou administra��o da vacina para o paciente no dia indicado
        -- sou houver, a fun��o retorna FALSE de modo a que os interfaces saibam que n�o foi inserido um registo novo
        ---------------------------------------
        SELECT SUM(counter)
          INTO l_vacc_dup_count
          FROM (SELECT COUNT(1) AS counter -- relatos de vacinas e vacinas importadas do SINUS
                  FROM pat_vacc_adm pva
                 WHERE pva.id_vacc = i_vacc
                   AND pva.id_patient = i_id_patient
                   AND to_char(pva.dt_pat_vacc_adm, 'yyyymmdd') =
                       to_char(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str, NULL), 'yyyymmdd')
                UNION ALL
                SELECT COUNT(1) AS counter -- prescri��es de vacinas
                  FROM drug_prescription dp, drug_presc_det dpd, episode e, mi_med mm, vacc_dci vd, vacc v
                 WHERE dp.id_drug_prescription = dpd.id_drug_prescription
                   AND dpd.id_drug = mm.id_drug
                   AND dp.id_episode = e.id_episode
                   AND mm.vers = l_version
                   AND mm.flg_type = g_month
                   AND mm.dci_id = vd.id_dci
                   AND vd.id_vacc = v.id_vacc
                   AND dp.flg_status = 'F' -- concluido
                   AND v.id_vacc = i_vacc
                   AND e.id_patient = i_id_patient
                   AND to_char(dp.dt_drug_prescription_tstz, 'yyyymmdd') =
                       to_char(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str, NULL), 'yyyymmdd'));
    
        IF l_vacc_dup_count >= 1
        THEN
            RETURN FALSE;
        ELSE
            IF NOT set_pat_vacc_adm(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_vacc                => table_number(i_vacc),
                                    i_emb                 => table_varchar('-1'),
                                    i_id_patient          => i_id_patient,
                                    i_id_episode          => NULL,
                                    i_dt_begin_str        => i_dt_begin_str,
                                    i_presc               => NULL,
                                    i_flg_status          => pk_alert_constant.g_active,
                                    i_flg_orig            => g_orig_i, -- importada do SINUS
                                    i_desc_vaccine        => i_desc_vaccine,
                                    i_flg_advers_react    => -2, -- sem reac��es
                                    i_notes_advers_react  => NULL,
                                    i_application_spot    => NULL,
                                    i_lot_number          => i_lot_number,
                                    i_dt_expiration_str   => NULL,
                                    i_report_orig         => 'Importa��o SINUS',
                                    i_notes               => NULL,
                                    i_flg_time            => table_varchar(''),
                                    i_takes               => table_number(NULL),
                                    i_dosage              => table_number(NULL),
                                    i_unit_measure        => table_number(NULL),
                                    i_dt_presc            => NULL,
                                    i_notes_presc         => NULL,
                                    i_prof_presc          => NULL,
                                    i_test                => pk_alert_constant.g_no,
                                    i_prof_cat_type       => pk_alert_constant.g_cat_type_doc,
                                    i_dt_predicted        => l_dt_predicted,
                                    i_flg_reported        => NULL,
                                    i_id_drug             => table_varchar('-1'),
                                    i_flg_type_date       => g_day,
                                    i_dosage_admin        => table_number(NULL),
                                    i_dosage_unit_measure => table_number(NULL),
                                    o_flg_show            => l_flg_show,
                                    o_msg                 => l_msg,
                                    o_msg_req             => l_msg_req,
                                    o_msg_title           => l_msg_title,
                                    o_button              => l_button,
                                    o_id_admin            => l_id_admin,
                                    o_type_admin          => l_type_admin,
                                    o_error               => o_error)
            
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;
    --------------------------------------
    -- ***********************************
    --------------------------------------

    FUNCTION set_pat_vacc_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_vacc                IN table_number,
        i_emb                 IN table_varchar,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_presc               IN prescription.id_prescription%TYPE,
        i_flg_status          IN pat_vacc_adm.flg_status%TYPE,
        i_flg_orig            IN pat_vacc_adm.flg_orig%TYPE,
        i_desc_vaccine        IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_flg_advers_react    IN VARCHAR2,
        i_notes_advers_react  IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot    IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number          IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str   IN VARCHAR2,
        i_report_orig         IN pat_vacc_adm_det.report_orig%TYPE,
        i_notes               IN pat_vacc_adm_det.notes%TYPE,
        i_flg_time            IN table_varchar,
        i_takes               IN table_number,
        i_dosage              IN table_number,
        i_unit_measure        IN table_number,
        i_dt_presc            IN VARCHAR2,
        i_notes_presc         IN pat_vacc_adm.notes_presc%TYPE,
        i_prof_presc          IN pat_vacc_adm.prof_presc%TYPE,
        i_test                IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_flg_reported        IN VARCHAR2 DEFAULT NULL,
        i_id_drug             IN table_varchar,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN pat_vacc_adm.flg_type_date%TYPE,
        i_dosage_admin        IN table_number,
        i_dosage_unit_measure IN table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_id_admin            OUT NUMBER,
        o_type_admin          OUT VARCHAR2,
        o_error               OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        v_data_total             VARCHAR2(14);
        v_data_parcial           VARCHAR2(14);
        i_dt_begin_aux           VARCHAR2(14);
        i_dt_begin               TIMESTAMP WITH LOCAL TIME ZONE;
        i_dt_expiration          TIMESTAMP WITH LOCAL TIME ZONE;
        i_dt_presc_prof          TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_next_take           TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_pat_vacc_adm        pat_vacc_adm.id_pat_vacc_adm%TYPE;
        l_continue               BOOLEAN := TRUE;
        l_flg_status             VARCHAR2(1);
        l_prod_med               pk_types.cursor_type;
        l_id_pat_medic_list      pk_types.cursor_type; -- a utilizar em substitui��o da l_id_pat_medication_list nos parametros da fun��o set_pat_medication
        l_desc_vaccine           table_varchar;
        l_flg_status_a           table_varchar;
        l_id_pat_medication_list NUMBER;
        l_id_pat_medication_arr  table_number := table_number();
        l_id_drug                mi_med.id_drug%TYPE := NULL;
        l_emb_char               table_varchar;
        l_prod_med_decr          table_varchar;
        l_flg_status_prod        table_varchar;
        l_na                     sys_message.desc_message%TYPE;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_flg_type_date pat_vacc_adm.flg_type_date%TYPE := g_day;
        v_flg_total     VARCHAR2(2);
        v_flg_parcial   VARCHAR2(2);
    
        l_emb_id pat_vacc_adm_det.emb_id%TYPE;
    BEGIN
        l_na := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M036');
    
        -- vers�o 2.4.3 proxima toma
        IF i_dt_predicted = l_na
        THEN
            l_dt_next_take := NULL;
        ELSE
            l_dt_next_take := pk_date_utils.get_string_tstz(i_lang,
                                                            profissional(i_prof.id, i_prof.institution, NULL),
                                                            i_dt_predicted,
                                                            NULL);
        END IF;
    
        IF i_presc IS NOT NULL -- valida se a receita j� foi impressa, de outra forma n�o � possivel avan�ar
        THEN
            IF NOT exist_imp_presc(i_lang       => i_lang,
                                   i_id_episode => i_id_episode,
                                   i_id_patient => i_id_patient,
                                   i_presc      => i_presc,
                                   o_flg_show   => o_flg_show,
                                   o_msg        => o_msg,
                                   o_msg_req    => o_msg_req,
                                   o_msg_title  => o_msg_title,
                                   o_button     => o_button,
                                   o_error      => o_error)
            THEN
                --o_error := l_error;
                RETURN FALSE;
            END IF;
            IF o_flg_show = pk_alert_constant.g_yes
            THEN
                l_continue := FALSE;
                RETURN TRUE;
            END IF;
        END IF;
    
        i_dt_begin_aux := i_dt_begin_str;
        -- flg_type_date
        SELECT substr(i_dt_begin_str, 7, 2),
               substr(i_dt_begin_str, 1, 4) || '0101000000',
               substr(i_dt_begin_str, 5, 2),
               substr(i_dt_begin_str, 1, 6) || '01000000'
          INTO v_flg_total, v_data_total, v_flg_parcial, v_data_parcial
          FROM dual;
    
        IF i_flg_type_date IS NOT NULL
        THEN
            l_flg_type_date := i_flg_type_date;
            IF v_flg_total != '00'
            THEN
                i_dt_begin_aux := i_dt_begin_str;
            ELSIF v_flg_parcial != '00'
            THEN
                i_dt_begin_aux := v_data_parcial;
            ELSE
                i_dt_begin_aux := v_data_total;
            END IF;
        
        ELSE
            IF v_flg_total != '00'
            THEN
                l_flg_type_date := g_day;
                i_dt_begin_aux  := i_dt_begin_str;
            ELSIF v_flg_parcial != '00'
            THEN
                l_flg_type_date := g_month;
                i_dt_begin_aux  := v_data_parcial;
            ELSE
                l_flg_type_date := pk_alert_constant.g_yes;
                i_dt_begin_aux  := v_data_total;
            END IF;
        END IF;
        --dt_begin
        i_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                    profissional(i_prof.id, i_prof.institution, NULL),
                                                    i_dt_begin_aux,
                                                    NULL);
    
        --dt_presc
        i_dt_presc_prof := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_presc,
                                                         NULL);
    
        i_dt_expiration := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_expiration_str,
                                                         NULL);
        g_error         := ' INSERT INTO PAT_VACC_ADM ';
    
        g_sysdate := SYSDATE;
    
        IF i_test = pk_alert_constant.g_yes
        THEN
            -- Verificar se o exame j� tinha sido requisitado recentemente e se t�m resultados
            g_error := 'CALL TO EXIST_VACCINE_PRESC';
        
            IF NOT exist_pat_vacc(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_id_episode => i_id_episode,
                                  i_id_patient => i_id_patient,
                                  i_vacc       => i_vacc,
                                  i_emb        => i_emb,
                                  o_flg_show   => o_flg_show,
                                  o_msg        => o_msg,
                                  o_msg_req    => o_msg_req,
                                  o_msg_title  => o_msg_title,
                                  o_button     => o_button,
                                  o_error      => o_error)
            THEN
                --o_error := l_error;
                RETURN FALSE;
            END IF;
            IF o_flg_show = pk_alert_constant.g_yes
            THEN
                l_continue := FALSE;
            
            END IF;
        
        END IF;
        IF l_continue
        THEN
        
            FOR i IN 1 .. i_emb.count
            LOOP
            
                SELECT seq_pat_vacc_adm.nextval
                  INTO l_id_pat_vacc_adm
                  FROM dual;
            
                IF i_flg_time(i) = pk_alert_constant.g_no -- at� ao pr�ximo epis�dio
                THEN
                    l_flg_status := g_day; -- pendente
                ELSE
                    l_flg_status := i_flg_status;
                END IF;
            
                INSERT INTO pat_vacc_adm
                    (id_pat_vacc_adm,
                     dt_pat_vacc_adm,
                     id_prof_writes,
                     id_vacc,
                     id_patient,
                     id_episode,
                     flg_status,
                     flg_time,
                     takes,
                     dosage,
                     flg_orig,
                     dt_presc,
                     notes_presc,
                     prof_presc,
                     flg_type_date,
                     id_vacc_manufacturer,
                     code_mvx,
                     dosage_admin,
                     dosage_unit_measure,
                     flg_reported)
                VALUES
                    (l_id_pat_vacc_adm,
                     i_dt_begin,
                     i_prof.id,
                     i_vacc(i),
                     i_id_patient,
                     i_id_episode,
                     l_flg_status,
                     nvl(i_flg_time(i), g_flg_time_e),
                     i_takes(i),
                     i_dosage(i),
                     i_flg_orig,
                     i_dt_presc_prof,
                     i_notes_presc,
                     i_prof_presc,
                     l_flg_type_date,
                     i_vacc_manuf,
                     code_mvx,
                     i_dosage_admin(i),
                     i_dosage_unit_measure(i),
                     i_flg_reported);
            
                o_id_admin   := l_id_pat_vacc_adm;
                o_type_admin := 'V';
            
                g_error := ' INSERT INTO PAT_VACC_ADM_DET ';
            
                IF i_flg_orig = g_orig_r
                THEN
                    l_desc_vaccine := table_varchar();
                    l_desc_vaccine.extend;
                    l_desc_vaccine(1) := i_desc_vaccine;
                
                    l_flg_status_a := table_varchar();
                    l_flg_status_a.extend;
                    l_flg_status_a(1) := pk_alert_constant.g_active;
                
                    -- se for um relato insere na medica��o
                
                    FOR j IN 1 .. 1
                    LOOP
                        l_id_drug := -1;
                        --                        i_id_drug(j);
                    END LOOP;
                
                    IF l_id_drug IS NULL
                       OR l_id_drug = CAST(-1 AS VARCHAR) -- sem medicamento associado
                    THEN
                        IF NOT pk_medication_previous.set_outros_produtos(i_lang                  => i_lang,
                                                                          i_episode               => i_id_episode,
                                                                          i_patient               => i_id_patient,
                                                                          i_prof                  => i_prof,
                                                                          i_prod_med_decr         => l_desc_vaccine,
                                                                          i_med_id_type           => table_varchar(''),
                                                                          i_flg_status            => l_flg_status_a,
                                                                          i_dt_begin              => table_varchar(''),
                                                                          i_notes                 => table_varchar(''),
                                                                          i_prof_cat_type         => pk_alert_constant.g_cat_type_doc,
                                                                          i_qty                   => table_number(NULL),
                                                                          i_id_unit_measure_qty   => table_number(NULL),
                                                                          i_freq                  => table_number(NULL),
                                                                          i_id_unit_measure_freq  => table_number(NULL),
                                                                          i_duration              => table_number(NULL),
                                                                          i_id_unit_measure_dur   => table_number(NULL),
                                                                          i_dt_start_pat_med_tstz => table_varchar(''),
                                                                          i_dt_end_pat_med_tstz   => table_varchar(''),
                                                                          i_flg_show              => pk_alert_constant.g_no,
                                                                          i_epis_doc              => NULL,
                                                                          i_vers                  => table_varchar(l_version),
                                                                          i_flg_no_med            => pk_alert_constant.g_no,
                                                                          i_flg_take_type         => table_varchar(''),
                                                                          i_id_cdr_call           => table_number(NULL),
                                                                          o_prod_med              => l_prod_med,
                                                                          o_flg_show              => o_flg_show,
                                                                          o_msg                   => o_msg,
                                                                          o_msg_title             => o_msg_title,
                                                                          o_button                => o_button,
                                                                          o_error                 => o_error)
                        
                        -- no caso dos relatos ter� de interagir com a medica��o
                        THEN
                            ROLLBACK;
                            RETURN FALSE;
                        END IF;
                    
                        g_error := ' FETCH L_PROD_MED';
                    
                        /*FETCH l_prod_med
                        INTO l_id_pat_medication_list, l_prod_med_decr, l_flg_status_prod;*/
                    
                        FETCH l_prod_med
                            INTO l_id_pat_medication_arr, l_prod_med_decr, l_flg_status_prod;
                    
                        IF l_id_pat_medication_arr.count != 0
                        THEN
                            l_id_pat_medication_list := l_id_pat_medication_arr(l_id_pat_medication_arr.first);
                        ELSE
                            l_id_pat_medication_list := NULL;
                        END IF;
                    
                    ELSIF i_flg_orig = g_orig_v
                    THEN
                        -- com medicamento associado
                    
                        l_emb_char := table_varchar();
                        l_emb_char.extend;
                        l_emb_char(1) := i_emb(1);
                    
                        IF NOT pk_medication_previous.set_pat_medication(i_lang                  => i_lang,
                                                                         i_episode               => i_id_episode,
                                                                         i_patient               => i_id_patient,
                                                                         i_prof                  => i_prof,
                                                                         i_presc_pharm           => table_number(NULL),
                                                                         i_drug_req_det          => table_number(NULL),
                                                                         i_drug_presc_det        => table_number(NULL),
                                                                         i_id_pat_medic          => table_number(NULL),
                                                                         i_emb                   => l_emb_char,
                                                                         i_med                   => table_varchar(NULL),
                                                                         i_drug                  => i_id_drug,
                                                                         i_med_id_type           => table_varchar('I'),
                                                                         i_prod_med              => table_varchar(''),
                                                                         i_flg_status            => table_varchar(pk_alert_constant.g_active),
                                                                         i_dt_begin              => table_varchar(''),
                                                                         i_notes                 => table_varchar(''),
                                                                         i_flg_type              => table_varchar('I'),
                                                                         i_prof_cat_type         => pk_alert_constant.g_cat_type_doc,
                                                                         i_qty                   => table_number(NULL),
                                                                         i_id_unit_measure_qty   => table_number(NULL),
                                                                         i_freq                  => table_number(NULL),
                                                                         i_id_unit_measure_freq  => table_number(NULL),
                                                                         i_duration              => table_number(NULL),
                                                                         i_id_unit_measure_dur   => table_number(NULL),
                                                                         i_dt_start_pat_med_tstz => table_varchar(''),
                                                                         i_dt_end_pat_med_tstz   => table_varchar(''),
                                                                         i_epis_doc              => NULL,
                                                                         i_vers                  => table_varchar(l_version),
                                                                         i_flg_no_med            => pk_alert_constant.g_no,
                                                                         i_adv_reactions         => table_varchar(NULL), --NULL,
                                                                         i_med_destination       => table_varchar(NULL), --NULL,
                                                                         o_id_pat_medic_list     => l_id_pat_medic_list,
                                                                         --o_id_pat_medic_list     => l_id_pat_medication_list,
                                                                         o_error => o_error)
                        THEN
                            --o_error := l_error || ' xxxx ' || i_id_drug(1) || ' l_emb_char ' || l_emb_char(1);
                            ROLLBACK;
                            RETURN FALSE;
                        END IF;
                    
                        --if l_id_pat_medic_list is not null then
                        FETCH l_id_pat_medic_list
                            INTO l_id_pat_medication_list;
                        --   end if;
                    END IF;
                END IF;
            
                IF i_emb.exists(i)
                THEN
                    l_emb_id := i_emb(i);
                END IF;
            
                IF l_emb_id IS NULL
                   AND i_id_drug.exists(i)
                THEN
                    l_emb_id := i_id_drug(i);
                END IF;
            
                INSERT INTO pat_vacc_adm_det
                    (id_pat_vacc_adm_det,
                     id_pat_vacc_adm,
                     dt_take,
                     id_drug_presc_plan,
                     id_episode,
                     flg_status,
                     desc_vaccine,
                     lot_number,
                     dt_expiration,
                     flg_advers_react,
                     notes_advers_react,
                     application_spot,
                     report_orig,
                     notes,
                     emb_id,
                     id_unit_measure,
                     id_prof_writes,
                     dt_reg,
                     id_pat_medication_list,
                     dt_next_take,
                     flg_type_date,
                     id_vacc_manufacturer,
                     code_mvx,
                     flg_reported)
                VALUES
                    (seq_pat_vacc_adm_det.nextval,
                     l_id_pat_vacc_adm,
                     i_dt_begin,
                     NULL,
                     i_id_episode,
                     l_flg_status,
                     i_desc_vaccine,
                     i_lot_number,
                     i_dt_expiration,
                     i_flg_advers_react,
                     i_notes_advers_react,
                     i_application_spot,
                     i_report_orig,
                     i_notes,
                     l_emb_id,
                     i_unit_measure(i),
                     i_prof.id,
                     g_sysdate_tstz,
                     l_id_pat_medication_list,
                     l_dt_next_take,
                     l_flg_type_date,
                     i_vacc_manuf,
                     code_mvx,
                     i_flg_reported);
            
            END LOOP;
        
            --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
            --Checklist - 16
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate,
                                          i_dt_first_obs        => g_sysdate,
                                          o_error               => o_error)
            THEN
                --o_error := l_error;
                ROLLBACK;
                RETURN FALSE;
            END IF;
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
                                              'PK_VACC',
                                              'SET_PAT_VACC_ADM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END set_pat_vacc_adm;

    /**********************************************************************************************
    *   Verificar se a vacina j� tinha sido administrada, ou requisitado recentemente  V.2.4.2
    *
    * @param i_lang                  The id language
    * @param i_id_episode            Epis�dio
    * @param i_id_patient            Id do paciente
    * @param i_vacc                  Id da vacina
    * @param i_emb                   Id do medicamento
    *
    * @param o_flg_show              Y - existe msg para mostrar; N - � existe
    * @param o_msg                   mensagem com vacinas q foram administradas
    * @param o_msg_req               mensagem com vacinas q foram requisitados recentemente
    * @param o_msg_title             T�tulo da msg a mostrar ao utilizador, caso
    * @param o_flg_show              Y - existe msg para mostrar; N - � existe
    * @param o_button                Bot�es a mostrar: N - n�o, R - lido, C - confirmado Tb pode mostrar combina��es destes, qd � p/ mostrar + do q 1 bot�o
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Teresa Coutinho
    * @version                       1.0
    * @since                         2008/01/09
    **********************************************************************************************/

    FUNCTION exist_pat_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_vacc       IN table_number,
        i_emb        IN table_varchar,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_dt_req     vaccine_prescription.dt_vaccine_prescription%TYPE;
        l_string_req VARCHAR2(2000);
        l_string     VARCHAR2(2000);
        l_desc_vacc  VARCHAR2(200);
        l_first      BOOLEAN := TRUE;
        l_first_req  BOOLEAN := TRUE;
        l_version    mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_vacc_presc
        (
            l_vacc IN vacc.id_vacc%TYPE,
            l_emb  IN pat_vacc_adm_det.emb_id%TYPE
        ) IS
        
            SELECT med_descr desc_vacc --pva.dt_presc
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, me_med mm
             WHERE pva.id_episode = i_id_episode
               AND pva.flg_status != g_vacc_presc_canc
               AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
               AND pvad.flg_status != g_vacc_presc_det_canc
               AND pva.id_vacc = l_vacc
               AND mm.emb_id = pvad.emb_id
               AND mm.emb_id = l_emb
               AND mm.vers = l_version
               AND pva.id_episode_destination IS NULL;
    
        CURSOR c_vacc
        (
            l_vacc IN vacc.id_vacc%TYPE,
            l_emb  IN pat_vacc_adm_det.emb_id%TYPE
        ) IS
            SELECT med_descr desc_vacc
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, me_med mm
             WHERE pva.id_episode = i_id_episode
               AND pva.flg_status != g_vacc_presc_canc
               AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
               AND pvad.flg_status != g_vacc_presc_det_canc
               AND pva.id_vacc = l_vacc
               AND mm.emb_id = pvad.emb_id
               AND mm.emb_id = l_emb
               AND mm.vers = l_version
               AND pva.id_episode_destination IS NULL;
    
    BEGIN
        o_flg_show  := pk_alert_constant.g_no;
        o_msg_title := pk_message.get_message(i_lang, 'VACCINE_M001');
        o_button    := 'NC';
    
        g_error := 'LOOP';
        FOR i IN 1 .. i_vacc.count
        LOOP
            -- Loop sobre o array de IDs de vacinas
            g_error := 'OPEN C_VACCINE';
            OPEN c_vacc(i_vacc(i), i_emb(i));
            FETCH c_vacc
                INTO l_desc_vacc;
            g_found := c_vacc%FOUND;
            CLOSE c_vacc;
        
            g_error := 'EXIST VACC';
            IF g_found
            THEN
                -- Encontra administra��o
                o_flg_show := pk_alert_constant.g_yes;
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_string := l_string || ', ';
                END IF;
                l_string := l_string || l_desc_vacc;
            
            ELSE
                g_error := 'OPEN C_VACCINE_PRESC';
                OPEN c_vacc_presc(i_vacc(i), i_emb(i));
                FETCH c_vacc_presc
                    INTO l_desc_vacc; --l_dt_req
                g_found := c_vacc_presc%FOUND;
                CLOSE c_vacc_presc;
            
                IF g_found
                THEN
                    -- Encontra requisi��o
                    o_flg_show := pk_alert_constant.g_yes;
                    IF l_first_req
                    THEN
                        l_first_req := FALSE;
                    ELSE
                        l_string_req := l_string_req || ', ';
                    END IF;
                    l_string_req := l_string_req || l_desc_vacc;
                END IF;
            END IF;
        END LOOP;
    
        IF l_string IS NOT NULL
        THEN
            o_msg := REPLACE(pk_message.get_message(i_lang, 'VACCINE_M003'), '@1', l_string);
        END IF;
    
        IF l_string_req IS NOT NULL
        THEN
            o_msg_req := REPLACE(pk_message.get_message(i_lang, 'VACCINE_M002'), '@1', l_string_req);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'EXIST_PAT_VACC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END exist_pat_vacc;

    /**********************************************************************************************
    *   Alterar o estado da req (detalhe) de vacina:  requisitado => finalizado V.2.4.2
    *
    * @param i_lang                   The id language
    * @param i_vacc_adm_det           Id da requisicao de vacina
    * @param i_patient                Id do paciente
    * @param i_notes                  Notas (null FFR)
    * @param i_flg_take_type          Tipo de toma (null FFR)
    * @param i_prof                   Id_profissional
    * @param i_prof_cat_type          Categoria profiaaional
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2008/01/09
    **********************************************************************************************/

    FUNCTION set_vacc_presc_det
    (
        i_lang               IN language.id_language%TYPE,
        i_vacc_adm           IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_notes              IN pat_vacc_adm_det.notes%TYPE,
        i_flg_take_type      IN VARCHAR2,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_flg_advers_react   IN VARCHAR2,
        i_notes_advers_react IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot   IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number         IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str  IN VARCHAR2,
        i_dt_adm_str         IN VARCHAR2,
        i_vacc_manuf         IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx             IN vacc_manufacturer.code_mvx%TYPE,
        i_flg_type_date      IN pat_vacc_adm_det.flg_type_date%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_status IS
        
            SELECT pva.flg_status, pva.id_pat_vacc_adm, pva.flg_time, pva.id_vacc, pva.id_episode
              FROM pat_vacc_adm_det pvad, pat_vacc_adm pva
             WHERE pvad.id_pat_vacc_adm = i_vacc_adm
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.id_episode_destination IS NULL;
    
        CURSOR c_det(i_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE) IS
            SELECT 'X'
              FROM pat_vacc_adm_det
             WHERE --id_pat_vacc_adm_det != i_vacc_adm_det
            --AND
             id_pat_vacc_adm = i_vacc_adm
             AND flg_status NOT IN (g_vacc_presc_det_canc, g_vacc_presc_det_fin);
    
        l_status_ini  pat_vacc_adm_det.flg_status%TYPE;
        l_id_vacc_adm pat_vacc_adm.id_pat_vacc_adm%TYPE;
        l_flg_time    pat_vacc_adm.flg_time%TYPE;
        l_char        VARCHAR2(1);
        l_flg         pat_vacc_adm_det.flg_status%TYPE;
        l_vaccine     vacc.id_vacc%TYPE;
        l_epis        episode.id_episode%TYPE;
    
        l_flg_advers_react pat_vacc_adm_det.flg_advers_react%TYPE;
        i_dt_adm           TIMESTAMP WITH LOCAL TIME ZONE;
        i_dt_expiration    TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        i_dt_adm := pk_date_utils.get_string_tstz(i_lang,
                                                  profissional(i_prof.id, i_prof.institution, NULL),
                                                  i_dt_adm_str,
                                                  NULL);
    
        i_dt_expiration := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_expiration_str,
                                                         NULL);
    
        g_sysdate := SYSDATE;
    
        g_error := 'OPEN C_STATUS';
        OPEN c_status;
        FETCH c_status
            INTO l_status_ini, l_id_vacc_adm, l_flg_time, l_vaccine, l_epis;
        CLOSE c_status;
    
        IF l_status_ini IN (g_vacc_presc_det_req, g_vacc_presc_det_d)
        THEN
            g_error := 'VALIDATE';
            IF l_flg_time = g_flg_time_next
            THEN
                -- Uma vacina requisitada para epis. seguinte � pode ser administrada, pq
                -- qd � requisitado p/ um epis. futuro, a cria��o de epis�dio provoca a replica��o
                -- das requisi��es (em estado 'requisitado' e � 'pendente')
                --o_error := pk_message.get_message(i_lang, 'VACCINE_M005');
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_VACC',
                                                  'SET_VACC_PRESC_DET',
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
            IF i_flg_advers_react = '-1'
            THEN
                l_flg_advers_react := pk_alert_constant.g_yes;
            ELSIF i_flg_advers_react = '-2'
            THEN
                l_flg_advers_react := pk_alert_constant.g_no;
            ELSE
                l_flg_advers_react := pk_alert_constant.g_yes;
            END IF;
        
            g_error := 'UPDATE PAT_VACC_ADM_DET';
            UPDATE pat_vacc_adm_det
               SET flg_status           = g_vacc_presc_det_fin,
                   flg_advers_react     = l_flg_advers_react,
                   notes_advers_react   = i_notes_advers_react,
                   application_spot     = i_application_spot,
                   lot_number           = i_lot_number,
                   dt_expiration        = i_dt_expiration,
                   dt_take              = i_dt_adm,
                   notes                = i_notes,
                   id_prof_writes       = i_prof.id,
                   id_vacc_manufacturer = i_vacc_manuf,
                   code_mvx             = code_mvx,
                   flg_type_date        = i_flg_type_date
             WHERE id_pat_vacc_adm = i_vacc_adm;
        
            -- Pesquisa a exist�ncia de outros detalhes do mm cabe�alho, � cancelados
            g_error := 'OPEN C_DET';
            OPEN c_det(l_id_vacc_adm);
            FETCH c_det
                INTO l_char;
            g_found := c_det%FOUND;
            CLOSE c_det;
            IF g_found
            THEN
                l_flg := g_vacc_presc_par;
            ELSE
                l_flg := g_vacc_presc_res;
            END IF;
        
            g_error := 'UPDATE PAT_VACC_ADM';
            UPDATE pat_vacc_adm
               SET flg_status = l_flg, dt_pat_vacc_adm = i_dt_adm
             WHERE id_pat_vacc_adm = i_vacc_adm;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO PK_VACCINE.UPDATE_VACCINE_TASK';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_VACC_PRESC_DET',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /************************************************************************************************************
    * Validates the tuberculin test state, and returns the warings when existing
    *
    * @param      i_lang             id language
    * @param      i_prof             id professional
    * @param      i_test_id          tuberculin test ID
    *
    * @param      o_flg_show         flag that indicates if exist any warning message to be shown
    * @param      o_message_title    label for the title of the warning message screen
    * @param      o_message_text     warning message
    * @param      o_forward_button   label for the forward button
    * @param      o_back_button      label for the back button
    * @param      o_error            error message
    *
    * @return      TRUE if sucess, FALSE otherwise
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/11
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_warnings
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN drug_prescription.id_drug_prescription%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --test state
        l_test_state VARCHAR2(1);
    
        -- timestamps
        l_dt_presc     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_take      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_result    TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate_tstz TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        --times
        l_days  VARCHAR2(100);
        l_hours VARCHAR2(100);
    
        l_min_time_result CONSTANT NUMBER := 48;
        l_max_time_result CONSTANT NUMBER := 72;
        --    to_number((i_hours + (24 * i_days))) < l_max_time_result
    
    BEGIN
        g_error      := 'GET STATE';
        l_test_state := get_tuberculin_test_state(i_test_id);
        g_error      := 'GET TIMESTAMPS';
    
        SELECT dp.dt_drug_prescription_tstz, dpp.dt_take_tstz, dpr.dt_drug_presc_result
          INTO l_dt_presc, l_dt_take, l_dt_result
          FROM drug_prescription dp,
               drug_presc_det dpd,
               (SELECT *
                  FROM drug_presc_plan dpp1
                 WHERE dpp1.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend, pk_alert_constant.g_active)
                   AND dpp1.id_drug_presc_plan IN
                       (SELECT MAX(id_drug_presc_plan)
                          FROM drug_presc_plan dpp2
                         WHERE dpp2.id_drug_presc_det = dpp1.id_drug_presc_det)) dpp,
               drug_presc_result dpr
         WHERE dp.id_drug_prescription = i_test_id
           AND dp.id_drug_prescription = dpd.id_drug_prescription
           AND dpp.id_drug_presc_det(+) = dpd.id_drug_presc_det
              --pode n�o existir resultado
           AND dpp.id_drug_presc_plan = dpr.id_drug_presc_plan(+);
    
        g_error := 'VALIDATE WARNINGS';
        IF l_test_state = g_tuberculin_test_state_adm
        THEN
        
            l_days  := get_summary_time_day(l_sysdate_tstz, l_dt_take);
            l_hours := get_summary_time_hour(l_sysdate_tstz, l_dt_take);
        
            IF to_number((l_hours + (24 * l_days))) < l_min_time_result
            THEN
            
                o_flg_show := pk_alert_constant.g_yes;
                --text message
                SELECT s.desc_message text
                  INTO o_message_title
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_T043';
                --title message
                SELECT s.desc_message text
                  INTO o_message_text
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M001';
                --forward_button message
                SELECT s.desc_message text
                  INTO o_forward_button
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M002';
                --back_button message
                SELECT s.desc_message text
                  INTO o_back_button
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M003';
            ELSIF to_number((l_hours + (24 * l_days))) > l_max_time_result
            THEN
                o_flg_show := pk_alert_constant.g_yes;
                --text message
                SELECT s.desc_message text
                  INTO o_message_title
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_T043';
                --title message
                SELECT s.desc_message text
                  INTO o_message_text
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M004';
                --forward_button message
                SELECT s.desc_message text
                  INTO o_forward_button
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M002';
                --back_button message
                SELECT s.desc_message text
                  INTO o_back_button
                  FROM sys_message s
                 WHERE s.id_language = i_lang
                   AND s.code_message = 'TUBERCULIN_TEST_M003';
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        ELSE
            --n�o existe warning
            o_flg_show := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_TUBERCULIN_TEST_WARNINGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_tuberculin_test_warnings;
    --

    /**********************************************************************************************
    *    Verificar se existem registos provenientes do Interface V.2.4.2, e retornar uma
    * mensagem de aviso caso existam.
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_vacc                   id da vacina
    * @param i_id_patient             id do paciente
    *
    * @param      o_flg_show         flag that indicates if exist any warning message to be shown
    * @param      o_message_title    label for the title of the warning message screen
    * @param      o_message_text     warning message
    * @param      o_forward_button   label for the forward button
    * @param      o_back_button      label for the back button
    * @param      o_error            error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/11/26
    **********************************************************************************************/

    FUNCTION get_vacc_adm_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_count_vacc IS
            SELECT COUNT(*)
              FROM drug_presc_plan dpp, vacc_med_ext vme, drug_presc_det dpd, drug_prescription dp, episode e
             WHERE dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_vacc
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dp.id_episode = e.id_episode
               AND e.id_patient = i_id_patient;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_count_vacc_interf IS
            SELECT COUNT(*)
              FROM drug_presc_plan dpp, vacc_med_ext vme, drug_presc_det dpd, drug_prescription dp, episode e
             WHERE dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_vacc
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dp.id_episode = e.id_episode
               AND e.id_patient = i_id_patient
               AND vme.flg_available = pk_alert_constant.g_no;
    
        v_count_vacc NUMBER;
    
        v_count_vacc_interf NUMBER;
    
    BEGIN
        --todas as vacinas
        OPEN c_count_vacc;
        FETCH c_count_vacc
            INTO v_count_vacc;
        CLOSE c_count_vacc;
        --vacinas das interfaces
        OPEN c_count_vacc_interf;
        FETCH c_count_vacc_interf
            INTO v_count_vacc_interf;
        CLOSE c_count_vacc_interf;
    
        IF v_count_vacc = 0
           OR v_count_vacc <> v_count_vacc_interf
        THEN
            o_flg_show := pk_alert_constant.g_no;
        ELSE
            o_flg_show := pk_alert_constant.g_yes;
            --text message
            SELECT s.desc_message text
              INTO o_message_text
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_M006';
            --title message
            SELECT s.desc_message text
              INTO o_message_title
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T049';
            --forward_button message
            SELECT s.desc_message text
              INTO o_forward_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T040';
            --back_button message
            SELECT s.desc_message text
              INTO o_back_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T039';
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ADM_WARNINGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vacc_adm_warnings;
    --

    /************************************************************************************************************
    * This function returns the details for all takes for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_vacc_id            vaccine's id
    *
    * @param      o_main_title         screen's main title
    * @param      o_this_take_title    this take's title
    * @param      o_history_take_title takes history title
    * @param      o_detail_info        vaccine detail information
    * @param      o_vacc_name          vaccine name
    *
    * @param      o_can_title          title for canceled details
    * @param      o_can_det            cursor with the canceled details
    * @param      o_adm_title          title for administration details
    * @param      o_admdet             cursor with the administration details
    * @param      o_presc_title        title for prescription details
    * @param      o_presc_det          cursor with the prescription details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_vaccines_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_vacc_id IN vacc.id_vacc%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
        g_error := 'START';
        --main title
        SELECT pk_message.get_message(i_lang, 'VACC_T070') || ': ' ||
               pk_translation.get_translation(i_lang, v.code_desc_vacc) --v.desc_vacc_extv.desc_vacc_ext
          INTO o_main_title
          FROM vacc v
         WHERE v.id_vacc = i_vacc_id;
    
        --this take title (apenas a label)
        o_this_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T042');
    
        --takes history title (apenas a label)
        o_history_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T041');
    
        --vacc name
        --Esta informa��o serve o caso particular de administra��o de vacinas
        SELECT nvl(pk_translation.get_translation(i_lang, v.code_desc_vacc),
                   pk_translation.get_translation(i_lang, v.code_vacc)) --v.desc_vacc_ext
          INTO o_vacc_name
          FROM vacc v
         WHERE v.id_vacc = i_vacc_id;
    
        IF NOT get_vacc_viewer_details(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_vacc        => i_vacc_id,
                                       o_detail_info => o_detail_info,
                                       o_error       => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        --responsible:
        OPEN o_test_info FOR
        -- vacinas fora do PNV ou relatos
            SELECT pva.id_pat_vacc_adm id_test,
                   decode(pva.flg_orig,
                          g_orig_i,
                          ' ',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)) prof_name,
                   count_vacc_take(i_lang, i_patient, i_vacc_id, pvad.dt_take, i_prof) ||
                   vacc_ordinal(count_vacc_take(i_lang, i_patient, i_vacc_id, pvad.dt_take, i_prof), i_lang) || ' ' ||
                   pk_message.get_message(i_lang, 'VACC_T017') dt_last,
                   --esta str apenas aparece no caso de ser um relato
                   decode(pva.flg_orig, g_orig_i, '(' || pvad.report_orig || ')', '') ||
                   --esta str apenas aparece no caso de ser uma vacina trazida pelo utente
                    decode(pva.flg_reported,
                           pk_alert_constant.g_yes,
                           pk_message.get_message(i_lang, 'VACC_T062'),
                           decode(pva.prof_presc, NULL, '', '(' || pk_message.get_message(i_lang, 'VACC_T071') || ')')) desc_other,
                   pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T050') desc_state,
                   --falta o estado cancelado
                   get_summary_state_label(i_lang, --
                                           decode(pva.flg_status,
                                                  g_day,
                                                  'P',
                                                  pk_alert_constant.g_no,
                                                  'P',
                                                  'R',
                                                  'P',
                                                  pk_alert_constant.g_active,
                                                  pk_alert_constant.g_active,
                                                  'C',
                                                  'C',
                                                  'P')) state,
                   decode(pva.flg_status,
                          g_day,
                          'P',
                          pk_alert_constant.g_no,
                          'P',
                          'R',
                          'P',
                          pk_alert_constant.g_active,
                          pk_alert_constant.g_active,
                          'C',
                          'C',
                          'P') flg_state,
                   pvad.dt_take dt_take
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p
             WHERE pva.id_vacc = i_vacc_id
               AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
               AND pva.id_patient = i_patient
               AND pva.id_prof_writes = p.id_professional
               AND pva.id_episode_destination IS NULL
            UNION ALL
            -- vacinas do PNV
            SELECT dp.id_drug_prescription id_test,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   count_vacc_take(i_lang, i_patient, i_vacc_id, dpp.dt_take_tstz, i_prof) ||
                   vacc_ordinal(count_vacc_take(i_lang, i_patient, i_vacc_id, dpp.dt_take_tstz, i_prof), i_lang) || ' ' ||
                   pk_message.get_message(i_lang, 'VACC_T017') dt_last,
                   '' desc_other,
                   pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T050') desc_state,
                   --as vacinas do PNV apenas t�m o estado administrado
                   get_summary_state_label(i_lang, pk_alert_constant.g_active) state,
                   pk_alert_constant.g_active flg_state,
                   dp.dt_drug_prescription_tstz dt_take
              FROM drug_prescription dp,
                   drug_presc_det    dpd,
                   drug_presc_plan   dpp,
                   mi_med            mim,
                   vacc_dci          vd,
                   professional      p
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND mim.dci_id = vd.id_dci
               AND mim.vers = l_version
               AND vd.id_vacc = i_vacc_id
               AND dp.id_professional = p.id_professional
            UNION ALL
            -- vacinas do PNV antigas
            SELECT dp.id_drug_prescription id_test,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   count_vacc_take(i_lang, i_patient, i_vacc_id, dpp.dt_take_tstz, i_prof) ||
                   vacc_ordinal(count_vacc_take(i_lang, i_patient, i_vacc_id, dpp.dt_take_tstz, i_prof), i_lang) || ' ' ||
                   pk_message.get_message(i_lang, 'VACC_T017') dt_last,
                   '' desc_other,
                   pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T050') desc_state,
                   --as vacinas do PNV apenas t�m o estado administrado
                   get_summary_state_label(i_lang, pk_alert_constant.g_active) state,
                   pk_alert_constant.g_active flg_state,
                   dp.dt_drug_prescription_tstz dt_take
              FROM drug_prescription dp,
                   drug_presc_det    dpd,
                   drug_presc_plan   dpp,
                   mi_med            mim,
                   vacc_med_ext      vme,
                   professional      p
             WHERE dp.id_patient = i_patient
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                  --filtro do grupo das vacinas
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND vme.id_vacc = i_vacc_id
               AND dp.id_professional = p.id_professional
             ORDER BY dt_take;
    
        g_error := 'CALL THE FUNCTION get_vaccine_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_vacc_canc_det(i_lang      => i_lang,
                                 i_patient   => i_patient,
                                 i_prof      => i_prof,
                                 i_test_id   => i_vacc_id,
                                 i_to_add    => FALSE,
                                 o_can_title => o_can_title,
                                 o_can_det   => o_can_det,
                                 o_error     => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_vaccine_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_vacc_adm_det(i_lang      => i_lang,
                                i_patient   => i_patient,
                                i_prof      => i_prof,
                                i_test_id   => i_vacc_id,
                                i_to_add    => FALSE,
                                o_adm_title => o_adm_title,
                                o_adm_det   => o_adm_det,
                                o_error     => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        --apenas para vacinas fora do PNV
        g_error := 'CALL THE FUNCTION get_vaccine_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_vacc_presc_det(i_lang         => i_lang,
                                  i_patient      => i_patient,
                                  i_prof         => i_prof,
                                  i_vacc_id      => i_vacc_id,
                                  i_vacc_take_id => NULL,
                                  i_to_add       => FALSE,
                                  o_presc_title  => o_presc_title,
                                  o_presc_det    => o_presc_det,
                                  o_error        => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        --apenas para vacinas fora do PNV
        g_error := 'CALL THE FUNCTION get_vaccine_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_vacc_advers_react_det(i_lang    => i_lang,
                                         i_patient => i_patient,
                                         i_prof    => i_prof,
                                         i_test_id => i_vacc_id,
                                         i_to_add  => FALSE,
                                         --OUT
                                         o_advers_react_title => o_advers_react_title,
                                         o_advers_react_det   => o_advers_react_det,
                                         --ERROR
                                         o_error => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'GET_VACCINES_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_test_info);
            pk_types.open_my_cursor(o_can_det);
            pk_types.open_my_cursor(o_adm_det);
            pk_types.open_my_cursor(o_presc_det);
            pk_types.open_my_cursor(o_advers_react_det);
            RETURN FALSE;
    END get_vaccines_detail;
    --
    /**********************************************************************************************
    *   Verificar se a receita j� foi impressa
    *
    * @param i_lang                  The id language
    * @param i_id_episode            Epis�dio
    * @param i_id_patient            Id do paciente
    * @param i_presc                 Id da prescri��o
    *
    * @param o_flg_show              Y - existe msg para mostrar; N - � existe
    * @param o_msg                   mensagem
    * @param o_msg_req               mensagem
    * @param o_msg_title             T�tulo da msg a mostrar ao utilizador, caso
    * @param o_button                Bot�es a mostrar: N - n�o, R - lido, C - confirmado Tb pode mostrar combina��es destes, qd � p/ mostrar + do q 1 bot�o
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Teresa Coutinho
    * @version                       1.0
    * @since                         2008/02/13
    **********************************************************************************************/

    FUNCTION exist_imp_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_presc      IN prescription.id_prescription%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_presc VARCHAR2(1);
    
        CURSOR c_presc IS
        
            SELECT p.flg_status
              FROM prescription p
             WHERE p.id_prescription = i_presc
               AND p.flg_status = g_flg_status_p;
    
    BEGIN
        o_flg_show  := pk_alert_constant.g_no;
        o_msg_title := pk_message.get_message(i_lang, 'DISCH_PRESCRIPTION_T001');
        o_button    := 'C';
    
        OPEN c_presc;
        FETCH c_presc
            INTO l_presc;
        g_found := c_presc%FOUND;
        CLOSE c_presc;
    
        g_error := 'EXIST PRESC IMP';
        IF g_found
        THEN
            o_flg_show := pk_alert_constant.g_no;
        ELSE
            o_flg_show := pk_alert_constant.g_yes;
            o_msg      := pk_message.get_message(i_lang, 'VACC_M011');
            o_msg_req  := pk_message.get_message(i_lang, 'VACC_M011');
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'INS_DRUG_PRESC_PLAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END exist_imp_presc;

    /************************************************************************************************************
    * Return the TIMESTAMP as a string in the correct format
    *
    * @param      i_lang               language
    * @param      i_prof               profissional
    * @param      i_date               TIMESTAMP
    *
    * @return     a string with the date in the the correct format
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/02/27
    ***********************************************************************************************************/
    FUNCTION format_dt_expiration_test_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR IS
    
        l_str_date VARCHAR2(100);
    BEGIN
    
        IF i_date IS NOT NULL
        THEN
            l_str_date := pk_date_utils.date_chr_short_read(i_lang, i_date, i_prof);
        ELSE
            RETURN NULL;
        END IF;
        RETURN l_str_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_dt_expiration_test_date;

    /************************************************************************************************************
    * Return the TIMESTAMP as a string in the correct format
    *
    * @param      i_lang               language
    *
    * @return     unit for the reading keypad
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/02/28
    ***********************************************************************************************************/

    FUNCTION get_reading_unit_list
    (
        i_lang      IN language.id_language%TYPE,
        o_read_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_read_unit FOR
            SELECT 1 val_min, 99 val_max, 'mm' unit
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_READING_UNIT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_read_unit);
            RETURN FALSE;
    END;

    PROCEDURE upd_drug_presc_det
    (
        id_drug_presc_det_in IN drug_presc_det.id_drug_presc_det%TYPE,
        i_vacc_manufacturer  IN drug_presc_det.id_vacc_manufacturer%TYPE,
        code_mvx             IN drug_presc_det.code_mvx%TYPE
    ) IS
        l_rowids table_varchar;
        l_error  VARCHAR2(4000);
        o_error  t_error_out;
    BEGIN
        ts_drug_presc_det.upd(id_drug_presc_det_in     => id_drug_presc_det_in,
                              flg_status_in            => g_drug_presc_det_f,
                              id_vacc_manufacturer_in  => i_vacc_manufacturer,
                              id_vacc_manufacturer_nin => FALSE,
                              code_mvx_in              => code_mvx,
                              code_mvx_nin             => FALSE,
                              rows_out                 => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => NULL,
                                      i_prof         => NULL,
                                      i_table_name   => 'DRUG_PRESC_DET',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20003, g_error_message_20003 || '/' || l_error || '/' || SQLERRM);
            --  falta i_lang para poder chamar a fun��o process_error
            pk_utils.undo_changes;
    END upd_drug_presc_det;

    /************************************************************************************************************
    * Cancel the reported vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_episode            episode
    * @param      i_id_patient         patient
    * @param      i_prof               profissional
    * @param      id_id_pat_medication_list  id_pat_medication_list
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/03/20
    ***********************************************************************************************************/
    FUNCTION set_cancel_report_vacc
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_prof                    IN profissional,
        id_id_pat_medication_list IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_vacc_adm           pat_vacc_adm.id_pat_vacc_adm%TYPE;
        l_id_id_pat_medication_list NUMBER;
    
        CURSOR c_medication_list IS
            SELECT pva.id_pat_vacc_adm
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pvad.id_pat_medication_list = l_id_id_pat_medication_list
               AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm;
    
    BEGIN
        IF id_id_pat_medication_list IS NOT NULL
        THEN
            FOR i IN 1 .. 1
            LOOP
                l_id_id_pat_medication_list := id_id_pat_medication_list(1);
            END LOOP;
        
            g_error := 'GET L_ID_PAT_VACC_ADM';
        
            OPEN c_medication_list;
            FETCH c_medication_list
                INTO l_id_pat_vacc_adm;
            g_found := c_medication_list%FOUND;
            CLOSE c_medication_list;
        
            g_error := 'GET SET_CANCEL_OTHER_VACC';
            IF g_found
            THEN
                IF NOT set_cancel_other_vacc(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_vacc_presc_id => l_id_pat_vacc_adm,
                                             i_notes_cancel  => NULL,
                                             o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
        END IF;
        --COMMIT; -- Jos� Brito 12/03/2010 ALERT-26489 Avoid commit when cancelling reported medication.
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_CANCEL_REPORT_VACC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    /************************************************************************************************************
    * GET PNV vaccines
    *
    * @param      i_lang               language
    * @param      i_id_patient         patient
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION get_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_vaccine    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
    BEGIN
        --
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_vaccine);
            RETURN TRUE;
        END IF;
    
        -- retorna os registos que est�o ocultos
        OPEN o_vaccine FOR
            SELECT v.id_vacc par_var,
                   pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                   decode(count_vacc_take_all(i_lang, i_id_patient, v.id_vacc, NULL), 0, NULL, 'Agendamento' || ' ') ||
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det
              FROM vacc_group vg, vacc v
             WHERE vg.id_vacc_type_group = l_vacc_type_group
               AND vg.id_vacc = v.id_vacc
             ORDER BY pk_translation.get_translation(i_lang, v.code_vacc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vaccine);
            RETURN FALSE;
    END;

    /************************************************************************************************************
    * Add PNV vaccines
    *
    * @param      i_lang               language
    * @param      i_id_patient         patient
    * @param      i_vacc        array id_vacc
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION ins_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_vacc       IN table_number,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids      table_varchar;
        l_pat_vacc_tc ts_pat_vacc.pat_vacc_tc;
        l_pat_vacc    pat_vacc%ROWTYPE;
    BEGIN
        IF i_vacc IS NOT NULL
           AND i_vacc.count > 0
        THEN
            l_pat_vacc.id_patient      := i_id_patient;
            l_pat_vacc.flg_available   := pk_alert_constant.g_yes;
            l_pat_vacc.dt_pat_vacc     := g_sysdate_tstz;
            l_pat_vacc.id_professional := i_prof.id;
            l_pat_vacc.id_episode      := i_episode;
        
            FOR i IN 1 .. i_vacc.count
            LOOP
                l_pat_vacc.id_vacc := i_vacc(i);
            
                l_pat_vacc_tc(i) := l_pat_vacc;
            END LOOP;
        
            g_error := 'CALL ts_pat_vacc.ins';
            ts_pat_vacc.ins(rows_in => l_pat_vacc_tc, rows_out => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'pat_vacc',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'INS_VACC',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /************************************************************************************************************
    * Validates the hided values and returns the warings when existing
    *
    * @param      i_lang               language
    * @param      i_prof               professional
    * @param      i_val                code 'OV'/'OP'
    * @param      i_vacc               id_vacc
    * @param      i_patient            id_patient
    *
    * @param      o_flg_show         flag that indicates if exist any warning message to be shown
    * @param      o_message_title    label for the title of the warning message screen
    * @param      o_message_text     warning message
    * @param      o_forward_button   label for the forward button
    * @param      o_back_button      label for the back button
    * @param      o_error            error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION get_vacc_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_val        IN sys_domain.val%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_val = 'OP'
        THEN
            -- Ocultar Vacina do Programa Nacional de Vacina��o
            o_flg_show := pk_alert_constant.g_yes;
            --text message
            SELECT s.desc_message text
              INTO o_message_text
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_M012';
            --title message
            SELECT s.desc_message text
              INTO o_message_title
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T073';
            --forward_button message
            SELECT s.desc_message text
              INTO o_forward_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T075';
            --back_button message
            SELECT s.desc_message text
              INTO o_back_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T074';
        ELSE
            -- OP Ocultar Programa Nacional de Vacina��o
            o_flg_show := pk_alert_constant.g_yes;
            --text message
            SELECT s.desc_message text
              INTO o_message_text
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_M012';
            --title message
            SELECT s.desc_message text
              INTO o_message_title
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T077';
            --forward_button message
            SELECT s.desc_message text
              INTO o_forward_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T075';
            --back_button message
            SELECT s.desc_message text
              INTO o_back_button
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message = 'VACC_T074';
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_WARNINGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vacc_warnings;

    /************************************************************************************************************
    * GET available groups -- depending on presc_type, verifies if it's available for the institution and software
    *
    * @param      i_lang               language
    * @param      i_id_patient         patient
    * @param      i_vacc               vaccine
    *
    * @param      o_error              error message
    *
    * @return     varchar2 pk_alert_constant.g_yes available ; pk_alert_constant.g_no Not available
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/22
    ***********************************************************************************************************/

    FUNCTION get_group_available
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_presc_type IN vacc_type_group.flg_presc_type%TYPE
    ) RETURN VARCHAR2 IS
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
        CURSOR c_vacc_type_group IS
            SELECT MAX(vtg.id_vacc_type_group)
              FROM vacc_type_group vtg, vacc_type_group_soft_inst vtgsi
             WHERE vtgsi.id_vacc_type_group = vtg.id_vacc_type_group
               AND vtg.flg_presc_type = i_presc_type
               AND vtgsi.id_institution = i_prof.institution
               AND vtgsi.id_software = i_prof.software;
    
    BEGIN
    
        OPEN c_vacc_type_group;
        FETCH c_vacc_type_group
            INTO l_vacc_type_group;
        g_found := c_vacc_type_group%FOUND;
        CLOSE c_vacc_type_group;
        IF NOT g_found
           OR l_vacc_type_group IS NULL
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        RETURN pk_alert_constant.g_yes;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END;

    /************************************************************************************************************
    * Count all the takes for a patient in the PNV
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient
    * @param      i_vacc               vaccine
    * @param      i_prof               professional
    *
    * @param      o_error              error message
    *
    * @return     number of takes
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/23
    ***********************************************************************************************************/

    FUNCTION count_vacc_take_all
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE,
        i_prof   IN profissional
    ) RETURN NUMBER IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_count_take_all IS
        --Doses j� administradas
            SELECT COUNT(COUNT)
              FROM (SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           vacc_med_ext      vme,
                           drug_presc_plan   dpp,
                           vacc              v,
                           visit             vi,
                           episode           e
                     WHERE dpd.id_drug = mm.id_drug
                       AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                       AND vme.id_vacc = v.id_vacc
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND dp.id_patient = i_id_pat
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    --Novas vacinas que n�o usam a vacc_med_ext
                    SELECT 1 COUNT
                      FROM drug_prescription dp,
                           drug_presc_det    dpd,
                           mi_med            mm,
                           drug_presc_plan   dpp,
                           vacc              v,
                           visit             vi,
                           episode           e,
                           vacc_dci          vd
                     WHERE dpd.id_drug = mm.id_drug
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpd.id_drug = mm.id_drug
                       AND mm.dci_id = vd.id_dci
                       AND vd.id_vacc = v.id_vacc
                       AND mm.vers = l_version
                       AND mm.flg_type = g_month
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND dp.id_patient = i_id_pat
                       AND e.id_episode = dp.id_episode
                       AND e.id_visit = vi.id_visit
                       AND vi.id_patient = i_id_pat
                    UNION ALL
                    -- relatos
                    SELECT 1 COUNT
                      FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad
                     WHERE pva.id_patient = i_id_pat
                       AND pvad.emb_id = mem.emb_id(+)
                       AND pva.id_vacc = i_vacc
                       AND pva.flg_orig IN ('R', 'V')
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL
                       AND pva.flg_status NOT IN (pk_alert_constant.g_cancelled, g_vacc_status_edit));
    
        l_count_take NUMBER;
    
    BEGIN
        g_error := 'OPEN C_COUNT_TAKE';
        OPEN c_count_take_all;
        FETCH c_count_take_all
            INTO l_count_take;
    
        CLOSE c_count_take_all;
    
        RETURN l_count_take;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END count_vacc_take_all;

    /************************************************************************************************************
    * Returns the date of the last administration for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient's ID
    * @param      i_vacc               vaccine's ID
    *
    * @return     date for the last vaccine administration
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/04/28
    ***********************************************************************************************************/
    FUNCTION get_next_take_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_date_bd IS
            SELECT pat1.dt_birth
              FROM patient pat1
             WHERE pat1.id_patient = i_id_pat
               AND pat1.flg_status != pk_alert_constant.g_inactive;
    
        --Este cursor retorna a data mais recente de uma administra��o de vacinas ou relatos
        CURSOR c_date IS
            SELECT CAST(MAX(dt_adm) AS DATE)
              FROM (
                    --registo de vacinas antigas
                    SELECT dpp.dt_take_tstz dt_adm
                      FROM drug_prescription dp,
                            drug_presc_det    dpd,
                            mi_med            mm,
                            vacc_med_ext      vme,
                            drug_presc_plan   dpp,
                            vacc              v,
                            episode           e
                     WHERE dpd.id_drug = mm.id_drug
                       AND mm.flg_type = 'V'
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                       AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
                       AND vme.id_vacc = v.id_vacc
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_patient = i_id_pat
                    UNION ALL
                    --Novas vacinas que n�o usam a vacc_med_ext
                    SELECT nvl(dpp.dt_next_take, dpp.dt_take_tstz) dt_adm
                      FROM drug_prescription dp,
                            drug_presc_det    dpd,
                            mi_med            mm,
                            drug_presc_plan   dpp,
                            vacc              v,
                            episode           e,
                            vacc_dci          vd
                     WHERE dpd.id_drug = mm.id_drug
                       AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dp.id_drug_prescription = dpd.id_drug_prescription
                          --Novas vacinas
                       AND dpd.id_drug = mm.id_drug
                       AND mm.dci_id = vd.id_dci
                       AND vd.id_vacc = v.id_vacc
                       AND mm.vers = l_version
                       AND mm.flg_type = g_month
                          --
                       AND dpp.flg_status = pk_alert_constant.g_active
                       AND v.id_vacc = i_vacc
                       AND e.id_episode = dp.id_episode
                       AND e.id_patient = i_id_pat
                    UNION ALL
                    -- relatos e vacinas fora do PNV
                    SELECT nvl(pvad.dt_next_take, decode(pvad.dt_take, NULL, pvad.dt_reg, pvad.dt_take)) dt_adm
                      FROM pat_vacc_adm pva, me_med mem, pat_vacc_adm_det pvad
                     WHERE pva.id_patient = i_id_pat
                       AND pvad.emb_id = mem.emb_id(+)
                       AND pva.id_vacc = i_vacc
                       AND pva.flg_orig IN ('R', 'I') -- relatos e importadas do SINUS
                       AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                       AND pva.id_episode_destination IS NULL);
    
        l_date    TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_bd TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        OPEN c_date;
        FETCH c_date
            INTO l_date;
    
        CLOSE c_date;
    
        IF l_date IS NULL
        THEN
            OPEN c_date_bd;
            FETCH c_date_bd
                INTO l_date_bd;
        
            CLOSE c_date_bd;
            RETURN l_date_bd;
        ELSE
            RETURN l_date;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_next_take_date;

    /************************************************************************************************************
    * This function returns a string with the day and month(abbreviation) separated by a space,
    *  for a specified TIMESTAMP (e.g. 12 Nov)
    *
    * @param      i_lang           language
    * @param      i_dt             date as a timestamp
    * @param      i_prof           professional
    *
    * @return     day and month(abbreviation) as a string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/05/14
    ***********************************************************************************************************/
    FUNCTION get_day_month_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    
    BEGIN
        --devolve o m�s como uma string
        RETURN substr(REPLACE(pk_date_utils.date_chr_space_tsz(i_lang, i_dt, i_prof.institution, 0), ','), 0, 7);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_day_month_from_timestamp;
    /************************************************************************************************************
    * This function returns the ordinality of a dose
    *
    * @param      n_dose           dose
    * @param      i_lang           language
    *
    * @return     string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/11/04
    ***********************************************************************************************************/

    FUNCTION vacc_ordinal
    (
        n_dose IN NUMBER,
        i_lang IN language.id_language%TYPE
    ) RETURN VARCHAR2 IS
        x_result VARCHAR2(2);
    BEGIN
        IF i_lang = 2
        THEN
            IF abs(n_dose) BETWEEN 10 AND 20
            THEN
                RETURN 'th';
            END IF;
            SELECT decode(MOD(abs(n_dose), 10), 1, 'st', 2, 'nd', 3, 'rd', 'th')
              INTO x_result
              FROM dual;
        ELSE
        
            x_result := pk_message.get_message(i_lang, 'VACC_T022');
        
        END IF;
    
        RETURN x_result;
    
    END;

    /********************************************************************************************
    * Devolve cursor com as vacinas a integrar no DASHBOARD_CARE
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_id_patient  Patient ID
    * @param IN   i_id_episode  Episode ID
    
    * @param OUT  o_vacc        cursor com as vacinas (para integrar com alertas de sa�de)
    *
    * @author                   Pedro Teixeira
    * @since                    27/04/2009
    ********************************************************************************************/
    FUNCTION get_care_dash_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vacc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
        l_desc_status VARCHAR2(200);
        --configuracao - Aparecer a cor das vacinas em falta
        l_pnv_color_display sys_config.value%TYPE;
    BEGIN
    
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            pk_types.open_my_cursor(o_vacc);
            RETURN TRUE;
        END IF;
    
        l_desc_status       := pk_message.get_message(i_lang, 'CARE_DASHBOARD_M003');
        l_pnv_color_display := pk_sysconfig.get_config('PNV_COLOR_DISPLAY', i_prof);
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN o_vacc FOR
            SELECT description, status, desc_status
              FROM (SELECT pk_translation.get_translation(i_lang, v.code_vacc) description,
                           decode(l_pnv_color_display,
                                  pk_alert_constant.g_no,
                                  '914|I|||' || g_waitingicon || '|||||' ||
                                  pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) || '|',
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_text,
                                                                       NULL,
                                                                       decode(get_next_take_date(i_lang,
                                                                                                 i_prof,
                                                                                                 i_patient,
                                                                                                 v.id_vacc),
                                                                              NULL,
                                                                              decode(abs((get_last_date(i_lang,
                                                                                                        i_prof,
                                                                                                        i_patient,
                                                                                                        v.id_vacc) +
                                                                                         t.val_min) - SYSDATE),
                                                                                     NULL,
                                                                                     pk_message.get_message(i_lang,
                                                                                                            'COMMON_M036'),
                                                                                     get_age_recommend(i_lang,
                                                                                                       abs((get_last_date(i_lang,
                                                                                                                          i_prof,
                                                                                                                          i_patient,
                                                                                                                          v.id_vacc) +
                                                                                                           t.val_min) -
                                                                                                           SYSDATE))),
                                                                              get_age_recommend(i_lang,
                                                                                                abs(CAST(get_next_take_date(i_lang,
                                                                                                                            i_prof,
                                                                                                                            i_patient,
                                                                                                                            v.id_vacc) AS DATE) -
                                                                                                    SYSDATE))),
                                                                       NULL,
                                                                       NULL,
                                                                       914,
                                                                       pk_alert_constant.g_color_red)) status,
                           l_desc_status desc_status,
                           get_last_date(i_lang, i_prof, i_patient, v.id_vacc) dt_take
                      FROM vacc_dose vd, TIME t, vacc v, vacc_group vg
                     WHERE vd.n_dose = count_vacc_take(i_lang, i_patient, v.id_vacc, NULL, i_prof)
                       AND vd.id_time = t.id_time
                       AND v.id_vacc = vd.id_vacc
                       AND vg.id_vacc_type_group = l_vacc_type_group
                       AND vg.id_vacc = v.id_vacc
                       AND vd.id_time = t.id_time
                     ORDER BY dt_take);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_CARE_DASH_VACC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Devolve o id do grupo de vacinas associado ao tipo que � passado na entrada
    *
    * @param      i_lang           language
    * @param      i_prof           professional
    * @param      i_flg_presc_type tipo de prescri��o:
    *    g_flg_presc_pnv        vacc_type_group.flg_presc_type%TYPE := 'P';
    *    g_flg_presc_tuberculin vacc_type_group.flg_presc_type%TYPE := 'T';
    *    g_flg_presc_other_vacc vacc_type_group.flg_presc_type%TYPE := 'O';
    
    * @param OUT  o_type_group      id_vacc_type_group do tipo de vacinas que � passado
    *
    * @author                   Pedro Teixeira
    * @since                    27/04/2009
    ********************************************************************************************/
    FUNCTION get_vacc_type_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_presc_type IN vacc_type_group.flg_presc_type%TYPE,
        o_type_group     OUT vacc_type_group.id_vacc_type_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_vacc_type_group IS
            SELECT nvl((SELECT MAX(vtg.id_vacc_type_group)
                         FROM vacc_type_group vtg
                        WHERE vtg.flg_presc_type = i_flg_presc_type
                          AND EXISTS (SELECT *
                                 FROM vacc_type_group_soft_inst vtgsi
                                WHERE vtgsi.id_vacc_type_group = vtg.id_vacc_type_group
                                  AND vtgsi.id_institution = i_prof.institution
                                  AND vtgsi.id_software = i_prof.software)),
                       (SELECT MAX(vtg.id_vacc_type_group)
                          FROM vacc_type_group vtg
                         WHERE vtg.flg_presc_type = i_flg_presc_type
                           AND EXISTS (SELECT *
                                  FROM vacc_type_group_soft_inst vtgsi
                                 WHERE vtgsi.id_vacc_type_group = vtg.id_vacc_type_group
                                   AND vtgsi.id_institution IN (i_prof.institution, 0)
                                   AND vtgsi.id_software IN (i_prof.software, 0))))
              FROM dual;
    
    BEGIN
    
        IF i_flg_presc_type IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        OPEN c_vacc_type_group;
        FETCH c_vacc_type_group
            INTO o_type_group;
        g_found := c_vacc_type_group%FOUND;
        CLOSE c_vacc_type_group;
        IF NOT g_found
           OR o_type_group IS NULL
        THEN
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
                                              'PK_VACC',
                                              'GET_VACC_TYPE_GROUP',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Devolve 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_value           Id da prescricao da vacina
    
    * @param OUT  o_advers_react    cursor com a info de reaccoes adversas
    *
    * @author                   Pedro Teixeira
    * @since                    27/04/2009
    ********************************************************************************************/
    FUNCTION get_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2,
        o_id_value  OUT NUMBER,
        o_notes     OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_var(v_id_reg vacc_advers_react.id_reg%TYPE) IS
            SELECT var.id_vacc_adver_reac, var.notes_advers_react notes
              FROM vacc_advers_react var
             WHERE var.id_reg = v_id_reg
               AND var.flg_status = pk_alert_constant.g_active;
    
        r_var              c_var%ROWTYPE;
        l_drug_presc_plan  drug_presc_plan.id_vacc_adv_reaction%TYPE;
        l_flg_advers_react drug_presc_plan.flg_advers_react%TYPE := pk_alert_constant.g_no;
    
    BEGIN
        IF i_type_vacc = 'V'
        THEN
            SELECT dpp.id_drug_presc_plan
              INTO l_drug_presc_plan
              FROM drug_presc_plan dpp
              JOIN drug_presc_det dpd
                ON dpd.id_drug_presc_det = dpp.id_drug_presc_det
              JOIN drug_prescription dp
                ON dp.id_drug_prescription = dpd.id_drug_prescription
             WHERE dp.id_drug_prescription = i_value;
            OPEN c_var(l_drug_presc_plan);
            FETCH c_var
                INTO r_var;
            IF c_var%FOUND
            THEN
                o_id_value := r_var.id_vacc_adver_reac;
                o_notes    := r_var.notes;
            ELSE
                SELECT dpp.id_vacc_adv_reaction VALUE, dpp.notes_advers_react
                  INTO o_id_value, o_notes
                  FROM drug_presc_plan dpp
                 WHERE dpp.id_drug_presc_plan = l_drug_presc_plan;
            END IF;
        
        ELSE
            OPEN c_var(i_value);
            FETCH c_var
                INTO r_var;
            IF c_var%FOUND
            THEN
                o_id_value := r_var.id_vacc_adver_reac;
                o_notes    := r_var.notes;
            ELSE
                SELECT pvad.id_vacc_adv_reaction, pvad.notes_advers_react
                  INTO o_id_value, o_notes
                  FROM pat_vacc_adm_det pvad
                 WHERE pvad.id_pat_vacc_adm = i_value;
            END IF;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_ADVERS_REACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_advers_react;

    /********************************************************************************************
    * This function return a value of adverse reaction
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_value           Vacc prescription identifier
    * @param IN   i_type_vacc       Vacc Type of the vaccine (V- Administer, R - Report)
    *
    * @return Adverse reaction value
    *
    * @author                   Jorge Silva
    * @since                    12/05/2014
    ********************************************************************************************/
    FUNCTION get_advers_react_value
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_var(v_id_reg vacc_advers_react.id_reg%TYPE) IS
            SELECT var.notes_advers_react notes
              FROM vacc_advers_react var
             WHERE var.id_reg = v_id_reg
               AND var.flg_status = pk_alert_constant.g_active;
    
        r_var              c_var%ROWTYPE;
        l_drug_presc_plan  drug_presc_plan.id_vacc_adv_reaction%TYPE;
        l_flg_advers_react drug_presc_plan.flg_advers_react%TYPE := pk_alert_constant.g_no;
        l_notes            VARCHAR2(4000);
    BEGIN
        IF i_type_vacc = 'V'
        THEN
            SELECT dpp.id_drug_presc_plan
              INTO l_drug_presc_plan
              FROM drug_presc_plan dpp
              JOIN drug_presc_det dpd
                ON dpd.id_drug_presc_det = dpp.id_drug_presc_det
              JOIN drug_prescription dp
                ON dp.id_drug_prescription = dpd.id_drug_prescription
             WHERE dp.id_drug_prescription = i_value;
        
            OPEN c_var(l_drug_presc_plan);
            FETCH c_var
                INTO r_var;
            IF c_var%FOUND
            THEN
                l_notes := r_var.notes;
            
            ELSE
                SELECT dpp.notes_advers_react
                  INTO l_notes
                  FROM drug_presc_plan dpp
                 WHERE dpp.id_drug_presc_plan = l_drug_presc_plan;
            END IF;
        
        ELSE
            OPEN c_var(i_value);
            FETCH c_var
                INTO r_var;
            IF c_var%FOUND
            THEN
                l_notes := r_var.notes;
            ELSE
                SELECT pvad.notes_advers_react
                  INTO l_notes
                  FROM pat_vacc_adm_det pvad
                 WHERE pvad.id_pat_vacc_adm = i_value;
            END IF;
        
        END IF;
    
        RETURN l_notes;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_advers_react_value;

    FUNCTION set_advers_react_internal
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reg    IN drug_prescription.id_drug_prescription%TYPE,
        i_value     IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes     IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
        l_id_reg drug_presc_plan.id_drug_presc_plan%TYPE;
    BEGIN
        g_error := 'SET advers_react';
    
        IF i_type_vacc = 'V'
        THEN
            SELECT dpp.id_drug_presc_plan
              INTO l_id_reg
              FROM drug_presc_plan dpp, drug_presc_det dpd
             WHERE dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug_prescription = i_id_reg;
        ELSE
            l_id_reg := i_id_reg;
        END IF;
    
        UPDATE vacc_advers_react var
           SET var.flg_status = pk_alert_constant.g_inactive
         WHERE var.id_reg = l_id_reg
           AND var.flg_type = i_type_vacc;
    
        ts_vacc_advers_react.ins(id_reg_in             => l_id_reg,
                                 flg_type_in           => i_type_vacc,
                                 flg_status_in         => pk_alert_constant.g_active,
                                 notes_advers_react_in => i_notes,
                                 id_prof_write_in      => i_prof.id,
                                 dt_prof_write_in      => current_timestamp,
                                 id_value_in           => '-1',
                                 id_vacc_adver_reac_in => i_value,
                                 rows_out              => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'vacc_advers_react',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_ADVERS_REACT_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_advers_react_internal;

    FUNCTION set_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reg    IN drug_prescription.id_drug_prescription%TYPE,
        i_value     IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes     IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT set_advers_react_internal(i_lang      => i_lang,
                                         i_prof      => i_prof,
                                         i_id_reg    => i_id_reg,
                                         i_value     => i_value,
                                         i_notes     => i_notes,
                                         i_type_vacc => i_type_vacc,
                                         o_error     => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
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
                                              'PK_VACC',
                                              'SET_ADVERS_REACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_advers_react;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_vacc_manufacturer FOR
            SELECT vm.id_vacc_manufacturer data,
                   pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) label
              FROM vacc_manufacturer vm
              JOIN vacc_manufacturer_inst_soft vmis
                ON vmis.id_vacc_manufacturer = vm.id_vacc_manufacturer
             WHERE vmis.id_institution IN (0, i_prof.institution)
               AND vm.flg_available = pk_alert_constant.g_yes
               AND vmis.id_software IN (0, i_prof.software)
             ORDER BY label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_MANUFACTURER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_manufacturer);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Return all manufacturer data
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_manufacturer    all manufacturer 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market market.id_market%TYPE;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF (l_market <> pk_alert_constant.g_id_market_usa)
        THEN
            IF NOT get_vacc_manufacturer(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         o_vacc_manufacturer => o_vacc_manufacturer,
                                         o_error             => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
        ELSE
            OPEN o_vacc_manufacturer FOR
                SELECT vm.id_vacc_manufacturer data,
                       pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) label,
                       0 rank
                  FROM mi_med mm
                  JOIN vacc_manufacturer_cvx vmc
                    ON vmc.cvx_code = mm.code_cvx
                  JOIN vacc_manufacturer vm
                    ON vm.id_vacc_manufacturer = vmc.id_vacc_manufacturer
                   AND vm.flg_available = pk_alert_constant.g_yes
                 WHERE mm.id_drug = i_id_drug
                   AND mm.vers = l_version
                UNION ALL
                SELECT g_other_value data, pk_message.get_message(i_lang, g_other_label) label, 1 rank
                  FROM dual
                 ORDER BY rank, label ASC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_MANUFACTURER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_manufacturer);
            RETURN FALSE;
    END get_vacc_manufacturer;

    /**
    * Gets list of reported options
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursor with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Rita Lopes
    * @version 1.0 
    * @since   19-05-2011
    */
    FUNCTION get_reported
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'GET_REPORTED';
        l_market_rep NUMBER;
        l_market     market.id_market%TYPE;
    
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT COUNT(*)
          INTO l_market_rep
          FROM vacc_report vr, vacc_report_inst_soft_markt vrism
         WHERE vr.id_vacc_report = vrism.id_vacc_report
           AND vrism.flg_available = pk_alert_constant.g_yes
           AND vrism.id_institution IN (0, i_prof.institution)
           AND vrism.id_software IN (0, i_prof.software)
           AND vrism.id_market IN (l_market);
    
        IF (l_market_rep > 0)
        THEN
            -- execute cursor and return it  
            g_error := 'GET CURSOR o_domains';
            OPEN o_domains FOR
                SELECT vr.id_vacc_report data,
                       pk_translation.get_translation(i_lang, vr.code_vacc_report) label,
                       vr.rank
                  FROM vacc_report vr, vacc_report_inst_soft_markt vrism
                 WHERE vr.id_vacc_report = vrism.id_vacc_report
                   AND vrism.flg_available = pk_alert_constant.g_yes
                   AND vrism.id_institution IN (0, i_prof.institution)
                   AND vrism.id_software IN (0, i_prof.software)
                   AND vrism.id_market IN (l_market)
                 ORDER BY rank, label;
        
        ELSE
            -- execute cursor and return it  
            g_error := 'GET CURSOR o_domains';
            OPEN o_domains FOR
                SELECT vr.id_vacc_report data,
                       pk_translation.get_translation(i_lang, vr.code_vacc_report) label,
                       vr.rank
                  FROM vacc_report vr, vacc_report_inst_soft_markt vrism
                 WHERE vr.id_vacc_report = vrism.id_vacc_report
                   AND vrism.flg_available = pk_alert_constant.g_yes
                   AND vrism.id_institution IN (0, i_prof.institution)
                   AND vrism.id_software IN (0, i_prof.software)
                   AND vrism.id_market IN (pk_alert_constant.g_id_market_all)
                 ORDER BY rank, label;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_domains);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_reported;

    FUNCTION get_vacc_adm_det_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_adm_det FOR
        --vacinas fora do PNV e relatos
            SELECT pva.id_pat_vacc_adm id_admin_vacc,
                   mem.short_med_descr vaccine_name,
                   pvad.dt_take dt_admin,
                   pva.dosage_admin vacc_dosage,
                   pva.dosage_unit_measure vacc_unit,
                   pvad.lot_number vacc_lot,
                   pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) desc_manufacturer,
                   vm.code_mvx code_mvx,
                   mem.code_cvx code_cvx
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, me_med mem, vacc_manufacturer vm
             WHERE pvad.id_pat_vacc_adm_det = i_id_adm
               AND pva.id_episode_destination IS NULL
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND vm.id_vacc_manufacturer(+) = pva.id_vacc_manufacturer
               AND pvad.emb_id = mem.emb_id
               AND mem.vers = l_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_ADVERS_REACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_vacc_adm_det_intf;

    FUNCTION get_vacc_adm_rep_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_adm_det FOR
        --vacinas fora do PNV e relatos
            SELECT DISTINCT pva.id_pat_vacc_adm id_admin_vacc,
                            pvad.desc_vaccine vaccine_name,
                            pvad.dt_take dt_admin,
                            pva.dosage_admin vacc_dosage,
                            pva.dosage_unit_measure vacc_unit,
                            pvad.lot_number vacc_lot,
                            pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) desc_manufacturer,
                            vm.code_mvx code_mvx,
                            mem.code_cvx code_cvx
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, mi_med mem, vacc_manufacturer vm
             WHERE pvad.id_pat_vacc_adm_det = i_id_adm
               AND pva.id_episode_destination IS NULL
               AND vm.id_vacc_manufacturer(+) = pva.id_vacc_manufacturer
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pvad.emb_id = mem.id_drug(+)
               AND mem.vers(+) = l_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ADM_REP_INTF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_adm_det);
            RETURN FALSE;
    END get_vacc_adm_rep_intf;

    FUNCTION get_vacc_drug_adm_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_adm_det FOR
        --vacinas fora do PNV e relatos
            SELECT dpd.id_drug_presc_det id_admin_vacc,
                   mim.med_descr vaccine_name,
                   format_tuberculin_test_date(i_lang, i_prof, dpp.dt_take_tstz, dpp.flg_type_date) dt_admin,
                   dpp.dosage vacc_dosage,
                   dpp.dosage_unit_measure vacc_unit,
                   dpp.lot_number vacc_lot,
                   pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) desc_manufacturer,
                   vm.code_mvx code_mvx,
                   mim.code_cvx code_cvx
              FROM drug_prescription dp, drug_presc_det dpd, drug_presc_plan dpp, mi_med mim, vacc_manufacturer vm
             WHERE dpd.id_drug_presc_det = i_id_adm
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND vm.id_vacc_manufacturer(+) = dpd.id_vacc_manufacturer
               AND dpd.id_drug = mim.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND mim.vers = l_version;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_DRUG_ADM_INTF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_adm_det);
            RETURN FALSE;
    END get_vacc_drug_adm_intf;

    FUNCTION get_vacc_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_unit_measure OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_vacc_unit_measure FOR
            SELECT u.id_unit_measure id,
                   pk_translation.get_translation(i_lang, u.code_unit_measure) label,
                   decode(u.id_unit_measure, 10012, g_year, 'N') flg_default
              FROM unit_measure u, unit_measure_subtype ums, unit_measure_group umg
             WHERE ums.id_unit_measure_type = 1015 -- Tipo de prescricao
               AND ums.id_unit_measure_subtype = 106 -- Sub tipo vacinas
               AND ums.id_unit_measure_type = umg.id_unit_measure_type
               AND ums.id_unit_measure_subtype = umg.id_unit_measure_subtype
               AND umg.id_unit_measure = u.id_unit_measure
             ORDER BY umg.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_vacc_unit_measure);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_VACC',
                                              i_function => 'GET_VACC_UNIT_MEASURE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vacc_unit_measure;

    /**
     * This function returns the scope of episodes
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     * @param    IN  i_episode         Episode ID
     * @param    IN  i_flg_filter      Flag filter
     *
     * @return   BOOLEAN
     *
     * @version  
     * @since    
     * @created  
    */

    FUNCTION get_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN table_number IS
    
        l_epis     table_number := table_number();
        l_epis_all table_number := table_number();
    
    BEGIN
    
        -- get all episodes that belongs to the patient    
        SELECT a.id_episode
          BULK COLLECT
          INTO l_epis_all
          FROM episode a
         WHERE a.id_patient = i_patient
         ORDER BY a.dt_creation DESC;
    
        CASE
            WHEN i_flg_filter = g_rep_type_episode THEN
                l_epis.extend(1);
                l_epis(l_epis.count) := nvl(i_episode, 1);
            
            WHEN i_flg_filter = g_rep_type_visit THEN
                -- get all episodes that belongs to current visit
                SELECT a.id_episode
                  BULK COLLECT
                  INTO l_epis
                  FROM episode a
                 WHERE a.id_visit = (SELECT e.id_visit
                                       FROM episode e
                                      WHERE e.id_episode = i_episode)
                 ORDER BY a.dt_creation DESC;
            
            WHEN i_flg_filter = g_rep_type_patient THEN
                l_epis := l_epis_all;
            
            ELSE
                l_epis := l_epis_all;
        END CASE;
    
        RETURN l_epis;
    
    END get_scope;

    FUNCTION get_vacc_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_filter  IN VARCHAR2,
        o_vacc        OUT pk_types.cursor_type,
        o_hist        OUT pk_types.cursor_type,
        o_discontinue OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sub_title     CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                         i_code_mess => 'VACC_T059');
        l_sub_title_rep CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                         i_code_mess => 'REP_VACC_008');
    
        l_epis table_number := table_number();
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    BEGIN
    
        -- get scope of episodes
        l_epis := get_scope(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_patient    => i_patient,
                            i_episode    => i_episode,
                            i_flg_filter => i_flg_filter);
    
        OPEN o_vacc FOR
            SELECT l_sub_title sub_title,
                   v.id_vacc,
                   nvl(pva.id_parent, pva.id_pat_vacc_adm) id_unique,
                   pva.flg_status,
                   nvl(v.desc_vacc_ext, mem.dci_descr) par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                   count_vacc_take(i_lang, i_patient, pva.id_vacc, pvad.dt_reg, i_prof) time_var,
                   decode(pvad.flg_type_date,
                          g_year,
                          pk_vacc.get_year_from_timestamp(pvad.dt_take),
                          g_month,
                          pk_date_utils.get_month_year(i_lang, i_prof, pvad.dt_take),
                          g_day,
                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                pvad.dt_take,
                                                                i_prof.institution,
                                                                i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software)) admin_date,
                   pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof) expire_date,
                   pvad.lot_number,
                   get_advers_react_value(i_lang, i_prof, pva.id_pat_vacc_adm, g_orig_r) notes_advers_react,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_prof_writes) nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(pva.flg_status,
                                                      pk_alert_constant.g_cancelled,
                                                      pvad.dt_cancel,
                                                      pva.create_time),
                                               i_prof.institution,
                                               i_prof.software) documented_date,
                   '' desc_other,
                   nvl(pva.code_mvx, get_manufacturer_description(i_lang, pva.id_vacc_manufacturer)) manufacturer,
                   pva.dosage_admin dosage,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, pva.dosage_unit_measure) dosage_unt_measure,
                   pk_alert_constant.g_no nvp,
                   get_vacc_route_description(i_lang, i_prof, pvad.emb_id, pvad.vacc_route_data) admroute,
                   nvl(pvad.application_spot,
                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot, pvad.application_spot_code, i_lang)) admsite,
                   nvl(pvad.origin_desc, get_origin_description(i_lang, pvad.id_vacc_origin)) origin,
                   nvl(pvad.doc_vis_desc, get_doc_description(i_lang, i_prof, pvad.id_vacc_doc_vis)) doctype,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate,
                   get_vacc_cat_description(i_lang, pvad.id_vacc_funding_cat) doccat,
                   nvl(pvad.funding_source_desc, get_vacc_source_description(i_lang, pvad.id_vacc_funding_source)) docsource,
                   nvl(pvad.report_orig, get_vacc_report_description(i_lang, pvad.id_information_source)) information,
                   '' orderby,
                   nvl(pvad.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_administred)) admby,
                   decode(pvad.dt_next_take,
                          '',
                          pk_message.get_message(i_lang, g_vacc_no_app),
                          pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_next_take, i_prof)) nextdose,
                   pk_message.get_message(i_lang, g_rep_title_details) record_type,
                   get_vacc_description(i_lang, i_prof, pvad.emb_id, pva.id_vacc) vacc_desc,
                   decode(pvad.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_yes,
                          decode(pva.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)) flg_edited,
                   decode(pvad.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, g_updated_details),
                          decode(pva.id_parent,
                                 NULL,
                                 pk_message.get_message(i_lang, g_documented_details),
                                 pk_message.get_message(i_lang, g_updated_details))) type_desc,
                   '' cancel_reason,
                   '' cancel_notes,
                   pvad.notes admnotes,
                   decode(pva.flg_status, pk_alert_constant.g_cancelled, pvad.dt_cancel, pva.create_time) dt_order_by
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, me_med mem, vacc v, vacc_group vg, vacc_type_group vtg
             WHERE pva.id_patient = i_patient
               AND pva.id_episode IN (SELECT *
                                        FROM TABLE(l_epis))
               AND pva.id_vacc = v.id_vacc
               AND pvad.emb_id = mem.emb_id(+)
               AND vg.id_vacc = v.id_vacc
               AND vtg.flg_pnv = pk_alert_constant.g_no
               AND vg.id_vacc_type_group = vtg.id_vacc_type_group
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.id_episode_destination IS NULL
            UNION ALL
            SELECT l_sub_title_rep sub_title,
                   v.id_vacc,
                   nvl(dp.id_parent, dp.id_drug_prescription) id_unique,
                   dpp.flg_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                   count_vacc_take(i_lang, i_patient, vme.id_vacc, dpp.dt_take_tstz, i_prof) time_var,
                   decode(dpp.flg_type_date,
                          g_year,
                          pk_vacc.get_year_from_timestamp(dpp.dt_take_tstz),
                          g_month,
                          pk_date_utils.get_month_year(i_lang, i_prof, dpp.dt_take_tstz),
                          g_day,
                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                dpp.dt_take_tstz,
                                                                i_prof.institution,
                                                                i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, dpp.dt_take_tstz, i_prof.institution, i_prof.software)) admin_date,
                   pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expire_date,
                   dpp.lot_number lot_number,
                   get_advers_react_value(i_lang, i_prof, dp.id_drug_prescription, g_orig_v) notes_advers_react,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_prof_writes) nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(dp.flg_status,
                                                      pk_alert_constant.g_cancelled,
                                                      dpp.dt_cancel_tstz,
                                                      dp.create_time),
                                               i_prof.institution,
                                               i_prof.software) documented_date,
                   '' desc_other,
                   nvl(dpt.code_mvx, get_manufacturer_description(i_lang, dpt.id_vacc_manufacturer)) manufacturer,
                   dpp.dosage dosage,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, dpp.dosage_unit_measure) dosage_unt_measure,
                   pk_alert_constant.g_yes nvp,
                   get_vacc_route_description(i_lang, i_prof, dpt.id_drug, dpp.vacc_route_data) admroute,
                   nvl(dpp.application_spot,
                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot, dpp.application_spot_code, i_lang)) admsite,
                   nvl(dpp.origin_desc, get_origin_description(i_lang, dpp.id_vacc_origin)) origin,
                   nvl(dpp.doc_vis_desc, get_doc_description(i_lang, i_prof, dpp.id_vacc_doc_vis)) doctype,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate,
                   get_vacc_cat_description(i_lang, dpp.id_vacc_funding_cat) doccat,
                   nvl(dpp.funding_source_desc, get_vacc_source_description(i_lang, dpp.id_vacc_funding_source)) docsource,
                   '' information,
                   nvl(dpp.ordered_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_ordered)) orderby,
                   nvl(dpp.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_administred)) admby,
                   decode(dpp.dt_next_take,
                          '',
                          pk_message.get_message(i_lang, g_vacc_no_app),
                          pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_next_take, i_prof)) nextdose,
                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                   get_vacc_description(i_lang, i_prof, dpt.id_drug, v.id_vacc) vacc_desc,
                   decode(dp.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_yes,
                          decode(dp.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)) flg_edited,
                   decode(dp.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, g_updated_details),
                          decode(dp.id_parent,
                                 NULL,
                                 pk_message.get_message(i_lang, g_documented_details),
                                 pk_message.get_message(i_lang, g_updated_details))) type_desc,
                   '' cancel_reason,
                   '' cancel_notes,
                   dpp.notes admnotes,
                   decode(dp.flg_status, pk_alert_constant.g_cancelled, dpp.dt_cancel_tstz, dp.create_time) dt_order_by
              FROM drug_prescription dp, drug_presc_det dpt, drug_presc_plan dpp, vacc_med_ext vme, vacc v
             WHERE dp.id_patient = i_patient
               AND dp.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
               AND dp.id_drug_prescription = dpt.id_drug_prescription
               AND dpp.id_vacc_med_ext = vme.id_vacc_med_ext
               AND dpt.id_drug_presc_det = dpp.id_drug_presc_det
               AND v.id_vacc = vme.id_vacc
            UNION ALL
            -- relatos
            SELECT l_sub_title_rep sub_title,
                   v.id_vacc,
                   nvl(pva.id_parent, pva.id_pat_vacc_adm) id_unique,
                   pva.flg_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                   count_vacc_take(i_lang, i_patient, pva.id_vacc, nvl(pvad.dt_take, pvad.dt_reg), i_prof) time_var,
                   decode(pvad.flg_type_date,
                          g_year,
                          pk_vacc.get_year_from_timestamp(pvad.dt_take),
                          g_month,
                          pk_date_utils.get_month_year(i_lang, i_prof, pvad.dt_take),
                          g_day,
                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                pvad.dt_take,
                                                                i_prof.institution,
                                                                i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software)) admin_date,
                   pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof) expire_date,
                   pvad.lot_number,
                   get_advers_react_value(i_lang, i_prof, pva.id_pat_vacc_adm, g_vacc_dose_report) notes_advers_react,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_prof_writes) nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(pva.flg_status,
                                                      pk_alert_constant.g_cancelled,
                                                      pvad.dt_cancel,
                                                      pva.create_time),
                                               i_prof.institution,
                                               i_prof.software) documented_date,
                   decode(pva.flg_orig,
                          'R',
                          pk_message.get_message(i_lang, 'VACC_T062'),
                          'I',
                          '(' || pvad.report_orig || ')',
                          '') ||
                   decode(pva.prof_presc, NULL, '', '(' || pk_message.get_message(i_lang, 'VACC_T071') || ')') desc_other,
                   nvl(pvad.code_mvx, get_manufacturer_description(i_lang, pvad.id_vacc_manufacturer)) manufacturer,
                   pva.dosage_admin dosage,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, pva.dosage_unit_measure) dosage_unt_measure,
                   pk_alert_constant.g_yes nvp,
                   get_vacc_route_description(i_lang, i_prof, pvad.emb_id, pvad.vacc_route_data) admroute,
                   nvl(pvad.application_spot,
                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot, pvad.application_spot_code, i_lang)) admsite,
                   nvl(pvad.origin_desc, get_origin_description(i_lang, pvad.id_vacc_origin)) origin,
                   nvl(pvad.doc_vis_desc, get_doc_description(i_lang, i_prof, pvad.id_vacc_doc_vis)) doctype,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate,
                   get_vacc_cat_description(i_lang, pvad.id_vacc_funding_cat) doccat,
                   nvl(pvad.funding_source_desc, get_vacc_source_description(i_lang, pvad.id_vacc_funding_source)) docsource,
                   nvl(pvad.report_orig, get_vacc_report_description(i_lang, pvad.id_information_source)) information,
                   '' orderby,
                   nvl(pvad.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_administred)) admby,
                   decode(pvad.dt_next_take,
                          '',
                          pk_message.get_message(i_lang, g_vacc_no_app),
                          pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_next_take, i_prof)) nextdose,
                   pk_message.get_message(i_lang, g_rep_title_details) record_type,
                   get_vacc_description(i_lang, i_prof, pvad.emb_id, pva.id_vacc) vacc_desc,
                   decode(pvad.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_yes,
                          decode(pva.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)) flg_edited,
                   decode(pvad.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, g_updated_details),
                          decode(pva.id_parent,
                                 NULL,
                                 pk_message.get_message(i_lang, g_documented_details),
                                 pk_message.get_message(i_lang, g_updated_details))) type_desc,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   pvad.notes_cancel cancel_notes,
                   pvad.notes admnotes,
                   decode(pva.flg_status, pk_alert_constant.g_cancelled, pvad.dt_cancel, pva.create_time) dt_order_by
              FROM pat_vacc_adm pva
              JOIN pat_vacc_adm_det pvad
                ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
              JOIN vacc v
                ON v.id_vacc = pva.id_vacc
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = pvad.id_cancel_reason
             WHERE pva.id_patient = i_patient
               AND pva.id_episode IN (SELECT *
                                        FROM TABLE(l_epis))
               AND pva.flg_orig = 'R'
               AND pva.id_episode_destination IS NULL
               AND pva.flg_status NOT IN (g_vacc_status_edit)
            UNION ALL
            --Prescription
            SELECT l_sub_title_rep sub_title,
                   v.id_vacc,
                   nvl(dp.id_parent, dp.id_drug_prescription) id_unique,
                   decode(dpp.flg_status, 'U', pk_alert_constant.g_cancelled, dpp.flg_status) flg_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                   count_vacc_take(i_lang, i_patient, vd.id_vacc, dpp.dt_take_tstz, i_prof) time_var,
                   decode(dpp.flg_type_date,
                          g_year,
                          pk_vacc.get_year_from_timestamp(dpp.dt_take_tstz),
                          g_month,
                          pk_date_utils.get_month_year(i_lang, i_prof, dpp.dt_take_tstz),
                          g_day,
                          pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                dpp.dt_take_tstz,
                                                                i_prof.institution,
                                                                i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, dpp.dt_take_tstz, i_prof.institution, i_prof.software)) admin_date,
                   pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expire_date,
                   dpp.lot_number lot_number,
                   get_advers_react_value(i_lang, i_prof, dp.id_drug_prescription, g_orig_v) notes_advers_react,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_prof_writes) nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(dpp.flg_status, 'U', dpp.dt_cancel_tstz, dp.create_time),
                                               i_prof.institution,
                                               i_prof.software) documented_date,
                   '' desc_other,
                   nvl(dpt.code_mvx, get_manufacturer_description(i_lang, dpt.id_vacc_manufacturer)) manufacturer,
                   dpp.dosage dosage,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, dpp.dosage_unit_measure) dosage_unt_measure,
                   pk_alert_constant.g_yes nvp,
                   get_vacc_route_description(i_lang, i_prof, dpt.id_drug, dpp.vacc_route_data) admroute,
                   nvl(dpp.application_spot,
                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot, dpp.application_spot_code, i_lang)) admsite,
                   nvl(dpp.origin_desc, get_origin_description(i_lang, dpp.id_vacc_origin)) origin,
                   nvl(dpp.doc_vis_desc, get_doc_description(i_lang, i_prof, dpp.id_vacc_doc_vis)) doctype,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate,
                   get_vacc_cat_description(i_lang, dpp.id_vacc_funding_cat) doccat,
                   nvl(dpp.funding_source_desc, get_vacc_source_description(i_lang, dpp.id_vacc_funding_source)) docsource,
                   '' information,
                   nvl(dpp.ordered_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_ordered)) orderby,
                   nvl(dpp.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_administred)) admby,
                   decode(dpp.dt_next_take,
                          '',
                          pk_message.get_message(i_lang, g_vacc_no_app),
                          pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_next_take, i_prof)) nextdose,
                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                   get_vacc_description(i_lang, i_prof, dpt.id_drug, v.id_vacc) vacc_desc,
                   decode(dp.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_yes,
                          decode(dp.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)) flg_edited,
                   decode(dp.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, g_updated_details),
                          decode(dp.id_parent,
                                 NULL,
                                 pk_message.get_message(i_lang, g_documented_details),
                                 pk_message.get_message(i_lang, g_updated_details))) type_desc,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   dpp.cancel_reason_descr cancel_notes,
                   dpp.notes admnotes,
                   decode(dp.flg_status, pk_alert_constant.g_cancelled, dpp.dt_cancel_tstz, dp.create_time) dt_order_by
              FROM drug_prescription dp
              JOIN drug_presc_det dpt
                ON dp.id_drug_prescription = dpt.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpt.id_drug_presc_det
               AND dpp.flg_status NOT IN (g_vacc_status_edit, pk_alert_constant.g_cancelled)
              JOIN mi_med mim
                ON dpt.id_drug = mim.id_drug
               AND mim.flg_available = pk_alert_constant.g_yes
               AND mim.vers = l_version
              JOIN vacc_dci vd
                ON vd.id_dci = mim.dci_id
              JOIN vacc v
                ON v.id_vacc = vd.id_vacc
              JOIN vacc_group vg
                ON vg.id_vacc = v.id_vacc
              JOIN vacc_type_group vtg
                ON vtg.id_vacc_type_group = vg.id_vacc_type_group
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = dpp.id_cancel_reason
             WHERE dp.id_patient = i_patient
               AND vtg.flg_pnv = pk_alert_constant.g_yes
               AND dp.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
             ORDER BY sub_title, id_vacc, time_var ASC /*, dt_order_by ASC*/
            ;
    
        OPEN o_discontinue FOR
        
            SELECT pv.id_vacc,
                   pvh.notes,
                   pk_not_order_reason_db.get_not_order_reason_desc(i_lang, pvh.id_reason) reason,
                   pvh.flg_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) par_desc,
                   pk_translation.get_translation(i_lang, v.code_desc_vacc) par_desc_det,
                   decode(pvh.flg_status,
                          g_status_s,
                          pk_message.get_message(i_lang, g_vacc_title_discontinue),
                          pk_message.get_message(i_lang, g_vacc_title_resume)) title,
                   pk_alert_constant.g_yes nvp
              FROM pat_vacc pv
              JOIN pat_vacc_hist pvh
                ON pvh.id_patient = pv.id_patient
              JOIN vacc v
                ON v.id_vacc = pv.id_vacc
               AND pvh.id_vacc = pv.id_vacc
             WHERE pv.flg_status = g_status_s
               AND pv.id_patient = i_patient
               AND pv.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
             ORDER BY pvh.dt_status ASC;
    
        OPEN o_hist FOR
            SELECT *
              FROM (SELECT COUNT(1) over(PARTITION BY id_unique, id_vacc ORDER BY id_unique, id_vacc) recordnumber, t.*
                      FROM (SELECT v.id_vacc,
                                   nvl(dp.id_parent, dp.id_drug_prescription) id_unique,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               dpp.dt_take_tstz,
                                                               i_prof.institution,
                                                               i_prof.software) admin_date,
                                   pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expire_date,
                                   dpp.lot_number lot_number,
                                   get_adv_reactions_description(i_lang, dpp.id_vacc_adv_reaction) notes_advers_react,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_prof_writes) nick_name,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               dp.create_time,
                                                               i_prof.institution,
                                                               i_prof.software) documented_date,
                                   nvl(dpt.code_mvx, get_manufacturer_description(i_lang, dpt.id_vacc_manufacturer)) manufacturer,
                                   nvl(TRIM(pk_utils.to_str(dpp.dosage) || ' ' ||
                                            pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                         i_prof,
                                                                                         dpp.dosage_unit_measure)),
                                       '') admdose_desc,
                                   get_vacc_route_description(i_lang, i_prof, dpt.id_drug, dpp.vacc_route_data) admroute,
                                   nvl(dpp.application_spot,
                                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot,
                                                                        dpp.application_spot_code,
                                                                        i_lang)) admsite,
                                   nvl(dpp.origin_desc, get_origin_description(i_lang, dpp.id_vacc_origin)) origin,
                                   nvl(dpp.doc_vis_desc, get_doc_description(i_lang, i_prof, dpp.id_vacc_doc_vis)) doctype,
                                   pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate,
                                   get_vacc_cat_description(i_lang, dpp.id_vacc_funding_cat) doccat,
                                   nvl(dpp.funding_source_desc,
                                       get_vacc_source_description(i_lang, dpp.id_vacc_funding_source)) docsource,
                                   '' information,
                                   nvl(dpp.ordered_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_ordered)) orderby,
                                   nvl(dpp.administred_desc,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_administred)) admby,
                                   decode(dpp.dt_next_take,
                                          '',
                                          pk_message.get_message(i_lang, g_vacc_no_app),
                                          pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_next_take, i_prof)) nextdose,
                                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                                   get_vacc_description(i_lang, i_prof, dpt.id_drug, v.id_vacc) vacc_desc,
                                   decode(dp.id_parent,
                                          NULL,
                                          pk_message.get_message(i_lang, g_documented_details),
                                          pk_message.get_message(i_lang, g_updated_details)) type_desc,
                                   '' cancel_reason,
                                   '' cancel_notes,
                                   dpp.notes admnotes,
                                   dp.create_time dt_reg,
                                   decode(dp.id_parent,
                                          NULL,
                                          pk_message.get_message(i_lang, g_adm_title_details),
                                          pk_message.get_message(i_lang, g_adm_edit_title_details)) title
                              FROM drug_prescription dp
                              JOIN drug_presc_det dpt
                                ON dp.id_drug_prescription = dpt.id_drug_prescription
                              JOIN drug_presc_plan dpp
                                ON dpp.id_drug_presc_det = dpt.id_drug_presc_det
                               AND dpp.flg_status <> pk_alert_constant.g_cancelled
                              JOIN mi_med mim
                                ON dpt.id_drug = mim.id_drug
                               AND mim.flg_available = pk_alert_constant.g_yes
                               AND mim.vers = l_version
                              JOIN vacc_dci vd
                                ON vd.id_dci = mim.dci_id
                              JOIN vacc v
                                ON v.id_vacc = vd.id_vacc
                             WHERE dp.id_patient = i_patient
                               AND dp.id_episode IN (SELECT *
                                                       FROM TABLE(l_epis))
                            UNION
                            SELECT v.id_vacc,
                                   nvl(pva.id_parent, pva.id_pat_vacc_adm) id_unique,
                                   pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software) admin_date,
                                   pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof) expire_date,
                                   pvad.lot_number,
                                   get_adv_reactions_description(i_lang, pvad.id_vacc_adv_reaction) notes_advers_react,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_prof_writes) nick_name,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               pva.create_time,
                                                               i_prof.institution,
                                                               i_prof.software) documented_date,
                                   nvl(pvad.code_mvx, get_manufacturer_description(i_lang, pvad.id_vacc_manufacturer)) manufacturer,
                                   nvl(TRIM(pk_utils.to_str(pva.dosage_admin) || ' ' ||
                                            pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                         i_prof,
                                                                                         pva.dosage_unit_measure)),
                                       '') admdose_desc,
                                   get_vacc_route_description(i_lang, i_prof, pvad.emb_id, pvad.vacc_route_data) admroute,
                                   nvl(pvad.application_spot,
                                       pk_sysdomain.get_domain_no_avail(g_domain_application_spot,
                                                                        pvad.application_spot_code,
                                                                        i_lang)) admsite,
                                   nvl(pvad.origin_desc, get_origin_description(i_lang, pvad.id_vacc_origin)) origin,
                                   nvl(pvad.doc_vis_desc, get_doc_description(i_lang, i_prof, pvad.id_vacc_doc_vis)) doctype,
                                   pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate,
                                   get_vacc_cat_description(i_lang, pvad.id_vacc_funding_cat) doccat,
                                   nvl(pvad.funding_source_desc,
                                       get_vacc_source_description(i_lang, pvad.id_vacc_funding_source)) docsource,
                                   nvl(pvad.report_orig, get_vacc_report_description(i_lang, pvad.id_information_source)) information,
                                   '' orderby,
                                   nvl(pvad.administred_desc,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_administred)) admby,
                                   decode(pvad.dt_next_take,
                                          '',
                                          pk_message.get_message(i_lang, g_vacc_no_app),
                                          pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_next_take, i_prof)) nextdose,
                                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                                   get_vacc_description(i_lang, i_prof, pvad.emb_id, pva.id_vacc) vacc_desc,
                                   decode(pva.id_parent,
                                          NULL,
                                          pk_message.get_message(i_lang, g_documented_details),
                                          pk_message.get_message(i_lang, g_updated_details)) type_desc,
                                   '' cancel_reason,
                                   '' cancel_notes,
                                   pvad.notes admnotes,
                                   pva.create_time dt_reg,
                                   decode(pva.id_parent,
                                          NULL,
                                          pk_message.get_message(i_lang, g_rep_title_details),
                                          pk_message.get_message(i_lang, g_rep_edit_title_details)) title
                              FROM pat_vacc_adm pva
                              JOIN pat_vacc_adm_det pvad
                                ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
                               AND pvad.flg_status <> pk_alert_constant.g_cancelled
                              JOIN vacc v
                                ON v.id_vacc = pva.id_vacc
                             WHERE pva.id_patient = i_patient
                               AND pva.id_episode IN (SELECT *
                                                        FROM TABLE(l_epis))
                               AND pva.flg_orig = 'R'
                               AND pva.id_episode_destination IS NULL
                            --Cancel
                            UNION ALL
                            SELECT vd.id_vacc,
                                   nvl(dp.id_parent, dp.id_drug_prescription) id_unique,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               dpp.dt_take_tstz,
                                                               i_prof.institution,
                                                               i_prof.software) admin_date,
                                   '' expire_date,
                                   '' lot_number,
                                   '' notes_advers_react,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_prof_cancel) nick_name,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               dpp.dt_cancel_tstz,
                                                               i_prof.institution,
                                                               i_prof.software) documented_date,
                                   '' manufacturer,
                                   '' admdose_desc,
                                   '' admroute,
                                   '' admsite,
                                   '' origin,
                                   '' doctype,
                                   '' docdate,
                                   '' doccat,
                                   '' docsource,
                                   '' information,
                                   '' orderby,
                                   '' admby,
                                   '' nextdose,
                                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                                   get_vacc_description(i_lang, i_prof, dpt.id_drug, vd.id_vacc) vacc_desc,
                                   pk_message.get_message(i_lang, g_cancel_title_details) || ':' type_desc,
                                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                                   dpp.notes_cancel cancel_notes,
                                   '' admnotes,
                                   dpp.dt_cancel_tstz dt_reg,
                                   pk_message.get_message(i_lang, g_cancel_title_details) title
                              FROM drug_prescription dp
                              JOIN drug_presc_det dpt
                                ON dp.id_drug_prescription = dpt.id_drug_prescription
                              JOIN drug_presc_plan dpp
                                ON dpp.id_drug_presc_det = dpt.id_drug_presc_det
                              JOIN mi_med mim
                                ON dpt.id_drug = mim.id_drug
                               AND mim.flg_available = pk_alert_constant.g_yes
                               AND mim.vers = l_version
                              JOIN vacc_dci vd
                                ON vd.id_dci = mim.dci_id
                              JOIN cancel_reason cr
                                ON cr.id_cancel_reason = dpp.id_cancel_reason
                             WHERE dp.id_patient = i_patient
                               AND dp.flg_status = pk_alert_constant.g_cancelled
                               AND dp.id_episode IN (SELECT *
                                                       FROM TABLE(l_epis))
                            UNION
                            SELECT v.id_vacc,
                                   nvl(pva.id_parent, pva.id_pat_vacc_adm) id_unique,
                                   pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software) admin_date,
                                   '' expire_date,
                                   '' lot_number,
                                   '' notes_advers_react,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_prof_cancel) nick_name,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               pvad.dt_cancel,
                                                               i_prof.institution,
                                                               i_prof.software) documented_date,
                                   '' manufacturer,
                                   '' admdose_desc,
                                   '' admroute,
                                   '' admsite,
                                   '' origin,
                                   '' doctype,
                                   '' docdate,
                                   '' doccat,
                                   '' docsource,
                                   '' information,
                                   '' orderby,
                                   '' admby,
                                   '' nextdose,
                                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                                   get_vacc_description(i_lang, i_prof, pvad.emb_id, pva.id_vacc) vacc_desc,
                                   pk_message.get_message(i_lang, g_cancel_title_details) || ':' type_desc,
                                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                                   pvad.notes_cancel cancel_notes,
                                   pvad.notes admnotes,
                                   pvad.dt_cancel dt_reg,
                                   pk_message.get_message(i_lang, g_cancel_title_details) title
                              FROM pat_vacc_adm pva
                              JOIN pat_vacc_adm_det pvad
                                ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
                               AND pvad.flg_status = pk_alert_constant.g_cancelled
                              JOIN vacc v
                                ON v.id_vacc = pva.id_vacc
                              LEFT JOIN cancel_reason cr
                                ON cr.id_cancel_reason = pvad.id_cancel_reason
                             WHERE pva.id_patient = i_patient
                               AND pva.id_episode IN (SELECT *
                                                        FROM TABLE(l_epis))
                               AND pva.flg_orig = 'R'
                               AND pva.id_episode_destination IS NULL
                            --Adverse Reaction
                            UNION ALL
                            SELECT id_vacc,
                                   nvl(id_parent, id) id_unique,
                                   pk_date_utils.date_char_tsz(i_lang, dt_take, i_prof.institution, i_prof.software) admin_date,
                                   '' expire_date,
                                   '' lot_number,
                                   decode(id_vacc_adver_reac,
                                          g_other_value,
                                          notes_advers_react,
                                          get_adv_reactions_description(i_lang, id_vacc_adver_reac)) notes_advers_react,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_adv_react) nick_name,
                                   pk_date_utils.date_char_tsz(i_lang, dt_adv_react, i_prof.institution, i_prof.software) documented_date,
                                   '' manufacturer,
                                   '' admdose_desc,
                                   '' admroute,
                                   '' admsite,
                                   '' origin,
                                   '' doctype,
                                   '' docdate,
                                   '' doccat,
                                   '' docsource,
                                   '' information,
                                   '' orderby,
                                   '' admby,
                                   '' nextdose,
                                   pk_message.get_message(i_lang, g_vacc_adm) record_type,
                                   get_vacc_description(i_lang, i_prof, emb_id, id_vacc) vacc_desc,
                                   pk_message.get_message(i_lang, g_updated_details) type_desc,
                                   '' cancel_reason,
                                   '' cancel_notes,
                                   '' admnotes,
                                   dt_adv_react dt_reg,
                                   pk_message.get_message(i_lang, g_vacc_title_adv_react) title
                              FROM (SELECT var.id_reg          id,
                                           pva.id_parent       id_parent,
                                           pva.id_vacc         id_vacc,
                                           pva.dt_pat_vacc_adm dt_begin,
                                           var.dt_prof_write   dt_adv_react,
                                           var.id_prof_write   id_prof_adv_react,
                                           pvad.emb_id,
                                           pvad.dt_take,
                                           var.*
                                      FROM vacc_advers_react var
                                      JOIN pat_vacc_adm pva
                                        ON pva.id_pat_vacc_adm = var.id_reg
                                       AND pva.id_patient = i_patient
                                       AND pva.id_episode IN (SELECT *
                                                                FROM TABLE(l_epis))
                                      JOIN pat_vacc_adm_det pvad
                                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                                    UNION ALL
                                    SELECT dp.id_drug_prescription id,
                                           dp.id_parent            id_parent,
                                           vd.id_vacc              id_vacc,
                                           dp.dt_begin_tstz        dt_begin,
                                           var.dt_prof_write       dt_adv_react,
                                           var.id_prof_write       id_prof_adv_react,
                                           dpd.id_drug             emb_id,
                                           dpp.dt_take_tstz        dt_take,
                                           var.*
                                      FROM vacc_advers_react var
                                      JOIN drug_presc_plan dpp
                                        ON dpp.id_drug_presc_plan = var.id_reg
                                      JOIN drug_presc_det dpd
                                        ON dpd.id_drug_presc_det = dpp.id_drug_presc_det
                                      JOIN drug_prescription dp
                                        ON dp.id_drug_prescription = dpd.id_drug_prescription
                                      JOIN mi_med mim
                                        ON dpd.id_drug = mim.id_drug
                                       AND mim.flg_available = pk_alert_constant.g_yes
                                      JOIN vacc_dci vd
                                        ON vd.id_dci = mim.dci_id
                                       AND dp.id_patient = i_patient
                                       AND dp.id_episode IN (SELECT *
                                                               FROM TABLE(l_epis)))) t) t1
             WHERE t1.recordnumber > 1
             ORDER BY id_vacc, id_unique, dt_reg DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_VACC',
                                                     i_function => 'GET_VACC_REP',
                                                     o_error    => o_error);
        
            pk_types.open_my_cursor(o_hist);
            pk_types.open_my_cursor(o_discontinue);
            pk_types.open_my_cursor(o_vacc);
        
            RETURN FALSE;
    END get_vacc_rep;

    FUNCTION get_tuberculin_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2,
        o_vacc       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis    table_number := table_number();
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        -- get scope of episodes
        l_epis := get_scope(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_patient    => i_patient,
                            i_episode    => i_episode,
                            i_flg_filter => i_flg_filter);
    
        OPEN o_vacc FOR
            SELECT dpr.value || ' mm' VALUE,
                   dpr.evaluation,
                   dpr.notes_advers_react,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dpr.id_prof_resp) nick_name,
                   pk_date_utils.date_chr_short_read(i_lang, dpr.dt_drug_presc_result, i_prof) read_date,
                   pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expire_date,
                   pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) manufacturer,
                   dpp.lot_number lot_number,
                   dpt.id_vacc_manufacturer,
                   dpp.dosage dosage,
                   pk_translation.get_translation(i_lang, um.code_unit_measure_abrv) dosage_unt_measure,
                   nvl(mim.med_descr, '--') name_dosage,
                   pk_alert_constant.g_no nvp
              FROM vacc_type_group      vtg,
                   vacc_group           vg,
                   vacc                 v,
                   vacc_group_soft_inst vgsi,
                   drug_prescription    dp,
                   drug_presc_det       dpt,
                   drug_presc_result    dpr,
                   drug_presc_plan      dpp,
                   professional         p,
                   mi_med               mim,
                   unit_measure         um,
                   vacc_manufacturer    vm
             WHERE vtg.id_vacc_type_group = 3
               AND vtg.id_vacc_type_group = vg.id_vacc_type_group
               AND vg.id_vacc = v.id_vacc
               AND vgsi.id_vacc_group = vg.id_vacc_group
                  --Soft and Inst
               AND (vgsi.id_software = 0 OR vgsi.id_software = i_prof.software)
               AND (vgsi.id_institution = 0 OR vgsi.id_institution = i_prof.institution)
               AND dp.id_patient = i_patient
               AND dp.id_episode IN (SELECT *
                                       FROM TABLE(l_epis))
               AND dp.id_drug_prescription = dpt.id_drug_prescription
               AND dpt.id_drug_presc_det = dpp.id_drug_presc_det
               AND dpr.id_drug_presc_plan = dpp.id_drug_presc_plan
               AND p.id_professional = dpr.id_prof_resp
               AND dpt.id_drug = mim.id_drug
               AND mim.vers = l_version
               AND dpp.dosage_unit_measure = um.id_unit_measure(+)
               AND vm.id_vacc_manufacturer(+) = dpt.id_vacc_manufacturer;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_VACC',
                                                     i_function => 'GET_TUBERCULIN_REP',
                                                     o_error    => o_error);
    END get_tuberculin_rep;

    FUNCTION get_vacc_adm_det_ft
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_test_state VARCHAR2(1);
    
        l_tests_ids table_info := table_info();
    
        l_adm_det_info table_info := table_info();
    
        l_tests_ids_pos NUMBER(3) := 1;
    
        --procura todos os ids de vacinas fora do PNV ou relatos (gravados nas tabelas pat_vacc_adm*)
        --apenas para vacinas que tenham j� sido administradas
        CURSOR c_tests IS
            SELECT pva.id_pat_vacc_adm id, '' desc_info
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_pat_vacc_adm = i_test_id
               AND pva.id_patient = i_patient
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND (pvad.dt_take IS NOT NULL AND pva.flg_orig = 'V' OR pva.flg_orig IN ('R', 'I'))
               AND pva.id_episode_destination IS NULL;
    
    BEGIN
    
        IF NOT i_to_add
        THEN
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T012');
        
            FOR l_test_cur IN c_tests
            LOOP
                l_tests_ids.extend;
                l_tests_ids(l_tests_ids_pos) := info(l_test_cur.id, NULL, NULL);
                l_tests_ids_pos := l_tests_ids_pos + 1;
            END LOOP;
        
            l_adm_det_info := format_screen_info(i_lang, 'ADM_VACC', o_error);
        
            --Explica��o:
            -- A nested table 'l_tests_ids' tem os id dos v�rios registos nas tabelas pat_vacc_adm (relatos e vacinas fora do PNV)
            -- A nested table 'l_vacc_adm_ids' tem os id dos v�rios registos nas tabelas drug_prescription (vacinas do PNV)
            -- 1 � necess�rio fazer um union destes dois casos.
        
            -- A nested table 'l_adm_det_info' tem os uma lista com a informa��o que vai ser apresentada no ecr�, e com a sua ordena��o
            -- � necess�rio cruzar com esta nested table para saber quais os campos a apresentar!
        
            OPEN o_adm_det FOR
                SELECT det_name, det_value, desc_resp, flg_show, id_test
                  FROM (
                        --vacinas fora do PNV e relatos
                        SELECT rtrim(s.desc_message, ':') || ':' det_name, --garante que todas as labels terminam em :
                                get_oth_vacc_value_det(i_lang, i_prof, test_ids.id, s.code_message) det_value,
                                '' desc_resp,
                                --a label Origem do relato apenas � apresentada para os relatos...
                                decode(s.code_message,
                                       'VACC_T036', -- 'Origem do relato', apenas dispon�vel para relatos
                                       decode(pva.flg_reported,
                                              pk_alert_constant.g_yes,
                                              pk_alert_constant.g_yes,
                                              decode(pva.flg_orig, g_orig_r, pk_alert_constant.g_yes, pk_alert_constant.g_no)),
                                       'TUBERCULIN_TEST_T018', -- 'Respons�vel pela administra��o', nas importa��es do SINUS n�o h�
                                       decode(pva.flg_orig, g_orig_i, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                       pk_alert_constant.g_yes) flg_show,
                                test_ids.id id_test,
                                adm_info.id id_label
                          FROM sys_message s,
                                pat_vacc_adm pva,
                                TABLE(l_tests_ids) test_ids,
                                TABLE(l_adm_det_info) adm_info
                         WHERE s.code_message IN (SELECT adm_info.desc_info
                                                    FROM TABLE(l_adm_det_info) adm_info)
                           AND s.id_language = i_lang
                           AND pva.id_pat_vacc_adm = test_ids.id
                           AND s.code_message = adm_info.desc_info
                           AND pva.id_episode_destination IS NULL
                         ORDER BY id_test, id_label)
                UNION ALL
                SELECT '' det_name,
                       '' det_value,
                       decode(pva.flg_orig,
                              g_orig_i,
                              pk_date_utils.date_char_tsz(i_lang,
                                                          nvl(pvad.dt_reg, pvad.dt_take),
                                                          i_prof.institution,
                                                          i_prof.software),
                              pk_tools.get_prof_description(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            decode(pva.flg_orig, g_orig_r, pvad.dt_reg, pvad.dt_take),
                                                            pva.id_episode) || ' / ' ||
                              pk_date_utils.date_char_tsz(i_lang,
                                                          decode(pva.flg_orig, g_orig_r, pvad.dt_reg, pvad.dt_take),
                                                          i_prof.institution,
                                                          i_prof.software)) desc_resp,
                       pk_alert_constant.g_yes flg_show,
                       test_ids.id id_test
                  FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p, TABLE(l_tests_ids) test_ids
                 WHERE pva.id_pat_vacc_adm = test_ids.id
                   AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
                   AND p.id_professional = pvad.id_prof_writes
                   AND pva.id_episode_destination IS NULL;
        
        ELSE
            --title
            o_adm_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T019');
        
            --NOTA [OA]: A ordena��o dos campos neste cursor � importante porque define a forma como os mesmos s�o
            -- apresentados no ecr�. Os c�digos destes campos n�o podem ser alterados!
            g_error := 'OPEN CURSOR o_adm_det TO GET THE ADMINISTRATION DETAILS';
            pk_types.open_my_cursor(o_adm_det);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ADM_DET_FT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_adm_det);
            RETURN FALSE;
    END get_vacc_adm_det_ft;

    /************************************************************************************************************
        * This function returns the details for all takes for the specified vaccine.
        *
        * @param      i_lang               language
        * @param      i_prof               profisisonal
        * @param      i_patient            patient's identifier
        * @param      i_vacc_id            vaccine's id
        *
        * @param      o_main_title         screen's main title
        * @param      o_this_take_title    this take's title
        * @param      o_history_take_title takes history title
        * @param      o_detail_info        vaccine detail information
        * @param      o_vacc_name          vaccine name
        *
        * @param      o_can_title          title for canceled details
        * @param      o_can_det            cursor with the canceled details
        * @param      o_adm_title          title for administration details
        * @param      o_admdet             cursor with the administration details
        * @param      o_presc_title        title for prescription details
        * @param      o_presc_det          cursor with the prescription details
        * @param      o_error              error message
        *
        * @return     boolean type, "False" on error or "True" if success
    USUS    * @author     Orlando Antunes
        * @version    0.1
        * @since      2007/11/23
        ***********************************************************************************************************/
    FUNCTION get_vaccines_detail_free_text
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_reg     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'START';
        --main title
        SELECT pk_message.get_message(i_lang, 'VACC_T070') || ': ' || pvad.desc_vaccine
          INTO o_main_title
          FROM pat_vacc_adm_det pvad
         WHERE pvad.id_pat_vacc_adm = i_reg;
    
        --this take title (apenas a label)
        o_this_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T042');
    
        --takes history title (apenas a label)
        o_history_take_title := pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T041');
    
        --vacc name
        --Esta informa��o serve o caso particular de administra��o de vacinas
        o_vacc_name := NULL;
    
        --detail information - texto do detalhe
        g_error := 'GET DETAIL INFO';
    
        o_detail_info := '<b>' || pk_message.get_message(i_lang, 'VACC_T010') || '</b> ' ||
                         pk_sysdomain.get_domain('VACC_TYPE_GROUP.FLG_PNV', pk_alert_constant.g_no, i_lang) ||
                         '<br><b>' || pk_message.get_message(i_lang, 'VACC_T013') || '</b><br><br>';
        --responsible:
        OPEN o_test_info FOR
        -- vacinas fora do PNV ou relatos
            SELECT pva.id_pat_vacc_adm id_test,
                   decode(pva.flg_orig,
                          g_orig_i,
                          ' ',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)) prof_name,
                   row_number() over(PARTITION BY pva.flg_orig ORDER BY pvad.dt_reg) --
                   || vacc_ordinal(count_vacc_take(i_lang, i_patient, i_reg, decode(pva.flg_orig, g_orig_r, nvl(pvad.dt_take, pvad.dt_reg), g_orig_i, nvl(pvad.dt_take, pvad.dt_reg), pvad.dt_reg), i_prof), i_lang) || ' ' || pk_message.get_message(i_lang, 'VACC_T017') dt_last,
                   --esta str apenas aparece no caso de ser um relato
                   decode(pva.flg_orig,
                           g_orig_r,
                           pk_message.get_message(i_lang, 'VACC_T062'),
                           g_orig_i,
                           '(' || pvad.report_orig || ')',
                           '') ||
                   --esta str apenas aparece no caso de ser uma vacina trazida pelo utente
                    decode(pva.flg_reported,
                           pk_alert_constant.g_yes,
                           pk_message.get_message(i_lang, 'VACC_T062'),
                           decode(pva.prof_presc, NULL, '', '(' || pk_message.get_message(i_lang, 'VACC_T071') || ')')) desc_other,
                   pk_message.get_message(i_lang, 'TUBERCULIN_TEST_T050') desc_state,
                   --falta o estado cancelado
                   get_summary_state_label(i_lang, --
                                           decode(pva.flg_status,
                                                  g_day,
                                                  'P',
                                                  'N',
                                                  'P',
                                                  'R',
                                                  'P',
                                                  'A',
                                                  'A',
                                                  'C',
                                                  'C',
                                                  'P')) state,
                   decode(pva.flg_status, g_day, 'P', 'N', 'P', 'R', 'P', 'A', 'A', 'C', 'C', 'P') flg_state,
                   pvad.dt_reg dt_take
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad, professional p
             WHERE pva.id_pat_vacc_adm = i_reg
               AND pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
               AND pva.id_patient = i_patient
               AND pva.id_prof_writes = p.id_professional
               AND pva.id_episode_destination IS NULL
             ORDER BY dt_take;
    
        g_error := 'CALL THE FUNCTION get_vaccine_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_vacc_canc_det(i_lang      => i_lang,
                                 i_patient   => i_patient,
                                 i_prof      => i_prof,
                                 i_test_id   => i_reg,
                                 i_to_add    => FALSE,
                                 o_can_title => o_can_title,
                                 o_can_det   => o_can_det,
                                 o_error     => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_vaccine_adm_det TO GET THE ADMINISTRATION DETAILS';
        IF NOT get_vacc_adm_det_ft(i_lang      => i_lang,
                                   i_patient   => i_patient,
                                   i_prof      => i_prof,
                                   i_test_id   => i_reg,
                                   i_to_add    => FALSE,
                                   o_adm_title => o_adm_title,
                                   o_adm_det   => o_adm_det,
                                   o_error     => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        --apenas para vacinas fora do PNV
        g_error := 'CALL THE FUNCTION get_vaccine_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_vacc_presc_det(i_lang         => i_lang,
                                  i_patient      => i_patient,
                                  i_prof         => i_prof,
                                  i_vacc_id      => NULL,
                                  i_vacc_take_id => i_reg,
                                  i_to_add       => FALSE,
                                  o_presc_title  => o_presc_title,
                                  o_presc_det    => o_presc_det,
                                  o_error        => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL THE FUNCTION get_vaccine_presc_det TO GET THE PRESCRIPTION DETAILS';
        IF NOT get_vacc_advers_react_det(i_lang    => i_lang,
                                         i_patient => i_patient,
                                         i_prof    => i_prof,
                                         i_test_id => i_reg,
                                         i_to_add  => FALSE,
                                         --OUT
                                         o_advers_react_title => o_advers_react_title,
                                         o_advers_react_det   => o_advers_react_det,
                                         --ERROR
                                         o_error => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'GET_VACCINES_DETAIL_FREE_TEXT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_test_info);
            pk_types.open_my_cursor(o_can_det);
            pk_types.open_my_cursor(o_adm_det);
            pk_types.open_my_cursor(o_presc_det);
            pk_types.open_my_cursor(o_advers_react_det);
            RETURN FALSE;
    END get_vaccines_detail_free_text;

    /**
     * This function is used to get the list of vaccine per patient
     * and return: - vaccine codes      
     *
     * DEPENDENCIES: REPORTS
     *
     * @param  i_lang  IN                      Language ID
     * @param  i_prof  IN                      Professional structure
     * @param  i_patient  IN                   Patient ID
     * @param  i_id_scope  IN                  Scope ID
     * @param  i_scope  OUT                    Scope
     *
     * @return   BOOLEAN
     *
     * @version  2.6.3.5
     * @since    31-Mar-2014
     * @author   Joel Lopes
    */
    FUNCTION get_vacc_list_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_id_scope IN NUMBER,
        i_scope    IN VARCHAR2
    ) RETURN t_tab_vacc_cdas IS
        l_tab_vacc_cdas t_tab_vacc_cdas := t_tab_vacc_cdas();
        l_error         t_error_out;
        l_episodes      table_number := table_number();
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        -- identifica��o do grupo a utilizar na especifica��o das vacinas
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    
        CURSOR c_vacc IS
            SELECT v.id_vacc,
                   vm.code_mvx id_vacc_manufacturer,
                   pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer) vacc_manufacturer_name,
                   decode(dpp.flg_type_date,
                          g_year,
                          substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 4),
                          g_month,
                          substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 6),
                          g_day,
                          substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 8),
                          pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof)) dt_pat_vacc_adm,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dp.dt_begin_tstz, i_prof.institution, i_prof.software) dt_format,
                   dpp.flg_status,
                   pk_sysdomain.get_desc_domain_set(i_lang        => i_lang,
                                                    i_code_domain => 'DRUG_PRESC_PLAN.FLG_STATUS',
                                                    i_vals        => dpp.flg_status) desc_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) code_vacc_us,
                   get_vacc_description(i_lang, i_prof, dpd.id_drug, v.id_vacc) code_desc_vacc_us,
                   m.code_cvx,
                   dpp.dosage n_dose,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, dpp.dosage_unit_measure) unit_measure,
                   dpp.dosage_unit_measure unit_measure_trans,
                   dpp.lot_number
              FROM vacc_dci vd
              JOIN mi_med m
                ON m.dci_id = vd.id_dci
               AND m.vers = l_version
              JOIN vacc v
                ON v.id_vacc = vd.id_vacc
              JOIN vacc_group vg
                ON vg.id_vacc = v.id_vacc
               AND vg.id_vacc_type_group = l_vacc_type_group
              JOIN vacc_group_soft_inst vgsi
                ON vgsi.id_vacc_group = vg.id_vacc_group
               AND vgsi.id_institution = i_prof.institution
               AND vgsi.id_software = i_prof.software
              JOIN drug_presc_det dpd
                ON dpd.id_drug = m.id_drug
              JOIN drug_prescription dp
                ON dp.id_drug_prescription = dpd.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
              LEFT JOIN vacc_manufacturer vm
                ON dpd.id_vacc_manufacturer = vm.id_vacc_manufacturer
             WHERE ((i_patient IS NULL OR dp.id_patient = i_patient) AND
                   (i_id_scope IS NULL OR (dp.id_episode IS NOT NULL AND dp.id_episode = i_id_scope)) OR
                   dp.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                       j.column_value
                                        FROM TABLE(l_episodes) j))
               AND dpp.flg_status <> g_vacc_status_edit
            
            UNION ALL
            SELECT pva.id_vacc,
                   vm.code_mvx id_vacc_manufacturer,
                   nvl(pvad.code_mvx, get_manufacturer_description(i_lang, pvad.id_vacc_manufacturer)) vacc_manufacturer_name,
                   decode(pvad.flg_type_date,
                          g_year,
                          substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 4),
                          g_month,
                          substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 6),
                          g_day,
                          substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 8),
                          pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof)) dt_pat_vacc_adm,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software) dt_format,
                   pva.flg_status,
                   pk_sysdomain.get_desc_domain_set(i_lang        => i_lang,
                                                    i_code_domain => 'DRUG_PRESC_PLAN.FLG_STATUS',
                                                    i_vals        => pva.flg_status) desc_status,
                   pk_translation.get_translation(i_lang, v.code_vacc) code_vacc_us,
                   get_vacc_description(i_lang, i_prof, mm.id_drug, v.id_vacc) code_desc_vacc_us,
                   mm.code_cvx,
                   pva.dosage n_dose,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, pva.dosage_unit_measure) unit_measure,
                   pva.dosage_unit_measure unit_measure_trans,
                   pvad.lot_number
              FROM pat_vacc_adm pva
              JOIN pat_vacc_adm_det pvad
                ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
              JOIN mi_med mm
                ON mm.id_drug = pvad.emb_id
               AND mm.vers = l_version
              LEFT JOIN vacc_manufacturer vm
                ON vm.id_vacc_manufacturer = pva.id_vacc_manufacturer
              JOIN vacc v
                ON v.id_vacc = pva.id_vacc
              JOIN vacc_group vg
                ON vg.id_vacc = v.id_vacc
               AND vg.id_vacc_type_group = l_vacc_type_group
              JOIN vacc_group_soft_inst vgsi
                ON vgsi.id_vacc_group = vg.id_vacc_group
               AND vgsi.id_institution = i_prof.institution
               AND vgsi.id_software = i_prof.software
             WHERE ((i_patient IS NULL OR pva.id_patient = i_patient) AND
                   (i_id_scope IS NULL OR (pva.id_episode IS NOT NULL AND pva.id_episode = i_id_scope)) OR
                   pva.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                        j.column_value
                                         FROM TABLE(l_episodes) j))
               AND pva.flg_status <> g_vacc_status_edit;
    
        l_vacc_info c_vacc%ROWTYPE;
    
    BEGIN
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => l_error)
        THEN
            RETURN l_tab_vacc_cdas;
        END IF;
    
        --find list of episodes
        IF i_scope = g_rep_type_visit
        THEN
        
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_patient,
                                                      i_id_episode        => NULL,
                                                      i_id_visit          => i_id_scope,
                                                      i_flg_visit_or_epis => i_scope);
        ELSE
            l_episodes := pk_patient.get_episode_list(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_patient,
                                                      i_id_episode        => i_id_scope,
                                                      i_id_visit          => NULL,
                                                      i_flg_visit_or_epis => i_scope);
        END IF;
    
        g_error := 'get_vacc_list_cda: i_patient: ' || i_patient || ' i_id_scope: ' || i_id_scope;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_vacc;
        LOOP
            g_error := 'FETCH MAPPING CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_vacc
                INTO l_vacc_info;
            EXIT WHEN c_vacc%NOTFOUND;
        
            g_error := 'CONSTRUCT t_rec_allergies_cdas';
            pk_alertlog.log_debug(g_error);
            l_tab_vacc_cdas.extend();
            l_tab_vacc_cdas(l_tab_vacc_cdas.last) := t_rec_vacc_cdas(id_vacc                => l_vacc_info.id_vacc,
                                                                     id_vacc_manufacturer   => l_vacc_info.id_vacc_manufacturer,
                                                                     vacc_manufacturer_name => l_vacc_info.vacc_manufacturer_name,
                                                                     dt_pat_vacc_adm        => l_vacc_info.dt_pat_vacc_adm,
                                                                     dt_format              => l_vacc_info.dt_format,
                                                                     flg_status             => l_vacc_info.flg_status,
                                                                     desc_status            => l_vacc_info.desc_status,
                                                                     code_vacc_us           => l_vacc_info.code_vacc_us,
                                                                     code_desc_vacc_us      => l_vacc_info.code_desc_vacc_us,
                                                                     code_cvx               => l_vacc_info.code_cvx,
                                                                     n_dose                 => l_vacc_info.n_dose,
                                                                     unit_measure           => l_vacc_info.unit_measure,
                                                                     unit_measure_trans     => l_vacc_info.unit_measure_trans,
                                                                     lot_number             => l_vacc_info.lot_number);
        
        END LOOP;
    
        RETURN l_tab_vacc_cdas;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_VACC_LIST_CDA',
                                              o_error    => l_error);
            RETURN l_tab_vacc_cdas;
    END get_vacc_list_cda;

    /**
     * This function returned if a next date is enabled or not
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient ID
     * @param  i_tk_date       IN   Take Date
     * @param  i_vacc          IN   Vacc ID
     * @param  i_dt_adm_str    IN   Date Administration
     * 
     * @return  next date is available (Y/N)
     *
     * @version  2.6.4.0.2
     * @since    22-05-2014
     * @author   Jorge Silva
    */
    FUNCTION get_next_date_available
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_tk_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2 IS
        l_current_take NUMBER;
        l_return       VARCHAR2(1);
    
        CURSOR c_next_date(i_current_take NUMBER) IS
            SELECT DISTINCT pk_alert_constant.g_yes
              FROM patient p, vacc_dose vd, TIME t
             WHERE p.id_patient = i_patient
               AND vd.id_vacc = i_vacc
               AND vd.n_dose = i_current_take
               AND vd.id_time = t.id_time;
    
    BEGIN
        -- numero de tomas administradas 
        l_current_take := count_vacc_take(i_lang     => i_lang,
                                          i_id_pat   => i_patient,
                                          i_vacc     => i_vacc,
                                          i_lasttake => i_tk_date,
                                          i_prof     => i_prof) + 1;
    
        OPEN c_next_date(l_current_take);
        FETCH c_next_date
            INTO l_return;
        IF c_next_date%NOTFOUND
        THEN
            l_return := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_next_date_available;

    /**
     * This function returned a date of next take     
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient ID
     * @param  i_vacc          IN   Vacc ID
     * @param  i_dt_adm_str    IN   Date Administration
     * 
     * @param  o_info_next_date  OUT Cursor of next take date
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_next_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_vacc           IN vacc.id_vacc%TYPE,
        i_dt_adm_str     IN VARCHAR2,
        o_info_next_date OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error           t_error_out;
        l_current_take    NUMBER;
        l_dt_adm_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_vacc_next       VARCHAR2(50);
        l_vacc_next_print VARCHAR2(50);
        l_dt_adm_str      VARCHAR2(16);
    
        CURSOR c_next_date
        (
            i_dt_adm_date  TIMESTAMP WITH LOCAL TIME ZONE,
            i_current_take NUMBER
        ) IS
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang,
                                                        pk_date_utils.add_days_to_tstz(i_dt_adm_date, val_min),
                                                        i_prof) vacc_next,
                            
                            pk_date_utils.date_chr_short_read(i_lang,
                                                              pk_date_utils.add_days_to_tstz(i_dt_adm_date, val_min),
                                                              i_prof) vacc_next_print
              FROM patient p, vacc_dose vd, TIME t
             WHERE p.id_patient = i_patient
               AND vd.id_vacc = i_vacc
               AND vd.n_dose = i_current_take
               AND vd.id_time = t.id_time;
    
    BEGIN
    
        g_error := 'OPEN count_vacc_take_all';
    
        l_dt_adm_str := i_dt_adm_str;
    
        IF (length(i_dt_adm_str) = 8)
        THEN
            l_dt_adm_str := i_dt_adm_str || '000000';
        END IF;
    
        -- numero de tomas administradas 
        l_current_take := count_vacc_take_all(i_lang, i_patient, i_vacc, i_prof) + 2;
    
        SELECT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_dt_adm_str,
                                             i_timezone  => NULL)
          INTO l_dt_adm_date
          FROM dual;
    
        OPEN c_next_date(l_dt_adm_date, l_current_take);
        FETCH c_next_date
            INTO l_vacc_next, l_vacc_next_print;
        IF c_next_date%NOTFOUND
        THEN
            l_vacc_next       := '';
            l_vacc_next_print := pk_message.get_message(i_lang, g_vacc_no_app);
        END IF;
    
        OPEN o_info_next_date FOR
            SELECT l_vacc_next vacc_next, l_vacc_next_print vacc_next_print
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_VACC_NEXT_DATE',
                                              o_error    => l_error);
            pk_types.open_my_cursor(o_info_next_date);
            RETURN FALSE;
    END get_vacc_next_date;

    /**
     * This function returned a viewer details    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_vacc          IN   Vacc ID
     * 
     * @param  o_detail_info_out  OUT Cursor of viewer details
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_viewer_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vacc        IN vacc.id_vacc%TYPE,
        o_detail_info OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_vacc_det_info     pk_types.cursor_type;
        l_vacc_det_info_age pk_types.cursor_type;
        l_info              VARCHAR2(4000) := '';
    BEGIN
        --detail information - texto do detalhe
        IF get_vacc_dose_info_detail_new(i_lang,
                                         i_prof,
                                         i_vacc,
                                         NULL,
                                         NULL,
                                         l_vacc_det_info,
                                         l_vacc_det_info_age,
                                         o_error)
        THEN
            --percorre os cursores para organizar a informa��o:
            --Info
            IF l_vacc_det_info IS NOT NULL
            THEN
                g_error := 'GET DETAIL INFO';
                --cursor j� aberto
                LOOP
                    FETCH l_vacc_det_info
                        INTO l_info;
                    EXIT WHEN l_vacc_det_info%NOTFOUND;
                    o_detail_info := o_detail_info || l_info;
                END LOOP;
                CLOSE l_vacc_det_info;
            END IF;
            --linha de intervalo
            --adiciona formata��o do texto
            o_detail_info := o_detail_info || '<br><br>';
        
            g_error := 'GET DETAIL AGE INFO';
            --Age
            IF l_vacc_det_info_age IS NOT NULL
            THEN
                --cursor j� aberto
                LOOP
                    FETCH l_vacc_det_info_age
                        INTO l_info;
                    EXIT WHEN l_vacc_det_info_age%NOTFOUND;
                    o_detail_info := o_detail_info || l_info || '<br>';
                END LOOP;
                CLOSE l_vacc_det_info_age;
            END IF;
        ELSE
            o_detail_info := '';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_VACC_VIEWER_DETAILS',
                                              o_error    => o_error);
            o_detail_info := '';
            RETURN FALSE;
    END get_vacc_viewer_details;

    /**
     * This function return all values of administration screen create or edit
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of administration screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_administration
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN drug_prescription.id_drug_prescription%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market             market.id_market%TYPE;
        l_next_date_desc     VARCHAR2(50 CHAR);
        l_next_date_value    VARCHAR2(50 CHAR);
        o_info               pk_types.cursor_type;
        l_id_adv_reaction    vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE;
        l_notes_adv_reaction drug_presc_plan.notes_advers_react%TYPE;
        l_error              t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF (i_drug IS NULL OR i_drug = -1)
        THEN
        
            IF NOT get_vacc_next_date(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_patient        => i_patient,
                                      i_vacc           => i_vacc,
                                      i_dt_adm_str     => pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof),
                                      o_info_next_date => o_info,
                                      o_error          => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
            FETCH o_info
                INTO l_next_date_value, l_next_date_desc;
            CLOSE o_info;
        
            OPEN o_form FOR
                SELECT NULL vac_value,
                       '' vac_desc,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) admdate_value,
                       pk_date_utils.date_char_tsz(i_lang, g_sysdate_tstz, i_prof.institution, i_prof.software) admdate_desc,
                       NULL admdose_value,
                       '' admdose_desc,
                       NULL admdose_um,
                       NULL admroute_value,
                       '' admroute_desc,
                       NULL admsite_value,
                       '' admsite_desc,
                       NULL manufacturer_value,
                       '' manufacturer_desc,
                       '' lot_desc,
                       NULL expdate_value,
                       '' expdate_desc,
                       NULL origin_value,
                       '' origin_desc,
                       NULL doctype_value,
                       '' doctype_desc,
                       NULL docdate_value,
                       '' docdate_desc,
                       NULL doccat_value,
                       '' doccat_desc,
                       NULL docsource_value,
                       '' docsource_desc,
                       i_prof.id orderby_value,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) orderby_desc,
                       NULL admby_value,
                       '' admby_desc,
                       l_next_date_value nextdose_value,
                       l_next_date_desc nextdose_desc,
                       NULL advreaction_value,
                       '' advreaction_desc,
                       '' admnotes_desc,
                       get_next_date_available(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_tk_date => g_sysdate_tstz,
                                               i_vacc    => i_vacc) next_date_enable
                  FROM dual;
        ELSE
            IF NOT get_advers_react(i_lang      => i_lang,
                                    i_prof      => i_prof,
                                    i_value     => i_drug,
                                    i_type_vacc => g_orig_v,
                                    o_id_value  => l_id_adv_reaction,
                                    o_notes     => l_notes_adv_reaction,
                                    o_error     => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            OPEN o_form FOR
                SELECT dpd.id_drug vac_value,
                       get_vacc_description(i_lang, i_prof, dpd.id_drug, i_vacc) vac_desc,
                       decode(flg_type_date,
                              g_year,
                              substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 4),
                              g_month,
                              substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 6),
                              g_day,
                              substr(pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof), 1, 8),
                              pk_date_utils.date_send_tsz(i_lang, dpp.dt_take_tstz, i_prof)) admdate_value,
                       decode(dpp.flg_type_date,
                              g_year,
                              pk_vacc.get_year_from_timestamp(dpp.dt_take_tstz),
                              g_month,
                              pk_date_utils.get_month_year(i_lang, i_prof, dpp.dt_take_tstz),
                              g_day,
                              pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                    dpp.dt_take_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software),
                              pk_date_utils.date_char_tsz(i_lang, dpp.dt_take_tstz, i_prof.institution, i_prof.software)) admdate_desc,
                       dpp.dosage admdose_value,
                       nvl(TRIM(pk_utils.to_str(dpp.dosage) || ' ' ||
                                pk_unit_measure.get_unit_measure_description(i_lang, i_prof, dpp.dosage_unit_measure)),
                           '') admdose_desc,
                       dpp.dosage_unit_measure admdose_um,
                       dpp.vacc_route_data admroute_value,
                       get_vacc_route_description(i_lang, i_prof, dpd.id_drug, dpp.vacc_route_data) admroute_desc,
                       dpp.application_spot_code admsite_value,
                       nvl(dpp.application_spot,
                           pk_sysdomain.get_domain_no_avail(g_domain_application_spot, dpp.application_spot_code, i_lang)) admsite_desc,
                       dpd.id_vacc_manufacturer manufacturer_value,
                       nvl(dpd.code_mvx, get_manufacturer_description(i_lang, dpd.id_vacc_manufacturer)) manufacturer_desc,
                       dpp.lot_number lot_desc,
                       pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expdate_desc,
                       pk_date_utils.date_send(i_lang, dpp.dt_expiration, i_prof) expdate_value,
                       dpp.id_vacc_origin origin_value,
                       nvl(dpp.origin_desc, get_origin_description(i_lang, dpp.id_vacc_origin)) origin_desc,
                       dpp.id_vacc_doc_vis doctype_value,
                       nvl(dpp.doc_vis_desc, get_doc_description(i_lang, i_prof, dpp.id_vacc_doc_vis)) doctype_desc,
                       pk_date_utils.date_send_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate_desc,
                       dpp.id_vacc_funding_cat doccat_value,
                       get_vacc_cat_description(i_lang, dpp.id_vacc_funding_cat) doccat_desc,
                       dpp.id_vacc_funding_source docsource_value,
                       nvl(dpp.funding_source_desc, get_vacc_source_description(i_lang, dpp.id_vacc_funding_source)) docsource_desc,
                       dpp.id_ordered orderby_value,
                       nvl(dpp.ordered_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_ordered)) orderby_desc,
                       dpp.id_administred admby_value,
                       nvl(dpp.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_administred)) admby_desc,
                       pk_date_utils.date_send_tsz(i_lang, dpp.dt_next_take, i_prof) nextdose_value,
                       decode(dpp.dt_next_take,
                              '',
                              pk_message.get_message(i_lang, g_vacc_no_app),
                              pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_next_take, i_prof)) nextdose_desc,
                       l_id_adv_reaction advreaction_value,
                       decode(l_id_adv_reaction,
                              g_other_value,
                              l_notes_adv_reaction,
                              get_adv_reactions_description(i_lang, l_id_adv_reaction)) advreaction_desc,
                       dpp.notes admnotes_desc,
                       get_next_date_available(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_tk_date => dpp.dt_take_tstz,
                                               i_vacc    => i_vacc) next_date_enable
                  FROM drug_prescription dp
                  JOIN drug_presc_det dpd
                    ON dpd.id_drug_prescription = dp.id_drug_prescription
                  JOIN drug_presc_plan dpp
                    ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
                 WHERE dp.id_drug_prescription = i_drug;
        
        END IF;
    
        IF (l_market = pk_alert_constant.g_id_market_usa)
        THEN
            o_doc_show := pk_alert_constant.g_yes;
        ELSE
            o_doc_show := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_VACC_FORM_ADMINISTRATION',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_form);
            RETURN FALSE;
    END get_vacc_form_administration;

    /**
     * This function return all values of report screen create or edit
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of report screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen  
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market             market.id_market%TYPE;
        l_id_adv_reaction    vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE;
        l_notes_adv_reaction pat_vacc_adm_det.notes_advers_react%TYPE;
        l_error              t_error_out;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF (i_drug IS NULL OR i_drug = -1)
        THEN
        
            OPEN o_form FOR
                SELECT NULL vac_value,
                       '' vac_desc,
                       NULL admdate_value,
                       '' admdate_desc,
                       NULL admdose_value,
                       '' admdose_desc,
                       NULL admdose_um,
                       NULL admroute_value,
                       '' admroute_desc,
                       NULL admsite_value,
                       '' admsite_desc,
                       NULL manufacturer_value,
                       '' manufacturer_desc,
                       '' lot_desc,
                       NULL expdate_value,
                       '' expdate_desc,
                       NULL origin_value,
                       '' origin_desc,
                       NULL doctype_value,
                       '' doctype_desc,
                       NULL docdate_value,
                       '' docdate_desc,
                       NULL doccat_value,
                       '' doccat_desc,
                       NULL docsource_value,
                       '' docsource_desc,
                       NULL information_value,
                       '' information_desc,
                       NULL admby_value,
                       '' admby_desc,
                       NULL nextdose_value,
                       '' nextdose_desc,
                       NULL advreaction_value,
                       '' advreaction_desc,
                       '' admnotes_desc,
                       get_next_date_available(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_tk_date => g_sysdate_tstz,
                                               i_vacc    => i_vacc) next_date_enable
                  FROM dual;
        
        ELSE
        
            IF NOT get_advers_react(i_lang      => i_lang,
                                    i_prof      => i_prof,
                                    i_value     => i_drug,
                                    i_type_vacc => g_orig_r,
                                    o_id_value  => l_id_adv_reaction,
                                    o_notes     => l_notes_adv_reaction,
                                    o_error     => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            OPEN o_form FOR
                SELECT pvad.emb_id vac_value,
                       get_vacc_description(i_lang, i_prof, pvad.emb_id, i_vacc) vac_desc,
                       decode(pvad.flg_type_date,
                              g_year,
                              substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 4),
                              g_month,
                              substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 6),
                              g_day,
                              substr(pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof), 1, 8),
                              pk_date_utils.date_send_tsz(i_lang, pvad.dt_take, i_prof)) admdate_value,
                       decode(pvad.flg_type_date,
                              g_year,
                              pk_vacc.get_year_from_timestamp(pvad.dt_take),
                              g_month,
                              pk_date_utils.get_month_year(i_lang, i_prof, pvad.dt_take),
                              g_day,
                              pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                    pvad.dt_take,
                                                                    i_prof.institution,
                                                                    i_prof.software),
                              pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software)) admdate_desc,
                       pva.dosage_admin admdose_value,
                       nvl(TRIM(pk_utils.to_str(pva.dosage_admin) || ' ' ||
                                pk_unit_measure.get_unit_measure_description(i_lang, i_prof, pva.dosage_unit_measure)),
                           '') admdose_desc,
                       pva.dosage_unit_measure admdose_um,
                       pvad.vacc_route_data admroute_value,
                       get_vacc_route_description(i_lang, i_prof, pvad.emb_id, pvad.vacc_route_data) admroute_desc,
                       pvad.application_spot_code admsite_value,
                       nvl(pvad.application_spot,
                           pk_sysdomain.get_domain_no_avail(g_domain_application_spot,
                                                            pvad.application_spot_code,
                                                            i_lang)) admsite_desc,
                       pvad.id_vacc_manufacturer manufacturer_value,
                       nvl(pvad.code_mvx, get_manufacturer_description(i_lang, pvad.id_vacc_manufacturer)) manufacturer_desc,
                       pvad.lot_number lot_desc,
                       pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof) expdate_desc,
                       pk_date_utils.date_send(i_lang, pvad.dt_expiration, i_prof) expdate_value,
                       pvad.id_vacc_origin origin_value,
                       nvl(pvad.origin_desc, get_origin_description(i_lang, pvad.id_vacc_origin)) origin_desc,
                       pvad.id_vacc_doc_vis doctype_value,
                       nvl(pvad.doc_vis_desc, get_doc_description(i_lang, i_prof, pvad.id_vacc_doc_vis)) doctype_desc,
                       pk_date_utils.date_send_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate_value,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate_desc,
                       pvad.id_vacc_funding_cat doccat_value,
                       get_vacc_cat_description(i_lang, pvad.id_vacc_funding_cat) doccat_desc,
                       pvad.id_vacc_funding_source docsource_value,
                       nvl(pvad.funding_source_desc, get_vacc_source_description(i_lang, pvad.id_vacc_funding_source)) docsource_desc,
                       pvad.id_information_source information_value,
                       nvl(pvad.report_orig, get_vacc_report_description(i_lang, pvad.id_information_source)) information_desc,
                       pvad.id_administred admby_value,
                       nvl(pvad.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_administred)) admby_desc,
                       pk_date_utils.date_send_tsz(i_lang, pvad.dt_next_take, i_prof) nextdose_value,
                       decode(pvad.dt_next_take,
                              '',
                              pk_message.get_message(i_lang, g_vacc_no_app),
                              pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_next_take, i_prof)) nextdose_desc,
                       l_id_adv_reaction advreaction_value,
                       decode(l_id_adv_reaction,
                              g_other_value,
                              l_notes_adv_reaction,
                              get_adv_reactions_description(i_lang, l_id_adv_reaction)) advreaction_desc,
                       pvad.notes admnotes_desc,
                       get_next_date_available(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_tk_date => pvad.dt_next_take,
                                               i_vacc    => i_vacc) next_date_enable
                  FROM pat_vacc_adm pva
                  JOIN pat_vacc_adm_det pvad
                    ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
                 WHERE pvad.id_pat_vacc_adm = i_drug;
        END IF;
    
        IF (l_market = pk_alert_constant.g_id_market_usa)
        THEN
            o_doc_show := pk_alert_constant.g_yes;
        ELSE
            o_doc_show := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_VACC_FORM_REPORT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_form);
            RETURN FALSE;
    END get_vacc_form_report;

    /**
     * This function returned all professional (doctor and nurse) in this institution    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * 
     * @param  o_prof_list  OUT     Cursor of professional (order by)
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    11-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_order_by_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat table_varchar := table_varchar(pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_nurse);
    BEGIN
        g_error := 'CALL get_order_by_prof_list';
    
        IF NOT pk_list.get_prof_inst_and_other_list(i_lang, i_prof, l_prof_cat, o_prof_list, o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_names,
                                              i_function => 'GET_ORDER_BY_PROF_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof_list);
            RETURN FALSE;
    END get_order_by_prof_list;

    /********************************************************************************************
    * Return a rout list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_route    rout list
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_route_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_drug    IN mi_med.id_drug%TYPE,
        o_vacc_route OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_vacc_route FOR
            SELECT mm.route_id data, mm.route_descr label
              FROM mi_med mm
             WHERE mm.id_drug = i_id_drug
               AND mm.flg_available = pk_alert_constant.g_yes
               AND mm.vers = l_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ROUTE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_route);
            RETURN FALSE;
    END get_vacc_route_list;

    /********************************************************************************************
    * Return default dose 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_dose    return default dose 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_dose_default
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_drug   IN mi_med.id_drug%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_vacc_dose FOR
            SELECT mm.qt_dos_comp data,
                   mm.qt_dos_comp || ' ' || pk_translation.get_translation(i_lang, um.code_unit_measure_abrv) label,
                   mm.id_unit_measure id_unit_measure
              FROM mi_med mm
              JOIN unit_measure um
                ON um.id_unit_measure = mm.id_unit_measure
             WHERE mm.id_drug = i_id_drug
               AND mm.flg_available = pk_alert_constant.g_yes
               AND mm.vers = l_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_DOSE_DEFAULT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_dose);
            RETURN FALSE;
    END get_vacc_dose_default;

    /********************************************************************************************
    * List of vaccine funding program eligibility category
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_type     Return list of vaccine funding program eligibility category
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_funding_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vacc_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_vacc_type FOR
            SELECT vfe.id_vacc_funding_elig data, vfe.concept_description label
              FROM vacc_funding_eligibility vfe
             WHERE vfe.flg_available = pk_alert_constant.g_yes
             ORDER BY vfe.concept_description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_FUNDING_TYPE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_type);
            RETURN FALSE;
    END get_vacc_funding_type;

    /********************************************************************************************
    * List of vaccine funding source
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_source     Return list of vaccine funding source
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_funding_source
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_source OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_vacc_source FOR
            SELECT vfs.id_vacc_funding_source data, vfs.concept_description label
              FROM vacc_funding_source vfs
             WHERE vfs.flg_available = pk_alert_constant.g_yes
             ORDER BY vfs.concept_description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_FUNDING_SOURCE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_source);
            RETURN FALSE;
    END get_vacc_funding_source;

    /********************************************************************************************
    * Return all documents filter by vaccine 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_doc    all documents filter by vaccine 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_doc_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        o_vacc_doc OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        OPEN o_vacc_doc FOR
            SELECT vd.id_vacc_doc_vis data,
                   vd.doc_vis_name || ' (' || pk_date_utils.date_chr_short_read(i_lang, vd.doc_edition_data, i_prof) || ')' label
              FROM mi_med mm
              JOIN vacc_doc_cvx vdc
                ON vdc.cvx_code = mm.code_cvx
              JOIN vacc_doc_vis vd
                ON vd.id_vacc_doc_vis = vdc.id_vacc_doc_vis
             WHERE mm.id_drug = i_id_drug
               AND mm.flg_available = pk_alert_constant.g_yes
               AND mm.vers = l_version
            UNION ALL
            SELECT g_other_value data, pk_message.get_message(i_lang, g_other_label) label
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'get_vacc_doc_list',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_doc);
            RETURN FALSE;
    END get_vacc_doc_list;

    /********************************************************************************************
    * Return document filter by barcode
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_barcode_desc    Barcode description
    
    * @param OUT  o_vacc_doc    Return document(description, edition date and id) filter by barcode
    *
    * @author                   Jorge Silva
    * @since                    27/05/2014
    ********************************************************************************************/
    FUNCTION get_vacc_doc_value
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_barcode_desc IN VARCHAR2,
        o_vacc_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_vacc_doc FOR
            SELECT vd.id_vacc_doc_vis data,
                   vd.doc_vis_name || ' (' || pk_date_utils.date_chr_short_read(i_lang, vd.doc_edition_data, i_prof) || ')' label
              FROM vacc_doc_vis vd
             WHERE vd.doc_vis_barcode = i_barcode_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'get_vacc_doc_value',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_doc);
            RETURN FALSE;
    END get_vacc_doc_value;

    /********************************************************************************************
    * This refers to the origin of the vaccine
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_origin     Return origin of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    13/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_origin_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_origin OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market market.id_market%TYPE;
    
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        OPEN o_vacc_origin FOR
            SELECT data, label
              FROM (SELECT vo.id_vacc_origin data,
                           pk_translation.get_translation(i_lang, vo.vacc_description) label,
                           decode(id_vacc_origin, -1, 1, 0) rank
                      FROM vacc_origin vo
                     WHERE vo.id_market IN (l_market, pk_alert_constant.g_id_market_all))
             ORDER BY rank, label ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_ORIGIN_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vacc_origin);
            RETURN FALSE;
    END get_vacc_origin_list;

    /********************************************************************************************
    * This refers to the adverse reaction of the vaccine
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_adv_reaction     Return adverse reaction of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    16/04/2014
    ********************************************************************************************/
    FUNCTION get_adverse_reaction_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_adv_reaction OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market market.id_market%TYPE;
    
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        OPEN o_adv_reaction FOR
            SELECT var.id_vacc_adverse_reaction data,
                   pk_translation.get_translation(i_lang, var.concept_description) label,
                   decode(var.id_vacc_adverse_reaction, -1, 1, 0) rank
              FROM vacc_adverse_reaction var
             WHERE var.id_market IN (l_market, pk_alert_constant.g_id_market_all)
               AND var.flg_available = pk_alert_constant.g_yes
             ORDER BY rank, label ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_ADVERSE_REACTION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_adv_reaction);
            RETURN FALSE;
    END get_adverse_reaction_list;

    /**
     * This function is used to register a administration the new vaccine
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * 
     * @param  o_prof_list  OUT     Cursor of professional (order by)
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    11-04-2014
     * @author   Jorge Silva
    */
    FUNCTION set_pat_administration
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_begin      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --adverse reaction
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufactured
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN VARCHAR2,
        
        --i_flg_type_date       IN VARCHAR2,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN vacc_origin.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE,
        i_doc_source      IN vacc_funding_source.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN VARCHAR2,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        --Notes
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type_date pat_vacc_adm_det.flg_type_date%TYPE := 'H';
        l_dt_begin_str  VARCHAR2(14);
    BEGIN
        g_error := 'SET_PAT_ADMINISTRATION_INTERN';
    
        IF (length(i_dt_begin) = 4)
        THEN
            l_flg_type_date := g_year;
            l_dt_begin_str  := i_dt_begin || '0101000000';
        ELSIF (length(i_dt_begin) = 6)
        THEN
            l_flg_type_date := g_month;
            l_dt_begin_str  := i_dt_begin || '01000000';
        ELSIF (length(i_dt_begin) = 8)
        THEN
            l_flg_type_date := g_day;
            l_dt_begin_str  := i_dt_begin || '000000';
        ELSE
            l_dt_begin_str := i_dt_begin;
        END IF;
    
        IF NOT set_pat_administration_intern(i_lang          => i_lang,
                                             i_episode       => i_episode,
                                             i_prof          => i_prof,
                                             i_pat           => i_pat,
                                             i_drug_presc    => i_drug_presc,
                                             i_dt_begin      => l_dt_begin_str,
                                             i_prof_cat_type => i_prof_cat_type,
                                             i_id_drug       => i_id_drug,
                                             i_id_vacc       => i_id_vacc,
                                             
                                             i_flg_advers_react   => g_year,
                                             i_advers_react       => i_advers_react,
                                             i_notes_advers_react => i_notes_advers_react,
                                             
                                             i_application_spot      => i_application_spot,
                                             i_application_spot_desc => i_application_spot_desc,
                                             
                                             i_lot_number => i_lot_number,
                                             i_dt_exp     => i_dt_exp,
                                             
                                             i_vacc_manuf      => i_vacc_manuf,
                                             i_vacc_manuf_desc => i_vacc_manuf_desc,
                                             
                                             i_flg_type_date       => l_flg_type_date,
                                             i_dosage_admin        => i_dosage_admin,
                                             i_dosage_unit_measure => i_dosage_unit_measure,
                                             
                                             i_adm_route => i_adm_route,
                                             
                                             i_vacc_origin      => i_vacc_origin,
                                             i_vacc_origin_desc => i_vacc_origin_desc,
                                             
                                             i_doc_vis      => i_doc_vis,
                                             i_doc_vis_desc => i_doc_vis_desc,
                                             
                                             i_dt_doc_delivery => i_dt_doc_delivery,
                                             i_doc_cat         => i_doc_cat,
                                             i_doc_source      => i_doc_source,
                                             i_doc_source_desc => i_doc_source_desc,
                                             
                                             i_order_by   => i_order_by,
                                             i_order_desc => i_order_desc,
                                             
                                             i_administer_by   => i_administer_by,
                                             i_administer_desc => i_administer_desc,
                                             
                                             i_dt_predicted => i_dt_predicted,
                                             i_test         => pk_alert_constant.g_no,
                                             
                                             i_notes => i_notes,
                                             
                                             o_drug_presc_plan => o_drug_presc_plan,
                                             o_drug_presc_det  => o_drug_presc_det,
                                             o_flg_show        => o_flg_show,
                                             o_msg             => o_msg,
                                             o_msg_result      => o_msg_result,
                                             o_msg_title       => o_msg_title,
                                             o_type_admin      => o_type_admin,
                                             o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_PAT_ADMINISTRATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_pat_administration;

    /**********************************************************************************************
    *  Criar prescri��es de medicamentos (vacinas)
    *
    * @param i_lang                   the id language
    * @param i_episode                id_do epis�dio
    * @param i_prof                   Profissional que requisita
    * @param i_pat                    id do paciente
    * @param i_flg_time               Realiza��o: E - neste epis�dio; N - pr�ximo epis�dio; B - entre epis�dios
    * @param i_dt_begin               Data a partir da qual � pedida a realiza��o do exame
    * @param i_notes                  Notas de prescri��o no plano
    * @param i_take_type              Tipo de plano de tomas: N - normal, S - SOS,  U - unit�rio, C - cont�nuo, A - ad eternum
    * @param i_drug                   array de medicamentos
    * @param i_dt_end                 data fim. � indicada em CHECK_PRESC_PARAM; se for 'n�o aplic�vel', I_DT_END = NULL
    * @param i_interval               intervalo entre tomas
    * @param i_dosage                 dosagem
    * @param i_prof_cat_type          Tipo de categoria do profissional, tal como � retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_justif                 Se a escolha do medicamento foi feita por + frequentes, I_JUSTIF = N. Sen�o, I_JUSTIF = Y.
    * @param i_justif_valid           Se esta fun��o � chamada a partir do ecr� de justifica��o, I_JUSTIF_VALID = Y. Sen�o, I_JUSTIF_VALID = N.
    * @param i_test                   indica��o se testa a exist�ncia de exames com resultados ou j� requisitados (se a msg O_MSG_REQ ou O_MSG_RESULT j� foram apresentadas e o user continuou, I_TEST = pk_alert_constant.g_no)
    
    * @param  o_msg_req               mensagem com exames q foram requisitados recentemente
    * @param o_msg_result             mensagem com exames q foram requisitados recentemente e t�m resultado
    * @param o_msg_title              T�tulo da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param  o_button                Bot�es a mostrar: N - n�o, R - lido, C - confirmado Tb pode mostrar combina��es destes, qd � p/ mostrar + do q 1 bot�o
    * @param o_justif                 Indica��o de q precisa de mostrar o ecr� de justifica��o: NULL - � mostra not NULL - cont�m o t�tulo do ecr� de msg
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2014/04/16
    **********************************************************************************************/
    FUNCTION set_pat_administration_intern
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN drug_prescription.id_episode%TYPE,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        i_drug_presc IN drug_prescription.id_drug_prescription%TYPE,
        i_flg_time   IN drug_prescription.flg_time%TYPE DEFAULT 'E',
        i_dt_begin   IN VARCHAR2,
        
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --Old screen
        i_flg_advers_react   IN VARCHAR2,
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufacturer
        i_vacc_manuf      IN drug_presc_det.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN drug_presc_det.code_mvx%TYPE,
        
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN drug_presc_plan.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN drug_presc_plan.origin_desc%TYPE,
        
        --Docs
        i_doc_vis      IN drug_presc_plan.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN drug_presc_plan.id_vacc_funding_cat%TYPE,
        i_doc_source      IN drug_presc_plan.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN drug_presc_plan.ordered_desc%TYPE,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN drug_presc_plan.administred_desc%TYPE,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        i_test         IN VARCHAR2,
        
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status_det         drug_presc_det.flg_status%TYPE;
        l_dt_first_drug_prsc epis_info.dt_first_drug_prsc_tstz%TYPE;
        l_interval           drug_presc_det.interval%TYPE;
    
        --Valor do id do episodio associado ao paciente, ou do novo episodio caso ainda n�o exista
        l_episode drug_prescription.id_episode%TYPE;
    
        --Exception
        invalid_episode EXCEPTION;
    
        --drug_prescription pk
        dp_pk drug_prescription.id_drug_prescription%TYPE;
        --drug_presc_det pk
        dpd_pk drug_presc_det.id_drug_presc_det%TYPE;
        --drug_presc_plan pk
        dpp_pk drug_presc_plan.id_drug_presc_plan%TYPE;
    
        l_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_dt_doc_delivery_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        --Conjunto de avdverse reaction activas
        CURSOR c_adv_reaction
        (
            v_id_reg   vacc_advers_react.id_reg%TYPE,
            v_flg_type vacc_advers_react.flg_type%TYPE
        ) IS
        
            SELECT var.id_vacc_adver_reac, var.notes_advers_react notes
              FROM vacc_advers_react var
             WHERE var.id_reg = v_id_reg
               AND var.flg_status = pk_alert_constant.g_active
               AND var.flg_type = v_flg_type;
    
        --vacinas j� administradas(apenas as novas vacinas)
        CURSOR c_adm_vaccines IS
            SELECT COUNT(*)
              FROM drug_prescription dp,
                   drug_presc_det    dpd,
                   mi_med            mm,
                   drug_presc_plan   dpp,
                   vacc              v,
                   visit             vi,
                   episode           e,
                   vacc_dci          vd
             WHERE dpd.id_drug = mm.id_drug
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dp.id_drug_prescription = dpd.id_drug_prescription
               AND dpd.id_drug = mm.id_drug
               AND mm.dci_id = vd.id_dci
               AND vd.id_vacc = v.id_vacc
               AND mm.vers = l_version
               AND mm.flg_type = g_month
               AND dpp.flg_status = pk_alert_constant.g_active
               AND v.id_vacc = i_id_vacc
               AND e.id_episode = dp.id_episode
               AND e.id_visit = vi.id_visit
               AND vi.id_patient = i_pat
               AND dpp.dt_take_tstz = l_dt_begin_tstz;
    
        --numero de vacinas administradas para a mesma hora
        l_count_vacc_take      PLS_INTEGER;
        l_dt_next_take         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_current_time_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_expiration        drug_presc_plan.dt_expiration%TYPE;
    
        l_rowids_1 table_varchar;
        e_process_event EXCEPTION;
    
        l_presc_det  drug_presc_det.id_drug_presc_det%TYPE;
        l_presc_plan drug_presc_plan.id_drug_presc_plan%TYPE;
        l_parent     drug_prescription.id_parent%TYPE;
    
        r_adv_reaction c_adv_reaction%ROWTYPE;
    BEGIN
    
        IF (i_drug_presc IS NOT NULL)
        THEN
        
            SELECT dpd.id_drug_presc_det, dpp.id_drug_presc_plan, dp.id_parent
              INTO l_presc_det, l_presc_plan, l_parent
              FROM drug_prescription dp
              JOIN drug_presc_det dpd
                ON dpd.id_drug_prescription = dp.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
             WHERE dp.id_drug_prescription = i_drug_presc;
        
            ts_drug_prescription.upd(id_drug_prescription_in => i_drug_presc, flg_status_in => g_vacc_status_edit);
        
            ts_drug_presc_det.upd(id_drug_presc_det_in => l_presc_det, flg_status_in => g_vacc_status_edit);
        
            ts_drug_presc_plan.upd(id_drug_presc_plan_in => l_presc_plan, flg_status_in => g_vacc_status_edit);
        END IF;
    
        -- vers�o 2.4.3 proxima toma
        l_dt_next_take  := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_predicted,
                                                         NULL);
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_begin,
                                                         NULL);
    
        l_dt_doc_delivery_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                                profissional(i_prof.id, i_prof.institution, NULL),
                                                                i_dt_doc_delivery,
                                                                NULL);
    
        l_dt_expiration := to_date(i_dt_exp, 'YYYYMMDDHH24MISS');
    
        IF i_test = pk_alert_constant.g_yes
        THEN
            OPEN c_adm_vaccines;
            FETCH c_adm_vaccines
                INTO l_count_vacc_take;
            CLOSE c_adm_vaccines;
        
            IF l_count_vacc_take IS NOT NULL
               AND l_count_vacc_take <> 0
            THEN
                o_msg_title := pk_message.get_message(i_lang, 'VACC_T081');
                o_msg       := pk_message.get_message(i_lang, 'VACC_T082');
                o_flg_show  := pk_alert_constant.g_yes;
                RETURN TRUE;
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        l_episode := i_episode;
    
        IF nvl(l_dt_begin_tstz, g_sysdate_tstz) < g_sysdate_tstz
        THEN
            l_dt_current_time_tstz := l_dt_begin_tstz;
        ELSE
            l_dt_current_time_tstz := g_sysdate_tstz;
        END IF;
    
        -- *********************************
        -- PT 24/09/2008 2.4.3.d
        g_error := 'INSERT INTO DRUG_PRESCRIPTION';
        ts_drug_prescription.ins(id_drug_prescription_out     => dp_pk,
                                 id_episode_in                => l_episode,
                                 id_professional_in           => i_prof.id,
                                 flg_type_in                  => g_presc_type_int,
                                 flg_time_in                  => i_flg_time,
                                 flg_status_in                => g_presc_fin,
                                 dt_drug_prescription_tstz_in => l_dt_current_time_tstz,
                                 dt_begin_tstz_in             => l_dt_begin_tstz,
                                 id_patient_in                => i_pat,
                                 id_parent_in                 => nvl(l_parent, i_drug_presc),
                                 rows_out                     => l_rowids_1);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DRUG_PRESCRIPTION',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
        -- *********************************
    
        g_error      := 'INSERT INTO DRUG_PRESC_DET';
        l_status_det := g_presc_det_fin;
    
        dpd_pk := ins_drug_presc_det(i_lang,
                                     i_prof,
                                     dp_pk,
                                     NULL,
                                     g_presc_take_uni,
                                     NULL,
                                     NULL,
                                     l_status_det,
                                     NULL,
                                     NULL,
                                     NULL,
                                     l_interval,
                                     1,
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
                                     l_dt_begin_tstz,
                                     l_dt_begin_tstz,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     pk_alert_constant.g_no,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     --to_number(REPLACE(i_dos_comp, '.', ',')),
                                     NULL,
                                     NULL,
                                     i_id_drug,
                                     l_version,
                                     NULL,
                                     NULL,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_no,
                                     i_vacc_manuf,
                                     i_vacc_manuf_desc);
    
        --output do novo id da dpd
        o_drug_presc_det := dpd_pk;
    
        g_error := 'CREATE VACC TAKE CONT';
    
        dpp_pk := ins_drug_presc_plan(i_lang,
                                      i_prof,
                                      dpd_pk,
                                      NULL,
                                      i_prof.id,
                                      NULL,
                                      g_presc_plan_stat_adm,
                                      i_notes,
                                      NULL,
                                      NULL,
                                      l_episode,
                                      NULL,
                                      NULL,
                                      i_flg_advers_react,
                                      i_notes_advers_react,
                                      i_application_spot_desc,
                                      i_lot_number,
                                      l_dt_expiration,
                                      NULL,
                                      l_dt_begin_tstz,
                                      l_dt_begin_tstz,
                                      NULL,
                                      l_dt_next_take,
                                      i_flg_type_date,
                                      i_dosage_admin,
                                      i_dosage_unit_measure,
                                      i_doc_cat,
                                      i_doc_source,
                                      i_doc_source_desc,
                                      i_doc_vis,
                                      i_doc_vis_desc,
                                      i_vacc_origin,
                                      i_vacc_origin_desc,
                                      i_order_desc,
                                      i_administer_desc,
                                      i_adm_route,
                                      i_order_by,
                                      i_administer_by,
                                      l_dt_doc_delivery_tstz,
                                      i_advers_react,
                                      i_application_spot);
    
        --output do novo id da dpp
        o_drug_presc_plan := dpp_pk;
        o_type_admin      := g_day;
    
        g_error := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
        IF NOT pk_visit.upd_epis_info_drug(i_lang               => i_lang,
                                           i_id_episode         => l_episode,
                                           i_id_prof            => i_prof,
                                           i_dt_first_drug_prsc => l_dt_first_drug_prsc,
                                           i_dt_first_drug_take => NULL,
                                           i_prof_cat_type      => i_prof_cat_type,
                                           o_error              => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            --o_error := l_error;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO PK_PRESCRIPTION.INSERT_DRUG_PRESC_TASK';
        IF NOT pk_prescription_int.insert_drug_presc_task(i_lang          => i_lang,
                                                          i_episode       => l_episode,
                                                          i_prof          => i_prof,
                                                          i_prof_cat_type => i_prof_cat_type,
                                                          o_error         => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        OPEN c_adv_reaction(i_drug_presc, g_vacc_dose_adm);
        FETCH c_adv_reaction
            INTO r_adv_reaction;
        IF c_adv_reaction%FOUND
        THEN
            UPDATE vacc_advers_react var
               SET var.flg_status = pk_alert_constant.g_inactive
             WHERE var.id_reg = i_drug_presc
               AND var.flg_type = g_vacc_dose_adm;
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
                                              'PK_VACC',
                                              'SET_PAT_ADMINISTRATION_INTERN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_administration_intern;

    /********************************************************************************************
    * Return name of vaccine with default value of route and dose
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  Return name of vaccine
    *
    * @author                   Jorge Silva
    * @since                    18/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_description
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN mi_med.id_drug%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2 IS
    
        l_version mi_med.vers%TYPE;
        l_ret     VARCHAR2(4000 CHAR);
    BEGIN
    
        l_version := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        SELECT pk_translation.get_translation(i_lang, v.code_vacc) || ' / ' || mim.med_descr || ' (' || mim.route_abrv || ')'
          INTO l_ret
          FROM vacc v
          JOIN vacc_dci vd
            ON vd.id_vacc = v.id_vacc
          JOIN mi_med mim
            ON mim.dci_id = vd.id_dci
           AND mim.vers = l_version
           AND mim.flg_available = pk_alert_constant.g_yes
         WHERE mim.id_drug = i_drug
           AND v.id_vacc = i_vacc;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_vacc_description;

    /********************************************************************************************
    * Return a route description
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    * @param IN   i_id_route       toute identifier
    *
    * @return     Route description
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_route_description
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        i_id_route IN mi_med.route_id%TYPE
    ) RETURN VARCHAR2 IS
        l_route_desc mi_med.route_descr%TYPE;
        l_version    mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    BEGIN
    
        SELECT mm.route_descr label
          INTO l_route_desc
          FROM mi_med mm
         WHERE mm.id_drug = i_id_drug
           AND mm.route_id = i_id_route
           AND mm.flg_available = pk_alert_constant.g_yes
           AND mm.vers = l_version;
    
        RETURN l_route_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_vacc_route_description;

    /********************************************************************************************
    * Return a description of manufactured
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_manufactured_id   manufactured identifier
    *
    * @return     Description of manufactured
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_manufacturer_description
    (
        i_lang            IN language.id_language%TYPE,
        i_manufactured_id IN vacc_manufacturer.id_vacc_manufacturer%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, vm.code_vacc_manufacturer)
          INTO l_ret
          FROM vacc_manufacturer vm
         WHERE vm.id_vacc_manufacturer = i_manufactured_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_manufacturer_description;

    /********************************************************************************************
    * Return a description of origin
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_origin_description
    (
        i_lang      IN language.id_language%TYPE,
        i_origin_id IN vacc_origin.id_vacc_origin%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, vo.vacc_description)
          INTO l_ret
          FROM vacc_origin vo
         WHERE vo.id_vacc_origin = i_origin_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_origin_description;

    /********************************************************************************************
    * Return a description of origin documents
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin documents
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_cat_description
    (
        i_lang        IN language.id_language%TYPE,
        i_vacc_cat_id IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT vfe.concept_description
          INTO l_ret
          FROM vacc_funding_eligibility vfe
         WHERE vfe.id_vacc_funding_elig = i_vacc_cat_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_vacc_cat_description;

    /********************************************************************************************
    * Return a description of documents source
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of documents source
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_source_description
    (
        i_lang           IN language.id_language%TYPE,
        i_vacc_source_id IN vacc_funding_source.id_vacc_funding_source%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT vfs.concept_description
          INTO l_ret
          FROM vacc_funding_source vfs
         WHERE vfs.id_vacc_funding_source = i_vacc_source_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_vacc_source_description;

    /********************************************************************************************
    * Return a description of information source of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_report_id   information source identifier
    *
    * @return     Description of information source
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_report_description
    (
        i_lang      IN language.id_language%TYPE,
        i_report_id IN vacc_report.id_vacc_report%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, vr.code_vacc_report)
          INTO l_ret
          FROM vacc_report vr
         WHERE vr.id_vacc_report = i_report_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_vacc_report_description;

    /********************************************************************************************
    * Return a adverse reaction description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_adv_reactions_id   adverse reaction identifier
    *
    * @return     Description of adverse reaction description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_adv_reactions_description
    (
        i_lang             IN language.id_language%TYPE,
        i_adv_reactions_id IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, var.concept_description)
          INTO l_ret
          FROM vacc_adverse_reaction var
         WHERE var.id_vacc_adverse_reaction = i_adv_reactions_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_adv_reactions_description;

    /********************************************************************************************
    * Return a doc description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_doc_id      doc identifier
    *
    * @return     Description doc description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_doc_description
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_doc_id IN vacc_doc_vis.id_vacc_doc_vis%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
    
        SELECT vd.doc_vis_name || ' (' || pk_date_utils.date_chr_short_read(i_lang, vd.doc_edition_data, i_prof) || ')'
          INTO l_ret
          FROM vacc_doc_vis vd
         WHERE vd.id_vacc_doc_vis = i_doc_id;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_doc_description;

    /************************************************************************************************************
    * Cancel the administration of nvp vacc 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_drug_prescription  id drug prescription 
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2012-03-13
    ***********************************************************************************************************/
    FUNCTION set_cancel_adm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_drug_prescription drug_prescription%ROWTYPE;
        l_drug_prescription_det NUMBER;
        l_drug_presc_plan       drug_presc_plan.id_drug_presc_plan%TYPE;
        --Exception
        unexpected_error EXCEPTION;
        l_rows table_varchar;
    BEGIN
        SELECT dpd.id_drug_presc_det, dpp.id_drug_presc_plan
          INTO l_drug_prescription_det, l_drug_presc_plan
          FROM drug_presc_det dpd, drug_presc_plan dpp
         WHERE dpd.id_drug_prescription = i_drug_prescription
           AND dpd.id_drug_presc_det = dpp.id_drug_presc_det;
    
        IF NOT pk_prescription_int.cancel_adm_take(i_lang                => i_lang,
                                                   i_drug_presc_plan     => l_drug_presc_plan,
                                                   i_dt_next             => NULL,
                                                   i_prof                => i_prof,
                                                   i_notes               => i_notes_cancel,
                                                   i_id_cancel_reason    => i_id_cancel_reason,
                                                   i_cancel_reason_descr => NULL,
                                                   o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_prescription_int.cancel_presc(i_lang, l_drug_prescription_det, i_prof, i_notes_cancel, o_error)
        THEN
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
                                              'PK_VACC',
                                              'SET_CANCEL_ADM',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END set_cancel_adm;

    /************************************************************************************************************
    * Cancel the administration of nvp vacc 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_drug_prescription  id drug prescription 
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2012-03-13
    ***********************************************************************************************************/
    FUNCTION set_cancel_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO SET_CANCEL_OTHER_VACC';
        IF NOT set_cancel_other_vacc(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_vacc_presc_id    => i_vacc_presc_id,
                                     i_id_cancel_reason => i_id_cancel_reason,
                                     i_notes_cancel     => i_notes_cancel,
                                     o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
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
                                              'PK_VACC',
                                              'SET_CANCEL_REPORT',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END set_cancel_report;

    FUNCTION set_pat_report
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_presc         IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str  IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN mi_med.id_drug%TYPE,
        i_vacc          IN pat_vacc_adm.id_vacc%TYPE,
        
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str IN VARCHAR2,
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE,
        
        i_adm_route IN VARCHAR2,
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery     IN VARCHAR2,
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE,
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE,
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        i_notes IN pat_vacc_adm_det.notes%TYPE,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT set_pat_report(i_lang                  => i_lang,
                              i_id_episode            => i_id_episode,
                              i_prof                  => i_prof,
                              i_id_patient            => i_id_patient,
                              i_presc                 => i_presc,
                              i_dt_begin_str          => i_dt_begin_str,
                              i_prof_cat_type         => i_prof_cat_type,
                              i_id_drug               => i_id_drug,
                              i_vacc                  => i_vacc,
                              i_advers_react          => i_advers_react,
                              i_notes_advers_react    => i_notes_advers_react,
                              i_application_spot_code => i_application_spot_code,
                              i_application_spot      => i_application_spot,
                              i_lot_number            => i_lot_number,
                              i_dt_expiration_str     => i_dt_expiration_str,
                              i_vacc_manuf            => i_vacc_manuf,
                              i_vacc_manuf_desc       => i_vacc_manuf_desc,
                              i_dosage_admin          => i_dosage_admin,
                              i_dosage_unit_measure   => i_dosage_unit_measure,
                              i_adm_route             => i_adm_route,
                              i_vacc_origin           => i_vacc_origin,
                              i_vacc_origin_desc      => i_vacc_origin_desc,
                              i_doc_vis               => i_doc_vis,
                              i_doc_vis_desc          => i_doc_vis_desc,
                              i_dt_doc_delivery       => i_dt_doc_delivery,
                              i_vacc_funding_cat      => i_vacc_funding_cat,
                              i_vacc_funding_source   => i_vacc_funding_source,
                              i_funding_source_desc   => i_funding_source_desc,
                              i_information_source    => i_information_source,
                              i_report_orig           => i_report_orig,
                              i_administred           => i_administred,
                              i_administred_desc      => i_administred_desc,
                              i_notes                 => i_notes,
                              i_flg_status            => pk_alert_constant.g_active,
                              i_suspended_notes       => '',
                              i_dt_predicted          => i_dt_predicted,
                              i_id_reason_sus         => NULL,
                              i_dt_suspended          => NULL,
                              o_id_admin              => o_id_admin,
                              o_type_admin            => o_type_admin,
                              o_error                 => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'SET_PAT_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END set_pat_report;

    FUNCTION set_discontinue_dose
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_vacc            IN pat_vacc_adm.id_vacc%TYPE,
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE,
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_id_admin   pat_vacc_adm.id_pat_vacc_adm%TYPE;
        o_type_admin VARCHAR2(1);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF NOT set_pat_report(i_lang            => i_lang,
                              i_id_episode      => i_id_episode,
                              i_prof            => i_prof,
                              i_id_patient      => i_id_patient,
                              i_presc           => NULL,
                              i_prof_cat_type   => '',
                              i_id_drug         => NULL,
                              i_vacc            => i_vacc,
                              i_flg_status      => g_status_s,
                              i_suspended_notes => i_suspended_notes,
                              i_id_reason_sus   => i_id_reason_sus,
                              i_dt_suspended    => g_sysdate_tstz,
                              o_id_admin        => o_id_admin,
                              o_type_admin      => o_type_admin,
                              o_error           => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'set_discontinue_dose',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END set_discontinue_dose;

    FUNCTION set_resume_dose
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN pat_vacc_adm.id_vacc%TYPE,
        i_drug       IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_id_admin   pat_vacc_adm.id_pat_vacc_adm%TYPE;
        o_type_admin VARCHAR2(1);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF NOT set_pat_report(i_lang            => i_lang,
                              i_id_episode      => i_id_episode,
                              i_prof            => i_prof,
                              i_presc           => i_drug,
                              i_id_patient      => i_id_patient,
                              i_prof_cat_type   => '',
                              i_id_drug         => NULL,
                              i_vacc            => i_vacc,
                              i_flg_status      => g_status_r,
                              i_suspended_notes => '',
                              i_id_reason_sus   => NULL,
                              i_dt_suspended    => NULL,
                              o_id_admin        => o_id_admin,
                              o_type_admin      => o_type_admin,
                              o_error           => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
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
                                              'PK_VACC',
                                              'set_RESUME_dose',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END set_resume_dose;

    FUNCTION set_pat_report
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_presc         IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str  IN VARCHAR2 DEFAULT '',
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN mi_med.id_drug%TYPE,
        i_vacc          IN pat_vacc_adm.id_vacc%TYPE,
        
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE DEFAULT NULL,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE DEFAULT '',
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE DEFAULT NULL,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE DEFAULT '',
        i_dt_expiration_str IN VARCHAR2 DEFAULT '',
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2 DEFAULT '',
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE DEFAULT NULL,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE DEFAULT NULL,
        
        i_adm_route IN VARCHAR2 DEFAULT '',
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2 DEFAULT '',
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE DEFAULT NULL,
        i_doc_vis_desc IN VARCHAR2 DEFAULT '',
        
        i_dt_doc_delivery     IN VARCHAR2 DEFAULT '',
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE DEFAULT '',
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE DEFAULT '',
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2 DEFAULT '',
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2 DEFAULT '',
        
        i_notes IN pat_vacc_adm_det.notes%TYPE DEFAULT '',
        
        i_flg_status      IN pat_vacc_adm_det.flg_status%TYPE DEFAULT 'A',
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE DEFAULT '',
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE DEFAULT NULL,
        i_dt_suspended    IN pat_vacc_adm_det.dt_suspended%TYPE DEFAULT NULL,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_dt_begin_aux         VARCHAR2(14);
        l_dt_begin             TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_expiration        TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_next_take         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_doc_delivery_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_pat_vacc_adm pat_vacc_adm.id_pat_vacc_adm%TYPE;
        l_continue        BOOLEAN := TRUE;
    
        l_reason not_order_reason.id_not_order_reason%TYPE := NULL;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_flg_type_date pat_vacc_adm_det.flg_type_date%TYPE := 'H';
    
        l_emb_id pat_vacc_adm_det.emb_id%TYPE;
    
        l_rows table_varchar := table_varchar();
    
        l_parent pat_vacc_adm.id_parent%TYPE;
    
        --Conjunto de avdverse reaction activas
        CURSOR c_adv_reaction
        (
            v_id_reg   vacc_advers_react.id_reg%TYPE,
            v_flg_type vacc_advers_react.flg_type%TYPE
        ) IS
            SELECT var.id_vacc_adver_reac, var.notes_advers_react notes
              FROM vacc_advers_react var
             WHERE var.id_reg = v_id_reg
               AND var.flg_status = pk_alert_constant.g_active
               AND var.flg_type = v_flg_type;
    
        r_adv_reaction c_adv_reaction%ROWTYPE;
    
    BEGIN
    
        IF (length(i_dt_begin_str) = 4)
        THEN
            l_flg_type_date := g_year;
            i_dt_begin_aux  := i_dt_begin_str || '0101000000';
        ELSIF (length(i_dt_begin_str) = 6)
        THEN
            l_flg_type_date := g_month;
            i_dt_begin_aux  := i_dt_begin_str || '01000000';
        ELSIF (length(i_dt_begin_str) = 8)
        THEN
            l_flg_type_date := g_day;
            i_dt_begin_aux  := i_dt_begin_str || '000000';
        ELSE
            i_dt_begin_aux := i_dt_begin_str;
        END IF;
    
        l_dt_next_take := pk_date_utils.get_string_tstz(i_lang,
                                                        profissional(i_prof.id, i_prof.institution, NULL),
                                                        i_dt_predicted,
                                                        NULL);
    
        l_dt_doc_delivery_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                                profissional(i_prof.id, i_prof.institution, NULL),
                                                                i_dt_doc_delivery,
                                                                NULL);
    
        IF i_presc IS NOT NULL
           AND i_flg_status <> g_status_r
        THEN
            ts_pat_vacc_adm.upd(id_pat_vacc_adm_in => i_presc, flg_status_in => g_vacc_status_edit);
        
            ts_pat_vacc_adm_det.upd(flg_status_in => g_vacc_status_edit,
                                    where_in      => 'id_pat_vacc_adm = ' || i_presc,
                                    rows_out      => l_rows);
        
            SELECT pva.id_parent
              INTO l_parent
              FROM pat_vacc_adm pva
             WHERE pva.id_pat_vacc_adm = i_presc;
        END IF;
    
        IF i_id_reason_sus IS NOT NULL
        THEN
            IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_not_order_reason_ea => i_id_reason_sus,
                                                               o_id_not_order_reason => l_reason,
                                                               o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --dt_begin
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang,
                                                    profissional(i_prof.id, i_prof.institution, NULL),
                                                    i_dt_begin_aux,
                                                    NULL);
    
        l_dt_expiration := pk_date_utils.get_string_tstz(i_lang,
                                                         profissional(i_prof.id, i_prof.institution, NULL),
                                                         i_dt_expiration_str,
                                                         NULL);
        g_error         := ' INSERT INTO PAT_VACC_ADM ';
    
        --  g_sysdate := SYSDATE;
    
        SELECT seq_pat_vacc_adm.nextval
          INTO l_id_pat_vacc_adm
          FROM dual;
    
        ts_pat_vacc_adm.ins(id_pat_vacc_adm_in      => l_id_pat_vacc_adm,
                            dt_pat_vacc_adm_in      => l_dt_begin,
                            id_prof_writes_in       => i_prof.id,
                            id_vacc_in              => i_vacc,
                            id_patient_in           => i_id_patient,
                            id_episode_in           => i_id_episode,
                            flg_status_in           => i_flg_status,
                            flg_time_in             => g_flg_time_e,
                            flg_orig_in             => g_vacc_dose_report,
                            flg_type_date_in        => l_flg_type_date,
                            id_vacc_manufacturer_in => i_vacc_manuf,
                            id_parent_in            => nvl(l_parent, i_presc),
                            code_mvx_in             => i_vacc_manuf_desc,
                            dosage_admin_in         => i_dosage_admin,
                            dosage_unit_measure_in  => i_dosage_unit_measure,
                            flg_reported_in         => pk_alert_constant.g_yes);
    
        o_id_admin   := l_id_pat_vacc_adm;
        o_type_admin := 'V';
    
        IF i_id_drug IS NOT NULL
        THEN
            l_emb_id := i_id_drug;
        END IF;
    
        ts_pat_vacc_adm_det.ins(id_pat_vacc_adm_det_in    => seq_pat_vacc_adm_det.nextval,
                                id_pat_vacc_adm_in        => l_id_pat_vacc_adm,
                                dt_take_in                => l_dt_begin,
                                id_episode_in             => i_id_episode,
                                flg_status_in             => i_flg_status,
                                lot_number_in             => i_lot_number,
                                dt_expiration_in          => l_dt_expiration,
                                notes_advers_react_in     => i_notes_advers_react,
                                application_spot_in       => i_application_spot,
                                report_orig_in            => i_report_orig,
                                notes_in                  => i_notes,
                                emb_id_in                 => l_emb_id,
                                id_prof_writes_in         => i_prof.id,
                                dt_reg_in                 => g_sysdate_tstz,
                                id_pat_medication_list_in => NULL,
                                dt_next_take_in           => l_dt_next_take,
                                flg_type_date_in          => l_flg_type_date,
                                id_vacc_manufacturer_in   => i_vacc_manuf,
                                code_mvx_in               => i_vacc_manuf_desc,
                                flg_reported_in           => pk_alert_constant.g_yes,
                                id_information_source_in  => i_information_source,
                                id_vacc_funding_cat_in    => i_vacc_funding_cat,
                                id_vacc_funding_source_in => i_vacc_funding_source,
                                funding_source_desc_in    => i_funding_source_desc,
                                id_vacc_doc_vis_in        => i_doc_vis,
                                id_vacc_origin_in         => i_vacc_origin,
                                origin_desc_in            => i_vacc_origin_desc,
                                vacc_route_data_in        => i_adm_route,
                                id_administred_in         => i_administred,
                                administred_desc_in       => i_administred_desc,
                                dt_doc_delivery_tstz_in   => l_dt_doc_delivery_tstz,
                                id_vacc_adv_reaction_in   => i_advers_react,
                                doc_vis_desc_in           => i_doc_vis_desc,
                                application_spot_code_in  => i_application_spot_code,
                                id_reason_sus_in          => l_reason,
                                dt_suspended_in           => i_dt_suspended,
                                suspended_notes_in        => i_suspended_notes,
                                vers_in                   => l_version);
    
        OPEN c_adv_reaction(i_presc, g_flg_presc_other_vacc);
        FETCH c_adv_reaction
            INTO r_adv_reaction;
        IF c_adv_reaction%FOUND
        THEN
            UPDATE vacc_advers_react var
               SET var.flg_status = pk_alert_constant.g_inactive
             WHERE var.id_reg = i_presc;
        END IF;
    
        --dados para actualizar "Actualizar datas de 1� observa��o m�dica..."
        --Checklist - 16
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate,
                                      i_dt_first_obs        => g_sysdate,
                                      o_error               => o_error)
        THEN
            --o_error := l_error;
            ROLLBACK;
            RETURN FALSE;
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
                                              'PK_VACC',
                                              'SET_PAT_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END set_pat_report;

    /********************************************************************************************
    * Return name of vaccine with date of dose adminstration 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_vacc         Vaccine id
    * @param IN   i_drug            Drug prescription ID
    *
    * @param OUT  o_desc            Return name of vaccine with date of dose adminstration 
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_adm_take_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_drug    IN drug_prescription.id_drug_prescription%TYPE,
        o_desc    OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_title    VARCHAR2(1000 CHAR);
        l_label    VARCHAR2(100 CHAR);
        l_subtitle VARCHAR2(2000 CHAR);
        l_date     VARCHAR2(100 CHAR);
    BEGIN
    
        l_label := pk_message.get_message(i_lang, g_administration_label);
    
        SELECT pk_date_utils.date_char_tsz(i_lang, dp.dt_begin_tstz, i_prof.institution, i_prof.software)
          INTO l_date
          FROM drug_prescription dp
         WHERE dp.id_drug_prescription = i_drug;
    
        SELECT pk_translation.get_translation(i_lang, v.code_vacc),
               pk_translation.get_translation(i_lang, v.code_desc_vacc)
          INTO l_title, l_subtitle
          FROM vacc v
         WHERE v.id_vacc = i_id_vacc;
    
        o_desc := l_title || ' (' || l_subtitle || '); ' || l_label || ': ' || l_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_vacc_adm_take_desc;

    /********************************************************************************************
    * Return name of vaccine with date of dose report 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_vacc         Vaccine id
    * @param IN   i_pat_vacc_adm    Report prescription ID
    *
    * @param OUT  o_desc            Return name of vaccine with date of dose report 
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_rep_take_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vacc      IN vacc.id_vacc%TYPE,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_desc         OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_title    VARCHAR2(1000 CHAR);
        l_label    VARCHAR2(100 CHAR);
        l_subtitle VARCHAR2(2000 CHAR);
        l_date     VARCHAR2(100 CHAR);
    BEGIN
    
        l_label := pk_message.get_message(i_lang, g_administration_label);
    
        SELECT pk_date_utils.date_char_tsz(i_lang, pva.dt_pat_vacc_adm, i_prof.institution, i_prof.software)
          INTO l_date
          FROM pat_vacc_adm pva
         WHERE pva.id_pat_vacc_adm = i_pat_vacc_adm;
    
        SELECT pk_translation.get_translation(i_lang, v.code_vacc),
               pk_translation.get_translation(i_lang, v.code_desc_vacc)
          INTO l_title, l_subtitle
          FROM vacc v
         WHERE v.id_vacc = i_id_vacc;
    
        o_desc := l_title || ' (' || l_subtitle || '); ' || l_label || ': ' || l_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_vacc_rep_take_desc;

    FUNCTION get_has_adm_canceled(i_drug IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        SELECT pk_alert_constant.g_yes
          INTO l_status
          FROM drug_prescription dp
         WHERE (dp.id_drug_prescription = i_drug OR dp.id_parent = i_drug)
           AND dp.flg_status = pk_alert_constant.g_cancelled;
    
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_has_adm_canceled;

    FUNCTION get_has_rep_canceled(i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        SELECT pk_alert_constant.g_yes
          INTO l_status
          FROM pat_vacc_adm pva
         WHERE (pva.id_pat_vacc_adm = i_pat_vacc_adm OR pva.id_parent = i_pat_vacc_adm)
           AND pva.flg_status = pk_alert_constant.g_cancelled;
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_has_rep_canceled;

    /************************************************************************************************************
    * This function returns the details for all takes for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_vacc_id            vaccine's id
    *
    * @param      o_adm                detail of administration (Date of administration)
    * @param      o_desc               cursor with the description details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/
    FUNCTION get_vacc_details
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        o_adm     OUT pk_types.cursor_type,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_version         mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_vacc_type_group vacc_type_group.id_vacc_type_group%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF NOT get_vacc_type_group(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_flg_presc_type => g_flg_presc_pnv, -- vacinas do PNV
                                   o_type_group     => l_vacc_type_group,
                                   o_error          => o_error)
        THEN
            RETURN TRUE;
        END IF;
    
        OPEN o_adm FOR
        
            SELECT id,
                   pk_message.get_message(i_lang, decode(title, g_vaccine_title, g_vacc_discontinue, g_vacc_adm)) || ':' title,
                   subtitle,
                   decode(flg_type_date,
                          g_year,
                          pk_vacc.get_year_from_timestamp(vacc_date),
                          g_month,
                          pk_date_utils.get_month_year(i_lang, i_prof, vacc_date),
                          g_day,
                          pk_date_utils.date_chr_short_read_tsz(i_lang, vacc_date, i_prof.institution, i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, vacc_date, i_prof.institution, i_prof.software)) dt,
                   decode(vacc_status,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_active) flg_state
              FROM (SELECT dpp.dt_take_tstz vacc_date,
                           dpp.dt_take_tstz vacc_date_order,
                           dp.id_drug_prescription id,
                           get_has_adm_canceled(dp.id_drug_prescription) vacc_status,
                           g_administration_title title,
                           '' subtitle,
                           dpp.flg_type_date flg_type_date
                      FROM drug_prescription dp
                      JOIN drug_presc_det dpd
                        ON dp.id_drug_prescription = dpd.id_drug_prescription
                      JOIN drug_presc_plan dpp
                        ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.flg_status <> pk_alert_constant.g_cancelled
                      JOIN mi_med mim
                        ON dpd.id_drug = mim.id_drug
                       AND mim.vers = l_version
                       AND mim.flg_available = pk_alert_constant.g_yes
                      JOIN vacc_dci vd
                        ON vd.id_dci = mim.dci_id
                      JOIN vacc v
                        ON v.id_vacc = vd.id_vacc
                      JOIN vacc_group vg
                        ON vg.id_vacc = v.id_vacc
                       AND vg.id_vacc_type_group = l_vacc_type_group
                      JOIN vacc_group_soft_inst vgsi
                        ON vgsi.id_vacc_group = vg.id_vacc_group
                       AND vgsi.id_institution = i_prof.institution
                       AND vgsi.id_software = i_prof.software
                     WHERE dp.id_patient = i_patient
                       AND vd.id_vacc = i_id_vacc
                       AND dp.id_parent IS NULL
                    UNION ALL
                    SELECT pvad.dt_take vacc_date,
                           pvad.dt_take vacc_date_order,
                           pva.id_pat_vacc_adm id,
                           get_has_rep_canceled(pva.id_pat_vacc_adm) vacc_status,
                           g_administration_title title,
                           '' subtitle,
                           pvad.flg_type_date flg_type_date
                      FROM pat_vacc_adm pva
                      JOIN pat_vacc_adm_det pvad
                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                     WHERE pva.id_vacc = i_id_vacc
                       AND pva.id_patient = i_patient
                       AND pva.id_parent IS NULL
                       AND pva.flg_status NOT IN (g_status_r, g_status_s)
                    UNION ALL
                    SELECT NULL vacc_date,
                           pvad.dt_suspended vacc_date_order,
                           pva.id_pat_vacc_adm id,
                           pk_alert_constant.g_active vacc_status,
                           g_administration_title title,
                           pk_message.get_message(i_lang, g_vacc_sub_title_discontinue) subtitle,
                           'H' flg_type_date
                      FROM pat_vacc_adm pva
                      JOIN pat_vacc_adm_det pvad
                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                     WHERE pva.id_vacc = i_id_vacc
                       AND pva.id_patient = i_patient
                       AND pva.id_parent IS NULL
                       AND pva.flg_status = (g_status_s)
                    UNION ALL
                    SELECT NULL vacc_date,
                           g_sysdate_tstz vacc_date_order,
                           pvh.id_vacc id,
                           pk_alert_constant.g_active vacc_status,
                           g_vaccine_title title,
                           '' subtitle,
                           'H' flg_type_date
                      FROM pat_vacc_hist pvh
                     WHERE pvh.id_vacc = i_id_vacc
                       AND pvh.id_patient = i_patient
                       AND pvh.flg_status = g_status_s
                       AND rownum = 1)
             ORDER BY vacc_date_order DESC;
    
        OPEN o_desc FOR
            SELECT id, id_parent, title, description
              FROM (SELECT dp.create_time vacc_reg,
                           dp.id_drug_prescription id,
                           nvl(dp.id_parent, dp.id_drug_prescription) id_parent,
                           get_description_adm_detail(i_lang => i_lang,
                                                      i_prof => i_prof,
                                                      i_drug => dp.id_drug_prescription,
                                                      i_vacc => v.id_vacc) description,
                           decode(dp.id_parent,
                                  NULL,
                                  pk_message.get_message(i_lang, g_adm_title_details),
                                  pk_message.get_message(i_lang, g_adm_edit_title_details)) title
                      FROM drug_prescription dp
                      JOIN drug_presc_det dpd
                        ON dp.id_drug_prescription = dpd.id_drug_prescription
                      JOIN drug_presc_plan dpp
                        ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.flg_status <> pk_alert_constant.g_cancelled
                      JOIN mi_med mim
                        ON dpd.id_drug = mim.id_drug
                       AND mim.vers = l_version
                       AND mim.flg_available = pk_alert_constant.g_yes
                      JOIN vacc_dci vd
                        ON vd.id_dci = mim.dci_id
                      JOIN vacc v
                        ON v.id_vacc = vd.id_vacc
                      JOIN vacc_group vg
                        ON vg.id_vacc = v.id_vacc
                       AND vg.id_vacc_type_group = l_vacc_type_group
                      JOIN vacc_group_soft_inst vgsi
                        ON vgsi.id_vacc_group = vg.id_vacc_group
                       AND vgsi.id_institution = i_prof.institution
                       AND vgsi.id_software = i_prof.software
                     WHERE dp.id_patient = i_patient
                       AND vd.id_vacc = i_id_vacc
                    UNION ALL
                    SELECT pva.create_time vacc_reg,
                           pva.id_pat_vacc_adm id,
                           nvl(pva.id_parent, pva.id_pat_vacc_adm) id_parent,
                           get_description_report_detail(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_pat_vacc_adm => pva.id_pat_vacc_adm,
                                                         i_vacc         => pva.id_vacc) description,
                           decode(pva.id_parent,
                                  NULL,
                                  pk_message.get_message(i_lang, g_rep_title_details),
                                  pk_message.get_message(i_lang, g_rep_edit_title_details)) title
                      FROM pat_vacc_adm pva
                      JOIN pat_vacc_adm_det pvad
                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                     WHERE pva.id_vacc = i_id_vacc
                       AND pva.id_patient = i_patient
                       AND pva.flg_status NOT IN (g_status_r, g_status_s)
                    --Canceled
                    UNION ALL
                    SELECT dp.dt_cancel_tstz vacc_reg,
                           dp.id_drug_prescription id,
                           nvl(dp.id_parent, dp.id_drug_prescription) id_parent,
                           get_desc_adm_cancel_detail(i_lang => i_lang,
                                                      i_prof => i_prof,
                                                      i_drug => dp.id_drug_prescription) description,
                           pk_message.get_message(i_lang, g_cancel_title_details) title
                      FROM drug_prescription dp
                      JOIN drug_presc_det dpd
                        ON dp.id_drug_prescription = dpd.id_drug_prescription
                      JOIN drug_presc_plan dpp
                        ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
                       AND dpp.flg_status <> pk_alert_constant.g_cancelled
                      JOIN mi_med mim
                        ON dpd.id_drug = mim.id_drug
                       AND mim.vers = l_version
                       AND mim.flg_available = pk_alert_constant.g_yes
                      JOIN vacc_dci vd
                        ON vd.id_dci = mim.dci_id
                      JOIN vacc v
                        ON v.id_vacc = vd.id_vacc
                      JOIN vacc_group vg
                        ON vg.id_vacc = v.id_vacc
                       AND vg.id_vacc_type_group = l_vacc_type_group
                      JOIN vacc_group_soft_inst vgsi
                        ON vgsi.id_vacc_group = vg.id_vacc_group
                       AND vgsi.id_institution = i_prof.institution
                       AND vgsi.id_software = i_prof.software
                     WHERE dp.id_patient = i_patient
                       AND vd.id_vacc = i_id_vacc
                       AND dp.flg_status = pk_alert_constant.g_cancelled
                    UNION ALL
                    SELECT pva.dt_cancel vacc_reg,
                           pva.id_pat_vacc_adm id,
                           nvl(pva.id_parent, pva.id_pat_vacc_adm) id_parent,
                           get_desc_rep_cancel_detail(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_pat_vacc_adm => pva.id_pat_vacc_adm) description,
                           pk_message.get_message(i_lang, g_cancel_title_details) title
                      FROM pat_vacc_adm pva
                      JOIN pat_vacc_adm_det pvad
                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                     WHERE pva.id_vacc = i_id_vacc
                       AND pva.id_patient = i_patient
                       AND pva.flg_status = pk_alert_constant.g_cancelled
                    --Vaccine discontinue/resume
                    UNION ALL
                    SELECT pvh.dt_status vacc_reg,
                           pvh.id_pat_vacc_hist id,
                           pvh.id_vacc id_parent,
                           get_desc_disc_detail(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_pat_vacc_hist => pvh.id_pat_vacc_hist) description,
                           decode(pvh.flg_status,
                                  g_status_s,
                                  pk_message.get_message(i_lang, g_vacc_title_discontinue),
                                  pk_message.get_message(i_lang, g_vacc_title_resume)) title
                      FROM pat_vacc_hist pvh
                     WHERE pvh.id_vacc = i_id_vacc
                       AND pvh.id_patient = i_patient
                       AND pvh.flg_status IN (g_status_s, g_status_a)
                    --Dose discontinue/resume 
                    UNION ALL
                    SELECT decode(pva.flg_status, g_status_s, pvad.dt_suspended, pvad.dt_reg) vacc_reg,
                           pva.id_pat_vacc_adm id,
                           nvl(pva.id_parent, pva.id_pat_vacc_adm) id_parent,
                           get_desc_disc_dose_detail(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_pat_vacc_adm => pva.id_pat_vacc_adm) description,
                           decode(pva.flg_status,
                                  g_status_r,
                                  pk_message.get_message(i_lang, g_vacc_title_resume),
                                  pk_message.get_message(i_lang, g_vacc_title_discontinue)) title
                      FROM pat_vacc_adm pva
                      JOIN pat_vacc_adm_det pvad
                        ON pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
                     WHERE pva.id_vacc = i_id_vacc
                       AND pva.id_patient = i_patient
                       AND pva.flg_status IN (g_status_r, g_status_s)
                    --Adverse Reaction
                    UNION ALL
                    SELECT adv.dt_prof_write vacc_reg,
                           id,
                           nvl(adv.id_parent, adv.id) id_parent,
                           get_description_detail(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_id_prof => adv.id_prof_write,
                                                  i_labels  => table_varchar2(g_adv_reaction_details),
                                                  i_res     => table_varchar2(decode(id_vacc,
                                                                                     g_other_value,
                                                                                     notes_advers_react,
                                                                                     get_adv_reactions_description(i_lang,
                                                                                                                   id_vacc))),
                                                  i_dt      => adv.dt_prof_write,
                                                  i_updated => pk_alert_constant.g_yes) description,
                           pk_message.get_message(i_lang, g_vacc_title_adv_react) title
                      FROM (SELECT var.id_reg             id,
                                   pva.id_parent          id_parent,
                                   var.id_vacc_adver_reac id_vacc,
                                   pva.dt_pat_vacc_adm    dt_begin,
                                   var.*
                              FROM vacc_advers_react var
                              JOIN pat_vacc_adm pva
                                ON pva.id_pat_vacc_adm = var.id_reg
                               AND pva.id_patient = i_patient
                            UNION ALL
                            SELECT dp.id_drug_prescription id,
                                   dp.id_parent            id_parent,
                                   var.id_vacc_adver_reac  id_vacc,
                                   dp.dt_begin_tstz        dt_begin,
                                   var.*
                            
                              FROM vacc_advers_react var
                              JOIN drug_presc_plan dpp
                                ON dpp.id_drug_presc_plan = var.id_reg
                              JOIN drug_presc_det dpd
                                ON dpd.id_drug_presc_det = dpp.id_drug_presc_det
                              JOIN drug_prescription dp
                                ON dp.id_drug_prescription = dpd.id_drug_prescription
                               AND dp.id_patient = i_patient) adv)
             ORDER BY vacc_reg DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_DETAILS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_adm);
            pk_types.open_my_cursor(o_desc);
        
            RETURN FALSE;
    END get_vacc_details;

    /************************************************************************************************************
    * This function 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/
    FUNCTION get_description_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_labels  IN table_varchar2,
        i_res     IN table_varchar2,
        i_dt      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_updated IN VARCHAR2
    ) RETURN CLOB IS
        l_ret   CLOB := '';
        l_state sys_message.desc_message%TYPE;
    BEGIN
    
        FOR i IN 1 .. i_labels.count
        LOOP
            IF i_res(i) IS NOT NULL
            THEN
                l_ret := l_ret || '<b>' || pk_message.get_message(i_lang, i_labels(i)) || ': </b>' || i_res(i) ||
                         '<br>';
            END IF;
        
        END LOOP;
    
        IF i_updated = pk_alert_constant.g_yes
        THEN
            l_state := pk_message.get_message(i_lang, g_updated_details);
        ELSE
            l_state := pk_message.get_message(i_lang, g_documented_details);
        END IF;
    
        l_ret := l_ret || '<i>' || l_state || ' ' || pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof) || '; ' ||
                 pk_date_utils.date_char_tsz(i_lang, i_dt, i_prof.institution, i_prof.software) || '</i><br>';
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_description_detail;

    /************************************************************************************************************
    * This function 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/
    FUNCTION get_description_report_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE
    ) RETURN CLOB IS
        l_vacc          VARCHAR2(4000 CHAR);
        l_adm_date      VARCHAR2(100 CHAR);
        l_adm_dose      VARCHAR2(4000 CHAR);
        l_adm_route     VARCHAR2(4000 CHAR);
        l_adm_site      VARCHAR2(4000 CHAR);
        l_manufactured  VARCHAR2(4000 CHAR);
        l_lot           VARCHAR2(4000 CHAR);
        l_exp_date      VARCHAR2(100 CHAR);
        l_origin        VARCHAR2(4000 CHAR);
        l_doc_type      VARCHAR2(4000 CHAR);
        l_doc_date      VARCHAR2(100 CHAR);
        l_doc_cat       VARCHAR2(4000 CHAR);
        l_doc_source    VARCHAR2(4000 CHAR);
        l_info          VARCHAR2(4000 CHAR);
        l_adm_by        VARCHAR2(4000 CHAR);
        l_next_dose     VARCHAR2(100 CHAR);
        l_adv_reactions VARCHAR2(4000 CHAR);
        l_notes         VARCHAR2(4000 CHAR);
        l_has_updated   VARCHAR2(1 CHAR);
    
        l_label_array table_varchar2;
        l_res_array   table_varchar2;
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_prof        professional.id_professional%TYPE;
    BEGIN
    
        SELECT get_vacc_description(i_lang, i_prof, pvad.emb_id, pva.id_vacc) vac_desc,
               decode(pvad.flg_type_date,
                      g_year,
                      pk_vacc.get_year_from_timestamp(pvad.dt_take),
                      g_month,
                      pk_date_utils.get_month_year(i_lang, i_prof, pvad.dt_take),
                      g_day,
                      pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software),
                      pk_date_utils.date_char_tsz(i_lang, pvad.dt_take, i_prof.institution, i_prof.software)) admdate_desc,
               --pk_date_utils.date_char_tsz(i_lang, pva.dt_pat_vacc_adm, i_prof.institution, i_prof.software) admdate_desc,
               nvl(TRIM(pk_utils.to_str(pva.dosage_admin) || ' ' ||
                        pk_unit_measure.get_unit_measure_description(i_lang, i_prof, pva.dosage_unit_measure)),
                   '') admdose_desc,
               get_vacc_route_description(i_lang, i_prof, pvad.emb_id, pvad.vacc_route_data) admroute_desc,
               nvl(pvad.application_spot,
                   pk_sysdomain.get_domain_no_avail(g_domain_application_spot, pvad.application_spot_code, i_lang)) admsite_desc,
               nvl(pvad.code_mvx, get_manufacturer_description(i_lang, pvad.id_vacc_manufacturer)) manufacturer_desc,
               pvad.lot_number lot_desc,
               pk_date_utils.date_chr_short_read(i_lang, pvad.dt_expiration, i_prof) expdate_desc,
               nvl(pvad.origin_desc, get_origin_description(i_lang, pvad.id_vacc_origin)) origin_desc,
               nvl(pvad.doc_vis_desc, get_doc_description(i_lang, i_prof, pvad.id_vacc_doc_vis)) doctype_desc,
               pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_doc_delivery_tstz, i_prof) docdate_desc,
               get_vacc_cat_description(i_lang, pvad.id_vacc_funding_cat) doccat_desc,
               nvl(pvad.funding_source_desc, get_vacc_source_description(i_lang, pvad.id_vacc_funding_source)) docsource_desc,
               nvl(pvad.report_orig, get_vacc_report_description(i_lang, pvad.id_information_source)) information_desc,
               nvl(pvad.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, pvad.id_administred)) admby_desc,
               decode(pvad.dt_next_take,
                      '',
                      pk_message.get_message(i_lang, g_vacc_no_app),
                      pk_date_utils.date_chr_short_read_tsz(i_lang, pvad.dt_next_take, i_prof)) nextdose_desc,
               get_adv_reactions_description(i_lang, pvad.id_vacc_adv_reaction) advreaction_desc,
               pvad.notes admnotes_desc,
               pva.create_time,
               pva.id_prof_writes,
               decode(pva.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_vacc,
               l_adm_date,
               l_adm_dose,
               l_adm_route,
               l_adm_site,
               l_manufactured,
               l_lot,
               l_exp_date,
               l_origin,
               l_doc_type,
               l_doc_date,
               l_doc_cat,
               l_doc_source,
               l_info,
               l_adm_by,
               l_next_dose,
               l_adv_reactions,
               l_notes,
               l_date,
               l_prof,
               l_has_updated
          FROM pat_vacc_adm pva
          JOIN pat_vacc_adm_det pvad
            ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
         WHERE pvad.id_pat_vacc_adm = i_pat_vacc_adm
           AND pva.id_vacc = i_vacc;
    
        l_label_array := NEW table_varchar2(g_name_vacc_details,
                                            g_adm_details,
                                            g_adm_dose_details,
                                            g_adm_route_details,
                                            g_adm_site_details,
                                            g_manufactured_details,
                                            g_lot_details,
                                            g_exp_date_details,
                                            g_origin_details,
                                            g_doc_vis_details,
                                            g_doc_vis_date_details,
                                            g_doc_cat_details,
                                            g_doc_source_details,
                                            g_information_source_details,
                                            g_adm_by_details,
                                            g_next_dose_details,
                                            g_adv_reaction_details,
                                            g_notes_details);
    
        l_res_array := NEW table_varchar2(l_vacc,
                                          l_adm_date,
                                          l_adm_dose,
                                          l_adm_route,
                                          l_adm_site,
                                          l_manufactured,
                                          l_lot,
                                          l_exp_date,
                                          l_origin,
                                          l_doc_type,
                                          l_doc_date,
                                          l_doc_cat,
                                          l_doc_source,
                                          l_info,
                                          l_adm_by,
                                          l_next_dose,
                                          l_adv_reactions,
                                          l_notes);
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => l_has_updated);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_description_report_detail;

    FUNCTION get_description_adm_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN CLOB IS
        l_vacc          VARCHAR2(4000 CHAR);
        l_adm_date      VARCHAR2(100 CHAR);
        l_adm_dose      VARCHAR2(4000 CHAR);
        l_adm_route     VARCHAR2(4000 CHAR);
        l_adm_site      VARCHAR2(4000 CHAR);
        l_manufactured  VARCHAR2(4000 CHAR);
        l_lot           VARCHAR2(4000 CHAR);
        l_exp_date      VARCHAR2(100 CHAR);
        l_origin        VARCHAR2(4000 CHAR);
        l_doc_type      VARCHAR2(4000 CHAR);
        l_doc_date      VARCHAR2(100 CHAR);
        l_doc_cat       VARCHAR2(4000 CHAR);
        l_doc_source    VARCHAR2(4000 CHAR);
        l_ordered       VARCHAR2(4000 CHAR);
        l_adm_by        VARCHAR2(4000 CHAR);
        l_next_dose     VARCHAR2(100 CHAR);
        l_adv_reactions VARCHAR2(4000 CHAR);
        l_notes         VARCHAR2(4000 CHAR);
        l_prof          professional.id_professional%TYPE;
        l_has_updated   VARCHAR2(1 CHAR);
        l_label_array   table_varchar2;
        l_res_array     table_varchar2;
    
        l_version mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        l_date TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
        SELECT get_vacc_description(i_lang, i_prof, dpd.id_drug, v.id_vacc) vac_desc,
               decode(dpp.flg_type_date,
                      g_year,
                      pk_vacc.get_year_from_timestamp(dpp.dt_take_tstz),
                      g_month,
                      pk_date_utils.get_month_year(i_lang, i_prof, dpp.dt_take_tstz),
                      g_day,
                      pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                            dpp.dt_take_tstz,
                                                            i_prof.institution,
                                                            i_prof.software),
                      pk_date_utils.date_char_tsz(i_lang, dpp.dt_take_tstz, i_prof.institution, i_prof.software)) admdate_desc,
               nvl(TRIM(pk_utils.to_str(dpp.dosage) || ' ' ||
                        pk_unit_measure.get_unit_measure_description(i_lang, i_prof, dpp.dosage_unit_measure)),
                   '') admdose_desc,
               get_vacc_route_description(i_lang, i_prof, dpd.id_drug, dpp.vacc_route_data) admroute_desc,
               nvl(dpp.application_spot,
                   pk_sysdomain.get_domain_no_avail(g_domain_application_spot, dpp.application_spot_code, i_lang)) admsite_desc,
               nvl(dpd.code_mvx, get_manufacturer_description(i_lang, dpd.id_vacc_manufacturer)) manufacturer_desc,
               dpp.lot_number lot_desc,
               pk_date_utils.date_chr_short_read(i_lang, dpp.dt_expiration, i_prof) expdate_desc,
               nvl(dpp.origin_desc, get_origin_description(i_lang, dpp.id_vacc_origin)) origin_desc,
               nvl(dpp.doc_vis_desc, get_doc_description(i_lang, i_prof, dpp.id_vacc_doc_vis)) doctype_desc,
               pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_doc_delivery_tstz, i_prof) docdate_desc,
               get_vacc_cat_description(i_lang, dpp.id_vacc_funding_cat) doccat_desc,
               nvl(dpp.funding_source_desc, get_vacc_source_description(i_lang, dpp.id_vacc_funding_source)) docsource_desc,
               nvl(dpp.ordered_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_ordered)) orderby_desc,
               nvl(dpp.administred_desc, pk_prof_utils.get_name_signature(i_lang, i_prof, dpp.id_administred)) admby_desc,
               decode(dpp.dt_next_take,
                      '',
                      pk_message.get_message(i_lang, g_vacc_no_app),
                      pk_date_utils.date_chr_short_read_tsz(i_lang, dpp.dt_next_take, i_prof)) nextdose_desc,
               get_adv_reactions_description(i_lang, dpp.id_vacc_adv_reaction) advreaction_desc,
               dpp.notes admnotes_desc,
               dp.create_time,
               dpp.id_prof_writes,
               decode(dp.id_parent, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_vacc,
               l_adm_date,
               l_adm_dose,
               l_adm_route,
               l_adm_site,
               l_manufactured,
               l_lot,
               l_exp_date,
               l_origin,
               l_doc_type,
               l_doc_date,
               l_doc_cat,
               l_doc_source,
               l_ordered,
               l_adm_by,
               l_next_dose,
               l_adv_reactions,
               l_notes,
               l_date,
               l_prof,
               l_has_updated
          FROM drug_prescription dp
          JOIN drug_presc_det dpd
            ON dpd.id_drug_prescription = dp.id_drug_prescription
          JOIN drug_presc_plan dpp
            ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
           AND dpp.flg_status <> pk_alert_constant.g_cancelled
          JOIN mi_med mim
            ON dpd.id_drug = mim.id_drug
           AND mim.flg_available = pk_alert_constant.g_yes
           AND mim.vers = l_version
          JOIN vacc_dci vd
            ON vd.id_dci = mim.dci_id
          JOIN vacc v
            ON v.id_vacc = vd.id_vacc
         WHERE dp.id_drug_prescription = i_drug
           AND v.id_vacc = i_vacc;
    
        l_label_array := NEW table_varchar2(g_name_vacc_details,
                                            g_adm_details,
                                            g_adm_dose_details,
                                            g_adm_route_details,
                                            g_adm_site_details,
                                            g_manufactured_details,
                                            g_lot_details,
                                            g_exp_date_details,
                                            g_origin_details,
                                            g_doc_vis_details,
                                            g_doc_vis_date_details,
                                            g_doc_cat_details,
                                            g_doc_source_details,
                                            g_ordered_details,
                                            g_adm_by_details,
                                            g_next_dose_details,
                                            g_adv_reaction_details,
                                            g_notes_details);
    
        l_res_array := NEW table_varchar2(l_vacc,
                                          l_adm_date,
                                          l_adm_dose,
                                          l_adm_route,
                                          l_adm_site,
                                          l_manufactured,
                                          l_lot,
                                          l_exp_date,
                                          l_origin,
                                          l_doc_type,
                                          l_doc_date,
                                          l_doc_cat,
                                          l_doc_source,
                                          l_ordered,
                                          l_adm_by,
                                          l_next_dose,
                                          l_adv_reactions,
                                          l_notes);
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => l_has_updated);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_description_adm_detail;

    FUNCTION get_desc_adm_cancel_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE
    ) RETURN CLOB IS
        l_prof_cancel VARCHAR2(4000 CHAR);
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_notes       VARCHAR2(4000 CHAR);
        l_reason      VARCHAR2(4000 CHAR);
    
        l_label_array table_varchar2;
        l_res_array   table_varchar2;
    
    BEGIN
        SELECT dpp.id_prof_cancel,
               dpp.dt_cancel_tstz,
               dpp.notes_cancel,
               pk_translation.get_translation(i_lang, cr.code_cancel_reason)
          INTO l_prof_cancel, l_date, l_notes, l_reason
          FROM drug_prescription dp
          JOIN drug_presc_det dpd
            ON dpd.id_drug_prescription = dp.id_drug_prescription
          JOIN drug_presc_plan dpp
            ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
           AND dpp.flg_status <> pk_alert_constant.g_cancelled
          LEFT JOIN cancel_reason cr
            ON cr.id_cancel_reason = dpp.id_cancel_reason
         WHERE dp.id_drug_prescription = i_drug;
    
        l_label_array := NEW table_varchar2(g_cancel_reason_details, g_cancel_notes_details);
    
        l_res_array := NEW table_varchar2(l_reason, l_notes);
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof_cancel,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => pk_alert_constant.g_yes);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_desc_adm_cancel_detail;

    FUNCTION get_desc_rep_cancel_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB IS
        l_prof_cancel VARCHAR2(4000 CHAR);
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_notes       VARCHAR2(4000 CHAR);
        l_reason      VARCHAR2(4000 CHAR);
    
        l_label_array table_varchar2;
        l_res_array   table_varchar2;
    
    BEGIN
        SELECT pvad.id_prof_cancel,
               pvad.dt_cancel,
               pvad.notes_cancel,
               pk_translation.get_translation(i_lang, cr.code_cancel_reason)
          INTO l_prof_cancel, l_date, l_notes, l_reason
          FROM pat_vacc_adm pva
          JOIN pat_vacc_adm_det pvad
            ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
          LEFT JOIN cancel_reason cr
            ON cr.id_cancel_reason = pvad.id_cancel_reason
         WHERE pvad.id_pat_vacc_adm = i_pat_vacc_adm;
    
        l_label_array := NEW table_varchar2(g_cancel_reason_details, g_cancel_notes_details);
    
        l_res_array := NEW table_varchar2(l_reason, l_notes);
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof_cancel,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => pk_alert_constant.g_yes);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_desc_rep_cancel_detail;

    FUNCTION get_desc_disc_dose_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB IS
        l_prof      VARCHAR2(4000 CHAR);
        l_date      TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_notes     VARCHAR2(4000 CHAR);
        l_reason    VARCHAR2(4000 CHAR);
        l_next_date VARCHAR2(100 CHAR);
    
        l_label_array table_varchar2;
        l_res_array   table_varchar2;
    
    BEGIN
        SELECT pva.id_prof_writes,
               decode(pva.flg_status, g_status_s, pvad.dt_suspended, pvad.dt_reg),
               pvad.suspended_notes,
               pk_not_order_reason_db.get_not_order_reason_desc(i_lang, pvad.id_reason_sus),
               get_next_take_date(i_lang => i_lang, i_prof => i_prof, i_id_pat => pva.id_patient, i_vacc => pva.id_vacc)
          INTO l_prof, l_date, l_notes, l_reason, l_next_date
          FROM pat_vacc_adm pva
          JOIN pat_vacc_adm_det pvad
            ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
         WHERE pvad.id_pat_vacc_adm = i_pat_vacc_adm;
    
        l_label_array := NEW table_varchar2(g_reason, g_notes_details, g_vacc_dose_sch_details);
        l_res_array   := NEW table_varchar2(l_reason,
                                            l_notes,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        l_next_date,
                                                                        i_prof.institution,
                                                                        i_prof.software));
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => pk_alert_constant.g_yes);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_desc_disc_dose_detail;

    FUNCTION get_desc_disc_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_vacc_hist IN pat_vacc_hist.id_pat_vacc_hist%TYPE
    ) RETURN CLOB IS
        l_prof_cancel VARCHAR2(4000 CHAR);
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_notes       VARCHAR2(4000 CHAR);
        l_reason      VARCHAR2(4000 CHAR);
    
        l_label_array table_varchar2;
        l_res_array   table_varchar2;
    
    BEGIN
        SELECT pvh.id_prof_status,
               pvh.dt_status,
               pvh.notes,
               pk_not_order_reason_db.get_not_order_reason_desc(i_lang, pvh.id_reason)
          INTO l_prof_cancel, l_date, l_notes, l_reason
          FROM pat_vacc_hist pvh
         WHERE pvh.id_pat_vacc_hist = i_pat_vacc_hist;
    
        l_label_array := NEW table_varchar2(g_cancel_reason_details, g_cancel_notes_details);
    
        l_res_array := NEW table_varchar2(l_reason, l_notes);
    
        RETURN get_description_detail(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_id_prof => l_prof_cancel,
                                      i_labels  => l_label_array,
                                      i_res     => l_res_array,
                                      i_dt      => l_date,
                                      i_updated => pk_alert_constant.g_yes);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_desc_disc_detail;

    FUNCTION set_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_status     IN pat_vacc.flg_status%TYPE,
        i_id_reason  IN pat_vacc_hist.id_reason%TYPE,
        i_notes      IN pat_vacc_hist.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'UPDATE pat_vacc';
    
        UPDATE pat_vacc pv
           SET pv.flg_status     = i_status,
               pv.id_prof_status = i_prof.id,
               pv.dt_status      = g_sysdate_tstz,
               pv.id_reason      = i_id_reason,
               pv.notes          = i_notes
         WHERE pv.id_vacc = i_vacc
           AND pv.id_patient = i_id_patient;
    
        g_error := 'UPDATE pat_vacc';
        INSERT INTO pat_vacc_hist
            (id_pat_vacc_hist, id_vacc, id_patient, flg_status, id_prof_status, dt_status, id_reason, notes)
        VALUES
            (seq_pat_vacc_hist.nextval,
             i_vacc,
             i_id_patient,
             i_status,
             i_prof.id,
             g_sysdate_tstz,
             i_id_reason,
             i_notes);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_status;

    FUNCTION set_vacc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_status     IN pat_vacc.flg_status%TYPE,
        i_id_reason  IN NUMBER,
        i_notes      IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count  NUMBER;
        l_reason not_order_reason.id_not_order_reason%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_count
          FROM pat_vacc pv
         WHERE pv.id_vacc = i_vacc
           AND pv.id_patient = i_id_patient;
    
        IF l_count = 0
        THEN
            -- insere as vacinas que faltam
            g_error := 'CALL ins_vacc';
            IF NOT ins_vacc(i_lang       => i_lang,
                            i_id_patient => i_id_patient,
                            i_vacc       => table_number(i_vacc),
                            i_prof       => i_prof,
                            i_episode    => i_episode,
                            o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        l_reason := NULL;
    
        IF i_id_reason IS NOT NULL
        THEN
            IF NOT pk_not_order_reason_db.set_not_order_reason(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_not_order_reason_ea => i_id_reason,
                                                               o_id_not_order_reason => l_reason,
                                                               o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- update vaccines status
        g_error := 'CALL set_status';
        IF NOT set_status(i_lang       => i_lang,
                          i_prof       => i_prof,
                          i_id_patient => i_id_patient,
                          i_vacc       => i_vacc,
                          i_status     => i_status,
                          i_id_reason  => l_reason,
                          i_notes      => i_notes,
                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'SET_VACC_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_vacc_status;

    /**
    * Get patient vaccine status.
    *
    * @param i_patient      logged professional structure
    * @param i_vacc         presc type flag
    *
    * @return               patient vaccine status
    *
    * @author               Elisabete Bugalho
    * @version               2.5.3
    * @since                2012/05/31
    */
    FUNCTION get_vacc_status
    (
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN pat_vacc.flg_status%TYPE IS
        l_ret pat_vacc.flg_status%TYPE;
    
        CURSOR c_status IS
            SELECT pv.flg_status
              FROM pat_vacc pv
             WHERE pv.id_patient = i_patient
               AND pv.id_vacc = i_vacc;
    BEGIN
        IF i_patient IS NULL
           OR i_vacc IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_status;
            FETCH c_status
                INTO l_ret;
            CLOSE c_status;
        
            IF l_ret IS NULL
            THEN
                l_ret := pk_alert_constant.g_active;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_vacc_status;

    FUNCTION has_active_option
    (
        i_status IN VARCHAR2,
        i_option IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1);
    
    BEGIN
    
        CASE i_status
            WHEN g_status_s THEN
                IF (i_option = 'VACC_RESUME')
                THEN
                    l_ret := pk_alert_constant.g_active;
                ELSE
                    l_ret := pk_alert_constant.g_inactive;
                END IF;
            WHEN pk_alert_constant.g_active THEN
                IF (i_option = 'VACC_RESUME')
                THEN
                    l_ret := pk_alert_constant.g_inactive;
                ELSE
                    l_ret := pk_alert_constant.g_active;
                END IF;
        END CASE;
    
        RETURN l_ret;
    END has_active_option;

    FUNCTION has_discontinue_vacc
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
    
        SELECT pk_alert_constant.g_yes
          INTO l_ret
          FROM pat_vacc pv
         WHERE pv.id_patient = i_pat
           AND pv.id_vacc = i_id_vacc
           AND pv.flg_status = g_status_s;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
        
            RETURN pk_alert_constant.g_no;
        
    END has_discontinue_vacc;

    FUNCTION has_discontinue_dose
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
    
        SELECT pk_alert_constant.g_yes
          INTO l_ret
          FROM pat_vacc_adm pva
          LEFT JOIN pat_vacc_adm_det pvad
            ON pvad.id_pat_vacc_adm = pva.id_pat_vacc_adm
         WHERE pva.id_patient = i_pat
           AND pva.id_vacc = i_id_vacc
           AND pvad.flg_status = g_status_s
           AND pva.id_parent NOT IN (SELECT pva1.id_parent
                                       FROM pat_vacc_adm pva1
                                      WHERE pva1.id_patient = i_pat
                                        AND pva1.id_vacc = i_id_vacc
                                        AND pva1.flg_status = g_status_r);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
        
            RETURN pk_alert_constant.g_no;
        
    END has_discontinue_dose;

    /********************************************************************************************
      * Return name of vaccine with last take 
        *
        * @param IN   i_lang            Language ID
        * @param IN   i_prof            Professional ID
        * @param IN   i_id_vacc         Vaccine id
        * @param IN   i_dose            Dose (-1 dose selected or null)
        *
        * @param OUT  Return name of vaccine with last take 
        *
        * @author                   Jorge Silva
        * @since                    05/05/2014
    ********************************************************************************************/
    FUNCTION get_vacc_descontinue_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_dose    IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                VARCHAR2(4000);
        l_title_abrev        VARCHAR2(4000);
        l_title              VARCHAR2(4000);
        l_dt_predicted_array table_varchar := table_varchar();
        l_predicted_take     pk_types.cursor_type;
        l_dummy_1            table_varchar;
        l_dt_predicted       VARCHAR2(200);
    
        l_next_dt TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, v.code_vacc),
               pk_translation.get_translation(i_lang, v.code_desc_vacc)
          INTO l_title_abrev, l_title
          FROM vacc v
         WHERE v.id_vacc = i_id_vacc;
    
        l_ret := l_title_abrev || ' (' || l_title || ')';
    
        IF (i_dose = -1)
        THEN
        
            l_next_dt := get_next_take_date(i_lang => i_lang, i_prof => i_prof, i_id_pat => i_pat, i_vacc => i_id_vacc);
        
            l_ret := l_ret || ' - ' || pk_message.get_message(i_lang, g_vacc_adm) || ': ' ||
                     pk_message.get_message(i_lang, g_vacc_sub_title_discontinue) || ' - ' ||
                     pk_date_utils.date_char_tsz(i_lang, l_next_dt, i_prof.institution, i_prof.software);
        
        END IF;
    
        o_desc := l_ret;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VACC',
                                              'GET_VACC_DESCONTINUE_DESC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vacc_descontinue_desc;

BEGIN
    --Inicializa��o do logger
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    g_sysdate      := SYSDATE;
    g_sysdate_tstz := current_timestamp;

END pk_vacc;
/