/*-- Last Change Revision: $Rev: 2050043 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-11-11 08:54:13 +0000 (sex, 11 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient IS

    e_call_error EXCEPTION;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_necess) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL necess, NULL id_necessity, NULL rank, NULL flg_status, NULL flg_comb
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /*
    * Return designated provider
    *
    * @param   i_lang                  language associated to the professional executing the request
    * @param   i_prof                  Professional info
    * @param   i_patient               patient identifier  
    * @param   i_episode               episode identifier  
    *
    * @RETURN  designated provider
    * @author  paulo teixeira
    * @version 2.5.1
    * @since   2010-10-19
    *
    */
    FUNCTION get_designated_provider
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_error         t_error_out;
        l_fam_phys_name professional.name%TYPE;
    BEGIN
        IF NOT pk_adt.get_pat_family_physician(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_patient       => i_patient,
                                               o_fam_phys_name => l_fam_phys_name,
                                               o_error         => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_fam_phys_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_designated_provider;

    /*
    * Return negative "julian" age for purpose of sorting in main grids. Formula only.
    *
    * @param   I_LANG              language associated to the professional executing the request
    * @param   i_dt_birth          date of birth of individual
    * @param   i_age               age of individual
    *
    * @RETURN  negative julian date if available, null if not available
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   15-FEB-2008
    *
    */
    FUNCTION get_julian_age
    (
        i_lang        language.id_language%TYPE,
        i_dt_birth    patient.dt_birth%TYPE,
        i_age         patient.age%TYPE,
        i_dt_deceased patient.dt_deceased%TYPE
    ) RETURN NUMBER IS
        l_year_format   VARCHAR2(4) := 'YYYY';
        l_julian_format VARCHAR2(4) := 'J';
        l_julian_age    NUMBER;
        k_max_value      CONSTANT NUMBER := '999999999999';
        k_months_in_year CONSTANT NUMBER := 12;
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE;
    BEGIN
    
        l_dt_birth    := i_dt_birth;
        l_dt_deceased := coalesce(i_dt_deceased, current_timestamp);
    
        --l_age := l_dt_deceased - l_dt_birth
        --l_julian_age := to_number(to_char(l_age, l_julian_format));
    
        l_julian_age := to_number(to_char(l_dt_deceased, l_julian_format));
    
        RETURN l_julian_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_julian_age;

    /*
    * Return negative "julian" age for purpose of sorting in main grids with patient id
    *
    * @param   I_LANG              language associated to the professional executing the request
    * @param   i_id_patient        id of patient
    *
    * @RETURN  negative julian date if available, null if not available
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   15-FEB-2008
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    09-03-2009
    * @version 2.5
    */
    FUNCTION get_julian_age
    (
        i_lang       language.id_language%TYPE,
        i_id_patient patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_error      t_error_out;
        l_julian_age NUMBER;
    BEGIN
        g_error := 'GET JULIAN AGE';
        SELECT pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) julian_age
          INTO l_julian_age
          FROM patient pat
         WHERE id_patient = i_id_patient;
    
        RETURN l_julian_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_JULIAN_AGE_P',
                                              l_error);
            RETURN NULL;
    END get_julian_age;

    /**
    * Return translated initial for the gender domain. Internally this functions does caching.
    *
    * @param i_lang language id
    * @param i_gender value of the patient.gender column
    */
    FUNCTION get_gender
    (
        i_lang   language.id_language%TYPE,
        i_gender patient.gender%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
    BEGIN
        RETURN pk_sysdomain.get_domain_cached(i_lang, i_gender, 'PATIENT.GENDER.ABBR');
    END;

    /*
    * Returns the patient's gender
    *
    * @param   i_id_patient        id of patient
    *
    * @return  String with the patients gender
    * @author  Joao Martins
    * @version 2.6.0.1
    * @since   26-Feb-2010
    */
    FUNCTION get_pat_gender(i_id_patient IN patient.id_patient%TYPE) RETURN patient.gender%TYPE IS
        l_gender patient.gender%TYPE;
    BEGIN
        g_error := 'GET PATIENT GENDER';
        SELECT gender
          INTO l_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        RETURN l_gender;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_gender;

    FUNCTION get_local_pat_info
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_name          OUT patient.name%TYPE,
        o_nick_name     OUT patient.nick_name%TYPE,
        o_gender        OUT patient.gender%TYPE,
        o_desc_gender   OUT VARCHAR2,
        o_dt_birth      OUT VARCHAR2,
        o_dt_birth_send OUT VARCHAR2,
        o_age           OUT VARCHAR2,
        o_dt_deceased   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar info do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               Saida:   O_NAME - PATIENT.NAME 
               O_NICK_NAME - PATIENT.NICK_NAME 
               O_GENDER - PATIENT.GENDER 
               O_DT_BIRTH - PATIENT.DT_BIRTH 
               O_AGE - idade calculada para o doente 
               O_DT_DECEASED - PATIENT.DT_DECEASED 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/02/24  
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        o_timezone timezone_region.timezone_region%TYPE;
        CURSOR c_pat IS
            SELECT p.name,
                   p.nick_name,
                   p.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, i_lang) desc_gender,
                   pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof) dt_birth,
                   pk_date_utils.dt_chr(i_lang, p.dt_deceased, i_prof) dt_deceased,
                   get_pat_age(i_lang, i_id_pat, i_prof) age,
                   pk_date_utils.date_send_str(i_lang,
                                               to_char(dt_birth, pk_date_utils.g_dateformat),
                                               i_prof,
                                               o_timezone) o_dt_birth_send
              FROM patient p
             WHERE p.id_patient = i_id_pat;
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO o_name, o_nick_name, o_gender, o_desc_gender, o_dt_birth, o_dt_deceased, o_age, o_dt_birth_send;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
        IF g_found
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              pk_message.get_message(i_lang, 'COMMON_M001'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LOCAL_PAT_INFO',
                                              o_error);
            RETURN FALSE;
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
                                              'GET_LOCAL_PAT_INFO',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_nick_name   OUT patient.nick_name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_dt_birth    OUT VARCHAR2,
        o_age         OUT VARCHAR2,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar info do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               Saida:   O_NAME - PATIENT.NAME 
               O_NICK_NAME - PATIENT.NICK_NAME 
               O_GENDER - PATIENT.GENDER 
               O_DT_BIRTH - PATIENT.DT_BIRTH 
               O_AGE - idade calculada para o doente 
               O_DT_DECEASED - PATIENT.DT_DECEASED 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/02/24  
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        function_user_exeception EXCEPTION;
        o_dt_birth_send          VARCHAR2(100);
        l_desc_gender            VARCHAR2(100);
    BEGIN
    
        IF NOT get_local_pat_info(i_lang,
                                  i_id_pat,
                                  i_prof,
                                  o_name,
                                  o_nick_name,
                                  o_gender,
                                  l_desc_gender,
                                  o_dt_birth,
                                  o_dt_birth_send,
                                  o_age,
                                  o_dt_deceased,
                                  o_error)
        THEN
            RAISE function_user_exeception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_user_exeception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_INFO',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_INFO',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_desc_pat_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        o_name          OUT patient.name%TYPE,
        o_nick_name     OUT patient.nick_name%TYPE,
        o_gender        OUT patient.gender%TYPE,
        o_desc_gender   OUT VARCHAR2,
        o_dt_birth      OUT VARCHAR2,
        o_dt_birth_send OUT VARCHAR2,
        o_age           OUT VARCHAR2,
        o_dt_deceased   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        function_user_exeception EXCEPTION;
    
    BEGIN
    
        IF NOT get_local_pat_info(i_lang,
                                  i_id_pat,
                                  i_prof,
                                  o_name,
                                  o_nick_name,
                                  o_gender,
                                  o_desc_gender,
                                  o_dt_birth,
                                  o_dt_birth_send,
                                  o_age,
                                  o_dt_deceased,
                                  o_error)
        THEN
            RAISE function_user_exeception;
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
                                              'GET_DESC_PAT_INFO',
                                              o_error);
            RETURN FALSE;
    END get_desc_pat_info;

    FUNCTION get_pat_birth_date
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_name          OUT patient.name%TYPE,
        o_nick_name     OUT patient.nick_name%TYPE,
        o_gender        OUT patient.gender%TYPE,
        o_dt_birth      OUT VARCHAR2,
        o_age           OUT VARCHAR2,
        o_dt_deceased   OUT VARCHAR2,
        o_dt_birth_send OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar info do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               Saida:   O_NAME - PATIENT.NAME 
               O_NICK_NAME - PATIENT.NICK_NAME 
               O_GENDER - PATIENT.GENDER 
               O_DT_BIRTH - PATIENT.DT_BIRTH 
               O_AGE - idade calculada para o doente 
               O_DT_DECEASED - PATIENT.DT_DECEASED 
               O_ERROR - erro 
         
          CRIAÇÃO: Carlos Vieira   13 Out 2008
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        function_user_exeception EXCEPTION;
        l_desc_gender            VARCHAR2(100);
    BEGIN
        IF NOT get_local_pat_info(i_lang,
                                  i_id_pat,
                                  i_prof,
                                  o_name,
                                  o_nick_name,
                                  o_gender,
                                  l_desc_gender,
                                  o_dt_birth,
                                  o_dt_birth_send,
                                  o_age,
                                  o_dt_deceased,
                                  o_error)
        THEN
            RAISE function_user_exeception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_user_exeception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BIRTH_DATE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BIRTH_DATE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_name        IN patient.name%TYPE,
        i_nick_name   IN patient.nick_name%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar info do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente. Se estiver preenchido, actualiza 
                    registo, senão cria 
               I_NAME - nome completo 
               I_NICK_NAME - nome abreviado 
               I_GENDER - sexo (M / F) 
               I_DT_BIRTH - data nascimento 
               I_DT_DECEASED - data falecimento 
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/02/24  
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_char VARCHAR2(1);
    
        CURSOR c_pat IS
            SELECT 'X'
              FROM patient p
             WHERE p.id_patient = i_id_pat
               AND p.flg_status = g_patient_active;
    
        -- denormalization variables
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_char;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            ts_patient.ins(id_patient_in      => ts_patient.next_key('SEQ_PATIENT'),
                           name_in            => i_name,
                           gender_in          => i_gender,
                           dt_birth_in        => i_dt_birth,
                           nick_name_in       => nvl(i_nick_name, i_name),
                           flg_status_in      => g_patient_active,
                           dt_deceased_in     => i_dt_deceased,
                           adw_last_update_in => g_sysdate,
                           rows_out           => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => NULL,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            IF i_name IS NULL
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  pk_message.get_message(i_lang, 'PATIENT_M001'),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_INFO',
                                                  o_error);
                RETURN FALSE;
            END IF;
        
            UPDATE patient
               SET name        = i_name,
                   gender      = i_gender,
                   dt_birth    = i_dt_birth,
                   nick_name   = nvl(i_nick_name, i_name),
                   dt_deceased = i_dt_deceased
             WHERE id_patient = i_id_pat;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_process_event THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_INFO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_INFO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_pat_age
    (
        i_lang       IN language.id_language%TYPE,
        i_dt_start   IN DATE,
        i_dt_end     IN DATE,
        i_age_format IN VARCHAR2 DEFAULT 'YEARS'
    ) RETURN NUMBER IS
    
        l_age NUMBER;
        k_mask CONSTANT VARCHAR2(0100 CHAR) := 'YYYY-MM-DD HH24:MI:SS';
    
    BEGIN
    
        IF i_dt_start IS NULL
        --OR i_dt_end IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF i_age_format = 'YEARS'
        THEN
            l_age := months_between(nvl(i_dt_end, SYSDATE), i_dt_start) / 12;
            l_age := trunc(l_age);
        ELSIF i_age_format = k_format_age_ynr
        THEN
            l_age := months_between(nvl(i_dt_end, SYSDATE), i_dt_start) / 12;
            l_age := l_age;
        ELSIF i_age_format = 'MONTHS'
        THEN
            l_age := months_between(nvl(i_dt_end, SYSDATE), i_dt_start);
            l_age := trunc(l_age);
        ELSIF i_age_format = 'WEEKS'
        THEN
            l_age := (nvl(to_date(to_char(i_dt_end, k_mask), k_mask), SYSDATE) - i_dt_start) / 7;
            l_age := trunc(l_age);
        ELSIF i_age_format = 'DAYS'
        THEN
            l_age := nvl(to_date(to_char(i_dt_end, k_mask), k_mask), SYSDATE) - i_dt_start;
            l_age := trunc(l_age);
        ELSIF i_age_format = 'HOURS'
        THEN
            l_age := (nvl(to_date(to_char(i_dt_end, k_mask), k_mask), SYSDATE) - i_dt_start) * 24;
            l_age := trunc(l_age);
        ELSIF i_age_format = 'MINUTES'
        THEN
            l_age := (nvl(to_date(to_char(i_dt_end, k_mask), k_mask), SYSDATE) - i_dt_start) * 24 * 60;
            l_age := trunc(l_age);
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age;

    /**
    * Returns the patient age with a given format (YEARS, MONTHS OR DAYS)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_dt_birth     Date of birth
    * @param   i_dt_deceased  Date of death
    * @param   i_age          Patient age
    * @param   i_age_format   Age format (years, months or days)
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  JOSE.SILVA
    * @version 2.6.0.4
    * @since   07-09-2010
    */
    FUNCTION get_pat_age
    (
        i_lang        IN language.id_language%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE DEFAULT NULL,
        i_age         IN patient.age%TYPE,
        i_age_format  IN VARCHAR2 DEFAULT 'YEARS',
        i_patient     IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
    
        l_age NUMBER;
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE DEFAULT NULL;
        l_pat_age     patient.age%TYPE;
    
        k_mask CONSTANT VARCHAR2(0100 CHAR) := 'YYYY-MM-DD HH24:MI:SS';
    
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            SELECT p.dt_birth, p.dt_deceased, p.age
              INTO l_dt_birth, l_dt_deceased, l_pat_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        ELSE
            l_dt_birth    := i_dt_birth;
            l_dt_deceased := i_dt_deceased;
            l_pat_age     := i_age;
        END IF;
    
        IF (l_dt_birth IS NULL)
        THEN
            IF (l_pat_age IS NULL)
            THEN
                RETURN NULL;
            END IF;
        END IF;
    
        IF i_age_format = 'YEARS'
        THEN
            l_age := nvl(l_pat_age, months_between(nvl(l_dt_deceased, SYSDATE), l_dt_birth) / 12);
            l_age := trunc(l_age);
        ELSIF i_age_format = k_format_age_ynr
        THEN
            l_age := nvl(l_pat_age, months_between(nvl(l_dt_deceased, SYSDATE), l_dt_birth) / 12);
            l_age := l_age;
        ELSIF i_age_format = 'MONTHS'
        THEN
            l_age := nvl(l_pat_age * 12, months_between(nvl(l_dt_deceased, SYSDATE), l_dt_birth));
            l_age := trunc(l_age);
        ELSIF i_age_format = 'DAYS'
        THEN
            l_age := nvl((l_pat_age * 365),
                         (nvl(to_date(to_char(l_dt_deceased, k_mask), k_mask), SYSDATE) - l_dt_birth));
            l_age := trunc(l_age);
        END IF;
    
        RETURN(l_age);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age;

    FUNCTION get_pat_age
    (
        i_lang     IN language.id_language%TYPE,
        i_dt_birth IN patient.dt_birth%TYPE,
        i_age      IN patient.age%TYPE,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DT_BIRTH - Data de nascimento do paciente 
                  I_AGE - Idade do paciente na tabela PATIENT
                  I_INST - Instituição para tradução
                  I_SOFT - Software para tradução
               Saida:   
         
          CRIAÇÃO: Fábio Oliveira 2008/05/14 
          NOTAS: Esta função foi criada pois muitas vezes nós já temos a informação do paciente e assim basta enviar a data de nascimento e a idade
        *********************************************************************************/
        l_months  NUMBER;
        l_num_age NUMBER;
        l_age     VARCHAR2(50);
    
    BEGIN
    
        l_months := pk_patient.get_pat_age(i_lang       => i_lang,
                                           i_dt_birth   => i_dt_birth,
                                           i_age        => i_age,
                                           i_age_format => 'MONTHS');
    
        IF l_months IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (i_age IS NULL)
        THEN
            --LG 2006-11-08
            IF l_months < 1
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                                    i_dt_birth   => i_dt_birth,
                                                    i_age        => i_age,
                                                    i_age_format => 'DAYS');
            
                l_age := l_num_age || pk_sysconfig.get_config('DAYS_SIGN', i_inst, i_soft);
            
            ELSIF l_months < 36
            THEN
                l_age := l_months || pk_sysconfig.get_config('MONTHS_SIGN', i_inst, i_soft);
            ELSE
                l_num_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                                    i_dt_birth   => i_dt_birth,
                                                    i_age        => i_age,
                                                    i_age_format => 'YEARS');
            
                l_age := l_num_age;
            END IF;
        ELSE
            l_age := i_age;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_pat_age
    (
        i_lang        IN language.id_language%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        i_age         IN patient.age%TYPE,
        i_inst        IN institution.id_institution%TYPE,
        i_soft        IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DT_BIRTH - Data de nascimento do paciente 
                  I_DT_DECEASED - Data de falecimento do paciente
                  I_AGE - Idade do paciente na tabela PATIENT
                  I_INST - Instituição para tradução
                  I_SOFT - Software para tradução
               Saida:   
         
          CRIAÇÃO: BM 2010/07/30
          NOTAS: Esta função foi criada pois muitas vezes nós já temos a informação do paciente e assim basta enviar a data de nascimento e a idade
        *********************************************************************************/
        l_months  NUMBER;
        l_num_age NUMBER;
        l_age     VARCHAR2(50);
    
    BEGIN
    
        l_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                           i_dt_birth    => i_dt_birth,
                                           i_dt_deceased => i_dt_deceased,
                                           i_age         => i_age,
                                           i_age_format  => 'MONTHS');
    
        IF l_months IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (i_age IS NULL)
        THEN
            --LG 2006-11-08
            IF l_months < 1
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => i_dt_birth,
                                                    i_dt_deceased => i_dt_deceased,
                                                    i_age         => i_age,
                                                    i_age_format  => 'DAYS');
            
                l_age := l_num_age || pk_sysconfig.get_config('DAYS_SIGN', i_inst, i_soft);
            
            ELSIF l_months < 36
            THEN
                l_age := l_months || pk_sysconfig.get_config('MONTHS_SIGN', i_inst, i_soft);
            ELSE
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => i_dt_birth,
                                                    i_dt_deceased => i_dt_deceased,
                                                    i_age         => i_age,
                                                    i_age_format  => 'YEARS');
            
                l_age := l_num_age;
            END IF;
        ELSE
            l_age := i_age;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age;

    FUNCTION get_pat_age_long
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_months  NUMBER;
        l_num_age NUMBER;
        l_age     VARCHAR2(50);
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased DATE;
    
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, to_date(to_char(p.dt_deceased, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
              FROM patient p
             WHERE p.id_patient = i_id_pat;
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth, l_age, l_dt_deceased;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            RETURN NULL;
        END IF;
    
        l_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                           i_dt_birth    => l_dt_birth,
                                           i_dt_deceased => l_dt_deceased,
                                           i_age         => l_age,
                                           i_age_format  => 'MONTHS');
    
        IF l_months IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (l_age IS NULL)
        THEN
            --LG 2006-11-08
            IF l_months < 1
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_age,
                                                    i_age_format  => 'DAYS');
            
                l_age := l_num_age || ' ' || CASE trunc(l_num_age)
                             WHEN 1 THEN
                              pk_message.get_message(i_lang, 'COMMON_M092')
                             ELSE
                              pk_message.get_message(i_lang, 'COMMON_M093')
                         END;
            
            ELSIF l_months < 36
            THEN
                l_age := l_months || ' ' || CASE trunc(l_months)
                             WHEN 1 THEN
                              pk_message.get_message(i_lang, 'COMMON_M060')
                             ELSE
                              pk_message.get_message(i_lang, 'COMMON_M061')
                         END;
            ELSE
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_age,
                                                    i_age_format  => 'YEARS');
            
                l_age := l_num_age;
            END IF;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age_long;

    FUNCTION get_pat_age_years
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_months  NUMBER;
        l_num_age NUMBER;
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased DATE;
    
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, to_date(to_char(p.dt_deceased, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
              FROM patient p
             WHERE p.id_patient = i_id_pat;
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth, l_num_age, l_dt_deceased;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            RETURN NULL;
        END IF;
    
        l_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                           i_dt_birth    => l_dt_birth,
                                           i_dt_deceased => l_dt_deceased,
                                           i_age         => l_num_age,
                                           i_age_format  => 'MONTHS');
    
        IF l_months IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (l_num_age IS NULL)
        THEN
            --LG 2006-11-08
            IF l_months < 12
            THEN
                l_num_age := 0;
            ELSE
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_num_age,
                                                    i_age_format  => 'YEARS');
            END IF;
        END IF;
    
        RETURN l_num_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age_years;

    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               Saida:   
         
          CRIAÇÃO: CRS 2005/03/23 
          NOTAS: Como se trata de um cálculo frequente/ necessário noutras funções cujo 
             único retorno é um array, é conveniente q haja uma função q possa ser 
           utilizada dentro de um SELECT
                     2006-11-08 LG, inclui o campo age, idade estimada, no cálculo da idade 
                     2008-05-19 FO: usa função mais específica eliminando duplicação de código
        *********************************************************************************/
    
    BEGIN
    
        RETURN get_pat_age(i_lang, i_id_pat, i_prof.institution, i_prof.software);
    
    END;

    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               Saida:   
         
          CRIAÇÃO: SS 2006/01/16 
          NOTAS: 
                     2006-11-08 LG, inclui o campo age, idade estimada, no cálculo da idade 
                     2008-05-19 FO: usa função que calcula a idade dando a data de nascimento
        *********************************************************************************/
        l_dt_birth    patient.dt_birth%TYPE;
        l_age         patient.age%TYPE;
        l_dt_deceased patient.dt_deceased%TYPE;
    
        --FO 2008-05-15
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, p.dt_deceased
              FROM patient p
             WHERE p.id_patient = i_id_pat;
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth, l_age, l_dt_deceased;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            RETURN NULL;
        END IF;
    
        RETURN get_pat_age(i_lang, l_dt_birth, l_dt_deceased, l_age, i_inst, i_soft);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_pat_age_with_format
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_units      OUT VARCHAR2
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DT_BIRTH - Data de nascimento do paciente 
                  I_AGE - Idade do paciente na tabela PATIENT
                  I_INST - Instituição para tradução
                  I_SOFT - Software para tradução
               Saida:   
         get_
          CRIAÇÃO: Fábio Oliveira 2008/05/14 
          NOTAS: Esta função foi criada pois muitas vezes nós já temos a informação do paciente e assim basta enviar a data de nascimento e a idade
        *********************************************************************************/
        l_months  PLS_INTEGER;
        l_num_age NUMBER;
        l_age     VARCHAR2(50);
    
        c_months_to_days  PLS_INTEGER := 1;
        c_months_to_month PLS_INTEGER := 36;
        c_days_format     VARCHAR2(1 CHAR) := 'd';
        c_months_format   VARCHAR2(1 CHAR) := 'm';
        c_years_format    VARCHAR2(1 CHAR) := 'y';
    
        l_dt_birth    patient.dt_birth%TYPE;
        l_dt_deceased DATE;
    
        CURSOR c_pat IS
            SELECT p.dt_birth, p.age, to_date(to_char(p.dt_deceased, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth, l_age, l_dt_deceased;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            RETURN NULL;
        END IF;
    
        l_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                           i_dt_birth    => l_dt_birth,
                                           i_dt_deceased => l_dt_deceased,
                                           i_age         => l_age,
                                           i_age_format  => 'MONTHS');
    
        IF l_months IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (l_age IS NULL)
        THEN
        
            IF l_months < c_months_to_days
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_age,
                                                    i_age_format  => 'DAYS');
            
                l_age   := l_num_age || '-' || c_days_format;
                o_units := c_days_format;
            
            ELSIF l_months < c_months_to_month
            THEN
                l_age   := l_months || '-' || c_months_format;
                o_units := c_months_format;
            ELSE
                l_num_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                    i_dt_birth    => l_dt_birth,
                                                    i_dt_deceased => l_dt_deceased,
                                                    i_age         => l_age,
                                                    i_age_format  => 'YEARS');
            
                l_age   := l_num_age || '-' || c_years_format;
                o_units := c_years_format;
            END IF;
        ELSE
            l_age   := l_age || '-' || c_years_format;
            o_units := c_years_format;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age_with_format;

    FUNCTION get_pat_short_name(i_id_pat IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar o nome do doente 
           PARAMETROS:  Entrada: I_ID_PAT - ID do doente 
                  Saida:   
         
          CRIAÇÃO: SS 2007/02/12 
          NOTAS:  
        *********************************************************************************/
        l_name VARCHAR2(4000);
    
    BEGIN
        g_error := 'GET CURSOR';
    
        SELECT substr(name, 1, instr(name, ' ')) || substr(name, instr(name, ' ', -1) + 1) name
          INTO l_name
          FROM patient p
         WHERE p.id_patient = i_id_pat;
    
        RETURN l_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION set_pat_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_pat           IN patient.id_patient%TYPE,
        i_pat_problem   IN pat_problem.id_pat_problem%TYPE,
        i_prof          IN profissional,
        i_diag          IN pat_problem.id_diagnosis%TYPE,
        i_desc          IN pat_problem.desc_pat_problem%TYPE,
        i_notes         IN pat_problem.notes%TYPE,
        i_age           IN pat_problem.flg_age%TYPE,
        i_dt_symptoms   IN VARCHAR2,
        i_flg_approved  IN pat_problem.flg_aproved%TYPE,
        i_pct           IN pat_problem.pct_incapacity%TYPE,
        i_surgery       IN pat_problem.flg_surgery%TYPE,
        i_notes_support IN pat_problem.notes_support%TYPE,
        i_dt_confirm    IN VARCHAR2,
        i_rank          IN pat_problem.rank%TYPE,
        i_status        IN pat_problem.flg_status%TYPE,
        i_epis_diag     IN pat_problem.id_epis_diagnosis%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_notes_cancel  IN pat_problem.cancel_notes%TYPE DEFAULT NULL,
        i_cancel_reason IN pat_problem.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar / alterar / cancelar um "Problema" ou "Doença Relevante" 
               do doente. 
               Se I_PAT_PROBLEM = NULL, registo é criado, OU trata-se de um cancelamento 
                         de diagnóstico de epis. e ñ se sabe qual o ID 
                   de problema correspondente (ver PK_CLINICAL_INFO.CANCEL_EPIS_DIAGNOSIS) 
            Se I_PAT_PROBLEM é preenchido e I_STATUS = 'C', o registo é cancelado.
            Se I_PAT_PROBLEM é preenchido e I_STATUS = 'A', o registo é actualizado 
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - ID do doente 
               I_PAT_PROBLEM - ID do registo. Se vier preenchido, é pq 
                       se trata de um Update ao registo. Senão, 
                   é um Insert.
               I_PROF - ID do profissional q regista (criação / alteração) 
               I_DIAG - Diagnóstico (opcional) 
               I_DESC - problema, caso ñ se tenha optado pela escolha de 
                   um diagnóstico da lista 
               I_NOTES - notas 
               I_AGE - Período da vida do utente: P - perinatal, N - neonatal, 
                     I - infância, E - escolar, A - adulto 
               I_DT_SYMPTOMS - data aproximada de início do problema. É uma 
                       string com formato YYYY-MM-DD q depois é convertida 
               I_FLG_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
               I_TYPE - A - activo, P - passivo, I - incapacidade permanente 
               I_YEAR_BEGIN, I_MONTH_BEGIN, I_DAY_BEGIN - mesmo q ñ se saiba 
                 a data de início do problema, pode-se indicar ano, mês 
                e / ou dia aproximados 
               I_YEAR_END, I_MONTH_END, I_DAY_END - mesmo q ñ se saiba 
                 a data de fim do problema, pode-se indicar ano, mês 
                e / ou dia aproximados 
               I_PCT - percentagem de incapacidade provocada pelo problema 
               I_SURGERY - indicador de q o problema foi resolvido através 
                      de cirurgia (Y / N) 
               I_NOTES_SUPPORT - Apoios de recurso, relativos ao problema apontado 
               I_DT_CONFIRM - Data de confirmação da doença de trabalho 
               I_RANK - Ordem de importância 
               I_STATUS - A - activo, P - passivo, I - incapacidade permanente 
                 C - cancelado. 
               I_EPIS_DIAG - ID de EPIS_DIAGNOSIS. Diag. provável / definitivo q 
                     passa a ser problema do doente 
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida:   O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
               O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                     O_FLG_SHOW = Y 
               O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                 + do q 1 botão 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/07 
          NOTAS: Não é permitido eliminar info do registo, mesmo qd se trata de um Update; 
             se houver info errada, cancela-se o registo 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_char VARCHAR2(1);
        --l_error              VARCHAR2(2000);
        l_year_begin         pat_problem.year_begin%TYPE;
        l_month_begin        pat_problem.month_begin%TYPE;
        l_day_begin          pat_problem.day_begin%TYPE;
        v_pat_problem_hist   pat_problem_hist%ROWTYPE;
        l_id_pat_problem     pat_problem.id_pat_problem%TYPE;
        l_id_alert_diagnosis pat_problem.id_alert_diagnosis%TYPE;
        l_dt_confirm         TIMESTAMP WITH LOCAL TIME ZONE;
        l_iu                 VARCHAR2(2);
        CURSOR c_exist IS
            SELECT 'X'
              FROM pat_problem
             WHERE id_pat_problem = i_pat_problem
               AND flg_status = i_status;
    
        CURSOR c_pat_prob_hist(l_pat_problem IN pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_episode,
                   id_epis_anamnesis,
                   id_cancel_reason,
                   id_habit_characterization
              FROM pat_problem
             WHERE id_pat_problem = l_pat_problem;
    
        CURSOR c_epis_diag IS
            SELECT id_pat_problem, d.id_alert_diagnosis
              FROM pat_problem p, visit v, episode e, epis_diagnosis d
             WHERE d.id_epis_diagnosis = i_epis_diag
               AND e.id_episode = d.id_episode
               AND v.id_visit = e.id_visit
               AND p.id_epis_diagnosis = d.id_epis_diagnosis
               AND p.id_patient = v.id_patient;
    
        -- denormalization variables
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        l_dt_confirm   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_confirm, NULL);
    
        g_error := 'GET DATE SYMPTOMS1';
        IF i_dt_symptoms IS NOT NULL
        THEN
            g_error       := 'GET DATE SYMPTOMS2';
            l_year_begin  := to_number(substr(i_dt_symptoms, 1, instr(i_dt_symptoms, '-') - 1));
            l_month_begin := to_number(substr(substr(i_dt_symptoms, instr(i_dt_symptoms, '-') + 1),
                                              1,
                                              instr(substr(i_dt_symptoms, instr(i_dt_symptoms, '-') + 1), '-') - 1));
            l_day_begin   := to_number(substr(substr(i_dt_symptoms, instr(i_dt_symptoms, '-') + 1),
                                              instr(substr(i_dt_symptoms, instr(i_dt_symptoms, '-') + 1), '-') + 1));
        END IF;
        g_error := 'GET DATE SYMPTOMS3';
    
        IF i_pat_problem IS NULL
        THEN
            g_error := 'GET DATE SYMPTOMS4';
            IF i_epis_diag IS NOT NULL
            THEN
                -- Cancelamento de diagnóstico de epis. (ver PK_CLINICAL_INFO.CANCEL_EPIS_DIAGNOSIS) 
                g_error := 'OPEN C_EPIS_DIAG';
                OPEN c_epis_diag;
                FETCH c_epis_diag
                    INTO l_id_pat_problem, l_id_alert_diagnosis;
                g_found := c_epis_diag%NOTFOUND;
                CLOSE c_epis_diag;
                IF g_found
                THEN
                    l_iu := 'I';
                ELSE
                    l_iu := 'U';
                END IF;
            
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  pk_message.get_message(i_lang, 'COMMON_M001'),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM',
                                                  o_error);
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        ELSE
            --actualizar registo existente de problema 
            g_error := 'GET DATE SYMPTOMS5';
        
            l_iu             := 'U';
            l_id_pat_problem := i_pat_problem;
        
            g_error := 'GET CURSOR C_EXIST';
            OPEN c_exist;
            FETCH c_exist
                INTO l_char;
            g_found := c_exist%FOUND;
            CLOSE c_exist;
        
            IF g_found
            THEN
                -- Problema já tinha este status
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  REPLACE(pk_message.get_message(i_lang, 'COMMON_M013'),
                                                          '@1',
                                                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS',
                                                                                  i_status,
                                                                                  i_lang)),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM',
                                                  o_error);
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_iu = 'I'
        THEN
            -- novo registo 
            g_error := 'CHECK DESC PROBLEM';
            IF i_diag IS NULL
               AND i_desc IS NULL
               AND i_epis_diag IS NULL
            THEN
                -- Não foi indicado um descritivo de problema nem diagnóstico  
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  REPLACE(REPLACE(pk_message.get_message(i_lang, 'COMMON_M004'),
                                                                  '@1',
                                                                  'diagnóstico'),
                                                          '@2',
                                                          'descritivo do problema'),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM',
                                                  o_error);
                RETURN FALSE;
            END IF;
        
            IF i_diag IS NOT NULL
            THEN
                -- Criação de registo de doença relevante 
                g_error := 'CALL TO CHECK_PAT_PROBLEM';
                IF NOT check_pat_problem(i_lang      => i_lang,
                                         i_diag      => i_diag,
                                         i_id_pat    => i_pat,
                                         o_flg_show  => o_flg_show,
                                         o_msg_title => o_msg_title,
                                         o_msg_text  => o_msg_text,
                                         o_button    => o_button,
                                         o_error     => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
                IF o_flg_show = 'Y'
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            IF i_status != g_pat_probl_active
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  pk_message.get_message(i_lang, 'PATIENT_M005'),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM',
                                                  o_error);
                RETURN FALSE;
            END IF;
        
            ts_pat_problem.ins(id_pat_problem_in      => ts_pat_problem.next_key('SEQ_PAT_PROBLEM'),
                               id_patient_in          => i_pat,
                               id_diagnosis_in        => i_diag,
                               id_alert_diagnosis_in  => l_id_alert_diagnosis, -- ALERT-736: diagnosis synonyms support
                               id_professional_ins_in => i_prof.id,
                               dt_pat_problem_tstz_in => g_sysdate_tstz,
                               desc_pat_problem_in    => i_desc,
                               notes_in               => i_notes,
                               flg_age_in             => i_age,
                               year_begin_in          => l_year_begin,
                               month_begin_in         => l_month_begin,
                               day_begin_in           => l_day_begin,
                               pct_incapacity_in      => i_pct,
                               flg_surgery_in         => i_surgery,
                               notes_support_in       => i_notes_support,
                               dt_confirm_tstz_in     => l_dt_confirm,
                               flg_status_in          => g_pat_probl_active,
                               rank_in                => i_rank,
                               id_epis_diagnosis_in   => i_epis_diag,
                               flg_aproved_in         => i_flg_approved,
                               id_institution_in      => i_prof.institution,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROBLEM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            --actualizar 
            g_error := 'OPEN C_PAT_PROB_HIST';
            OPEN c_pat_prob_hist(l_id_pat_problem);
            FETCH c_pat_prob_hist
                INTO v_pat_problem_hist.id_pat_problem,
                     v_pat_problem_hist.id_patient, --
                     v_pat_problem_hist.id_diagnosis,
                     v_pat_problem_hist.id_alert_diagnosis, --
                     v_pat_problem_hist.id_professional_ins,
                     v_pat_problem_hist.dt_pat_problem_tstz, --
                     v_pat_problem_hist.desc_pat_problem,
                     v_pat_problem_hist.notes,
                     v_pat_problem_hist.flg_age, --
                     v_pat_problem_hist.year_begin,
                     v_pat_problem_hist.month_begin,
                     v_pat_problem_hist.day_begin, --
                     v_pat_problem_hist.year_end,
                     v_pat_problem_hist.month_end,
                     v_pat_problem_hist.day_end, --
                     v_pat_problem_hist.pct_incapacity,
                     v_pat_problem_hist.flg_surgery,
                     v_pat_problem_hist.notes_support, --
                     v_pat_problem_hist.dt_confirm_tstz,
                     v_pat_problem_hist.rank,
                     v_pat_problem_hist.flg_status, --
                     v_pat_problem_hist.id_epis_diagnosis,
                     v_pat_problem_hist.flg_aproved,
                     v_pat_problem_hist.id_institution, --
                     v_pat_problem_hist.id_episode,
                     v_pat_problem_hist.id_epis_anamnesis,
                     v_pat_problem_hist.id_cancel_reason,
                     v_pat_problem_hist.id_habit_characterization; --
        
            g_found := c_pat_prob_hist%FOUND;
        
            CLOSE c_pat_prob_hist;
        
            IF NOT g_found
            THEN
                -- O Problema não existe
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  pk_message.get_message(i_lang, 'COMMON_M001'),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_PROBLEM',
                                                  o_error);
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            /* IF I_STATUS != G_PAT_PROBL_CANCEL THEN
                 G_ERROR := 'INSERT HIST';  
             if not INS_PAT_PROBLEM_HIST (I_LANG => I_LANG,
                                   I_PAT_PROBLEM_HIST=> V_PAT_PROBLEM_HIST,
                     O_ERROR => L_ERROR) THEN
                  o_error := l_error;
                  RETURN FALSE;
                end if;
             
                 G_ERROR := 'UPDATE';  
                 UPDATE PAT_PROBLEM 
                 SET NOTES = NVL(I_NOTES, NOTES), 
                  YEAR_BEGIN = NVL(L_YEAR_BEGIN, YEAR_BEGIN), 
                  MONTH_BEGIN = NVL(L_MONTH_BEGIN, MONTH_BEGIN), 
                  DAY_BEGIN = NVL(L_DAY_BEGIN, DAY_BEGIN), 
                  YEAR_END = NVL(I_YEAR_END, YEAR_END), 
                  MONTH_END = NVL(I_MONTH_END, MONTH_END), 
                  DAY_END = NVL(I_DAY_END, DAY_END), 
                  PCT_INCAPACITY = NVL(I_PCT, PCT_INCAPACITY), 
                  FLG_SURGERY = NVL(I_SURGERY, FLG_SURGERY), 
                  RANK = NVL(I_RANK, RANK),
                  NOTES_SUPPORT = NVL(I_NOTES_SUPPORT, NOTES_SUPPORT), 
                  DT_CONFIRM = NVL(I_DT_CONFIRM, DT_CONFIRM),
                  FLG_STATUS = I_STATUS,
                  DT_PAT_PROBLEM = G_SYSDATE,
                  ID_PROFESSIONAL_INS = I_PROF.ID
              WHERE ID_PAT_PROBLEM = I_PAT_PROBLEM;
            
            ELSE*/
            g_error := 'INSERT HIST';
            IF NOT ins_pat_problem_hist(i_lang => i_lang, i_pat_problem_hist => v_pat_problem_hist, o_error => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'UPDATE PAT_PROBLEM';
            ts_pat_problem.upd(id_pat_problem_in      => l_id_pat_problem,
                               flg_status_in          => g_pat_probl_cancel,
                               dt_pat_problem_tstz_in => g_sysdate_tstz,
                               id_professional_ins_in => i_prof.id,
                               id_institution_in      => i_prof.institution,
                               notes_in               => i_notes,
                               cancel_notes_in        => i_notes_cancel,
                               id_cancel_reason_in    => i_cancel_reason,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROBLEM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF i_epis_diag IS NOT NULL
            THEN
                g_error := 'UPDATE EPIS_DIAGNOSIS';
                UPDATE epis_diagnosis
                   SET flg_status             = g_pat_probl_cancel,
                       dt_cancel_tstz         = g_sysdate_tstz,
                       id_professional_cancel = i_prof.id,
                       notes_cancel           = i_notes,
                       id_cancel_reason       = i_cancel_reason
                 WHERE id_epis_diagnosis = i_epis_diag;
            END IF;
        
            -- END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_pat_problem_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg            IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Alterar / cancelar problema do doente.
                Usada no ecrã de mudanças de estado dos "Problemas" do doente, pq 
             permite a mudança de estado de vários problemas em simultâneo.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - ID do doente 
               I_PROF - profissional q regista 
               I_ID_PAT_PROBLEM - array de IDs de registos alterados 
               I_FLG - array de estados 
               I_NOTES - array de notas  
               I_TYPE - array de tipos: P - problemas, A - alergias, H - hábitos 
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/04/16 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_flg_status       pat_problem.flg_status%TYPE;
        l_prof_upd         pat_problem.id_professional_ins%TYPE;
        l_dt_update_tstz   pat_problem.dt_pat_problem_tstz%TYPE;
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
        l_flg_show         VARCHAR2(1);
        l_msg_title        VARCHAR2(2000);
        l_msg_text         VARCHAR2(2000);
        l_button           VARCHAR2(6);
    
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   id_habit_characterization
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        -- denormalization variables
        l_rowids     table_varchar;
        l_rowids_upd table_varchar;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_problem.count
        LOOP
            -- Loop sobre o array de IDs de registos 
            g_error            := 'GET TYPE / STATUS';
            v_pat_problem_hist := NULL;
            l_flg_status       := i_flg(i);
            l_prof_upd         := i_prof.id;
            l_dt_update_tstz   := g_sysdate_tstz;
        
            IF i_type(i) = g_pat_prob_allrg
            THEN
                IF NOT set_pat_allergy(i_lang           => i_lang,
                                       i_epis           => i_epis,
                                       i_id_pat_allergy => i_id_pat_problem(i),
                                       i_id_pat         => i_pat,
                                       i_prof           => i_prof,
                                       i_allergy        => NULL,
                                       i_drug_pharma    => NULL,
                                       i_notes          => i_notes(i),
                                       i_dt_first_time  => NULL,
                                       i_flg_type       => NULL,
                                       i_flg_approved   => NULL,
                                       i_flg_status     => i_flg(i),
                                       i_dt_symptoms    => NULL,
                                       i_prof_cat_type  => i_prof_cat_type,
                                       o_flg_show       => l_flg_show,
                                       o_msg_title      => l_msg_title,
                                       o_msg_text       => l_msg_text,
                                       o_button         => l_button,
                                       o_error          => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            
            ELSIF i_type(i) = g_pat_prob_prob
            THEN
                g_error := 'OPEN CURSOR';
                OPEN c_prob(i_id_pat_problem(i));
                FETCH c_prob
                    INTO v_pat_problem_hist.id_pat_problem,
                         v_pat_problem_hist.id_patient,
                         v_pat_problem_hist.id_diagnosis,
                         v_pat_problem_hist.id_alert_diagnosis,
                         v_pat_problem_hist.id_professional_ins,
                         v_pat_problem_hist.dt_pat_problem_tstz,
                         v_pat_problem_hist.desc_pat_problem,
                         v_pat_problem_hist.notes,
                         v_pat_problem_hist.flg_age,
                         v_pat_problem_hist.year_begin,
                         v_pat_problem_hist.month_begin,
                         v_pat_problem_hist.day_begin,
                         v_pat_problem_hist.year_end,
                         v_pat_problem_hist.month_end,
                         v_pat_problem_hist.day_end,
                         v_pat_problem_hist.pct_incapacity,
                         v_pat_problem_hist.flg_surgery,
                         v_pat_problem_hist.notes_support,
                         v_pat_problem_hist.dt_confirm_tstz,
                         v_pat_problem_hist.rank,
                         v_pat_problem_hist.flg_status,
                         v_pat_problem_hist.id_epis_diagnosis,
                         v_pat_problem_hist.flg_aproved,
                         v_pat_problem_hist.id_institution,
                         v_pat_problem_hist.id_pat_habit,
                         v_pat_problem_hist.id_episode,
                         v_pat_problem_hist.id_epis_anamnesis,
                         v_pat_problem_hist.id_habit_characterization;
                g_found := c_prob%NOTFOUND;
                CLOSE c_prob;
            
                g_error := 'INSERT HIST';
                IF NOT
                    ins_pat_problem_hist(i_lang => i_lang, i_pat_problem_hist => v_pat_problem_hist, o_error => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            
                g_error := 'UPDATE PAT_PROBLEM';
                /*                ts_pat_problem.upd(id_pat_problem_in      => i_id_pat_problem(i),
                flg_status_in          => l_flg_status,
                dt_pat_problem_tstz_in => l_dt_update_tstz,
                id_professional_ins_in => l_prof_upd,
                id_institution_in      => i_prof.institution,
                notes_in               => i_notes(i),
                id_episode_in          => i_epis,
                rows_out               => l_rowids);*/
            
                -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'UPDATE PAT_HABIT';
                -- *********************************
                -- PT 10/10/2008 2.4.3.d
            
                ts_pat_habit.upd(id_pat_habit_in => v_pat_problem_hist.id_pat_habit,
                                 flg_status_in   => l_flg_status,
                                 id_episode_in   => i_epis,
                                 rows_out        => l_rowids_upd);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_HABIT',
                                              i_rowids     => l_rowids_upd,
                                              o_error      => o_error);
                -- *********************************
                /*UPDATE pat_habit
                  SET flg_status     = l_flg_status,
                      dt_cancel_tstz = l_dt_update_tstz,
                      id_prof_cancel = i_prof.id,
                      note_cancel    = i_notes(i),
                      id_episode     = i_epis -- SS: 2006/04/19: Alteração para a folha resumo
                WHERE id_pat_habit = v_pat_problem_hist.id_pat_habit;*/
            
            END IF;
        END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_PROBLEM_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION create_pat_problem_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_desc_problem   IN table_varchar,
        i_flg            IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_age            IN table_varchar,
        i_flg_approved   IN table_varchar,
        i_epis_anamnesis IN table_number,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Criar problemas do doente. 
                Usada no ecrã de "Problemas" do doente, pq permite registar vários 
             problemas (texto livre) em simultâneo. 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - ID do doente 
               I_PROF - profissional q regista 
               I_DESC_PROBLEM - array de descritivos de problemas 
               I_FLG - array de estados 
               I_NOTES - array de notas  
               I_DT_SYMPTOMS - data aproximada de início do problema. É uma 
                       string com formato YYYY-MM-DD q depois é convertida 
               I_AGE - Período da vida do utente: P - perinatal, N - neonatal, 
                     I - infância, E - escolar, A - adulto 
               I_FLG_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
               I_EPIS_ANAMNESIS - ID de registo de queixa / história escolhido a partir do multi-choice 
                                             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/04/21 
          NOTAS:  
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_year_begin  pat_problem.year_begin%TYPE;
        l_month_begin pat_problem.month_begin%TYPE;
        l_day_begin   pat_problem.day_begin%TYPE;
    
        -- denormalization variables
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_desc_problem.count
        LOOP
            -- Loop sobre o array de descritivos 
            g_error       := 'GET DATE SYMPTOMS';
            l_year_begin  := NULL;
            l_month_begin := NULL;
            l_day_begin   := NULL;
            IF i_dt_symptoms IS NOT NULL
            THEN
                l_year_begin  := to_number(substr(i_dt_symptoms(i), 1, instr(i_dt_symptoms(i), '-') - 1));
                l_month_begin := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  1,
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') - 1));
                l_day_begin   := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') + 1));
            END IF;
        
            g_error := 'INSERT INTO PAT_PROBLEM';
            IF i_desc_problem(i) IS NOT NULL
            THEN
                ts_pat_problem.ins(id_pat_problem_in      => ts_pat_problem.next_key('SEQ_PAT_PROBLEM'),
                                   id_patient_in          => i_pat,
                                   id_professional_ins_in => i_prof.id,
                                   dt_pat_problem_tstz_in => g_sysdate_tstz,
                                   flg_status_in          => i_flg(i),
                                   desc_pat_problem_in    => i_desc_problem(i),
                                   notes_in               => i_notes(i),
                                   year_begin_in          => l_year_begin,
                                   month_begin_in         => l_month_begin,
                                   day_begin_in           => l_day_begin,
                                   flg_age_in             => i_age(i),
                                   flg_aproved_in         => i_flg_approved(i),
                                   id_institution_in      => i_prof.institution,
                                   id_episode_in          => i_epis,
                                   id_epis_anamnesis_in   => i_epis_anamnesis(i),
                                   rows_out               => l_rowids);
            
                g_error := 'INSERT INTO PAT_PROBLEM -> PROCESS_INSERT';
                -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PAT_PROBLEM_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION create_relev_disease_array
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_pat           IN pat_problem.id_patient%TYPE,
        i_prof          IN profissional,
        i_id_diagnosis  IN table_number,
        i_flg           IN table_varchar,
        i_notes         IN table_varchar,
        i_dt_symptoms   IN table_varchar,
        i_age           IN table_varchar,
        i_flg_approved  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_diag     IN pat_problem.desc_pat_problem%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Criar problemas do doente através dos ID dos diagnósticos.
                Utilizado para registar "Doenças Relevantes" 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - ID do doente 
               I_PROF - profissional q regista 
               I_ID_DIAGNOSIS - ID do diagnóstico
               I_FLG - array de estados: A - activo, P - passivo, C - cancelado 
               I_NOTES - array de notas  
               I_DT_SYMPTOMS - data aproximada de início do problema. É uma 
                       string com formato YYYY-MM-DD q depois é convertida 
               I_AGE - Período da vida do utente: P - perinatal, N - neonatal, 
                     I - infância, E - escolar, A - adulto 
               I_FLG_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               I_DESC_DIAG - descritivo da doença relevante (se "outro diagnóstico") 
               Saida:   O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
               O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                     O_FLG_SHOW = Y 
               O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                 + do q 1 botão 
               O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/27 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next        pat_problem.id_pat_problem%TYPE;
        l_year_begin  pat_problem.year_begin%TYPE;
        l_month_begin pat_problem.month_begin%TYPE;
        l_day_begin   pat_problem.day_begin%TYPE;
    
        -- denormalization variables
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
        e_no_show       EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_diagnosis.count
        LOOP
            g_error := 'CALL TO CHECK_PAT_PROBLEM';
            IF NOT check_pat_problem(i_lang      => i_lang,
                                     i_diag      => i_id_diagnosis(i),
                                     i_id_pat    => i_pat,
                                     o_flg_show  => o_flg_show,
                                     o_msg_title => o_msg_title,
                                     o_msg_text  => o_msg,
                                     o_button    => o_button,
                                     o_error     => o_error)
            THEN
                RAISE e_call_error;
            END IF;
            IF o_flg_show = 'Y'
            THEN
                RAISE e_no_show;
            END IF;
        
            g_error       := 'GET DATE SYMPTOMS';
            l_year_begin  := NULL;
            l_month_begin := NULL;
            l_day_begin   := NULL;
            IF i_dt_symptoms IS NOT NULL
            THEN
                l_year_begin  := to_number(substr(i_dt_symptoms(i), 1, instr(i_dt_symptoms(i), '-') - 1));
                l_month_begin := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  1,
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') - 1));
                l_day_begin   := to_number(substr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1),
                                                  instr(substr(i_dt_symptoms(i), instr(i_dt_symptoms(i), '-') + 1), '-') + 1));
            END IF;
        
            g_error := 'GET SEQ_PATIENT.NEXTVAL';
            SELECT seq_pat_problem.nextval
              INTO l_next
              FROM dual;
        
            ts_pat_problem.ins(id_pat_problem_in      => ts_pat_problem.next_key('SEQ_PAT_PROBLEM'),
                               id_patient_in          => i_pat,
                               id_professional_ins_in => i_prof.id,
                               dt_pat_problem_tstz_in => g_sysdate_tstz,
                               flg_status_in          => i_flg(i),
                               id_diagnosis_in        => i_id_diagnosis(i),
                               notes_in               => i_notes(i),
                               year_begin_in          => l_year_begin,
                               month_begin_in         => l_month_begin,
                               day_begin_in           => l_day_begin,
                               flg_age_in             => i_age(i),
                               flg_aproved_in         => i_flg_approved(i),
                               id_institution_in      => i_prof.institution,
                               desc_pat_problem_in    => i_desc_diag,
                               id_episode_in          => i_epis,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROBLEM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END LOOP;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_no_show THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              o_msg,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_RELEV_DISEASE_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            o_flg_show := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_RELEV_DISEASE_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION check_pat_problem
    (
        i_lang      IN language.id_language%TYPE,
        i_diag      IN pat_problem.id_diagnosis%TYPE,
        i_id_pat    IN pat_problem.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verifica se o diagnóstico já tinha sido atribuído ao doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DIAG - ID da do diagnóstico 
               I_ID_PAT - ID do doente 
               Saida:   O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
               O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                     O_FLG_SHOW = Y 
               O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                 + do q 1 botão 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/07/24 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_char VARCHAR2(1);
    
        CURSOR c_prob IS
            SELECT 'X'
              FROM pat_problem pa
             WHERE pa.id_diagnosis = i_diag
               AND pa.id_patient = i_id_pat
               AND pa.desc_pat_problem IS NULL;
        --    AND PA.FLG_STATUS != G_PAT_ALLERGY_CANCEL;
    
    BEGIN
        o_flg_show := 'N';
    
        g_error := 'OPEN CURSOR C_PROB';
        OPEN c_prob;
        FETCH c_prob
            INTO l_char;
        g_found := c_prob%FOUND; -- Este diagnóstico já foi atribuído a este doente 
        CLOSE c_prob;
    
        IF g_found
        THEN
            o_flg_show  := 'Y';
            o_msg_text  := pk_message.get_message(i_lang, 'PATIENT_M010');
            o_msg_title := pk_message.get_message(i_lang, 'PATIENT_M011');
            o_button    := 'R';
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
                                              'CHECK_PAT_PROBLEM',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_pat_problem
    (
        i_lang        IN language.id_language%TYPE,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_status      IN pat_problem.flg_status%TYPE,
        i_type        IN VARCHAR2,
        i_prof        IN profissional,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter problemas do doente, podendo incluir: 
               problemas, doenças relevantes, diagnósticos, alergias 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - ID do doente 
               I_STATUS - estado do registo (activo / cancelado / passivo). 
                    Se ñ está preenchido, retorna todos os registos 
               I_TYPE - P - problemas; D - doenças relevantes; 
                   E - diagnósticos; A - alergias; H - hábitos 
                  Se for vazio, traz todos os tipos 
               Saida:   O_PAT_PROBLEM - problemas 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/22 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5  
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_pat_problem FOR
            SELECT p.id_professional,
                   pp.id_pat_problem id_problem,
                   'P' TYPE,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_problem2,
                   decode(pp.id_habit,
                          '',
                          pk_date_utils.dt_chr_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof.institution, i_prof.software),
                          decode(pp.year_begin,
                                 '',
                                 '',
                                 decode(pp.month_begin,
                                        '',
                                        to_char(pp.year_begin),
                                        substr(to_char(to_date(pp.year_begin || lpad(pp.month_begin, 2, '0'), 'YYYYMM'),
                                                       'DD-MM-YYYY'),
                                               4)))) dt_problem,
                   decode(pp.desc_pat_problem,
                          '',
                          decode(pp.id_habit,
                                 '',
                                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_diagnosis        => d1.id_diagnosis,
                                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                            i_code                => d.code_icd,
                                                            i_flg_other           => d.flg_other,
                                                            i_flg_std_diag        => pk_alert_constant.g_yes,
                                                            i_epis_diag           => ed.id_epis_diagnosis)),
                          pp.desc_pat_problem) desc_probl,
                   decode(pp.desc_pat_problem,
                          '',
                          decode(pp.id_habit,
                                 '',
                                 decode(nvl(ed.id_epis_diagnosis, 0),
                                        0,
                                        pk_message.get_message(i_lang, 'PROBLEMS_M004'),
                                        decode(ed.flg_type,
                                               g_epis_diag_passive,
                                               pk_message.get_message(i_lang, 'PROBLEMS_M002'),
                                               pk_message.get_message(i_lang, 'PROBLEMS_M003'))),
                                 pk_message.get_message(i_lang, 'PROBLEMS_M006')),
                          decode(pp.id_diagnosis,
                                 NULL,
                                 pk_message.get_message(i_lang, 'PROBLEMS_M001'),
                                 pk_message.get_message(i_lang, 'PROBLEMS_M004'))) title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', g_pat_probl_active, i_lang) desc_active,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', g_pat_probl_passive, i_lang) desc_passive,
                   pk_message.get_message(i_lang, 'PROBLEMS_T010') desc_cancel,
                   -- CRS 2006/10/11 Tem de mostrar uma msg em vez do domínio, pq o domínio aparece por extenso e no ecrã 
                   -- alimentado por esta função tem de aparecer a palavra partida 
                   --Pk_Sysdomain.GET_DOMAIN('PAT_PROBLEM.FLG_STATUS', G_PAT_PROBL_CANCEL, I_LANG) DESC_CANCEL,
                   g_pat_probl_active flg_active,
                   g_pat_probl_passive flg_passive,
                   g_pat_probl_cancel flg_cancel1,
                   pp.flg_status,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', pp.flg_status) rank_type,
                   decode(pp.flg_status, g_pat_probl_cancel, 'Y', 'N') flg_cancel
              FROM pat_problem pp, diagnosis d, professional p, epis_diagnosis ed, diagnosis d1, habit h
             WHERE pp.id_patient = i_pat
               AND pp.id_diagnosis = d.id_diagnosis(+)
               AND pp.id_professional_ins = p.id_professional(+)
               AND pp.flg_status = nvl(i_status, pp.flg_status)
               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND pp.id_habit = h.id_habit(+)
               AND ((i_type = 'D' AND pp.id_diagnosis = d.id_diagnosis) OR (i_type = 'H' AND pp.id_habit = h.id_habit) OR
                   (i_type = 'P' AND pp.id_diagnosis IS NULL AND pp.id_epis_diagnosis IS NULL) OR
                   (i_type = 'E' AND ed.id_epis_diagnosis = pp.id_epis_diagnosis) OR nvl(i_type, 'X') = 'X')
            UNION ALL
            SELECT p.id_professional,
                   pa.id_pat_allergy id_problem,
                   'A' TYPE,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_problem2,
                   to_char(pa.year_begin) dt_problem,
                   pk_translation.get_translation(i_lang, a.code_allergy) desc_probl,
                   pk_message.get_message(i_lang, 'PROBLEMS_M005') title,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', g_pat_allergy_active, i_lang) desc_active,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', g_pat_allergy_passive, i_lang) desc_passive,
                   pk_message.get_message(i_lang, 'PROBLEMS_T010') desc_cancel,
                   -- CRS 2006/10/11 Tem de mostrar uma msg em vez do domínio, pq o domínio aparece por extenso e no ecrã 
                   -- alimentado por esta função tem de aparecer a palavra partida 
                   --Pk_Sysdomain.GET_DOMAIN('PAT_ALLERGY.FLG_STATUS', G_PAT_ALLERGY_CANCEL, I_LANG) DESC_CANCEL,
                   g_pat_allergy_active flg_active,
                   g_pat_allergy_passive flg_passive,
                   g_pat_allergy_cancel flg_cancel1,
                   pa.flg_status,
                   pk_sysdomain.get_rank(i_lang, 'PAT_ALLERGY.FLG_STATUS', pa.flg_status) rank_type,
                   decode(pa.flg_status, g_pat_allergy_cancel, 'Y', 'N') flg_cancel
              FROM pat_allergy pa, allergy a, professional p
             WHERE pa.id_patient = i_pat
               AND a.id_allergy = pa.id_allergy
               AND p.id_professional = pa.id_prof_write
               AND pa.flg_status = nvl(i_status, pa.flg_status)
               AND nvl(i_type, 'A') = 'A'
             ORDER BY rank_type, dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PROBLEM',
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            RETURN FALSE;
    END;

    FUNCTION get_pat_problem_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter histórico de mudanças de estado de um problema 
               (problemas, doenças relevantes, diagnósticos, alergias) 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT_PROB - ID do registo 
               I_TYPE - Tipo: P - problema, A - alergia 
               Saida:   O_PAT_PROBLEM - problemas 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/07/24 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_problem FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order,
                   pp.notes,
                   pp.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp.flg_status, i_lang) desc_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_problem_hist pp, professional p, speciality s
             WHERE pp.id_pat_problem = i_pat_prob
               AND 'P' = i_type
               AND pp.id_professional_ins = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
            UNION ALL
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof) dt_order,
                   pp1.notes,
                   pp1.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', pp1.flg_status, i_lang) desc_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p1.id_professional, NULL, NULL) desc_speciality
              FROM pat_problem pp1, professional p1, speciality s1
             WHERE pp1.id_pat_problem = i_pat_prob
               AND 'P' = i_type
               AND pp1.id_professional_ins = p1.id_professional
               AND s1.id_speciality(+) = p1.id_speciality
            UNION ALL
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   pa.notes,
                   pa.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_allergy pa, professional p, speciality s
             WHERE pa.id_pat_allergy = i_pat_prob
               AND 'A' = i_type
               AND pa.id_prof_write = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
            UNION ALL
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   pa.notes,
                   pa.flg_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) desc_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_allergy_hist pa, professional p, speciality s
             WHERE pa.id_pat_allergy = i_pat_prob
               AND 'A' = i_type
               AND pa.id_prof_write = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
             ORDER BY dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PROBLEM_DET',
                                              o_error);
            pk_types.open_my_cursor(o_problem);
            RETURN FALSE;
    END;

    FUNCTION get_relev_disease_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_problem.id_patient%TYPE,
        i_status  IN pat_problem.flg_status%TYPE,
        i_prof    IN profissional,
        o_disease OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter doenças relevantes do utente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_STATUS - estado do registo (activo / cancelado / passivo). 
                    Se ñ está preenchido, retorna todos os registos 
               Saida:   O_DISEASE - doenças relevantes 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/04/29 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_flg_type_med CONSTANT pat_history_diagnosis.flg_type%TYPE := 'M';
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_disease FOR
        -- RdSN 2007/09/24
        -- New model for the relevant diseases
            SELECT phd.id_pat_history_diagnosis,
                   phd.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                              i_id_diagnosis       => d.id_diagnosis,
                                              i_code               => d.code_icd,
                                              i_flg_other          => d.flg_other,
                                              i_flg_std_diag       => ad.flg_icd9) ||
                   decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis) diagnosis,
                   pk_sysdomain.get_domain('PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status, i_lang) status,
                   pk_date_utils.dt_chr_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    phd.dt_pat_history_diagnosis_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   decode(phd.notes, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                   decode(phd.flg_status, g_pat_probl_cancel, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_ord1
              FROM pat_history_diagnosis phd, alert_diagnosis ad, professional p, diagnosis d
             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_patient = i_id_pat
               AND phd.flg_status = nvl(i_status, phd.flg_status)
               AND phd.id_professional = p.id_professional
               AND phd.flg_type = l_flg_type_med
               AND phd.id_alert_diagnosis IS NOT NULL
               AND phd.id_pat_history_diagnosis =
                   pk_problems.get_pat_hist_diag_recent(i_lang,
                                                        phd.id_alert_diagnosis,
                                                        NULL,
                                                        i_id_pat,
                                                        i_prof,
                                                        g_pat_history_diagnosis_n)
             ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status),
                      phd.dt_pat_history_diagnosis_tstz DESC,
                      diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RELEV_DISEASE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_disease);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_relev_disease_det
    (
        i_lang    IN language.id_language%TYPE,
        i_disease IN pat_problem.id_pat_problem%TYPE,
        i_prof    IN profissional,
        o_disease OUT pk_types.cursor_type,
        o_notes   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe da doença relevante 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DISEASE - Id da doença relevante 
               Saida:   O_DISEASE - detalhe da doença relevante    
               O_NOTES - notas da doença relevante  
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/04/29 
          NOTAS: Como é guardado o histórico de mudanças de estado, o cursor O_NOTES 
             inclui notas, responsável e data de registo de cancelamento 
           (PAT_PROBLEM) e de registo (PAT_PROBLEM_HIST) 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        --L_AUX PAT_PROBLEM.ID_PAT_PROBLEM%TYPE;
    
    BEGIN
    
        g_error := 'GET CURSOR O_DISEASE';
        OPEN o_disease FOR
            SELECT phd.id_pat_history_diagnosis,
                   phd.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision) dt,
                   pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                              i_id_diagnosis       => d.id_diagnosis,
                                              i_code               => d.code_icd,
                                              i_flg_other          => d.flg_other,
                                              i_flg_std_diag       => ad.flg_icd9) ||
                   decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis) diagnosis,
                   pk_sysdomain.get_domain('PAT_HISTORY_DIANOGIS.FLG_STATUS', phd.flg_status, i_lang) status,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_pat_problem,
                   decode(phd.flg_status, g_pat_probl_cancel, pk_message.get_message(i_lang, 'COMMON_M017'), '') title_cancel,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_history_diagnosis phd, alert_diagnosis ad, professional p, speciality s, diagnosis d
             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.id_pat_history_diagnosis = i_disease
               AND phd.id_professional = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
             ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIANOGIS.FLG_STATUS', phd.flg_status), diagnosis;
    
        g_error := 'GET CURSOR O_NOTES1';
        OPEN o_notes FOR
            SELECT decode(phd.notes, NULL, 'N', 'R') reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_order,
                   nvl(phd.notes, pk_message.get_message(i_lang, 'COMMON_M007')) notes,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_pat_problem,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_history_diagnosis phd, alert_diagnosis ad, professional p, speciality s
             WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
               AND phd.id_pat_history_diagnosis = i_disease
               AND phd.id_professional = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
             ORDER BY dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RELEV_DISEASE_DET',
                                              o_error);
            pk_types.open_my_cursor(o_disease);
            pk_types.open_my_cursor(o_notes);
            RETURN FALSE;
    END;

    FUNCTION set_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_id_pat         IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN pat_allergy.id_allergy%TYPE,
        i_drug_pharma    IN pat_allergy.id_drug_pharma%TYPE,
        i_notes          IN pat_allergy.notes%TYPE,
        i_dt_first_time  IN VARCHAR2,
        i_flg_type       IN pat_allergy.flg_type%TYPE,
        i_flg_approved   IN pat_allergy.flg_aproved%TYPE,
        i_flg_status     IN pat_allergy.flg_status%TYPE,
        i_dt_symptoms    IN VARCHAR2,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar alergia / reacção idiossincrática. Se for uma actualização,
               basta preencher I_ID_PAT_ALLERGY e I_FLG_STATUS 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT - Id do doente 
             I_PROF - prof. responsável pelo registo 
             I_ALLERGY - ID da alergia 
             I_DRUG_PHARMA - ID do principio activo 
             I_NOTES - notas 
             I_DT_FIRST_TIME - Data de observação dos primeiros sintomas 
             I_FLG_TYPE - I - reacção idiossincrática, A - alergia 
             I_FLG_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
             I_DT_SYMPTOMS - data aproximada de início do problema. É uma 
                   string com formato YYYY-MM-DD q depois é convertida 
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida: O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
             O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
             O_FLG_SHOW = Y 
             O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
             O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
              Tb pode mostrar combinações destes, qd é p/ mostrar 
                                            + do q 1 botão 
             O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/03/23 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        l_exception      EXCEPTION;
        l_id_pat_allergy pat_allergy.id_pat_allergy%TYPE;
    
    BEGIN
    
        IF (NOT pk_allergy.set_allergy(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_patient          => i_id_pat,
                                       i_id_episode          => i_epis,
                                       i_id_pat_allergy      => NULL,
                                       i_id_allergy          => i_allergy,
                                       i_desc_allergy        => NULL,
                                       i_notes               => i_notes,
                                       i_flg_status          => i_flg_status,
                                       i_flg_type            => i_flg_type,
                                       i_flg_aproved         => i_flg_approved,
                                       i_desc_aproved        => NULL,
                                       i_year_begin          => NULL,
                                       i_id_symptoms         => NULL,
                                       i_id_allergy_severity => NULL,
                                       i_flg_edit            => NULL,
                                       i_desc_edit           => NULL,
                                       o_id_pat_allergy      => l_id_pat_allergy,
                                       o_error               => o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION create_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN table_number,
        i_allergy_cancel IN table_number,
        i_status         IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_type           IN table_varchar,
        i_approved       IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_patient.call_create_pat_allergy_array(i_lang           => i_lang,
                                                        i_epis           => i_epis,
                                                        i_pat            => i_pat,
                                                        i_prof           => i_prof,
                                                        i_allergy        => i_allergy,
                                                        i_allergy_cancel => i_allergy_cancel,
                                                        i_status         => i_status,
                                                        i_notes          => i_notes,
                                                        i_dt_symptoms    => i_dt_symptoms,
                                                        i_type           => i_type,
                                                        i_approved       => i_approved,
                                                        i_prof_cat_type  => i_prof_cat_type,
                                                        o_flg_show       => o_flg_show,
                                                        o_msg_title      => o_msg_title,
                                                        o_msg            => o_msg,
                                                        o_button         => o_button,
                                                        o_error          => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PAT_ALLERGY_ARRAY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION call_create_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN table_number,
        i_allergy_cancel IN table_number,
        i_status         IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_type           IN table_varchar,
        i_approved       IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Criar alergias / reacções idiossincráticas do utente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_PAT - Id do doente 
                                 I_PROF - profissional q regista 
                                 I_ALLERGY - array de ID de alergias 
                                 I_ALLERGY_CANCEL - array de ID de alergias a cancelar 
                                 I_STATUS - estado A - activo; C - cancelado; P - passivo 
                                 I_NOTES - array de notas
                                 I_DT_SYMPTOMS - data aproximada de início do problema. É uma 
                         string com formato YYYY-MM-DD q depois é convertida 
                 I_TYPE - I - reacção idiossincrática, A - alergia 
                 I_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                       como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida: O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
                 O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
                 O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
                 O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                    + do q 1 botão 
                 O_ERROR - erro 
                     
          CRIAÇÃO: CRS 2005/03/17 
          ALTERAÇÃO: ASM 2007/01/31 Permite a alteraçâo do estado de uma "SEM ALERGIA / A..." 
               ASM 2007/02/15 Novo parâmetro de entrada que permite verificar se vão ser 
                            canceladas alergias e chamar a função de cancelamento das
                                    mesmas 
          
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        l_exception      EXCEPTION;
        l_id_pat_allergy table_number;
    
    BEGIN
        l_id_pat_allergy := table_number();
    
        IF (NOT pk_allergy.set_allergy_array(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_patient          => i_pat,
                                             i_id_episode          => i_epis,
                                             i_id_pat_allergy      => NULL,
                                             i_id_allergy          => i_allergy,
                                             i_desc_allergy        => NULL,
                                             i_notes               => i_notes,
                                             i_flg_status          => i_status,
                                             i_flg_type            => i_type,
                                             i_flg_aproved         => i_approved,
                                             i_desc_aproved        => NULL,
                                             i_year_begin          => NULL,
                                             i_id_symptoms         => NULL,
                                             i_id_allergy_severity => NULL,
                                             i_flg_edit            => NULL,
                                             i_desc_edit           => NULL,
                                             o_id_pat_allergy      => l_id_pat_allergy,
                                             o_error               => o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PAT_ALLERGY_ARRAY',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION check_selected_allergies
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN pat_allergy.id_patient%TYPE,
        i_allergy     IN pat_allergy.id_allergy%TYPE,
        i_prof        IN profissional,
        o_flg_without OUT allergy.flg_without%TYPE,
        o_allergy     OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO: Função para verificar se foi seleccionada uma "sem alergia a" que 
               possa cancelar outras alergias já registadas ou vice-versa 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_PATIENT - Id do paciente 
                I_ALLERGY - Id da alergia 
                I_PROF - profissional q regista 
               Saida: O_FLG_WITHOUT - Flag que indica para que ecran de detalhe se vai para registar a alergia  
             O_ALLERGY - alergias a serem caneladas 
                                 O_FLG_SHOW - indica se existe ou não uma mensagem a mostrar ao utilizador. Valores possíveis: Y / N 
                                 O_BUTTON - indicadores dos botões a mostrar na mensagem 
                                   Valores possíveis: N - não, R - lido, C - confirmado 
                                            O valor do parâmetro pode ser uma combinação de mais do que um dos valores possíveis
                                 O_MSG_TITLE - Título da mensagem 
                                 O_MSG - Texto da mensagem 
                                 O_ERROR - erro 
               
          CRIAÇÃO: ASM 2007/01/17 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        l_nkda            allergy.flg_without%TYPE;
        l_allergy_out     NUMBER;
        l_reg             NUMBER;
        l_reg_allergy     NUMBER;
        l_reg_allergy_out NUMBER;
    
        CURSOR c_nkda IS
            SELECT a.flg_without
              FROM allergy a
             WHERE a.id_allergy = i_allergy;
    
        CURSOR c_allergy_out IS
            SELECT COUNT(1)
              FROM allergy a
             WHERE a.flg_without IS NOT NULL
               AND a.id_allergy_parent IS NULL
               AND a.id_allergy = i_allergy;
    
        -- Registo de alergias 
        CURSOR c_reg IS
            SELECT COUNT(1)
              FROM pat_allergy pa, allergy a
             WHERE pa.id_patient = i_patient
               AND pa.flg_status != g_pat_allergy_cancel
               AND pa.id_allergy = a.id_allergy
               AND a.flg_without IS NULL
               AND a.id_allergy_parent IS NOT NULL;
    
        -- Registo de "sem alergias a..."   
        CURSOR c_reg_allergy IS
            SELECT COUNT(1)
              FROM pat_allergy pa, allergy a
             WHERE pa.id_patient = i_patient
               AND pa.flg_status != g_pat_allergy_cancel
               AND pa.id_allergy = a.id_allergy
               AND a.flg_without IS NOT NULL
               AND a.id_allergy_parent IS NOT NULL;
    
        -- Registo de "sem alergias"   
        CURSOR c_reg_allergy_out IS
            SELECT COUNT(1)
              FROM pat_allergy pa, allergy a
             WHERE pa.id_patient = i_patient
               AND pa.flg_status != g_pat_allergy_cancel
               AND pa.id_allergy = a.id_allergy
               AND a.flg_without IS NOT NULL
               AND a.id_allergy_parent IS NULL;
    
    BEGIN
    
        g_error := 'GET CURSOR C_NKDA';
        OPEN c_nkda;
        FETCH c_nkda
            INTO l_nkda;
        g_found := c_nkda%NOTFOUND;
        CLOSE c_nkda;
    
        IF l_nkda IS NULL
        THEN
            -- Não se está a registar um "SEM ALERGIAS / A..." 
            g_error := 'GET CURSOR C_REG_ALLERGY';
            OPEN c_reg;
            FETCH c_reg
                INTO l_reg;
            g_found := c_reg%NOTFOUND;
            CLOSE c_reg;
        
            IF l_reg = 0
            THEN
                -- Não existe registo de alergias 
                g_error := 'GET CURSOR C_REG_ALLERGY';
                OPEN c_reg_allergy;
                FETCH c_reg_allergy
                    INTO l_reg_allergy;
                g_found := c_reg_allergy%NOTFOUND;
                CLOSE c_reg_allergy;
            
                IF l_reg_allergy = 0
                THEN
                    -- Não existe registo de "SEM ALERGIAS A..." 
                    g_error := 'GET CURSOR C_REG_ALLERGY_OUT';
                    OPEN c_reg_allergy_out;
                    FETCH c_reg_allergy_out
                        INTO l_reg_allergy_out;
                    g_found := c_reg_allergy_out%NOTFOUND;
                    CLOSE c_reg_allergy_out;
                
                    IF l_reg_allergy_out = 0
                    THEN
                        -- Não existe registo de "SEM ALERGIAS" 
                        o_flg_without := NULL;
                        pk_types.open_my_cursor(o_allergy);
                        o_flg_show  := 'N';
                        o_button    := NULL;
                        o_msg_title := NULL;
                        o_msg       := NULL;
                    ELSE
                        g_error       := 'GET FLAG O_FLG_WITHOUT';
                        o_flg_without := 'N';
                    
                        g_error := 'GET CURSOR O_ALLERGY';
                        OPEN o_allergy FOR
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.id_allergy != i_allergy
                               AND a.id_allergy_parent IS NULL;
                    
                        o_flg_show  := 'Y';
                        o_button    := NULL;
                        o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                        o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M003');
                    END IF;
                ELSE
                    g_error       := 'GET FLAG O_FLG_WITHOUT';
                    o_flg_without := 'N';
                
                    g_error := 'GET CURSOR O_ALLERGY';
                    OPEN o_allergy FOR
                        SELECT pa.id_pat_allergy,
                               a.id_allergy,
                               pk_translation.get_translation(i_lang, a.code_allergy) text
                          FROM pat_allergy pa, allergy a
                         WHERE pa.id_patient = i_patient
                           AND pa.id_allergy IS NOT NULL
                           AND pa.flg_status != g_pat_allergy_cancel
                           AND pa.id_allergy = a.id_allergy
                           AND a.id_allergy != i_allergy
                           AND a.id_allergy_parent IS NULL
                        UNION
                        SELECT pa.id_pat_allergy,
                               a.id_allergy,
                               pk_translation.get_translation(i_lang, a.code_allergy) text
                          FROM pat_allergy pa, allergy a
                         WHERE pa.id_patient = i_patient
                           AND pa.id_allergy IS NOT NULL
                           AND pa.flg_status != g_pat_allergy_cancel
                           AND pa.id_allergy = a.id_allergy
                           AND a.id_allergy != i_allergy
                           AND a.id_allergy_parent = (SELECT a.id_allergy_parent
                                                        FROM allergy a
                                                       WHERE a.id_allergy = i_allergy);
                    o_flg_show  := 'Y';
                    o_button    := NULL;
                    o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                    o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M003');
                END IF;
            ELSE
                g_error := 'GET CURSOR C_REG_ALLERGY';
                OPEN c_reg_allergy;
                FETCH c_reg_allergy
                    INTO l_reg_allergy;
                g_found := c_reg_allergy%NOTFOUND;
                CLOSE c_reg_allergy;
            
                IF l_reg_allergy = 0
                THEN
                    -- Não existe registo de "SEM ALERGIAS A..." 
                    o_flg_without := NULL;
                    pk_types.open_my_cursor(o_allergy);
                    o_flg_show  := 'N';
                    o_button    := NULL;
                    o_msg_title := NULL;
                    o_msg       := NULL;
                ELSE
                    g_error := 'GET CURSOR C_REG_ALLERGY_OUT';
                    OPEN c_reg_allergy_out;
                    FETCH c_reg_allergy_out
                        INTO l_reg_allergy_out;
                    g_found := c_reg_allergy_out%NOTFOUND;
                    CLOSE c_reg_allergy_out;
                
                    IF l_reg_allergy_out = 0
                    THEN
                        -- Não existe registo de "SEM ALERGIAS" 
                        g_error       := 'GET FLAG O_FLG_WITHOUT';
                        o_flg_without := 'N';
                    
                        g_error := 'GET CURSOR O_ALLERGY';
                        OPEN o_allergy FOR
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa,
                                   (SELECT a.id_allergy, a.code_allergy, a.flg_without
                                      FROM allergy a
                                     WHERE pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                                       AND a.id_allergy_parent IS NOT NULL
                                       AND a.id_allergy != i_allergy
                                     START WITH a.id_allergy = (SELECT a.id_allergy_parent
                                                                  FROM allergy a
                                                                 WHERE a.id_allergy = i_allergy)
                                    CONNECT BY PRIOR a.id_allergy = a.id_allergy_parent) a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.flg_without IS NOT NULL;
                        o_flg_show  := 'Y';
                        o_button    := NULL;
                        o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                        o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M004');
                    ELSE
                        g_error       := 'GET FLAG O_FLG_WITHOUT';
                        o_flg_without := 'N';
                    
                        g_error := 'GET CURSOR O_ALLERGY';
                        OPEN o_allergy FOR
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.id_allergy != i_allergy
                               AND a.id_allergy_parent IS NULL
                            UNION
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.id_allergy != i_allergy
                               AND a.id_allergy_parent = (SELECT a.id_allergy_parent
                                                            FROM allergy a
                                                           WHERE a.id_allergy = i_allergy);
                    
                        o_flg_show  := 'Y';
                        o_button    := NULL;
                        o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                        o_msg       := '6'; --Pk_Message.GET_MESSAGE(I_LANG, 'HELP_ALLERGY_M003');
                    END IF;
                END IF;
            
            END IF;
        
        ELSE
            -- Está a registar-se um "SEM ALERGIAS / A..." 
            g_error := 'GET CURSOR C_ALLERGY_OUT';
            OPEN c_allergy_out;
            FETCH c_allergy_out
                INTO l_allergy_out;
            g_found := c_allergy_out%NOTFOUND;
            CLOSE c_allergy_out;
        
            IF l_allergy_out = 0
            THEN
                -- Está a registar-se um "SEM ALERGIAS A..." 
                g_error := 'GET CURSOR C_ALLERGY_OUT';
                OPEN c_reg;
                FETCH c_reg
                    INTO l_reg;
                g_found := c_reg%NOTFOUND;
                CLOSE c_reg;
            
                IF l_reg = 0
                THEN
                    -- Não existem registos de alergias  
                    o_flg_without := 'Y';
                    pk_types.open_my_cursor(o_allergy);
                    o_flg_show  := 'N';
                    o_button    := NULL;
                    o_msg_title := NULL;
                    o_msg       := NULL;
                ELSE
                    g_error       := 'GET FLAG O_FLG_WITHOUT';
                    o_flg_without := 'Y';
                
                    g_error := 'GET CURSOR O_ALLERGY';
                    OPEN o_allergy FOR
                        SELECT pa.id_pat_allergy,
                               a.id_allergy,
                               pk_translation.get_translation(i_lang, a.code_allergy) text
                          FROM pat_allergy pa,
                               (SELECT a.id_allergy, a.code_allergy
                                  FROM allergy a
                                 WHERE pk_translation.get_translation(i_lang, a.code_allergy) IS NOT NULL
                                   AND a.id_allergy_parent IS NOT NULL
                                   AND a.id_allergy != i_allergy
                                 START WITH a.id_allergy = (SELECT a.id_allergy_parent
                                                              FROM allergy a
                                                             WHERE a.id_allergy = i_allergy)
                                CONNECT BY PRIOR a.id_allergy = a.id_allergy_parent) a
                         WHERE pa.id_patient = i_patient
                           AND pa.id_allergy IS NOT NULL
                           AND pa.flg_status != g_pat_allergy_cancel
                           AND pa.id_allergy = a.id_allergy;
                
                    o_flg_show  := 'Y';
                    o_button    := NULL;
                    o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                    o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M001');
                END IF;
            ELSE
                -- Está a registar-se um "SEM ALERGIAS"  
                IF l_reg = 0
                THEN
                    -- Não existem registos de alergias  
                    o_flg_without := 'Y';
                    pk_types.open_my_cursor(o_allergy);
                    o_flg_show  := 'N';
                    o_button    := NULL;
                    o_msg_title := NULL;
                    o_msg       := NULL;
                ELSE
                    g_error := 'GET CURSOR C_REG_ALLERGY';
                    OPEN c_reg_allergy;
                    FETCH c_reg_allergy
                        INTO l_reg_allergy;
                    g_found := c_reg_allergy%NOTFOUND;
                    CLOSE c_reg_allergy;
                
                    IF l_reg_allergy = 0
                    THEN
                        -- Não existem registos de "SEM ALERGIAS A..." 
                        g_error       := 'GET FLAG O_FLG_WITHOUT';
                        o_flg_without := 'Y';
                    
                        g_error := 'GET CURSOR O_ALLERGY';
                        OPEN o_allergy FOR
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.id_allergy != i_allergy;
                        o_flg_show  := 'Y';
                        o_button    := NULL;
                        o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                        o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M002');
                    ELSE
                        g_error       := 'GET FLAG O_FLG_WITHOUT';
                        o_flg_without := 'Y';
                    
                        g_error := 'GET CURSOR O_ALLERGY';
                        OPEN o_allergy FOR
                            SELECT pa.id_pat_allergy,
                                   a.id_allergy,
                                   pk_translation.get_translation(i_lang, a.code_allergy) text
                              FROM pat_allergy pa, allergy a
                             WHERE pa.id_patient = i_patient
                               AND pa.id_allergy IS NOT NULL
                               AND pa.flg_status != g_pat_allergy_cancel
                               AND pa.id_allergy = a.id_allergy
                               AND a.id_allergy != i_allergy
                               AND a.flg_without IS NULL;
                        o_flg_show  := 'Y';
                        o_button    := NULL;
                        o_msg_title := pk_message.get_message(i_lang, 'HELP_ALLERGY_T001');
                        o_msg       := pk_message.get_message(i_lang, 'HELP_ALLERGY_M002');
                    END IF;
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
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_SELECTED_ALLERGIES',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_aux_pat_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_allergy IN pat_allergy.id_allergy%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO: Função intermédia de criação de registo 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ALLERGY - Id da alergia 
               Saida:   O_ALLERGY - alergias  
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/06/25 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_char_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software);
    
        g_error := 'GET CURSOR';
        OPEN o_allergy FOR
            SELECT pk_translation.get_translation(i_lang, a.code_allergy) allergy,
                   g_sysdate_char dt_server,
                   g_pat_allergy_all flg_type,
                   g_pat_allergy_pat flg_aproved,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', g_pat_allergy_all, i_lang) TYPE,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_APROVED', g_pat_allergy_pat, i_lang) SOURCE
              FROM allergy a
             WHERE a.id_allergy = i_allergy
               AND a.flg_available = g_pat_allergy_available;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AUX_PAT_ALLERGY',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_allergy_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_allergy.id_patient%TYPE,
        i_status  IN pat_allergy.flg_status%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter alergias / reacções idiossincráticas do utente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_STATUS - estado do registo (activo / cancelado / passivo). 
                    Se ñ está preenchido, retorna todos os registos 
               Saida:   O_ALLERGY - alergias  
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/03/17 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
    
        g_error := 'GET CURSOR';
        IF (NOT pk_allergy.get_viewer_allergy_list(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => i_id_pat,
                                                   i_episode => NULL,
                                                   o_allergy => o_allergy,
                                                   o_error   => o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_ALLERGY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_allergy_det
    (
        i_lang    IN language.id_language%TYPE,
        i_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_notes   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe da alergia / reacção idiossincrática  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ALLERGY - Id da alergia / reacção idiossincrática  
               Saida:   O_ALLERGY - detalhe da alergia   
               O_NOTES - notas da alergia 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/04/29 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET CURSOR O_ALLERGY';
        OPEN o_allergy FOR
            SELECT DISTINCT pa.id_pat_allergy,
                            pa.flg_status,
                            pa.flg_type,
                            pa.flg_aproved,
                            pa.year_begin dt,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        decode(nvl(hist.id_pat_allergy, 0),
                                                               0,
                                                               pa.dt_pat_allergy_tstz,
                                                               hist.dt_pat_allergy_tstz),
                                                        i_prof.institution,
                                                        i_prof.software) dt_pat_allergy,
                            decode(nvl(hist.id_pat_allergy, 0),
                                   0,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                   hist.nick_name) nick_name,
                            pk_translation.get_translation(i_lang, a.code_allergy) allergy,
                            pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) TYPE,
                            pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) status,
                            pk_sysdomain.get_domain('PAT_ALLERGY.FLG_APROVED', pa.flg_aproved, i_lang) aproved,
                            decode(pa.flg_status,
                                   g_pat_allergy_cancel,
                                   pk_message.get_message(i_lang, 'COMMON_M017'),
                                   '') title_cancel,
                            decode(nvl(hist.id_pat_allergy, 0),
                                   0,
                                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL),
                                   pk_translation.get_translation(i_lang, hist.code_speciality)) desc_speciality
              FROM pat_allergy pa,
                   allergy a,
                   professional p,
                   speciality s,
                   (SELECT pah.id_pat_allergy,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) nick_name,
                           pah.dt_pat_allergy_tstz,
                           s1.code_speciality
                      FROM pat_allergy_hist pah, professional p1, speciality s1
                     WHERE pah.id_pat_allergy = i_allergy
                       AND pah.id_prof_write = p1.id_professional
                       AND s1.id_speciality(+) = p1.id_speciality
                       AND pah.dt_pat_allergy_tstz =
                           (SELECT MIN(h1.dt_pat_allergy_tstz)
                              FROM pat_allergy_hist h1
                             WHERE h1.id_pat_allergy = pah.id_pat_allergy)) hist
             WHERE pa.id_allergy = a.id_allergy
               AND pa.id_pat_allergy = i_allergy
               AND pa.id_prof_write = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
               AND hist.id_pat_allergy(+) = pa.id_pat_allergy
             ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_ALLERGY.FLG_STATUS', pa.flg_status),
                      pk_sysdomain.get_rank(i_lang, 'PAT_ALLERGY.FLG_TYPE', pa.flg_type),
                      allergy;
    
        g_error := 'GET CURSOR O_NOTES';
        OPEN o_notes FOR
            SELECT decode(pa.notes, NULL, 'N', 'R') reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   nvl(pa.notes, pk_message.get_message(i_lang, 'COMMON_M007')) notes,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) dsec_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_allergy_hist pa, professional p, speciality s
             WHERE pa.id_pat_allergy = i_allergy
               AND pa.id_prof_write = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
            UNION ALL
            SELECT decode(pa.notes, NULL, 'N', 'R') reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order,
                   nvl(pa.notes, pk_message.get_message(i_lang, 'COMMON_M007')) notes,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) dsec_status,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) desc_speciality
              FROM pat_allergy pa, professional p, speciality s
             WHERE pa.id_pat_allergy = i_allergy
               AND pa.id_prof_write = p.id_professional
               AND s.id_speciality(+) = p.id_speciality
             ORDER BY dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_ALLERGY_DET',
                                              o_error);
            pk_types.open_my_cursor(o_allergy);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION call_cancel_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar alergia de um doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_ALLERGY - ID de uma alergia 
               I_DRUG_PHARMA - ID de um princípio activo 
               I_STATUS - estado do registo: A - activo; C - cancelado. 
                    Se ñ for preenchido, traz todos os registos, 
                 independente/ do estado 
               Saida:   O_VACCINE - vacinas administradas 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/03/24 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_pat_allergy pat_allergy%ROWTYPE;
        --
        l_error VARCHAR2(4000);
        CURSOR c_cancel IS
            SELECT *
              FROM pat_allergy
             WHERE id_pat_allergy = i_id_pat_allergy;
        --    AND FLG_STATUS = G_PAT_ALLERGY_CANCEL;
    
        -- denormalization variables
        l_rowids table_varchar;
        l_ret    BOOLEAN;
    
        e_canceled EXCEPTION;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR C_CANCEL';
        OPEN c_cancel;
        FETCH c_cancel
            INTO l_pat_allergy;
        CLOSE c_cancel;
    
        --Verifica se o registo já estava cancelado
        IF l_pat_allergy.flg_status = g_pat_allergy_cancel
        THEN
        
            RAISE e_canceled;
        END IF;
    
        g_error := 'INSERT HIST';
        --Insere o registo no histórico
        INSERT INTO pat_allergy_hist
            (id_pat_allergy_hist,
             id_patient,
             id_pat_allergy,
             dt_pat_allergy_tstz,
             flg_status,
             notes,
             id_prof_write,
             dt_first_time_tstz,
             flg_type,
             flg_aproved,
             id_allergy,
             id_drug_pharma,
             year_begin,
             month_begin,
             day_begin,
             year_end,
             month_end,
             day_end,
             id_institution,
             id_episode)
        VALUES
            (seq_pat_allergy_hist.nextval,
             l_pat_allergy.id_patient,
             l_pat_allergy.id_pat_allergy,
             l_pat_allergy.dt_pat_allergy_tstz,
             l_pat_allergy.flg_status,
             l_pat_allergy.notes,
             l_pat_allergy.id_prof_write,
             l_pat_allergy.dt_first_time_tstz,
             l_pat_allergy.flg_type,
             l_pat_allergy.flg_aproved,
             l_pat_allergy.id_allergy,
             l_pat_allergy.id_drug_pharma,
             l_pat_allergy.year_begin,
             l_pat_allergy.month_begin,
             l_pat_allergy.day_begin,
             l_pat_allergy.year_end,
             l_pat_allergy.month_end,
             l_pat_allergy.day_end,
             l_pat_allergy.id_institution,
             l_pat_allergy.id_episode);
    
        g_error := 'UPDATE PAT_ALLERGY';
        ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy,
                           id_prof_write_in       => i_prof.id,
                           dt_pat_allergy_tstz_in => g_sysdate,
                           notes_in               => i_notes,
                           flg_status_in          => g_pat_allergy_cancel,
                           rows_out               => l_rowids);
    
        -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => l_pat_allergy.id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_canceled THEN
            IF i_lang = 1
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                   '@1',
                                   'alergia/reacção idiossincrática');
            ELSIF i_lang = 2
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'allergy/allergic reaction');
            ELSIF i_lang = 3
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                   '@1',
                                   'alergia/reacción idiosincrática');
            ELSIF i_lang = 4
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'allergie/allergische reactie');
            ELSIF i_lang = 5
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                   '@1',
                                   'allergia/reazione idiosincratica');
            ELSIF i_lang = 6
            THEN
                l_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                   '@1',
                                   'allergie/réaction idiosyncrasique');
            END IF;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              l_error,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_CANCEL_PAT_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_CANCEL_PAT_ALLERGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION cancel_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT call_cancel_pat_allergy(i_lang           => i_lang,
                                       i_id_pat_allergy => i_id_pat_allergy,
                                       i_prof           => i_prof,
                                       i_notes          => i_notes,
                                       o_error          => o_error)
        
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            NULL;
    END;

    FUNCTION cancel_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN table_number,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Cancelar as alergias de um paciente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT_ALLERGY - Array de IDs das alergia 
             I_PROF - profissional 
             I_NOTES - notas de cancelamento 
               Saida: O_ERROR - erro 
               
          CRIAÇÃO: ASM 2007/01/22 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *********************************************************************************/
        l_pat_allergy pat_allergy%ROWTYPE;
    
        -- denormalization variables
        l_rowids table_varchar;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_pat_allergy.count
        LOOP
        
            SELECT *
              INTO l_pat_allergy
              FROM pat_allergy
             WHERE id_pat_allergy = i_id_pat_allergy(i);
        
            -- Verifica se o registo já estava cancelado 
            IF l_pat_allergy.flg_status = g_pat_allergy_cancel
            THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                                          '@1',
                                                          pk_message.get_message(i_lang, 'ALLERGY_LIST_M004')),
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_PROF_PHOTO_URL',
                                                  o_error);
                RETURN FALSE;
            END IF;
        
            g_error := 'INSERT PAT_ALLERGY_HIST';
            -- Insere o registo no histórico 
            INSERT INTO pat_allergy_hist
                (id_pat_allergy_hist,
                 id_pat_allergy,
                 dt_pat_allergy_tstz,
                 id_allergy,
                 id_patient,
                 id_drug_pharma,
                 flg_status,
                 notes,
                 id_prof_write,
                 dt_first_time_tstz,
                 flg_type,
                 flg_aproved,
                 year_begin,
                 month_begin,
                 day_begin,
                 year_end,
                 month_end,
                 day_end,
                 id_institution,
                 id_episode,
                 flg_nature)
            VALUES
                (seq_pat_allergy_hist.nextval,
                 l_pat_allergy.id_pat_allergy,
                 l_pat_allergy.dt_pat_allergy_tstz,
                 l_pat_allergy.id_allergy,
                 l_pat_allergy.id_patient,
                 l_pat_allergy.id_drug_pharma,
                 l_pat_allergy.flg_status,
                 l_pat_allergy.notes,
                 l_pat_allergy.id_prof_write,
                 l_pat_allergy.dt_first_time_tstz,
                 l_pat_allergy.flg_type,
                 l_pat_allergy.flg_aproved,
                 l_pat_allergy.year_begin,
                 l_pat_allergy.month_begin,
                 l_pat_allergy.day_begin,
                 l_pat_allergy.year_end,
                 l_pat_allergy.month_end,
                 l_pat_allergy.day_end,
                 l_pat_allergy.id_institution,
                 l_pat_allergy.id_episode,
                 l_pat_allergy.flg_nature);
        
            g_error := 'UPDATE PAT_ALLERGY';
            ts_pat_allergy.upd(id_pat_allergy_in      => i_id_pat_allergy(i),
                               id_prof_write_in       => i_prof.id,
                               dt_pat_allergy_tstz_in => g_sysdate,
                               notes_in               => i_notes,
                               flg_status_in          => g_pat_allergy_cancel,
                               rows_out               => l_rowids);
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_ALLERGY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => NULL,
                                          i_pat                 => l_pat_allergy.id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
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
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_ALLERGY_ARRAY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION check_pat_allergy
    (
        i_lang      IN language.id_language%TYPE,
        i_allergy   IN allergy.id_allergy%TYPE,
        i_id_pat    IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Verifica se a alergia já tinha sido atribuída ao doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ALLERGY - ID da alergia 
               I_ID_PAT - ID do doente 
               Saida:   O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
               O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                     O_FLG_SHOW = Y 
               O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
               O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                 + do q 1 botão 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/07/24 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        l_char VARCHAR2(1);
    
        CURSOR c_allr IS
            SELECT 'X'
              FROM pat_allergy pa, allergy a
             WHERE pa.id_allergy = i_allergy
               AND pa.id_patient = i_id_pat
               AND a.id_allergy = pa.id_allergy;
        --    AND PA.FLG_STATUS != G_PAT_ALLERGY_CANCEL;
    
    BEGIN
        o_flg_show := 'N';
    
        g_error := 'OPEN CURSOR C_ALLR';
        OPEN c_allr;
        FETCH c_allr
            INTO l_char;
        g_found := c_allr%FOUND; -- Esta alergia já foi atribuída a este doente 
        CLOSE c_allr;
    
        IF g_found
        THEN
            o_flg_show  := 'Y';
            o_msg_text  := pk_message.get_message(i_lang, 'PATIENT_M008');
            o_msg_title := pk_message.get_message(i_lang, 'PATIENT_M009');
            o_button    := 'R';
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
                                              'CHECK_PAT_ALLERGY',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION set_pat_soc_att
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_name             IN patient.name%TYPE,
        i_nick_name        IN patient.nick_name%TYPE,
        i_gender           IN patient.gender%TYPE,
        i_dt_birth         IN patient.dt_birth%TYPE,
        i_isencao          IN pat_soc_attributes.id_isencao%TYPE,
        i_dt_deceased      IN patient.dt_deceased%TYPE,
        i_marital_status   IN pat_soc_attributes.marital_status%TYPE,
        i_address          IN pat_soc_attributes.address%TYPE,
        i_location         IN pat_soc_attributes.location%TYPE,
        i_district         IN pat_soc_attributes.district%TYPE,
        i_zip_code         IN pat_soc_attributes.zip_code%TYPE,
        i_country_nat      IN pat_soc_attributes.id_country_nation%TYPE,
        i_country_res      IN pat_soc_attributes.id_country_address%TYPE,
        i_scholarship      IN pat_soc_attributes.id_scholarship%TYPE,
        i_religion         IN pat_soc_attributes.id_religion%TYPE,
        i_num_main_contact IN pat_soc_attributes.num_main_contact%TYPE,
        i_num_contact      IN pat_soc_attributes.num_contact%TYPE,
        i_flg_job_status   IN pat_soc_attributes.flg_job_status%TYPE,
        i_father_name      IN pat_soc_attributes.father_name%TYPE,
        i_mother_name      IN pat_soc_attributes.mother_name%TYPE,
        i_job              IN pat_job.id_occupation%TYPE,
        i_recm             IN recm.id_recm%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        *   Cancelar problema do doente  
        * @param     I_LANG - Língua registada como preferência do profissional 
        * @param     I_ID_PAT - Id do doente 
        * @param     I_PROF - profissional q regista 
        * @param     I_NAME - nome completo 
        * @param     I_NICK_NAME - nome abreviado 
        * @param     I_GENDER - sexo (M / F) 
        * @param     I_DT_BIRTH - data bnascimento 
        * @param     I_ISENCAO - isenção 
        * @param     I_DT_DECEASED - data falecimento 
        * @param     I_MARITAL_STATUS - estado civil 
        * @param     I_ADDRESS, I_ZIP_CODE, I_LOCATION - morada, cód postal, localidade 
        * @param     I_DISTRICT - distrito 
        * @param     I_COUNTRY_NAT - país de naturalidade 
        * @param     I_COUNTRY_RES - país de residência 
        * @param     I_SCHOLARSHIP - escolaridade 
        * @param     I_RELIGION - religião 
        * @param     I_NUM_MAIN_CONTACT - nº telefone principal 
        * @param     I_NUM_CONTACT - nº telefone alternativo 
        * @param     I_FLG_JOB_STATUS - actual situação profissional  
        * @param     I_JOB - ID da ocupação 
        * @param     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                            como é retornada em PK_LOGIN.GET_PROF_PREF 
        * @param     I_EPIS
        * @param     O_ERROR - erro 
                 
        * @author     CRS 
        * @version    
        * @since     2005/03/14 
        *
        * @author  Pedro Santos
        * @version 2.4.3-Denormalized
        * @since   2008/10/30  
        * reason need to include i_epis
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next     pat_soc_attributes.id_pat_soc_attributes%TYPE;
        l_char     VARCHAR2(1);
        l_pat_cli  VARCHAR2(1);
        l_next_cli pat_cli_attributes.id_pat_cli_attributes%TYPE;
        l_code     ine_location.ine_freguesia%TYPE;
        l_rowids   table_varchar;
        CURSOR c_pat IS
            SELECT 'X'
              FROM pat_soc_attributes
             WHERE id_patient = i_id_pat;
    
        CURSOR c_pat_cli IS
            SELECT 'X'
              FROM pat_cli_attributes
             WHERE id_patient = i_id_pat
               AND id_institution = i_prof.institution;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --SS 2006/08/02: codificação do INE para distrito/concelho/freguesia (necessário para a prescrição - ficheiro XML)
        -- 2006/09/02 : lógica do cálculo de INE_LOCATION em função interna
        IF NOT find_ine_location_internal(i_lang, i_prof, i_zip_code, l_code, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CURSOR C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_char;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            g_error := 'GET SEQ_PAT_SOC_ATTRIBUTES.NEXTVAL';
            l_next  := ts_pat_soc_attributes.next_key();
        
            g_error := 'INSERT INTO PAT_SOC_ATTRIBUTES';
            ts_pat_soc_attributes.ins(id_pat_soc_attributes_in => l_next,
                                      id_patient_in            => i_id_pat,
                                      marital_status_in        => i_marital_status,
                                      address_in               => i_address,
                                      location_in              => i_location,
                                      district_in              => i_district,
                                      zip_code_in              => i_zip_code,
                                      num_main_contact_in      => i_num_main_contact,
                                      num_contact_in           => i_num_contact,
                                      flg_job_status_in        => i_flg_job_status,
                                      id_country_nation_in     => i_country_nat,
                                      id_country_address_in    => i_country_res,
                                      id_scholarship_in        => i_scholarship,
                                      id_religion_in           => i_religion,
                                      mother_name_in           => i_mother_name,
                                      father_name_in           => i_father_name,
                                      id_isencao_in            => i_isencao,
                                      id_institution_in        => i_prof.institution,
                                      ine_location_in          => l_code,
                                      id_episode_in            => nvl(i_epis, -1),
                                      rows_out                 => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-PAT_SOC_ATTRIBUTES';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_SOC_ATTRIBUTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            g_error := 'GET CURSOR C_PAT_CLI';
            OPEN c_pat_cli;
            FETCH c_pat_cli
                INTO l_pat_cli;
            g_found := c_pat_cli%FOUND;
            CLOSE c_pat_cli;
        
            IF NOT g_found
            THEN
                g_error    := 'GET SEQ_PAT_CLI_ATTRIBUTES.NEXTVAL';
                l_next_cli := ts_pat_cli_attributes.next_key();
            
                g_error := 'INSERT INTO PAT_CLI_ATTRIBUTES';
                ts_pat_cli_attributes.ins(id_pat_cli_attributes_in => l_next_cli,
                                          id_patient_in            => i_id_pat,
                                          id_institution_in        => i_prof.institution,
                                          id_recm_in               => i_recm,
                                          id_episode_in            => nvl(i_epis, -1),
                                          rows_out                 => l_rowids);
                g_error := 'UPDATES T_DATA_GOV_MNT-PAT_CLI_ATTRIBUTES';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_CLI_ATTRIBUTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            ELSE
                g_error := 'UPDATE PAT_CLI_ATTRIBUTES';
                UPDATE pat_cli_attributes
                   SET id_recm = i_recm
                 WHERE id_patient = i_id_pat;
            
            END IF;
        
        ELSE
            g_error := 'UPDATE';
            UPDATE pat_soc_attributes
               SET marital_status     = i_marital_status,
                   id_isencao         = i_isencao,
                   address            = i_address,
                   location           = i_location,
                   district           = i_district,
                   zip_code           = i_zip_code,
                   num_main_contact   = i_num_main_contact,
                   num_contact        = i_num_contact,
                   flg_job_status     = i_flg_job_status,
                   id_country_nation  = i_country_nat,
                   id_country_address = i_country_res,
                   id_scholarship     = i_scholarship,
                   id_religion        = i_religion,
                   mother_name        = i_mother_name,
                   father_name        = i_father_name,
                   ine_location       = l_code
             WHERE id_patient = i_id_pat;
        
            g_error := 'GET CURSOR C_PAT_CLI';
            OPEN c_pat_cli;
            FETCH c_pat_cli
                INTO l_pat_cli;
            g_found := c_pat_cli%FOUND;
            CLOSE c_pat_cli;
        
            IF NOT g_found
            THEN
                g_error    := 'GET SEQ_PAT_CLI_ATTRIBUTES.NEXTVAL';
                l_next_cli := ts_pat_cli_attributes.next_key();
            
                g_error := 'INSERT INTO PAT_CLI_ATTRIBUTES';
                ts_pat_cli_attributes.ins(id_pat_cli_attributes_in => l_next_cli,
                                          id_patient_in            => i_id_pat,
                                          id_institution_in        => i_prof.institution,
                                          id_recm_in               => i_recm,
                                          id_episode_in            => nvl(i_epis, -1),
                                          rows_out                 => l_rowids);
                g_error := 'UPDATES T_DATA_GOV_MNT-PAT_CLI_ATTRIBUTES';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_CLI_ATTRIBUTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            ELSE
                g_error := 'UPDATE PAT_CLI_ATTRIBUTES';
                UPDATE pat_cli_attributes
                   SET id_recm = i_recm
                 WHERE id_patient = i_id_pat;
            
            END IF;
        
        END IF;
    
        g_error := 'CALL TO SET_PAT_INFO';
        IF NOT set_pat_info(i_lang        => i_lang,
                            i_id_pat      => i_id_pat,
                            i_name        => i_name,
                            i_nick_name   => i_nick_name,
                            i_gender      => i_gender,
                            i_dt_birth    => i_dt_birth,
                            i_dt_deceased => i_dt_deceased,
                            o_error       => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        IF i_job = -1
        THEN
            g_error := 'DELETE PAT_JOB';
            DELETE pat_job
             WHERE id_patient = i_id_pat;
        
        ELSIF i_job IS NOT NULL
        THEN
            g_error := 'CALL TO SET_PAT_JOB_INTERNAL';
            IF NOT set_pat_job_internal(i_lang              => i_lang,
                                        i_id_pat            => i_id_pat,
                                        i_occup             => i_job,
                                        i_prof              => i_prof,
                                        i_location          => NULL,
                                        i_year_begin        => NULL,
                                        i_year_end          => NULL,
                                        i_activity_type     => NULL,
                                        i_prof_disease_risk => NULL,
                                        i_notes             => NULL,
                                        i_num_workers       => NULL,
                                        i_company           => NULL,
                                        i_prof_cat_type     => i_prof_cat_type,
                                        i_occupation_desc   => NULL,
                                        i_epis              => nvl(i_epis, -1),
                                        o_error             => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                ROLLBACK;
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'SET_PAT_SOC_ATT');
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END;

    FUNCTION get_pat_soc_att
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_pat    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter atributos sociais do doente  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_PROF - ID do prof 
               O_PAT - Retorna atributos do doente
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/14 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        g_error := 'GET o_pat';
        OPEN o_pat FOR
            SELECT pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', p.marital_status, i_lang) desc_marital_status,
                   p.marital_status,
                   p.address,
                   p.location,
                   p.district,
                   p.zip_code,
                   pk_translation.get_translation(i_lang, i.code_isencao) desc_isencao,
                   i.id_isencao,
                   pk_translation.get_translation(i_lang, ctr.code_country) country_nation,
                   pk_translation.get_translation(i_lang, ctr_add.code_country) country_address,
                   pk_translation.get_translation(i_lang, s.code_scholarship) schol,
                   pk_translation.get_translation(i_lang, r.code_religion) relig,
                   num_main_contact,
                   num_contact,
                   flg_job_status,
                   p.id_scholarship,
                   p.id_religion,
                   pk_sysdomain.get_domain_no_avail('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', flg_job_status, i_lang) job_status,
                   pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) gend,
                   father_name,
                   mother_name,
                   p.id_patient,
                   p.id_country_nation,
                   p.id_country_address,
                   pk_translation.get_translation(i_lang, o.code_occupation) occup,
                   o.id_occupation,
                   pat.name,
                   pat.nick_name,
                   pat.gender,
                   pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) dt_birth_string,
                   pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) dt_birth,
                   pat.dt_birth dt_birth_dt, -- JS: 2007-05-14, necário para interface de registo de utentes no sonho
                   pk_date_utils.dt_chr(i_lang, pat.dt_deceased, i_prof) dt_deceased,
                   pk_patient.get_pat_age(i_lang, i_id_pat, i_prof) age,
                   cr.num_clin_record num_prc_clin,
                   rm.flg_recm,
                   pca.id_recm
              FROM patient pat,
                   pat_soc_attributes p,
                   country ctr,
                   country ctr_add,
                   scholarship s,
                   religion r,
                   occupation o,
                   clin_record cr,
                   isencao i,
                   pat_cli_attributes pca,
                   recm rm,
                   (SELECT *
                      FROM pat_job
                     WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                FROM pat_job p1
                                               WHERE p1.id_patient = i_id_pat)) pj
             WHERE pat.id_patient = i_id_pat
               AND cr.id_patient(+) = pat.id_patient
               AND cr.id_institution(+) = i_prof.institution
               AND p.id_patient(+) = pat.id_patient
               AND ctr.id_country(+) = p.id_country_nation
               AND ctr_add.id_country(+) = p.id_country_address
               AND s.id_scholarship(+) = p.id_scholarship
               AND r.id_religion(+) = p.id_religion
               AND pj.id_patient(+) = p.id_patient
               AND o.id_occupation(+) = pj.id_occupation
               AND cr.flg_status(+) = g_clin_rec_active
               AND i.id_isencao(+) = p.id_isencao
               AND pca.id_patient(+) = pat.id_patient
               AND pca.id_institution(+) = i_prof.institution
               AND rm.id_recm(+) = pca.id_recm;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_SOC_ATT',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END;

    /**************************************************************************
    * Register the patient's necessities.
    *   
    * @param i_lang               Language ID 
    * @param i_prof               Professional info 
    * @param i_id_patient         Patient ID 
    * @param i_id_episode         Episode ID
    * @param i_tbl_id_necessity   Array with necessities ID 
    * @param i_tbl_flg_status     Array with the necessities status 
    * @param i_sysdate            Register date
    * @param i_id_epis_triage     Triage event ID
    * @param i_id_institution     Institution where the necessity is registered ID
    * @param o_error              Error message 
    *
    * @return                TRUE / FALSE
    *                        
    * @author                Sergio Dias
    * @version               2.6.3.8.1
    * @since                 16-9-2013
    **************************************************************************/
    FUNCTION set_pat_necessity_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_tbl_id_necessity IN table_number,
        i_tbl_flg_status   IN table_varchar,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_triage   IN epis_triage.id_epis_triage%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'SET_PAT_NECESS_INTERNAL';
        l_next      pat_necessity.id_pat_necessity%TYPE;
        l_next_hist pat_necessity_hist.id_pat_necessity_hist%TYPE;
        l_status    pat_necessity.flg_status%TYPE;
    
        l_rowids      table_varchar := table_varchar();
        l_rows_etr_pn table_varchar;
        l_rowids_hist table_varchar;
    
        l_id_pat_necessity pat_necessity.id_pat_necessity%TYPE;
        l_count            NUMBER;
    
        CURSOR c_necess(l_id pat_necessity.id_necessity%TYPE) IS
            SELECT pn.id_pat_necessity
              FROM pat_necessity pn
             WHERE pn.id_patient = i_id_patient
               AND pn.id_institution = nvl(i_id_institution, i_prof.institution)
               AND pk_episode.get_id_visit(i_episode => pn.id_episode) =
                   pk_episode.get_id_visit(i_episode => i_id_episode)
               AND pn.id_necessity = l_id
               AND pn.flg_status <> g_pat_necess_inactive;
    
    BEGIN
        g_error := 'BEGIN NECESSITIES LOOP';
        pk_alertlog.log_debug(g_error);
        g_sysdate_tstz := current_timestamp;
        FOR i IN 1 .. i_tbl_id_necessity.count
        LOOP
            l_id_pat_necessity := NULL;
            l_next             := NULL;
        
            g_error := 'GET CURSOR C_NECESS (' || i_tbl_id_necessity(i) || ')';
            pk_alertlog.log_debug(g_error);
            OPEN c_necess(i_tbl_id_necessity(i));
            FETCH c_necess
                INTO l_id_pat_necessity;
            g_found := c_necess%FOUND;
            CLOSE c_necess;
        
            IF g_found
            THEN
                IF i_tbl_flg_status(i) = g_pat_necess_inactive
                THEN
                    -- check if this record is referenced in epis_triage_pat_necessity
                    g_error := 'GET COUNT EPIS_TRIAGE_PAT_NECESSITY';
                    pk_alertlog.log_debug(g_error);
                    SELECT COUNT(1)
                      INTO l_count
                      FROM epis_triage_pat_necessity etpn
                     WHERE etpn.id_pat_necessity = l_id_pat_necessity;
                
                    IF nvl(l_count, 0) > 0
                    THEN
                        -- if it is, it can not be deleted so it is inactivated
                        g_error := 'UPDATE PAT_NECESSITY';
                        pk_alertlog.log_debug(g_error);
                        UPDATE pat_necessity
                           SET flg_status = i_tbl_flg_status(i)
                         WHERE id_patient = i_id_patient
                           AND id_necessity = i_tbl_id_necessity(i)
                           AND id_institution = nvl(i_id_institution, i_prof.institution)
                           AND id_episode = i_id_episode;
                    ELSE
                        -- if it is not referenced, delete it
                        g_error := 'TS_PAT_NECESSITY.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_pat_necessity.del_by(where_clause_in => 'id_pat_necessity = ' || l_id_pat_necessity);
                    END IF;
                    l_id_pat_necessity := NULL;
                ELSE
                    -- A record for this necessity already exists, update it
                    g_error := 'UPDATE (' || i_tbl_id_necessity(i) || ')';
                    pk_alertlog.log_debug(g_error);
                
                    UPDATE pat_necessity
                       SET flg_status = i_tbl_flg_status(i)
                     WHERE id_pat_necessity = l_id_pat_necessity;
                END IF;
            
            ELSE
                IF i_tbl_flg_status(i) IN (g_pat_necess_active_config, g_pat_necess_active)
                THEN
                    -- insert a new record in PAT_NECESSITY 
                    g_error := 'GET SEQ_PAT_NECESSITY.NEXTVAL';
                    l_next  := ts_pat_necessity.next_key();
                
                    g_error := 'INSERT PAT_NECESSITY(' || i_tbl_id_necessity(i) || ')';
                    pk_alertlog.log_debug(g_error);
                    ts_pat_necessity.ins(id_pat_necessity_in => l_next,
                                         id_patient_in       => i_id_patient,
                                         id_necessity_in     => i_tbl_id_necessity(i),
                                         flg_status_in       => i_tbl_flg_status(i),
                                         id_institution_in   => nvl(i_id_institution, i_prof.institution),
                                         id_episode_in       => i_id_episode,
                                         rows_out            => l_rowids);
                
                    g_error := 'SET DATA GOVERNANCE';
                    pk_alertlog.log_debug(g_error);
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_NECESSITY',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            END IF;
        
            -- insert in PAT_NECESSITY_HIST
            IF (l_next IS NOT NULL OR l_id_pat_necessity IS NOT NULL)
               AND i_tbl_flg_status(i) IN (g_pat_necess_active_config, g_pat_necess_active)
            THEN
                g_error     := 'GET SEQ_PAT_NECESSITY.NEXTVAL';
                l_next_hist := ts_pat_necessity_hist.next_key();
            
                g_error := 'INSERT PAT_NECESSITY_HIST(' || i_tbl_id_necessity(i) || ')';
                pk_alertlog.log_debug(g_error);
                ts_pat_necessity_hist.ins(id_pat_necessity_hist_in => l_next_hist,
                                          dt_register_in           => nvl(i_sysdate, g_sysdate_tstz),
                                          id_pat_necessity_in      => nvl(l_next, l_id_pat_necessity),
                                          id_patient_in            => i_id_patient,
                                          id_necessity_in          => i_tbl_id_necessity(i),
                                          flg_status_in            => i_tbl_flg_status(i),
                                          id_institution_in        => nvl(i_id_institution, i_prof.institution),
                                          id_episode_in            => i_id_episode,
                                          rows_out                 => l_rowids_hist);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_NECESSITY_HIST',
                                              i_rowids     => l_rowids_hist,
                                              o_error      => o_error);
            END IF;
        
            -- Store the association between triage and necessities, if the necessity is set as ACTIVE.
            IF i_id_epis_triage IS NOT NULL
               AND (l_next IS NOT NULL OR l_id_pat_necessity IS NOT NULL)
               AND i_tbl_flg_status(i) = g_pat_necess_active_config
            THEN
                g_error := 'SET TRIAGE/NECESSITIES';
                pk_alertlog.log_debug(g_error);
                ts_epis_triage_pat_necessity.ins(id_epis_triage_in   => i_id_epis_triage,
                                                 id_pat_necessity_in => nvl(l_next, l_id_pat_necessity),
                                                 rows_out            => l_rows_etr_pn);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_TRIAGE_PAT_NECESSITY',
                                              i_rowids     => l_rows_etr_pn,
                                              o_error      => o_error);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_pat_necessity_internal;

    /****************************************************************************** 
    * Register the patient's necessities. Function used in Flash
    *   
    * @param i_lang               Language ID 
    * @param i_prof               Professional info 
    * @param i_id_patient         Patient ID 
    * @param i_id_episode         Episode ID
    * @param i_tbl_id_necessity   Array with necessities ID 
    * @param i_tbl_flg_status     Array with the necessities status 
    * @param i_sysdate            Register date
    * @param i_id_epis_triage     Triage event ID
    * @param i_id_institution     Institution where the necessity is registered ID
    * @param o_error              Error message 
    *
    * @return                TRUE / FALSE
    *                        
    * @author                Sergio Dias
    * @version               2.6.3.8.1
    * @since                 16-9-2013
    *********************************************************************************/
    FUNCTION set_pat_necess
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_tbl_id_necessity IN table_number,
        i_tbl_flg_status   IN table_varchar,
        i_prof             IN profissional,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(200) := 'SET_PAT_NECESS';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO SET_PAT_NECESS_INTERNAL';
        pk_alertlog.log_debug(g_error);
        IF NOT set_pat_necessity_internal(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_patient       => i_id_patient,
                                          i_id_episode       => i_id_episode,
                                          i_tbl_id_necessity => i_tbl_id_necessity,
                                          i_tbl_flg_status   => i_tbl_flg_status,
                                          o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_necess;

    /****************************************************************************** 
    * Register the patient's necessities. Function used in DB
    *   
    * @param i_lang               Language ID 
    * @param i_prof               Professional info 
    * @param i_id_patient         Patient ID 
    * @param i_id_episode         Episode ID
    * @param i_tbl_id_necessity   Array with necessities ID 
    * @param i_tbl_flg_status     Array with the necessities status 
    * @param i_sysdate            Register date
    * @param i_id_epis_triage     Triage event ID
    * @param i_id_institution     Institution where the necessity is registered ID
    * @param o_error              Error message 
    *
    * @return                TRUE / FALSE
    *                        
    * @author                Sergio Dias
    * @version               2.6.3.8.1
    * @since                 16-9-2013
    *********************************************************************************/
    FUNCTION set_pat_necess
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_tbl_id_necessity IN table_number,
        i_tbl_flg_status   IN table_varchar,
        i_prof_cat_type    IN category.flg_type%TYPE DEFAULT NULL,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_triage   IN epis_triage.id_epis_triage%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(200) := 'SET_PAT_NECESS';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO SET_PAT_NECESS_INTERNAL';
        pk_alertlog.log_debug(g_error);
        IF NOT set_pat_necessity_internal(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_patient       => i_id_patient,
                                          i_id_episode       => i_id_episode,
                                          i_tbl_id_necessity => i_tbl_id_necessity,
                                          i_tbl_flg_status   => i_tbl_flg_status,
                                          i_sysdate          => i_sysdate,
                                          i_id_epis_triage   => i_id_epis_triage,
                                          i_id_institution   => i_id_institution,
                                          o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_necess;

    /******************************************************************************
    * OBJECTIVO:   Obter necessidades permanentes do doente  
    * (apenas é usado no InterAlert, vai devolver todas as necessidades do paciente independentemente da visita)
    * PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
    *                       I_ID_PAT - Id do doente 
    *                       I_STATUS - estado do registo (activo / inactivo). Se ñ está preenchido, retorna todos os registos 
    *              Saida:   O_NECESS - necessidade
    *                       O_ERROR - erro 
    * 
    * CRIAÇÃO: CRS 2005/03/15 
    * NOTAS:
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    *********************************************************************************/
    FUNCTION get_pat_necess
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_status IN pat_necessity.flg_status%TYPE,
        o_necess OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_necess FOR
            SELECT p.id_pat_necessity, pk_translation.get_translation(i_lang, n.code_necessity) necess, n.flg_comb
              FROM pat_necessity p, necessity n
             WHERE p.id_patient = i_id_pat
               AND p.flg_status = g_pat_necess_active_config
               AND n.id_necessity = p.id_necessity
               AND p.flg_status = nvl(i_status, p.flg_status);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_NECESS',
                                              o_error);
            pk_types.open_my_cursor(o_necess);
            RETURN FALSE;
    END;

    /******************************************************************************
    *   OBJECTIVE:   Get patient's necessities (in this visit)
    *   PARAMETERS:  Input:  I_LANG - Language
    *                        I_PROF - Professional information
    *                        I_ID_PATIENT - Patient ID
    *                        I_ID_EPISODE - Episode ID 
    *                Output: O_NECESS - Necessities cursor
    *                        O_ERROR - Error
    * 
    *  CREATED: CRS 2005/03/15 
    *
    * UPDATED:
    * @author  Sergio Dias
    * @date    Oct-28-2013
    * @version 2.6.3.8.3
    *********************************************************************************/
    FUNCTION get_all_pat_necess
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_necess     OUT cursor_necess,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode       episode.id_episode%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_count            NUMBER;
        l_has_saved_values VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        -- check if this patient has saved necessities in this visit
        g_error := 'SELECT COUNT(PN.ID_NECESSITY)';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(pn.id_necessity)
          INTO l_count
          FROM pat_necessity pn
         WHERE pn.id_patient = i_id_patient
           AND pn.id_institution = i_prof.institution
           AND pn.flg_status <> g_pat_necess_inactive
           AND pk_episode.get_id_visit(i_episode => pn.id_episode) = pk_episode.get_id_visit(i_episode => i_id_episode);
    
        IF l_count > 0
        THEN
            l_has_saved_values := pk_alert_constant.g_yes;
        ELSE
            l_has_saved_values := pk_alert_constant.g_no;
        END IF;
    
        g_error := 'GET O_NECESS';
        pk_alertlog.log_debug(g_error);
        OPEN o_necess FOR
            SELECT *
              FROM (SELECT pk_translation.get_translation(i_lang, n.code_necessity) necess,
                           n.id_necessity,
                           n.rank,
                           decode(pn.id_pat_necessity,
                                  NULL,
                                  decode(l_has_saved_values,
                                         pk_alert_constant.g_no,
                                         decode(ndis.flg_selected,
                                                pk_alert_constant.g_yes,
                                                g_pat_necess_active_config,
                                                g_pat_necess_inactive),
                                         g_pat_necess_inactive),
                                  decode(pn.flg_status, g_pat_necess_active_config, g_pat_necess_active, pn.flg_status)) flg_status,
                           n.flg_comb
                      FROM necessity_dept_inst_soft ndis
                      JOIN necessity n
                        ON ndis.id_necessity = n.id_necessity
                      LEFT JOIN pat_necessity pn -- joined with transactional table to only load default values for flg_status if there are no saved records
                        ON pn.id_patient = i_id_patient
                       AND pn.id_necessity = n.id_necessity
                       AND pn.id_institution = i_prof.institution
                       AND pn.flg_status <> g_pat_necess_inactive
                       AND pk_episode.get_id_visit(i_episode => pn.id_episode) =
                           pk_episode.get_id_visit(i_episode => i_id_episode)
                     WHERE n.flg_available = g_necess_avail
                       AND ndis.flg_area = pk_alert_constant.g_nece_dept_inst_soft_config
                       AND ndis.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND ndis.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                       AND rownum > 0)
             WHERE necess IS NOT NULL
             ORDER BY rank, necess;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_PAT_NECESS',
                                              o_error);
            open_my_cursor(o_necess);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_hplan_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number,
        i_num_hplan     IN table_varchar,
        i_dt_hplan      IN table_date,
        i_default       IN table_varchar,
        i_default_epis  IN table_varchar,
        i_barcode       IN table_varchar,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_hplan    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar planos de saúde 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT - Id do doente 
                                 I_ID_EPIS - Id do episódio
             I_ID_HPLAN - plano de saúde 
             I_NUM_HPLAN - nº 
             I_DT_HPLAN - data de validade do plano 
             I_DEFAULT - flag que indica se o plano é o que está em uso  
             I_DEFAULT_EPIS - flag que indica se o plano é o que está em uso neste episódio
             I_BARCODE - cód barras 
             I_PROF - profissional q regista 
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                    como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida: O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          ALTERAÇÕES: SS 2006/04/08: plano de saúde em uso e plano de saúde em uso neste episódio 
          NOTAS: 
          ALTERAÇÕES: LG 2006-NOV-01: função executa a lógica, mas não faz o commit.
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next_php     pat_health_plan.id_pat_health_plan%TYPE;
        l_next_ehp     epis_health_plan.id_epis_health_plan%TYPE;
        l_id_pat_hplan pat_health_plan.id_pat_health_plan%TYPE;
        --l_error         VARCHAR2(2000);
        l_count PLS_INTEGER;
    
        CURSOR c_hplan_default IS
            SELECT ROWID
              FROM pat_health_plan
             WHERE id_patient = i_id_pat
               AND flg_default = g_pat_hplan_default
               AND (id_institution IN
                   (SELECT *
                       FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt))) OR
                   id_institution IS NULL);
    
        CURSOR c_hplan(l_id_hplan pat_health_plan.id_health_plan%TYPE) IS --já existe este plano para o paciente
            SELECT id_pat_health_plan
              FROM pat_health_plan
             WHERE id_patient = i_id_pat
               AND id_health_plan = l_id_hplan
               AND nvl(id_institution, -1) = nvl(i_prof.institution, -1);
    
        l_no_num         EXCEPTION;
        l_already_exists EXCEPTION;
    
        l_check_hplan_dup sys_config.value%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        -- ACM, 2010-06-01: ALERT-101823
        g_error           := 'CHECK_HPLAN_DUPLICATED';
        l_check_hplan_dup := pk_sysconfig.get_config('CHECK_HPLAN_DUPLICATED', i_prof);
    
        --LG 2006/11/03 
        IF (i_id_epis IS NOT NULL)
        THEN
            -- CRS 2006/05/03                
            DELETE epis_health_plan
             WHERE id_pat_health_plan IN (SELECT id_pat_health_plan
                                            FROM pat_health_plan
                                           WHERE id_patient = i_id_pat
                                             AND id_institution = i_prof.institution);
            -- CRS 2006/05/03            
        
        END IF;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_hplan.count
        LOOP
        
            IF i_num_hplan(i) IS NULL
            THEN
                RAISE l_no_num;
            
            END IF;
        
            g_error := 'l_check_hplan_dup=' || l_check_hplan_dup;
            IF l_check_hplan_dup = pk_alert_constant.g_yes
            THEN
            
                SELECT COUNT(0)
                  INTO l_count
                  FROM pat_health_plan p
                 WHERE p.num_health_plan = i_num_hplan(i)
                   AND p.id_health_plan = i_id_hplan(i)
                   AND p.id_patient != i_id_pat
                   AND NOT EXISTS (SELECT 0
                          FROM pat_health_plan p
                         WHERE p.num_health_plan = i_num_hplan(i)
                           AND p.id_health_plan = i_id_hplan(i)
                           AND p.id_patient = i_id_pat);
            
                IF l_count > 0
                THEN
                    RAISE l_already_exists;
                END IF;
            END IF;
        
            l_id_pat_hplan := NULL;
        
            IF i_default(i) = 'Y'
            THEN
                -- JS, 2008-07-15: Actualiza todos com flg_default = 'N'
                g_error := 'LOOP C_HPLAN_DEFAULT';
                FOR w IN c_hplan_default
                LOOP
                    UPDATE pat_health_plan
                       SET flg_default = 'N'
                     WHERE ROWID = w.rowid;
                END LOOP;
            END IF; --I_DEFAULT(I)
        
            SELECT seq_pat_health_plan.nextval
              INTO l_next_php
              FROM dual;
        
            g_error := 'MERGE INTO PAT_HEALTH_PLAN ' || l_next_php;
            MERGE INTO pat_health_plan p
            USING (SELECT i_id_pat id_patient, i_id_hplan(i) id_health_plan, column_value id_institution
                     FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt))
                   UNION ALL
                   SELECT i_id_pat id_patient, i_id_hplan(i) id_health_plan, NULL id_institution
                     FROM dual) a
            ON (p.id_patient = a.id_patient --
            AND p.id_health_plan = a.id_health_plan -- 
            AND (nvl(p.id_institution, -1) = nvl(a.id_institution, -1)))
            WHEN MATCHED THEN
                UPDATE
                   SET flg_default      = i_default(i),
                       barcode          = i_barcode(i),
                       num_health_plan  = i_num_hplan(i),
                       dt_health_plan   = i_dt_hplan(i),
                       desc_health_plan = i_desc_hplan(i)
                --                 returning p.id_pat_health_plan into l_id_pat_hplan               
                
            
            WHEN NOT MATCHED THEN
                INSERT
                    (id_pat_health_plan,
                     id_patient,
                     id_health_plan,
                     flg_status,
                     num_health_plan,
                     dt_health_plan,
                     flg_default,
                     barcode,
                     id_institution,
                     desc_health_plan)
                VALUES
                    (decode(a.id_institution, i_prof.institution, l_next_php, seq_pat_health_plan.nextval),
                     a.id_patient,
                     a.id_health_plan,
                     'A',
                     i_num_hplan(i),
                     i_dt_hplan(i),
                     i_default(i),
                     i_barcode(i),
                     a.id_institution,
                     i_desc_hplan(i));
        
            --This cursor was added because the new merge statement was not working
            --when achanging episode default HPLAN
            g_error := 'GET CURSOR C_HPLAN - ' || i_id_hplan(i);
            OPEN c_hplan(i_id_hplan(i));
            FETCH c_hplan
                INTO l_id_pat_hplan;
            g_found := c_hplan%FOUND;
            CLOSE c_hplan;
        
            g_error := 'I_DEFAULT_EPIS';
            IF i_default_epis(i) = 'Y'
            THEN
                --se o plano já existe e queremos alterar para "em uso neste episódio"
                g_error := 'DELETE EPIS_HEALTH_PLAN';
                DELETE epis_health_plan
                 WHERE id_pat_health_plan IN (SELECT id_pat_health_plan
                                                FROM pat_health_plan
                                               WHERE id_patient = i_id_pat
                                                 AND id_institution = i_prof.institution);
            
                g_error := 'GET SEQ_EPIS_HEALTH_PLAN.NEXTVAL';
                SELECT seq_epis_health_plan.nextval
                  INTO l_next_ehp
                  FROM dual;
            
                g_error := 'INSERT EPIS_HEALTH_PLAN -> ' || i_id_hplan(i) || ' -> ' || l_next_ehp || ' -> ' ||
                           i_id_epis || ' -> ' || nvl(l_id_pat_hplan, l_next_php);
                INSERT INTO epis_health_plan
                    (id_epis_health_plan, id_episode, id_pat_health_plan)
                VALUES
                    (l_next_ehp, i_id_epis, nvl(l_id_pat_hplan, l_next_php));
            END IF;
        
        END LOOP;
    
        -- José Brito 17/11/2008 A chamada à SET_FIRST_OBS deve ser retirada por dois motivos:
        -- 1) A função SET_PAT_HPLAN_INTERNAL é usada por funções das Interfaces;
        -- 2) As funções externas que usam esta função, também invocam a PK_VISIT.SET_FIRST_OBS;
    
        --g_error := 'CALL TO SET_FIRST_OBS';
        --IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
        --                              i_id_episode          => NULL,
        --                              i_pat                 => i_id_pat,
        --                              i_prof                => i_prof,
        --                              i_prof_cat_type       => i_prof_cat_type,
        --                              i_dt_last_interaction => g_sysdate_tstz,
        --                              i_dt_first_obs        => g_sysdate_tstz,
        --                              o_error               => l_error)
        --THEN
        --    o_error := l_error;
        --    RETURN FALSE;
        --END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_num THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'HEALTH_PLAN_M001',
                                              pk_message.get_message(i_lang, 'HEALTH_PLAN_M001'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPLAN_INTERNAL',
                                              o_error);
        
            RETURN FALSE;
        
        WHEN l_already_exists THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'HEALTH_PLAN_M004',
                                              pk_message.get_message(i_lang, 'HEALTH_PLAN_M004'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPLAN_INTERNAL',
                                              'U',
                                              '',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPLAN_INTERNAL',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION set_pat_hplan_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number, --HEALTH_PLAN.ID_HEALTH_PLAN%TYPE,
        i_num_hplan     IN table_varchar, --PAT_HEALTH_PLAN.NUM_HEALTH_PLAN%TYPE,
        i_dt_hplan      IN table_varchar, --PAT_HEALTH_PLAN.DT_HEALTH_PLAN%TYPE,
        i_default       IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_default_epis  IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_barcode       IN table_varchar, --PAT_HEALTH_PLAN.BARCODE%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_hplan    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_hplan_date table_date := table_date();
    
    BEGIN
        FOR i IN 1 .. i_dt_hplan.count
        LOOP
            l_dt_hplan_date.extend;
            l_dt_hplan_date(i) := trunc(CAST(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_hplan(i), NULL) AS DATE));
        END LOOP;
        RETURN set_pat_hplan_internal(i_lang          => i_lang,
                                      i_id_pat        => i_id_pat,
                                      i_id_epis       => i_id_epis,
                                      i_id_hplan      => i_id_hplan,
                                      i_num_hplan     => i_num_hplan,
                                      i_dt_hplan      => l_dt_hplan_date,
                                      i_default       => i_default,
                                      i_default_epis  => i_default_epis,
                                      i_barcode       => i_barcode,
                                      i_prof          => i_prof,
                                      i_prof_cat_type => i_prof_cat_type,
                                      i_desc_hplan    => i_desc_hplan,
                                      o_error         => o_error);
    
    END;

    FUNCTION set_pat_hplan_interface
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number, --HEALTH_PLAN.ID_HEALTH_PLAN%TYPE,
        i_num_hplan     IN table_varchar, --PAT_HEALTH_PLAN.NUM_HEALTH_PLAN%TYPE,
        i_dt_hplan      IN table_date, --PAT_HEALTH_PLAN.DT_HEALTH_PLAN%TYPE,
        i_default       IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_default_epis  IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_barcode       IN table_varchar, --PAT_HEALTH_PLAN.BARCODE%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar planos de saúde 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT - Id do doente 
                                 I_ID_EPIS - Id do episódio
             I_ID_HPLAN - plano de saúde 
             I_NUM_HPLAN - nº 
             I_DT_HPLAN - data de validade do plano 
             I_DEFAULT - flag que indica se o plano é o que está em uso  
             I_DEFAULT_EPIS - flag que indica se o plano é o que está em uso neste episódio
             I_BARCODE - cód barras 
             I_PROF - profissional q regista 
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                    como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida: O_ERROR - erro 
         
          CRIAÇÃO: RSS 2007/06/20
          NOTAS: A data de validade do plano de saude passou a ser um table_date
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        IF (NOT set_pat_hplan_internal(i_lang,
                                       i_id_pat,
                                       i_id_epis,
                                       i_id_hplan,
                                       i_num_hplan,
                                       i_dt_hplan,
                                       i_default,
                                       i_default_epis,
                                       i_barcode,
                                       i_prof,
                                       i_prof_cat_type,
                                       NULL,
                                       o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPLAN_INTERFACE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number, --HEALTH_PLAN.ID_HEALTH_PLAN%TYPE,
        i_num_hplan     IN table_varchar, --PAT_HEALTH_PLAN.NUM_HEALTH_PLAN%TYPE,
        i_dt_hplan      IN table_varchar, --PAT_HEALTH_PLAN.DT_HEALTH_PLAN%TYPE,
        i_default       IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_default_epis  IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_barcode       IN table_varchar, --PAT_HEALTH_PLAN.BARCODE%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_hplan    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar planos de saúde 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT - Id do doente 
                                 I_ID_EPIS - Id do episódio
             I_ID_HPLAN - plano de saúde 
             I_NUM_HPLAN - nº 
             I_DT_HPLAN - data de validade do plano 
             I_DEFAULT - flag que indica se o plano é o que está em uso  
             I_DEFAULT_EPIS - flag que indica se o plano é o que está em uso neste episódio
             I_BARCODE - cód barras 
             I_PROF - profissional q regista 
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                    como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida: O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          ALTERAÇÕES: SS 2006/04/08: plano de saúde em uso e plano de saúde em uso neste episódio 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        IF (NOT set_pat_hplan_internal(i_lang,
                                       i_id_pat,
                                       i_id_epis,
                                       i_id_hplan,
                                       i_num_hplan,
                                       i_dt_hplan,
                                       i_default,
                                       i_default_epis,
                                       i_barcode,
                                       i_prof,
                                       i_prof_cat_type,
                                       i_desc_hplan,
                                       o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HPLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_hplan         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter planos de saúde 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_ID_PAT - Id do doente 
             I_ID_EPIS - ID do episódio. 
             I_PROF - profissional 
             I_PROF_CAT_TYPE - categoria do profissional (FLG_TYPE) 
               Saida: O_HPLAN - planos de saúde 
             O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          ALTERAÇÃO: SS 2006/04/08: plano de saúde em uso e plano de saúde em uso neste episódio 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_soft software.id_software%TYPE;
    
        l_hp_other     health_plan.id_health_plan%TYPE;
        l_hp_other_cnt health_plan.id_content%TYPE;
    
    BEGIN
    
        l_hp_other_cnt := pk_sysconfig.get_config('HEALTH_PLAN_OTHER', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_hp_other
              FROM health_plan hp
             WHERE hp.id_content = l_hp_other_cnt
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_hp_other := NULL;
        END;
    
        l_soft := to_number(pk_sysconfig.get_config('SOFTWARE_ID_P1', i_prof));
        -- Se é software P1
        -- js, 2008-05-31: Retornar desc_health_plan se plano de saude "Outro"
        IF i_prof.software = l_soft
        THEN
            OPEN o_hplan FOR
                SELECT p.id_pat_health_plan,
                       p.num_health_plan,
                       p.flg_default,
                       'N' flg_default_epis,
                       pk_date_utils.dt_chr(i_lang, p.dt_health_plan, i_prof) dt_hplan,
                       decode(p.desc_health_plan,
                              NULL,
                              pk_translation.get_translation(i_lang, h.code_health_plan),
                              decode(l_hp_other,
                                     h.id_health_plan,
                                     p.desc_health_plan,
                                     pk_translation.get_translation(i_lang, h.code_health_plan))) hplan,
                       h.id_health_plan,
                       h.id_content,
                       to_char(p.dt_health_plan, 'YYYYMMDDHH24MISS') date_hplan,
                       1 rank,
                       decode(h.id_health_plan, l_hp_other, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_other,
                       pk_alert_constant.g_yes can_edit
                  FROM pat_health_plan p
                  JOIN health_plan h
                    ON (p.id_health_plan = h.id_health_plan)
                 WHERE p.id_patient = i_id_pat
                   AND p.id_institution IS NULL
                   AND h.flg_available = g_hplan_avail
                 ORDER BY rank, hplan;
        ELSE
            OPEN o_hplan FOR
                SELECT p.id_pat_health_plan,
                       p.num_health_plan,
                       p.flg_default,
                       decode(ehp.id_episode, i_id_epis, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default_epis,
                       pk_date_utils.dt_chr(i_lang, p.dt_health_plan, i_prof) dt_hplan,
                       decode(p.desc_health_plan,
                              NULL,
                              pk_translation.get_translation(i_lang, h.code_health_plan),
                              decode(l_hp_other,
                                     h.id_health_plan,
                                     p.desc_health_plan,
                                     pk_translation.get_translation(i_lang, h.code_health_plan))) hplan,
                       h.id_health_plan,
                       h.id_content,
                       to_char(p.dt_health_plan, 'YYYYMMDDHH24MISS') date_hplan,
                       decode(ehp.id_episode, NULL, 2, 1) rank,
                       decode(h.id_health_plan, l_hp_other, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_other
                  FROM pat_health_plan p
                  JOIN health_plan h
                    ON (p.id_health_plan = h.id_health_plan)
                  LEFT JOIN epis_health_plan ehp
                    ON (p.id_pat_health_plan = ehp.id_pat_health_plan AND ehp.id_episode = i_id_epis)
                 WHERE p.id_patient = i_id_pat
                   AND ((p.id_institution = i_prof.institution) OR
                       (p.id_institution != i_prof.institution AND
                       p.id_institution IN
                       (SELECT *
                            FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                     pk_ehr_access.g_inst_grp_flg_rel_adt))) AND
                       p.id_health_plan NOT IN
                       (SELECT p2.id_health_plan
                            FROM pat_health_plan p2
                            JOIN health_plan h2
                              ON (p2.id_health_plan = h2.id_health_plan)
                            LEFT JOIN epis_health_plan ehp2
                              ON (p2.id_pat_health_plan = ehp2.id_pat_health_plan AND ehp2.id_episode = i_id_epis)
                           WHERE p2.id_patient = i_id_pat
                             AND p2.id_institution = i_prof.institution
                             AND h2.flg_available = g_hplan_avail)))
                   AND h.flg_available = g_hplan_avail
                 ORDER BY rank, hplan;
        
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
                                              'GET_PAT_HPLAN',
                                              o_error);
            pk_types.open_my_cursor(o_hplan);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Cancel Health Plan
    * Used for SQL.
    *
    * @param i_lang                   language id
    * @param i_pat_hplan              health_plan id (pat_health_plan)
    * @param i_prof                   professional, software and institution ids           
    * @param i_prof_cat_type          not used          
    * @param i_test                   Y returns confirmation message, cancels otherwise    
    * @param   o_flg_show  Y show message, N otherwise
    * @param   o_msg  the message text 
    * @param   o_msg_title  message title 
    * @param   o_button the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed   
    * @param   o_error error message    
    *
    * @return  TRUE if sucess, FALSE otherwise 
    *                        
    * @author                         Joao Sa
    * @version                        2.0 
    * @since                          2008/07/11
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION cancel_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_pat_hplan     IN pat_health_plan.id_pat_health_plan%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_hplan_desc IS
            SELECT pk_translation.get_translation(i_lang, hp.code_health_plan)
              FROM pat_health_plan php, health_plan hp
             WHERE php.id_pat_health_plan = i_pat_hplan
               AND hp.id_health_plan = php.id_health_plan;
    
        CURSOR c_hplan IS
            SELECT id_pat_health_plan
              FROM pat_health_plan
             WHERE (id_patient, id_health_plan) IN
                   (SELECT id_patient, id_health_plan
                      FROM pat_health_plan
                     WHERE id_pat_health_plan = i_pat_hplan)
               AND (id_institution IN
                   (SELECT *
                       FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, pk_ehr_access.g_inst_grp_flg_rel_adt))) OR
                   id_institution IS NULL);
    
        l_hplan VARCHAR2(2000);
    
    BEGIN
    
        IF i_test = 'Y'
        THEN
            OPEN c_hplan_desc;
            FETCH c_hplan_desc
                INTO l_hplan;
            CLOSE c_hplan_desc;
        
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'HEALTH_PLAN_M002');
            o_msg       := REPLACE(pk_message.get_message(i_lang, 'HEALTH_PLAN_M003'), '@1', l_hplan);
            o_button    := 'NC';
        
            RETURN TRUE;
        END IF;
    
        FOR w IN c_hplan
        LOOP
        
            --ADT-3369
            --ADTs Admission pat health plan info
            --needs to be cleared as it is in PFH
            UPDATE admission_adt
               SET id_pat_health_plan = NULL
             WHERE id_pat_health_plan = w.id_pat_health_plan;
        
            g_error := 'DELETE EPIS_HEALTH_PLAN';
            DELETE epis_health_plan
             WHERE id_pat_health_plan = w.id_pat_health_plan;
        
            g_error := 'DELETE PAT_HEALTH_PLAN';
            DELETE pat_health_plan
             WHERE id_pat_health_plan = w.id_pat_health_plan;
        
        END LOOP;
    
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
                                              'CANCEL_PAT_HPLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_doc
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_doc        IN table_number, --DOC_TYPE.ID_DOC_TYPE%TYPE,
        i_number        IN table_varchar, --PAT_DOC.VALUE%TYPE,
        i_dt_emi        IN table_varchar, --PAT_DOC.DT_EMITED%TYPE,
        i_dt_exp        IN table_varchar, --PAT_DOC.DT_EXPIRE%TYPE,
        i_prof          IN profissional,
        i_status        IN table_varchar, --PAT_DOC.FLG_STATUS%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar documentos de identificação 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_ID_PAT_DOC - ID do registo. Se vier preenchido, é pq 
                      se trata de um Update ao registo. Senão, 
                  é um Insert.  NÃO ESTÁ A SER USADO!! 
               I_ID_DOC - tipo de doc. de id.
               I_NUMBER - nº do doc 
               I_DT_EMI - data de emissão 
               I_DT_EXP - data de validade 
               I_PROF - profissional q regista 
               I_STATUS - estado: Activo / Inactivo   NÃO ESTÁ A SER USADO!! 
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                      como é retornada em PK_LOGIN.GET_PROF_PREF 
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next   pat_doc.id_pat_doc%TYPE;
        l_char   VARCHAR2(1);
        l_id_doc pat_doc.id_doc_type%TYPE;
    
        CURSOR c_doc(l_id_doc pat_doc.id_doc_type%TYPE) IS
            SELECT 'X'
              FROM pat_doc
             WHERE id_patient = i_id_pat
               AND id_doc_type = l_id_doc;
    
        e_no_number EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'BEGIN LOOP';
        FOR i IN 1 .. i_id_doc.count
        LOOP
            -- Loop sobre o array de IDs de registos  
        
            IF i_number(i) IS NULL
               AND (i_dt_emi(i) IS NOT NULL OR i_dt_exp(i) IS NOT NULL)
            THEN
                RAISE e_no_number;
            END IF;
        
            g_error := 'GET CURSOR C_DOC';
            OPEN c_doc(i_id_doc(i));
            FETCH c_doc
                INTO l_char;
            g_found := c_doc%NOTFOUND;
            CLOSE c_doc;
        
            IF g_found
            THEN
                IF i_number(i) IS NOT NULL
                THEN
                    --insere registo se nº do documento not null 
                    g_error := 'GET SEQ_PAT_DOC.NEXTVAL';
                    SELECT seq_pat_doc.nextval
                      INTO l_next
                      FROM dual;
                
                    g_error := 'INSERT INTO PAT_DOC';
                    INSERT INTO pat_doc
                        (id_pat_doc, id_patient, id_doc_type, VALUE, dt_expire, dt_emited, flg_status, id_institution)
                    VALUES
                        (l_next,
                         i_id_pat,
                         i_id_doc(i),
                         i_number(i),
                         to_date(i_dt_exp(i), 'DD-MM-YYYY'),
                         to_date(i_dt_emi(i), 'DD-MM-YYYY'),
                         g_pat_doc_active,
                         i_prof.institution);
                
                    g_error := 'CALL TO SET_FIRST_OBS';
                    IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                                  i_id_episode          => NULL,
                                                  i_pat                 => i_id_pat,
                                                  i_prof                => i_prof,
                                                  i_prof_cat_type       => i_prof_cat_type,
                                                  i_dt_last_interaction => g_sysdate_tstz,
                                                  i_dt_first_obs        => g_sysdate_tstz,
                                                  o_error               => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                END IF;
            
            ELSE
                -- Já existe registo deste doc. para este doente 
                IF i_number(i) IS NULL
                THEN
                    g_error := 'DELETE';
                    DELETE pat_doc
                     WHERE id_patient = i_id_pat
                       AND id_doc_type = i_id_doc(i);
                
                ELSE
                    g_error := 'UPDATE';
                    UPDATE pat_doc
                       SET VALUE     = i_number(i),
                           dt_expire = to_date(i_dt_exp(i), 'DD-MM-YYYY'),
                           dt_emited = to_date(i_dt_emi(i), 'DD-MM-YYYY')
                     WHERE id_patient = i_id_pat
                       AND id_doc_type = i_id_doc(i);
                END IF;
            END IF;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_no_number THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'DOCUMENT_M001',
                                              pk_message.get_message(i_lang, 'DOCUMENT_M001'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DOC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DOC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_pat_doc
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_doc    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter documentos de identificação 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               Saida:   O_DOC - documentos 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        OPEN o_doc FOR
            SELECT p.id_pat_doc,
                   p.value,
                   d.rank,
                   pk_date_utils.dt_chr(i_lang, p.dt_emited, i_prof) dt_emited,
                   pk_date_utils.dt_chr(i_lang, p.dt_expire, i_prof) dt_expire,
                   pk_translation.get_translation(i_lang, d.code_doc_type) doc,
                   d.id_doc_type,
                   to_char(p.dt_emited, 'YYYYMMDDHH24MISS') date_emited,
                   to_char(p.dt_expire, 'YYYYMMDDHH24MISS') date_expire
              FROM pat_doc p, doc_type d, doc_types_config dtc
             WHERE p.id_patient = i_id_pat
               AND p.id_doc_type = d.id_doc_type
               AND d.flg_available = g_doc_avail
                  --This was referencing directly a column that was discontinued
                  --The column was changed but hardcoded variables remained the same
               AND dtc.id_doc_type = d.id_doc_type
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_doc_ori_type_parent = 1
            UNION ALL
            SELECT 0 id_pat_doc,
                   NULL VALUE,
                   d.rank,
                   NULL dt_emited,
                   NULL dt_expire,
                   pk_translation.get_translation(i_lang, d.code_doc_type) doc,
                   d.id_doc_type,
                   NULL date_emited,
                   NULL date_expire
              FROM doc_type d, doc_types_config dtc
             WHERE d.flg_available = g_doc_avail
                  --This was referencing directly a column that was discontinued
                  --The column was changed but hardcoded variables remained the same
               AND dtc.id_doc_type = d.id_doc_type
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_doc_ori_type_parent = 1
               AND d.id_doc_type NOT IN (SELECT d1.id_doc_type
                                           FROM doc_type d1, pat_doc p1
                                          WHERE p1.id_patient = i_id_pat
                                            AND p1.id_doc_type = d1.id_doc_type
                                            AND d1.flg_available = g_doc_avail)
             ORDER BY rank, doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_DOC',
                                              o_error);
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END;

    FUNCTION set_pat_job_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_occup             IN pat_job.id_occupation%TYPE,
        i_prof              IN profissional,
        i_location          IN pat_job.location%TYPE,
        i_year_begin        IN pat_job.year_begin%TYPE,
        i_year_end          IN pat_job.year_end%TYPE,
        i_activity_type     IN pat_job.activity_type%TYPE,
        i_prof_disease_risk IN pat_job.prof_disease_risk%TYPE,
        i_notes             IN pat_job.notes%TYPE,
        i_num_workers       IN pat_job.num_workers%TYPE,
        i_company           IN pat_job.company%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_occupation_desc   IN pat_job.occupation_desc%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        *       Registar profissão do doente, não faz commit na base de dados 
        * @param         I_LANG - Língua registada como preferência do profissional 
        * @param         I_ID_PAT - Id do doente 
        * @param         I_OCCUP - profissão * @param         
        * @param         I_PROF - profissional autor do registo 
        * @param         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                              como é retornada em PK_LOGIN.GET_PROF_PREF
        * @param         I_OCCUPATION_DESC - Descrição manual da profissão.
        * @param         I_EPIS Episode ÎD
        * @param         O_ERROR - erro 
        *         
        * @author         CRS 
        * @since          2005/03/15 
        *
        * @author         LG 
        * @since          2006-fev-02 
        *                 HANDWRITTEN OCCUPATION
        * @author         Pedro Santos
        * @version        2.4.3-Denormalized
        * @since          2008/10/02 
        * reason Episode Id added to table pat_job
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next   pat_job.id_pat_job%TYPE;
        l_char   VARCHAR2(1);
        l_rowids table_varchar;
        CURSOR c_job IS
            SELECT 'X'
              FROM pat_job
             WHERE id_patient = i_id_pat
               AND id_occupation = i_occup;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR C_JOB';
        OPEN c_job;
        FETCH c_job
            INTO l_char;
        g_found := c_job%NOTFOUND;
        CLOSE c_job;
    
        IF g_found
        THEN
            g_error := 'GET SET_PAT_JOB_INTERNAL.NEXTVAL';
            l_next  := ts_pat_job.next_key();
        
            g_error := 'INSERT INTO PAT_JOB';
            ts_pat_job.ins(id_pat_job_in        => l_next,
                           id_patient_in        => i_id_pat,
                           id_occupation_in     => i_occup,
                           dt_pat_job_tstz_in   => g_sysdate_tstz,
                           location_in          => i_location,
                           year_begin_in        => i_year_begin,
                           year_end_in          => i_year_end,
                           activity_type_in     => i_activity_type,
                           prof_disease_risk_in => i_prof_disease_risk,
                           notes_in             => i_notes,
                           num_workers_in       => i_num_workers,
                           company_in           => i_company,
                           flg_status_in        => g_pat_job_active,
                           id_institution_in    => i_prof.institution,
                           occupation_desc_in   => i_occupation_desc,
                           id_episode_in        => nvl(i_epis, -1),
                           rows_out             => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-PAT_JOB';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_JOB',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => NULL,
                                          i_pat                 => i_id_pat,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        ELSE
            g_error := 'UPDATE';
            UPDATE pat_job
               SET location          = i_location,
                   year_begin        = nvl(i_year_begin, year_begin),
                   year_end          = nvl(i_year_end, year_end),
                   activity_type     = nvl(i_activity_type, activity_type),
                   prof_disease_risk = nvl(i_prof_disease_risk, prof_disease_risk),
                   notes             = nvl(i_notes, notes),
                   num_workers       = i_num_workers,
                   company           = i_company,
                   dt_pat_job_tstz   = g_sysdate_tstz,
                   flg_status        = g_pat_job_active,
                   occupation_desc   = i_occupation_desc
             WHERE id_patient = i_id_pat
               AND id_occupation = i_occup;
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
                                              'SET_PAT_JOB_INTERNAL',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_job
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_occup             IN pat_job.id_occupation%TYPE,
        i_prof              IN profissional,
        i_location          IN pat_job.location%TYPE,
        i_year_begin        IN pat_job.year_begin%TYPE,
        i_year_end          IN pat_job.year_end%TYPE,
        i_activity_type     IN pat_job.activity_type%TYPE,
        i_prof_disease_risk IN pat_job.prof_disease_risk%TYPE,
        i_notes             IN pat_job.notes%TYPE,
        i_num_workers       IN pat_job.num_workers%TYPE,
        i_company           IN pat_job.company%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        * Registar profissão do doente 
        * @param   I_LANG - Língua registada como preferência do profissional 
        * @param   I_ID_PAT - Id do doente 
        * @param   I_OCCUP - profissão 
        * @param   I_PROF - profissional autor do registo 
        * @param   I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                              como é retornada em PK_LOGIN.GET_PROF_PREF 
        * @param   I_EPIS 
        * @param   O_ERROR - erro 
        *         
        * @author   CRS 
        * @since   2005/03/15 
        *
        * @author Pedro Santos
        * @since 2008/10/02
        * @version 2.4.3-Denormalized
        *reason added i_epis
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
    
        IF NOT pk_patient.set_pat_job_internal(i_lang,
                                               i_id_pat,
                                               i_occup,
                                               i_prof,
                                               i_location,
                                               i_year_begin,
                                               i_year_end,
                                               i_activity_type,
                                               i_prof_disease_risk,
                                               i_notes,
                                               i_num_workers,
                                               i_company,
                                               i_prof_cat_type,
                                               NULL,
                                               i_epis,
                                               o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_JOB',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_last_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        o_occup  OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter a ocupação actual ou a + recente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               Saida:   O_OCCUP - profissão 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *********************************************************************************/
        CURSOR c_job IS
            SELECT decode(p.occupation_desc,
                          NULL,
                          pk_translation.get_translation(i_lang, o.code_occupation),
                          p.occupation_desc) occup
              FROM pat_job p
              LEFT JOIN occupation o
                ON p.id_occupation = o.id_occupation -- LG 27-jAN-2007 profissão escrita à mão
             WHERE p.id_patient = i_id_pat
               AND p.dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                          FROM pat_job p1
                                         WHERE p1.id_patient = i_id_pat);
    BEGIN
        g_error := 'GET CURSOR C_JOB';
        OPEN c_job;
        FETCH c_job
            INTO o_occup;
        CLOSE c_job;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_PAT_JOB',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_status IN pat_job.flg_status%TYPE,
        i_prof   IN profissional,
        o_occup  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter o histórico de ocupações 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_STATUS - estado do registo (activo / cancelado). 
                    Se ñ está preenchido, retorna todos os registos 
               Saida:   O_OCCUP - profissões 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15
          ALTERAÇÃO: RdSN 2007/02/01 Commented references to PROFESSIONAL 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_occup FOR
            SELECT pk_translation.get_translation(i_lang, o.code_occupation) occup,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_pat_job_tstz, i_prof) dt_pat_job,
                   location,
                   year_begin,
                   year_end,
                   activity_type,
                   prof_disease_risk,
                   notes,
                   num_workers,
                   company,
                   p.id_pat_job
              FROM pat_job p, occupation o
             WHERE p.id_patient = i_id_pat
               AND p.id_occupation(+) = o.id_occupation
               AND p.flg_status = nvl(i_status, p.flg_status);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_JOB',
                                              o_error);
            pk_types.open_my_cursor(o_occup);
            RETURN FALSE;
    END;

    FUNCTION set_clin_rec
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat        IN clin_record.id_patient%TYPE,
        i_instit     IN clin_record.id_institution%TYPE,
        i_num        IN clin_record.num_clin_record%TYPE,
        i_pat_family IN clin_record.id_pat_family%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        *  registar processos clínicos 
        *
        * @param   I_LANG - Língua registada como preferência do profissional
        * @param   I_ID_PAT - Id do doente
        * @param   I_PROF - Profissional, Instit, Sw
        * @param   I EPIS - Id do episódio
        * @param   I_INSTIT - instituição
        * @param   I_NUM - nº proc. clínico 
        * @param   I_PAT_FAMILY - ID do registo familiar (caso dos CS) 
        * @param   O_ERROR - erro
        *  
        * @author  CRS
        * @version
        * @since   2005/03/15
        *               
        * @author    Pedro Santos
        * @version   2.4.3-Denormalized
        * @since     2008/09/30 
        * reason     added column id_episode to table CLIN_RECORD
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5                   
        *********************************************************************************/
        l_next   clin_record.id_clin_record%TYPE;
        l_rowids table_varchar;
    
    BEGIN
        g_error := 'GET SEQ_CLIN_RECORD.NEXTVAL';
        l_next  := ts_clin_record.next_key();
    
        g_error := 'INSERT CLIN_RECORD';
        ts_clin_record.ins(id_clin_record_in  => l_next,
                           num_clin_record_in => i_num,
                           flg_status_in      => g_clin_rec_active,
                           id_patient_in      => i_pat,
                           id_institution_in  => i_instit,
                           id_pat_family_in   => i_pat_family,
                           id_episode_in      => nvl(i_epis, -1),
                           rows_out           => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-CLIN_RECORD';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CLIN_RECORD',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                ROLLBACK;
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'SET_CLIN_RECORD');
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END;

    FUNCTION get_clin_rec
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN clin_record.id_patient%TYPE,
        i_instit     IN clin_record.id_institution%TYPE,
        i_pat_family IN clin_record.id_pat_family%TYPE,
        o_num        OUT clin_record.num_clin_record%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter processos clínicos 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT - Id do doente 
               I_INSTIT - instituição onde foi registado o proc. clínico 
               I_PAT_FAMILY - ID do registo familiar (caso dos CS) 
               Saida:   O_NUM - nº proc. clínico 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/15 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        CURSOR c_clin_rec IS
            SELECT num_clin_record
              FROM clin_record
             WHERE ((id_patient = i_pat AND i_pat IS NOT NULL) OR
                   (id_pat_family = i_pat_family AND i_pat_family IS NOT NULL))
               AND id_institution = i_instit
               AND flg_status = g_clin_rec_active;
    BEGIN
    
        g_error := 'OPEN CURSOR C_CLIN_REC';
        OPEN c_clin_rec;
        FETCH c_clin_rec
            INTO o_num;
        CLOSE c_clin_rec;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CLIN_REC',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION set_pat_cli_att_internal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_pregnancy   IN pat_cli_attributes.flg_pregnancy%TYPE,
        i_flg_breast_feed IN pat_cli_attributes.flg_breast_feed%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_id_recm         IN pat_cli_attributes.id_recm%TYPE,
        i_dt_val_recm     IN pat_cli_attributes.dt_val_recm%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        *   Registar info clínica do doente, sem commit 
        *   @param I_LANG - Língua registada como preferência do profissional 
        *   @param I_ID_PAT - Id do doente
        *   @param I_EPIS - Episode Id 
        *   @param I_FLG_PREGNANCY - indica se a utente está grávida (Y/N) 
        *   @param I_FLG_BREAST_FEED - indica se a utente está a amamentar (Y/N) 
        *   @param I_PROF - profissional q regista 
        *   @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal como é 
                                     retornada em PK_LOGIN.GET_PROF_PREF
        *   @param I_ID_RECM  - regime especial de comparticipação medicamentosa
        *   @param I_DT_VAL_RECM - data de validade do RECM 
        *   @param O_ERROR - erro 
        *
        *   @author CRS          
        *   @date   2005/03/17
        *   @version   
        * 
        *   @author    LG          
        *   @date      2006-09-01
        *   @version   - permitir tb o registo dos campos ID_RECM e DT_VAL_RECM 
        *
        *   @author    Pedro Santos         
        *   @date      2008/10/02
        *   @version   2.4.3-Denormalized 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next   pat_cli_attributes.id_pat_cli_attributes%TYPE;
        l_char   VARCHAR2(1);
        l_rowids table_varchar;
        CURSOR c_pat IS
            SELECT 'X'
              FROM pat_cli_attributes
             WHERE id_patient = i_id_pat;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_pat;
        FETCH c_pat
            INTO l_char;
        g_found := c_pat%FOUND;
        CLOSE c_pat;
        IF g_found
        THEN
            UPDATE pat_cli_attributes
               SET flg_breast_feed = i_flg_breast_feed,
                   flg_pregnancy   = i_flg_pregnancy,
                   id_recm         = i_id_recm,
                   dt_val_recm     = i_dt_val_recm
             WHERE id_patient = i_id_pat;
        ELSE
            g_error := 'GET SEQ_PAT_CLI_ATTRIBUTES.NEXTVAL';
            l_next  := ts_pat_cli_attributes.next_key();
        
            g_error := 'INSERT PAT_CLI_ATTRIBUTES';
            ts_pat_cli_attributes.ins(id_pat_cli_attributes_in => l_next,
                                      id_patient_in            => i_id_pat,
                                      flg_pregnancy_in         => i_flg_pregnancy,
                                      flg_breast_feed_in       => i_flg_breast_feed,
                                      id_institution_in        => i_prof.institution,
                                      id_recm_in               => i_id_recm,
                                      dt_val_recm_in           => i_dt_val_recm,
                                      id_episode_in            => nvl(i_epis, -1),
                                      rows_out                 => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-PAT_CLI_ATTRIBUTES';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_CLI_ATTRIBUTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'CALL TO SET_FIRST_OBS';
        
            -- pk_visit.set_first_obs não é aplicavel no caso do P1
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => NULL,
                                          i_pat                 => i_id_pat,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_CLI_ATT_INTERNAL',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_cli_att
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_pregnancy   IN pat_cli_attributes.flg_pregnancy%TYPE,
        i_flg_breast_feed IN pat_cli_attributes.flg_breast_feed%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_id_recm         IN pat_cli_attributes.id_recm%TYPE,
        i_dt_val_recm     IN pat_cli_attributes.dt_val_recm%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        *   Registar info clínica do doente, com commit
        *   LG 2006-09-01 permitir tb o registo dos campos ID_RECM e DT_VAL_RECM 
        *   @param   I_LANG - Língua registada como preferência do profissional 
        *   @param   I_ID_PAT - Id do doente 
        *   @param   I_FLG_PREGNANCY - indica se a utente está grávida (Y/N) 
        *   @param   I_FLG_BREAST_FEED - indica se a utente está a amamentar (Y/N) 
        *   @param   I_PROF - profissional q regista 
        *   @param   I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                     como é retornada em PK_LOGIN.GET_PROF_PREF
        *   @param   I_ID_RECM  - regime especial de comparticipação medicamentosa
        *   @param   I_DT_VAL_RECM - data de validade do RECM
        *   @param   I_EPIS
        *   @param   O_ERROR - erro 
        *        
        *   @author  CRS 
        *   @version
        *   @date    2005/03/17   
        *
        *   @author  Pedro Santos
        *   @version 2.4.3-Denormalized
        *   @since   2008/10/02           
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        IF NOT pk_patient.set_pat_cli_att_internal(i_lang,
                                                   i_id_pat,
                                                   i_flg_pregnancy,
                                                   i_flg_breast_feed,
                                                   i_prof,
                                                   i_prof_cat_type,
                                                   i_id_recm,
                                                   i_dt_val_recm,
                                                   i_epis,
                                                   o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_CLI_ATT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_pat_cli_att
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        o_id_pat_cli_attr OUT pat_cli_attributes.id_pat_cli_attributes%TYPE,
        o_flg_pregnancy   OUT pat_cli_attributes.flg_pregnancy%TYPE,
        o_flg_breast_feed OUT pat_cli_attributes.flg_breast_feed%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter info clínica do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               Saida:   O_FLG_PREGNANCY - indica se a utente está grávida (Y/N) 
               O_FLG_BREAST_FEED - indica se a utente está a amamentar (Y/N) 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/03/17 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        CURSOR c_pat_cli IS
            SELECT pa.id_pat_cli_attributes, pa.flg_breast_feed, pa.flg_pregnancy
              FROM pat_cli_attributes pa
             WHERE pa.id_patient = i_id_pat;
    
    BEGIN
        OPEN c_pat_cli;
        FETCH c_pat_cli
            INTO o_id_pat_cli_attr, o_flg_pregnancy, o_flg_breast_feed;
        CLOSE c_pat_cli;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CLI_ATT',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION set_pat_blood_int
    (
        i_lang            IN language.id_language%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_group       IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh          IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other      IN pat_blood_group.desc_other_system%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_analysis_result IN analysis_result.id_analysis_result%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_pat_blood_int(i_lang               => i_lang,
                                 i_epis               => i_epis,
                                 i_id_pat             => i_id_pat,
                                 i_flg_group          => i_flg_group,
                                 i_flg_rh             => i_flg_rh,
                                 i_desc_other         => i_desc_other,
                                 i_prof               => i_prof,
                                 i_prof_cat_type      => i_prof_cat_type,
                                 i_dt_pat_blood_group => NULL,
                                 i_analysis_result    => i_analysis_result,
                                 o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_BLOOD',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_blood_int;

    /******************************************************************************
       OBJECTIVO:   Registar grupo sanguíneo do doente  
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
              I_ID_PAT - Id do doente 
           I_FLG_GROUP - Grupo sanguineo: A, B, AB, O 
           I_FLG_RH - Factor Rhesus: P - positivo, N - negativo 
           I_DESC_OTHER - Outros sistemas 
           I_PROF - prof. q regista 
           I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                  como é retornada em PK_LOGIN.GET_PROF_PREF 
           Saida:   O_ERROR - erro 
           
      CRIAÇÃO: CRS 2005/06/16 
      NOTAS: 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    *********************************************************************************/

    FUNCTION set_pat_blood_int
    (
        i_lang               IN language.id_language%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_flg_group          IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh             IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other         IN pat_blood_group.desc_other_system%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_pat_blood_group IN pat_blood_group.dt_pat_blood_group_tstz%TYPE,
        i_analysis_result    IN analysis_result.id_analysis_result%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next         pat_blood_group.id_pat_blood_group%TYPE;
        l_id           pat_blood_group.id_pat_blood_group%TYPE;
        l_dt_pat_blood pat_blood_group.dt_pat_blood_group_tstz%TYPE;
    
        CURSOR c_blood IS
            SELECT id_pat_blood_group
              FROM pat_blood_group
             WHERE id_patient = i_id_pat
               AND flg_status = g_pat_blood_active;
    
        pat_exception EXCEPTION;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_blood';
        OPEN c_blood;
        FETCH c_blood
            INTO l_id;
        g_found := c_blood%FOUND;
        CLOSE c_blood;
        IF g_found
        THEN
            g_error := 'UPDATE pat_blood_group';
            UPDATE pat_blood_group
               SET flg_status = g_pat_blood_inactive
             WHERE id_pat_blood_group = l_id;
        END IF;
    
        g_error := 'GET SEQ_PAT_BLOOD_GROUP.NEXTVAL';
        SELECT seq_pat_blood_group.nextval
          INTO l_next
          FROM dual;
    
        IF i_dt_pat_blood_group IS NULL
        THEN
            l_dt_pat_blood := g_sysdate_tstz;
        ELSE
            l_dt_pat_blood := i_dt_pat_blood_group;
        END IF;
    
        g_error := 'INSERT pat_blood_group';
        INSERT INTO pat_blood_group
            (id_pat_blood_group,
             dt_pat_blood_group_tstz,
             id_patient,
             id_professional,
             flg_blood_group,
             flg_blood_rhesus,
             flg_status,
             desc_other_system,
             id_institution,
             id_episode,
             id_analysis_result)
        VALUES
            (l_next,
             l_dt_pat_blood,
             i_id_pat,
             i_prof.id,
             i_flg_group,
             i_flg_rh,
             g_pat_blood_active,
             i_desc_other,
             i_prof.institution,
             i_epis,
             i_analysis_result);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE pat_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pat_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_BLOOD_INT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_BLOOD_INT',
                                              o_error);
            RETURN FALSE;
    END set_pat_blood_int;

    FUNCTION set_pat_blood
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_flg_group     IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh        IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other    IN pat_blood_group.desc_other_system%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        pat_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'Call set_pat_blood_int';
        IF NOT set_pat_blood_int(i_lang          => i_lang,
                                 i_epis          => i_epis,
                                 i_id_pat        => i_id_pat,
                                 i_flg_group     => i_flg_group,
                                 i_flg_rh        => i_flg_rh,
                                 i_desc_other    => i_desc_other,
                                 i_prof          => i_prof,
                                 i_prof_cat_type => i_prof_cat_type,
                                 o_error         => o_error)
        THEN
            RAISE pat_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN pat_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_BLOOD',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_BLOOD',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_blood;

    FUNCTION with_notes
    (
        i_lang  IN language.id_language%TYPE,
        id_ares IN analysis_result.id_analysis_result%TYPE
    ) RETURN VARCHAR2 AS
        l_tbl_v table_number := table_number();
    BEGIN
        SELECT 1
          BULK COLLECT
          INTO l_tbl_v
          FROM analysis_result ar
         INNER JOIN analysis_result_par arp
            ON arp.id_analysis_result = ar.id_analysis_result
         WHERE ar.id_analysis_result = id_ares
           AND dbms_lob.getlength(arp.parameter_notes) IS NOT NULL;
    
        IF l_tbl_v.count > 0
        THEN
            RETURN pk_message.get_message(i_lang, 'COMMON_M101');
        ELSE
            RETURN NULL;
        END IF;
    END with_notes;

    FUNCTION get_pat_blood
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_blood  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter histórico de grupos sanguíneos do utente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               Saida:   O_BLOOD - histórico de grupos sanguíneos 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/06/16 
          ALTERAÇÃO: CRS 2006/08/29 Se registo inactivo, mostra data de cancelamento 
                  Estado cancelado a seguir ao grupo sanguíneo 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_blood FOR
            SELECT t.id_pat_blood_group,
                   t.id_analysis_result_par,
                   t.flg_status,
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || t.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || t.id_sample_type,
                                                            NULL) desc_analysis,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_reg,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_pat_blood_group_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    t.dt_pat_blood_group_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   t.desc_analysis_result blood_group,
                   decode(t.flg_status, g_pat_blood_inactive, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                   pk_patient.with_notes(i_lang, t.id_analysis_result) with_notes,
                   pk_date_utils.to_char_insttimezone(i_prof, t.dt_pat_blood_group_tstz, 'YYYYMMDDHH24MISS') dt_ord
              FROM (SELECT p.id_pat_blood_group,
                           ar.id_analysis,
                           ar.id_sample_type,
                           ar.id_analysis_result id_analysis_result,
                           CAST(COLLECT(arp.id_analysis_result_par) AS table_number_id) id_analysis_result_par,
                           listagg(arp.desc_analysis_result, ' ') within GROUP(ORDER BY arp.dt_analysis_result_par_tstz) desc_analysis_result,
                           p.dt_pat_blood_group_tstz,
                           p.id_professional,
                           p.flg_status
                      FROM pat_blood_group p, analysis_result ar, analysis_result_par arp
                     WHERE p.id_patient = i_id_pat
                       AND ar.id_analysis_result = p.id_analysis_result
                       AND arp.id_analysis_result = ar.id_analysis_result
                     GROUP BY p.id_pat_blood_group,
                              ar.id_analysis,
                              ar.id_sample_type,
                              ar.id_analysis_result,
                              p.flg_status,
                              p.dt_pat_blood_group_tstz,
                              p.id_professional) t
             ORDER BY t.dt_pat_blood_group_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BLOOD',
                                              o_error);
            pk_types.open_my_cursor(o_blood);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /******************************************************************************
       OBJECTIVO:   Obter detalhe do histórico do grupos sanguíneos do paciente 
       PARAMETROS:  Entrada: 
                    i_lang              - Língua registada como preferência do profissional 
                    i_id_pat            - Id do doente 
                    i_prof              - Id do profissional
                    id_pat_blood_group  - Id do registo de grupo sanguíneo(não está a ser usado para já)
                    i_all               - True (Create + Review), False (Only Create)
                    
                    Saida:   
                    o_blood_detail      - histórico de grupos sanguíneos 
                    o_error             - erro 
           
      CRIAÇÃO: Rui Duarte 2009/10/25 
      ACTUALIZAÇÃO: Filipe Machado 2009/12/10 
    
      NOTAS: 
    *********************************************************************************/
    FUNCTION get_pat_blood_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        id_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        i_all              IN BOOLEAN DEFAULT FALSE,
        o_blood_detail     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_groop              sys_message.desc_message%TYPE;
        l_rh                 sys_message.desc_message%TYPE;
        l_ohter_system       sys_message.desc_message%TYPE;
        l_label_review       sys_message.desc_message%TYPE;
        l_label_review_desc  sys_message.desc_message%TYPE;
        l_label_review_notes sys_message.desc_message%TYPE;
        l_all                PLS_INTEGER;
    
    BEGIN
    
        l_groop             := pk_message.get_message(i_lang, 'BLOOD_LIST_T001');
        l_rh                := pk_message.get_message(i_lang, 'BLOOD_LIST_T002');
        l_ohter_system      := pk_message.get_message(i_lang, 'BLOOD_LIST_T003');
        l_label_review      := pk_message.get_message(i_lang, 'DETAIL_COMMON_M004');
        l_label_review_desc := pk_message.get_message(i_lang, 'DETAIL_COMMON_M005');
    
        l_label_review_notes := pk_message.get_message(i_lang, 'PATIENT_HABITS_T007'); --a new label should be crerated
    
        g_blood_type_review_area := pk_review.get_blood_type_context();
    
        l_all := sys.diutil.bool_to_int(i_all);
    
        g_error := 'GET CURSOR';
        OPEN o_blood_detail FOR
            SELECT pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_STATUS', pbg.flg_status, i_lang) desc_edit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pbg.id_professional) prof_reg,
                   pk_date_utils.date_char_tsz(i_lang, pbg.dt_pat_blood_group_tstz, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pbg.id_professional,
                                                    pbg.dt_pat_blood_group_tstz,
                                                    pbg.id_episode) prof_spec_reg,
                   l_groop desc_blood_group,
                   pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_GROUP', pbg.flg_blood_group, i_lang) blood_group,
                   l_rh desc_blood_rhesus,
                   pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', pbg.flg_blood_rhesus, i_lang) blood_rhesus,
                   l_ohter_system desc_other_system,
                   pbg.desc_other_system other_system,
                   pk_alert_constant.g_no flg_review,
                   NULL review,
                   NULL desc_notes,
                   pbg.flg_status,
                   pbg.id_pat_blood_group,
                   pk_date_utils.date_send_tsz(i_lang, pbg.dt_pat_blood_group_tstz, i_prof) dt_order,
                   NULL notes
              FROM pat_blood_group pbg
             WHERE pbg.id_patient = i_id_pat
            UNION ALL
            SELECT l_label_review desc_edit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) prof_reg,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, pbg.id_episode) prof_spec_reg,
                   NULL desc_blood_group,
                   NULL blood_group,
                   NULL desc_blood_rhesus,
                   NULL blood_rhesus,
                   NULL desc_other_system,
                   NULL other_system,
                   pk_alert_constant.g_yes flg_review,
                   l_label_review_desc review,
                   l_label_review_notes desc_notes,
                   NULL flg_status,
                   NULL id_pat_blood_group,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_order,
                   rd.review_notes notes
              FROM review_detail rd, pat_blood_group pbg
             WHERE rd.id_record_area = pbg.id_pat_blood_group
               AND pbg.id_patient = i_id_pat
               AND rd.flg_context = g_blood_type_review_area
               AND l_all > 0
             ORDER BY dt_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BLOOD_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_blood_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_blood_detail;

    FUNCTION get_pat_blood_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        id_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_blood_detail     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT get_pat_blood_detail(i_lang             => i_lang,
                                    i_id_pat           => i_id_pat,
                                    i_prof             => i_prof,
                                    id_pat_blood_group => id_pat_blood_group,
                                    i_all              => TRUE,
                                    o_blood_detail     => o_blood_detail,
                                    o_error            => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BLOOD_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_blood_detail;

    FUNCTION set_pat_vaccine
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN pat_vaccine.id_patient%TYPE,
        i_prof            IN profissional,
        i_vaccine         IN pat_vaccine.id_vaccine%TYPE,
        i_instit          IN pat_vaccine.id_institution%TYPE,
        i_dt_take         IN VARCHAR2,
        i_flg_take_type   IN pat_vaccine.flg_take_type%TYPE,
        i_lab             IN pat_vaccine.lab%TYPE,
        i_lote            IN pat_vaccine.lote%TYPE,
        i_notes           IN pat_vaccine.notes%TYPE,
        i_tuberculin_type IN pat_vaccine.tuberculin_type%TYPE,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        * Registar vacinas 
        * @param              I_LANG - Língua registada como preferência do profissional 
        * @param              I_ID_PAT - Id do doente 
        * @param              I_PROF - profissional responsável pelo registo 
        * @param              I_VACCINE - ID da vacina administrada 
        * @param              I_DT_TAKE - data da toma 
        * @param              I_FLG_TAKE_TYPE - P - primovacinação, R - reforço 
        * @param              I_LAB - Laboratório de proveniência 
        * @param              I_LOTE - Lote 
        * @param              I_NOTES - notas 
        * @param              I_TUBERCULIN_TYPE - Tipo de tuberculina administrada 
                                nas provas tuberculínicas 
        * @param              I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                              como é retornada em PK_LOGIN.GET_PROF_PREF 
        * @param              I_Epis
        * @param              O_ERROR - erro 
        *              
        * @author CRS 
        * @since  2005/03/17 
        *
        * @author Pedro Santos 
        * @since  2008/10/03 
        * @version 2.4.3-denormalized
        * reason added id_episode to table pat_vaccine
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_next    pat_vaccine.id_pat_vaccine%TYPE;
        l_dt_take TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowids  table_varchar;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        l_dt_take      := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_take, NULL);
    
        g_error := 'GET SEQ_PAT_VACCINE.NEXTVAL';
        l_next  := ts_pat_vaccine.next_key();
    
        g_error := 'INSERT INTO PAT_VACCINE';
        ts_pat_vaccine.ins(id_pat_vaccine_in      => l_next,
                           id_patient_in          => i_id_pat,
                           id_institution_in      => i_prof.institution,
                           id_vaccine_in          => i_vaccine,
                           dt_pat_vaccine_tstz_in => g_sysdate_tstz,
                           id_professional_in     => i_prof.id,
                           dt_take_tstz_in        => l_dt_take,
                           flg_take_type_in       => i_flg_take_type,
                           lab_in                 => i_lab,
                           lote_in                => i_lote,
                           notes_in               => i_notes,
                           tuberculin_type_in     => i_tuberculin_type,
                           id_episode_in          => i_epis,
                           rows_out               => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-PAT_VACCINE';
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_VACCINE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_VACCINE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_vaccine
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_vaccine.id_patient%TYPE,
        i_vaccine IN pat_vaccine.id_vaccine%TYPE,
        i_prof    IN profissional,
        o_vaccine OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter vacinas administradas ao utente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - Id do doente 
               I_VACCINE - ID de uma vacina  
               Saida:   O_VACCINE - vacinas administradas 
               O_ERROR - erro 
               
          CRIAÇÃO: CRS 2005/03/17 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_vaccine FOR
            SELECT p.id_pat_vaccine,
                   pk_date_utils.date_char_tsz(i_lang, p.dt_pat_vaccine_tstz, i_prof.institution, i_prof.software) dt_pat_vaccine,
                   pk_translation.get_translation(i_lang, v.code_vaccine) vacc,
                   pk_translation.get_translation(i_lang, i.code_institution) instit,
                   pk_date_utils.dt_chr_tsz(i_lang, p.dt_take_tstz, i_prof) dt_take,
                   p.lab,
                   p.lote,
                   p.notes,
                   p.tuberculin_type,
                   pk_sysdomain.get_domain('PAT_VACCINE.FLG_TAKE_TYPE', p.flg_take_type, i_lang)
              FROM pat_vaccine p, institution i, vaccine v
             WHERE i.id_institution = p.id_institution
               AND p.id_vaccine = v.id_vaccine
               AND p.id_vaccine = nvl('I_VACCINE', p.id_vaccine)
             ORDER BY p.dt_take_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_VACCINE',
                                              o_error);
            pk_types.open_my_cursor(o_vaccine);
            RETURN FALSE;
    END;

    FUNCTION get_pat_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN pat_notes.id_patient%TYPE,
        i_flg_status IN pat_notes.flg_status%TYPE,
        i_prof       IN profissional,
        o_notes      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar notas do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
                I_FLG_STATUS - Estado da nota
                    A - activa
                   C - Cancelada
                   outros valores - todas
               Saida:   O_NOTES - cursor com as notas do doente 
              O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/15
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *********************************************************************************/
        l_aux pat_notes.id_patient%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT DISTINCT id_patient
              INTO l_aux
              FROM v_pat_notes
             WHERE id_patient = i_id_pat;
        
            g_error := 'GET CURSOR1';
            OPEN o_notes FOR
                SELECT 'R' reg,
                       id_pat_notes,
                       notes,
                       flg_status,
                       pk_sysdomain.get_domain('PAT_NOTES.FLG_NOTES', n.flg_status, i_lang) desc_flg_status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) nick_name_prof_writes,
                       pk_date_utils.date_char_tsz(i_lang, n.dt_note_tstz, i_prof.institution, i_prof.software) dt_note,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p2.id_professional) nick_name_prof_cancel,
                       pk_date_utils.date_char_tsz(i_lang, n.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                       note_cancel,
                       g_pat_note_flg_active flg_status_active,
                       g_pat_note_flg_cancel flg_status_cancel,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p1.id_professional,
                                                        n.dt_note_tstz,
                                                        n.id_episode) spec,
                       pk_sysdomain.get_domain('PAT_NOTES.FLG_NOTES', g_pat_note_flg_active, i_lang) desc_flg_status_active,
                       pk_sysdomain.get_domain('PAT_NOTES.FLG_NOTES', g_pat_note_flg_cancel, i_lang) desc_flg_status_cancel
                  FROM v_pat_notes n, professional p1, professional p2, speciality s
                 WHERE n.id_patient = i_id_pat
                   AND (n.flg_status = i_flg_status OR nvl(i_flg_status, NULL) IS NULL)
                   AND p1.id_professional(+) = n.id_prof_writes
                   AND p2.id_professional(+) = n.id_prof_cancel
                   AND s.id_speciality(+) = p1.id_speciality
                 ORDER BY n.dt_note_tstz DESC;
        
        EXCEPTION
            WHEN no_data_found THEN
            
                g_error := 'GET CURSOR2';
                OPEN o_notes FOR
                    SELECT 'N' reg,
                           NULL id_pat_notes,
                           pk_message.get_message(i_lang, 'COMMON_M007') notes,
                           NULL flg_status,
                           NULL desc_flg_status,
                           NULL nick_name_prof_writes,
                           NULL dt_note,
                           NULL nick_name_prof_cancel,
                           NULL dt_cancel,
                           NULL note_cancel,
                           NULL flg_status_active,
                           NULL flg_status_cancel,
                           NULL spec,
                           NULL desc_flg_status_active,
                           NULL desc_flg_status_cancel
                      FROM dual;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_notes;

    FUNCTION set_pat_notes
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_id_pat IN pat_notes.id_patient%TYPE,
        i_prof   IN profissional,
        i_notes  IN pat_notes.notes%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Guarda notas do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
                I_PROF - ID do profissional
                I_NOTES - Notas do profissional
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/15
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        CURSOR c_cat IS
            SELECT flg_type
              FROM category c, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND c.id_category = pc.id_category;
    
        l_cat category.flg_type%TYPE;
    
        l_ph_ft_id       pat_past_hist_ft_hist.id_pat_ph_ft%TYPE;
        l_pat_ph_ft_hist pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INSERT PAT_NOTES FREE TEXT';
        IF NOT pk_past_history.set_past_hist_free_text(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_pat              => i_id_pat,
                                                       i_episode          => i_epis,
                                                       i_doc_area         => pk_summary_page.g_doc_area_relev_notes,
                                                       i_ph_ft_id         => NULL,
                                                       i_ph_ft_text       => i_notes,
                                                       i_id_cancel_reason => NULL,
                                                       i_cancel_notes     => NULL,
                                                       i_dt_register      => g_sysdate_tstz,
                                                       i_dt_review        => NULL,
                                                       o_ph_ft_id         => l_ph_ft_id,
                                                       o_pat_ph_ft_hist   => l_pat_ph_ft_hist,
                                                       o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_notes;

    FUNCTION cancel_pat_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_notes IN pat_notes.id_pat_notes%TYPE,
        i_prof         IN profissional,
        i_notes        IN pat_notes.notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancela notas do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT_NOTES - ID da nota a cancelar 
                I_PROF - ID do profissional
                I_NOTES - Notas do concelamento do profissional
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/15
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        v_id_pat_notes pat_notes.id_pat_notes%TYPE;
        l_pat          pat_notes.id_patient%TYPE;
    
        CURSOR c_pat_notes IS
            SELECT id_pat_notes, id_patient
              FROM pat_notes
             WHERE id_pat_notes = i_id_pat_notes
               AND nvl(flg_status, g_pat_note_flg_active) = g_pat_note_flg_active;
    
        e_notfound EXCEPTION;
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET ID_PAT_NOTES';
        --Valida se a nota existe e ainda não está cancelada
        OPEN c_pat_notes;
        FETCH c_pat_notes
            INTO v_id_pat_notes, l_pat;
        g_found := c_pat_notes%NOTFOUND;
        CLOSE c_pat_notes;
        IF g_found
        THEN
            RAISE e_notfound;
        
        END IF;
    
        --cancela a nota
        g_error := 'CANCEL PAT_NOTES';
        UPDATE pat_notes
           SET id_prof_cancel = i_prof.id,
               dt_cancel_tstz = g_sysdate_tstz,
               note_cancel    = i_notes,
               flg_status     = g_pat_note_flg_cancel
         WHERE id_pat_notes = i_id_pat_notes
           AND flg_status != g_pat_note_flg_cancel;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => l_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_notfound THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PATIENT_M003',
                                              pk_message.get_message(i_lang, 'PATIENT_M003'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_pat_notes;

    FUNCTION ins_pat_problem_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_problem_hist pat_problem_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_patient.ins_pat_problem_hist_no_commit(i_lang             => i_lang,
                                                         i_pat_problem_hist => i_pat_problem_hist,
                                                         o_error            => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
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
                                              'INS_PAT_PROBLEM_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_pat_problem_hist;

    FUNCTION ins_pat_problem_hist_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_problem_hist pat_problem_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere registos de histórico na tabela PAT_PROBLEM_HIST 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_PAT_PROBLEM_HIST - Registo a inserir
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/19 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
        l_rowids table_varchar;
    BEGIN
        ts_pat_problem_hist.ins(id_pat_problem_hist_in       => ts_pat_problem_hist.next_key,
                                id_pat_problem_in            => i_pat_problem_hist.id_pat_problem,
                                id_patient_in                => i_pat_problem_hist.id_patient,
                                id_diagnosis_in              => i_pat_problem_hist.id_diagnosis,
                                id_professional_ins_in       => i_pat_problem_hist.id_professional_ins,
                                dt_pat_problem_tstz_in       => i_pat_problem_hist.dt_pat_problem_tstz,
                                desc_pat_problem_in          => i_pat_problem_hist.desc_pat_problem,
                                notes_in                     => i_pat_problem_hist.notes,
                                flg_age_in                   => i_pat_problem_hist.flg_age,
                                year_begin_in                => i_pat_problem_hist.year_begin,
                                month_begin_in               => i_pat_problem_hist.month_begin,
                                day_begin_in                 => i_pat_problem_hist.day_begin,
                                year_end_in                  => i_pat_problem_hist.year_end,
                                month_end_in                 => i_pat_problem_hist.month_end,
                                day_end_in                   => i_pat_problem_hist.day_end,
                                pct_incapacity_in            => i_pat_problem_hist.pct_incapacity,
                                flg_surgery_in               => i_pat_problem_hist.flg_surgery,
                                notes_support_in             => i_pat_problem_hist.notes_support,
                                dt_confirm_tstz_in           => i_pat_problem_hist.dt_confirm_tstz,
                                rank_in                      => i_pat_problem_hist.rank,
                                flg_status_in                => i_pat_problem_hist.flg_status,
                                flg_aproved_in               => i_pat_problem_hist.flg_aproved,
                                id_epis_diagnosis_in         => i_pat_problem_hist.id_epis_diagnosis,
                                id_institution_in            => i_pat_problem_hist.id_institution,
                                id_episode_in                => i_pat_problem_hist.id_episode,
                                id_epis_anamnesis_in         => i_pat_problem_hist.id_epis_anamnesis,
                                flg_nature_in                => i_pat_problem_hist.flg_nature,
                                id_alert_diagnosis_in        => i_pat_problem_hist.id_alert_diagnosis,
                                id_cancel_reason_in          => i_pat_problem_hist.id_cancel_reason,
                                cancel_notes_in              => i_pat_problem_hist.cancel_notes,
                                id_pat_habit_in              => i_pat_problem_hist.id_pat_habit,
                                dt_resolution_in             => i_pat_problem_hist.dt_resolution,
                                id_habit_characterization_in => i_pat_problem_hist.id_habit_characterization,
                                rows_out                     => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => NULL,
                                      i_table_name => 'PAT_PROBLEM_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INS_PAT_PROBLEM_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION ins_pat_allergy_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_allergy_hist pat_allergy_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere registos de histórico na tabela PAT_ALLERGY_HIST 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                    I_PAT_PROBLEM_HIST - Registo a inserir
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/04/19 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    BEGIN
        INSERT INTO pat_allergy_hist
            (id_pat_allergy_hist,
             id_pat_allergy,
             dt_pat_allergy_tstz,
             id_patient,
             flg_status,
             notes,
             id_prof_write,
             dt_first_time_tstz,
             flg_type,
             flg_aproved,
             year_begin,
             month_begin,
             day_begin,
             year_end,
             month_end,
             day_end,
             id_institution,
             id_episode)
        VALUES
            (seq_pat_allergy_hist.nextval,
             i_pat_allergy_hist.id_pat_allergy,
             i_pat_allergy_hist.dt_pat_allergy_tstz,
             i_pat_allergy_hist.id_patient,
             i_pat_allergy_hist.flg_status,
             i_pat_allergy_hist.notes,
             i_pat_allergy_hist.id_prof_write,
             i_pat_allergy_hist.dt_first_time_tstz,
             i_pat_allergy_hist.flg_type,
             i_pat_allergy_hist.flg_aproved,
             i_pat_allergy_hist.year_begin,
             i_pat_allergy_hist.month_begin,
             i_pat_allergy_hist.day_begin,
             i_pat_allergy_hist.year_end,
             i_pat_allergy_hist.month_end,
             i_pat_allergy_hist.day_end,
             i_pat_allergy_hist.id_institution,
             i_pat_allergy_hist.id_episode);
    
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
                                              'INS_PAT_ALLERGY_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION check_pat_habit
    (
        i_lang   IN language.id_language%TYPE,
        i_habit  IN habit.id_habit%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        o_msg    OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verifica se ao hábito já tinha sido atribuído ao doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_HABIT - ID do hábito 
             I_ID_PAT - ID do doente 
               Saida: O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
             O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
             O_FLG_SHOW = Y 
             O_MSG_TEXT - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
             O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
              Tb pode mostrar combinações destes, qd é p/ mostrar 
              + do q 1 botão 
                  O_ERROR - erro 
         
          CRIAÇÃO: SS 2006/02/15 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_char VARCHAR2(1);
    
        CURSOR c_habit IS
            SELECT 'X'
              FROM pat_habit pa
             WHERE pa.id_habit = i_habit
               AND pa.id_patient = i_id_pat
               AND flg_status != g_pat_habit_canc;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_HABIT';
        OPEN c_habit;
        FETCH c_habit
            INTO l_char;
        g_found := c_habit%FOUND; -- Este hábito já foi atribuído a este doente 
        CLOSE c_habit;
    
        IF g_found
        THEN
            o_msg := pk_message.get_message(i_lang, 'PATIENT_M012');
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
                                              'CHECK_PAT_HABIT',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_habit_dt_begin
    (
        i_dt_begin_hab IN VARCHAR2,
        o_dt_begin_hab OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin_hab table_varchar;
    
    BEGIN
    
        l_dt_begin_hab := table_varchar();
    
        l_dt_begin_hab.extend(3);
    
        g_error := 'GET BEGIN DATE';
        IF i_dt_begin_hab IS NOT NULL
        THEN
        
            l_dt_begin_hab(1) := substr(i_dt_begin_hab, 1, 4);
            l_dt_begin_hab(2) := substr(i_dt_begin_hab, 5, 2);
            l_dt_begin_hab(3) := substr(i_dt_begin_hab, 7, 2);
        
        END IF;
        o_dt_begin_hab := l_dt_begin_hab;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HABIT_DT_BEGIN',
                                              o_error);
            RETURN FALSE;
        
    END get_habit_dt_begin;

    /********************************************************************************************
    * get detail last record
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_episode                   Episode ID
    * @param i_patient                   Patient ID
    * @param i_pat_habit                 Patient habit ID
    * @param o_habit_detail              habit cursor
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   19-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/
    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN pat_habit.id_episode%TYPE,
        i_patient      IN pat_habit.id_patient%TYPE,
        i_pat_habit    IN pat_habit.id_pat_habit%TYPE,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_probl IS
            SELECT id_pat_problem
              FROM pat_problem
             WHERE id_pat_habit = i_pat_habit;
    
        l_id_pat_probl pat_problem.id_pat_habit%TYPE;
    
        l_habit                     sys_message.desc_message%TYPE;
        l_start                     sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_created             sys_message.desc_message%TYPE;
        l_label_edited              sys_message.desc_message%TYPE;
        l_label_cancelled           sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_characterization    sys_message.desc_message%TYPE;
    
        l_fst_dt_order VARCHAR2(200);
    
    BEGIN
    
        l_habit                     := pk_message.get_message(i_lang, 'PATIENT_HABITS_T005');
        l_start                     := pk_message.get_message(i_lang, 'PATIENT_HABITS_T006');
        l_label_status              := pk_message.get_message(i_lang, 'PATIENT_HABITS_T004');
        l_label_nature              := pk_message.get_message(i_lang, 'PATIENT_HABITS_T013');
        l_label_notes               := pk_message.get_message(i_lang, 'PATIENT_HABITS_T007');
        l_label_created             := pk_message.get_message(i_lang, 'DETAIL_COMMON_M001');
        l_label_edited              := pk_message.get_message(i_lang, 'DETAIL_COMMON_M002');
        l_label_cancelled           := pk_message.get_message(i_lang, 'DETAIL_COMMON_M003');
        l_label_cancellation_reason := pk_message.get_message(i_lang, 'DETAIL_COMMON_M006');
        l_label_cancellation_notes  := pk_message.get_message(i_lang, 'DETAIL_COMMON_M007');
        l_label_characterization    := pk_message.get_message(i_lang, 'HABIT_CARACTERIZATION_M001');
    
        OPEN c_pat_probl;
        FETCH c_pat_probl
            INTO l_id_pat_probl;
    
        --get habit first record date (oldest)
        SELECT MIN(dt_order)
          INTO l_fst_dt_order
          FROM (SELECT pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order
                  FROM pat_problem pp, professional p
                 WHERE pp.id_pat_problem = l_id_pat_probl
                   AND pp.id_professional_ins = p.id_professional
                UNION ALL
                SELECT pk_date_utils.date_send_tsz(i_lang, pph.dt_pat_problem_tstz, i_prof) dt_order
                  FROM pat_problem_hist pph, professional p
                 WHERE pph.id_pat_problem = l_id_pat_probl
                   AND pph.id_professional_ins = p.id_professional);
    
        g_error := 'GET O_HABIT_DETAIL';
        OPEN o_habit_detail FOR
            SELECT *
              FROM (SELECT decode(pp1.flg_status,
                                  pk_alert_constant.g_cancelled,
                                  l_label_cancelled,
                                  decode(pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof),
                                         l_fst_dt_order,
                                         l_label_created,
                                         l_label_edited)) desc_edit,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_reg,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       pp1.dt_pat_problem_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_reg,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p1.id_professional,
                                                            pp1.dt_pat_problem_tstz,
                                                            pp1.id_episode) prof_spec_reg,
                           l_habit desc_habit,
                           pk_translation.get_translation(i_lang, h.code_habit) habit,
                           l_label_status desc_status,
                           pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', pp1.flg_status, i_lang) status,
                           l_label_nature desc_nature,
                           pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang) nature,
                           l_start desc_dt_start,
                           decode(pp1.year_begin,
                                  '',
                                  '',
                                  decode(pp1.month_begin,
                                         '',
                                         to_char(pp1.year_begin),
                                         decode(pp1.day_begin,
                                                '',
                                                substr(to_char(to_date(pp1.year_begin || lpad(pp1.month_begin, 2, '0'),
                                                                       'YYYYMM'),
                                                               'DD-Mon-YYYY'),
                                                       4),
                                                pk_date_utils.dt_chr(i_lang,
                                                                     to_date(pp1.year_begin || lpad(pp1.month_begin, 2, '0') ||
                                                                             lpad(pp1.day_begin, 2, '0'),
                                                                             'YYYYMMDD'),
                                                                     i_prof)))) dt_start,
                           l_label_notes desc_notes,
                           pp1.notes notes,
                           l_label_cancellation_reason desc_cancel_reason,
                           (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                              FROM cancel_reason cr
                             WHERE cr.id_cancel_reason = pp1.id_cancel_reason) cancel_reason,
                           l_label_cancellation_notes desc_cancel_notes,
                           ph.cancel_notes cancel_notes,
                           pk_alert_constant.g_no flg_review,
                           NULL review_desc,
                           pp1.flg_status,
                           pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof) dt_order,
                           get_dt_begin_to_flash(i_lang, ph.id_pat_habit, pp1.id_patient, i_prof) dt_begin_to_flash,
                           pk_translation.get_translation(i_lang, hc.code_habit_characterization) habit_characterization,
                           l_label_characterization desc_habit_characterization,
                           ph.id_habit id_habit,
                           hc.id_habit_characterization
                      FROM pat_problem pp1, professional p1, pat_habit ph, habit h, habit_characterization hc
                     WHERE pp1.id_pat_problem = l_id_pat_probl
                       AND pp1.id_professional_ins = p1.id_professional
                       AND ph.id_habit = h.id_habit
                       AND ph.id_pat_habit = i_pat_habit
                       AND ph.id_habit_characterization = hc.id_habit_characterization(+)
                     ORDER BY dt_order DESC)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_PAT_HABIT');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_pat_habit;

    /********************************************************************************************
    * get patient problem row
    *
    * @param i_pat_problem               Patient problem ID
    * @param o_row                       Patient problem row type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   24-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/
    FUNCTION get_pat_problem_hist_row
    (
        i_pat_problem IN pat_problem.id_pat_problem%TYPE,
        o_row         OUT pat_problem_hist%ROWTYPE
    ) RETURN BOOLEAN IS
        CURSOR c_prob(l_id pat_problem.id_pat_problem%TYPE) IS
            SELECT id_pat_problem,
                   id_patient,
                   id_diagnosis,
                   id_alert_diagnosis,
                   id_professional_ins,
                   dt_pat_problem_tstz,
                   desc_pat_problem,
                   notes,
                   flg_age,
                   year_begin,
                   month_begin,
                   day_begin,
                   year_end,
                   month_end,
                   day_end,
                   pct_incapacity,
                   flg_surgery,
                   notes_support,
                   dt_confirm_tstz,
                   rank,
                   flg_status,
                   id_epis_diagnosis,
                   flg_aproved,
                   id_institution,
                   id_pat_habit,
                   id_episode,
                   id_epis_anamnesis,
                   cancel_notes,
                   id_cancel_reason,
                   dt_resolution,
                   flg_nature,
                   id_habit_characterization
              FROM pat_problem
             WHERE id_pat_problem = l_id;
    
        v_pat_problem_hist pat_problem_hist%ROWTYPE;
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN c_prob(i_pat_problem);
        FETCH c_prob
            INTO v_pat_problem_hist.id_pat_problem,
                 v_pat_problem_hist.id_patient, --
                 v_pat_problem_hist.id_diagnosis, --
                 v_pat_problem_hist.id_alert_diagnosis, --
                 v_pat_problem_hist.id_professional_ins, --
                 v_pat_problem_hist.dt_pat_problem_tstz, --
                 v_pat_problem_hist.desc_pat_problem, --
                 v_pat_problem_hist.notes,
                 v_pat_problem_hist.flg_age, --
                 v_pat_problem_hist.year_begin,
                 v_pat_problem_hist.month_begin, --
                 v_pat_problem_hist.day_begin,
                 v_pat_problem_hist.year_end, --
                 v_pat_problem_hist.month_end,
                 v_pat_problem_hist.day_end, --
                 v_pat_problem_hist.pct_incapacity,
                 v_pat_problem_hist.flg_surgery, --
                 v_pat_problem_hist.notes_support,
                 v_pat_problem_hist.dt_confirm_tstz, --
                 v_pat_problem_hist.rank,
                 v_pat_problem_hist.flg_status, --
                 v_pat_problem_hist.id_epis_diagnosis,
                 v_pat_problem_hist.flg_aproved, --
                 v_pat_problem_hist.id_institution,
                 v_pat_problem_hist.id_pat_habit, --
                 v_pat_problem_hist.id_episode,
                 v_pat_problem_hist.id_epis_anamnesis, --
                 v_pat_problem_hist.cancel_notes,
                 v_pat_problem_hist.id_cancel_reason, --
                 v_pat_problem_hist.flg_nature,
                 v_pat_problem_hist.dt_resolution,
                 v_pat_problem_hist.id_habit_characterization;
    
        g_found := c_prob%NOTFOUND;
        CLOSE c_prob;
    
        o_row := v_pat_problem_hist;
    
        RETURN TRUE;
    
    END get_pat_problem_hist_row;

    /********************************************************************************************
    * set patient's habit
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_episode                   Episode ID
    * @param i_patient                   Patient ID
    * @param i_pat_habit                 Patient habit ID
    * @param i_dt_begin                  Patient habit date begin
    * @param i_flg_status                Habit flag status
    * @param i_notes                     Notes
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   19-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/
    FUNCTION set_pat_habit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN pat_habit.id_episode%TYPE,
        i_patient                   IN pat_habit.id_patient%TYPE,
        i_pat_habit                 IN pat_habit.id_pat_habit%TYPE,
        i_dt_begin                  IN VARCHAR2,
        i_flg_status                IN pat_habit.flg_status%TYPE,
        i_notes                     IN pat_habit.notes%TYPE,
        i_id_habit_characterization IN habit_characterization.id_habit_characterization%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_problem pat_problem.id_pat_problem%TYPE;
    
        l_pat_prob_hist_row pat_problem_hist%ROWTYPE;
    
        l_flg_status pat_problem.flg_status%TYPE;
    
        l_new_status BOOLEAN;
    
        l_dt_begin table_varchar;
    
        l_rowids     table_varchar;
        l_rowids_aux table_varchar;
    BEGIN
    
        IF NOT get_habit_dt_begin(i_dt_begin, l_dt_begin, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT pap.id_pat_problem, pap.flg_status
          INTO l_pat_problem, l_flg_status
          FROM pat_problem pap
         WHERE pap.id_pat_habit = i_pat_habit;
    
        --BEGIN History 
        IF NOT get_pat_problem_hist_row(l_pat_problem, l_pat_prob_hist_row)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'INSERT HIST';
        IF NOT ins_pat_problem_hist(i_lang => i_lang, i_pat_problem_hist => l_pat_prob_hist_row, o_error => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --END  History
    
        g_error := 'UPDATE PAT_HABIT';
        ts_pat_habit.upd(id_pat_habit_in               => i_pat_habit,
                         flg_status_in                 => i_flg_status,
                         id_prof_writes_in             => i_prof.id,
                         id_prof_writes_nin            => FALSE,
                         dt_pat_habit_tstz_in          => current_timestamp,
                         id_institution_in             => i_prof.institution,
                         id_institution_nin            => FALSE,
                         year_begin_in                 => l_dt_begin(1),
                         year_begin_nin                => FALSE,
                         month_begin_in                => l_dt_begin(2),
                         month_begin_nin               => FALSE,
                         day_begin_in                  => l_dt_begin(3),
                         day_begin_nin                 => FALSE,
                         notes_in                      => i_notes,
                         notes_nin                     => FALSE,
                         id_episode_in                 => i_episode,
                         id_episode_nin                => FALSE,
                         id_habit_characterization_in  => i_id_habit_characterization,
                         id_habit_characterization_nin => FALSE,
                         rows_out                      => l_rowids);
    
        l_new_status := i_flg_status IN (g_flg_status_a, g_flg_status_p, g_flg_status_r);
    
        IF (l_flg_status = g_flg_status_c AND l_new_status)
        THEN
        
            ts_pat_habit.upd(id_pat_habit_in      => i_pat_habit,
                             note_cancel_in       => NULL,
                             note_cancel_nin      => FALSE,
                             cancel_notes_in      => NULL,
                             cancel_notes_nin     => FALSE,
                             id_prof_cancel_in    => NULL,
                             id_prof_cancel_nin   => FALSE,
                             id_cancel_reason_in  => NULL,
                             id_cancel_reason_nin => FALSE,
                             dt_cancel_tstz_in    => NULL,
                             dt_cancel_tstz_nin   => FALSE,
                             rows_out             => l_rowids);
        
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HABIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --Pat problem
        ts_pat_problem.upd(id_pat_problem_in             => l_pat_problem,
                           flg_status_in                 => i_flg_status,
                           dt_pat_problem_tstz_in        => current_timestamp,
                           id_professional_ins_in        => i_prof.id,
                           id_professional_ins_nin       => FALSE,
                           id_institution_in             => i_prof.institution,
                           id_institution_nin            => FALSE,
                           notes_in                      => i_notes,
                           notes_nin                     => FALSE,
                           id_episode_in                 => i_episode,
                           id_episode_nin                => FALSE,
                           year_begin_in                 => l_dt_begin(1),
                           year_begin_nin                => FALSE,
                           month_begin_in                => l_dt_begin(2),
                           month_begin_nin               => FALSE,
                           day_begin_in                  => l_dt_begin(3),
                           day_begin_nin                 => FALSE,
                           id_pat_habit_in               => i_pat_habit,
                           dt_resolution_in              => NULL,
                           dt_resolution_nin             => FALSE,
                           id_habit_characterization_in  => i_id_habit_characterization,
                           id_habit_characterization_nin => FALSE,
                           rows_out                      => l_rowids_aux);
    
        IF (l_flg_status = g_flg_status_c AND l_new_status)
        THEN
        
            ts_pat_problem.upd(id_pat_problem_in    => l_pat_problem,
                               cancel_notes_in      => NULL,
                               cancel_notes_nin     => FALSE,
                               id_cancel_reason_in  => NULL,
                               id_cancel_reason_nin => FALSE,
                               rows_out             => l_rowids_aux);
        
        END IF;
    
        g_error := 'call set_register_by_me_nc';
        IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_episode,
                                                 i_pat         => i_patient,
                                                 i_id_problem  => l_pat_problem,
                                                 i_flg_type    => 'P',
                                                 i_flag_active => pk_alert_constant.g_yes,
                                                 o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROBLEM',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'call set_pat_problem_review';
        IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_pat_problem => l_pat_problem,
                                                  i_flg_source     => pk_problems.g_problem_type_habit,
                                                  i_review_notes   => NULL,
                                                  i_episode        => i_episode,
                                                  i_flg_auto       => pk_alert_constant.g_yes,
                                                  o_error          => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'SET_PAT_HABIT');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_pat_habit;

    /********************************************************************************************
    * get habit status
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param o_habit_status              Habit status
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   22-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/

    FUNCTION get_habit_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_habit_status OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DOMAIN';
        RETURN pk_sysdomain.get_values_domain(i_code_dom      => 'PAT_HABIT.FLG_STATUS',
                                              i_lang          => i_lang,
                                              o_data          => o_habit_status,
                                              i_vals_included => NULL,
                                              i_vals_excluded => table_varchar('C', 'U'));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_HABIT_STATUS');
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- close cursor
                pk_types.open_my_cursor(o_habit_status);
                -- function called by Flash layer, reseting error state
                pk_alert_exceptions.reset_error_state;
                -- return failure
                RETURN l_ret;
            END;
    END get_habit_status;

    FUNCTION set_pat_habit
    (
        i_lang                      IN language.id_language%TYPE,
        i_epis                      IN episode.id_episode%TYPE,
        i_id_patient                IN pat_habit.id_patient%TYPE,
        i_id_habit                  IN pat_habit.id_habit%TYPE,
        i_flg_status                IN pat_habit.flg_status%TYPE,
        i_prof                      IN profissional,
        i_notes                     IN pat_habit.notes%TYPE,
        i_prof_cat_type             IN category.flg_type%TYPE,
        i_dt_begin_hab              IN VARCHAR2,
        i_dt_end_hab                IN VARCHAR2,
        i_id_habit_characterization IN habit_characterization.id_habit_characterization%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere registos de hábitos do paciente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_ID_PAT_HABIT - ID do registo a actualizar. Se for um registo novo vem a nulo
             I_ID_PATIENT - ID do paciente
             I_ID_HABIT - ID do hábito
             I_FLG_STATUS - Estado do hábito. Estados possíveis:
                          A - activo, 
                       C - cancelado pelo prof., 
                       U - cancelado pelo utente 
             I_PROF - ID do profissional
             I_NOTES - Notas do profissional
             I_PROF_CAT_TYPE - Categoria do profissional
             I_DT_BEGIN_HAB - data aproximada de início do hábito. É uma 
                string com formato YYYY-MM-DD q depois é convertida 
                 I_ID_DIAGNOSIS - ID do diagnóstico  
             I_FLG_AGE - Período da vida do utente: P - perinatal, N - neonatal, 
                I - infância, E - escolar, A - adulto 
             I_FLG_APPROVED - U - relatada pelo utente, M - comprovada clinicamente 
            Saida: O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24 
          CORRECÇÕES: CRS 2005/06/25 
          NOTAS: Para já não se prevê que os registos possam ser alterados, excepto o cancelamento 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_year_begin     pat_habit.year_begin%TYPE;
        l_month_begin    pat_habit.month_begin%TYPE;
        l_day_begin      pat_habit.day_begin%TYPE;
        l_year_end       pat_habit.year_begin%TYPE;
        l_month_end      pat_habit.month_begin%TYPE;
        l_day_end        pat_habit.day_begin%TYPE;
        l_next           pat_habit.id_pat_habit%TYPE;
        l_msg            VARCHAR2(4000);
        l_rowids_1       table_varchar;
        l_id_pat_problem pat_problem.id_pat_problem%TYPE;
        -- denormalization variables
        l_rowids        table_varchar;
        l_ret           BOOLEAN;
        e_process_event EXCEPTION;
    
        e_habit_exists EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO CHECK_PAT_ALLERGY';
        IF NOT check_pat_habit(i_lang   => i_lang,
                               i_habit  => i_id_habit,
                               i_id_pat => i_id_patient,
                               o_msg    => l_msg,
                               o_error  => o_error)
        THEN
            ROLLBACK;
            --RETURN FALSE;
        END IF;
        IF l_msg IS NOT NULL
        THEN
            RAISE e_habit_exists;
            RETURN FALSE;
        END IF;
    
        g_error := 'GET BEGIN DATE';
        IF i_dt_begin_hab IS NOT NULL
        THEN
            l_year_begin  := substr(i_dt_begin_hab, 1, 4);
            l_month_begin := substr(i_dt_begin_hab, 5, 2);
            l_day_begin   := substr(i_dt_begin_hab, 7, 2);
        END IF;
    
        g_error := 'GET END DATE';
        IF i_dt_end_hab IS NOT NULL
        THEN
            l_year_end  := substr(i_dt_end_hab, 1, 4);
            l_month_end := substr(i_dt_end_hab, 5, 2);
            l_day_end   := substr(i_dt_end_hab, 7, 2);
        
        END IF;
    
        --Verifica se é um novo registo para inserir ou um registo já existente para actualizar.
        IF i_id_habit IS NOT NULL
        THEN
            --Insere novo registo 
        
            -- *********************************
            -- PT 18/09/2008 2.4.3.d
            g_error := 'GET NEXT HABIT ID';
            l_next  := ts_pat_habit.next_key();
        
            g_error := 'INSERT NEW HABIT';
            ts_pat_habit.ins(id_pat_habit_in              => l_next,
                             id_patient_in                => i_id_patient,
                             id_habit_in                  => i_id_habit,
                             dt_pat_habit_tstz_in         => g_sysdate_tstz,
                             flg_status_in                => g_pat_habit_active,
                             id_prof_writes_in            => i_prof.id,
                             notes_in                     => i_notes,
                             year_begin_in                => l_year_begin,
                             month_begin_in               => l_month_begin,
                             day_begin_in                 => l_day_begin,
                             year_end_in                  => l_year_end,
                             month_end_in                 => l_month_end,
                             day_end_in                   => l_day_end,
                             id_institution_in            => i_prof.institution,
                             id_episode_in                => i_epis,
                             id_habit_characterization_in => i_id_habit_characterization,
                             rows_out                     => l_rowids_1);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HABIT',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
            -- *********************************
            l_id_pat_problem := ts_pat_problem.next_key('SEQ_PAT_PROBLEM');
        
            g_error := 'INSERT INTO PAT_PROBLEM';
            ts_pat_problem.ins(id_pat_problem_in            => l_id_pat_problem,
                               id_patient_in                => i_id_patient,
                               id_professional_ins_in       => i_prof.id,
                               dt_pat_problem_tstz_in       => g_sysdate_tstz,
                               flg_status_in                => i_flg_status,
                               notes_in                     => i_notes,
                               year_begin_in                => l_year_begin,
                               month_begin_in               => l_month_begin,
                               day_begin_in                 => l_day_begin,
                               id_institution_in            => i_prof.institution,
                               id_habit_in                  => i_id_habit,
                               id_pat_habit_in              => l_next,
                               id_episode_in                => i_epis,
                               id_habit_characterization_in => i_id_habit_characterization,
                               rows_out                     => l_rowids);
        
            g_error := 'call set_register_by_me_nc';
            IF NOT pk_problems.set_register_by_me_nc(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_episode  => i_epis,
                                                     i_pat         => i_id_patient,
                                                     i_id_problem  => l_id_pat_problem,
                                                     i_flg_type    => 'P',
                                                     i_flag_active => pk_alert_constant.g_yes,
                                                     o_error       => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'call set_pat_problem_review';
            IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_pat_problem => l_id_pat_problem,
                                                      i_flg_source     => pk_problems.g_problem_type_habit,
                                                      i_review_notes   => NULL,
                                                      i_episode        => i_epis,
                                                      i_flg_auto       => pk_alert_constant.g_yes,
                                                      o_error          => o_error)
            THEN
                RAISE e_habit_exists;
            END IF;
        
            -- CHAMAR A FUNCAO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PROBLEM',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --Actualiza informação sobre a primeira observação      
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => NULL,
                                          i_pat                 => i_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_habit_exists THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              l_msg,
                                              l_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HABIT',
                                              'U',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HABIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        i_all          IN BOOLEAN DEFAULT FALSE,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obtém detalhe do hábito 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                            I_ID_PAT_HABIT - ID do registo a obter   
                            I_IS_REVIEW - if true include review       
               Saida:   O_HABIT - Array com os dados do hábito do paciente
                              O_NOTES - Histórico
                   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24 
          ALTERAÇÕES: CRS 2005/06/24 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *
        * UPDATED: ALERT-870
        * @author  Rui Duarte
        * @date    26-10-2009
        * @version 2.5.0.7 
        *********************************************************************************/
    
        CURSOR c_pat_probl IS
            SELECT id_pat_problem
              FROM pat_problem
             WHERE id_pat_habit = i_id_pat_habit;
    
        l_id_pat_probl pat_problem.id_pat_habit%TYPE;
    
        l_habit                     sys_message.desc_message%TYPE;
        l_start                     sys_message.desc_message%TYPE;
        l_label_status              sys_message.desc_message%TYPE;
        l_label_nature              sys_message.desc_message%TYPE;
        l_label_notes               sys_message.desc_message%TYPE;
        l_label_created             sys_message.desc_message%TYPE;
        l_label_edited              sys_message.desc_message%TYPE;
        l_label_cancelled           sys_message.desc_message%TYPE;
        l_label_review              sys_message.desc_message%TYPE;
        l_label_review_desc         sys_message.desc_message%TYPE;
        l_label_cancellation_reason sys_message.desc_message%TYPE;
        l_label_cancellation_notes  sys_message.desc_message%TYPE;
        l_label_characterization    sys_message.desc_message%TYPE;
    
        l_fst_dt_order VARCHAR2(200);
        l_all          PLS_INTEGER;
    
    BEGIN
    
        l_habit             := pk_message.get_message(i_lang, 'PATIENT_HABITS_T005');
        l_start             := pk_message.get_message(i_lang, 'PATIENT_HABITS_T006');
        l_label_status      := pk_message.get_message(i_lang, 'PATIENT_HABITS_T004');
        l_label_nature      := pk_message.get_message(i_lang, 'PATIENT_HABITS_T013');
        l_label_notes       := pk_message.get_message(i_lang, 'PATIENT_HABITS_T007');
        l_label_created     := pk_message.get_message(i_lang, 'DETAIL_COMMON_M001');
        l_label_edited      := pk_message.get_message(i_lang, 'DETAIL_COMMON_M002');
        l_label_cancelled   := pk_message.get_message(i_lang, 'DETAIL_COMMON_M003');
        l_label_review      := pk_message.get_message(i_lang, 'DETAIL_COMMON_M004');
        l_label_review_desc := pk_message.get_message(i_lang, 'DETAIL_COMMON_M005');
        --pk_message.get_message(i_lang, 'DETAIL_COMMON_M005');
        l_label_cancellation_reason := pk_message.get_message(i_lang, 'DETAIL_COMMON_M006');
        l_label_cancellation_notes  := pk_message.get_message(i_lang, 'DETAIL_COMMON_M007');
        l_label_characterization    := pk_message.get_message(i_lang, 'HABIT_CARACTERIZATION_M001');
    
        OPEN c_pat_probl;
        FETCH c_pat_probl
            INTO l_id_pat_probl;
    
        --get habit first record date (oldest)
        SELECT MIN(dt_order)
          INTO l_fst_dt_order
          FROM (SELECT pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order
                  FROM pat_problem pp, professional p
                 WHERE pp.id_pat_problem = l_id_pat_probl
                   AND pp.id_professional_ins = p.id_professional
                UNION ALL
                SELECT pk_date_utils.date_send_tsz(i_lang, pph.dt_pat_problem_tstz, i_prof) dt_order
                  FROM pat_problem_hist pph, professional p
                 WHERE pph.id_pat_problem = l_id_pat_probl
                   AND pph.id_professional_ins = p.id_professional);
    
        g_habit_review_area := pk_review.get_habits_context();
    
        l_all := sys.diutil.bool_to_int(i_all);
    
        g_error := 'GET O_HABIT_DETAIL';
        OPEN o_habit_detail FOR
        
            SELECT decode(pp.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_label_cancelled,
                          decode(pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof),
                                 l_fst_dt_order,
                                 l_label_created,
                                 l_label_edited)) desc_edit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_reg,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    p.id_professional,
                                                    pp.dt_pat_problem_tstz,
                                                    pp.id_episode) prof_spec_reg,
                   l_habit desc_habit,
                   pk_translation.get_translation(i_lang, h.code_habit) habit,
                   l_label_status desc_status,
                   pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', pp.flg_status, i_lang) status,
                   l_label_nature desc_nature,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp.flg_nature, i_lang) nature,
                   l_start desc_dt_start,
                   decode(pp.year_begin,
                          '',
                          '',
                          decode(pp.month_begin,
                                 '',
                                 to_char(pp.year_begin),
                                 decode(pp.day_begin,
                                        '',
                                        substr(to_char(to_date(pp.year_begin || lpad(pp.month_begin, 2, '0'), 'YYYYMM'),
                                                       'DD-Mon-YYYY'),
                                               4),
                                        pk_date_utils.dt_chr(i_lang,
                                                             to_date(pp.year_begin || lpad(pp.month_begin, 2, '0') ||
                                                                     lpad(pp.day_begin, 2, '0'),
                                                                     'YYYYMMDD'),
                                                             i_prof)))) dt_start,
                   l_label_notes desc_notes,
                   pp.notes notes,
                   l_label_cancellation_reason desc_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = pp.id_cancel_reason) cancel_reason,
                   l_label_cancellation_notes desc_cancel_notes,
                   decode(pp.flg_status, g_pat_habit_canc, pp.cancel_notes, '') cancel_notes,
                   pk_alert_constant.g_no flg_review,
                   NULL review,
                   pp.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order,
                   pk_translation.get_translation(i_lang, hc.code_habit_characterization) habit_characterization,
                   l_label_characterization desc_habit_characterization,
                   ph.id_habit id_habit,
                   hc.id_habit_characterization,
                   2 rank
              FROM pat_problem_hist pp, professional p, pat_habit ph, habit h, habit_characterization hc
             WHERE pp.id_pat_problem = l_id_pat_probl
               AND pp.id_professional_ins = p.id_professional
               AND ph.id_habit = h.id_habit
               AND ph.id_pat_habit = i_id_pat_habit
               AND pp.id_habit_characterization = hc.id_habit_characterization(+)
               AND l_all > 0
            UNION ALL
            SELECT decode(pp1.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_label_cancelled,
                          decode(pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof),
                                 l_fst_dt_order,
                                 l_label_created,
                                 l_label_edited)) desc_edit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_reg,
                   pk_date_utils.date_char_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    p1.id_professional,
                                                    pp1.dt_pat_problem_tstz,
                                                    pp1.id_episode) prof_spec_reg,
                   l_habit desc_habit,
                   pk_translation.get_translation(i_lang, h.code_habit) habit,
                   l_label_status desc_status,
                   pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', pp1.flg_status, i_lang) status,
                   l_label_nature desc_nature,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE', pp1.flg_nature, i_lang) nature,
                   l_start desc_dt_start,
                   decode(pp1.year_begin,
                          '',
                          '',
                          decode(pp1.month_begin,
                                 '',
                                 to_char(pp1.year_begin),
                                 decode(pp1.day_begin,
                                        '',
                                        substr(to_char(to_date(pp1.year_begin || lpad(pp1.month_begin, 2, '0'), 'YYYYMM'),
                                                       'DD-Mon-YYYY'),
                                               4),
                                        pk_date_utils.dt_chr(i_lang,
                                                             to_date(pp1.year_begin || lpad(pp1.month_begin, 2, '0') ||
                                                                     lpad(pp1.day_begin, 2, '0'),
                                                                     'YYYYMMDD'),
                                                             i_prof)))) dt_start,
                   l_label_notes desc_notes,
                   pp1.notes notes,
                   l_label_cancellation_reason desc_cancel_reason,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = pp1.id_cancel_reason) cancel_reason,
                   l_label_cancellation_notes desc_cancel_notes,
                   decode(pp1.flg_status, g_pat_habit_canc, nvl(ph.cancel_notes, pp1.cancel_notes)) cancel_notes,
                   pk_alert_constant.g_no flg_review,
                   NULL review_desc,
                   pp1.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, pp1.dt_pat_problem_tstz, i_prof) dt_order,
                   pk_translation.get_translation(i_lang, hc.code_habit_characterization) habit_characterization,
                   l_label_characterization desc_habit_characterization,
                   ph.id_habit id_habit,
                   hc.id_habit_characterization,
                   2 rank
              FROM pat_problem pp1, professional p1, pat_habit ph, habit h, habit_characterization hc
             WHERE pp1.id_pat_problem = l_id_pat_probl
               AND pp1.id_professional_ins = p1.id_professional
               AND ph.id_habit = h.id_habit
               AND ph.id_pat_habit = i_id_pat_habit
               AND pp1.id_habit_characterization = hc.id_habit_characterization(+)
            UNION ALL
            SELECT l_label_review desc_edit,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) prof_reg,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, ph.id_episode) prof_spec_reg,
                   NULL desc_habit,
                   NULL habit,
                   NULL desc_status,
                   NULL status,
                   NULL desc_nature,
                   NULL nature,
                   NULL desc_dt_start,
                   NULL dt_start,
                   l_label_notes desc_review_notes,
                   rd.review_notes review_notes,
                   NULL desc_cancel_reason,
                   NULL cancel_reason,
                   NULL desc_cancel_notes,
                   NULL cancel_notes,
                   pk_alert_constant.g_yes flg_review,
                   l_label_review_desc review,
                   NULL flg_status,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_order,
                   NULL habit_characterization,
                   NULL desc_habit_characterization,
                   NULL id_habit,
                   NULL id_habit_characterization,
                   1 rank
              FROM review_detail rd
              JOIN pat_habit ph
                ON ph.id_pat_habit = rd.id_record_area
             WHERE rd.id_record_area = i_id_pat_habit
               AND rd.flg_context = g_habit_review_area
               AND l_all > 0
             ORDER BY dt_order DESC, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HABIT',
                                              o_error);
        
            pk_types.open_my_cursor(o_habit_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_habit;

    /******************************************************************************************** 
    * get patient habits
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_id_pat_habit      Patient habit id
    * @param IN   i_prof              Professional Type
    * @param OUT  o_habit_detail      Habits array 
    * @param OUT  o_error             Error structure
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.5
    * @since    2009-Dec-09
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'GET O_HABIT_DETAIL';
    
        IF NOT get_pat_habit(i_lang         => i_lang,
                             i_id_pat_habit => i_id_pat_habit,
                             i_prof         => i_prof,
                             i_all          => TRUE,
                             o_habit_detail => o_habit_detail,
                             o_error        => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HABIT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pat_habit;

    /******************************************************************************************** 
    * get habit date begin last update or insert
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_pat_habit         Habit ID
    * @param IN   i_id_pat            Patient id
    * @param IN   i_prof              Professional Type
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.7
    * @since    2009-Feb-22
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_dt_begin_last_update
    (
        i_lang      IN language.id_language%TYPE,
        i_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_id_pat    IN pat_habit.id_patient%TYPE,
        i_prof      IN profissional
    ) RETURN VARCHAR2 IS
    
        l_dt_begin VARCHAR2(50);
    
    BEGIN
    
        SELECT decode(reg.year_begin,
                      '',
                      '',
                      decode(reg.month_begin,
                             '',
                             to_char(reg.year_begin),
                             decode(reg.day_begin,
                                    '',
                                    pk_date_utils.get_month_year(i_lang,
                                                                 i_prof,
                                                                 to_date(reg.year_begin || lpad(reg.month_begin, 2, '0'),
                                                                         'YYYYMM')),
                                    pk_date_utils.dt_chr(i_lang,
                                                         to_date(reg.year_begin || lpad(reg.month_begin, 2, '0') ||
                                                                 lpad(reg.day_begin, 2, '0'),
                                                                 'YYYYMMDD'),
                                                         i_prof)))) dt_begin
          INTO l_dt_begin
          FROM (SELECT pp.year_begin, pp.month_begin, pp.day_begin, pp.dt_pat_problem_tstz
                  FROM pat_problem pp
                 WHERE pp.id_patient = i_id_pat
                   AND pp.id_pat_habit = i_pat_habit) reg
         WHERE rownum = 1;
    
        RETURN l_dt_begin;
    
    END get_dt_begin_last_update;

    /******************************************************************************************** 
    * get habit date begin last update or insert (YYYY-MM-DAY format)
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_pat_habit         Habit ID
    * @param IN   i_id_pat            Patient id
    * @param IN   i_prof              Professional Type
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.7
    * @since    2009-Feb-22
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_dt_begin_to_flash
    (
        i_lang      IN language.id_language%TYPE,
        i_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_id_pat    IN pat_habit.id_patient%TYPE,
        i_prof      IN profissional
    ) RETURN VARCHAR2 IS
    
        l_dt_begin VARCHAR2(12);
    
    BEGIN
    
        SELECT reg.year_begin || lpad(reg.month_begin, 2, '0') || lpad(reg.day_begin, 2, '0') dt_begin_to_flash
          INTO l_dt_begin
          FROM (SELECT pp.year_begin, pp.month_begin, pp.day_begin, pp.dt_pat_problem_tstz
                  FROM pat_problem pp
                 WHERE pp.id_patient = i_id_pat
                   AND pp.id_pat_habit = i_pat_habit) reg
         WHERE rownum = 1;
    
        RETURN l_dt_begin;
    
    END get_dt_begin_to_flash;

    FUNCTION get_all_habit
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN pat_habit.id_patient%TYPE,
        i_prof   IN profissional,
        o_habit  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obtém hábitos do doente  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente          
               Saida:   O_HABIT - Array de hábitos 
                  O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/06/24 
          NOTAS: 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_habit FOR
            SELECT p.id_pat_habit,
                   p.flg_status flg_status,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional)
                      FROM dual) prof_write,
                   (SELECT pk_translation.get_translation(i_lang, h.code_habit)
                      FROM dual) desc_habit,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang, p.dt_pat_habit_tstz, i_prof)
                      FROM dual) date_target,
                   (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                            p.dt_pat_habit_tstz,
                                                            i_prof.institution,
                                                            i_prof.software)
                      FROM dual) hour_target,
                   (SELECT pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', p.flg_status, i_lang)
                      FROM dual) desc_status,
                   decode(p.notes,
                          '',
                          decode(p.note_cancel, '', '', pk_message.get_message(i_lang, 'COMMON_M097')),
                          pk_message.get_message(i_lang, 'COMMON_M097')) title_notes,
                   nvl(p.note_cancel, p.notes) notes,
                   decode(p.flg_status, g_pat_habit_canc, 'Y', 'N') flg_cancel,
                   (SELECT pk_date_utils.to_char_insttimezone(i_prof, p.dt_pat_habit_tstz, 'YYYYMMDDHH24MISS')
                      FROM dual) dt_ord1,
                   (SELECT get_dt_begin_last_update(i_lang, p.id_pat_habit, i_id_pat, i_prof)
                      FROM dual) dt_begin,
                   (SELECT get_dt_begin_to_flash(i_lang, p.id_pat_habit, i_id_pat, i_prof)
                      FROM dual) dt_begin_to_flash,
                   hcr.id_habit_characterization id_characterization,
                   h.id_content,
                   (SELECT pk_translation.get_translation(i_lang, hc.code_habit_characterization)
                      FROM dual) desc_characterization
              FROM pat_habit p
              JOIN habit h
                ON h.id_habit = p.id_habit
              JOIN professional pf
                ON pf.id_professional = p.id_prof_writes
              LEFT JOIN habit_charact_relation hcr
                ON p.id_habit_characterization = hcr.id_habit_characterization
               AND h.id_habit = hcr.id_habit
              LEFT JOIN habit_characterization hc
                ON hc.id_habit_characterization = hcr.id_habit_characterization
             WHERE p.id_patient = i_id_pat
             ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_HABIT.FLG_STATUS', p.flg_status), p.dt_pat_habit_tstz DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_HABIT',
                                              o_error);
            pk_types.open_my_cursor(o_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_habit;

    FUNCTION cancel_pat_habit
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_habit  IN pat_habit.id_pat_habit%TYPE,
        i_prof          IN profissional,
        i_notes         IN pat_habit.note_cancel%TYPE,
        i_cancel_reason IN pat_habit.id_cancel_reason%TYPE DEFAULT NULL,
        i_dt_hab_end    IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancela hábito do paciente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                            I_ID_PAT_HABIT - ID do hábito a cancelar  
                  I_PROF - ID do profissional
                  I_NOTES - Notas de cancelamento
                  I_DT_HAB_END - Data de fim do hábito. Pode estar a nulo.
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_flg_status pat_habit.flg_status%TYPE;
        l_year_end   pat_habit.year_begin%TYPE;
        l_month_end  pat_habit.month_begin%TYPE;
        l_day_end    pat_habit.day_begin%TYPE;
        l_pat        pat_habit.id_patient%TYPE;
        l_habit      pat_habit.id_habit%TYPE;
        l_probl      pat_problem.id_pat_problem%TYPE;
        l_flg_show   VARCHAR2(2000);
        l_msg_title  VARCHAR2(2000);
        l_msg_text   VARCHAR2(2000);
        l_button     VARCHAR2(2000);
        --
        l_id_episode pat_habit.id_episode%TYPE;
    
        CURSOR c_habit IS
            SELECT flg_status, id_patient, id_habit, id_episode
              FROM pat_habit
             WHERE id_pat_habit = i_id_pat_habit
               AND flg_status != g_pat_habit_canc;
    
        CURSOR c_probl IS
            SELECT id_pat_problem
              FROM pat_problem
             WHERE id_pat_habit = i_id_pat_habit;
    
        l_ret BOOLEAN;
    
        l_rowids_upd table_varchar;
        e_notfound   EXCEPTION;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --Verifica qual o estado do hábito. Se já estiver cancelado, não o pode ser novamente
        OPEN c_habit;
        FETCH c_habit
            INTO l_flg_status, l_pat, l_habit, l_id_episode;
        g_found := c_habit%FOUND;
        CLOSE c_habit;
    
        IF NOT g_found
        THEN
            --Não foi encontrado o hábito a cancelar. Ou não existe ou já foi cancelado
            RAISE e_notfound;
        END IF;
    
        IF i_dt_hab_end IS NOT NULL
        THEN
            l_year_end  := to_number(substr(i_dt_hab_end, 1, instr(i_dt_hab_end, '-') - 1));
            l_month_end := to_number(substr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1),
                                            1,
                                            instr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1), '-') - 1));
            l_day_end   := to_number(substr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1),
                                            instr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1), '-') + 1));
        END IF;
        IF i_dt_hab_end IS NOT NULL
        THEN
            IF instr(i_dt_hab_end, '-') = 0
            THEN
                l_year_end := i_dt_hab_end;
            ELSE
                l_year_end := to_number(substr(i_dt_hab_end, 1, instr(i_dt_hab_end, '-') - 1));
            
                IF instr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1), '-') = 0
                THEN
                    l_month_end := substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1);
                ELSE
                    l_month_end := to_number(substr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1),
                                                    1,
                                                    instr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1), '-') - 1));
                    l_day_end   := to_number(substr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1),
                                                    instr(substr(i_dt_hab_end, instr(i_dt_hab_end, '-') + 1), '-') + 1));
                END IF;
            END IF;
        END IF;
    
        --actualiza o hábito com a informação do cancelamento
        g_error := 'CANCEL HABIT';
        -- *********************************
        -- PT 10/10/2008 2.4.3.d
        ts_pat_habit.upd(id_pat_habit_in     => i_id_pat_habit,
                         dt_cancel_tstz_in   => g_sysdate_tstz,
                         id_prof_cancel_in   => i_prof.id,
                         note_cancel_in      => i_notes, -- What's the difference ???
                         cancel_notes_in     => i_notes, -- What's the difference ???
                         year_end_in         => l_year_end,
                         month_end_in        => l_month_end,
                         day_end_in          => l_day_end,
                         flg_status_in       => g_pat_habit_canc,
                         id_cancel_reason_in => i_cancel_reason,
                         rows_out            => l_rowids_upd);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HABIT',
                                      i_rowids     => l_rowids_upd,
                                      o_error      => o_error);
        -- *********************************
        /*UPDATE pat_habit
          SET dt_cancel_tstz = g_sysdate_tstz,
              id_prof_cancel = i_prof.id,
              note_cancel    = i_notes,
              year_end       = l_year_end,
              month_end      = l_month_end,
              day_end        = l_day_end,
              flg_status     = g_pat_habit_canc
        WHERE id_pat_habit = i_id_pat_habit;*/
    
        OPEN c_probl;
        FETCH c_probl
            INTO l_probl;
        CLOSE c_probl;
    
        IF NOT pk_patient.set_pat_problem(i_lang          => i_lang,
                                          i_epis          => NULL,
                                          i_pat           => l_pat,
                                          i_pat_problem   => l_probl,
                                          i_prof          => i_prof,
                                          i_diag          => NULL,
                                          i_desc          => NULL,
                                          i_notes         => NULL,
                                          i_age           => NULL,
                                          i_dt_symptoms   => NULL,
                                          i_flg_approved  => NULL,
                                          i_pct           => NULL,
                                          i_surgery       => NULL,
                                          i_notes_support => NULL,
                                          i_dt_confirm    => NULL,
                                          i_rank          => NULL,
                                          i_status        => g_pat_habit_canc,
                                          i_epis_diag     => NULL,
                                          i_prof_cat_type => NULL,
                                          i_notes_cancel  => i_notes,
                                          i_cancel_reason => i_cancel_reason,
                                          o_flg_show      => l_flg_show,
                                          o_msg_title     => l_msg_title,
                                          o_msg_text      => l_msg_text,
                                          o_button        => l_button,
                                          o_error         => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => l_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_notfound THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PATIENT_M006',
                                              pk_message.get_message(i_lang, 'PATIENT_M006'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_HABIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_HABIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_fam_soc_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_patient    IN pat_fam_soc_hist.id_patient%TYPE,
        i_flg_type      IN pat_fam_soc_hist.flg_type%TYPE,
        i_notes         IN pat_fam_soc_hist.notes%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere registos de história familiar e social do paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PATIENT - ID do paciente
                  I_FLG_TYPE - Tipo: F - história familiar; 
                                     S - hist. social
                  I_NOTES - Notas do profissional
                  I_PROF - ID do profissional
                  I_PROF_CAT_TYPE - Categoria do profissional
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24
          NOTAS: Para já não se prevê que os registos possam ser alterados, excepto o cancelamento 
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Insere registo
        g_error := 'INSERT PAT_FAM_SOC_HIST';
        INSERT INTO pat_fam_soc_hist
            (id_pat_fam_soc_hist,
             dt_pat_fam_soc_hist_tstz,
             id_patient,
             id_pat_family,
             flg_type,
             flg_status,
             notes,
             id_prof_write,
             id_institution,
             id_episode)
        VALUES
            (seq_pat_fam_soc_hist.nextval,
             g_sysdate_tstz,
             i_id_patient,
             NULL,
             i_flg_type,
             g_pat_fam_soc_hist_act,
             i_notes,
             i_prof.id,
             i_prof.institution,
             i_epis);
    
        --Actualiza informação sobre a primeira observação      
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_FAM_SOC_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION cancel_pat_fam_soc_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat_fam_soc_hist IN pat_fam_soc_hist.id_pat_fam_soc_hist%TYPE,
        i_prof                IN profissional,
        i_notes               IN pat_fam_soc_hist.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancela registos de história familiar e social do paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                            I_ID_PAT_HABIT - ID do hábito a cancelar  
                  I_PROF - ID do profissional
                  I_NOTES - Notas de cancelamento
                  I_DT_HAB_END - Data de fim do hábito. Pode estar a nulo.
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5
        *********************************************************************************/
        l_flg_status pat_fam_soc_hist.flg_status%TYPE;
        l_pat        pat_fam_soc_hist.id_patient%TYPE;
    
        CURSOR c_hist IS
            SELECT flg_status, id_patient
              FROM pat_fam_soc_hist
             WHERE id_pat_fam_soc_hist = i_id_pat_fam_soc_hist
               AND flg_status != g_pat_fam_soc_hist_canc;
    
        e_notfound EXCEPTION;
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --verifica qual o estado do registo. Se já está cancelado não o vai ser novamente
        g_error := 'GET CURSOR';
        OPEN c_hist;
        FETCH c_hist
            INTO l_flg_status, l_pat;
        g_found := c_hist%FOUND;
        CLOSE c_hist;
    
        IF NOT g_found
        THEN
            --Não foi encontrado o registo a cancelar. Ou não existe ou já foi cancelado
            RAISE e_notfound;
        
        END IF;
    
        --Cancela o registo
        UPDATE pat_fam_soc_hist
           SET flg_status     = g_pat_fam_soc_hist_canc,
               dt_cancel_tstz = g_sysdate_tstz,
               id_prof_cancel = i_prof.id,
               notes_cancel   = i_notes
         WHERE id_pat_fam_soc_hist = i_id_pat_fam_soc_hist;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => l_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_notfound THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PATIENT_M007',
                                              pk_message.get_message(i_lang, 'PATIENT_M007'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_FAM_SOC_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_FAM_SOC_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_pat_fam_soc_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_fam_soc_hist.id_patient%TYPE,
        i_type    IN pat_fam_soc_hist.flg_type%TYPE,
        i_prof    IN profissional,
        o_pat_fam OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obtém informação relativa à história familiar ou social do paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_ID_PAT - ID do doente 
               I_TYPE - F - história familiar; S - hist. social 
               Saida:   O_PAT_FAM - registos de história familiar ou social 
               O_ERROR - erro 
         
          CRIAÇÃO: RB 2005/05/24 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *********************************************************************************/
        l_aux pat_notes.id_patient%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT DISTINCT id_patient
              INTO l_aux
              FROM pat_fam_soc_hist
             WHERE id_patient = i_id_pat
               AND flg_type = i_type;
        
            g_error := 'GET CURSOR1';
            OPEN o_pat_fam FOR
                SELECT 'R' reg,
                       p.id_pat_fam_soc_hist,
                       p.flg_type,
                       p.flg_status,
                       p.notes,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   p.dt_pat_fam_soc_hist_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_pat_fam_soc_hist,
                       pk_sysdomain.get_domain('PAT_FAM_SOC_HIST.FLG_TYPE', p.flg_type, i_lang) desc_type,
                       pk_sysdomain.get_domain('PAT_FAM_SOC_HIST.FLG_STATUS', p.flg_status, i_lang) desc_status,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional) prof_write,
                       pk_date_utils.date_char_tsz(i_lang, p.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) prof_cancel,
                       p.notes_cancel,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, pf.id_professional, NULL, NULL) desc_spec
                  FROM pat_fam_soc_hist p, professional pf, professional pc, speciality s
                 WHERE p.id_patient = i_id_pat
                   AND p.flg_type = i_type
                   AND pf.id_professional = p.id_prof_write
                   AND pc.id_professional(+) = p.id_prof_cancel
                   AND s.id_speciality(+) = pf.id_speciality
                 ORDER BY p.dt_pat_fam_soc_hist_tstz DESC;
        
        EXCEPTION
            WHEN no_data_found THEN
            
                g_error := 'GET CURSOR2';
                OPEN o_pat_fam FOR
                    SELECT 'N' reg,
                           NULL id_pat_fam_soc_hist,
                           NULL flg_type,
                           NULL flg_status,
                           pk_message.get_message(i_lang, 'COMMON_M007') notes,
                           NULL dt_pat_fam_soc_hist,
                           NULL desc_type,
                           NULL desc_status,
                           NULL prof_write,
                           NULL dt_cancel,
                           NULL prof_cancel,
                           NULL notes_cancel,
                           NULL desc_spec
                      FROM dual;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_FAM_SOC_HIST',
                                              o_error);
            pk_types.open_my_cursor(o_pat_fam);
            RETURN FALSE;
    END;

    FUNCTION find_ine_location_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_zip_code     IN VARCHAR2,
        o_ine_location OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   definir o código INE em função do código postal 
           PARAMETROS:  Entrada:   I_LANG - língua registada como preferencial do profissional
                I_PROF - profissional que regista,
               I_ZIP_CODE - código postal,
                                   O_INE_LOCATION - código de localização do INE 
               O_ERROR - erro 
           
          CRIAÇÃO: LG 2006/09/01 
          NOTAS:
        *
        * UPDATED: ALERT-19390
        * @author  Telmo Castro
        * @date    10-03-2009
        * @version 2.5 
        *********************************************************************************/
        CURSOR count_ine_code IS
            SELECT COUNT(*)
              FROM ine_location
             WHERE zip_code = to_number(substr(i_zip_code, 1, 4));
    
        CURSOR ine_code IS
            SELECT ine_freguesia
              FROM ine_location
             WHERE zip_code = to_number(substr(i_zip_code, 1, 4));
    
        l_code  ine_location.ine_freguesia%TYPE;
        l_count NUMBER;
    
    BEGIN
    
        --SS 2006/08/02: codificação do INE para distrito/concelho/freguesia (necessário para a prescrição - ficheiro XML)
        g_error := 'GET CURSOR COUNT_INE_CODE'; -- nº de freguesias com o cod.postal
        OPEN count_ine_code;
        FETCH count_ine_code
            INTO l_count;
        CLOSE count_ine_code;
    
        g_error := 'GET CURSOR INE_CODE';
        OPEN ine_code;
        FETCH ine_code
            INTO l_code;
        CLOSE ine_code;
    
        IF l_count != 1
        THEN
            -- se há mais do que uma freguesia com aquele código postal, guarda o código do concelho
            l_code := substr(l_code, 1, 4);
        END IF;
    
        o_ine_location := l_code;
        RETURN TRUE;
    
        -- LG 2006-08-31 CHECK IF I_ZIP_CODE IS NUMERIC. 
    EXCEPTION
        WHEN invalid_number THEN
            o_ine_location := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'FIND_INE_LOCATION_INTERNAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END find_ine_location_internal;

    /**
    * Creates CLIN_RECORD record.
    * This function is not to becalled directly from flash.
    * It is for database internal use. 
    * 
    * @param   I_LANG the user language id.
    * @param   I_PROF Professional 
    * @param   I_CLIN_RECORD the clin_record to insert.
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   23-10-2006
    *  
    * @author  Pedro Santos
    * @version 2.4.3-Denormalized
    * @since   2008/09/30
    * reason added column id_episode to table clin_record
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */
    FUNCTION create_clin_record
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_clin_record_row IN OUT clin_record%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids         table_varchar;
        l_id_clin_record clin_record.id_clin_record%TYPE;
    BEGIN
        -- set id_clin_record
        IF (i_clin_record_row.id_clin_record IS NULL)
        THEN
            g_error                          := 'GET ID_CLIN_RECORD';
            l_id_clin_record                 := ts_clin_record.next_key();
            i_clin_record_row.id_clin_record := l_id_clin_record;
        END IF;
        -- set flg_status
        IF (i_clin_record_row.flg_status IS NULL)
        THEN
            g_error                      := 'SET FLAG VALUE';
            i_clin_record_row.flg_status := g_clin_rec_active;
        
        END IF;
        -- set id_institution_enroled
        IF (i_clin_record_row.id_instit_enroled IS NULL)
        THEN
            g_error                             := 'SET INSTIT ENROLED';
            i_clin_record_row.id_instit_enroled := i_clin_record_row.id_institution;
        END IF;
    
        g_error := 'INSERT CLIN_RECORD';
        ts_clin_record.ins(rec_in => i_clin_record_row, rows_out => l_rowids);
    
        g_error := 'ACTUALIZA T_DATA_GOV_MNT-CLIN_RECORD';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CLIN_RECORD',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_CLIN_RECORD',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_clin_record;

    /**
    * Updates a CLIN_RECORD record.
    * This function is not to becalled directly from flash.
    * It is for database internal use. 
    *
    * @param   I_LANG the user language id.
    * @param   I_CLIN_RECORD the clin_record to insert.
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   23-10-2006 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */
    FUNCTION update_clin_record
    (
        i_lang            IN language.id_language%TYPE,
        i_clin_record_row IN OUT clin_record%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE CLIN_RECORD';
        UPDATE clin_record
           SET ROW = i_clin_record_row
         WHERE id_clin_record = i_clin_record_row.id_clin_record;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_CLIN_RECORD',
                                              o_error);
            pk_utils.undo_changes;
    END update_clin_record;

    /**
    * Creates a patient.
    * The index array is used to relate I_KEYS with I_VALUES.
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param   I_CONTEXT context identifing the screen template,
    * @param   I_KEYS array with keys about which info is available to create the patient. A key must respect the <TABLE>.<COLUMN> format to identifie the value.  
    * @param   I_VALUES array with which info is available to create the patient
    * @param   I_PROF_CAT_TYPE the professional category
    * @param   O_ID_PATIENT The new patient id 
    * @param   I_EPIS Episode id   
    * @param   O_FLG_SHOW  =Y to show a message, otherwise = N 
    * @param   O_MSG_TITLE  the message title, when O_FLG_SHOW = Y 
    * @param   O_MSG_TEXT  the message text , when O_FLG_SHOW = Y
    * @param   O_BUTTON the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed   
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   19-10-2006
    *
    * @author  Pedro Santos
    * @version 2.4.3-Denormalized
    * @since   2008/10/02 
    * reason: added i_epis
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */
    FUNCTION create_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_context        IN screen_template.context%TYPE,
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_btn            IN sys_button_prop.id_sys_button_prop%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_id_patient     OUT patient.id_patient%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- local types
        TYPE varchar_hashtable IS TABLE OF VARCHAR(4000) INDEX BY VARCHAR(200);
        TYPE boolean_hashtable IS TABLE OF BOOLEAN INDEX BY VARCHAR(200);
        -- local variables
        -- metadata variables
        l_plsql_blocks      varchar_hashtable;
        l_plsql_block       VARCHAR2(4000);
        l_has_tables_values boolean_hashtable;
        l_has_table_values  BOOLEAN;
    
        internal_exception         EXCEPTION;
        l_key                      VARCHAR2(4000);
        l_table_name               VARCHAR2(200);
        l_column_name              VARCHAR(200);
        l_point_separator_position NUMBER;
        l_convertion_exp           VARCHAR2(4000);
        l_screen_metadata          pk_screen_template_internal.screen_metadata_type;
        l_pat_dmgr_hist_row        pat_dmgr_hist%ROWTYPE;
        l_create_dmgr_hist_bool    BOOLEAN;
        l_pat_dmgr_hist_seq_number NUMBER;
        l_count                    PLS_INTEGER;
        l_rowids                   table_varchar;
        -- PATIENT TABLE
        -- PAT_SOC_ATTRIBUTES TABLE
        l_ine_location pat_soc_attributes.ine_location%TYPE;
        -- PAT_JOB TABLE
        --PAT_CLI_ATTRIBUTES TABLE
        --CLIN_RECORD TABLE 
        --PAT_HEALTH_PLAN 
        l_id_health_plans   table_number;
        l_num_health_plans  table_varchar;
        l_desc_health_plans table_varchar;
        l_dt_health_plans   table_varchar;
        l_flg_defaults      table_varchar;
        l_default_epis      table_varchar;
        l_barcodes          table_varchar;
    
        --DOC_EXTERNAL      
        l_id_doc_external doc_external.id_doc_external%TYPE;
    
        l_count_ttl  PLS_INTEGER;
        l_count_inst PLS_INTEGER;
        --health plan default content id
        l_id_cnt_hp     health_plan.id_content%TYPE;
        l_id_default_hp health_plan.id_health_plan%TYPE;
        -- CHANGES START 
        -- TODO: ADD FOLLOWING COLUMNS IN TABLES 
        --I_ID_DOC_TYPE IN PAT_DOC.ID_DOC_TYPE%TYPE,
        --I_VALUE IN PAT_DOC.VALUE%TYPE,
        --I_FAMILY_DOCTOR IN VARCHAR2, -- PAT_SOC_ATTRIBUTES.CONTACT_NUMBER_4
    
    BEGIN
        -- TODO: try to avoid patient duplicate creation checking patient name, last name, middle name, date of birth, default document, default health plan
        -- initialize variables 
        g_patient_row            := NULL;
        g_pat_soc_attributes_row := NULL;
        g_pat_job_row            := NULL;
        g_pat_cli_attributes_row := NULL;
        g_clin_record_row        := NULL;
        g_doc_external_row       := NULL;
        -- hastable to plsql blocks 
        l_plsql_blocks('PATIENT') := ' ';
        l_plsql_blocks('PAT_SOC_ATTRIBUTES') := ' ';
        l_plsql_blocks('PAT_JOB') := ' ';
        l_plsql_blocks('PAT_CLI_ATTRIBUTES') := ' ';
        l_plsql_blocks('CLIN_RECORD') := ' ';
        l_plsql_blocks('PAT_HEALTH_PLAN') := ' ';
        l_plsql_blocks('DOC_EXTERNAL') := ' ';
        -- hashtable to tables with values to set 
        l_has_tables_values('PATIENT') := FALSE;
        l_has_tables_values('PAT_SOC_ATTRIBUTES') := FALSE;
        l_has_tables_values('PAT_JOB') := FALSE;
        l_has_tables_values('PAT_CLI_ATTRIBUTES') := FALSE;
        l_has_tables_values('CLIN_RECORD') := FALSE;
        l_has_tables_values('PAT_HEALTH_PLAN') := FALSE;
        l_has_tables_values('DOC_EXTERNAL') := FALSE;
    
        -- get template metadata
        g_error := 'GET SCREEN_TEMPLATE_METADATA';
        IF (NOT pk_screen_template_internal.get_screen_template_metadata(i_lang,
                                                                         i_prof,
                                                                         i_context,
                                                                         l_screen_metadata,
                                                                         o_error))
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- validate mandatory fields
        IF (NOT pk_screen_template_internal.validate_screen_fields(i_lang,
                                                                   i_prof,
                                                                   l_screen_metadata,
                                                                   i_keys,
                                                                   i_values,
                                                                   o_flg_show,
                                                                   o_msg_text,
                                                                   o_msg_title,
                                                                   o_button,
                                                                   o_error))
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- bind values from input to local variables
        g_error := 'BUILD SQLS - PHASE 1';
        FOR i IN 1 .. i_keys.count
        LOOP
            -- Loop sobre o array de chaves
            l_key                      := i_keys(i);
            l_point_separator_position := instr(l_key, '.');
            l_table_name               := upper(substr(l_key, 1, l_point_separator_position - 1)); -- calc table name
            l_column_name              := upper(substr(l_key, l_point_separator_position + 1)); -- calc column name
            -- as we are inserting, null values are not relevant, and readOnly values are to be inserted, so no check on read-only values is done  
            IF (i_values(i) IS NOT NULL)
            THEN
                SELECT COUNT(0)
                  INTO l_count
                  FROM user_tables t, user_tab_columns c
                 WHERE t.table_name = c.table_name
                   AND t.table_name = l_table_name
                   AND t.temporary = 'N'
                   AND c.column_name = l_column_name;
            
                IF l_count > 0
                   AND (l_table_name IN ('PATIENT',
                                         'PAT_SOC_ATTRIBUTES',
                                         'PAT_JOB',
                                         'PAT_CLI_ATTRIBUTES',
                                         'CLIN_RECORD',
                                         'PAT_HEALTH_PLAN',
                                         'DOC_EXTERNAL'))
                THEN
                    l_has_tables_values(l_table_name) := TRUE;
                    -- generate pl/sql dynamic code 
                    IF (NOT pk_screen_template_internal.varchar_to_data_type(i_values(i),
                                                                             l_screen_metadata,
                                                                             l_key,
                                                                             i_lang,
                                                                             l_convertion_exp,
                                                                             o_error))
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                    l_plsql_blocks(l_table_name) := l_plsql_blocks(l_table_name) || 'PK_PATIENT.G_' || l_table_name ||
                                                    '_ROW.' || l_column_name || ' := ' || l_convertion_exp || '; ';
                    --Silently ignore uknown combinations.
                    --ELSE
                    --   g_error := ' Uknown TABLE.COLUMN combination: ' || l_key;
                    --   RAISE internal_exception;
                END IF;
            END IF;
        END LOOP;
    
        -- PATIENT
        g_error            := 'PATIENT';
        l_has_table_values := l_has_tables_values('PATIENT');
        IF (l_has_table_values)
        THEN
            -- bind values to G_PATIENT_ROW
            g_error       := 'BIND PATIENT VALUES';
            l_plsql_block := l_plsql_blocks('PATIENT');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
            g_patient_row.flg_status := g_patient_active;
            -- get next patient id 
            g_error                  := 'GET PATIENT ID';
            g_patient_row.id_patient := ts_patient.next_key;
            -- update patient age
            g_error := 'UPDATE PATIENT AGE';
            IF (g_patient_row.dt_birth IS NOT NULL)
            THEN
                -- if age and dt_birth are set dt_birth takes priority
                g_patient_row.age := NULL;
            END IF;
            -- update patient flg migration
            g_patient_row.flg_migration := g_patient_alert;
            g_error                     := 'INSERT PATIENT';
        
            ts_patient.ins(id_patient_in        => g_patient_row.id_patient,
                           name_in              => g_patient_row.name,
                           gender_in            => g_patient_row.gender,
                           dt_birth_in          => g_patient_row.dt_birth,
                           nick_name_in         => g_patient_row.nick_name,
                           flg_status_in        => g_patient_row.flg_status,
                           dt_deceased_in       => g_patient_row.dt_deceased,
                           id_pat_family_in     => g_patient_row.id_pat_family,
                           last_name_in         => g_patient_row.last_name,
                           middle_name_in       => g_patient_row.middle_name,
                           age_in               => g_patient_row.age,
                           flg_migration_in     => g_patient_row.flg_migration,
                           total_fam_members_in => g_patient_row.total_fam_members,
                           rows_out             => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        ELSE
            -- no patient info. there is something wrong
            g_error := 'NO PATIENT INFO';
            RAISE internal_exception;
        END IF;
    
        -- PAT_SOC_ATTRIBUTES
        -- bind values to L_PAT_SOC_ATTRIBUTES_ROW 
        g_error            := 'BIND PAT_SOC_ATTRIBUTES VALUES';
        l_has_table_values := l_has_tables_values('PAT_SOC_ATTRIBUTES');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_SOC_ATTRIBUTES');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
        g_pat_soc_attributes_row.id_patient := g_patient_row.id_patient;
    
        g_error := 'PAT_SOC_ATTRIBUTES';
        -- calculate ine_location
        IF (g_pat_soc_attributes_row.zip_code IS NOT NULL)
        THEN
            IF NOT
                find_ine_location_internal(i_lang, i_prof, g_pat_soc_attributes_row.zip_code, l_ine_location, o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        g_pat_soc_attributes_row.ine_location := l_ine_location;
        -- get pat_soc_attributes id 
    
        -- JS, 2007-13-12: 0 para id_institution, usado pelo P1
        g_pat_soc_attributes_row.id_institution        := 0;
        g_error                                        := 'GET PAT_SOC_ATTRIBUTES ID';
        g_pat_soc_attributes_row.id_pat_soc_attributes := ts_pat_soc_attributes.next_key();
        g_pat_soc_attributes_row.id_episode            := nvl(i_epis, -1);
        -- insert into pat_soc_attributes
        g_error := 'INSERT PAT_SOC_ATTRIBUTES';
        ts_pat_soc_attributes.ins(rec_in => g_pat_soc_attributes_row, rows_out => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_SOC_ATTRIBUTES',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- JS, 2008-06-02: Para restantes softwares
        g_pat_soc_attributes_row.id_institution        := i_prof.institution;
        g_error                                        := 'GET PAT_SOC_ATTRIBUTES ID';
        g_pat_soc_attributes_row.id_pat_soc_attributes := ts_pat_soc_attributes.next_key();
        g_pat_soc_attributes_row.id_episode            := nvl(i_epis, -1);
        -- insert into pat_soc_attributes
        g_error := 'INSERT PAT_SOC_ATTRIBUTES';
        ts_pat_soc_attributes.ins(rec_in => g_pat_soc_attributes_row, rows_out => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_SOC_ATTRIBUTES',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- PAT_JOB 
        -- bind values to G_PAT_JOB_ROW 
        g_error            := 'BIND PAT_JOB VALUES';
        l_has_table_values := l_has_tables_values('PAT_JOB');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_JOB');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
    
        -- create pat_job register only if occupation is specified 
        IF (g_pat_job_row.id_occupation IS NOT NULL OR g_pat_job_row.occupation_desc IS NOT NULL)
        THEN
            g_error := 'PAT_JOB';
            IF NOT pk_patient.set_pat_job_internal(i_lang              => i_lang,
                                                   i_id_pat            => g_patient_row.id_patient,
                                                   i_occup             => g_pat_job_row.id_occupation,
                                                   i_prof              => i_prof,
                                                   i_location          => NULL,
                                                   i_year_begin        => NULL,
                                                   i_year_end          => NULL,
                                                   i_activity_type     => NULL,
                                                   i_prof_disease_risk => NULL,
                                                   i_notes             => NULL,
                                                   i_num_workers       => NULL,
                                                   i_company           => NULL,
                                                   i_prof_cat_type     => i_prof_cat_type,
                                                   i_occupation_desc   => g_pat_job_row.occupation_desc,
                                                   i_epis              => nvl(i_epis, -1),
                                                   o_error             => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
        -- PAT_CLI_ATTRIBUTES 
        -- bind values to G_PAT_CLI_ATTRIBUTES_ROW 
        g_error            := 'BIND PAT_CLI_ATTRIBUTES VALUES';
        l_has_table_values := l_has_tables_values('PAT_CLI_ATTRIBUTES');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_CLI_ATTRIBUTES');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
    
        g_error := 'PAT_CLI_ATTRIBUTES';
        IF NOT pk_patient.set_pat_cli_att_internal(i_lang            => i_lang,
                                                   i_id_pat          => g_patient_row.id_patient,
                                                   i_flg_pregnancy   => NULL,
                                                   i_flg_breast_feed => NULL,
                                                   i_prof            => i_prof,
                                                   i_prof_cat_type   => i_prof_cat_type,
                                                   i_id_recm         => g_pat_cli_attributes_row.id_recm,
                                                   i_dt_val_recm     => NULL,
                                                   i_epis            => nvl(i_epis, -1),
                                                   o_error           => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --CLIN_RECORD 
        -- bind values to G_CLIN_RECORD_ROW 
        g_error            := 'BIND CLIN_RECORD VALUES';
        l_has_table_values := l_has_tables_values('CLIN_RECORD');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('CLIN_RECORD');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
        g_clin_record_row.id_patient     := g_patient_row.id_patient;
        g_clin_record_row.id_institution := i_prof.institution;
        g_error                          := 'CLIN_RECORD';
        IF NOT (create_clin_record(i_lang, i_prof, g_clin_record_row, o_error))
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        IF pk_sysconfig.get_config('GENERATE_AUTOMATIC_CLIN_RECORD', i_prof) = 'Y'
        THEN
            --Importante !! 
            --Este bloco de c+odigo que actualiza a clin_record está aqui apenas para 
            --ser executado em clientes brasileiros, pois estes desejam que o alert
            --gere ids de processo clínico automáticamente.
            --Este código deverá ser removido quando o ADT ficar pronto
            g_error := 'COUNT CLIN_REC';
            SELECT COUNT(0), SUM(decode(id_institution, i_prof.institution, 1, 0))
              INTO l_count_ttl, l_count_inst
              FROM clin_record
             WHERE id_patient = g_patient_row.id_patient;
        
            IF l_count_ttl = 0
            THEN
                --sem registos na clin_record para este paciente
                g_error := 'INS CLIN_REC 1';
                INSERT INTO clin_record
                    (id_clin_record,
                     flg_status,
                     id_patient,
                     id_institution,
                     id_pat_family,
                     num_clin_record,
                     id_instit_enroled)
                VALUES
                    (seq_clin_record.nextval,
                     g_clin_rec_active,
                     g_patient_row.id_patient,
                     i_prof.institution,
                     NULL,
                     NULL,
                     i_prof.institution);
            
            ELSIF l_count_inst = 0
            THEN
                --não tem linha para esta instituição
                --faz-se uma cópia da linha existente noutra.
                g_error := 'INS CLIN_REC 2';
                INSERT INTO clin_record
                    (id_clin_record,
                     flg_status,
                     id_patient,
                     id_institution,
                     id_pat_family,
                     num_clin_record,
                     id_instit_enroled)
                    SELECT seq_clin_record.nextval,
                           flg_status,
                           id_patient,
                           i_prof.institution,
                           id_pat_family,
                           num_clin_record,
                           i_prof.institution
                      FROM (SELECT id_clin_record,
                                   flg_status,
                                   id_patient,
                                   id_institution,
                                   id_pat_family,
                                   num_clin_record,
                                   id_instit_enroled
                              FROM clin_record
                             WHERE id_patient = g_patient_row.id_patient
                             ORDER BY decode(flg_status, g_clin_rec_active, 0, 1) ASC,
                                      id_institution,
                                      id_clin_record DESC)
                     WHERE rownum < 2;
            END IF;
            --colocar g_patient_row.id_patientínico caso não esteja definido
            g_error := 'UPDATE CLIN_REC';
            UPDATE clin_record
               SET num_clin_record = g_patient_row.id_patient
             WHERE id_patient = g_patient_row.id_patient
               AND id_institution = i_prof.institution
               AND num_clin_record IS NULL;
        END IF;
    
        --PAT_HEALTH_PLAN 
        -- WARNING: This code only supports one healthplan in id screen 
        g_error            := 'BIND PAT_HEALTH_PLAN VALUES';
        l_has_table_values := l_has_tables_values('PAT_HEALTH_PLAN');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            g_pat_health_plan_row.flg_default    := g_pat_hplan_flg_default_no;
            g_pat_health_plan_row.id_patient     := g_patient_row.id_patient;
            g_pat_health_plan_row.flg_status     := g_pat_hplan_active;
            g_pat_health_plan_row.id_institution := i_prof.institution;
            g_error                              := 'GET ID_HEALTH_PLAN';
            --BEGIN
            --    l_health_plan_flg_type := l_screen_metadata('PAT_HEALTH_PLAN.NUM_HEALTH_PLAN').health_plan_flg_type;
            --    IF (l_health_plan_flg_type IS NULL)
            --    THEN
            --        g_error := 'PAT_HEALTH_PLAN.NUM_HEALTH_PLAN HAS NO flgType ATTRIBUTE IN XML SCREEN TEMPLATE';
            --        RAISE internal_exception;
            --    END IF;
            --    SELECT hp.id_health_plan
            --      INTO g_pat_health_plan_row.id_health_plan
            --      FROM health_plan hp
            --      JOIN health_plan_instit hpi ON hp.id_health_plan = hpi.id_health_plan
            --     WHERE hpi.id_health_plan = hp.id_health_plan
            --       AND hp.flg_type = l_health_plan_flg_type
            --       AND hpi.id_institution = i_prof.institution;
            --EXCEPTION
            --    WHEN no_data_found THEN
            --        g_error := 'NO HEALTH PLAN WITH TYPE ' || l_health_plan_flg_type || ' DEFINED TO INSTITUTION ' ||
            --                   i_prof.institution;
            --        RAISE internal_exception;
            --END;
            -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
            l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
            BEGIN
                SELECT hp.id_health_plan
                  INTO l_id_default_hp
                  FROM health_plan hp
                 WHERE hp.id_content = l_id_cnt_hp
                   AND hp.flg_available = 'Y';
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_default_hp := NULL;
            END;
        
            g_pat_health_plan_row.id_health_plan := l_id_default_hp;
            IF g_pat_health_plan_row.id_health_plan IS NULL
            THEN
                g_error := 'SYS_CONFIG PARAMETER ''ADT_NATIONAL_HEALTH_PLAN_ID'' NOT DEFINED FOR INSTITUTION ' ||
                           i_prof.institution || ' AND SOFTWARE ' || i_prof.software;
                RAISE internal_exception;
            END IF;
        
            l_plsql_block := l_plsql_blocks('PAT_HEALTH_PLAN');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        
            g_error             := 'PAT_HEALTH_PLAN';
            l_id_health_plans   := table_number(g_pat_health_plan_row.id_health_plan);
            l_num_health_plans  := table_varchar(g_pat_health_plan_row.num_health_plan);
            l_dt_health_plans   := table_varchar(nvl(g_pat_health_plan_row.dt_health_plan,
                                                     to_char(g_pat_health_plan_row.dt_health_plan, 'DD/MM/YYYY')));
            l_desc_health_plans := table_varchar(g_pat_health_plan_row.desc_health_plan);
            l_flg_defaults      := table_varchar(g_pat_health_plan_row.flg_default);
            l_default_epis      := table_varchar(NULL);
            l_barcodes          := table_varchar(g_pat_health_plan_row.barcode);
            IF NOT pk_patient.set_pat_hplan(i_lang,
                                            g_pat_health_plan_row.id_patient,
                                            NULL,
                                            l_id_health_plans,
                                            l_num_health_plans,
                                            l_dt_health_plans,
                                            l_flg_defaults,
                                            l_default_epis,
                                            l_barcodes,
                                            i_prof,
                                            i_prof_cat_type,
                                            l_desc_health_plans,
                                            o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
        --DOC_EXTERNAL 
        -- WARNING: This code only supports one doc_external in id screen
        g_error            := 'BIND DOC_EXTERNAL';
        l_has_table_values := l_has_tables_values('DOC_EXTERNAL');
        g_error            := 'SET PAT_DOC_EXTERNAL';
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('DOC_EXTERNAL');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            pk_alertlog.log_debug('create_patient, doc_external bind' || chr(10) || l_plsql_block);
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
        IF NOT pk_doc_internal.set_doc_identific_internal(i_lang,
                                                          i_prof,
                                                          g_patient_row.id_patient,
                                                          g_doc_external_row.num_doc,
                                                          i_btn,
                                                          l_id_doc_external,
                                                          o_create_doc_msg,
                                                          o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- several types of professionals can create patient info, meaning that they are interacting with the patient 
        g_sysdate_tstz := current_timestamp;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => g_patient_row.id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- filling the l_pat_dmgr_hist_row
    
        g_error := ' SELECT SEQ_PAT_DMGR_HIST.NEXTVAL';
    
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_pat_dmgr_hist_seq_number
          FROM dual;
    
        g_error                                := 'FILLING L_PAT_DMGR_HIST_ROW';
        l_pat_dmgr_hist_row.id_pat_dmgr_hist   := l_pat_dmgr_hist_seq_number;
        l_pat_dmgr_hist_row.id_patient         := g_patient_row.id_patient;
        l_pat_dmgr_hist_row.id_professional    := i_prof.id;
        l_pat_dmgr_hist_row.id_institution     := i_prof.institution;
        l_pat_dmgr_hist_row.dt_change_tstz     := current_timestamp;
        l_pat_dmgr_hist_row.name               := g_patient_row.name;
        l_pat_dmgr_hist_row.gender             := g_patient_row.gender;
        l_pat_dmgr_hist_row.nick_name          := g_patient_row.nick_name;
        l_pat_dmgr_hist_row.age                := g_patient_row.age;
        l_pat_dmgr_hist_row.marital_status     := g_pat_soc_attributes_row.marital_status;
        l_pat_dmgr_hist_row.address            := g_pat_soc_attributes_row.address;
        l_pat_dmgr_hist_row.district           := g_pat_soc_attributes_row.district;
        l_pat_dmgr_hist_row.zip_code           := g_pat_soc_attributes_row.zip_code;
        l_pat_dmgr_hist_row.num_main_contact   := g_pat_soc_attributes_row.num_main_contact;
        l_pat_dmgr_hist_row.num_contact        := g_pat_soc_attributes_row.num_contact;
        l_pat_dmgr_hist_row.flg_job_status     := g_pat_soc_attributes_row.flg_job_status;
        l_pat_dmgr_hist_row.id_country_nation  := g_pat_soc_attributes_row.id_country_nation;
        l_pat_dmgr_hist_row.id_country_address := g_pat_soc_attributes_row.id_country_address;
        l_pat_dmgr_hist_row.id_scholarship     := g_pat_soc_attributes_row.id_scholarship;
        l_pat_dmgr_hist_row.father_name        := g_pat_soc_attributes_row.father_name;
        l_pat_dmgr_hist_row.id_isencao         := g_pat_soc_attributes_row.id_isencao;
        l_pat_dmgr_hist_row.birth_place        := g_pat_soc_attributes_row.birth_place;
        l_pat_dmgr_hist_row.num_health_plan    := g_pat_health_plan_row.num_health_plan;
        l_pat_dmgr_hist_row.id_recm            := g_pat_cli_attributes_row.id_recm;
        l_pat_dmgr_hist_row.id_occupation      := g_pat_job_row.id_occupation;
        l_pat_dmgr_hist_row.occupation_desc    := g_pat_job_row.occupation_desc;
        l_pat_dmgr_hist_row.mother_name        := g_pat_soc_attributes_row.mother_name;
        l_pat_dmgr_hist_row.location           := g_pat_soc_attributes_row.location;
        l_pat_dmgr_hist_row.num_doc_external   := g_doc_external_row.num_doc;
        l_pat_dmgr_hist_row.flg_migrator       := g_pat_soc_attributes_row.flg_migrator;
        -- calling the insertion function to the pat_dmgr_hist table
    
        g_error                 := 'CALLING PK_DMGR_HIST.CREATE_DMGR_HIST';
        l_create_dmgr_hist_bool := pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row, i_lang, i_prof, o_error);
        IF NOT l_create_dmgr_hist_bool
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        -- set return patient id
        o_id_patient := g_patient_row.id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PATIENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Set patient attributes: personal, clinical, social, etc. 
    * I_KEYS and I_VALUES are related by array index.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPIS  Episode id, 
    * @param   I_ID_PATIENT the patient id 
    * @param   I_CONTEXT context identifing the screen template,
    * @param   I_ID_PATIENT the patient id 
    * @param   I_KEYS array with keys about which info is available to the patient. A key must respect the <TABLE>.<COLUMN> format to identifie the value.  
    * @param   I_VALUES array with which info is available to the patient
    * @param   I_PROF_CAT_TYPE the professional category   
    * @param   O_FLG_SHOW  =Y to show a message, otherwise = N 
    * @param   O_MSG_TITLE  the message title, when O_FLG_SHOW = Y 
    * @param   O_MSG_TEXT  the message text , when O_FLG_SHOW = Y
    * @param   O_BUTTON the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed   
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   26-10-2006
    *
    * @author  Pedro Santos
    * @version 2.4.3-Denormalized
    * @since   2008/09/30
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */
    FUNCTION set_patient_attributes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_context        IN screen_template.context%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_btn            IN sys_button_prop.id_sys_button_prop%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- local types
        TYPE varchar_hashtable IS TABLE OF VARCHAR(4000) INDEX BY VARCHAR(200);
        TYPE boolean_hashtable IS TABLE OF BOOLEAN INDEX BY VARCHAR(200);
        -- local variables
        -- metadata variables
        l_screen_metadata          pk_screen_template_internal.screen_metadata_type;
        l_plsql_blocks             varchar_hashtable;
        l_plsql_block              VARCHAR2(4000);
        l_has_tables_values        boolean_hashtable;
        l_has_table_values         BOOLEAN;
        internal_exception         EXCEPTION;
        l_key                      VARCHAR2(4000);
        l_table_name               VARCHAR2(200);
        l_column_name              VARCHAR(200);
        l_point_separator_position NUMBER;
        l_convertion_exp           VARCHAR2(4000);
        l_ine_location             pat_soc_attributes.ine_location%TYPE;
        l_id_health_plans          table_number;
        l_num_health_plans         table_varchar;
        l_dt_health_plans          table_varchar;
        l_desc_health_plans        table_varchar;
        l_flg_defaults             table_varchar;
        l_default_epis             table_varchar;
        l_barcodes                 table_varchar;
        l_id_doc_external          doc_external.id_doc_external%TYPE;
        l_pat_dmgr_hist_row        pat_dmgr_hist%ROWTYPE;
        l_create_dmgr_hist_bool    BOOLEAN;
        l_pat_dmgr_hist_seq_number NUMBER;
        l_id                       NUMBER;
        l_rowids                   table_varchar;
        l_clin_rec_next            clin_record.id_clin_record%TYPE;
    
        --health plan default content id
        l_id_cnt_hp     health_plan.id_content%TYPE;
        l_id_default_hp health_plan.id_health_plan%TYPE;
    
        -- ACM, 2010-06-16: ALERT-70412
        --l_ref_update          PLS_INTEGER;
        --l_patient_old_row     patient%ROWTYPE;
        --l_pat_soc_att_old_row pat_soc_attributes%ROWTYPE;
    BEGIN
        -- initialize variables 
        g_patient_row            := NULL;
        g_pat_soc_attributes_row := NULL;
        g_pat_job_row            := NULL;
        g_pat_cli_attributes_row := NULL;
        g_clin_record_row        := NULL;
        g_doc_external_row       := NULL;
        -- hastable to plsql blocks 
        l_plsql_blocks('PATIENT') := ' ';
        l_plsql_blocks('PAT_SOC_ATTRIBUTES') := ' ';
        l_plsql_blocks('PAT_JOB') := ' ';
        l_plsql_blocks('PAT_CLI_ATTRIBUTES') := ' ';
        l_plsql_blocks('CLIN_RECORD') := ' ';
        l_plsql_blocks('PAT_HEALTH_PLAN') := ' ';
        l_plsql_blocks('DOC_EXTERNAL') := ' ';
        -- hashtable to tables with values to set 
        l_has_tables_values('PATIENT') := FALSE;
        l_has_tables_values('PAT_SOC_ATTRIBUTES') := FALSE;
        l_has_tables_values('PAT_JOB') := FALSE;
        l_has_tables_values('PAT_CLI_ATTRIBUTES') := FALSE;
        l_has_tables_values('CLIN_RECORD') := FALSE;
        l_has_tables_values('PAT_HEALTH_PLAN') := FALSE;
        l_has_tables_values('DOC_EXTERNAL') := FALSE;
    
        -- ACM, 2010-06-16: ALERT-70412
        --l_ref_update := 0;
    
        -- get template metadata
        g_error := 'GET SCREEN_TEMPLATE_METADATA';
        IF (NOT pk_screen_template_internal.get_screen_template_metadata(i_lang,
                                                                         i_prof,
                                                                         i_context,
                                                                         l_screen_metadata,
                                                                         o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        -- validate mandatory fields
        IF (NOT pk_screen_template_internal.validate_screen_fields(i_lang,
                                                                   i_prof,
                                                                   l_screen_metadata,
                                                                   i_keys,
                                                                   i_values,
                                                                   o_flg_show,
                                                                   o_msg_text,
                                                                   o_msg_title,
                                                                   o_button,
                                                                   o_error))
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- bind values from input to local variables
        g_error := 'BUILD SQLS - PHASE 1';
        FOR i IN 1 .. i_keys.count
        LOOP
            -- Loop sobre o array de chaves
            l_key := i_keys(i);
            -- readOnly attributes are not set 
            IF (NOT l_screen_metadata(l_key).readonly)
            THEN
                l_point_separator_position := instr(l_key, '.');
                l_table_name               := upper(substr(l_key, 1, l_point_separator_position - 1)); -- calc table name
                l_column_name              := upper(substr(l_key, l_point_separator_position + 1)); -- calc column name
                -- as we are updating null values are relevant
                IF (l_table_name IN ('PATIENT',
                                     'PAT_SOC_ATTRIBUTES',
                                     'PAT_JOB',
                                     'PAT_CLI_ATTRIBUTES',
                                     'CLIN_RECORD',
                                     'PAT_HEALTH_PLAN',
                                     'DOC_EXTERNAL'))
                THEN
                    l_has_tables_values(l_table_name) := TRUE;
                    -- generate pl/sql dynamic code 
                    IF (NOT pk_screen_template_internal.varchar_to_data_type(i_values(i),
                                                                             l_screen_metadata,
                                                                             l_key,
                                                                             i_lang,
                                                                             l_convertion_exp,
                                                                             o_error))
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                    l_plsql_blocks(l_table_name) := l_plsql_blocks(l_table_name) || 'PK_PATIENT.G_' || l_table_name ||
                                                    '_ROW.' || l_column_name || ' := ' || l_convertion_exp || '; ';
                ELSE
                    g_error := ' UNKNOWN TABLE NAME:' || l_table_name;
                    RAISE internal_exception;
                END IF;
            END IF;
        END LOOP;
    
        -- PATIENT
        IF (i_id_patient IS NOT NULL)
        THEN
        
            g_error            := 'PATIENT';
            l_has_table_values := l_has_tables_values('PATIENT');
        
            -- get current patient values
            SELECT *
              INTO g_patient_row
              FROM patient
             WHERE id_patient = i_id_patient
               FOR UPDATE; --USE FOR UPDATE TO LOCK THE REGISTER 
        
            -- ACM, 2010-06-16: ALERT-70412 - check to see if there was an update on name, gender or dt_birth
            --g_error           := 'l_patient_old_row';
            --l_patient_old_row := g_patient_row;
        
            -- bind values to G_PATIENT_ROW
            IF l_has_table_values
            THEN
                g_error       := 'BIND PATIENT VALUES';
                l_plsql_block := l_plsql_blocks('PATIENT');
                l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
                EXECUTE IMMEDIATE l_plsql_block;
                -- update patient age 
                g_error := 'UPDATE PATIENT AGE';
                IF (g_patient_row.dt_birth IS NOT NULL)
                THEN
                    -- if age and dt_birth are set dt_birth takes priority 
                    g_patient_row.age := NULL;
                END IF;
                --update patient info 
                g_error := 'UPDATE PATIENT';
                UPDATE patient
                   SET ROW = g_patient_row
                 WHERE id_patient = i_id_patient;
            
                -- ACM, 2010-06-16: ALERT-70412 - check to see if there was an update on name, gender or dt_birth
                --g_error := 'check diff';
                --IF (l_patient_old_row.name != g_patient_row.name)
                --   OR l_patient_old_row.gender != g_patient_row.gender
                --   OR l_patient_old_row.dt_birth != g_patient_row.dt_birth
                --THEN
                --    l_ref_update := 1;
                --END IF;
            
            END IF;
        ELSE
            -- no patient info. there is something wrong 
            g_error := 'PATIENT.ID_PATIENT NOT PROVIDED';
            RAISE internal_exception;
        END IF;
    
        -- PAT_SOC_ATTRIBUTES
        -- get current pat_soc_attributes values, a ptient has only one register in pat_soc_attributes 
        -- JS, 2007-12-13: No caso do P1 é registado 0 para id_institution em pat_soc_attributes
        BEGIN
            g_error := 'FIND PAT_SOC_ATTRIBUTES';
            SELECT *
              INTO g_pat_soc_attributes_row
              FROM pat_soc_attributes
             WHERE id_patient = i_id_patient
               AND id_institution = 0
               FOR UPDATE; --USE FOR UPDATE TO LOCK THE REGISTER
        
            -- ACM, 2010-06-16: ALERT-70412 - check to see if there was an update on name, gender or dt_birth
            --g_error               := 'l_pat_soc_Att_old_row';
            --l_pat_soc_att_old_row := g_pat_soc_attributes_row;
        
        EXCEPTION
            WHEN no_data_found THEN
                -- VALUES TO INITIALIZE PAT_SOC_ATTRIBUTES
                g_pat_soc_attributes_row.id_pat_soc_attributes := NULL;
        END;
        -- bind values to L_PAT_SOC_ATTRIBUTES_ROW 
        g_error            := 'BIND PAT_SOC_ATTRIBUTES VALUES';
        l_has_table_values := l_has_tables_values('PAT_SOC_ATTRIBUTES');
    
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_id          := g_pat_soc_attributes_row.id_pat_soc_attributes;
            l_plsql_block := l_plsql_blocks('PAT_SOC_ATTRIBUTES');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
            g_pat_soc_attributes_row.id_patient            := g_patient_row.id_patient;
            g_pat_soc_attributes_row.id_institution        := 0;
            g_pat_soc_attributes_row.id_pat_soc_attributes := l_id;
        
            g_error := 'PAT_SOC_ATTRIBUTES';
            -- calculate ine_location 
            IF (g_pat_soc_attributes_row.zip_code IS NOT NULL)
            THEN
                IF NOT find_ine_location_internal(i_lang,
                                                  i_prof,
                                                  g_pat_soc_attributes_row.zip_code,
                                                  l_ine_location,
                                                  o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
            g_pat_soc_attributes_row.ine_location := l_ine_location;
        
            IF (g_pat_soc_attributes_row.id_pat_soc_attributes IS NOT NULL)
            THEN
                -- update pat_soc_attributes, a patient only has a pat_soc_attributes registry 
                g_error := 'UPDATE PAT_SOC_ATTRIBUTES';
                UPDATE pat_soc_attributes
                   SET ROW = g_pat_soc_attributes_row
                 WHERE id_pat_soc_attributes = g_pat_soc_attributes_row.id_pat_soc_attributes;
            ELSE
                -- get pat_soc_attributes id 
                g_error                                        := 'GET PAT_SOC_ATTRIBUTES ID';
                g_pat_soc_attributes_row.id_pat_soc_attributes := ts_pat_soc_attributes.next_key();
                g_pat_soc_attributes_row.id_episode            := i_epis;
                -- insert into pat_soc_attributes
                g_error := 'INSERT INTO PAT_SOC_ATTRIBUTES';
                ts_pat_soc_attributes.ins(rec_in => g_pat_soc_attributes_row, rows_out => l_rowids);
                g_error := 'UPDATES T_DATA_GOV_MNT-PAT_SOC_ATTRIBUTES';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_SOC_ATTRIBUTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        
            -- ACM, 2010-06-16: ALERT-70412 - check to see if there was an update on address, 
            -- location, zip_code or id_country_address (only for id_institution = 0, used for referral software)
            --g_error := 'check diff';
            --IF l_pat_soc_att_old_row.address != g_pat_soc_attributes_row.address
            --   OR l_pat_soc_att_old_row.location != g_pat_soc_attributes_row.location
            --   OR l_pat_soc_att_old_row.zip_code != g_pat_soc_attributes_row.zip_code
            --   OR l_pat_soc_att_old_row.id_country_address != g_pat_soc_attributes_row.id_country_address
            --THEN
            --    l_ref_update := 1;
            --END IF;
        
        END IF;
    
        g_pat_soc_attributes_row.id_pat_soc_attributes := NULL;
    
        -- get current pat_soc_attributes values, a ptient has only one register in pat_soc_attributes 
        BEGIN
            g_error := 'FIND PAT_SOC_ATTRIBUTES';
            SELECT *
              INTO g_pat_soc_attributes_row
              FROM pat_soc_attributes
             WHERE id_patient = i_id_patient
               AND id_institution = i_prof.institution
               FOR UPDATE; --USE FOR UPDATE TO LOCK THE REGISTER
        EXCEPTION
            WHEN no_data_found THEN
                -- VALUES TO INITIALIZE PAT_SOC_ATTRIBUTES
                g_pat_soc_attributes_row.id_pat_soc_attributes := NULL;
        END;
    
        -- bind values to L_PAT_SOC_ATTRIBUTES_ROW 
        g_error            := 'BIND PAT_SOC_ATTRIBUTES VALUES';
        l_has_table_values := l_has_tables_values('PAT_SOC_ATTRIBUTES');
    
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_SOC_ATTRIBUTES');
            l_id          := g_pat_soc_attributes_row.id_pat_soc_attributes;
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
            g_pat_soc_attributes_row.id_patient            := g_patient_row.id_patient;
            g_pat_soc_attributes_row.id_institution        := i_prof.institution;
            g_pat_soc_attributes_row.id_pat_soc_attributes := l_id;
        
            g_error := 'PAT_SOC_ATTRIBUTES';
            -- calculate ine_location 
            IF (g_pat_soc_attributes_row.zip_code IS NOT NULL)
            THEN
                IF NOT find_ine_location_internal(i_lang,
                                                  i_prof,
                                                  g_pat_soc_attributes_row.zip_code,
                                                  l_ine_location,
                                                  o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
            g_pat_soc_attributes_row.ine_location := l_ine_location;
        
            IF (g_pat_soc_attributes_row.id_pat_soc_attributes IS NOT NULL)
            THEN
                -- update pat_soc_attributes, a patient only has a pat_soc_attributes registry 
                g_error := 'UPDATE PAT_SOC_ATTRIBUTES';
                UPDATE pat_soc_attributes
                   SET ROW = g_pat_soc_attributes_row
                 WHERE id_pat_soc_attributes = g_pat_soc_attributes_row.id_pat_soc_attributes;
            ELSE
                -- get pat_soc_attributes id 
                g_error                                        := 'GET PAT_SOC_ATTRIBUTES ID';
                g_pat_soc_attributes_row.id_pat_soc_attributes := ts_pat_soc_attributes.next_key();
                g_pat_soc_attributes_row.id_episode            := i_epis;
                -- insert into pat_soc_attributes
                g_error := 'INSERT INTO PAT_SOC_ATTRIBUTES';
                ts_pat_soc_attributes.ins(rec_in => g_pat_soc_attributes_row, rows_out => l_rowids);
                g_error := 'UPDATES T_DATA_GOV_MNT-PAT_SOC_ATTRIBUTES';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_SOC_ATTRIBUTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        
        END IF;
    
        -- PAT_JOB 
        -- bind values to G_PAT_JOB_ROW 
        g_error            := 'BIND PAT_JOB VALUES';
        l_has_table_values := l_has_tables_values('PAT_JOB');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_JOB');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        
        END IF;
        g_error := 'PAT_JOB ID_OCCUPATION';
        -- delete pat_job, a patient has only a pat_job register 
        DELETE pat_job
         WHERE id_patient = i_id_patient;
        -- update pat_job info
        IF (g_pat_job_row.id_occupation IS NOT NULL OR g_pat_job_row.occupation_desc IS NOT NULL)
        THEN
            IF NOT pk_patient.set_pat_job_internal(i_lang              => i_lang,
                                                   i_id_pat            => g_patient_row.id_patient,
                                                   i_occup             => g_pat_job_row.id_occupation,
                                                   i_prof              => i_prof,
                                                   i_location          => NULL,
                                                   i_year_begin        => NULL,
                                                   i_year_end          => NULL,
                                                   i_activity_type     => NULL,
                                                   i_prof_disease_risk => NULL,
                                                   i_notes             => NULL,
                                                   i_num_workers       => NULL,
                                                   i_company           => NULL,
                                                   i_prof_cat_type     => i_prof_cat_type,
                                                   i_occupation_desc   => g_pat_job_row.occupation_desc,
                                                   i_epis              => i_epis,
                                                   o_error             => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        -- PAT_CLI_ATTRIBUTES 
        -- bind values to G_PAT_CLI_ATTRIBUTES_ROW 
        g_error            := 'BIND PAT_CLI_ATTRIBUTES VALUES';
        l_has_table_values := l_has_tables_values('PAT_CLI_ATTRIBUTES');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('PAT_CLI_ATTRIBUTES');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
        END IF;
        g_error := 'PAT_CLI_ATTRIBUTES';
        -- a delete is not performed as it is implemented in set_pat_soc_att 
        IF NOT pk_patient.set_pat_cli_att_internal(i_lang            => i_lang,
                                                   i_id_pat          => g_patient_row.id_patient,
                                                   i_flg_pregnancy   => NULL,
                                                   i_flg_breast_feed => NULL,
                                                   i_prof            => i_prof,
                                                   i_prof_cat_type   => i_prof_cat_type,
                                                   i_id_recm         => g_pat_cli_attributes_row.id_recm,
                                                   i_dt_val_recm     => NULL,
                                                   i_epis            => i_epis,
                                                   o_error           => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- bind values to G_CLIN_RECORD_ROW 
        g_error            := 'BIND CLIN_RECORD VALUES';
        l_has_table_values := l_has_tables_values('CLIN_RECORD');
        IF (l_has_table_values)
        THEN
            --CLIN_RECORD
            -- TODO CHANGE BEHAVIOUR, WHEN SETTING WE MUST CHECK THE EXISTENCE 
            -- get current clin_record values, a patient a register in clin_record per institution
            BEGIN
                g_error := 'GET CLIN_RECORD 1';
                SELECT *
                  INTO g_clin_record_row
                  FROM clin_record
                 WHERE id_patient = i_id_patient
                   AND id_institution = i_prof.institution
                   FOR UPDATE; --USE FOR UPDATE TO LOCK THE REGISTER            
            EXCEPTION
                --Se o paciente ainda não tem registo na CLIN_RECORD 
                --cria-se registo. a edição do valor do processo só está disponível
                --nalguns mercados tipo brasileiro, e nunca pode falhar.
                WHEN no_data_found THEN
                
                    l_clin_rec_next := ts_clin_record.next_key();
                    -- setting rec values before insert so that each rrec field can later be used
                    -- as defined previously under the RETURNING INSERT clause
                    g_clin_record_row.id_clin_record    := l_clin_rec_next;
                    g_clin_record_row.flg_status        := 'A';
                    g_clin_record_row.id_patient        := i_id_patient;
                    g_clin_record_row.id_institution    := i_prof.institution;
                    g_clin_record_row.id_pat_family     := NULL;
                    g_clin_record_row.num_clin_record   := NULL;
                    g_clin_record_row.id_instit_enroled := i_prof.institution;
                    g_clin_record_row.id_episode        := i_epis;
                
                    g_error := 'INSERT CLIN_RECORD';
                    ts_clin_record.ins(rec_in => g_clin_record_row, rows_out => l_rowids);
                    g_error := 'T_DATA_GOV_MNT-INSERT-CLIN_RECORD';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'CLIN_RECORD',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
            END;
        
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('CLIN_RECORD');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
            g_error := 'CLIN_RECORD';
            IF NOT (update_clin_record(i_lang, g_clin_record_row, o_error))
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
        --PAT_HEALTH_PLAN 
        -- WARNING: This code only supports one healthplan in id screen 
        g_error            := 'BIND PAT_HEALTH_PLAN VALUES';
        l_has_table_values := l_has_tables_values('PAT_HEALTH_PLAN');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            g_pat_health_plan_row.flg_default    := g_pat_hplan_flg_default_no;
            g_pat_health_plan_row.id_patient     := g_patient_row.id_patient;
            g_pat_health_plan_row.flg_status     := g_pat_hplan_active;
            g_pat_health_plan_row.id_institution := i_prof.institution;
            g_error                              := 'GET ID_HEALTH_PLAN';
            --BEGIN
            --    l_health_plan_flg_type := l_screen_metadata('PAT_HEALTH_PLAN.NUM_HEALTH_PLAN').health_plan_flg_type;
            --    IF (l_health_plan_flg_type IS NULL)
            --    THEN
            --        g_error := 'PAT_HEALTH_PLAN.NUM_HEALTH_PLAN HAS NO flgType ATTRIBUTE IN XML SCREEN TEMPLATE';
            --        RAISE internal_exception;
            --    END IF;
            --
            --    SELECT hp.id_health_plan
            --      INTO g_pat_health_plan_row.id_health_plan
            --      FROM health_plan hp
            --      JOIN health_plan_instit hpi ON hp.id_health_plan = hpi.id_health_plan
            --     WHERE hpi.id_health_plan = hp.id_health_plan
            --       AND hp.flg_type = l_health_plan_flg_type
            --       AND hpi.id_institution = i_prof.institution;
            --
            --EXCEPTION
            --    WHEN no_data_found THEN
            --        g_error := 'NO HEALTH PLAN WITH TYPE ' || l_health_plan_flg_type || ' DEFINED TO INSTITUTION ' ||
            --                   i_prof.institution;
            --        RAISE internal_exception;
            --END;
        
            -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
            l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
            BEGIN
                SELECT hp.id_health_plan
                  INTO l_id_default_hp
                  FROM health_plan hp
                 WHERE hp.id_content = l_id_cnt_hp
                   AND hp.flg_available = 'Y';
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_default_hp := NULL;
            END;
        
            g_pat_health_plan_row.id_health_plan := l_id_default_hp;
            IF g_pat_health_plan_row.id_health_plan IS NULL
            THEN
                g_error := 'SYS_CONFIG PARAMETER ''ADT_NATIONAL_HEALTH_PLAN_ID'' NOT DEFINED FOR INSTITUTION ' ||
                           i_prof.institution || ' AND SOFTWARE ' || i_prof.software;
                RAISE internal_exception;
            END IF;
        
            l_plsql_block := l_plsql_blocks('PAT_HEALTH_PLAN');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            EXECUTE IMMEDIATE l_plsql_block;
            g_error := 'PAT_HEALTH_PLAN';
            IF (g_pat_health_plan_row.num_health_plan IS NULL)
            THEN
            
                g_error := 'DELETE EPIS_HEALTH_PLAN';
                DELETE epis_health_plan
                 WHERE id_pat_health_plan IN
                       (SELECT id_pat_health_plan
                          FROM pat_health_plan
                         WHERE id_patient = i_id_patient
                           AND id_health_plan = g_pat_health_plan_row.id_health_plan);
            
                g_error := 'DELETE PAT_HEALTH_PLAN';
                DELETE FROM pat_health_plan
                 WHERE id_patient = i_id_patient
                   AND id_health_plan = g_pat_health_plan_row.id_health_plan;
            
            ELSE
                g_error             := 'SET_PAT_HEALTH_PLAN_INTERNAL';
                l_id_health_plans   := table_number(g_pat_health_plan_row.id_health_plan);
                l_num_health_plans  := table_varchar(g_pat_health_plan_row.num_health_plan);
                l_dt_health_plans   := table_varchar(nvl(g_pat_health_plan_row.dt_health_plan,
                                                         to_char(g_pat_health_plan_row.dt_health_plan, 'DD/MM/YYYY')));
                l_desc_health_plans := table_varchar(g_pat_health_plan_row.desc_health_plan);
                l_flg_defaults      := table_varchar(g_pat_health_plan_row.flg_default);
                l_default_epis      := table_varchar(NULL);
                l_barcodes          := table_varchar(g_pat_health_plan_row.barcode);
                IF NOT set_pat_hplan_internal(i_lang,
                                              g_pat_health_plan_row.id_patient,
                                              NULL,
                                              l_id_health_plans,
                                              l_num_health_plans,
                                              l_dt_health_plans,
                                              l_flg_defaults,
                                              l_default_epis,
                                              l_barcodes,
                                              i_prof,
                                              i_prof_cat_type,
                                              l_desc_health_plans,
                                              o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        --DOC_EXTERNAL 
        -- WARNING: This code only supports one healthplan in id screen     
        g_error            := 'BIND PAT_JOB VALUES';
        l_has_table_values := l_has_tables_values('DOC_EXTERNAL');
        IF (l_has_table_values)
        THEN
            -- bind only if there is something to bind 
            l_plsql_block := l_plsql_blocks('DOC_EXTERNAL');
            l_plsql_block := 'BEGIN ' || l_plsql_block || ' END;';
            pk_alertlog.log_debug('DOC_EXTERNAL BIND' || chr(10) || l_plsql_block);
            EXECUTE IMMEDIATE l_plsql_block;
        
        END IF;
        g_error := 'SET DOC_EXTERNAL';
        IF NOT pk_doc_internal.set_doc_identific_internal(i_lang,
                                                          i_prof,
                                                          i_id_patient,
                                                          g_doc_external_row.num_doc,
                                                          i_btn,
                                                          l_id_doc_external,
                                                          o_create_doc_msg,
                                                          o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- JS, 2007-07-01: Actualizar estado dos pedidos do paciente independentemente do software
        -- em que esta logado
        g_error := 'Call pk_p1_core.update_patient_requests';
        IF NOT pk_p1_core.update_patient_requests(i_lang       => i_lang,
                                                  i_id_patient => i_id_patient,
                                                  i_prof       => i_prof,
                                                  o_error      => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --g_error := 'l_ref_update=' || l_ref_update;
        --pk_alertlog.log_debug(g_error);
        --IF l_ref_update = 1
        --THEN
        --
        --    g_error := 'Call PK_API_REF_EVENT.set_patient / ID_PAT=' || i_id_patient;
        --    IF NOT pk_api_ref_event.set_patient(i_lang       => i_lang,
        --                                        i_prof       => i_prof,
        --                                        i_id_patient => i_id_patient,
        --                                        o_error      => o_error)
        --    THEN
        --        pk_alertlog.log_warn(g_error);
        --    END IF;
        --
        --END IF;
    
        -- several types of professionals can update patient info, meaning that they are interacting with the patient
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- filling the l_pat_dmgr_hist_row
    
        g_error := 'seq_pat_dmgr_hist.NEXTVAL';
    
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_pat_dmgr_hist_seq_number
          FROM dual;
    
        g_error                                := 'filling the l_pat_dmgr_hist_row';
        l_pat_dmgr_hist_row.id_pat_dmgr_hist   := l_pat_dmgr_hist_seq_number;
        l_pat_dmgr_hist_row.id_patient         := g_patient_row.id_patient;
        l_pat_dmgr_hist_row.id_professional    := i_prof.id;
        l_pat_dmgr_hist_row.id_institution     := i_prof.institution;
        l_pat_dmgr_hist_row.dt_change_tstz     := current_timestamp;
        l_pat_dmgr_hist_row.name               := g_patient_row.name;
        l_pat_dmgr_hist_row.gender             := g_patient_row.gender;
        l_pat_dmgr_hist_row.dt_birth           := g_patient_row.dt_birth;
        l_pat_dmgr_hist_row.nick_name          := g_patient_row.nick_name;
        l_pat_dmgr_hist_row.age                := g_patient_row.age;
        l_pat_dmgr_hist_row.marital_status     := g_pat_soc_attributes_row.marital_status;
        l_pat_dmgr_hist_row.address            := g_pat_soc_attributes_row.address;
        l_pat_dmgr_hist_row.district           := g_pat_soc_attributes_row.district;
        l_pat_dmgr_hist_row.zip_code           := g_pat_soc_attributes_row.zip_code;
        l_pat_dmgr_hist_row.num_main_contact   := g_pat_soc_attributes_row.num_main_contact;
        l_pat_dmgr_hist_row.num_contact        := g_pat_soc_attributes_row.num_contact;
        l_pat_dmgr_hist_row.flg_job_status     := g_pat_soc_attributes_row.flg_job_status;
        l_pat_dmgr_hist_row.id_country_nation  := g_pat_soc_attributes_row.id_country_nation;
        l_pat_dmgr_hist_row.id_country_address := g_pat_soc_attributes_row.id_country_address;
        l_pat_dmgr_hist_row.id_scholarship     := g_pat_soc_attributes_row.id_scholarship;
        l_pat_dmgr_hist_row.father_name        := g_pat_soc_attributes_row.father_name;
        l_pat_dmgr_hist_row.id_isencao         := g_pat_soc_attributes_row.id_isencao;
        l_pat_dmgr_hist_row.birth_place        := g_pat_soc_attributes_row.birth_place;
        l_pat_dmgr_hist_row.num_health_plan    := g_pat_health_plan_row.num_health_plan;
        l_pat_dmgr_hist_row.id_recm            := g_pat_cli_attributes_row.id_recm;
        l_pat_dmgr_hist_row.id_occupation      := g_pat_job_row.id_occupation;
        l_pat_dmgr_hist_row.occupation_desc    := g_pat_job_row.occupation_desc;
        l_pat_dmgr_hist_row.mother_name        := g_pat_soc_attributes_row.mother_name;
        l_pat_dmgr_hist_row.location           := g_pat_soc_attributes_row.location;
        l_pat_dmgr_hist_row.num_doc_external   := g_doc_external_row.num_doc;
        l_pat_dmgr_hist_row.id_geo_state       := g_pat_soc_attributes_row.id_geo_state;
        l_pat_dmgr_hist_row.desc_geo_state     := g_pat_soc_attributes_row.desc_geo_state;
        l_pat_dmgr_hist_row.num_contrib        := g_pat_soc_attributes_row.num_contrib;
        l_pat_dmgr_hist_row.flg_migrator       := g_pat_soc_attributes_row.flg_migrator;
    
        -- calling the insertion function to the pat_dmgr_hist table
    
        g_error                 := 'Calling pk_dmgr_hist.create_dmgr_hist';
        l_create_dmgr_hist_bool := pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row, i_lang, i_prof, o_error);
        IF NOT l_create_dmgr_hist_bool
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PATIENT_ATTRIBUTES',
                                              o_error);
            pk_alertlog.log_debug(l_plsql_block);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_patient_attributes;

    /**
    * Get patient attributes: personal, clinical, social, etc. 
    * O_KEYS and O_VALUES are related by array index.
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param I_CONTEXT context identifing the screen template,
    * @param  I_PATIENT the patient 
    * @param   I_PROF_CAT_TYPE the professional category   
    * @param   O_KEYS array with keys about which info is available the patient. A key has the <TABLE>.<COLUMN> format to identifie the value.  
    * @param   O_VALUES array with which info is available to the patient 
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar E
    * @version 1.0 
    * @since   26-10-2006 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */

    FUNCTION get_patient_attributes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_context       IN screen_template.context%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_keys          OUT table_varchar,
        o_values        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --PATIENT
        l_patient_row patient%ROWTYPE;
        --PAT_SOC_ATTRIBUTES
        l_pat_soc_attributes_row pat_soc_attributes%ROWTYPE;
        l_country_row            country%ROWTYPE;
        --PAT_JOB
        l_pat_job_row pat_job%ROWTYPE;
        --PAT_CLI_ATTRIBUTES
        l_pat_cli_attributes_row pat_cli_attributes%ROWTYPE;
        l_recm_row               recm%ROWTYPE;
        --CLIN_RECORD
        l_clin_record_row clin_record%ROWTYPE;
        --PAT_HEALTH_PLAN
        l_pat_health_plan_row pat_health_plan%ROWTYPE;
        l_id_health_plan      health_plan.id_health_plan%TYPE;
        l_id_cnt_hp           health_plan.id_content%TYPE;
        --DOC_EXTERNAL
        l_doc_external_row doc_external%ROWTYPE;
    
        l_table_name VARCHAR2(200);
        l_index      NUMBER;
        -- METADATA VARIABLES
        l_screen_metadata pk_screen_template_internal.screen_metadata_type;
        l_column_metadata pk_screen_template_internal.column_metadata_type;
        l_keys            table_varchar;
        l_values          table_varchar;
    
        l_aux BOOLEAN;
        -- LG 22-JAN-2007 
        l_aux_varchar pk_translation.t_desc_translation;
    
        -- JS, 2007-10-23: Validacao software p1
        l_soft             software.id_software%TYPE DEFAULT to_number(pk_sysconfig.get_config('SOFTWARE_ID_P1',
                                                                                               i_prof));
        internal_exception EXCEPTION;
    
        l_occupation_desc pat_job.occupation_desc%TYPE;
    
    BEGIN
        --initialize output variables
        l_keys := table_varchar();
        l_keys.extend(100);
        l_values := table_varchar();
        l_values.extend(100);
    
        -- get template metadata
        g_error := 'GET SCREEN_TEMPLATE_METADATA';
        IF (NOT pk_screen_template_internal.get_screen_template_metadata(i_lang,
                                                                         i_prof,
                                                                         i_context,
                                                                         l_screen_metadata,
                                                                         o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        -- VALUES FROM PATIENT TABLE 
        g_error := 'GET FROM PATIENT';
        SELECT *
          INTO l_patient_row
          FROM patient
         WHERE id_patient = i_id_patient;
        --
        l_index := 1;
        l_table_name := 'PATIENT';
        l_keys(l_index) := l_table_name || '.ID_PATIENT';
        --
        SELECT nvl2(l_patient_row.id_patient, to_char(l_patient_row.id_patient), NULL)
          INTO l_values(l_index)
          FROM dual;
        --
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.NAME';
        l_values(l_index) := l_patient_row.name;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.GENDER';
        l_values(l_index) := l_patient_row.gender;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.GENDER.DESCRIPTION';
        l_values(l_index) := pk_sysdomain.get_domain('PATIENT.GENDER', l_patient_row.gender, i_lang);
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.DT_BIRTH';
        SELECT nvl2(l_patient_row.dt_birth, to_char(l_patient_row.dt_birth, g_date_convert_pattern), NULL)
          INTO l_values(l_index)
          FROM dual;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.DT_BIRTH.DESCRIPTION';
        SELECT nvl2(l_patient_row.dt_birth, pk_date_utils.dt_chr(i_lang, l_patient_row.dt_birth, i_prof), NULL)
          INTO l_values(l_index)
          FROM dual;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.NICK_NAME';
        l_values(l_index) := l_patient_row.nick_name;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.FLG_STATUS';
        l_values(l_index) := l_patient_row.flg_status;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.DT_DECEASED';
        SELECT nvl2(l_patient_row.dt_deceased, to_char(l_patient_row.dt_deceased, g_date_convert_pattern), NULL)
          INTO l_values(l_index)
          FROM dual;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.DT_DECEASED.DESCRIPTION';
        SELECT nvl2(l_patient_row.dt_deceased, pk_date_utils.dt_chr(i_lang, l_patient_row.dt_deceased, i_prof), NULL)
          INTO l_values(l_index)
          FROM dual;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.ID_PAT_FAMILY';
        SELECT nvl2(l_patient_row.id_pat_family, to_char(l_patient_row.id_pat_family), NULL)
          INTO l_values(l_index)
          FROM dual;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.LAST_NAME';
        l_values(l_index) := l_patient_row.last_name;
        l_index := l_index + 1;
        l_keys(l_index) := l_table_name || '.MIDDLE_NAME';
        l_values(l_index) := l_patient_row.middle_name;
        l_index := l_index + 1;
    
        --RS 20080315 when months then shows 0 value
        l_keys(l_index) := l_table_name || '.AGE';
        IF (l_patient_row.dt_birth IS NOT NULL)
        THEN
            -- calculate age from dt_birth
            --l_values(l_index) := trunc(months_between(trunc(SYSDATE), trunc(l_patient_row.dt_birth)) / 12);
            l_values(l_index) := pk_patient.get_pat_age(i_lang => i_lang, i_id_pat => i_id_patient, i_prof => i_prof);
            l_index := l_index + 1;
        ELSE
            SELECT nvl2(l_patient_row.age, to_char(l_patient_row.age), NULL)
              INTO l_values(l_index)
              FROM dual;
            l_index := l_index + 1;
        END IF;
    
        -- VALUES FROM PAT_SOC_ATTRIBUTES TABLE 
        g_error := 'GET FROM PAT_SOC_ATTRIBUTES';
        BEGIN
            IF pk_sysconfig.get_config('SHARE_PATIENT_ATTRIBUTES', i_prof) = 'Y'
            THEN
                SELECT *
                  INTO l_pat_soc_attributes_row
                  FROM pat_soc_attributes
                 WHERE id_patient = i_id_patient
                   AND id_institution = 0;
            ELSE
                SELECT *
                  INTO l_pat_soc_attributes_row
                  FROM pat_soc_attributes
                 WHERE id_patient = i_id_patient
                   AND id_institution = i_prof.institution;
            END IF;
        
            l_table_name := 'PAT_SOC_ATTRIBUTES';
            l_keys(l_index) := l_table_name || '.ID_PAT_SOC_ATTRIBUTES';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_pat_soc_attributes);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.MARITAL_STATUS';
            l_values(l_index) := l_pat_soc_attributes_row.marital_status;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.MARITAL_STATUS.DESCRIPTION';
            l_values(l_index) := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS',
                                                         l_pat_soc_attributes_row.marital_status,
                                                         i_lang);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ADDRESS';
            l_values(l_index) := l_pat_soc_attributes_row.address;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.LOCATION';
            l_values(l_index) := l_pat_soc_attributes_row.location;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.DISTRICT';
            l_values(l_index) := l_pat_soc_attributes_row.district;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ZIP_CODE';
            l_values(l_index) := l_pat_soc_attributes_row.zip_code;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.NUM_MAIN_CONTACT';
            l_values(l_index) := l_pat_soc_attributes_row.num_main_contact;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.NUM_CONTACT';
            l_values(l_index) := l_pat_soc_attributes_row.num_contact;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.FLG_JOB_STATUS';
            l_values(l_index) := l_pat_soc_attributes_row.flg_job_status;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.FLG_JOB_STATUS.DESCRIPTION';
            l_values(l_index) := pk_sysdomain.get_domain_no_avail('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS',
                                                                  l_pat_soc_attributes_row.flg_job_status,
                                                                  i_lang);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ID_COUNTRY_NATION';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_country_nation);
            l_index := l_index + 1;
            IF (l_pat_soc_attributes_row.id_country_nation IS NOT NULL)
            THEN
                SELECT *
                  INTO l_country_row
                  FROM country
                 WHERE id_country = l_pat_soc_attributes_row.id_country_nation;
                l_keys(l_index) := l_table_name || '.ID_COUNTRY_NATION.DESCRIPTION';
                l_values(l_index) := pk_translation.get_translation(i_lang, l_country_row.code_country);
                l_index := l_index + 1;
            END IF;
            l_keys(l_index) := l_table_name || '.ID_COUNTRY_ADDRESS';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_country_address);
            l_index := l_index + 1;
            IF (l_pat_soc_attributes_row.id_country_address IS NOT NULL)
            THEN
                SELECT *
                  INTO l_country_row
                  FROM country
                 WHERE id_country = l_pat_soc_attributes_row.id_country_address;
                l_keys(l_index) := l_table_name || '.ID_COUNTRY_ADDRESS.DESCRIPTION';
                l_values(l_index) := pk_translation.get_translation(i_lang, l_country_row.code_country);
                l_index := l_index + 1;
            END IF;
            l_keys(l_index) := l_table_name || '.ID_SCHOLARSHIP';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_scholarship);
            l_index := l_index + 1;
            IF (l_pat_soc_attributes_row.id_scholarship IS NOT NULL)
            THEN
                l_keys(l_index) := l_table_name || '.ID_SCHOLARSHIP.DESCRIPTION';
                l_values(l_index) := pk_translation.get_translation(i_lang,
                                                                    'SCHOLARSHIP.CODE_SCHOLARSHIP.' ||
                                                                    l_pat_soc_attributes_row.id_scholarship);
                l_index := l_index + 1;
            END IF;
            l_keys(l_index) := l_table_name || '.ID_RELIGION';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_religion);
            l_index := l_index + 1;
            IF (l_pat_soc_attributes_row.id_religion IS NOT NULL)
            THEN
                l_keys(l_index) := l_table_name || '.ID_RELIGION.DESCRIPTION';
                l_values(l_index) := pk_translation.get_translation(i_lang,
                                                                    'RELIGION.CODE_RELIGION.' ||
                                                                    l_pat_soc_attributes_row.id_religion);
                l_index := l_index + 1;
            END IF;
            l_keys(l_index) := l_table_name || '.MOTHER_NAME';
            l_values(l_index) := l_pat_soc_attributes_row.mother_name;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.FATHER_NAME';
            l_values(l_index) := l_pat_soc_attributes_row.father_name;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ID_ISENCAO';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_isencao);
            l_index := l_index + 1;
            IF (l_pat_soc_attributes_row.id_isencao IS NOT NULL)
            THEN
                l_keys(l_index) := l_table_name || '.ID_ISENCAO.DESCRIPTION';
                l_values(l_index) := pk_translation.get_translation(i_lang,
                                                                    'ISENCAO.CODE_ISENCAO.' ||
                                                                    l_pat_soc_attributes_row.id_isencao);
                l_index := l_index + 1;
            END IF;
            l_keys(l_index) := l_table_name || '.ID_INSTITUTION';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_institution);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.DT_ISENCAO';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.dt_isencao, g_date_convert_pattern);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.DT_ISENCAO.DESCRIPTION';
            l_values(l_index) := pk_date_utils.dt_chr(i_lang, l_pat_soc_attributes_row.dt_isencao, i_prof);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.INE_LOCATION';
            l_values(l_index) := l_pat_soc_attributes_row.ine_location;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ID_LANGUAGE';
            l_values(l_index) := to_char(l_pat_soc_attributes_row.id_language);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.NOTES';
            l_values(l_index) := l_pat_soc_attributes_row.notes;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.CONTACT_NUMBER_3';
            l_values(l_index) := l_pat_soc_attributes_row.contact_number_3;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.CONTACT_NUMBER_4';
            l_values(l_index) := l_pat_soc_attributes_row.contact_number_4;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.BIRTH_PLACE';
            l_values(l_index) := l_pat_soc_attributes_row.birth_place;
            l_index := l_index + 1;
        
            l_keys(l_index) := l_table_name || '.DESC_GEO_STATE';
            l_values(l_index) := l_pat_soc_attributes_row.desc_geo_state;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.NUM_CONTRIB';
            l_values(l_index) := l_pat_soc_attributes_row.num_contrib;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.FLG_MIGRATOR';
            l_values(l_index) := l_pat_soc_attributes_row.flg_migrator;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.FLG_MIGRATOR.DESCRIPTION';
        
            l_values(l_index) := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_MIGRATOR',
                                                         l_pat_soc_attributes_row.flg_migrator,
                                                         i_lang);
            l_index := l_index + 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- do nothing, no info availble
        END;
    
        -- VALUES FROM PAT_JOB TABLE 
        g_error := 'GET FROM PAT_JOB';
        BEGIN
            -- this block is used to control non-existence of pat_job info.
            SELECT *
              INTO l_pat_job_row
              FROM pat_job
             WHERE id_patient = i_id_patient
               AND dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                        FROM pat_job p1
                                       WHERE p1.id_patient = i_id_patient);
        
            l_table_name := 'PAT_JOB';
            l_keys(l_index) := l_table_name || '.ID_PAT_JOB';
            l_values(l_index) := l_pat_job_row.id_pat_job;
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ID_OCCUPATION';
            l_values(l_index) := to_char(l_pat_job_row.id_occupation);
            l_index := l_index + 1;
            IF (l_pat_job_row.id_occupation IS NOT NULL)
            THEN
                --  js, 2007-12-28: Se id registado retorna ID_OCCUPATION.DESCRIPTION E OCCUPATION_DESC 
                l_occupation_desc := pk_translation.get_translation(i_lang,
                                                                    'OCCUPATION.CODE_OCCUPATION.' ||
                                                                    l_pat_job_row.id_occupation);
                l_keys(l_index) := l_table_name || '.ID_OCCUPATION.DESCRIPTION';
                l_values(l_index) := l_occupation_desc;
                l_index := l_index + 1;
                l_keys(l_index) := l_table_name || '.OCCUPATION_DESC';
                l_values(l_index) := l_occupation_desc;
                l_index := l_index + 1;
            ELSE
                -- lg 2007 Mar 27 profissão em texto livre l_keys(l_index) := l_table_name || '.ID_OCCUPATION.DESCRIPTION';
                l_keys(l_index) := l_table_name || '.OCCUPATION_DESC';
                l_values(l_index) := l_pat_job_row.occupation_desc;
                l_index := l_index + 1;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- do nothing, no info availble
        END;
    
        -- VALUES FROM PAT_CLI_ATTRIBUTES TABLE
        BEGIN
            g_error := 'GET FROM PAT_CLI_ATTRIBUTES';
            SELECT *
              INTO l_pat_cli_attributes_row
              FROM pat_cli_attributes
             WHERE id_patient = i_id_patient;
            l_table_name := 'PAT_CLI_ATTRIBUTES';
            l_keys(l_index) := l_table_name || '.ID_PAT_CLI_ATTRIBUTES';
            l_values(l_index) := to_char(l_pat_cli_attributes_row.id_pat_cli_attributes);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.ID_RECM';
            l_values(l_index) := l_pat_cli_attributes_row.id_recm;
            l_index := l_index + 1;
            IF (l_pat_cli_attributes_row.id_recm IS NOT NULL)
            THEN
                SELECT *
                  INTO l_recm_row
                  FROM recm
                 WHERE id_recm = l_pat_cli_attributes_row.id_recm;
                -- LG 22-JAN-2007 
                l_aux_varchar := pk_translation.get_translation(i_lang, l_recm_row.code_recm);
                l_keys(l_index) := l_table_name || '.ID_RECM.DESCRIPTION';
                -- LG 22-JAN-2007 
                IF (l_aux_varchar IS NULL)
                THEN
                    l_values(l_index) := l_recm_row.flg_recm;
                ELSE
                    l_values(l_index) := l_recm_row.flg_recm || ' - ' || l_aux_varchar;
                END IF;
                l_index := l_index + 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- do nothing, no info available
        END;
    
        -- VALUES FROM CLIN_RECORD TABLE
        BEGIN
            g_error := 'GET FROM CLIN_RECORD';
            SELECT *
              INTO l_clin_record_row
              FROM clin_record
             WHERE id_patient = i_id_patient
               AND id_institution = i_prof.institution
               AND rownum < 2;
            l_table_name := 'CLIN_RECORD';
            l_keys(l_index) := l_table_name || '.ID_CLIN_RECORD';
            l_values(l_index) := to_char(l_clin_record_row.id_clin_record);
            l_index := l_index + 1;
            l_keys(l_index) := l_table_name || '.NUM_CLIN_RECORD';
            l_values(l_index) := l_clin_record_row.num_clin_record;
            l_index := l_index + 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- do nothing, no info availble
        END;
    
        -- VALUES FROM PAT_HEALTH_PLAN TABLE
        -- LG:2007-JAN-11 CHECK IF METADATA EXISTS. IS NOT NULL OPERATOR IS NOT ALLOWED
        BEGIN
            l_aux             := TRUE;
            l_column_metadata := l_screen_metadata('PAT_HEALTH_PLAN.NUM_HEALTH_PLAN');
        EXCEPTION
            WHEN no_data_found THEN
                l_aux := FALSE;
        END;
    
        -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
        l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
        IF l_id_health_plan IS NULL
        THEN
            g_error := 'SYS_CONFIG PARAMETER ''ADT_NATIONAL_HEALTH_PLAN_ID'' NOT DEFINED FOR INSTITUTION ' ||
                       i_prof.institution || ' AND SOFTWARE ' || i_prof.software;
            RAISE internal_exception;
        END IF;
    
        -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
        -- IF (l_aux AND l_column_metadata.health_plan_flg_type IS NOT NULL)
        IF (l_aux)
        THEN
            -- SCREEN HAS PAT_HEALTH_PLAN INFO
            -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
            -- l_health_plan_flg_type := l_column_metadata.health_plan_flg_type;
            -- g_error                := 'FIND HEALTH_PLAN.ID_HEALTH_PLAN';
            BEGIN
                -- JS, 2007-10-23: Parametro flg_type no xml_template substituido pelo id sys_config 'ADT_NATIONAL_HEALTH_PLAN_ID'.
                --SELECT hp.id_health_plan
                --  INTO l_id_health_plan
                --  FROM health_plan hp
                --  JOIN health_plan_instit hpi ON hp.id_health_plan = hpi.id_health_plan
                -- WHERE hpi.id_health_plan = hp.id_health_plan
                --   AND hp.flg_type = l_health_plan_flg_type
                --   AND hpi.id_institution = i_prof.institution;
            
                -- Se é software P1
                IF i_prof.software = l_soft
                THEN
                    g_error := 'GET FROM PAT_HEALTH_PLAN';
                    SELECT *
                      INTO l_pat_health_plan_row
                      FROM pat_health_plan
                     WHERE id_patient = i_id_patient
                       AND id_health_plan = l_id_health_plan
                       AND id_institution IS NULL;
                ELSE
                    g_error := 'GET FROM PAT_HEALTH_PLAN';
                    SELECT *
                      INTO l_pat_health_plan_row
                      FROM pat_health_plan
                     WHERE id_patient = i_id_patient
                       AND id_health_plan = l_id_health_plan
                       AND id_institution = i_prof.institution;
                END IF;
            
                l_table_name := 'PAT_HEALTH_PLAN';
                l_keys(l_index) := l_table_name || '.NUM_HEALTH_PLAN';
                l_values(l_index) := l_pat_health_plan_row.num_health_plan;
                l_index := l_index + 1;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- do nothing, no info availble
            END;
        END IF;
        g_error := 'GET FROM CLIN_RECORD100';
    
        -- VALUES FROM DOC_EXTERNAL TABLE
        -- CHECK IF METADATA EXISTS. IS NOT NULL OPERATOR IS NOT ALLOWED
        BEGIN
            l_aux             := TRUE;
            l_column_metadata := l_screen_metadata('DOC_EXTERNAL.NUM_DOC');
        EXCEPTION
            WHEN no_data_found THEN
                l_aux := FALSE;
        END;
        IF (l_aux)
        THEN
            -- SCREEN HAS DOC_EXTERNAL INFO
            g_error := 'FIND DOC_EXTERNAL.NUM_DOC';
            IF NOT pk_doc_internal.get_doc_identific_internal(i_lang,
                                                              i_prof,
                                                              i_id_patient,
                                                              i_btn,
                                                              l_doc_external_row,
                                                              o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            IF (l_doc_external_row.id_doc_external IS NOT NULL)
            THEN
                l_table_name := 'DOC_EXTERNAL';
                l_keys(l_index) := l_table_name || '.NUM_DOC';
                l_values(l_index) := l_doc_external_row.num_doc;
                l_index := l_index + 1;
            
            END IF;
        END IF;
    
        -- JS - O parametro do trim é o numero de elementos a eliminar a partir do fim
        l_keys.trim(100 - l_index + 1);
        l_values.trim(100 - l_index + 1);
        o_keys   := l_keys;
        o_values := l_values;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_ATTRIBUTES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_patient_attributes;
    --
    /**********************************************************************************************
    * Criar ou actualizar a história do paciente : Médica, Cirúrgica, Familiar e Social 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id
    * @param i_dt_pat_history         
    * @param i_id_diagnosis           diagnosis id
    * @param i_flg_status             Estado.Se o acrónimo da história = HMC, então os estados serão estes:D - despiste(ampulheta)
                                                                                                           F - confirmar
                                                                                                           R - declinar(-)
                                                                                                           B - Diagnóstico base
                                      Se o acrónimo da história = HFS, então os estados serão estes:A - Activo             
    * @param i_desc_diag              description diagnosis 
    * @param i_notes                  notes
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param i_prof_cat_type          professional category
    * @param i_dt_begin_hist          Data aproximada de início da história do paciente. 
    * @param i_dt_end_hist            Data fim aproximada da história do paciente.
    * @param i_epis                   Episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * @author                         Pedro Santos
    * @version                        2.4.3-Denormalized
    * @since                          2008/10/30  
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5    
    **********************************************************************************************/
    FUNCTION create_pat_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_dt_pat_history IN pat_history.dt_pat_history_tstz%TYPE,
        i_id_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_flg_status     IN pat_history.flg_status%TYPE,
        i_desc_diag      IN pat_history.desc_diagnosis%TYPE,
        i_notes          IN pat_history.notes%TYPE,
        i_flg_type_hist  IN pat_history.flg_type_hist%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_dt_begin_hist  IN VARCHAR2,
        i_dt_end_hist    IN VARCHAR2,
        i_epis           IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next        pat_history.id_pat_history%TYPE;
        l_year_begin  pat_habit.year_begin%TYPE;
        l_month_begin pat_habit.month_begin%TYPE;
        l_year_end    pat_habit.year_begin%TYPE;
        l_month_end   pat_habit.month_begin%TYPE;
        l_day_end     pat_habit.day_begin%TYPE;
        l_rowids      table_varchar;
        l_flg_type    pat_history.flg_type%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET BEGIN DATE';
        IF i_dt_begin_hist IS NOT NULL
        THEN
            l_month_begin := to_number(substr(i_dt_begin_hist, 1, instr(i_dt_begin_hist, '/') - 1));
            l_year_begin  := substr(i_dt_begin_hist, instr(i_dt_begin_hist, '/') + 1);
        END IF;
        --
        g_error := 'GET END DATE';
        IF i_dt_end_hist IS NOT NULL
        THEN
            IF instr(i_dt_end_hist, '/') = 0
            THEN
                l_year_end := i_dt_end_hist;
            ELSE
                l_year_end := to_number(substr(i_dt_end_hist, 1, instr(i_dt_end_hist, '/') - 1));
            
                IF instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1), '/') = 0
                THEN
                    l_month_end := substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1);
                ELSE
                    l_month_end := to_number(substr(substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1),
                                                    1,
                                                    instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1), '/') - 1));
                    l_day_end   := to_number(substr(substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1),
                                                    instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '/') + 1), '/') + 1));
                END IF;
            END IF;
        END IF;
        --  
        g_error    := 'GET SEQ_PAT_HISTORY.NEXTVAL';
        l_next     := ts_pat_history.next_key();
        l_flg_type := CASE i_id_diagnosis
                          WHEN NULL THEN
                           NULL
                          ELSE
                           g_diag_type_p
                      END;
        --   
        g_error := 'INSERT PAT_HISTORY (1)';
        ts_pat_history.ins(id_pat_history_in      => l_next,
                           id_patient_in          => i_id_patient,
                           dt_pat_history_tstz_in => g_sysdate_tstz,
                           id_diagnosis_in        => i_id_diagnosis,
                           id_prof_writes_in      => i_prof.id,
                           flg_status_in          => i_flg_status,
                           flg_type_in            => l_flg_type, --decode(i_id_diagnosis, NULL, NULL, g_diag_type_p),
                           desc_diagnosis_in      => i_desc_diag,
                           notes_in               => i_notes,
                           flg_type_hist_in       => i_flg_type_hist,
                           year_begin_in          => l_year_begin,
                           month_begin_in         => l_month_begin,
                           year_end_in            => l_year_end,
                           month_end_in           => l_month_end,
                           day_end_in             => l_day_end,
                           adw_last_update_in     => g_sysdate,
                           id_episode_in          => i_epis,
                           rows_out               => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-PAT_HISTORY';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HISTORY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --                     
        --Actualiza informação sobre a primeira observação      
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PAT_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Cancelar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_pat_history         
    * @param i_notes                  notes
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param i_prof_cat_type          professional category
    * @param i_dt_end_hist            Data fim aproximada da história do paciente.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION cancel_pat_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_history IN pat_history.id_pat_history%TYPE,
        i_notes          IN pat_history.notes%TYPE,
        i_flg_type_hist  IN pat_history.flg_type_hist%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_dt_end_hist    IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient patient.id_patient%TYPE;
        l_year_end   pat_habit.year_begin%TYPE;
        l_month_end  pat_habit.month_begin%TYPE;
        l_day_end    pat_habit.day_begin%TYPE;
        --
        CURSOR c_pat_hist IS
            SELECT id_patient
              FROM pat_history
             WHERE id_pat_history = i_id_pat_history
               AND flg_status != g_ph_flg_status_ca;
    
        e_notfound EXCEPTION;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se a história já está cancelada
        g_error := 'OPEN C_PAT_HIST';
        OPEN c_pat_hist;
        FETCH c_pat_hist
            INTO l_id_patient;
        g_found := c_pat_hist%FOUND;
        CLOSE c_pat_hist;
        --
        IF NOT g_found
        THEN
            --Não foi encontrada a história a cancelar(Ou não existe ou já foi cancelada)
            RAISE e_notfound;
        END IF;
        --
        IF i_dt_end_hist IS NOT NULL
        THEN
            IF instr(i_dt_end_hist, '-') = 0
            THEN
                l_year_end := i_dt_end_hist;
            ELSE
                l_year_end := to_number(substr(i_dt_end_hist, 1, instr(i_dt_end_hist, '-') - 1));
                -- 
                IF instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1), '-') = 0
                THEN
                    l_month_end := substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1);
                ELSE
                    l_month_end := to_number(substr(substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1),
                                                    1,
                                                    instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1), '-') - 1));
                    l_day_end   := to_number(substr(substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1),
                                                    instr(substr(i_dt_end_hist, instr(i_dt_end_hist, '-') + 1), '-') + 1));
                END IF;
            END IF;
        END IF;
        --
        g_error := 'CALL PK_PATIENT.SET_PAT_HISTORY_HIST';
        IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_patient    => l_id_patient,
                                               i_id_pat_hist   => i_id_pat_history,
                                               i_prof_cat_type => i_prof_cat_type,
                                               o_error         => o_error)
        THEN
            RAISE e_call_error;
        END IF;
        --
        --Actualiza  história do paciente com a informação do cancelamento
        g_error := 'UPDATE PAT_HISTORY';
        UPDATE pat_history
           SET dt_cancel_tstz = g_sysdate_tstz,
               id_prof_cancel = i_prof.id,
               note_cancel    = i_notes,
               year_end       = l_year_end,
               month_end      = l_month_end,
               day_end        = l_day_end,
               flg_status     = g_ph_flg_status_ca
         WHERE id_pat_history = i_id_pat_history;
        --                     
        --Actualiza informação sobre a primeira observação      
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => l_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_notfound THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PATIENT_M013',
                                              pk_message.get_message(i_lang, 'PATIENT_M013'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAT_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param o_past_hist              Listar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_pat_history
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_flg_type_hist IN VARCHAR2,
        o_pat_hist      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_PAT_HIST';
        OPEN o_pat_hist FOR
            SELECT ph.id_pat_history,
                   ph.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ph.desc_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis,
                   ph.flg_status status_pat_hist,
                   ph.id_prof_writes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional) prof_name_ampul, -- ampulheta
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_pat_history_tstz, i_prof) date_phist,
                   pk_date_utils.dt_chr_tsz(i_lang, ph.dt_pat_history_tstz, i_prof) date_target_phist,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_pat_history_tstz, i_prof.institution, i_prof.software) hour_target_phist,
                   ph.id_prof_confirmed, --confirmado
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pco.id_professional) prof_name_conf,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_confirmed_tstz, i_prof) date_conf,
                   pk_date_utils.dt_chr_tsz(i_lang, ph.dt_confirmed_tstz, i_prof) date_target_conf,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_confirmed_tstz, i_prof.institution, i_prof.software) hour_target_conf,
                   ph.id_prof_cancel, --cancelou
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pca.id_professional) prof_name_cancel,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang, ph.dt_cancel_tstz, i_prof) date_target_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_cancel,
                   ph.id_prof_rulled_out, -- declinou
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional) prof_name_rulled_out,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_rulled_out_tstz, i_prof) date_rulled_out,
                   pk_date_utils.dt_chr_tsz(i_lang, ph.dt_rulled_out_tstz, i_prof) date_target_rulled,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_rulled_out_tstz, i_prof.institution, i_prof.software) hour_target_rulled,
                   ph.id_prof_base, -- base
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pb.id_professional) prof_name_base,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_base_tstz, i_prof) date_base,
                   pk_date_utils.dt_chr_tsz(i_lang, ph.dt_base_tstz, i_prof) date_target_base,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_base_tstz, i_prof.institution, i_prof.software) hour_target_base,
                   sd.img_name icon_status,
                   decode(ph.flg_status,
                          g_ph_flg_status_d,
                          ph.dt_pat_history_tstz,
                          g_ph_flg_status_a,
                          ph.dt_pat_history_tstz,
                          g_ph_flg_status_co,
                          ph.dt_confirmed_tstz,
                          g_ph_flg_status_ca,
                          ph.dt_cancel_tstz,
                          g_ph_flg_status_b,
                          ph.dt_base_tstz,
                          ph.dt_rulled_out_tstz) date_order,
                   ph.notes,
                   ph.note_cancel,
                   ph.flg_type_hist,
                   decode(ph.flg_type_hist,
                          g_ph_type_hist_m,
                          pk_message.get_message(i_lang, 'PAT_HISTORY_M001'),
                          g_ph_type_hist_c,
                          pk_message.get_message(i_lang, 'PAT_HISTORY_M002'),
                          g_ph_type_hist_f,
                          pk_message.get_message(i_lang, 'PAT_HISTORY_M003'),
                          pk_message.get_message(i_lang, 'PAT_HISTORY_M004')) desc_type_hist
              FROM pat_history  ph,
                   diagnosis    d,
                   professional pco, --confirmou
                   professional pca, --cancelou
                   professional pr, --rulled
                   professional pd, --despiste
                   professional pb, --base
                   sys_domain   sd
             WHERE ph.id_patient = i_id_patient
               AND d.id_diagnosis = ph.id_diagnosis(+)
               AND pco.id_professional(+) = ph.id_prof_confirmed
               AND pca.id_professional(+) = ph.id_prof_cancel
               AND pr.id_professional(+) = ph.id_prof_rulled_out
               AND pd.id_professional(+) = ph.id_prof_writes
               AND pb.id_professional(+) = ph.id_prof_base
               AND sd.id_language = i_lang
               AND sd.code_domain = g_pat_hist_status
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val = ph.flg_status
             ORDER BY pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY.FLG_STATUS', ph.flg_status), date_order DESC;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_pat_hist);
            RETURN FALSE;
    END get_pat_history;
    --
    /**********************************************************************************************
    * Actualizar o histório da histórica Médica/Cirúrgica/Familiar/Social do paciente sempre que é alterado o seu estado  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_id_pat_hist            ID da história do paciente
    * @param i_prof_cat_type          professional category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION set_pat_history_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_pat_hist   IN pat_history.id_pat_history%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next pat_history_hist.id_pat_history_hist%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET SEQ_PAT_HISTORY_HIST.NEXTVAL';
        SELECT seq_pat_history_hist.nextval
          INTO l_next
          FROM dual;
        --      
        g_error := 'INSERT PAT_HISTORY_HIST';
        INSERT INTO pat_history_hist
            (id_pat_history_hist,
             id_pat_history,
             id_professional,
             dt_creation_tstz,
             flg_status,
             flg_type_diag,
             flg_type_hist,
             notes,
             adw_last_update)
            SELECT l_next,
                   i_id_pat_hist,
                   decode(flg_status,
                          g_ph_flg_status_ca,
                          id_prof_cancel,
                          g_ph_flg_status_d,
                          id_prof_writes,
                          g_ph_flg_status_co,
                          id_prof_confirmed,
                          g_ph_flg_status_r,
                          id_prof_rulled_out,
                          g_ph_flg_status_a,
                          id_prof_writes,
                          id_prof_base),
                   decode(flg_status,
                          g_ph_flg_status_ca,
                          dt_cancel_tstz,
                          g_ph_flg_status_d,
                          dt_pat_history_tstz,
                          g_ph_flg_status_co,
                          dt_confirmed_tstz,
                          g_ph_flg_status_r,
                          dt_rulled_out_tstz,
                          g_ph_flg_status_a,
                          dt_pat_history_tstz,
                          dt_base_tstz),
                   flg_status,
                   flg_type,
                   flg_type_hist,
                   decode(flg_status, g_ph_flg_status_ca, note_cancel, notes),
                   g_sysdate
              FROM pat_history
             WHERE id_pat_history = i_id_pat_hist;
        --  
        COMMIT;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
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
                                              'SET_PAT_HISTORY_HIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Alterar o estado de uma história médica/cirúrgica/familiar/social de um paciente  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_id_pat_hist            ID da história do paciente
    * @param i_flg_status             status    
    * @param i_prof_cat_type          professional category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION set_pat_hist_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_pat_hist   IN pat_history.id_pat_history%TYPE,
        i_flg_status    IN pat_history.flg_status%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status pat_history.flg_status%TYPE;
        l_flg_type   pat_history.flg_type%TYPE;
        l_pat_hist   pat_history.id_pat_history%TYPE;
        l_id_prof    professional.id_professional%TYPE;
        l_date       TIMESTAMP WITH LOCAL TIME ZONE;
        l_notes      pat_history.notes%TYPE;
        --
        CURSOR c_pat_hist IS
            SELECT id_pat_history
              FROM pat_history
             WHERE id_pat_history = i_id_pat_hist
               AND flg_status = g_ph_flg_status_b;
    
        CURSOR c_pat_hist_h(l_id_pat_hist IN pat_history.id_pat_history%TYPE) IS
            SELECT flg_status, flg_type_diag, id_professional, dt_creation_tstz, notes
              FROM pat_history_hist
             WHERE id_pat_history = l_id_pat_hist
               AND id_pat_history_hist = (SELECT MAX(ph1.id_pat_history_hist)
                                            FROM pat_history_hist ph1
                                           WHERE ph1.id_pat_history = l_id_pat_hist);
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        IF i_flg_status = g_ph_flg_status_d
        THEN
            -- DESPISTAR (em investigação)
            -- Actualizar o histórico
            g_error := 'CALL TO PK_PATIENT.SET_PAT_HISTORY_HIST(1)';
            IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_patient    => i_id_patient,
                                                   i_id_pat_hist   => i_id_pat_hist,
                                                   i_prof_cat_type => i_prof_cat_type,
                                                   o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            --      
            g_error := 'UPDATE PAT_HISTORY(1): ' || i_flg_status;
            UPDATE pat_history
               SET id_prof_rulled_out  = NULL,
                   dt_rulled_out_tstz  = NULL,
                   flg_status          = i_flg_status,
                   flg_type            = g_diag_type_p,
                   id_prof_confirmed   = NULL,
                   dt_confirmed_tstz   = NULL,
                   id_prof_cancel      = NULL,
                   dt_cancel_tstz      = NULL,
                   id_prof_base        = NULL,
                   dt_base_tstz        = NULL,
                   id_prof_writes      = i_prof.id,
                   dt_pat_history_tstz = g_sysdate_tstz
             WHERE id_pat_history = i_id_pat_hist;
        
        ELSIF i_flg_status = g_ph_flg_status_r
        THEN
            -- DECLINAR
            -- Actualizar o histórico
            g_error := 'CALL TO Pk_Patient.SET_PAT_HISTORY_HIST(2)';
            IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_patient    => i_id_patient,
                                                   i_id_pat_hist   => i_id_pat_hist,
                                                   i_prof_cat_type => i_prof_cat_type,
                                                   o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            --      
            g_error := 'UPDATE PAT_HISTORY(2): ' || i_flg_status;
            UPDATE pat_history
               SET id_prof_rulled_out = i_prof.id,
                   dt_rulled_out_tstz = g_sysdate_tstz,
                   flg_status         = i_flg_status,
                   flg_type           = g_diag_type_p,
                   id_prof_confirmed  = NULL,
                   dt_confirmed_tstz  = NULL,
                   id_prof_cancel     = NULL,
                   dt_cancel_tstz     = NULL,
                   id_prof_base       = NULL,
                   dt_base_tstz       = NULL
             WHERE id_pat_history = i_id_pat_hist;
        
        ELSIF i_flg_status = g_ph_flg_status_co
        THEN
            -- CONFIRMAR
            -- Actualizar o histórico
            g_error := 'CALL TO Pk_Patient.SET_PAT_HISTORY_HIST(2)';
            IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_patient    => i_id_patient,
                                                   i_id_pat_hist   => i_id_pat_hist,
                                                   i_prof_cat_type => i_prof_cat_type,
                                                   o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            --
            g_error := 'UPDATE PAT_HISTORY(3): ' || i_flg_status;
            UPDATE pat_history
               SET id_prof_confirmed  = i_prof.id,
                   dt_confirmed_tstz  = g_sysdate_tstz,
                   flg_status         = i_flg_status,
                   flg_type           = g_diag_type_p,
                   id_prof_cancel     = NULL,
                   dt_cancel_tstz     = NULL,
                   id_prof_rulled_out = NULL,
                   dt_rulled_out_tstz = NULL,
                   id_prof_base       = NULL,
                   dt_base_tstz       = NULL
             WHERE id_pat_history = i_id_pat_hist;
        
        ELSIF i_flg_status = g_ph_flg_status_b
        THEN
            dbms_output.put_line('I_FLG_STATUS: ' || i_flg_status);
            -- Diagnóstico BASE
            -- Verificar se existem diagnósticos BASE para este episódio
            g_error := 'GET CURSOR C_PAT_HIST';
            OPEN c_pat_hist;
            FETCH c_pat_hist
                INTO l_pat_hist;
            g_found := c_pat_hist%FOUND;
            CLOSE c_pat_hist;
            --
            dbms_output.put_line('L_PAT_HIST: ' || l_pat_hist);
            --
            IF g_found
            THEN
                dbms_output.put_line('G_FOUND');
                -- Esta história do paciente tem diagnósticos BASE
                g_error := 'GET CURSOR C_PAT_HIST_H';
                OPEN c_pat_hist_h(l_pat_hist);
                FETCH c_pat_hist_h
                    INTO l_flg_status, l_flg_type, l_id_prof, l_date, l_notes;
                g_found := c_pat_hist_h%FOUND;
                CLOSE c_pat_hist_h;
                --
                dbms_output.put_line('***********************************************');
                dbms_output.put_line(l_flg_status);
                dbms_output.put_line(l_flg_type);
                dbms_output.put_line(l_id_prof);
                dbms_output.put_line(l_date);
                dbms_output.put_line(l_notes);
                dbms_output.put_line('***********************************************');
                --
                -- Actualizar o histórico com o Diagnóstico BASE já existente
                g_error := 'CALL TO Pk_Patient.SET_PAT_HISTORY_HIST(3)';
                IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_patient    => i_id_patient,
                                                       i_id_pat_hist   => l_pat_hist,
                                                       i_prof_cat_type => i_prof_cat_type,
                                                       o_error         => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
                --
                g_error := 'UPDATE PAT_HISTORY(3)';
                dbms_output.put_line(g_error);
                UPDATE pat_history
                   SET id_prof_confirmed  = decode(l_flg_status, g_ph_flg_status_co, l_id_prof, NULL),
                       dt_confirmed_tstz  = decode(l_flg_status, g_ph_flg_status_co, l_date, NULL),
                       flg_status         = l_flg_status,
                       flg_type           = l_flg_type,
                       id_prof_cancel     = decode(l_flg_status, g_ph_flg_status_ca, l_id_prof, NULL),
                       dt_cancel_tstz     = decode(l_flg_status, g_ph_flg_status_ca, l_date, NULL),
                       id_prof_rulled_out = decode(l_flg_status, g_ph_flg_status_r, l_id_prof, NULL),
                       dt_rulled_out_tstz = decode(l_flg_status, g_ph_flg_status_r, l_date, NULL),
                       id_prof_base       = NULL,
                       dt_base_tstz       = NULL
                 WHERE id_pat_history = l_pat_hist;
                --
                COMMIT;
                --
                -- Actualizar o histórico com o Diagnóstico a ser alterado
                g_error := 'CALL TO Pk_Patient.SET_PAT_HISTORY_HIST(4)';
                IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_patient    => i_id_patient,
                                                       i_id_pat_hist   => i_id_pat_hist,
                                                       i_prof_cat_type => i_prof_cat_type,
                                                       o_error         => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
                --
                g_error := 'UPDATE PAT_HISTORY(4)';
                dbms_output.put_line(g_error);
                UPDATE pat_history
                   SET id_prof_confirmed  = NULL,
                       dt_confirmed_tstz  = NULL,
                       flg_status         = i_flg_status,
                       flg_type           = g_diag_type_b,
                       id_prof_cancel     = NULL,
                       dt_cancel_tstz     = NULL,
                       id_prof_rulled_out = NULL,
                       dt_rulled_out_tstz = NULL,
                       id_prof_base       = i_prof.id,
                       dt_base_tstz       = g_sysdate_tstz
                 WHERE id_pat_history = i_id_pat_hist;
                --
                COMMIT;
            ELSE
                -- Este episódio não tem diagnósticos BASE
                -- Actualizar o histórico
                g_error := 'CALL TO Pk_Patient.SET_PAT_HISTORY_HIST(5)';
                IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_patient    => i_id_patient,
                                                       i_id_pat_hist   => i_id_pat_hist,
                                                       i_prof_cat_type => i_prof_cat_type,
                                                       o_error         => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
                --
                g_error := 'UPDATE PAT_HISTORY(5): ' || i_flg_status;
                UPDATE pat_history
                   SET id_prof_base       = i_prof.id,
                       dt_base_tstz       = g_sysdate_tstz,
                       flg_status         = i_flg_status,
                       flg_type           = g_diag_type_b,
                       id_prof_cancel     = NULL,
                       dt_cancel_tstz     = NULL,
                       id_prof_rulled_out = NULL,
                       dt_rulled_out_tstz = NULL,
                       id_prof_confirmed  = NULL,
                       dt_confirmed_tstz  = NULL
                 WHERE id_pat_history = i_id_pat_hist;
            END IF;
            --   
        ELSIF i_flg_status = g_ph_flg_status_ca
        THEN
            -- CANCELAR
            -- Actualizar o histórico
            g_error := 'CALL TO PK_PATIENT.SET_PAT_HISTORY_HIST(6)';
            IF NOT pk_patient.set_pat_history_hist(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_patient    => i_id_patient,
                                                   i_id_pat_hist   => i_id_pat_hist,
                                                   i_prof_cat_type => i_prof_cat_type,
                                                   o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            --
            g_error := 'UPDATE PAT_HISTORY(6): ' || i_flg_status;
            UPDATE pat_history
               SET id_prof_cancel     = i_prof.id,
                   dt_cancel_tstz     = g_sysdate_tstz,
                   flg_status         = i_flg_status,
                   flg_type           = g_diag_type_p,
                   id_prof_confirmed  = NULL,
                   dt_confirmed_tstz  = NULL,
                   id_prof_rulled_out = NULL,
                   dt_rulled_out_tstz = NULL,
                   id_prof_base       = NULL,
                   dt_base_tstz       = NULL
             WHERE id_pat_history = i_id_pat_hist;
        END IF;
        --  
        COMMIT;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
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
                                              'SET_PAT_HIST_DIAG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/19 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    *
    * UPDATED: ALERT-122457 - Type: BUG and CONFIG Area: Wristbands ALERT EDIS 2.5.0.7.8 Expec (truncated)
    * @author  Alexandre Santos
    * @date    16-09-2010
    * @version 2.8.0.7.8
    **********************************************************************************************/
    FUNCTION get_barcode_print
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_config            IN sys_config.id_sys_config%TYPE,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_barcode_nec       OUT VARCHAR2,
        o_barcode_pat_n     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_type doc_type.id_doc_type%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DOC_TYPE_PID',
                                                                        i_prof_inst => i_prof.institution,
                                                                        i_prof_soft => i_prof.software);
    
        CURSOR c_patient IS
            SELECT pk_date_utils.date_hour_chr_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_admission,
                   pk_barcode.get_pat_barcode(i_lang, i_prof, e.id_episode, e.id_patient, e.barcode, cr.num_clin_record) barcode,
                   pk_translation.get_translation(i_lang, ec.code_external_cause) desc_external_cause,
                   REPLACE(pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode), '"', '') name,
                   pat.name pat_name,
                   pk_patient.get_gender(i_lang, pat.gender) gender,
                   pat.dt_birth,
                   ees.value,
                   pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution) id_epis_software,
                   cr.num_clin_record,
                   pes.value p_id,
                   nvl(psa.national_health_number,
                       (SELECT res.num_doc
                          FROM (SELECT de.num_doc,
                                       decode(de.id_doc_type,
                                              pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software),
                                              2,
                                              pk_sysconfig.get_config('DOC_TYPE_ID2', i_prof.institution, i_prof.software),
                                              1,
                                              0) rank_sys_config
                                  FROM doc_external de
                                 INNER JOIN doc_type dt
                                    ON (dt.id_doc_type = de.id_doc_type)
                                 WHERE de.id_episode = i_episode
                                 ORDER BY rank_sys_config DESC, dt.rank DESC, de.dt_inserted DESC) res
                         WHERE rownum = 1)) national_health_number,
                   (SELECT pk_translation.get_translation(i_lang, code_department)
                      FROM department d
                     WHERE d.id_department = e.id_department) AS department,
                   (SELECT pk_translation.get_translation(i_lang, code_institution)
                      FROM institution i
                     WHERE i.id_institution = e.id_institution) AS institution,
                   v.id_origin,
                   pk_translation.get_translation(i_lang, o.code_origin) desc_origin,
                   (SELECT pk_doc.get_pat_doc_num(pat.id_patient, l_doc_type)
                      FROM dual) doc_num,
                   pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) gender_string,
                   to_char(pat.dt_birth, 'DD.MM.YYYY') dt_birth_period,
                   pat.gender gender_letter,
                   decode(pk_utils.search_table_varchar(pk_edis_grid.g_tab_grid_origins,
                                                        (SELECT id_origin
                                                           FROM visit
                                                          WHERE id_visit = e.id_visit)),
                          '-1',
                          0,
                          1) priority_origin,
                   pk_utils.to_string(pk_edis_grid.g_tab_grid_origins) origins,
                   pk_translation.get_translation(i_lang, o.code_origin_abbrev) desc_origin_abbrev,
                   pk_adt.get_nationality(i_lang, i_prof, e.id_patient) nationality
              FROM episode            e,
                   visit              v,
                   patient            pat,
                   external_cause     ec,
                   epis_ext_sys       ees,
                   clin_record        cr,
                   pat_ext_sys        pes,
                   pat_soc_attributes psa,
                   origin             o
             WHERE pat.id_patient = i_patient
               AND v.id_visit = e.id_visit
               AND e.id_episode = i_episode
               AND v.id_external_cause = ec.id_external_cause(+)
               AND cr.id_patient(+) = pat.id_patient
               AND cr.id_institution(+) = i_prof.institution
               AND ees.id_episode(+) = e.id_episode
               AND ees.id_institution(+) = i_prof.institution
               AND pes.id_patient(+) = pat.id_patient
               AND pes.id_institution(+) = i_prof.institution
               AND pes.id_external_sys(+) = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof)
               AND ees.id_external_sys(+) = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof)
               AND psa.id_patient(+) = e.id_patient
               AND o.id_origin(+) = v.id_origin;
    
        CURSOR c_necessity IS
            SELECT DISTINCT x
              FROM (SELECT 'X' x
                      FROM pat_necessity pn, necessity n
                     WHERE pn.id_patient = i_patient
                       AND pn.id_necessity = n.id_necessity
                       AND n.flg_mov = g_mov_n
                       AND pn.flg_status = g_pat_nec_act
                    UNION ALL
                    SELECT 'X' x
                      FROM epis_triage et, necessity n
                     WHERE et.id_episode = i_episode
                       AND et.id_necessity = n.id_necessity
                       AND n.flg_mov = g_mov_n);
    
        l_barcode_config v_barcode_type_cfg%ROWTYPE;
    
        l_scfg_barcode_name patient.name%TYPE;
    
        l_char       VARCHAR2(1);
        r_patient    c_patient%ROWTYPE;
        l_age_gen    VARCHAR2(50);
        l_namemaxlen NUMBER;
        l_patname    patient.name%TYPE;
    
        l_clin_record_maxlen NUMBER;
    
        l_age             VARCHAR2(50);
        l_pat_first_name  patient.first_name%TYPE;
        l_pat_second_name patient.second_name%TYPE;
        l_pat_middle_name patient.middle_name%TYPE;
        l_pat_last_name   patient.last_name%TYPE;
        l_maiden_name     patient.maiden_name%TYPE;
        l_mother_surname  patient.mother_surname_maiden%TYPE;
        l_show_pat_info   BOOLEAN;
        l_abbreviate_name sys_config.value%TYPE;
        l_idx             PLS_INTEGER;
    
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
        l_grid_origins    sys_config.value%TYPE;
        l_priority_origin VARCHAR2(4000);
    
        l_pat_name_array table_varchar;
        l_pat_name       VARCHAR2(4000);
        l_pat_name_trans VARCHAR2(4000);
    
        l_barcode_pat_name_pattern sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'BARCODE_PATIENT_NAME_PATTERN',
                                                                                    i_prof    => i_prof);
    
        FUNCTION get_pat_barcode_inner
        (
            i_episode IN episode.id_episode%TYPE,
            i_config  IN VARCHAR2,
            i_value   IN VARCHAR2
        ) RETURN VARCHAR2 IS
        
            l_barcode_pat VARCHAR2(32000);
        
            l_decimal_symbol sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                              i_prof_inst => i_prof.institution,
                                                                              i_prof_soft => i_prof.software);
        
            l_nhs_format sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'NATIONAL_HEALTH_NUMBER_FORMAT',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
            l_error      t_error_out;
        
        BEGIN
        
            g_error := 'GET BARCODE_PAT';
        
            l_barcode_pat := i_value;
        
            g_error       := 'REPLACE BARCODE';
            l_barcode_pat := REPLACE(l_barcode_pat, '@1', r_patient.barcode);
        
            g_error       := 'REPLACE DT_ADMISSION';
            l_barcode_pat := REPLACE(l_barcode_pat, '@2', r_patient.dt_admission);
        
            g_error       := 'REPLACE EPIS_EXT_SYS.VALUE';
            l_barcode_pat := REPLACE(l_barcode_pat,
                                     '@3',
                                     pk_message.get_message(i_lang,
                                                            profissional(i_prof.id,
                                                                         i_prof.institution,
                                                                         r_patient.id_epis_software),
                                                            'BARCODE_EPIS_TYPE') || ':' || r_patient.value);
        
            g_error := 'REPLACE LABEL AND CLIN_RECORD';
            IF i_config = g_conf_barcode_patient
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@4',
                                         pk_message.get_message(i_lang, i_prof, 'BARCODE_CLIN_REC_LABEL') || ' ' ||
                                         substr(r_patient.num_clin_record, 1, l_clin_record_maxlen));
            
            ELSIF i_config = g_conf_barcode_pat_major_inc
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@4',
                                         pk_adt_core.get_bulk_admission_details(i_lang       => i_lang,
                                                                                i_prof       => i_prof,
                                                                                i_id_episode => i_episode,
                                                                                o_error      => l_error));
            END IF;
        
            g_error       := 'REPLACE PAT_EXT_SYS.VALUE';
            l_barcode_pat := REPLACE(l_barcode_pat,
                                     '@8',
                                     pk_message.get_message(i_lang, 'BARCODE_PRINT_M002') || r_patient.p_id);
        
            g_error       := 'REPLACE PATIENT.NAME';
            l_barcode_pat := REPLACE(l_barcode_pat, '@5', l_patname);
        
            IF l_pat_name_trans IS NOT NULL
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat, '@028', l_pat_name_trans);
            END IF;
        
            g_error       := 'REPLACE EXTERNAL CAUSE';
            l_barcode_pat := REPLACE(l_barcode_pat,
                                     '@6',
                                     pk_message.get_message(i_lang, i_prof, 'BARCODE_PRINT_M003') || ' ' ||
                                     substr(r_patient.desc_external_cause,
                                            1,
                                            to_number(pk_sysconfig.get_config('BARCODE_ANAMNESIS_MAX_LEN', i_prof))));
        
            g_error       := 'REPLACE AGE_AND_GENDER';
            l_barcode_pat := REPLACE(l_barcode_pat, '@7', l_age_gen);
        
            g_error       := 'REPLACE PAT_FIRST_NAME';
            l_barcode_pat := REPLACE(l_barcode_pat, '@009', l_pat_first_name);
        
            g_error       := 'REPLACE PAT_LAST_NAME';
            l_barcode_pat := REPLACE(l_barcode_pat, '@010', l_pat_last_name);
        
            g_error       := 'REPLACE AGE';
            l_barcode_pat := REPLACE(l_barcode_pat, '@011', l_age);
        
            IF i_config = g_conf_barcode_patient
            THEN
                g_error       := 'REPLACE GENDER';
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@012',
                                         pk_message.get_message(i_lang, i_prof, 'BARCODE_GENDER') || ' ' ||
                                         r_patient.gender);
            ELSIF i_config = g_conf_barcode_pat_major_inc
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@012',
                                         pk_sysdomain.get_domain(i_code_dom => 'PATIENT.GENDER',
                                                                 i_val      => r_patient.gender,
                                                                 i_lang     => i_lang));
            END IF;
        
            g_error := 'REPLACE NHS';
            IF l_nhs_format IS NOT NULL
            THEN
                BEGIN
                    g_error := 'FORMAT NHS';
                    pk_alertlog.log_debug(g_error);
                    l_barcode_pat := REPLACE(l_barcode_pat,
                                             '@013',
                                             to_char(REPLACE(TRIM(r_patient.national_health_number), chr(32), ''),
                                                     l_nhs_format,
                                                     'NLS_NUMERIC_CHARACTERS = ''' || l_decimal_symbol || ' '''));
                EXCEPTION
                    WHEN OTHERS THEN
                        l_barcode_pat := REPLACE(l_barcode_pat, '@013', r_patient.national_health_number);
                END;
            ELSE
                l_barcode_pat := REPLACE(l_barcode_pat, '@013', r_patient.national_health_number);
            END IF;
        
            g_error       := 'REPLACE CLIN_RECORD';
            l_barcode_pat := REPLACE(l_barcode_pat, '@014', r_patient.num_clin_record);
        
            g_error       := 'REPLACE LABEL NHS';
            l_barcode_pat := REPLACE(l_barcode_pat,
                                     '@015',
                                     pk_message.get_message(i_lang, i_prof, 'BARCODE_NHS') || ' ' ||
                                     r_patient.national_health_number);
        
            g_error := 'REPLACE LABEL AND DATE BIRTH';
            IF i_config = g_conf_barcode_patient
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@016',
                                         pk_message.get_message(i_lang, i_prof, 'BARCODE_DOB') || ' ' ||
                                         pk_date_utils.date_chr_short_read(i_lang, r_patient.dt_birth, i_prof));
            
            ELSIF i_config = g_conf_barcode_pat_major_inc
            THEN
                l_barcode_pat := REPLACE(l_barcode_pat,
                                         '@016',
                                         pk_date_utils.date_chr_short_read(i_lang, r_patient.dt_birth, i_prof));
            END IF;
        
            g_error       := 'REPLACE DEPARTMENT';
            l_barcode_pat := REPLACE(l_barcode_pat, '@017', r_patient.department);
        
            g_error       := 'REPLACE INSTITUTION';
            l_barcode_pat := REPLACE(l_barcode_pat, '@018', r_patient.institution);
        
            g_error       := 'REPLACE TAX NUMBER';
            l_barcode_pat := REPLACE(l_barcode_pat, '@019', pk_adt.get_tax_number(i_lang, i_prof, i_patient));
        
            g_error       := 'REPLACE ORIGIN';
            l_barcode_pat := REPLACE(l_barcode_pat, '@020', r_patient.desc_origin);
        
            g_error       := 'REPLACE DOC_NUM';
            l_barcode_pat := REPLACE(l_barcode_pat, '@021', r_patient.doc_num);
        
            g_error       := 'REPLACE DATE BIRTH';
            l_barcode_pat := REPLACE(l_barcode_pat,
                                     '@022',
                                     pk_date_utils.date_chr_short_read(i_lang, r_patient.dt_birth, i_prof));
        
            g_error       := 'REPLACE GENDER STRING';
            l_barcode_pat := REPLACE(l_barcode_pat, '@023', r_patient.gender_string);
        
            g_error       := 'REPLACE DT_BIRTH_PERIOD';
            l_barcode_pat := REPLACE(l_barcode_pat, '@024', r_patient.dt_birth_period);
        
            g_error       := 'REPLACE GENDER_LETTER';
            l_barcode_pat := REPLACE(l_barcode_pat, '@025', r_patient.gender_letter);
        
            g_error       := 'REPLACE EPIS_EXT_SYS.VALUE WITH NO LABEL';
            l_barcode_pat := REPLACE(l_barcode_pat, '@026', r_patient.value);
        
            g_error := 'REPLACE PRIORITY ORIGIN';
            IF r_patient.priority_origin = 1
            THEN
                l_priority_origin := nvl(r_patient.desc_origin_abbrev, r_patient.desc_origin);
            END IF;
            l_barcode_pat := REPLACE(l_barcode_pat, '@027', l_priority_origin);
        
            g_error       := 'REPLACE NATIONALITY';
            l_barcode_pat := REPLACE(l_barcode_pat, '@029', r_patient.nationality);
        
            RETURN l_barcode_pat;
        
        END get_pat_barcode_inner;
    
    BEGIN
        g_error                         := 'GET configurations';
        g_companion                     := pk_sysconfig.get_config('BARCODE_COMPANION_SIGN', i_prof);
        l_abbreviate_name               := pk_sysconfig.get_config('BARCODE_ABBREVIATE_MIDDLE_NAME', i_prof);
        l_grid_origins                  := pk_sysconfig.get_config(l_config_origin, i_prof);
        pk_edis_grid.g_tab_grid_origins := pk_utils.str_split_l(l_grid_origins, '|');
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO r_patient;
        CLOSE c_patient;
    
        g_error := 'GET AGE';
        l_age   := pk_patient.get_pat_age(i_lang, i_patient, i_prof);
    
        IF r_patient.dt_birth IS NOT NULL
           AND r_patient.gender IS NOT NULL
        THEN
            l_age_gen := r_patient.gender || '/' || l_age;
        ELSE
            l_age_gen := r_patient.gender || l_age;
        END IF;
    
        l_namemaxlen    := to_number(pk_sysconfig.get_config('BARCODE_PAT_NAME_MAX_LEN', i_prof));
        l_show_pat_info := pk_adt.show_patient_info(i_lang         => i_lang,
                                                    i_patient      => i_patient,
                                                    i_is_prof_resp => get_prof_resp(i_lang    => i_lang,
                                                                                    i_prof    => i_prof,
                                                                                    i_patient => i_patient,
                                                                                    i_episode => i_episode));
    
        g_error := 'GET PAT FIRST AND LAST NAME';
        IF NOT pk_adt.get_pat_divided_name(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_patient        => i_patient,
                                           o_first_name     => l_pat_first_name,
                                           o_second_name    => l_pat_second_name,
                                           o_middle_name    => l_pat_middle_name,
                                           o_last_name      => l_pat_last_name,
                                           o_maiden_name    => l_maiden_name,
                                           o_mother_surname => l_mother_surname,
                                           o_error          => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        l_pat_name_array := pk_string_utils.str_split(i_list => r_patient.name, i_delim => '/');
        l_pat_name       := l_pat_name_array(1);
        IF l_pat_name_array.count > 1
        THEN
            l_pat_name_trans := l_pat_name_array(2);
        END IF;
    
        IF l_barcode_pat_name_pattern IS NULL
        THEN
            IF l_namemaxlen < length(l_pat_name)
            THEN
                l_idx := instr(l_pat_first_name, ' ');
                IF l_idx > 0
                THEN
                    l_patname := substr(l_pat_first_name, 1, l_idx - 1);
                ELSE
                    l_pat_name := l_pat_first_name;
                END IF;
            
                l_patname := l_patname || ' ' || l_pat_middle_name || ' ' || l_pat_last_name;
                l_patname := substr(l_patname, 1, l_namemaxlen);
            
            ELSE
                l_patname := l_pat_name;
            END IF;
        ELSE
        
            IF NOT pk_adt.build_name(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_config      => l_barcode_pat_name_pattern,
                                     i_first_name  => l_pat_first_name,
                                     i_second_name => l_pat_second_name,
                                     i_midlle_name => l_pat_middle_name,
                                     i_last_name   => l_pat_last_name,
                                     o_pat_name    => l_scfg_barcode_name,
                                     o_error       => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
            IF l_namemaxlen < length(l_scfg_barcode_name)
            THEN
                IF l_show_pat_info
                THEN
                    IF l_abbreviate_name = pk_alert_constant.g_yes
                    THEN
                        l_patname := substr(pk_utils.format_middlename(l_scfg_barcode_name), 1, l_namemaxlen);
                    ELSE
                        l_patname := l_scfg_barcode_name;
                    END IF;
                ELSE
                    l_patname := l_scfg_barcode_name;
                END IF;
            ELSE
                l_patname := l_scfg_barcode_name;
            END IF;
        
        END IF;
    
        g_error              := 'GET CLIN_RECORD MAX LEN';
        l_clin_record_maxlen := to_number(pk_sysconfig.get_config('BARCODE_CLIN_REC_MAX_LEN', i_prof));
    
        l_barcode_config := pk_barcode.get_barcode_cfg(i_lang, i_prof, i_config);
    
        g_error       := 'GET PAT BARCODE';
        o_barcode_pat := get_pat_barcode_inner(i_episode, i_config, l_barcode_config.cfg_value);
    
        IF l_namemaxlen < length(r_patient.pat_name)
        THEN
            IF l_abbreviate_name = pk_alert_constant.g_yes
            THEN
                l_patname := substr(pk_utils.format_middlename(r_patient.pat_name), 1, l_namemaxlen);
            ELSE
                l_idx := instr(l_pat_first_name, ' ');
                IF l_idx > 0
                THEN
                    l_patname := substr(l_pat_first_name, 1, l_idx - 1);
                ELSE
                    l_patname := l_pat_first_name;
                END IF;
                l_patname := l_patname || ' ' || l_pat_middle_name || ' ' || l_pat_last_name;
                l_patname := substr(l_patname, 1, l_namemaxlen);
            END IF;
        ELSE
            l_patname := r_patient.pat_name;
        END IF;
    
        IF i_config = g_conf_barcode_patient
        THEN
            g_error         := 'GET BARCODE_PAT_N'; --vip
            o_barcode_pat_n := get_pat_barcode_inner(i_episode, i_config, l_barcode_config.cfg_value);
        
            IF g_companion IN (g_necessity_y, g_necessity_a)
            THEN
                IF g_companion = g_necessity_y
                THEN
                    -- permite acompanhante     
                    g_error := 'OPEN C_NECESSITY';
                    OPEN c_necessity;
                    FETCH c_necessity
                        INTO l_char;
                    g_found := c_necessity%FOUND;
                    CLOSE c_necessity;
                ELSIF g_companion = g_necessity_a
                THEN
                    g_found := TRUE;
                END IF;
            
                IF g_found
                THEN
                    l_barcode_config := pk_barcode.get_barcode_cfg(i_lang, i_prof, 'BARCODE_COMPANION');
                
                    g_error := 'GET BARCODE_NEC';
                    IF l_pat_name_trans IS NULL
                    THEN
                        o_barcode_nec := REPLACE(REPLACE(REPLACE(REPLACE(l_barcode_config.cfg_value,
                                                                         '@1',
                                                                         pk_message.get_message(i_lang,
                                                                                                i_prof,
                                                                                                'BARCODE_PRINT_M004')),
                                                                 '@2',
                                                                 substr(nvl(l_scfg_barcode_name, r_patient.name), 1, 34)),
                                                         '@3',
                                                         substr(nvl(r_patient.name, l_scfg_barcode_name), 34, 68)),
                                                 '@4',
                                                 r_patient.dt_admission);
                    ELSE
                        o_barcode_nec := REPLACE(REPLACE(REPLACE(REPLACE(l_barcode_config.cfg_value,
                                                                         '@1',
                                                                         pk_message.get_message(i_lang,
                                                                                                i_prof,
                                                                                                'BARCODE_PRINT_M004')),
                                                                 '@2',
                                                                 nvl(l_scfg_barcode_name, l_pat_name)),
                                                         '@3',
                                                         l_pat_name_trans),
                                                 '@4',
                                                 r_patient.dt_admission);
                    END IF;
                END IF;
            END IF;
        END IF;
    
        o_codification_type := l_barcode_config.cfg_type;
    
        g_error   := 'GET PRINTER';
        o_printer := l_barcode_config.cfg_printer;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BARCODE_PRINT',
                                              o_error);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante.
    * Usada em queries SQL.   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_error                  Error message
    *
    * @return                         String para impressão (paciente + acompanhante)  
    *                        
    * @author                         Rui Baeta
    * @since                          2008/02/29 
    **********************************************************************************************/
    FUNCTION get_barcode_print
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2 IS
        l_printer           VARCHAR2(2000);
        l_codification_type VARCHAR2(2000);
        l_barcode_pat       VARCHAR2(2000);
        l_barcode_nec       VARCHAR2(2000);
        l_barcode_pat_n     VARCHAR2(2000);
        l_error             t_error_out;
    BEGIN
    
        IF NOT pk_patient.get_barcode_print(i_lang,
                                            i_episode,
                                            i_patient,
                                            i_prof,
                                            g_conf_barcode_patient,
                                            l_printer,
                                            l_codification_type,
                                            l_barcode_pat,
                                            l_barcode_nec,
                                            l_barcode_pat_n,
                                            l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_barcode_pat || l_barcode_nec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_barcode_print;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Spratley
    * @version                        2.4.2.15
    * @since                          2008/09/11
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/

    FUNCTION get_barcode_print_new
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_barcode_nec       OUT VARCHAR2,
        o_barcode_pat_n     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_patient.get_barcode_print(i_lang,
                                            i_episode,
                                            i_patient,
                                            i_prof,
                                            g_conf_barcode_patient,
                                            o_printer,
                                            o_codification_type,
                                            o_barcode_pat,
                                            o_barcode_nec,
                                            o_barcode_pat_n,
                                            o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BARCODE_PRINT_NEW',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_barcode_print_new;

    /**********************************************************************************************
    * Get major incident data for the patient's wristband/frontsheet.  
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Gisela Couto
    * @version                        2.6.4.2
    * @since                          2014/09/08
    **********************************************************************************************/
    FUNCTION get_barcode_print_major_inc
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_barcode_nec   VARCHAR2(32000);
        l_barcode_pat_n VARCHAR2(32000);
        l_patient       patient.id_patient%TYPE;
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            l_patient := i_patient;
        ELSIF i_episode IS NOT NULL
        THEN
            SELECT epis.id_patient
              INTO l_patient
              FROM episode epis
             WHERE epis.id_episode = i_episode;
        ELSE
            raise_application_error(-20001, 'ID_EPISODE IS NULL');
        END IF;
    
        IF NOT get_barcode_print(i_lang,
                                 i_episode,
                                 l_patient,
                                 i_prof,
                                 g_conf_barcode_pat_major_inc,
                                 o_printer,
                                 o_codification_type,
                                 o_barcode_pat,
                                 l_barcode_nec,
                                 l_barcode_pat_n,
                                 o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT t.cfg_printer
          INTO o_printer
          FROM TABLE(pk_barcode.get_barcode_cfg_base(i_lang, i_prof, 'BARCODE_PATIENT_MAJOR_INC')) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BARCODE_PRINT_MAJOR_INC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_barcode_print_major_inc;

    --
    /**********************************************************************************************
    * Obter associado ao episódio / paciente   
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_barcode                Barcode associado ao episódio / paciente 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/20 
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    *
    * UPDATED: ALERT-125592 - Support in Alert for external barcodes
    * @author  Alexandre Santos
    * @date    21-09-2010
    * @version 2.5.0.7.8
    **********************************************************************************************/
    FUNCTION get_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_barcode OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_BARCODE';
    BEGIN
    
        SELECT pk_barcode.get_pat_barcode(i_lang, i_prof, i_episode, cr.id_patient, epis.barcode, cr.num_clin_record)
          INTO o_barcode
          FROM episode epis
          JOIN clin_record cr
            ON cr.id_patient = epis.id_patient
         WHERE epis.id_episode = i_episode
           AND cr.id_institution = i_prof.institution
           AND cr.flg_status = pk_alert_constant.g_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_barcode;
    --
    /**********************************************************************************************
    * Devolve o id_patient do sonho que corresponde ao id_patient ALert 
    *
    * @param i_lang                   the id language
    * @param i_prof                   
    * @param i_patient                patient id         
    * @param o_pat_ext_sys            Devolve o id_patient do sonho
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/03/19
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_pat_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_pat_ext_sys OUT pat_ext_sys.value%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_pat_ext_sys IS
            SELECT VALUE
              FROM pat_ext_sys
             WHERE id_patient = i_patient;
    BEGIN
        OPEN c_pat_ext_sys;
        FETCH c_pat_ext_sys
            INTO o_pat_ext_sys;
        CLOSE c_pat_ext_sys;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EXT_SYS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Get the external patient ID 
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional, software and institution id
    * @param i_ext_sys                External system ID
    * @param i_patient                Patient ID         
    * @param i_institution            Institution ID
    *
    * @return                         External patient ID
    *
    * @author  José Silva
    * @date    17-11-2011
    * @version 2.5.1.9
    **********************************************************************************************/
    FUNCTION get_pat_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN pat_ext_sys.value%TYPE IS
    
        l_external_sys external_sys.id_external_sys%TYPE;
        l_ret_value    pat_ext_sys.value%TYPE;
        l_error        t_error_out;
    
        CURSOR c_pat_ext_sys IS
            SELECT p.value
              FROM pat_ext_sys p
             WHERE p.id_patient = i_patient
               AND p.id_external_sys = l_external_sys
             ORDER BY decode(p.id_institution, i_institution, 1, 2), p.id_pat_ext_sys DESC;
    BEGIN
    
        IF i_ext_sys IS NULL
        THEN
            l_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        ELSE
            l_external_sys := i_ext_sys;
        END IF;
    
        g_error := 'FETCH EXTERNAL PATIENT ID';
        OPEN c_pat_ext_sys;
        FETCH c_pat_ext_sys
            INTO l_ret_value;
        CLOSE c_pat_ext_sys;
    
        RETURN l_ret_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EXT_SYS',
                                              l_error);
            RAISE;
    END get_pat_ext_sys;
    --

    /**
    * Validate item applicable gender.
    * Anwers the question? Is this item applicable to this patient gender?
    *
    * @param i_pat_gender        The patient gender
    * @param i_item_gender       The item gender
    *
    * @return 1 when applicable, 0 otherwise
    * @created 26-05-2007
    * @author Luís Gaspar & Luís Oliveira
    */
    FUNCTION validate_pat_gender
    (
        i_pat_gender  IN patient.gender%TYPE,
        i_item_gender IN patient.gender%TYPE
    ) RETURN NUMBER result_cache IS
        l_aux BOOLEAN;
    BEGIN
        l_aux := i_item_gender IS NULL OR i_pat_gender IS NULL OR i_pat_gender = i_item_gender OR i_pat_gender = 'I' OR
                 i_item_gender = 'I' OR i_pat_gender = 'U' OR i_item_gender = 'U';
        IF (l_aux)
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;
    --
    /**
    * Returns the url used to access an external system from 
    *
    * @param i_lang        the language id
    * @param i_prof        professional, software and institution id
    * @param i_patient     the patient id
    * @param i_episode     the episode id
    * @param o_url         The external system url
    * @param o_error       An error message
    *
    * @return boolean true if success, false otherwise
    * @created 06-Jun-2007
    * @author Luís Gaspar
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    */
    FUNCTION get_ext_sys_url
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_url     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_url := pk_sysconfig.get_config('EXTERNAL_SYS_URL', i_prof);
        RETURN TRUE;
    END;
    --
    /********************************************************************************************
    * Nome do paciente
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/19
    **********************************************************************************************/

    FUNCTION get_patient_name
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_patient_name OUT patient.name%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_patient_name := get_patient_name(i_lang, i_patient);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_patient_name;

    FUNCTION get_patient_name
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_name patient.name%TYPE;
    BEGIN
        BEGIN
            SELECT p.name
              INTO l_name
              FROM patient p
             WHERE p.id_patient = i_patient;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_name := NULL;
        END;
    
        RETURN l_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --
    /********************************************************************************************
    * Nome abreviado do paciente
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/19
    **********************************************************************************************/
    FUNCTION get_patient_nick_name
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_name patient.name%TYPE;
    BEGIN
        BEGIN
            SELECT p.nick_name
              INTO l_name
              FROM patient p
             WHERE p.id_patient = i_patient;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_name := NULL;
        END;
    
        RETURN l_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente bem como todas as alergias activas do paciente   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @author                         Rui Baeta
    * @version                        1.0 
    * @since                          2007/10/29
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_barcode_allergy_print
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_patient IS
            SELECT pat.name,
                   pk_patient.get_gender(i_lang, pat.gender) gender,
                   pat.dt_birth,
                   ees.value,
                   cr.num_clin_record,
                   (SELECT pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang,
                                                                                            'ALLERGY.CODE_ALLERGY.' ||
                                                                                            pa.id_allergy)
                                                        FROM pat_allergy pa
                                                       WHERE pa.id_patient = v.id_patient
                                                         AND pa.flg_status = g_pat_allergy_active),
                                                     '; ')
                      FROM dual) desc_allergy
              FROM episode e, visit v, patient pat, external_cause ec, epis_ext_sys ees, clin_record cr
             WHERE pat.id_patient = i_patient
               AND v.id_visit = e.id_visit
               AND e.id_episode = i_episode
               AND v.id_external_cause = ec.id_external_cause(+)
               AND cr.id_patient(+) = pat.id_patient
               AND cr.id_institution(+) = i_prof.institution
               AND ees.id_episode(+) = e.id_episode
               AND ees.id_institution(+) = i_prof.institution
               AND ees.id_external_sys(+) = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
    
        r_patient     c_patient%ROWTYPE;
        l_age_gen     VARCHAR2(50);
        l_namemaxlen  NUMBER;
        l_patname     patient.name%TYPE;
        l_label_vars  pk_utils.hashtable_varchar2;
        l_format_vars pk_utils.hashtable_varchar2;
        l_header_mask VARCHAR2(4000);
        l_cont_mask   VARCHAR2(4000);
        l_body_text   VARCHAR2(4000);
    
        l_barcode_config v_barcode_type_cfg%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO r_patient;
        CLOSE c_patient;
    
        g_error   := 'GET AGE';
        l_age_gen := pk_patient.get_pat_age(i_lang, i_patient, i_prof);
    
        IF l_age_gen IS NOT NULL
           AND r_patient.gender IS NOT NULL
        THEN
            l_age_gen := r_patient.gender || '/' || l_age_gen;
        ELSE
            l_age_gen := r_patient.gender || l_age_gen;
        END IF;
    
        l_namemaxlen := to_number(pk_sysconfig.get_config('BARCODE_ALLERGY_PAT_NAME_MAX_LEN', i_prof));
    
        IF l_namemaxlen < length(r_patient.name)
        THEN
            l_patname := substr(pk_utils.format_middlename(r_patient.name), 1, l_namemaxlen);
        ELSE
            l_patname := r_patient.name;
        END IF;
        -- convert accented chars in patient name
        l_patname := translate(l_patname,
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑáéíóúàèìòùâêîôûãõçäëïöüñ',
                               'AEIOUAEIOUAEIOUAOCAEIOUNaeiouaeiouaeiouaocaeioun');
    
        -- maximum number of lines of allergy string (header label)
        l_format_vars('@header_body_lines') := pk_sysconfig.get_config('BARCODE_ALLERGY_MAX_LINES', i_prof);
        -- maximum number of lines of allergy string (cont label)
        l_format_vars('@cont_body_lines') := pk_sysconfig.get_config('BARCODE_ALLERGY_CONT_MAX_LINES', i_prof);
        -- length of body text 
        l_format_vars('@body_text_width') := pk_sysconfig.get_config('BARCODE_ALLERGY_LINE_LEN', i_prof);
    
        -- print label
        g_error := 'GET BARCODE_PAT_ALLERGY';
    
        l_label_vars('@01') := l_patname;
        l_label_vars('@02') := l_age_gen;
        l_label_vars('@03') := pk_message.get_message(i_lang, 'BARCODE_ALLERGY_EPIS_LABEL') || i_episode;
        l_label_vars('@04') := pk_message.get_message(i_lang, 'BARCODE_ALLERGY_PROC_LABEL') ||
                               r_patient.num_clin_record;
        l_label_vars('@05') := to_char(current_timestamp, 'DD-MM-YYYY HH24:MI'); -- date
    
        l_barcode_config := pk_barcode.get_barcode_cfg(i_lang, i_prof, 'BARCODE_PAT_ALLERGY');
    
        l_body_text := pk_message.get_message(i_lang, 'BARCODE_ALLERGY_LABEL') ||
                       translate(r_patient.desc_allergy,
                                 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑáéíóúàèìòùâêîôûãõçäëïöüñ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUNaeiouaeiouaeiouaocaeioun');
    
        o_barcode_pat := pk_utils.build_label_print(l_barcode_config.cfg_value,
                                                    l_barcode_config.cfg_cont,
                                                    l_label_vars,
                                                    l_body_text,
                                                    l_format_vars);
    
        g_error             := 'GET PRINTER';
        o_codification_type := l_barcode_config.cfg_type;
        o_printer           := l_barcode_config.cfg_printer;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BARCODE_ALLERGY_PRINT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_barcode_allergy_print;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente bem como todas as alergias activas do paciente.
    * Usada em queries SQL.   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         String para impressão (paciente)  
    *                        
    * @author                         Rui Baeta
    * @version                        1.0 
    * @since                          2007/12/19
    **********************************************************************************************/
    FUNCTION get_barcode_allergy_print
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2 IS
        l_printer      VARCHAR2(2000);
        l_barcode_type VARCHAR2(2000);
        l_barcode      VARCHAR2(2000);
        l_error        t_error_out;
    BEGIN
    
        IF NOT pk_patient.get_barcode_allergy_print(i_lang,
                                                    i_episode,
                                                    i_patient,
                                                    i_prof,
                                                    l_printer,
                                                    l_barcode_type,
                                                    l_barcode,
                                                    l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_barcode;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_barcode_allergy_print;

    /**********************************************************************************************
    * Method that tests if the professional can create patients based on his profile template
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids   
    * @param o_permission             Flag 'Y' if the profissional can create patients, 'N' if he can't
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error                     
    *
    * @author                         Sérgio Santos
    * @version                        1.0 
    * @since                          2008/02/08
    *
    * UPDATED: ALERT-19390
    * @author  Telmo Castro
    * @date    10-03-2009
    * @version 2.5
    **********************************************************************************************/
    FUNCTION get_pat_creation_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_permission OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profiles     sys_config.value%TYPE;
        l_prof_profile VARCHAR2(2000);
    BEGIN
        -- Read sys_config parameter with the authorized profile templates
        g_error    := 'get authorized profiles';
        l_profiles := pk_sysconfig.get_config('PROF_CREATE_PATIENT', i_prof);
    
        -- Read the professional profile template
        g_error := 'get professional profile template';
        SELECT ppt.id_profile_template
          INTO l_prof_profile
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND pt.id_profile_template = ppt.id_profile_template
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
           AND pt.id_software = i_prof.software;
    
        -- Concat pipes for the the next function
        l_prof_profile := '|' || l_prof_profile || '|';
    
        -- by default, he is not authorized
        o_permission := 'N';
    
        -- Test if the professional profile template is in the authorized profile templates
        -- and if is authorized convert the flag to 'Y'
        IF instr(l_profiles, l_prof_profile) > 0
        THEN
            o_permission := 'Y';
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
                                              'GET_PAT_CREATION_PERMISSION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_creation_permission;

    /**
     * This functions sets a habit as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
     * @reason   ALERT-52344
    */
    FUNCTION set_habit_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_id_habit     IN pat_habit.id_pat_habit%TYPE,
        i_review_notes IN review_detail.review_notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_habit_review_area := pk_review.get_habits_context();
    
        g_error := 'SET_HABIT_REVIEW';
    
        IF (NOT pk_review.set_review(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_record_area => i_id_habit,
                                     i_flg_context    => g_habit_review_area,
                                     i_dt_review      => current_timestamp,
                                     i_review_notes   => i_review_notes,
                                     i_episode        => i_episode,
                                     i_flg_auto       => pk_alert_constant.g_no,
                                     o_error          => o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HABIT_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_habit_review;

    /**
     * This functions sets a blood type as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
     * @reason   ALERT-52344
    */
    FUNCTION set_blood_type_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_blood_type IN pat_allergy.id_pat_allergy%TYPE,
        i_review_notes  IN review_detail.review_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_blood_type_review_area := pk_review.get_blood_type_context();
    
        g_error := 'SET_BLOOD_TYPE_REVIEW';
    
        IF (NOT pk_review.set_review(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_record_area => i_id_blood_type,
                                     i_flg_context    => g_blood_type_review_area,
                                     i_dt_review      => current_timestamp,
                                     i_review_notes   => i_review_notes,
                                     o_error          => o_error))
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BLOOD_TYPE_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_blood_type_review;

    /**
     * Gets the patient location based on the institution group.
     *
     * @param IN   i_institution       Professional institution id
     * @param IN   i_flg_relation      type of relation between institutions
     * @param IN   i_patient           Patient id
     *
     * @return     Patient location. First verifies if the location exists in the professional institution
     *                               then verifies if the location exists in the institution 0
     *                               then verifies if exists in one of the institutions group
     *
     * @version  2.5.0.7
     * @since    11-12-2009
     * @author   Alexandre Santos
    */
    FUNCTION get_pat_location
    (
        i_institution  IN institution_group.id_institution%TYPE,
        i_flg_relation IN institution_group.flg_relation%TYPE,
        i_patient      IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.location%TYPE IS
        l_location pat_soc_attributes.location%TYPE;
    BEGIN
        BEGIN
            SELECT aux2.location
              INTO l_location
              FROM (SELECT psa2.location,
                           row_number() over(ORDER BY decode(aux.id_institution, i_institution, 1, 0, 2, aux.id_institution)) line_number
                      FROM pat_soc_attributes psa2
                      JOIN (SELECT column_value id_institution
                             FROM TABLE(pk_list.tf_get_all_inst_group(i_institution, i_flg_relation)) i
                           UNION
                           SELECT 0 id_institution
                             FROM dual) aux
                        ON aux.id_institution = psa2.id_institution
                     WHERE psa2.id_patient = i_patient) aux2
             WHERE aux2.line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_location := NULL;
        END;
    
        RETURN l_location;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_location;

    /**
    * Check if the professional is responsible for the episode (default behaviour).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               1, if the professional is responsible, or 0 otherwise
    */
    FUNCTION get_prof_resp_default
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN PLS_INTEGER IS
        l_func_name    VARCHAR2(200 CHAR) := 'GET_PROF_RESP_DEFAULT';
        l_is_prof_resp PLS_INTEGER;
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        IF i_episode IS NOT NULL
        THEN
            g_error := 'GET PROF CAT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'GET HANDOFF TYPE';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        
            SELECT decode(i_prof.id, nvl(ei.id_professional, sr.id_professional), pk_adt.g_true, pk_adt.g_false) is_prof_resp
              INTO l_is_prof_resp
              FROM epis_info ei
              LEFT JOIN sch_resource sr
                ON ei.id_schedule = sr.id_schedule
               AND sr.id_professional = i_prof.id
             WHERE ei.id_episode = i_episode
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_episode,
                                                                                    l_prof_cat,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1;
        ELSIF i_schedule IS NOT NULL
        THEN
            SELECT decode(i_prof.id, sr.id_professional, pk_adt.g_true, pk_adt.g_false) is_prof_resp
              INTO l_is_prof_resp
              FROM sch_resource sr
             WHERE sr.id_schedule = i_schedule;
        ELSE
            l_is_prof_resp := pk_adt.g_false;
        END IF;
    
        RETURN l_is_prof_resp;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_adt.g_false;
    END get_prof_resp_default;

    /**
    * Check if the professional is responsible for the PP/OUTP/CARE/SOCIAL episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               1, if the professional is responsible, or 0 otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.0
    * @since                2010/01/08
    */
    FUNCTION get_prof_resp_ambulatory
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        IF i_episode IS NOT NULL
        THEN
            SELECT decode(i_prof.id,
                          coalesce(ei.id_first_nurse_resp, ei.id_professional, sr.id_professional),
                          pk_adt.g_true,
                          pk_adt.g_false) is_prof_resp
              INTO l_is_prof_resp
              FROM epis_info ei
              LEFT JOIN sch_resource sr
                ON ei.id_schedule = sr.id_schedule
               AND sr.id_professional = i_prof.id
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_episode,
                                                                                    l_prof_cat,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1
             WHERE ei.id_episode = i_episode;
        ELSIF i_schedule IS NOT NULL
        THEN
            SELECT decode(i_prof.id, sr.id_professional, pk_adt.g_true, pk_adt.g_false) is_prof_resp
              INTO l_is_prof_resp
              FROM sch_resource sr
             WHERE sr.id_schedule = i_schedule
               AND sr.id_professional = i_prof.id
               AND sr.flg_leader = 'Y';
        ELSE
            l_is_prof_resp := pk_adt.g_false;
        END IF;
    
        RETURN l_is_prof_resp;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_adt.g_false;
    END get_prof_resp_ambulatory;

    /**
    * Check if the professional is responsible for the EDIS/INP episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               patient's name
    */
    FUNCTION get_prof_resp_edis_inp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp  PLS_INTEGER;
        l_total         PLS_INTEGER;
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      VARCHAR2(0050);
    
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        g_error := 'GET RESP PROF';
        SELECT COUNT(t.id_professional)
          INTO l_total
          FROM (SELECT column_value id_professional
                  FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang, i_prof, i_episode, l_prof_cat, l_hand_off_type))) t
         WHERE t.id_professional = i_prof.id;
    
        g_error := 'VERIFY IF CURR PROF IS RESP';
        IF l_total = 1
        THEN
            l_is_prof_resp := pk_adt.g_true;
        ELSE
            l_is_prof_resp := pk_adt.g_false;
        END IF;
    
        RETURN l_is_prof_resp;
    END get_prof_resp_edis_inp;

    /**
    * Check if the professional is responsible for the ORIS episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               patient's name
    */
    FUNCTION get_prof_resp_oris
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
    BEGIN
        g_error        := 'CHECK RESP PROF';
        l_is_prof_resp := pk_sr_tools.get_sr_prof_team(i_lang, i_prof, i_episode);
    
        RETURN l_is_prof_resp;
    END get_prof_resp_oris;

    /**
    * Check if the professional is responsible for the REFERRAL REquest
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    *
    * @return               patient's name
    */
    FUNCTION get_prof_resp_referral
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
        l_var          sys_config.value%TYPE;
    BEGIN
    
        g_error := 'Call pk_sysconfig.get_config';
        l_var   := pk_sysconfig.get_config('REF_VIP_AVAILABLE', i_prof);
    
        IF l_var = pk_alert_constant.g_yes
        THEN
            RETURN pk_adt.g_false;
        ELSE
            RETURN pk_adt.g_true;
        END IF;
    
    END get_prof_resp_referral;

    FUNCTION get_prof_resp_adt
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
        l_var          sys_config.value%TYPE;
    BEGIN
    
        RETURN pk_adt.g_true;
    
    END get_prof_resp_adt;

    /**
    * Check if the professional is responsible for the Activity Therapy episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               1, if the professional is responsible, or 0 otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.3
    * @since                01-Jul-2010
    */
    FUNCTION get_prof_resp_act_ther
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
        l_id_epis_type episode.id_epis_type%TYPE;
        l_id_episode   episode.id_episode%TYPE;
    BEGIN
    
        g_error := 'CALL pk_episode.get_epis_type for episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_id_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        IF (l_id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            l_id_episode := i_episode;
        ELSE
        
            l_id_episode := pk_activity_therapist.get_epis_child(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_epis_parent => i_episode);
        END IF;
    
        IF (l_id_episode IS NOT NULL)
        THEN
            l_is_prof_resp := get_prof_resp_default(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_episode  => l_id_episode,
                                                    i_schedule => NULL);
        END IF;
    
        RETURN l_is_prof_resp;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_adt.g_false;
    END get_prof_resp_act_ther;

    /**
    * Check if the professional is responsible for the episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               patient's name
    */
    FUNCTION get_prof_resp
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER IS
        l_is_prof_resp PLS_INTEGER;
    
    BEGIN
        IF i_prof.software = pk_alert_constant.g_soft_private_practice
           OR i_prof.software = pk_alert_constant.g_soft_primary_care
           OR i_prof.software = pk_alert_constant.g_soft_outpatient
           OR i_prof.software = pk_alert_constant.g_soft_nutritionist
           OR i_prof.software = pk_alert_constant.g_soft_case_manager
           OR i_prof.software = pk_alert_constant.g_soft_social
        THEN
            l_is_prof_resp := get_prof_resp_ambulatory(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_episode,
                                                       i_schedule => i_schedule);
        ELSIF i_prof.software = pk_alert_constant.g_soft_oris
        THEN
            l_is_prof_resp := get_prof_resp_oris(i_lang    => i_lang,
                                                 i_patient => i_patient,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode);
        ELSIF i_prof.software = pk_alert_constant.g_soft_inpatient
              OR i_prof.software = pk_alert_constant.g_soft_edis
              OR i_prof.software = pk_alert_constant.g_soft_ubu
              OR i_prof.software = pk_alert_constant.g_soft_triage
        THEN
            l_is_prof_resp := get_prof_resp_edis_inp(i_lang    => i_lang,
                                                     i_patient => i_patient,
                                                     i_prof    => i_prof,
                                                     i_episode => i_episode);
        ELSIF i_prof.software = pk_alert_constant.g_soft_act_therapist
        THEN
        
            l_is_prof_resp := get_prof_resp_act_ther(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_referral
        THEN
            l_is_prof_resp := get_prof_resp_referral(i_lang => i_lang, i_prof => i_prof);
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_adt
        THEN
            l_is_prof_resp := get_prof_resp_adt(i_lang => i_lang, i_prof => i_prof);
        
        ELSE
            l_is_prof_resp := get_prof_resp_default(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_episode  => i_episode,
                                                    i_schedule => i_schedule);
        END IF;
    
        RETURN l_is_prof_resp;
    END get_prof_resp;

    /**
    * Get the patient name (considering VIP alias)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               patient's name
    */
    FUNCTION get_pat_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN patient.name%TYPE IS
        l_is_prof_resp   PLS_INTEGER;
        l_is_prof_resp_1 NUMBER;
    BEGIN
    
        l_is_prof_resp := get_prof_resp(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_patient  => i_patient,
                                        i_episode  => i_episode,
                                        i_schedule => i_schedule);
    
        IF l_is_prof_resp = 0
        THEN
        
            IF i_episode IS NOT NULL
            THEN
                l_is_prof_resp_1 := pk_hand_off_core.is_prof_responsible_current(i_lang          => i_lang,
                                                                                 i_prof          => i_prof,
                                                                                 i_prof_cat      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                                               i_prof => i_prof),
                                                                                 i_id_episode    => i_episode,
                                                                                 i_hand_off_type => NULL);
            
                IF l_is_prof_resp_1 > -1
                THEN
                    l_is_prof_resp := 1;
                ELSE
                    l_is_prof_resp := 0;
                END IF;
            END IF;
        END IF;
    
        RETURN pk_adt.get_patient_name(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_patient       => i_patient,
                                       i_is_prof_resp  => l_is_prof_resp,
                                       i_id_sys_config => i_id_sys_config);
    
    END get_pat_name;

    /**
    * Get the patient name to use in sorting (order by clauses)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               patient's name
    */
    FUNCTION get_pat_name_to_sort
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE IS
        l_is_prof_resp PLS_INTEGER;
    BEGIN
    
        l_is_prof_resp := get_prof_resp(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_patient  => i_patient,
                                        i_episode  => i_episode,
                                        i_schedule => i_schedule);
    
        RETURN pk_adt.get_patient_name_to_sort(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_is_prof_resp => l_is_prof_resp);
    
    END get_pat_name_to_sort;

    FUNCTION get_decease_info_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_status      OUT patient.flg_status%TYPE,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
         OBJECTIVO:   Retornar informação para do falecimento do doente 
         PARAMETROS:  
                   Entrada: 
                   I_LANG - Língua registada como preferência do profissional 
                   I_ID_PAT - ID do doente 
                   i_PROF - ID do profissional
                   Saída:   
                   O_STATUS - A - activo, O - falecido, I - inactivo 
                   O_DT_DECEASED - PATIENT.DT_DECEASED 
                   O_ERROR - erro 
        *
        * CRIAÇÃO: ALERT-14510
        * @author  Isabela Fontoura
        * @date    07-01-2010
        * @version 1.0
        *********************************************************************************/
        CURSOR c_pat IS
            SELECT p.flg_status, pk_date_utils.dt_chr(i_lang, p.dt_deceased, i_prof) dt_deceased
              FROM patient p
             WHERE p.id_patient = i_id_pat;
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO o_status, o_dt_deceased;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
        IF g_found
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              pk_message.get_message(i_lang, 'COMMON_M001'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LOCAL_PAT_INFO',
                                              o_error);
            RETURN FALSE;
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
                                              'GET_DECEASE_INFO_WARNING',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get patient's age & gender based on episode ID
    *
    * @param i_lang                      Language ID
    * @param i_episode                   Episode ID
    * @param o_gender                    Patient's gender or NULL if patient doesn't exist
    * @param o_age                       Patient's age or NULL if patient doesn't exist
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION get_pat_info_by_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age
              INTO o_gender, o_age
              FROM patient p
             INNER JOIN episode e
                ON p.id_patient = e.id_patient
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                o_gender := NULL;
                o_age    := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PAT_INFO_BY_EPISODE');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_pat_info_by_episode;

    /********************************************************************************************
    * Get patient's age & gender based on patient ID
    *
    * @param i_lang                      Language ID
    * @param i_patient                   Patient ID
    * @param o_gender                    Patient's gender or NULL if patient doesn't exist
    * @param o_age                       Patient's age or NULL if patient doesn't exist
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION get_pat_info_by_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age
              INTO o_gender, o_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        EXCEPTION
            WHEN no_data_found THEN
                o_gender := NULL;
                o_age    := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PAT_INFO_BY_PATIENT');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_pat_info_by_patient;

    /**
    * Get Show patient info
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               Y/N
    *
    * @author               Elisabete Bugalho
    * @version              2.6.0.0
    * @since                25-02-2010
    */
    FUNCTION get_show_patient_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_schedule  IN schedule.id_schedule%TYPE DEFAULT NULL,
        o_show_info OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_is_prof_resp PLS_INTEGER;
    
    BEGIN
        l_is_prof_resp := get_prof_resp(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_patient  => i_patient,
                                        i_episode  => i_episode,
                                        i_schedule => i_schedule);
    
        IF pk_adt.show_patient_info(i_lang => i_lang, i_patient => i_patient, i_is_prof_resp => l_is_prof_resp)
        THEN
            o_show_info := pk_alert_constant.g_yes;
        ELSE
            o_show_info := pk_alert_constant.g_no;
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
                                              'GET_SHOW_PATIENT_INFO',
                                              o_error);
            RETURN FALSE;
        
    END get_show_patient_info;

    /* universal patient search function. the market parameter determines the data source, that is, which views objects are
    * used. search_values holds both the search criteria and respective search value. 
    * values for search criteria can be seen below. They are the constants wih prefix g_search_pat.
    * The search values must be stored like this: i_search_values(g_search_pat_nhn) := 'DF9233381'
    * output is sent to global temporary table PAT_TMPTAB_SEARCH. In this initial version this table only holds the id_patient.
    * Other columns can be added according to specific needs. GTT used due to potentially huge number of result rows obtained.
    *  
    * @param i_lang             Language ID
    * @param i_prof             Professional Type
    * @param i_id_market        market id. used to contextualize search itself
    * @param i_search_values    associative array containing both search criteria and its search values
    * @param o_all_patients     indicates if an actual search was performed. true = no search done. so no patient restrictions in the top search
    * @param o_error            Error data
    *
    * @return                   true or false on success or error
    *
    * @version  2.6
    * @data     08-02-2010
    * @author  Telmo
    */
    FUNCTION search_patients
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_market     IN market.id_market%TYPE,
        i_search_values IN pk_utils.hashtable_pls_integer,
        o_all_patients  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat    patient.id_patient%TYPE := CASE i_search_values.exists(g_search_pat_pat_id)
                                                   WHEN TRUE THEN
                                                    i_search_values(g_search_pat_pat_id)
                                                   ELSE
                                                    NULL
                                               END;
        l_bsn       patient.bsn%TYPE := CASE i_search_values.exists(g_search_pat_bsn)
                                            WHEN TRUE THEN
                                             i_search_values(g_search_pat_bsn)
                                            ELSE
                                             NULL
                                        END;
        l_ssn       person.social_security_number%TYPE := CASE i_search_values.exists(g_search_pat_ssn)
                                                              WHEN TRUE THEN
                                                               TRIM(i_search_values(g_search_pat_ssn))
                                                              ELSE
                                                               NULL
                                                          END;
        l_nhn       patient.national_health_number%TYPE := CASE i_search_values.exists(g_search_pat_nhn)
                                                               WHEN TRUE THEN
                                                                TRIM(i_search_values(g_search_pat_nhn))
                                                               ELSE
                                                                NULL
                                                           END;
        l_recnum    pat_identifier.alert_process_number%TYPE := CASE i_search_values.exists(g_search_pat_recnum)
                                                                    WHEN TRUE THEN
                                                                     TRIM(i_search_values(g_search_pat_recnum))
                                                                    ELSE
                                                                     NULL
                                                                END;
        l_birthdate patient.dt_birth%TYPE := CASE i_search_values.exists(g_search_pat_birthdate)
                                                 WHEN TRUE THEN
                                                  to_date(TRIM(i_search_values(g_search_pat_birthdate)),
                                                          'YYYYMMDDhh24miss')
                                                 ELSE
                                                  NULL
                                             END;
    
        l_gender    patient.gender%TYPE := CASE i_search_values.exists(g_search_pat_gender)
                                               WHEN TRUE THEN
                                                TRIM(i_search_values(g_search_pat_gender))
                                               ELSE
                                                NULL
                                           END;
        l_surprefix patient.surname_prefix%TYPE := CASE i_search_values.exists(g_search_pat_surnameprefix)
                                                       WHEN TRUE THEN
                                                        TRIM(i_search_values(g_search_pat_surnameprefix))
                                                       ELSE
                                                        NULL
                                                   END;
        l_surmaiden person.surname_maiden%TYPE := CASE i_search_values.exists(g_search_pat_surnamemaiden)
                                                      WHEN TRUE THEN
                                                       TRIM(i_search_values(g_search_pat_surnamemaiden))
                                                      ELSE
                                                       NULL
                                                  END;
        l_names     patient.name%TYPE := CASE i_search_values.exists(g_search_pat_names)
                                             WHEN TRUE THEN
                                              TRIM(i_search_values(g_search_pat_names))
                                             ELSE
                                              NULL
                                         END;
        l_initials  patient.initials%TYPE := CASE i_search_values.exists(g_search_pat_initials)
                                                 WHEN TRUE THEN
                                                  TRIM(i_search_values(g_search_pat_initials))
                                                 ELSE
                                                  NULL
                                             END;
    
    BEGIN
        -- check if there is at least one search criteria. 
        --If not, there is no point in performing search - no patient restrictions in the top search
        IF l_id_pat IS NULL
           AND l_bsn IS NULL
           AND l_ssn IS NULL
           AND l_nhn IS NULL
           AND l_recnum IS NULL
           AND l_birthdate IS NULL
           AND l_gender IS NULL
           AND l_surprefix IS NULL
           AND l_surmaiden IS NULL
           AND l_names IS NULL
           AND l_initials IS NULL
        THEN
            o_all_patients := pk_alert_constant.g_yes;
            RETURN TRUE;
        ELSE
            o_all_patients := pk_alert_constant.g_no;
        END IF;
    
        -- empty temp table
        g_error := 'TRUNCATE TEMPORARY TABLE PAT_TMPTAB_SEARCH';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE PAT_TMPTAB_SEARCH';
    
        -- search
        g_error := 'PERFORM SEARCH';
        CASE i_id_market
        -- ALL MARKETS
            WHEN pk_alert_constant.g_id_market_all THEN
                INSERT INTO pat_tmptab_search
                    SELECT p.id_patient
                      FROM alert_adtcod.v_patient_all_markets p
                     WHERE
                    -- pesquisa por id_patient
                     (l_id_pat IS NULL OR p.id_patient = l_id_pat);
            
        -- PT MARKET
            WHEN pk_alert_constant.g_id_market_pt THEN
                INSERT INTO pat_tmptab_search
                    SELECT p.id_patient
                      FROM patient p
                     WHERE
                    -- pesquisa por id_patient
                     (l_id_pat IS NULL OR p.id_patient = l_id_pat);
            
        -- DUTCH MARKET
            WHEN pk_alert_constant.g_id_market_nl THEN
                INSERT INTO pat_tmptab_search
                    SELECT DISTINCT p.id_patient
                      FROM patient p
                      JOIN person prs
                        ON prs.id_person = p.id_person
                      JOIN pat_identifier pi
                        ON p.id_patient = pi.id_patient
                     WHERE
                    -- pesquisa por id_patient
                     (l_id_pat IS NULL OR p.id_patient = l_id_pat)
                    -- pesquisa por BSN
                     AND (l_bsn IS NULL OR p.bsn = l_bsn)
                    -- pesquisa por SSN
                     AND (l_ssn IS NULL OR prs.social_security_number LIKE '%' || l_ssn || '%')
                    -- pesquisa por NHN
                     AND (l_nhn IS NULL OR p.national_health_number LIKE '%' || l_nhn || '%')
                    -- pesquisa por RECORD NUMBER
                     AND (l_recnum IS NULL OR pi.alert_process_number LIKE l_recnum || '%')
                    -- pesquisa por birthdate (i_birthdate tem de estar na forma YYYYMMDDhh24miss)
                     AND (l_birthdate IS NULL OR p.dt_birth = l_birthdate)
                    -- pesquisa por gender
                     AND (l_gender IS NULL OR p.gender = l_gender)
                    -- pesquisa por surname prefix
                     AND (l_surprefix IS NULL OR pk_utils.remove_upper_accentuation(p.surname_prefix) LIKE
                     '%' || pk_utils.remove_upper_accentuation(l_surprefix) || '%')
                    -- pesquisa por surname maiden
                     AND (l_surmaiden IS NULL OR pk_utils.remove_upper_accentuation(prs.surname_maiden) LIKE
                     '%' || pk_utils.remove_upper_accentuation(l_surmaiden) || '%')
                    -- pesquisa por name
                     AND (l_names IS NULL OR pk_utils.remove_upper_accentuation(p.name) LIKE
                     '%' || pk_utils.remove_upper_accentuation(l_names) || '%')
                    -- pesquisa por initials
                     AND (l_initials IS NULL OR p.initials LIKE '%' || TRIM(l_initials) || '%')
                    -- id_institution. em duvida
                     AND pi.id_institution = i_prof.institution;
            
        -- ADD OTHER MARKETS HERE
        
        -- ESCAPE CASE
            ELSE
                INSERT INTO pat_tmptab_search
                    SELECT DISTINCT p.id_patient
                      FROM alert_adtcod.v_patient_all_markets p
                     WHERE
                    -- pesquisa por id_patient
                     (l_id_pat IS NULL OR p.id_patient = l_id_pat)
                    -- pesquisa por RECORD NUMBER
                     AND (l_recnum IS NULL OR p.alert_process_number LIKE l_recnum || '%')
                    -- pesquisa por birthdate (i_birthdate tem de estar na forma YYYYMMDDhh24miss)
                     AND (l_birthdate IS NULL OR p.dt_birth = l_birthdate)
                    -- pesquisa por gender
                     AND (l_gender IS NULL OR p.gender = l_gender)
                    -- pesquisa por name
                     AND (l_names IS NULL OR pk_utils.remove_upper_accentuation(p.name) LIKE
                     '%' || pk_utils.remove_upper_accentuation(l_names) || '%')
                    -- id_institution. em duvida
                     AND p.id_institution = i_prof.institution;
            
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SEARCH_PATIENTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END search_patients;

    /******************************************************************************
       OBJECTIVE:   Return habit characterization values
       PARAMETERS:  IN:   I_LANG - Language ID
                          I_PROF - Professional data   
                    OUT:  O_HABIT_CHARACTERIZATION - Habit characterization values
                          O_ERROR - error
     
      CREATED: Sergio Dias 16-2-2011
    * @version 2.6.1.
    *********************************************************************************/
    FUNCTION get_habit_characterization
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_habit               IN habit.id_habit%TYPE,
        o_habit_characterization OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR(30) := 'GET_HABIT_CHARACTERIZATION';
    BEGIN
    
        g_error := 'GET O_HABIT_CHARACTERIZATION CURSOR';
        OPEN o_habit_characterization FOR
            SELECT hc.id_habit_characterization VALUE,
                   pk_translation.get_translation(i_lang, hc.code_habit_characterization) characterization
              FROM habit_characterization hc
              LEFT JOIN habit_charact_relation hcr
                ON hcr.id_habit_characterization = hc.id_habit_characterization
             WHERE hcr.id_habit = i_id_habit
               AND hcr.flg_available = pk_alert_constant.g_yes
             ORDER BY hc.rank, characterization;
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
            RETURN FALSE;
    END get_habit_characterization;

    /******************************************************************************
       OBJECTIVE:   Return habit info: characterization and start date
       PARAMETERS:  IN:   I_LANG - Language ID
                          I_PROF - Professional data   
                    OUT:  O_HABIT_CHARACTERIZATION - Habit characterization values
                          O_ERROR - error
     
      CREATED: Sofia Mendes 2-2-2011
    * @version 2.6.2.
    *********************************************************************************/
    FUNCTION get_pat_habit_info
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_habit           IN pat_habit.id_pat_habit%TYPE,
        o_habit_characterization OUT pk_translation.t_desc_translation,
        o_start_date             OUT pk_translation.t_desc_translation,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR(20) := 'GET_PAT_HABIT_INFO';
    BEGIN
    
        g_error := 'GET O_HABIT_CHARACTERIZATION CURSOR';
        SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => hc.code_habit_characterization),
               decode(ph.year_begin,
                      '',
                      '',
                      decode(ph.month_begin,
                             '',
                             to_char(ph.year_begin),
                             decode(ph.day_begin,
                                    '',
                                    substr(to_char(to_date(ph.year_begin || lpad(ph.month_begin, 2, '0'), 'YYYYMM'),
                                                   'DD-Mon-YYYY'),
                                           4),
                                    pk_date_utils.dt_chr(i_lang,
                                                         to_date(ph.year_begin || lpad(ph.month_begin, 2, '0') ||
                                                                 lpad(ph.day_begin, 2, '0'),
                                                                 'YYYYMMDD'),
                                                         i_prof)))) dt_begin
          INTO o_habit_characterization, o_start_date
          FROM pat_habit ph
          LEFT OUTER JOIN habit_characterization hc
            ON hc.id_habit_characterization = ph.id_habit_characterization
         WHERE ph.id_pat_habit = i_id_pat_habit;
    
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
            RETURN FALSE;
    END get_pat_habit_info;

    /**
    * Get a patient's national health service number.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               national health service number
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/02/08
    */
    FUNCTION get_nhs_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pat_health_plan.num_health_plan%TYPE IS
        l_idhp    pat_health_plan.id_health_plan%TYPE;
        l_ret     pat_health_plan.num_health_plan%TYPE;
        l_hp_ent  pk_translation.t_desc_translation;
        l_hp_desc pk_translation.t_desc_translation;
        l_error   t_error_out;
    BEGIN
        IF NOT pk_adt.get_national_health_number(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_patient      => i_patient,
                                                 o_hp_id_hp        => l_idhp,
                                                 o_num_health_plan => l_ret,
                                                 o_hp_entity       => l_hp_ent,
                                                 o_hp_desc         => l_hp_desc,
                                                 o_error           => l_error)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => l_error.ora_sqlcode);
        END IF;
    
        RETURN l_ret;
    END get_nhs_number;

    /********************************************************************************************
    * Get habits associated to a list of given episodes
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param o_habit             array with info habits
    *
    * @param o_error             Error message
    *
    * @return                    true or false on success or error
    *
    * @author                    Sofia Mendes (code separated from pk_episode.get_summary_s)
    * @since                     21/03/2013
    ********************************************************************************************/
    FUNCTION get_habits
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN table_number,
        o_habit OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(10 CHAR) := 'GET_HABITS';
    BEGIN
        --HÁBITOS
        g_error := 'CURSOR O_HABIT';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_habit FOR
            SELECT pk_translation.get_translation(i_lang, t.code_habit) || ' (' ||
                   pk_sysdomain.get_domain('PAT_HABIT.FLG_STATUS', t.flg_status, i_lang) || ')' desc_info,
                   t.id_episode,
                   pk_prof_utils.get_detail_signature(i_lang, i_prof, id_episode, dt_pat_habit_tstz, id_prof_writes) signature
              FROM (SELECT h.code_habit, ph.flg_status, ph.id_episode, ph.dt_pat_habit_tstz, ph.id_prof_writes
                      FROM pat_habit ph, habit h
                     WHERE ph.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                              *
                                               FROM TABLE(i_epis) t)
                       AND ph.flg_status != pk_alert_constant.g_cancelled
                       AND h.id_habit = ph.id_habit
                    UNION
                    SELECT h.code_habit, ph.flg_status, ph.id_episode, rd.dt_review, ph.id_prof_writes
                      FROM pat_habit ph, habit h, review_detail rd
                     WHERE rd.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                              *
                                               FROM TABLE(i_epis) t)
                       AND ph.flg_status != pk_alert_constant.g_cancelled
                       AND h.id_habit = ph.id_habit
                       AND ph.id_pat_habit = rd.id_record_area
                       AND rd.flg_context = pk_review.get_habits_context
                       AND flg_auto = pk_alert_constant.g_no
                       AND ph.id_pat_habit NOT IN
                           (SELECT ph.id_pat_habit
                              FROM pat_habit ph
                             WHERE ph.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                      *
                                                       FROM TABLE(i_epis) t)
                               AND ph.flg_status != pk_alert_constant.g_cancelled)) t
             ORDER BY dt_pat_habit_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_habits;
    /********************************************************************************************
    * Get list of episode (scope: patient/visit/episode)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        patient id
    * @param i_id_episode        episode id
    * @param i_flg_visit_or_epis scope (E-Episode, V-visit, P-Patient)
    *
    * @return                    episode list 
    *
    * @author                    Jorge Silva
    * @since                     25/09/2013
    ********************************************************************************************/
    FUNCTION get_episode_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN table_number IS
        l_episode table_number := table_number();
    BEGIN
        g_error := 'CALL get_episode_list';
    
        l_episode := get_episode_list(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_patient        => i_id_patient,
                                      i_id_episode        => i_id_episode,
                                      i_id_visit          => NULL,
                                      i_flg_visit_or_epis => i_flg_visit_or_epis);
    
        RETURN l_episode;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_episode_list;

    /********************************************************************************************
    * Get list of episode (scope: patient/visit/episode)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        patient id
    * @param i_id_episode        episode id
    * @param i_id_visit          visit_id
    * @param i_flg_visit_or_epis scope (E-Episode, V-visit, P-Patient)
    *
    * @return                    episode list 
    *
    * @author                    Joel Lopes
    * @since                     08/01/2014
    ********************************************************************************************/
    FUNCTION get_episode_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_id_visit          IN visit.id_visit%TYPE,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN table_number IS
        l_episode table_number := table_number();
    BEGIN
    
        --find list of episodes
    
        IF i_id_visit IS NOT NULL
           AND i_flg_visit_or_epis = g_scope_visit
        THEN
            BEGIN
                SELECT id_episode
                  BULK COLLECT
                  INTO l_episode
                  FROM episode epis
                 WHERE epis.id_visit = i_id_visit;
            EXCEPTION
                WHEN OTHERS THEN
                    l_episode := table_number();
            END;
        ELSIF i_id_episode IS NOT NULL
              AND i_flg_visit_or_epis = g_scope_visit
        THEN
            BEGIN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episode
                  FROM episode e
                 WHERE e.id_visit = (SELECT id_visit
                                       FROM episode epis
                                      WHERE epis.id_episode = i_id_episode);
            EXCEPTION
                WHEN OTHERS THEN
                    l_episode := table_number();
            END;
        ELSIF i_id_episode IS NOT NULL
              AND i_flg_visit_or_epis = g_scope_episode
        THEN
            l_episode.extend(1);
            l_episode(l_episode.count) := i_id_episode;
        ELSIF i_id_patient IS NOT NULL
              AND i_flg_visit_or_epis = g_scope_patient
        THEN
            BEGIN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episode
                  FROM episode e
                 WHERE e.id_patient = i_id_patient;
            EXCEPTION
                WHEN OTHERS THEN
                    l_episode := table_number();
            END;
        ELSE
            l_episode := table_number();
        END IF;
    
        RETURN l_episode;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_episode_list;

    /**
     * This function returns a true if the patient has any episode 
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   BOOLEAN
     *
     * @version  1.0
     * @since    2.5.2.7
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_any_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN IS
    
        l_epis_all     table_number := table_number();
        l_schedule_all table_number := table_number();
    
    BEGIN
        -- get all episodes that belongs to the patient    
        SELECT e.id_episode
          BULK COLLECT
          INTO l_epis_all
          FROM episode e
         WHERE e.id_patient = i_patient;
    
        -- get all schedule that belongs to the patient    
        SELECT sg.id_schedule
          BULK COLLECT
          INTO l_schedule_all
          FROM sch_group sg
         WHERE sg.id_patient = i_patient;
    
        RETURN(l_epis_all.count > 0 OR l_schedule_all.count > 0);
    
    END get_pat_has_any_episode;

    FUNCTION has_arabic_name(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
        l_count PLS_INTEGER;
        l_ret   VARCHAR2(1 CHAR);
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM patient p
         WHERE p.id_patient = i_patient
           AND coalesce(p.other_names_1, p.other_names_2, p.other_names_3) IS NOT NULL;
    
        IF l_count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END has_arabic_name;

    FUNCTION get_arabic_name(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1000 CHAR);
        --
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
    BEGIN
        IF has_arabic_name(i_patient => i_patient) = pk_alert_constant.g_yes
        THEN
            SELECT p.other_names_1, p.other_names_2, p.other_names_3
              INTO l_other_names_1, l_other_names_2, l_other_names_3
              FROM patient p
             WHERE p.id_patient = i_patient;
        
            IF l_other_names_1 IS NOT NULL
            THEN
                l_ret := l_other_names_1;
            END IF;
        
            IF l_other_names_2 IS NOT NULL
            THEN
                l_ret := CASE
                             WHEN l_ret IS NOT NULL THEN
                              l_ret || ' '
                             ELSE
                              NULL
                         END || l_other_names_2;
            END IF;
        
            IF l_other_names_3 IS NOT NULL
            THEN
                l_ret := CASE
                             WHEN l_ret IS NOT NULL THEN
                              l_ret || ' '
                             ELSE
                              NULL
                         END || l_other_names_3;
            END IF;
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_arabic_name;

    /**
     * This function returns a true if the patient has any episode not canceled
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   BOOLEAN
     *
     * @version  1.0
     * @since    2.5.2.7
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_any_episode_active
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN IS
    
        l_epis_all     table_number := table_number();
        l_schedule_all table_number := table_number();
    
    BEGIN
        -- get all episodes that belongs to the patient    
        SELECT e.id_episode
          BULK COLLECT
          INTO l_epis_all
          FROM episode e
         WHERE e.id_patient = i_patient
           AND e.flg_status <> g_flg_status_c;
    
        -- get all schedule that belongs to the patient    
        SELECT sg.id_schedule
          BULK COLLECT
          INTO l_schedule_all
          FROM sch_group sg
         WHERE sg.id_patient = i_patient;
    
        RETURN(l_epis_all.count > 0 OR l_schedule_all.count > 0);
    
    END get_pat_has_any_episode_active;

    /**
     * This function returns a Y/N if patient is inactive
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   Varchar
     *
     * @version  1.0
     * @since    2.6.4.3
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_inactive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_pat_flg_status VARCHAR2(1 CHAR);
    BEGIN
        -- get all episodes that belongs to the patient    
        SELECT CASE
                   WHEN p.flg_status IN (pk_patient.g_flg_status_i, pk_patient.g_flg_status_o) THEN
                    pk_alert_constant.g_yes
               
                   WHEN p.dt_deceased IS NOT NULL THEN
                    pk_alert_constant.g_yes
                   ELSE
                    pk_alert_constant.g_no
               END
        
          INTO l_pat_flg_status
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN(l_pat_flg_status);
    
    END get_pat_has_inactive;

    /********************************************************************************************
     * Gets patient/episode barcode
     *
     * @param i_lang          language id
     * @param i_prof          professional, software and institution ids
     * @param i_episode       episode id
    *********************************************************************************************/
    FUNCTION get_episode_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_error   t_error_out;
        l_barcode VARCHAR2(100);
    BEGIN
        IF NOT pk_patient.get_barcode(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_episode => i_episode,
                                      o_barcode => l_barcode,
                                      o_error   => l_error)
        THEN
            l_barcode := NULL;
        END IF;
        RETURN l_barcode;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
     * Gets patient blood type for CDA
     *
     * @param i_lang          language id
     * @param i_prof          professional, software and institution ids
     * @param i_id_patient    patient ID
    *********************************************************************************************/
    FUNCTION tf_pat_blood_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_pat_blood_cda
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_PAT_BLOOD_CDA';
    
        l_rec_pat_blood_cda t_rec_pat_blood_cda;
        l_error             t_error_out;
    BEGIN
    
        g_error := 'GET PATIENT BLOOD TYPE';
        FOR l_rec_pat_blood_cda IN (SELECT pbg.id_pat_blood_group,
                                           pbg.flg_status,
                                           pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_STATUS', pbg.flg_status, i_lang) desc_status,
                                           pbg.flg_blood_group,
                                           pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_GROUP',
                                                                   pbg.flg_blood_group,
                                                                   i_lang) blood_group,
                                           pbg.flg_blood_rhesus,
                                           pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS',
                                                                   pbg.flg_blood_rhesus,
                                                                   i_lang) blood_rhesus,
                                           pk_date_utils.date_send_tsz(i_lang, pbg.dt_pat_blood_group_tstz, i_prof) dt_reg_str,
                                           pbg.dt_pat_blood_group_tstz dt_reg_tstz,
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       pbg.dt_pat_blood_group_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software) dt_reg_formatted
                                      FROM pat_blood_group pbg
                                     WHERE pbg.id_patient = i_id_patient)
        LOOP
            PIPE ROW(l_rec_pat_blood_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN;
    END tf_pat_blood_cda;

    /********************************************************************************************
    * Function that returns the patient job ID
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    *
    * @return                         ID_OCUPATION
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_pat_job(i_id_pat IN patient.id_patient%TYPE) RETURN pat_job.id_occupation%TYPE IS
    
        CURSOR c_job IS
            SELECT p.id_occupation
              FROM pat_job p
             WHERE p.id_patient = i_id_pat
               AND p.dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                          FROM pat_job p1
                                         WHERE p1.id_patient = i_id_pat)
               AND p.flg_status = pk_alert_constant.g_active;
    
        l_id_ocupation pat_job.id_occupation%TYPE;
    BEGIN
        g_error := 'GET CURSOR C_JOB';
        OPEN c_job;
        FETCH c_job
            INTO l_id_ocupation;
        CLOSE c_job;
    
        RETURN l_id_ocupation;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_pat_job;

    /********************************************************************************************
    * Function that returns Age type of a patient
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    *
    * @return                         Type of age (Mi- Minutes/ H - Hour/D - Day/M - Months /Y - Years)
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          30/01/2017
    **********************************************************************************************/

    FUNCTION get_pat_age_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_date    IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_type     VARCHAR2(200 CHAR);
        l_year     NUMBER;
        l_month    NUMBER;
        l_day      NUMBER;
        l_hour     NUMBER;
        l_minute   NUMBER;
        l_flg_type patient.flg_type_dt_birth%TYPE;
        k_dt_ne     CONSTANT VARCHAR2(0200 CHAR) := '8';
        k_dt_ignore CONSTANT VARCHAR2(0200 CHAR) := '9';
        l_dt TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        SELECT flg_type_dt_birth
          INTO l_flg_type
          FROM patient
         WHERE id_patient = i_patient;
    
        l_dt := nvl(i_date, current_timestamp);
    
        CASE nvl(l_flg_type, g_flg_type_birth_f)
            WHEN g_flg_type_birth_si THEN
                l_type := k_dt_ignore;
            WHEN g_flg_type_birth_ne THEN
                l_type := k_dt_ne;
            WHEN g_flg_type_birth_f THEN
                SELECT trunc(months_between(nvl(dt_deceased, l_dt), nvl(dt_birth_tstz, dt_birth)) / 12) YEAR,
                       trunc(MOD(months_between(nvl(dt_deceased, l_dt), nvl(dt_birth_tstz, dt_birth)), 12)) MONTH,
                       trunc(to_date(to_char(nvl(dt_deceased, l_dt), 'YYYY-MON-DD HH24:MI:SS'),
                                     'YYYY-MON-DD HH24:MI:SS') -
                             add_months(nvl(dt_birth_tstz, dt_birth),
                                        trunc(months_between(nvl(dt_deceased, l_dt), nvl(dt_birth_tstz, dt_birth)) / 12) * 12 +
                                        trunc(MOD(months_between(nvl(dt_deceased, l_dt), nvl(dt_birth_tstz, dt_birth)),
                                                  12)))) DAY,
                       extract(hour FROM(nvl(dt_deceased, l_dt) - dt_birth_tstz)) hour,
                       extract(minute FROM(nvl(dt_deceased, l_dt) - dt_birth_tstz)) minute
                  INTO l_year, l_month, l_day, l_hour, l_minute
                  FROM patient p
                 WHERE p.id_patient = i_patient;
            
                IF l_year > 0
                THEN
                    l_type := 'Y';
                ELSIF l_month > 0
                THEN
                    l_type := 'M';
                ELSIF l_day > 0
                THEN
                    l_type := 'D';
                ELSIF l_hour > 0
                THEN
                    l_type := 'H';
                ELSIF l_minute > 0
                THEN
                    l_type := 'MI';
                ELSE
                    l_type := NULL;
                END IF;
        END CASE;
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age_type;

    /********************************************************************************************
    * Function that returns the age in 
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    * @param i_type                   Type of age (H - Hour/D - Day/M - Months /Y - Years)
    * 
    * @return                         age based on type
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          30/01/2017
    **********************************************************************************************/
    FUNCTION get_pat_age_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2,
        i_view    IN VARCHAR2 DEFAULT 'N',
        i_date    IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
        l_year     NUMBER;
        l_month    NUMBER;
        l_day      NUMBER;
        l_hour     NUMBER;
        l_minute   NUMBER;
        l_flg_type patient.flg_type_dt_birth%TYPE;
        k_dt_ne     CONSTANT NUMBER := 888;
        k_dt_ignore CONSTANT NUMBER := 999;
        k_ignore    CONSTANT NUMBER := 99;
        l_dt     TIMESTAMP WITH LOCAL TIME ZONE;
        l_type   VARCHAR2(200 CHAR);
        l_return NUMBER;
    
        k_yes CONSTANT VARCHAR2(0010 CHAR) := pk_alert_constant.g_yes;
        k_no  CONSTANT VARCHAR2(0010 CHAR) := pk_alert_constant.g_no;
    
        k_date_mask      CONSTANT VARCHAR2(0200 CHAR) := 'YYYY-MON-DD HH24:MI:SS';
        k_days_in_week   CONSTANT NUMBER := 7;
        k_months_in_year CONSTANT NUMBER := 12;
    
        k_flg_level_dt_birth_y  CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_flg_level_dt_birth_m  CONSTANT VARCHAR2(0010 CHAR) := 'M';
        k_flg_level_dt_birth_d  CONSTANT VARCHAR2(0010 CHAR) := 'D';
        k_flg_level_dt_birth_h  CONSTANT VARCHAR2(0010 CHAR) := 'H';
        k_flg_level_dt_birth_w  CONSTANT VARCHAR2(0010 CHAR) := 'W';
        k_flg_level_dt_birth_mi CONSTANT VARCHAR2(0010 CHAR) := 'MI';
    
        r_pat patient%ROWTYPE;
    
        FUNCTION iif
        (
            i_bool  IN BOOLEAN,
            i_true  IN NUMBER,
            i_false IN NUMBER
        ) RETURN NUMBER IS
        BEGIN
            IF i_bool
            THEN
                RETURN i_true;
            ELSE
                RETURN i_false;
            END IF;
        END iif;
    
        -- *********************************************
        FUNCTION get_pat_age_type RETURN VARCHAR2 IS
            l_return VARCHAR2(0200 CHAR);
            l_type   VARCHAR2(0200 CHAR);
        BEGIN
        
            l_type := i_type;
            IF l_type IS NULL
            THEN
                l_type := pk_patient.get_pat_age_type(i_lang    => NULL,
                                                      i_prof    => i_prof,
                                                      i_patient => i_patient,
                                                      i_date    => i_date);
            END IF;
        
            RETURN l_type;
        
        END get_pat_age_type;
    
        FUNCTION get_case_type RETURN VARCHAR2 IS
            l_return NUMBER;
        BEGIN
        
            CASE l_type
                WHEN k_flg_level_dt_birth_y THEN
                    l_return := l_year;
                WHEN k_flg_level_dt_birth_m THEN
                    l_return := l_month;
                WHEN k_flg_level_dt_birth_d THEN
                    l_return := l_day;
                WHEN k_flg_level_dt_birth_w THEN
                    l_return := trunc(l_day / k_days_in_week);
                WHEN k_flg_level_dt_birth_h THEN
                    l_return := l_hour;
                WHEN k_flg_level_dt_birth_mi THEN
                    l_return := l_minute;
                ELSE
                    l_return := NULL;
            END CASE;
        
            RETURN l_return;
        
        END get_case_type;
    
    BEGIN
    
        SELECT flg_type_dt_birth, dt_deceased, dt_birth_tstz, dt_birth
          INTO r_pat.flg_type_dt_birth, r_pat.dt_deceased, r_pat.dt_birth_tstz, r_pat.dt_birth
          FROM patient
         WHERE id_patient = i_patient;
    
        l_dt       := nvl(i_date, current_timestamp);
        l_flg_type := coalesce(r_pat.flg_type_dt_birth, g_flg_type_birth_f);
    
        CASE l_flg_type
            WHEN g_flg_type_birth_si THEN
            
                l_return := iif(i_view = k_yes, k_ignore, k_dt_ignore);
            
            WHEN g_flg_type_birth_ne THEN
            
                l_return := iif(i_view = k_yes, k_ignore, k_dt_ne);
            
            WHEN g_flg_type_birth_f THEN
            
                r_pat.dt_deceased   := nvl(r_pat.dt_deceased, l_dt);
                r_pat.dt_birth_tstz := nvl(r_pat.dt_birth_tstz, r_pat.dt_birth);
            
                l_year  := trunc(months_between(r_pat.dt_deceased, r_pat.dt_birth_tstz) / k_months_in_year);
                l_month := trunc(MOD(months_between(r_pat.dt_deceased, r_pat.dt_birth_tstz), k_months_in_year));
            
                l_day    := trunc(to_date(to_char(r_pat.dt_deceased, k_date_mask), k_date_mask) -
                                  add_months(r_pat.dt_birth_tstz, l_year * k_months_in_year + l_month));
                l_hour   := extract(hour FROM(r_pat.dt_deceased - r_pat.dt_birth_tstz));
                l_minute := extract(minute FROM(r_pat.dt_deceased - r_pat.dt_birth_tstz));
            
                l_type := get_pat_age_type();
            
                l_return := get_case_type();
            
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age_num;

    FUNCTION get_partial_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_ne      IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
    
        k_partial CONSTANT VARCHAR2(0200 CHAR) := '99';
        l_dt_birth_tstz patient.dt_birth_tstz%TYPE;
        l_flg_type_dt   patient.flg_type_dt_birth%TYPE;
        l_flg_level_dt  patient.flg_level_dt_birth%TYPE;
        k_dt_ne     CONSTANT VARCHAR2(0200 CHAR) := '88/88/8888';
        k_dt_ignore CONSTANT VARCHAR2(0200 CHAR) := '99/99/9999';
        l_return VARCHAR2(0200 CHAR);
    BEGIN
        SELECT nvl(p.dt_birth_tstz, p.dt_birth), flg_type_dt_birth, flg_level_dt_birth
          INTO l_dt_birth_tstz, l_flg_type_dt, l_flg_level_dt
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        CASE nvl(l_flg_type_dt, g_flg_type_birth_f)
            WHEN g_flg_type_birth_si THEN
                l_return := k_dt_ignore;
            WHEN g_flg_type_birth_ne THEN
                IF i_ne = pk_alert_constant.g_yes
                THEN
                    l_return := k_dt_ne;
                ELSE
                    l_return := k_dt_ignore;
                END IF;
            WHEN g_flg_type_birth_f THEN
                CASE l_flg_level_dt
                    WHEN g_flg_level_dt_birth_y THEN
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => l_dt_birth_tstz,
                                                                       i_mask      => 'YYYY');
                        l_return := k_partial || '/' || k_partial || '/' || l_return;
                    WHEN g_flg_level_dt_birth_m THEN
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => l_dt_birth_tstz,
                                                                       i_mask      => 'MM/YYYY');
                        l_return := k_partial || '/' || l_return;
                    ELSE
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => l_dt_birth_tstz,
                                                                       i_mask      => 'DD/MM/YYYY');
                END CASE;
        END CASE;
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_partial_pat_age;

    FUNCTION get_patient_ssn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_ssn_status         person.flg_ssn_status%TYPE;
        l_social_security_number person.social_security_number%TYPE;
        l_value                  VARCHAR2(200 CHAR);
        l_msg_ne                 sys_message.code_message%TYPE := 'PATIENT_IDENT_T035';
        l_msg_si                 sys_message.code_message%TYPE := 'PATIENT_IDENT_T036';
    BEGIN
        SELECT p.flg_ssn_status, p.social_security_number
          INTO l_flg_ssn_status, l_social_security_number
          FROM person p
          JOIN patient pat
            ON p.id_person = pat.id_person
         WHERE pat.id_patient = i_patient;
    
        CASE l_flg_ssn_status
            WHEN g_flg_ssn_status_d THEN
                l_value := l_social_security_number;
            WHEN g_flg_ssn_status_n THEN
                l_value := upper(pk_message.get_message(i_lang, i_prof, l_msg_si));
            ELSE
                l_value := upper(pk_message.get_message(i_lang, i_prof, l_msg_ne));
        END CASE;
        RETURN l_value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_ssn;

    FUNCTION get_pat_bed(i_id_episode IN epis_info.id_episode%TYPE) RETURN epis_info.id_bed%TYPE IS
        l_bed   epis_info.id_bed%TYPE;
        tbl_bed table_number;
    BEGIN
        SELECT ei.id_bed
          BULK COLLECT
          INTO tbl_bed
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        IF tbl_bed.count > 0
        THEN
            l_bed := tbl_bed(1);
        END IF;
    
        RETURN l_bed;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_bed;

    FUNCTION get_pat_bed_dept
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN drug_req.id_episode%TYPE
    ) RETURN department.id_department%TYPE IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PAT_BED_DEPT';
        --
        l_id_epis_department dep_clin_serv.id_department%TYPE := NULL;
        l_error              t_error_out;
        l_count              PLS_INTEGER;
    BEGIN
        BEGIN
            g_error := 'GET_PAT_BED';
            SELECT r.id_department
              INTO l_id_epis_department
              FROM epis_info ei
              JOIN bed b
                ON b.id_bed = ei.id_bed
              JOIN room r
                ON r.id_room = b.id_room
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                --If it is an INP episode that comes from EDIS and it is yet located in EDIS
                BEGIN
                    g_error := 'GET episode department';
                    SELECT CASE
                               WHEN e.id_department_requested <> -1 THEN
                                e.id_department_requested
                               ELSE
                                dcs.id_department
                           END
                      INTO l_id_epis_department
                      FROM epis_info ei
                      JOIN episode e
                        ON e.id_episode = ei.id_episode
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                     WHERE ei.id_episode = i_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        RETURN NULL;
                END;
        END;
    
        RETURN l_id_epis_department;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_BED_DEPT',
                                              l_error);
            RETURN NULL;
    END get_pat_bed_dept;

    /**
    * FUNCTION get_alert_process_number 
    *
    * @param i_lang                        Language identification 
    * @param i_prof                        Professional data 
    * @param i_episode                     Episode id
    *
    * @return                              Return alert_process_number column value
    *
    * @raises                              PL/SQL generic error "OTHERS"
    *
    * @author                              Amanda Lee
    * @version                             V2.7.3.6
    * @since                               2018-07-03
    */
    FUNCTION get_alert_process_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pat_identifier.alert_process_number%TYPE IS
    
        l_id_patient patient.id_patient%TYPE;
    
        l_process_number pat_identifier.alert_process_number%TYPE;
    
    BEGIN
    
        l_id_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        l_process_number := pk_patient.get_process_number(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => l_id_patient);
    
        RETURN l_process_number;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alert_process_number;

    FUNCTION ckeck_has_process_number
    (
        i_patient     IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
        l_alert_process_number table_varchar := table_varchar();
        l_ret                  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        SELECT pi.alert_process_number
          BULK COLLECT
          INTO l_alert_process_number
          FROM pat_identifier pi
         WHERE pi.id_institution = i_institution
           AND pi.id_patient = i_patient
           AND pi.flg_status = pk_alert_constant.g_active
           AND pi.alert_process_number IS NOT NULL;
        IF l_alert_process_number.count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
        
    END;

    FUNCTION get_patient_restricted_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_info       VARCHAR2(4000 CHAR);
        l_vip_status VARCHAR2(4000 CHAR);
    
    BEGIN
    
        SELECT p.vip_status
          INTO l_vip_status
          FROM patient p
         WHERE id_patient = i_patient;
    
        CASE l_vip_status
            WHEN 'V' THEN
                l_info := 'Very, Very Important Person (teste VS)';
            WHEN 'I' THEN
                l_info := 'Very Important Person (teste VS)';
            WHEN 'C' THEN
                l_info := 'Cenas(teste VS)';
            ELSE
                l_info := pk_alert_constant.g_no;
        END CASE;
    
        RETURN l_info;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_patient_restricted_info;

    FUNCTION get_pat_dt_birth
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN DATE IS
    
        l_date DATE;
    
    BEGIN
    
        SELECT p.dt_birth
          INTO l_date
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN l_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_dt_birth;

    FUNCTION get_pat_preferred_language
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret    VARCHAR2(1000);
        l_prefix VARCHAR2(1000) := 'LANGUAGE.CODE_LANGUAGE.';
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, l_prefix || p.id_preferred_language)
          INTO l_ret
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_preferred_language;

    FUNCTION get_pat_marital_state
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    )
    
     RETURN VARCHAR2 IS
        l_ret VARCHAR2(800);
    BEGIN
    
        SELECT pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', p.marital_status, i_lang)
          INTO l_ret
          FROM pat_soc_attributes p
         WHERE p.id_patient = i_patient;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_marital_state;

    FUNCTION get_pat_religion
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    )
    
     RETURN VARCHAR2 IS
        l_ret VARCHAR2(800);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, 'RELIGION.CODE_RELIGION.' || p.id_religion)
          INTO l_ret
          FROM pat_soc_attributes p
         WHERE p.id_patient = i_patient;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_religion;

    FUNCTION get_pat_address
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
        SELECT pk_adt.get_regional_classifier_desc(i_lang,
                                                   i_prof,
                                                   (pk_adt.get_rb_reg_classifier_id(pk_adt.get_patient_address_id(p.id_person),
                                                                                    5)))
          INTO l_ret
          FROM patient p
         WHERE id_patient = i_patient;
    
        RETURN l_ret;
    END get_pat_address;

    FUNCTION get_process_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_identifier.alert_process_number%TYPE IS
        l_ret                  pat_identifier.alert_process_number%TYPE;
        l_alert_process_number table_varchar := table_varchar();
        l_error                t_error_out;
    BEGIN
        SELECT t.alert_process_number
          BULK COLLECT
          INTO l_alert_process_number
          FROM (SELECT pi.alert_process_number, row_number() over(ORDER BY pi.id_institution DESC) line_number
                  FROM pat_identifier pi
                 WHERE pi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND pi.id_patient = i_id_patient
                   AND pi.flg_status = pk_alert_constant.g_active
                 ORDER BY pi.register_date NULLS LAST) t
         WHERE t.line_number = 1;
    
        IF l_alert_process_number.count > 0
        THEN
            l_ret := l_alert_process_number(1);
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCESS_NUMBER',
                                              l_error);
            RETURN NULL;
    END get_process_number;

    FUNCTION get_patient_phone
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(100 CHAR);
        l_dummy  VARCHAR2(200 CHAR);
        l_error  t_error_out;
    BEGIN
    
        IF NOT pk_adt.get_contact_info(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_patient  => i_patient,
                                       o_address  => l_dummy,
                                       o_location => l_dummy,
                                       o_regional => l_dummy,
                                       o_phone1   => l_return,
                                       o_phone2   => l_dummy,
                                       o_error    => l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_patient_phone;

    FUNCTION get_institution_from_group(i_prof IN profissional) RETURN table_number IS
        tbl_id     table_number;
        l_id_group NUMBER;
    BEGIN
    
        SELECT id_group
          BULK COLLECT
          INTO tbl_id
          FROM institution_group
         WHERE flg_relation = 'ADT'
           AND id_institution = i_prof.institution;
    
        IF tbl_id.count > 0
        THEN
        
            l_id_group := tbl_id(1);
        
            SELECT id_institution
              BULK COLLECT
              INTO tbl_id
              FROM (SELECT id_institution
                      FROM institution_group
                     WHERE id_group = l_id_group
                       AND flg_relation = 'ADT'
                    UNION
                    SELECT 0
                      FROM dual);
        
        ELSE
        
            tbl_id := table_number(i_prof.institution, 0);
        
        END IF;
    
        RETURN tbl_id;
    
    END get_institution_from_group;

    FUNCTION get_patient_docid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.document_identifier_number%TYPE IS
        l_ret                        pat_soc_attributes.document_identifier_number%TYPE;
        l_document_identifier_number table_varchar := table_varchar();
        l_error                      t_error_out;
        k_active CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_active;
        k_all    CONSTANT NUMBER := pk_alert_constant.g_inst_all;
        tbl_group table_number := table_number();
    BEGIN
    
        tbl_group := get_institution_from_group(i_prof);
    
        SELECT t.document_identifier_number
          BULK COLLECT
          INTO l_document_identifier_number
          FROM (SELECT psa.document_identifier_number
                  FROM pat_soc_attributes psa
                  JOIN (SELECT /*+ opt_estimate (table ig rows=1) */
                        column_value id_institution
                         FROM TABLE(tbl_group)) ig
                    ON ig.id_institution = psa.id_institution
                 WHERE nvl(psa.record_status, k_active) = k_active
                   AND psa.id_patient = i_id_patient
                --and psa.id_institution IN (i_prof.institution, k_all )
                 ORDER BY decode(psa.id_institution, i_prof.institution, -99, 1) ASC) t
         WHERE rownum = 1;
    
        IF l_document_identifier_number.count > 0
        THEN
            l_ret := l_document_identifier_number(1);
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_DOCID',
                                              l_error);
            RETURN NULL;
    END get_patient_docid;

    FUNCTION get_pat_name_without_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN patient.name%TYPE IS
    BEGIN
    
        RETURN pk_adt.get_patient_name(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_patient       => i_patient,
                                       i_is_prof_resp  => 0,
                                       i_id_sys_config => i_id_sys_config);
    
    END get_pat_name_without_resp;

    FUNCTION get_patient_minimal_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_data FOR
            SELECT nvl2(p.first_name || p.last_name,
                        p.first_name || ' ' || p.last_name,
                        pk_patient.get_pat_name_without_resp(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_patient => i_patient,
                                                             i_episode => NULL)) pat_name,
                   get_pat_age(i_lang => i_lang, i_id_pat => p.id_patient, i_prof => i_prof) pat_age,
                   get_pat_gender(i_id_patient => p.id_patient) pat_gender,
                   pk_patphoto.get_pat_photo(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_id_patient  => i_patient,
                                             i_id_episode  => NULL,
                                             i_id_schedule => NULL) pat_photo
              FROM patient p
             WHERE p.id_patient = i_patient;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_MINIMAL_DATA',
                                              o_error);
            RETURN FALSE;
    END get_patient_minimal_data;

    FUNCTION get_pat_health_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN VARCHAR2 AS
        l_tbl_v table_varchar := table_varchar();
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, hp.code_health_plan) hplan
          BULK COLLECT
          INTO l_tbl_v
          FROM pat_health_plan php
          JOIN health_plan hp
            ON php.id_health_plan = hp.id_health_plan
         WHERE php.id_patient = i_patient
           AND hp.flg_available = pk_alert_constant.g_yes
           AND php.institution_key = i_prof.institution;
    
        IF l_tbl_v.count > 0
        THEN
            RETURN l_tbl_v(1);
        ELSE
            RETURN NULL;
        END IF;
    END get_pat_health_plan;
    FUNCTION get_pat_hplan_entity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN VARCHAR2 AS
        l_tbl_v table_varchar := table_varchar();
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) hpentity
          BULK COLLECT
          INTO l_tbl_v
          FROM pat_health_plan php
          JOIN health_plan hp
            ON php.id_health_plan = hp.id_health_plan
          LEFT JOIN health_plan_entity hpe
            ON hp.id_health_plan_entity = hpe.id_health_plan_entity
         WHERE php.id_patient = i_patient
           AND hp.flg_available = pk_alert_constant.g_yes
           AND php.institution_key = i_prof.institution;
    
        IF l_tbl_v.count > 0
        THEN
            RETURN l_tbl_v(1);
        ELSE
            RETURN NULL;
        END IF;
    END get_pat_hplan_entity;

    ---- for ordering
    FUNCTION get_pat_age_to_sort(i_patient IN NUMBER) RETURN NUMBER IS
        l_return  NUMBER := 0;
        tbl_order table_number;
    BEGIN
    
        SELECT extract(DAY FROM duration) + (extract(hour FROM duration) / 100) xorder
          BULK COLLECT
          INTO tbl_order
          FROM (SELECT coalesce(t.dt_deceased, current_timestamp) - t.dt_birth duration
                  FROM patient t
                 WHERE t.id_patient = i_patient) xsql;
    
        IF tbl_order.count > 0
        THEN
            IF tbl_order(1) IS NULL
            THEN
                SELECT t.age
                  INTO l_return
                  FROM patient t
                 WHERE t.id_patient = i_patient
                   AND rownum = 1;
            ELSE
                l_return := tbl_order(1);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_pat_age_to_sort;

    FUNCTION get_pat_scholarship
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret         VARCHAR2(4000);
        l_scholarship table_varchar := table_varchar();
    BEGIN
        SELECT pk_translation.get_translation(i_lang, s.code_scholarship)
          BULK COLLECT
          INTO l_scholarship
          FROM pat_soc_attributes psa
          JOIN scholarship s
            ON s.id_scholarship = psa.id_scholarship
         WHERE psa.id_patient = i_patient;
    
        IF l_scholarship.count > 0
        THEN
            l_ret := l_scholarship(1);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_scholarship;

    FUNCTION get_pat_country_birth
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret            VARCHAR2(4000);
        l_country_nation table_varchar := table_varchar();
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, c.code_country)
          BULK COLLECT
          INTO l_country_nation
          FROM pat_soc_attributes psa
          JOIN country c
            ON c.id_country = psa.id_country_nation
         WHERE psa.id_patient = i_patient;
    
        IF l_country_nation.count > 0
        THEN
            l_ret := l_country_nation(1);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_country_birth;

    FUNCTION get_pat_occupation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret        VARCHAR2(4000);
        l_occupation table_varchar := table_varchar();
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, o.code_occupation)
          BULK COLLECT
          INTO l_occupation
          FROM occupation o
          JOIN (SELECT *
                  FROM pat_job
                 WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                            FROM pat_job p1
                                           WHERE p1.id_patient = i_patient)) pj
            ON pj.id_occupation = o.id_occupation;
    
        IF l_occupation.count > 0
        THEN
            l_ret := l_occupation(1);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_occupation;

    FUNCTION get_pat_race
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret     VARCHAR2(4000);
        l_id_race NUMBER(12);
    BEGIN
    
        IF NOT pk_adt_core.get_pat_race(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_patient   => i_patient,
                                        o_id_race   => l_id_race,
                                        o_desc_race => l_ret)
        THEN
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_race;

    FUNCTION get_pat_job_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret        VARCHAR2(4000);
        l_job_status table_varchar;
    BEGIN
    
        SELECT pk_sysdomain.get_domain_no_avail('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', t.flg_job_status, i_lang)
          BULK COLLECT
          INTO l_job_status
          FROM (SELECT pi.flg_job_status, row_number() over(ORDER BY pi.id_institution DESC) line_number
                  FROM pat_soc_attributes pi
                 WHERE pi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND pi.id_patient = i_patient
                   AND pi.record_status = pk_alert_constant.g_active) t
         WHERE t.line_number = 1;
    
        IF l_job_status.count > 0
        THEN
            l_ret := l_job_status(1);
        END IF;
    
        RETURN l_ret;
    END get_pat_job_status;

    FUNCTION get_pat_job_company
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret     VARCHAR2(4000);
        l_company table_varchar := table_varchar();
    BEGIN
    
        SELECT pj.company
          BULK COLLECT
          INTO l_company
          FROM pat_job pj
         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                    FROM pat_job p1
                                   WHERE p1.id_patient = i_patient);
    
        IF l_company.count > 0
        THEN
            l_ret := l_company(1);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_pat_job_company;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_patient;
/
