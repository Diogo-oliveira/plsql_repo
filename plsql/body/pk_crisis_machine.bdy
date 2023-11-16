/*-- Last Change Revision: $Rev: 2026923 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_crisis_machine IS

    -- Private package costants
    g_flg_status_waiting     CONSTANT VARCHAR2(1) := 'W';
    g_flg_status_in_progress CONSTANT VARCHAR2(1) := 'P';
    g_flg_status_generated   CONSTANT VARCHAR2(1) := 'G';
    g_flg_status_error       CONSTANT VARCHAR2(1) := 'E';
    g_flg_status_retry       CONSTANT VARCHAR2(1) := 'R';

    g_epis_type_sch CONSTANT VARCHAR2(3) := 'SCH';

    g_active          CONSTANT pat_blood_group.flg_status%TYPE := 'A';
    g_epis_active     CONSTANT VARCHAR2(1) := 'A';
    g_flg_rsync       CONSTANT VARCHAR2(1) := 'R';
    g_cl_flg_status_e CONSTANT VARCHAR2(1) := 'E';
    g_sched_adm_disch CONSTANT VARCHAR2(1) := 'M';
    g_sched_canc      CONSTANT VARCHAR2(1) := 'C';
    g_sched_scheduled CONSTANT VARCHAR2(1) := 'A';
    g_inp_epis_type   CONSTANT VARCHAR2(1) := 5;
    g_yes             CONSTANT VARCHAR2(1) := 'Y';
    g_modules         CONSTANT VARCHAR2(7) := 'modules';
    g_obs_epis_type   CONSTANT VARCHAR2(1) := 6;
    g_dummy_episode   CONSTANT episode.id_episode%TYPE := -1;

    -- Private package variables
    g_cm_dir_gen               VARCHAR2(200);
    g_cm_dir_upd               VARCHAR2(200);
    g_cm_dir_stage             VARCHAR2(200);
    g_cm_keys_path             VARCHAR2(200);
    g_cm_job_update_class      VARCHAR2(200);
    g_cm_job_generate_class    VARCHAR2(200);
    g_cm_job_generate_interval VARCHAR2(20);
    --g_crontab_file_name VARCHAR2(200);
    g_error             VARCHAR2(4000);
    g_cm_targetfolder   sys_config.value%TYPE;
    g_tunnelremotehost  sys_config.value%TYPE;
    g_rsync_server_user sys_config.value%TYPE;
    g_separator         VARCHAR2(200);
    g_sysdate_char      VARCHAR2(50);
    g_sysdate_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
    --g_win_copy_dir      VARCHAR2(200);
    g_package_name     VARCHAR2(30);
    g_package_owner    VARCHAR2(30);
    g_default_ssh_port NUMBER := 22;

    TYPE type_file_count IS TABLE OF NUMBER INDEX BY VARCHAR2(4000);
    g_file_count type_file_count;

    TYPE silhouette_type IS TABLE OF VARCHAR(30) INDEX BY VARCHAR(30);
    g_silhouette_lst silhouette_type;

    -- User defined exceptions
    g_exception EXCEPTION;

    --XSL for header processing
    g_header_xsl xmltype := xmltype.createxml('<?xml version="1.0" encoding="ISO-8859-1"?>
    <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:template match="/">
        <HEADER>
          <xsl:for-each select="ROWSET/ROW">
            <xsl:variable name="newTagValue">
              <xsl:choose>
                <xsl:when test="TAG=''EPIS_MANCH_COLOR''">
                  <xsl:value-of select="''O_ACUITY''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_ALLERGIES''">
                  <xsl:value-of select="''O_ALLERGY''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_BLOOD_TYPE''">
                  <xsl:value-of select="''O_BLOOD_TYPE''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_PREV_EPIS''">
                  <xsl:value-of select="''O_PREV_EPIS''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_HABITS''">
                  <xsl:value-of select="''O_HABIT''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_RELEV_NOTES''">
                  <xsl:value-of select="''O_RELEV_NOTE''" />
                </xsl:when>
                <xsl:when test="TAG=''EPIS_COMP_DIAG''">
                  <xsl:value-of select="''O_COMPL_DIAG''" />
                </xsl:when>
                <xsl:when test="TAG=''EPIS_LOCATION''">
                  <xsl:value-of select="''O_LOCATION_V''" />
                </xsl:when>
                <xsl:when test="TAG=''EPIS_NUMBER''">
                  <xsl:value-of select="''O_EPISODE_V''" />
                </xsl:when>
                <xsl:when test="TAG=''LABEL_EPIS''">
                  <xsl:value-of select="''O_EPISODE_T''" />
                </xsl:when>
                <xsl:when test="TAG=''LABEL_LOCATION''">
                  <xsl:value-of select="''O_LOCATION_T''" />
                </xsl:when>
                <xsl:when test="TAG=''PAT_NAME''">
                  <xsl:value-of select="''O_NAME''" />
                </xsl:when>
                <xsl:when test="TAG=''PAT_GENDER_AGE_PREG_WEEKS''">
                  <xsl:value-of select="''O_AGE''" />
                </xsl:when>
                <xsl:when test="TAG=''PAT_RECM_NO_ALLERGY_MED''">
                  <xsl:value-of select="''O_NKDA''" />
                </xsl:when>
                <xsl:when test="TAG=''LABEL_PROCESS''">
                  <xsl:value-of select="''O_CLIN_REC_T''" />
                </xsl:when>
                <xsl:when test="TAG=''EPIS_PROCESS''">
                  <xsl:value-of select="''O_CLIN_REC_V''" />
                </xsl:when>
                <xsl:when test="TAG=''EPIS_SOFTWARE''">
                  <xsl:value-of select="''O_APPLICATION''" />
                </xsl:when>
                <xsl:when test="TAG=''EHR_PREV_MED_HIST''">
                  <xsl:value-of select="''O_RELEV_DISEASE''" />
                </xsl:when>
                <!--<xsl:when test="TAG=''EPIS_LABEL_DISPOSITION_DATE''"> <xsl:value-of 
                  select="''O_DISCH_T''" /> </xsl:when> <xsl:when test="TAG=''EPIS_DISPOSITION_DATE''"> 
                  <xsl:value-of select="''O_DISCH_V''" /> </xsl:when> <xsl:when test="TAG=''EPIS_SCHEDULE''"> 
                  <xsl:value-of select="''O_SCHED_V''" /> </xsl:when> <xsl:when test="TAG=''EPIS_SERVICE''"> 
                  <xsl:value-of select="''O_SERV''" /> </xsl:when> <xsl:when test="TAG=''LABEL_SCHEDULE''"> 
                  <xsl:value-of select="''O_SCHED_T''" /> </xsl:when> <xsl:when test="TAG=''PAT_GENDER''"> 
                  <xsl:value-of select="''O_GENDER''" /> </xsl:when> <xsl:when test="TAG=''PAT_HEALTH_PLAN''"> 
                  <xsl:value-of select="''O_HEALTH_PLAN''" /> </xsl:when> <xsl:when test="TAG=''PROF_NAME''"> 
                  <xsl:value-of select="''O_PROF_NAME''" /> </xsl:when> <xsl:when test="TAG=''LABEL_REGISTER''"> 
                  <xsl:value-of select="''O_EFECTIV_T''" /> </xsl:when> <xsl:when test="TAG=''EPIS_REGISTER''"> 
                  <xsl:value-of select="''O_EFECTIV_V''" /> </xsl:when> -->
                <xsl:otherwise>
                  <xsl:value-of select="''NULL''" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:if test="$newTagValue!=''NULL''">
              <xsl:element name="{$newTagValue}">
                <xsl:value-of select="VAL" />
              </xsl:element>
            </xsl:if>
          </xsl:for-each>
        </HEADER>
      </xsl:template>
    </xsl:stylesheet>');

    /*
    Internal use function
    */
    PROCEDURE process_header_xml_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_epis.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN crisis_epis.id_software%TYPE,
        i_report         IN crisis_epis.id_report%TYPE,
        i_patient        IN crisis_epis.id_patient%TYPE,
        i_episode        IN crisis_epis.id_episode%TYPE,
        i_schedule       IN crisis_epis.id_schedule%TYPE,
        i_episode_type   IN crisis_epis.episode_type%TYPE
    ) IS
    
        l_cm_prof professional.id_professional%TYPE;
        l_prof    profissional;
        l_error   t_error_out;
    
        l_crisis_epis crisis_epis.id_crisis_epis%TYPE;
        l_patient     crisis_epis.id_patient%TYPE;
        l_episode     crisis_epis.id_episode%TYPE;
        l_schedule    crisis_epis.id_schedule%TYPE;
    
        l_header_id   header.id_header%TYPE;
        l_header_data pk_types.cursor_type;
    
        l_ctx_handle dbms_xmlgen.ctxhandle;
        l_xml_type   xmltype;
    
    BEGIN
    
        l_cm_prof := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                             i_prof    => profissional(0, i_institution, i_software));
    
        l_prof := profissional(l_cm_prof, i_institution, i_software);
    
        g_error := 'Fetch CRISIS_EPIS record: ' || i_crisis_machine || ', ' || i_software || ', ' || i_report || ', ' ||
                   i_patient || ', ' || i_episode || ', ' || i_schedule || chr(10);
    
        IF pk_alertlog.is_debug_enabled(i_object_name => g_package_name)
        THEN
            pk_alertlog.log_debug(g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => 'PROCESS_HEADER_XML_DETAIL');
        END IF;
    
        SELECT ce.id_crisis_epis, ce.id_patient, ce.id_episode, ce.id_schedule
          INTO l_crisis_epis, l_patient, l_episode, l_schedule
          FROM crisis_epis ce
         WHERE ce.id_crisis_machine = i_crisis_machine
           AND ce.id_software = i_software
           AND ce.id_report = i_report
           AND (((ce.id_patient IS NOT NULL AND ce.id_patient = i_patient) AND
               (ce.episode_type IS NOT NULL AND ce.episode_type = i_episode_type) AND
               (ce.id_episode IS NOT NULL AND ce.id_episode = i_episode) AND
               (ce.id_schedule IS NOT NULL AND ce.id_schedule = i_schedule)) OR ce.id_patient IS NULL);
    
        g_error := 'PK_HEADER.GET_HEADER for id_patient, id_episode, id_schedule: ' || l_patient || ', ' || l_episode || ', ' ||
                   l_schedule || chr(10);
        IF pk_header.get_header(i_lang        => i_lang,
                              i_prof        => l_prof,
                              i_id_episode  => CASE
                                                   WHEN i_episode_type = g_epis_type_sch THEN
                                                    NULL
                                                   ELSE
                                                    l_episode
                                               END,
                              i_id_patient  => l_patient,
                              i_id_schedule => l_schedule,
                              i_screen_mode => 'N',
                              i_flg_area    => 'G',
                              i_id_keys     => NULL, -- XXX ?
                              i_id_values   => NULL, -- XXX ?
                              o_id_header   => l_header_id,
                              o_data        => l_header_data,
                              o_error       => l_error)
        THEN
            l_ctx_handle := dbms_xmlgen.newcontext(l_header_data);
            l_xml_type   := dbms_xmlgen.getxmltype(ctx => l_ctx_handle);
            dbms_xmlgen.closecontext(l_ctx_handle);
        
            UPDATE crisis_epis ce
               SET ce.xml_header = xmltransform(l_xml_type, g_header_xsl)
             WHERE ce.id_crisis_epis = l_crisis_epis;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROCESS_HEADER_XML_DETAIL',
                                              l_error);
    END process_header_xml_detail;

    /*
    Internal use function
    */
    FUNCTION get_crisis_interval_search
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_error          OUT t_error_out
    ) RETURN INTERVAL DAY TO SECOND IS
    
        l_days crisis_machine.interval_search%TYPE;
    
    BEGIN
    
        g_error := 'GET_CURSOR C_CM_DET #2 -> ' || i_crisis_machine;
        SELECT cm.interval_search
          INTO l_days
          FROM crisis_machine cm
         WHERE cm.id_crisis_machine = i_crisis_machine;
    
        RETURN l_days;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CRISIS_INTERVAL_SEARCH',
                                              o_error);
            RETURN NULL;
    END get_crisis_interval_search;

    FUNCTION write_xml
    (
        i_lang      IN language.id_language%TYPE,
        i_select    IN pk_types.cursor_type,
        i_file_name IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_qryctx    dbms_xmlgen.ctxhandle;
        l_xml_value CLOB;
    
        l_result CLOB;
    
        l_xml_value_str VARCHAR2(100) := '<?xml version="1.0"?><ROWSET></ROWSET>';
    
    BEGIN
    
        IF i_select IS NOT NULL
        THEN
            INSERT INTO cm_cursor
                (file_name, xml_value, crypt)
            VALUES
                (g_cm_dir_upd || i_file_name || '.cmx', empty_clob(), 'Y')
            RETURNING xml_value INTO l_xml_value;
        
            l_qryctx := dbms_xmlgen.newcontext(i_select);
            g_error  := 'SET ROW TAG';
            -- Set the row header to be EMPLOYEE
            dbms_xmlgen.setrowtag(l_qryctx, 'RECORD');
            g_error := 'SET CONV SPEC CHARS';
            dbms_xmlgen.setconvertspecialchars(l_qryctx, TRUE);
        
            g_error := 'GENERATE XML';
            dbms_xmlgen.setnullhandling(l_qryctx, 2);
        
            g_error := 'CREATE TEMPORARY LOB';
            dbms_lob.createtemporary(lob_loc => l_result, cache => TRUE, dur => dbms_lob.session);
            dbms_lob.open(lob_loc => l_result, open_mode => dbms_lob.lob_readwrite);
        
            g_error := 'WRITE_XML#2';
            dbms_xmlgen.getxml(ctx => l_qryctx, tmpclob => l_result);
        
            --Close context
            g_error := 'Close context';
            dbms_xmlgen.closecontext(l_qryctx);
        
            IF nvl(dbms_lob.getlength(l_result), 0) = 0
            THEN
                g_error := 'write template result';
                dbms_lob.write(lob_loc => l_xml_value,
                               amount  => length(l_xml_value_str),
                               offset  => 1,
                               buffer  => l_xml_value_str);
            ELSE
                g_error := 'write template result';
                dbms_lob.append(dest_lob => l_xml_value, src_lob => l_result);
            END IF;
        
            g_error := 'Store filename value';
            g_file_count(i_file_name) := dbms_lob.getlength(l_result);
        
            IF (dbms_lob.isopen(lob_loc => l_result) = 1)
            THEN
                g_error := 'close lob';
                dbms_lob.close(lob_loc => l_result);
            END IF;
        
            IF (dbms_lob.istemporary(lob_loc => l_xml_value) = 1)
            THEN
                g_error := 'freetemporary lob #1';
                dbms_lob.freetemporary(lob_loc => l_xml_value);
            END IF;
        
            IF (dbms_lob.istemporary(lob_loc => l_result) = 1)
            THEN
                g_error := 'freetemporary lob #2';
                dbms_lob.freetemporary(lob_loc => l_result);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error('NO DATA FOUND - WRITE XML');
        
            BEGIN
                IF nvl(dbms_lob.getlength(l_xml_value), 0) > 0
                THEN
                    g_error := 'finishing objects: l_xml_value';
                    dbms_lob.freetemporary(l_xml_value);
                END IF;
            
                IF (dbms_lob.istemporary(lob_loc => l_result) = 1)
                THEN
                    g_error := 'finishing objects: l_result';
                    dbms_lob.freetemporary(lob_loc => l_result);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_error(g_error);
            END;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'WRITE_XML',
                                              o_error);
            BEGIN
                IF nvl(dbms_lob.getlength(l_xml_value), 0) > 0
                THEN
                    g_error := 'finishing objects: l_xml_value';
                    dbms_lob.freetemporary(l_xml_value);
                END IF;
            
                IF (dbms_lob.istemporary(lob_loc => l_result) = 1)
                THEN
                    g_error := 'finishing objects: l_result';
                    dbms_lob.freetemporary(lob_loc => l_result);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_error(g_error);
            END;
        
            RETURN FALSE;
    END write_xml;

    FUNCTION write_and_crypt
    (
        i_lang             IN language.id_language%TYPE,
        i_software         IN software.id_software%TYPE,
        i_application_name IN crisis_soft_details.aplication_name%TYPE,
        i_crisis_machine   IN crisis_machine.id_crisis_machine%TYPE,
        i_deepnav          IN crisis_soft_details.id_deepnav%TYPE,
        i_package_name     IN crisis_soft_details.package_name%TYPE,
        i_select           IN pk_types.cursor_type,
        i_output_file      IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_output_file    VARCHAR2(4000);
        l_processed_file NUMBER(6);
        l_error          t_error_out;
    
    BEGIN
    
        g_error := 'WRITE XML';
    
        IF lower(i_application_name) LIKE '%core%'
        THEN
            l_output_file := nvl(lower(i_output_file),
                                 lower(i_crisis_machine || g_separator || g_modules || g_separator || i_application_name ||
                                       g_separator || 'xml' || g_separator || i_software || '_' || i_deepnav || '_' ||
                                       i_package_name));
        ELSE
            l_output_file := nvl(lower(i_output_file),
                                 lower(i_crisis_machine || g_separator || g_modules || g_separator || i_application_name ||
                                       g_separator || 'xml' || g_separator || i_package_name));
        END IF;
    
        --validate if file is already processed
        SELECT COUNT(1)
          INTO l_processed_file
          FROM crisis_epis ce
         WHERE ce.cm_report_name = l_output_file;
    
        IF NOT g_file_count.exists(l_output_file)
        THEN
            IF NOT write_xml(i_lang => i_lang, i_select => i_select, i_file_name => l_output_file, o_error => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'WRITE_AND_CRYPT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'WRITE_AND_CRYPT',
                                              o_error);
            RETURN FALSE;
    END write_and_crypt;

    /** 
    * Returns KEYS path
    *
    * @return     varchar2
    * @author     RS
    * @version    0.1
    * @since      2007/08/24
    */

    FUNCTION get_keys_path RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'get_keys_path';
        RETURN g_cm_keys_path;
    
    END get_keys_path;

    /** 
    * Creates entrance.xml and config.xml for each crisis machine
    * 
    * @param      i_lang             language
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/08/07
    */

    FUNCTION set_initial_xml
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_generate_all   IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_select        pk_types.cursor_type;
        l_xml_value_str VARCHAR2(32767);
        l_xml_value     CLOB;
    
        CURSOR c_crisis_machines IS
            SELECT cm.id_crisis_machine, cm.id_language, cm.pwd_enc_cri_machine pwd_enc_cri_machine
              FROM crisis_machine cm
             WHERE cm.id_crisis_machine = i_crisis_machine;
    
        r_crisis_machine c_crisis_machines%ROWTYPE;
    
        CURSOR c_apps IS
            SELECT lower(cfd.aplication_name) aplication_name, cfd.id_software
              FROM crisis_soft_details cfd;
    
        CURSOR c_login(i_lang IN NUMBER) IS
            SELECT code_message, desc_message
              FROM sys_message
             WHERE id_language = i_lang
               AND code_message IN ('LOGIN_T001',
                                    'LOGIN_T002',
                                    'CRISIS_LOGN_T001',
                                    'CRISIS_LOGN_T002',
                                    'CRISIS_LOGN_T003',
                                    'CRISIS_LOGN_T004',
                                    'CRISIS_LOGN_T005',
                                    'CRISIS_INIT_T001',
                                    'CRISIS_INIT_T002')
               AND flg_available = g_yes;
    
        l_institution institution.id_institution%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN CURSOR';
        OPEN c_crisis_machines;
        FETCH c_crisis_machines
            INTO r_crisis_machine;
        CLOSE c_crisis_machines;
    
        --Now we send to JAVA a cursor with a temporary table
        g_error := 'Insert into cm_cursor';
        INSERT INTO cm_cursor
            (file_name, xml_value, crypt)
        VALUES
            (g_cm_dir_upd || r_crisis_machine.id_crisis_machine || g_separator || 'entrance.xml', empty_clob(), 'N')
        RETURNING xml_value INTO l_xml_value;
    
        g_error         := 'INIT XML FILE';
        l_xml_value_str := '<?xml version="1.0"?><ROWSET><RECORD>';
    
        g_error := 'INIT LOOP';
    
        FOR r_login IN c_login(r_crisis_machine.id_language)
        LOOP
            l_xml_value_str := l_xml_value_str || '<' || r_login.code_message || '>' || r_login.desc_message || '</' ||
                               r_login.code_message || '>';
        END LOOP;
    
        g_error         := 'END LOOP';
        l_xml_value_str := l_xml_value_str || '<LANGUAGE>' || r_crisis_machine.id_language || '</LANGUAGE>';
    
        l_institution := get_crisis_inst(r_crisis_machine.id_crisis_machine);
    
        l_xml_value_str := l_xml_value_str || '<DT_LAST_SYNC>' ||
                           pk_date_utils.to_char_insttimezone(profissional(NULL, l_institution, NULL),
                                                              g_sysdate_tstz,
                                                              'DD/MM/RRRR') || '</DT_LAST_SYNC>';
        l_xml_value_str := l_xml_value_str || '<HR_LAST_SYNC>' ||
                           pk_date_utils.to_char_insttimezone(profissional(NULL, l_institution, NULL),
                                                              g_sysdate_tstz,
                                                              'HH24:MI:SS') || '</HR_LAST_SYNC>';
        l_xml_value_str := l_xml_value_str || '<DT_LAST_SYNC_TSTZ>' ||
                           pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, profissional(NULL, l_institution, NULL)) ||
                           '</DT_LAST_SYNC_TSTZ>';
    
        g_error := 'INIT LOOP 2';
        FOR r_apps IN c_apps
        LOOP
            l_xml_value_str := l_xml_value_str || '<APP id="' || r_apps.id_software || '">' || g_modules || '\' ||
                               r_apps.aplication_name || '\</APP>';
        END LOOP;
    
        g_error         := 'END LOOP 2';
        l_xml_value_str := l_xml_value_str || '</RECORD></ROWSET>';
        dbms_lob.write(lob_loc => l_xml_value,
                       amount  => length(l_xml_value_str),
                       offset  => 1,
                       buffer  => l_xml_value_str);
    
        IF i_generate_all
        THEN
            g_error := 'CONFIG XML FILE';
            OPEN l_select FOR
                SELECT cmd.id_software,
                       pk_translation.get_translation(r_crisis_machine.id_language, s.code_software) desc_software,
                       pk_translation.get_translation(r_crisis_machine.id_language, s.code_icon) icon
                  FROM crisis_machine_det cmd, software s
                 WHERE s.id_software = cmd.id_software
                   AND cmd.id_crisis_machine = r_crisis_machine.id_crisis_machine;
        
            g_error := 'WRITE AND CRYPT XML';
            IF NOT write_and_crypt(i_lang             => i_lang,
                                   i_software         => NULL,
                                   i_application_name => NULL,
                                   i_crisis_machine   => r_crisis_machine.id_crisis_machine,
                                   i_deepnav          => NULL,
                                   i_package_name     => NULL,
                                   i_select           => l_select,
                                   i_output_file      => r_crisis_machine.id_crisis_machine || g_separator || 'config',
                                   o_error            => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF dbms_lob.istemporary(lob_loc => l_xml_value) = 1
        THEN
            g_error := 'freetemporary lob';
            dbms_lob.freetemporary(lob_loc => l_xml_value);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INITIAL_XML',
                                              o_error);
        
            BEGIN
                IF nvl(dbms_lob.getlength(l_xml_value), 0) > 0
                THEN
                    g_error := 'finishing objects: l_xml_value';
                    dbms_lob.freetemporary(l_xml_value);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_error(g_error);
            END;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INITIAL_XML',
                                              o_error);
            BEGIN
                IF nvl(dbms_lob.getlength(l_xml_value), 0) > 0
                THEN
                    g_error := 'finishing objects: l_xml_value';
                    dbms_lob.freetemporary(l_xml_value);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_error(g_error);
            END;
        
            RETURN FALSE;
    END set_initial_xml;

    PROCEDURE set_crontab
    (
        o_xml   OUT CLOB,
        o_error OUT VARCHAR2
    ) IS
    
        l_newline VARCHAR2(32000);
    
    BEGIN
    
        g_error   := 'Start xml creation';
        l_newline := '<?xml version=''1.0'' encoding=''utf-8''?>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<quartz xmlns="http://www.opensymphony.com/quartz/JobSchedulingData" ';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := 'xsi:schemaLocation="http://www.opensymphony.com/quartz/JobSchedulingData ';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := 'http://www.quartz-scheduler.org/xml/job_scheduling_data_1_5.xsd" ';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := 'version="1.5">';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<calendar class-name="org.quartz.impl.calendar.HolidayCalendar" replace="true">';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<name>holidayCalendar</name>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<description>HolidayCalendar</description>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<base-calendar class-name="org.quartz.impl.calendar.WeeklyCalendar">';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<name>weeklyCalendar</name>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<description>WeeklyCalendar</description>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<base-calendar class-name="org.quartz.impl.calendar.AnnualCalendar">';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<name>annualCalendar</name>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '<description>AnnualCalendar</description>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '</base-calendar>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '</base-calendar>';
        o_xml     := o_xml || l_newline || chr(13);
    
        l_newline := '</calendar>';
        o_xml     := o_xml || l_newline || chr(13);
    
        FOR rec IN (SELECT cm.id_crisis_machine, cm.act_interval
                      FROM crisis_machine cm
                     WHERE cm.flg_available = pk_alert_constant.g_yes
                     ORDER BY cm.id_crisis_machine)
        LOOP
            -- CrisisMachineUpdate
            l_newline := '<job>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-detail>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<name>CrisisMachineUpdate-' || rec.id_crisis_machine || '</name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<group>CrisisMachineUpdate</group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<description>CrisisMachineUpdate-' || rec.id_crisis_machine || '</description>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-class>' || g_cm_job_update_class || '</job-class>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<volatility>false</volatility>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<durability>false</durability>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<recover>false</recover>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-data-map allows-transient-data="true">';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<entry>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<key>id_crisis_machine</key>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<value>' || rec.id_crisis_machine || '</value>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</entry>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job-data-map>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job-detail>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<trigger>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<cron>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<name>CrisisMachineUpdate-' || rec.id_crisis_machine || '</name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<group>CrisisMachineUpdate</group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<description>CrisisMachineUpdate-' || rec.id_crisis_machine || '</description>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-name>CrisisMachineUpdate-' || rec.id_crisis_machine || '</job-name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-group>CrisisMachineUpdate</job-group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<!-- Every ' || rec.act_interval || ' minuts-->';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<cron-expression>0 ' || '0/' || rec.act_interval || ' * ? * *</cron-expression>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</cron>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</trigger>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job>';
            o_xml     := o_xml || l_newline || chr(13);
        
            --CrisisMachineGenerate
            l_newline := '<job>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-detail>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<name>CrisisMachineGenerate-' || rec.id_crisis_machine || '</name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<group>CrisisMachineGenerate</group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<description>CrisisMachineGenerate-' || rec.id_crisis_machine || '</description>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-class>' || g_cm_job_generate_class || '</job-class>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<volatility>false</volatility>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<durability>false</durability>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<recover>false</recover>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-data-map allows-transient-data="true">';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<entry>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<key>id_crisis_machine</key>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<value>' || rec.id_crisis_machine || '</value>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</entry>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job-data-map>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job-detail>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<trigger>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<cron>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<name>CrisisMachineGenerate-' || rec.id_crisis_machine || '</name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<group>CrisisMachineGenerate</group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<description>CrisisMachineGenerate-' || rec.id_crisis_machine || '</description>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-name>CrisisMachineGenerate-' || rec.id_crisis_machine || '</job-name>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<job-group>CrisisMachineGenerate</job-group>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<!-- Every ' || g_cm_job_generate_interval || ' seconds-->';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '<cron-expression>' || '0/' || g_cm_job_generate_interval || ' * * ? * *</cron-expression>';
        
            o_xml := o_xml || l_newline || chr(13);
        
            l_newline := '</cron>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</trigger>';
            o_xml     := o_xml || l_newline || chr(13);
        
            l_newline := '</job>';
            o_xml     := o_xml || l_newline || chr(13);
        END LOOP;
    
        l_newline := '</quartz>';
        o_xml     := o_xml || l_newline;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := g_error || ' / ' || SQLERRM;
    END set_crontab;

    FUNCTION get_last_episode
    (
        i_patient       IN patient.id_patient%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_software      IN software.id_software%TYPE DEFAULT NULL,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN episode.id_episode%TYPE IS
    
        l_episode episode.id_episode%TYPE;
    
        l_fetch_by_dcs sys_config.value%TYPE;
    
        l_error VARCHAR2(4000 CHAR);
    
    BEGIN
    
        g_error        := 'GET SYS_CONFIG CRISIS_FETCH_LAST_EPIS_BY_DCS';
        l_fetch_by_dcs := pk_sysconfig.get_config('CRISIS_FETCH_LAST_EPIS_BY_DCS',
                                                  profissional(0, i_institution, nvl(i_software, 0)));
    
        g_error := 'GET ID_EPISODE';
        SELECT id_episode
          INTO l_episode
          FROM (SELECT id_episode, rank() over(ORDER BY e_rank) rn
                  FROM (SELECT e.id_episode, e.dt_begin_tstz, rank() over(ORDER BY e.dt_begin_tstz DESC) * 1000 e_rank
                          FROM episode e
                         WHERE e.id_patient = i_patient
                           AND e.id_institution = i_institution
                           AND e.dt_begin_tstz IS NOT NULL
                           AND e.flg_ehr = 'N'
                        UNION ALL
                        SELECT e.id_episode,
                               e.dt_begin_tstz,
                               rank() over(PARTITION BY ei.id_dep_clin_serv ORDER BY e.dt_begin_tstz DESC) e_rank
                          FROM episode e
                         INNER JOIN epis_info ei
                            ON ei.id_episode = e.id_episode
                         WHERE l_fetch_by_dcs = pk_alert_constant.g_yes
                           AND e.id_patient = i_patient
                           AND e.id_institution = i_institution
                           AND ei.id_dep_clin_serv = i_dep_clin_serv
                           AND e.dt_begin_tstz IS NOT NULL
                           AND e.flg_ehr = 'N'))
         WHERE rn < 2;
    
        RETURN l_episode;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            l_error := g_package_name || '.' || 'GET_LAST_EPISODE' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(l_error);
        
            RETURN NULL;
    END get_last_episode;

    FUNCTION get_episode_and_patient
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_show_demographic_data NUMBER(24) := pk_sysconfig.get_config('CM_FLG_SHOW_VIPS', 0, 0);
    
    BEGIN
    
        g_error := 'GET_EPISODES';
        OPEN o_list FOR
            WITH cmdet AS
             (SELECT cm.id_crisis_machine,
                     cm.id_language,
                     cm.interval_search,
                     cmd.id_institution,
                     cmd.id_software,
                     (SELECT csd.aplication_name
                        FROM crisis_soft_details csd
                       WHERE csd.id_software = cmd.id_software) aplication_name,
                     pk_sysconfig.get_config('CM_GET_INACTIVE_EPIS', cmd.id_institution, cmd.id_software) cm_get_inactive_epis
                FROM crisis_machine cm
               INNER JOIN crisis_machine_det cmd
                  ON cmd.id_crisis_machine = cm.id_crisis_machine
               WHERE cm.id_crisis_machine = i_crisis_machine)
            SELECT t1.ep,
                   t1.rank,
                   t1.id_episode,
                   t1.id_patient,
                   t1.id_software,
                   t1.path_crisis_machine,
                   t1.flg_show_demographic_data,
                   t1.id_schedule
              FROM (SELECT 'EPIS' ep,
                           20 rank,
                           epis.id_episode,
                           epis.id_patient,
                           ei.id_software,
                           lower(g_cm_dir_gen || cmdet.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 cmdet.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           --@CLEAR cmd.id_report_section,
                           decode((SELECT p.alias
                                    FROM patient p
                                   WHERE p.id_patient = epis.id_patient),
                                  NULL,
                                  1,
                                  decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                           CASE ei.id_software
                               WHEN pk_alert_constant.g_soft_rehab THEN
                                CASE ei.id_schedule
                                    WHEN -1 THEN
                                     (SELECT ei2.id_schedule
                                        FROM epis_info ei2
                                       WHERE ei2.id_episode = nvl(epis.id_prev_episode, epis.id_episode))
                                    ELSE
                                     ei.id_schedule
                                END
                               ELSE
                                ei.id_schedule
                           END id_schedule
                      FROM epis_info ei
                     INNER JOIN cmdet
                        ON cmdet.id_software = ei.id_software
                     INNER JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND ((cmdet.cm_get_inactive_epis = pk_alert_constant.g_yes AND
                           nvl(epis.dt_end_tstz, current_timestamp) > (current_timestamp - cmdet.interval_search)) OR
                           (cmdet.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                     WHERE ei.dt_last_interaction_tstz IS NOT NULL
                       AND ei.dt_last_interaction_tstz >
                           (CAST(current_timestamp AS TIMESTAMP WITH LOCAL TIME ZONE) - cmdet.interval_search)
                       AND epis.flg_status IN (pk_alert_constant.g_epis_status_active,
                                               pk_alert_constant.g_epis_status_pendent,
                                               pk_alert_constant.g_epis_status_inactive)
                       AND epis.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                       AND epis.id_institution = cmdet.id_institution
                          --REHAB episodes processed in another query
                       AND epis.id_epis_type NOT IN (pk_alert_constant.g_epis_type_rehab_session,
                                                     pk_alert_constant.g_epis_type_rehab_appointment,
                                                     pk_alert_constant.g_epis_type_lab,
                                                     pk_alert_constant.g_epis_type_rad,
                                                     pk_alert_constant.g_epis_type_exam,
                                                     pk_alert_constant.g_epis_type_dietitian)
                       AND NOT EXISTS (SELECT 1
                              FROM crisis_epis ce
                             WHERE ce.id_crisis_machine = cmdet.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = epis.id_patient
                               AND ce.id_episode = epis.id_episode
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   ce.date_last_generated_tstz >= ei.dt_last_interaction_tstz)))
                    --Scheduled oris appointments
                    UNION ALL
                    SELECT /*+ opt_estimate(table sch rows = 1) */
                     'ORIS' ep,
                     20 rank,
                     sch.id_episode,
                     sch.id_patient,
                     x.id_software,
                     lower(g_cm_dir_gen || x.id_crisis_machine || g_separator || g_modules || g_separator ||
                           x.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                     --@CLEAR x.id_report_section,
                     decode(p.alias, NULL, 1, decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                     ei.id_schedule
                      FROM cmdet x NATURAL
                      JOIN TABLE(pk_api_sr_visit.tf_scheduled_episodes(x.id_language, profissional(pk_sysconfig.get_config('CRISIS_MACHINE_USER', profissional(0, x.id_institution, x.id_software)), x.id_institution, x.id_software), current_timestamp, current_timestamp + x.interval_search)) sch
                     INNER JOIN patient p
                        ON p.id_patient = sch.id_patient
                     INNER JOIN epis_info ei
                        ON ei.id_episode = sch.id_episode
                     INNER JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND (x.cm_get_inactive_epis = pk_alert_constant.g_yes OR
                           (x.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                     WHERE NOT EXISTS (SELECT 1
                              FROM crisis_epis ce
                             INNER JOIN epis_info ei
                                ON ei.id_episode = ce.id_episode
                             WHERE ce.id_crisis_machine = x.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = p.id_patient
                               AND ce.id_episode = sch.id_episode
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   nvl(pk_date_utils.get_timestamp_diff(ei.dt_last_interaction_tstz,
                                                                          ce.date_last_generated_tstz),
                                         -1) < 0)))
                       AND ei.id_software = x.id_software
                    UNION ALL
                    --Scheduled ambulatory appointments
                    SELECT x.ep,
                           20 rank,
                           x.id_episode,
                           x.id_patient,
                           x.id_software,
                           x.path_crisis_machine,
                           --@CLEAR x.id_report_section,
                           x.flg_show_demographic_data,
                           x.id_schedule
                      FROM (SELECT 'SCH' ep, -- for scheduled outpatient episodes first get report qith information from last episode, if it is not available than use current episode
                                   coalesce(get_last_episode(t.id_patient,
                                                             t.id_institution,
                                                             t.id_software,
                                                             t.id_dcs_requested),
                                            t.id_episode,
                                            g_dummy_episode) id_episode,
                                   t.id_patient,
                                   t.id_software,
                                   t.path_crisis_machine,
                                   --@CLEAR t.id_report_section,
                                   t.flg_show_demographic_data,
                                   t.id_schedule
                              FROM (SELECT DISTINCT sg.id_patient id_patient,
                                                    nvl(cmd.id_software, '0') id_software,
                                                    lower(g_cm_dir_gen || cm.id_crisis_machine || g_separator || g_modules ||
                                                          g_separator || csd.aplication_name) || g_separator || 'pdf' ||
                                                    g_separator path_crisis_machine,
                                                    --@CLEAR cmd.id_report_section id_report_section,
                                                    cmd.id_institution id_institution,
                                                    decode(p.alias, NULL, 1, decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                                                    MAX(s.dt_begin_tstz),
                                                    s.id_schedule,
                                                    s.id_dcs_requested,
                                                    ei.id_episode
                                      FROM schedule s
                                      JOIN schedule_outp sp
                                        ON sp.id_schedule = s.id_schedule
                                      JOIN sch_group sg
                                        ON s.id_schedule = sg.id_schedule
                                      JOIN crisis_machine_det cmd
                                        ON cmd.id_software = sp.id_software
                                      JOIN crisis_machine cm
                                        ON cm.id_crisis_machine = cmd.id_crisis_machine
                                      JOIN crisis_soft_details csd
                                        ON csd.id_software = cmd.id_software
                                      JOIN epis_type_soft_inst etsi
                                        ON etsi.id_epis_type = sp.id_epis_type
                                       AND etsi.id_software = sp.id_software
                                       AND etsi.id_institution IN (cmd.id_institution, 0)
                                      JOIN patient p
                                        ON p.id_patient = sg.id_patient
                                      LEFT JOIN epis_info ei
                                        ON s.id_schedule = ei.id_schedule
                                     WHERE sp.id_software = cmd.id_software
                                       AND cm.id_crisis_machine = i_crisis_machine
                                       AND s.id_instit_requested = cmd.id_institution
                                       AND s.flg_status = g_sched_scheduled
                                       AND NOT EXISTS (SELECT 1
                                              FROM episode e
                                             INNER JOIN epis_info curr_ei
                                                ON curr_ei.id_episode = e.id_episode
                                             WHERE e.id_patient = p.id_patient
                                               AND e.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                                               AND curr_ei.id_schedule = s.id_schedule)
                                       AND s.dt_begin_tstz BETWEEN trunc(current_timestamp) AND
                                           current_timestamp + cm.interval_search
                                          --REHAB episodes processed in another query
                                       AND sp.id_epis_type NOT IN
                                           (pk_alert_constant.g_epis_type_rehab_session,
                                            pk_alert_constant.g_epis_type_rehab_appointment,
                                            pk_alert_constant.g_epis_type_lab,
                                            pk_alert_constant.g_epis_type_rad,
                                            pk_alert_constant.g_epis_type_exam,
                                            pk_alert_constant.g_epis_type_dietitian)
                                       AND NOT EXISTS (SELECT 1
                                              FROM crisis_epis ce
                                             WHERE ce.id_patient = p.id_patient
                                               AND ce.id_crisis_machine = cm.id_crisis_machine
                                               AND ce.flg_status <> g_flg_status_retry
                                               AND ce.id_schedule = s.id_schedule)
                                     GROUP BY sg.id_patient,
                                              nvl(cmd.id_software, '0'),
                                              lower(g_cm_dir_gen || cm.id_crisis_machine || g_separator || g_modules ||
                                                    g_separator || csd.aplication_name) || g_separator || 'pdf' ||
                                              g_separator,
                                              --@CLEAR cmd.id_report_section,
                                              cmd.id_institution,
                                              decode(p.alias, NULL, 1, decode(l_show_demographic_data, 0, 0, 1)),
                                              s.id_schedule,
                                              s.id_dcs_requested,
                                              ei.id_episode) t) x
                     WHERE x.id_episode IS NOT NULL
                    UNION ALL
                    SELECT 'REHAB' ep,
                           20 rank,
                           cmr.id_episode,
                           cmr.id_patient,
                           x.id_software,
                           lower(g_cm_dir_gen || x.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 x.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           decode((SELECT p.alias
                                    FROM patient p
                                   WHERE p.id_patient = cmr.id_patient),
                                  NULL,
                                  1,
                                  decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                           nvl(cmr.id_schedule, -1) id_schedule
                      FROM cmdet x,
                           TABLE(pk_rehab_external_api_db.tf_cm_rehab_episodes(x.id_language,
                                                                               profissional(pk_sysconfig.get_config('CRISIS_MACHINE_USER',
                                                                                                                    profissional(0,
                                                                                                                                 x.id_institution,
                                                                                                                                 x.id_software)),
                                                                                            x.id_institution,
                                                                                            x.id_software),
                                                                               x.interval_search)) cmr,
                           episode epis
                     WHERE epis.id_episode = cmr.id_episode
                       AND x.id_software = cmr.id_software
                       AND x.id_software = pk_alert_constant.g_soft_rehab
                       AND (x.cm_get_inactive_epis = pk_alert_constant.g_yes OR
                           (x.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND NOT EXISTS
                     (SELECT 1
                              FROM crisis_epis ce
                             WHERE ce.id_crisis_machine = x.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = cmr.id_patient
                               AND ce.id_episode = cmr.id_episode
                               AND ce.id_software = cmr.id_software
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   pk_date_utils.get_timestamp_diff(ce.date_last_generated_tstz,
                                                                      cmr.dt_last_interaction) >= 0)))
                    UNION ALL
                    --Image Technician 
                    SELECT 'ITECH' ep,
                           20 rank,
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode) id_episode,
                           cmr.id_patient,
                           x.id_software,
                           lower(g_cm_dir_gen || x.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 x.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           decode((SELECT p.alias
                                    FROM patient p
                                   WHERE p.id_patient = cmr.id_patient),
                                  NULL,
                                  1,
                                  decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                           nvl(cmr.id_schedule, -1) id_schedule
                      FROM cmdet x,
                           TABLE(pk_exams_external_api_db.tf_cm_imaging_episodes(x.id_language,
                                                                                 profissional(pk_sysconfig.get_config('CRISIS_MACHINE_USER',
                                                                                                                      profissional(0,
                                                                                                                                   x.id_institution,
                                                                                                                                   x.id_software)),
                                                                                              x.id_institution,
                                                                                              x.id_software),
                                                                                 x.interval_search)) cmr,
                           episode epis
                     WHERE epis.id_episode =
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode)
                       AND (x.cm_get_inactive_epis = pk_alert_constant.g_yes OR
                           (x.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND x.id_software = cmr.id_software
                       AND x.id_software = pk_alert_constant.g_soft_imgtech
                       AND NOT EXISTS
                     (SELECT 1
                              FROM crisis_epis ce
                             WHERE ce.id_crisis_machine = x.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = cmr.id_patient
                               AND ce.id_episode = cmr.id_episode
                               AND ce.id_software = cmr.id_software
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   pk_date_utils.get_timestamp_diff(ce.date_last_generated_tstz,
                                                                      cmr.dt_last_interaction) >= 0)))
                    UNION ALL
                    --Other exams Technician 
                    SELECT 'EXAMS' ep,
                           20 rank,
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode) id_episode,
                           cmr.id_patient,
                           x.id_software,
                           lower(g_cm_dir_gen || x.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 x.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           decode((SELECT p.alias
                                    FROM patient p
                                   WHERE p.id_patient = cmr.id_patient),
                                  NULL,
                                  1,
                                  decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                           nvl(cmr.id_schedule, -1) id_schedule
                      FROM cmdet x,
                           TABLE(pk_exams_external_api_db.tf_cm_exams_episodes(x.id_language,
                                                                               profissional(pk_sysconfig.get_config('CRISIS_MACHINE_USER',
                                                                                                                    profissional(0,
                                                                                                                                 x.id_institution,
                                                                                                                                 x.id_software)),
                                                                                            x.id_institution,
                                                                                            x.id_software),
                                                                               x.interval_search)) cmr,
                           episode epis
                     WHERE epis.id_episode =
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode)
                       AND (x.cm_get_inactive_epis = pk_alert_constant.g_yes OR
                           (x.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND x.id_software = cmr.id_software
                       AND x.id_software = pk_alert_constant.g_soft_extech
                       AND NOT EXISTS
                     (SELECT 1
                              FROM crisis_epis ce
                             WHERE ce.id_crisis_machine = x.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = cmr.id_patient
                               AND ce.id_episode = cmr.id_episode
                               AND ce.id_software = cmr.id_software
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   pk_date_utils.get_timestamp_diff(ce.date_last_generated_tstz,
                                                                      cmr.dt_last_interaction) >= 0)))
                    UNION ALL
                    --Dietitian
                    SELECT 'DIET' ep,
                           20 rank,
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode) id_episode,
                           cmr.id_patient,
                           x.id_software,
                           lower(g_cm_dir_gen || x.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 x.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           decode((SELECT p.alias
                                    FROM patient p
                                   WHERE p.id_patient = cmr.id_patient),
                                  NULL,
                                  1,
                                  decode(l_show_demographic_data, 0, 0, 1)) flg_show_demographic_data,
                           nvl(cmr.id_schedule, -1) id_schedule
                      FROM cmdet x,
                           TABLE(pk_diet_api_db.tf_cm_diet_episodes(x.id_language,
                                                                    profissional(pk_sysconfig.get_config('CRISIS_MACHINE_USER',
                                                                                                         profissional(0,
                                                                                                                      x.id_institution,
                                                                                                                      x.id_software)),
                                                                                 x.id_institution,
                                                                                 x.id_software),
                                                                    x.interval_search)) cmr,
                           episode epis
                     WHERE epis.id_episode =
                           coalesce(cmr.id_episode, get_last_episode(cmr.id_patient, x.id_institution), g_dummy_episode)
                       AND (x.cm_get_inactive_epis = pk_alert_constant.g_yes OR
                           (x.cm_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND x.id_software = cmr.id_software
                       AND x.id_software = pk_alert_constant.g_soft_nutritionist
                       AND NOT EXISTS
                     (SELECT 1
                              FROM crisis_epis ce
                             WHERE ce.id_crisis_machine = x.id_crisis_machine
                               AND ce.episode_type <> g_epis_type_sch
                               AND ce.id_patient = cmr.id_patient
                               AND ce.id_episode = cmr.id_episode
                               AND ce.id_software = cmr.id_software
                               AND (ce.flg_status IN (g_flg_status_waiting, g_flg_status_in_progress) OR
                                   (ce.flg_status IN (g_flg_status_generated, g_flg_status_error) AND
                                   pk_date_utils.get_timestamp_diff(ce.date_last_generated_tstz,
                                                                      cmr.dt_last_interaction) >= 0)))
                    UNION ALL
                    SELECT 'GLOBAL' ep,
                           10 rank,
                           NULL id_episode,
                           NULL id_patient,
                           cmdet.id_software,
                           lower(g_cm_dir_gen || cmdet.id_crisis_machine || g_separator || g_modules || g_separator ||
                                 cmdet.aplication_name) || g_separator || 'pdf' || g_separator path_crisis_machine,
                           --@CLEAR cmd.id_report_section,
                           nvl(l_show_demographic_data, 0) flg_show_demographic_data,
                           NULL id_schedule
                      FROM cmdet) t1
             ORDER BY t1.rank, t1.id_software, t1.id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_EPISODE_AND_PATIENT' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_types.open_my_cursor(o_list);
            pk_alertlog.log_error(o_error);
            RETURN FALSE;
    END get_episode_and_patient;

    FUNCTION set_crisis_epis
    (
        i_lang                      IN language.id_language%TYPE,
        i_crisis_epis               IN crisis_epis.id_crisis_epis%TYPE,
        i_epis                      IN crisis_epis.id_episode%TYPE,
        i_pat                       IN crisis_epis.id_patient%TYPE,
        i_date_finish               IN TIMESTAMP WITH TIME ZONE,
        i_cm_report_name            IN crisis_epis.cm_report_name%TYPE,
        i_crisis_machine            IN crisis_machine.id_crisis_machine%TYPE,
        i_schedule                  IN crisis_epis.id_schedule%TYPE,
        i_id_report                 IN crisis_epis.id_report%TYPE,
        i_flg_report_type           IN crisis_epis.flg_report_type%TYPE,
        i_software                  IN crisis_epis.id_software%TYPE,
        i_crisis_log                IN crisis_log.id_crisis_log%TYPE,
        i_episode_type              IN crisis_epis.episode_type%TYPE,
        i_cm_report_path            IN crisis_epis.cm_report_path%TYPE,
        i_flg_show_demographic_data IN crisis_epis.flg_show_demographic_data%TYPE,
        i_flg_status                IN crisis_epis.flg_status%TYPE,
        i_token                     IN crisis_epis.token%TYPE,
        o_error                     OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_institution     institution.id_institution%TYPE;
        l_crisis_epis_cnt NUMBER := 0;
        l_crisis_epis     crisis_epis%ROWTYPE;
    
    BEGIN
    
        g_error       := 'SET_CRISIS_EPIS';
        l_institution := get_crisis_inst(i_crisis_machine);
    
        SELECT COUNT(*)
          INTO l_crisis_epis_cnt
          FROM crisis_epis ce
         WHERE (i_crisis_epis IS NOT NULL AND ce.id_crisis_epis = i_crisis_epis)
            OR (i_crisis_epis IS NULL AND
               (i_crisis_machine IS NULL OR (i_crisis_machine IS NOT NULL AND ce.id_crisis_machine = i_crisis_machine)) AND
               ce.id_software = i_software AND ce.id_report = i_id_report AND
               (i_episode_type IS NULL OR ce.episode_type = i_episode_type) AND
               ((ce.id_patient IS NOT NULL AND ce.id_patient = i_pat AND
               ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND ce.id_episode = i_epis) OR
               (ce.episode_type = g_epis_type_sch AND ce.id_schedule = i_schedule))) OR ce.id_patient IS NULL));
    
        IF l_crisis_epis_cnt = 0
        THEN
            IF i_flg_status = g_flg_status_waiting
            THEN
                INSERT INTO crisis_epis
                    (id_crisis_epis,
                     id_episode,
                     id_patient,
                     cm_report_name,
                     id_crisis_machine,
                     date_finish_tstz,
                     id_schedule,
                     id_report,
                     flg_report_type,
                     id_software,
                     episode_type,
                     cm_report_path,
                     flg_show_demographic_data,
                     flg_status,
                     token,
                     id_crisis_log)
                VALUES
                    (seq_crisis_epis.nextval,
                     i_epis,
                     i_pat,
                     i_cm_report_name,
                     i_crisis_machine,
                     i_date_finish,
                     i_schedule,
                     i_id_report,
                     i_flg_report_type,
                     i_software,
                     i_episode_type,
                     i_cm_report_path,
                     i_flg_show_demographic_data,
                     i_flg_status,
                     i_token,
                     i_crisis_log);
            ELSE
                o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                           'SET_CRISIS_EPIS' || '/ ' || g_error || ' / ' || 'The record doesn''t exist';
                pk_alertlog.log_error(o_error);
                RETURN FALSE;
            END IF;
        ELSE
            SELECT *
              INTO l_crisis_epis
              FROM crisis_epis ce
             WHERE (i_crisis_epis IS NOT NULL AND ce.id_crisis_epis = i_crisis_epis)
                OR (i_crisis_epis IS NULL AND (i_crisis_machine IS NULL OR (i_crisis_machine IS NOT NULL AND
                   ce.id_crisis_machine = i_crisis_machine)) AND ce.id_software = i_software AND
                   ce.id_report = i_id_report AND (i_episode_type IS NULL OR ce.episode_type = i_episode_type) AND
                   ((ce.id_patient IS NOT NULL AND ce.id_patient = i_pat AND
                   ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND ce.id_episode = i_epis) OR
                   (ce.episode_type = g_epis_type_sch AND ce.id_schedule = i_schedule))) OR ce.id_patient IS NULL));
        
            --This is for when the reset_in_process runs and the generating job generates the report any way. 
            --In this case another job may have already generated the report
            IF i_token IS NOT NULL
               AND l_crisis_epis.token IS NOT NULL
               AND i_token <> l_crisis_epis.token
            THEN
                RETURN TRUE;
            ELSE
                UPDATE crisis_epis ce
                   SET ce.cm_report_name   = nvl(i_cm_report_name, ce.cm_report_name),
                       ce.date_finish_tstz = nvl(i_date_finish, ce.date_finish_tstz),
                       ce.id_episode       = nvl(i_epis, ce.id_episode),
                       ce.id_crisis_log    = nvl(i_crisis_log, ce.id_crisis_log),
                       ce.flg_status       = i_flg_status,
                       ce.token            = nvl(i_token, ce.token)
                 WHERE (i_crisis_epis IS NOT NULL AND ce.id_crisis_epis = i_crisis_epis)
                    OR (i_crisis_epis IS NULL AND (i_crisis_machine IS NULL OR (i_crisis_machine IS NOT NULL AND
                       ce.id_crisis_machine = i_crisis_machine)) AND ce.id_software = i_software AND
                       ce.id_report = i_id_report AND (i_episode_type IS NULL OR ce.episode_type = i_episode_type) AND
                       ((ce.id_patient IS NOT NULL AND ce.id_patient = i_pat AND
                       ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND ce.id_episode = i_epis) OR
                       (ce.episode_type = g_epis_type_sch AND ce.id_schedule = i_schedule))) OR ce.id_patient IS NULL));
            
                IF i_flg_status = g_flg_status_generated
                THEN
                    process_header_xml_detail(i_lang           => i_lang,
                                              i_crisis_machine => i_crisis_machine,
                                              i_institution    => l_institution,
                                              i_software       => i_software,
                                              i_report         => i_id_report,
                                              i_patient        => i_pat,
                                              i_episode        => i_epis,
                                              i_schedule       => i_schedule,
                                              i_episode_type   => i_episode_type);
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'SET_CRISIS_EPIS' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(o_error);
            RETURN FALSE;
    END set_crisis_epis;

    FUNCTION get_outp_pp_care
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search crisis_machine.interval_search%TYPE;
        l_error       t_error_out;
    
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_show_vips NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CM_FLG_SHOW_VIPS', i_prof => l_prof);
    
        l_inc_adm_disch VARCHAR2(1) := nvl(pk_sysconfig.get_config(i_code_cf => 'CRISIS_INC_ADM_DISCH',
                                                                   i_prof    => l_prof),
                                           pk_alert_constant.g_no);
    
    BEGIN
    
        g_error        := 'GET_OUTP_PP_CARE';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang,
                                                      g_sysdate_tstz,
                                                      profissional(l_id_professional, i_institution, i_software));
    
        g_error       := 'GET_OUTP_PP_CARE - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT pk_adt.get_patient_name(i_lang, l_prof, t.id_patient, l_show_vips) pat_name,
                   pk_adt.get_patient_name_to_sort(i_lang, l_prof, t.id_patient, l_show_vips) pat_name_sort,
                   pk_patient.get_pat_age(i_lang, t.id_patient, l_prof) pat_age,
                   pk_patient.get_pat_gender(t.id_patient) pat_gender,
                   NULL photo,
                   pk_hea_prv_aux.get_clin_service(i_lang, l_prof, t.id_dcs_requested) cons_type,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_target_tstz, l_prof) dt_target_tstz,
                   pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', t.flg_sched, i_lang) img_sched,
                   g_sysdate_char dt_server,
                   t.id_episode,
                   nvl((SELECT pk_prof_utils.get_name_signature(i_lang, l_prof, p.id_professional)
                         FROM sch_prof_outp ps, professional p
                        WHERE ps.id_schedule_outp = t.id_schedule_outp
                          AND p.id_professional = ps.id_professional
                          AND rownum < 2),
                       pk_prof_utils.get_name_signature(i_lang, l_prof, t.id_professional)) doctor_name,
                   pk_date_utils.date_time_chr_tsz(i_lang, t.dt_target_tstz, l_prof) dt_target,
                   (SELECT xml_header
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) xml_header,
                   (SELECT flg_status
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.id_patient = t.id_patient
                              AND ce.id_schedule = t.id_schedule
                              AND ce.cm_report_name IS NOT NULL) report_list,
                   t.id_schedule,
                   pk_date_utils.date_send_tsz(i_lang, t.date_last_generated_tstz, l_prof) date_last_generated_tstz,
                   nvl((SELECT pk_prof_utils.get_desc_category(i_lang, l_prof, p.id_professional, t.id_instit_requested)
                         FROM sch_prof_outp ps, professional p
                        WHERE ps.id_schedule_outp = t.id_schedule_outp
                          AND p.id_professional = ps.id_professional
                          AND rownum < 2),
                       pk_prof_utils.get_desc_category(i_lang, l_prof, t.id_professional, t.id_instit_requested)) prof_desc_cat,
                   nvl(t.epis_flg_status, 'SCH_' || t.sch_flg_status) epis_flg_status,
                   CASE (nvl(t.epis_flg_status, 'X'))
                       WHEN 'X' THEN
                        pk_sysdomain.get_domain('SCHEDULE.FLG_STATUS', t.sch_flg_status, i_lang)
                       ELSE
                        pk_sysdomain.get_domain('EPISODE.FLG_STATUS', t.epis_flg_status, i_lang)
                   END epis_flg_status_desc,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette
              FROM (SELECT ce.id_patient,
                           MIN(s.id_dcs_requested) id_dcs_requested,
                           MIN(sp.dt_target_tstz) dt_target_tstz,
                           MIN(sp.flg_sched) flg_sched,
                           MIN(ei.id_episode) id_episode,
                           MIN(sp.id_schedule_outp) id_schedule_outp,
                           MIN(ei.id_professional) id_professional,
                           s.id_schedule,
                           MIN(ce.date_last_generated_tstz) date_last_generated_tstz,
                           MIN(s.id_instit_requested) id_instit_requested,
                           MIN(ce.id_crisis_machine) id_crisis_machine,
                           MIN(s.flg_status) sch_flg_status,
                           MIN((SELECT e.flg_status
                                 FROM episode e
                                WHERE e.id_episode = ei.id_episode)) epis_flg_status,
                           MIN(ce.id_crisis_epis) id_crisis_epis
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                      JOIN crisis_epis ce
                        ON ce.id_patient = sg.id_patient
                       AND ce.id_schedule = sg.id_schedule
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                     INNER JOIN patient p
                        ON p.id_patient = ce.id_patient
                     WHERE sp.id_software = l_prof.software
                       AND ((sp.flg_state != g_sched_adm_disch AND l_inc_adm_disch != pk_alert_constant.g_yes) OR
                           l_inc_adm_disch = pk_alert_constant.g_yes)
                       AND s.id_instit_requested = l_prof.institution
                       AND s.flg_status != g_sched_canc
                       AND (ce.episode_type = g_epis_type_sch OR
                           ce.episode_type != g_epis_type_sch AND
                           coalesce(ce.id_episode, ei.id_episode, 0) = nvl(ei.id_episode, 0))
                       AND ((pk_date_utils.get_timestamp_diff(sp.dt_target_tstz, (trunc(g_sysdate_tstz) - l_days_search)) > 0 AND
                           ei.id_episode IS NOT NULL) OR (sp.dt_target_tstz BETWEEN trunc(g_sysdate_tstz) AND
                           (g_sysdate_tstz + l_days_search) AND ei.id_episode IS NULL))
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ce.id_software = ei.id_software
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))
                       AND p.flg_status NOT IN ('I', 'C')
                     GROUP BY s.id_schedule, ce.id_patient) t
             ORDER BY dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OUTP_PP_CARE',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OUTP_PP_CARE',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_outp_pp_care;

    FUNCTION get_edis
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_wait_time_edis VARCHAR2(1) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_WAIT_TIME_EDIS',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_prof_resp NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CM_FLG_SHOW_VIPS', i_prof => l_prof);
    
        l_flg_get_inactive_epis VARCHAR2(1) := pk_sysconfig.get_config(i_code_cf => 'CM_GET_INACTIVE_EPIS',
                                                                       i_prof    => l_prof);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_EDIS';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_EDIS - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.rank_acuity,
                   t.acuity,
                   t.id_episode,
                   t.photo,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.desc_room,
                   t.name_prof,
                   t.dt_first_obs,
                   t.desc_epis_anamnesis,
                   t.service_desc,
                   t.date_admission_tstz,
                   t.date_last_generated_tstz,
                   t.id_patient,
                   t.id_crisis_machine,
                   t.epis_duration,
                   t.epis_duration_desc,
                   t.epis_flg_status,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette,
                   pk_sysdomain.get_domain('EPISODE.FLG_STATUS', t.epis_flg_status, i_lang) epis_flg_status_desc,
                   t.xml_header,
                   t.ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.episode_type <> g_epis_type_sch
                              AND ce.id_patient = t.id_patient
                              AND ce.id_episode = t.id_episode
                              AND ce.cm_report_name IS NOT NULL) report_list
              FROM (SELECT ei.triage_rank_acuity rank_acuity,
                           ei.triage_acuity acuity,
                           epis.id_episode,
                           NULL photo,
                           pk_adt.get_patient_name(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name,
                           pk_adt.get_patient_name_to_sort(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name_sort,
                           pk_patient.get_pat_age(i_lang, epis.id_patient, l_prof) pat_age,
                           pk_patient.get_pat_gender(epis.id_patient) pat_gender,
                           nvl(nvl(r.desc_room_abbreviation,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION' || ei.id_room)),
                               nvl(r.desc_room,
                                   pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || ei.id_room))) desc_room,
                           pk_prof_utils.get_name_signature(i_lang, l_prof, ei.id_professional) name_prof,
                           ei.dt_first_obs_tstz dt_first_obs,
                           pk_edis_grid.get_complaint_grid(i_lang, l_prof, epis.id_episode) desc_epis_anamnesis,
                           (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM dep_clin_serv dcs, clinical_service cs
                             WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                               AND cs.id_clinical_service = dcs.id_clinical_service) service_desc,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, l_prof) date_admission_tstz,
                           pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz,
                           ce.id_patient,
                           ce.id_crisis_machine,
                           pk_date_utils.get_timestamp_diff(decode(l_wait_time_edis,
                                                                   'T',
                                                                   nvl(get_triage_end_date(i_lang, epis.id_episode),
                                                                       g_sysdate_tstz),
                                                                   nvl(ei.dt_first_obs_tstz, g_sysdate_tstz)),
                                                            epis.dt_begin_tstz) epis_duration,
                           pk_date_utils.get_elapsed_tsz(i_lang,
                                                         epis.dt_begin_tstz,
                                                         decode(l_wait_time_edis,
                                                                'T',
                                                                nvl(get_triage_end_date(i_lang, epis.id_episode),
                                                                    g_sysdate_tstz),
                                                                nvl(ei.dt_first_obs_tstz, g_sysdate_tstz))) epis_duration_desc,
                           epis.flg_status epis_flg_status,
                           ce.id_crisis_epis,
                           ce.xml_header,
                           ce.flg_status ce_flg_status
                      FROM crisis_epis ce
                     INNER JOIN episode epis
                        ON epis.id_episode = ce.id_episode
                       AND ce.episode_type <> g_epis_type_sch
                     INNER JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                      LEFT OUTER JOIN room r
                        ON ei.id_room = r.id_room
                     INNER JOIN patient p
                        ON p.id_patient = epis.id_patient
                     WHERE ei.id_software = l_prof.software
                       AND epis.id_institution = l_prof.institution
                       AND epis.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ce.id_software = ei.id_software
                       AND (l_flg_get_inactive_epis = pk_alert_constant.g_yes OR
                           (l_flg_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))
                       AND p.flg_status NOT IN ('I', 'C')) t
             ORDER BY t.acuity;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EDIS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EDIS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_edis;

    FUNCTION get_oris
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search crisis_machine.interval_search%TYPE;
    
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
        l_prof            profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_prof_resp NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CM_FLG_SHOW_VIPS', i_prof => l_prof);
        l_sr_dept   NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'SURGERY_ROOM_DEPT', i_prof => l_prof);
    
        l_flg_get_inactive_epis VARCHAR2(1) := pk_sysconfig.get_config(i_code_cf => 'CM_GET_INACTIVE_EPIS',
                                                                       i_prof    => l_prof);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_ORIS';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_ORIS - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.dt_interv_preview,
                   t.desc_room,
                   t.photo,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.id_episode,
                   t.desc_diagnosis,
                   t.desc_surg,
                   t.prof_name,
                   t.dt_server,
                   t.dt_interv_preview_tstz,
                   t.prof_team_name,
                   t.date_last_generated_tstz,
                   t.epis_flg_status,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette,
                   pk_sysdomain.get_domain('EPISODE.FLG_STATUS', t.epis_flg_status, i_lang) epis_flg_status_desc,
                   (SELECT xml_header
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) xml_header,
                   (SELECT flg_status
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_episode = t.id_episode
                              AND ce.episode_type <> g_epis_type_sch
                              AND ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL) report_list
              FROM (SELECT DISTINCT pk_date_utils.date_time_chr_tsz(i_lang, s.dt_interv_preview_tstz, l_prof) dt_interv_preview,
                                    nvl(r.desc_room_abbreviation,
                                        pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_room,
                                    NULL photo,
                                    pk_adt.get_patient_name(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name,
                                    pk_adt.get_patient_name_to_sort(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name_sort,
                                    pk_patient.get_pat_age(i_lang, epis.id_patient, l_prof) pat_age,
                                    pk_patient.get_pat_gender(epis.id_patient) pat_gender,
                                    epis.id_episode,
                                    pk_sr_clinical_info.get_summary_diagnosis(i_lang,
                                                                              l_prof,
                                                                              s.id_episode,
                                                                              pk_alert_constant.g_yes) desc_diagnosis,
                                    pk_sr_clinical_info.get_proposed_surgery(i_lang, s.id_episode, l_prof) desc_surg,
                                    (SELECT pk_prof_utils.get_name_signature(i_lang, l_prof, pf.id_professional)
                                       FROM professional pf, sr_prof_team_det td
                                      WHERE td.id_episode = s.id_episode
                                        AND td.id_professional = td.id_prof_team_leader
                                        AND td.flg_status = g_active
                                        AND pf.id_professional = td.id_prof_team_leader
                                        AND rownum < 2) prof_name,
                                    pk_date_utils.date_send_tsz(i_lang, current_timestamp, l_prof) dt_server,
                                    pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, l_prof) dt_interv_preview_tstz,
                                    (SELECT prof_team_name
                                       FROM prof_team pt
                                      WHERE pt.id_prof_team = rec.id_prof_team) prof_team_name,
                                    pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz,
                                    epis.flg_status epis_flg_status,
                                    epis.id_patient,
                                    ce.id_crisis_epis,
                                    ce.id_crisis_machine
                      FROM schedule_sr s,
                           schedule h,
                           room r,
                           room_scheduled sr,
                           episode epis,
                           sr_surgery_record rec,
                           (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                              FROM room r, sr_room_status s
                             WHERE r.id_department = l_sr_dept
                               AND s.id_room(+) = r.id_room
                               AND (s.id_sr_room_state = (SELECT MAX(id_sr_room_state)
                                                            FROM sr_room_status s1
                                                           WHERE s1.id_room = s.id_room) OR NOT EXISTS
                                    (SELECT 1
                                       FROM sr_room_status s1
                                      WHERE s1.id_room = s.id_room))) m,
                           (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                              FROM sr_surgery_time st, sr_surgery_time_det std
                             WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                               AND st.flg_type = 'IC'
                               AND std.flg_status = g_epis_active) st,
                           crisis_epis ce,
                           epis_info ei,
                           patient p
                     WHERE ce.episode_type <> g_epis_type_sch
                       AND s.id_institution = l_prof.institution
                       AND h.id_schedule = s.id_schedule
                       AND epis.id_episode = ei.id_episode
                       AND ce.id_software = ei.id_software
                       AND epis.id_patient = s.id_patient
                       AND sr.id_schedule(+) = s.id_schedule
                       AND (sr.id_room_scheduled = (SELECT MAX(id_room_scheduled)
                                                      FROM room_scheduled
                                                     WHERE id_schedule = s.id_schedule) OR NOT EXISTS
                            (SELECT 1
                               FROM room_scheduled
                              WHERE id_schedule = s.id_schedule))
                       AND r.id_room(+) = sr.id_room
                       AND sr.id_room = m.id_room(+)
                       AND rec.id_schedule_sr(+) = s.id_schedule_sr
                       AND epis.id_episode = s.id_episode
                       AND st.id_episode(+) = epis.id_episode
                       AND epis.id_episode = ce.id_episode
                       AND epis.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ce.id_patient = p.id_patient
                       AND (l_flg_get_inactive_epis = pk_alert_constant.g_yes OR
                           (l_flg_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))
                       AND p.flg_status NOT IN ('I', 'C')) t
             ORDER BY dt_interv_preview_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORIS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORIS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_oris;

    FUNCTION get_inp
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_prof_resp NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CM_FLG_SHOW_VIPS', i_prof => l_prof);
    
        l_flg_get_inactive_epis VARCHAR2(1) := pk_sysconfig.get_config(i_code_cf => 'CM_GET_INACTIVE_EPIS',
                                                                       i_prof    => l_prof);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_INP';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_INP - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.desc_room,
                   t.pat_name,
                   t.pat_name_sort,
                   t.id_episode,
                   t.name_prof,
                   t.pat_age,
                   t.pat_gender,
                   t.photo,
                   t.service,
                   t.bed_name,
                   t.first_nurse_resp,
                   t.date_admission_tstz,
                   t.date_last_generated_tstz,
                   t.epis_flg_status,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette,
                   pk_sysdomain.get_domain('EPISODE.FLG_STATUS', t.epis_flg_status, i_lang) epis_flg_status_desc,
                   (SELECT xml_header
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) xml_header,
                   (SELECT flg_status
                      FROM crisis_epis ce
                     WHERE ce.id_crisis_epis = t.id_crisis_epis) ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_episode = t.id_episode
                              AND ce.episode_type <> g_epis_type_sch
                              AND ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL) report_list
              FROM (SELECT DISTINCT nvl(nvl(ro.desc_room_abbreviation,
                                            pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                                        nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                                    pk_adt.get_patient_name(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name,
                                    pk_adt.get_patient_name_to_sort(i_lang, l_prof, epis.id_patient, l_prof_resp) pat_name_sort,
                                    epis.id_episode,
                                    pk_prof_utils.get_nickname(i_lang, ei.id_professional) name_prof,
                                    pk_patient.get_pat_age(i_lang, epis.id_patient, l_prof) pat_age,
                                    pk_patient.get_pat_gender(epis.id_patient) pat_gender,
                                    NULL photo,
                                    decode('BED.CODE_BED.' || ei.id_bed,
                                           NULL,
                                           NULL,
                                           nvl(pk_translation.get_translation(i_lang, dpt.abbreviation),
                                               pk_translation.get_translation(i_lang, dpt.code_department))) service,
                                    (SELECT nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed))
                                       FROM bed b
                                      WHERE b.id_bed = ei.id_bed) bed_name,
                                    pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) first_nurse_resp,
                                    pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, l_prof) date_admission_tstz,
                                    pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz,
                                    epis.flg_status epis_flg_status,
                                    epis.id_patient,
                                    ce.id_crisis_epis,
                                    ce.flg_status,
                                    ce.id_crisis_machine
                      FROM crisis_epis ce
                     INNER JOIN episode epis
                        ON epis.id_episode = ce.id_episode
                       AND ce.episode_type <> g_epis_type_sch
                     INNER JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                      LEFT OUTER JOIN room ro
                        ON ei.id_room = ro.id_room
                     INNER JOIN department dpt
                        ON dpt.id_department = epis.id_department
                     INNER JOIN patient p
                        ON p.id_patient = epis.id_patient
                     WHERE ei.id_software = l_prof.software
                       AND epis.id_institution = l_prof.institution
                       AND epis.flg_ehr = pk_alert_constant.g_epis_ehr_normal
                       AND epis.id_epis_type IN (g_inp_epis_type, g_obs_epis_type)
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ce.id_software = ei.id_software
                       AND (l_flg_get_inactive_epis = pk_alert_constant.g_yes OR
                           (l_flg_get_inactive_epis = pk_alert_constant.g_no AND
                           epis.flg_status != pk_alert_constant.g_epis_status_inactive))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))
                       AND p.flg_status NOT IN ('I', 'C')) t
             ORDER BY pat_name_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INP',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INP',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_inp;

    FUNCTION get_rehab
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_REHAB';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_REHAB - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.id_episode,
                   t.origin,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.photo,
                   t.num_clin_record,
                   t.name_prof,
                   t.desc_session_type,
                   t.desc_schedule_type,
                   t.service,
                   t.desc_room,
                   t.bed_name,
                   t.date_last_generated_tstz,
                   t.dt_target,
                   t.dt_target_tstz,
                   nvl((SELECT e.flg_status
                         FROM episode e
                        WHERE e.id_episode = t.id_episode),
                       (SELECT e.flg_status
                          FROM episode e
                         INNER JOIN epis_info ei
                            ON ei.id_episode = e.id_episode
                         WHERE ei.id_schedule = t.id_schedule
                           AND rownum = 1)) epis_flg_status,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette,
                   pk_sysdomain.get_domain('EPISODE.FLG_STATUS',
                                           nvl((SELECT e.flg_status
                                                 FROM episode e
                                                WHERE e.id_episode = t.id_episode),
                                               (SELECT e.flg_status
                                                  FROM episode e
                                                 INNER JOIN epis_info ei
                                                    ON ei.id_episode = e.id_episode
                                                 WHERE ei.id_schedule = t.id_schedule
                                                   AND rownum = 1)),
                                           i_lang) epis_flg_status_desc,
                   t.xml_header,
                   t.ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL
                              AND ce.id_patient = t.id_patient
                              AND ce.id_schedule = t.id_schedule
                              AND ce.id_software = l_prof.software
                              AND nvl(ce.id_episode, -1) = nvl(t.id_episode, -1)) report_list
              FROM (SELECT ce.id_episode,
                           ce.id_schedule,
                           ce.id_crisis_machine,
                           origin,
                           pat_name,
                           pat_name_sort,
                           pat_age,
                           pat_gender,
                           photo,
                           num_clin_record,
                           name_prof,
                           desc_session_type,
                           desc_schedule_type,
                           servico service,
                           desc_room,
                           bed_name,
                           dt_target,
                           dt_target_tstz,
                           ce.id_patient,
                           ce.xml_header,
                           ce.flg_status ce_flg_status,
                           pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz
                      FROM crisis_epis ce,
                           TABLE(pk_rehab_external_api_db.tf_cm_rehab_episode_detail(i_lang,
                                                                                     l_prof,
                                                                                     ce.id_episode,
                                                                                     ce.id_schedule)) cre
                     WHERE ce.id_software = l_prof.software
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND
                           cre.id_episode = ce.id_episode) OR
                           (ce.episode_type = g_epis_type_sch AND cre.id_schedule = ce.id_schedule))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))) t
             ORDER BY pat_name_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REHAB',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REHAB',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_rehab;

    FUNCTION get_itech
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_ITECH';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_ITECH - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.id_episode,
                   t.id_schedule,
                   t.origin,
                   t.origin_desc,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.photo,
                   t.num_clin_record,
                   t.name_prof_resp,
                   t.name_prof_req,
                   t.desc_exam,
                   t.flg_imaging_status,
                   t.flg_status,
                   t.flg_status_desc,
                   t.flg_status_icon,
                   t.dt_target,
                   t.dt_target_tstz,
                   t.dt_admission_tstz date_admission_tstz,
                   t.epis_duration,
                   t.epis_duration_desc,
                   t.rank_acuity,
                   t.acuity,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette, --t.silhouette,
                   t.xml_header,
                   t.ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL
                              AND ce.id_patient = t.id_patient
                              AND ce.id_schedule = t.id_schedule
                              AND ce.id_software = l_prof.software
                              AND nvl(ce.id_episode, -1) = nvl(t.id_episode, -1)) report_list
              FROM (SELECT ce.id_patient,
                           ce.id_episode,
                           ce.id_schedule,
                           ce.id_crisis_machine,
                           origin,
                           origin_desc,
                           pat_name,
                           pat_name_sort,
                           pat_age,
                           pat_gender,
                           NULL photo,
                           num_clin_record,
                           name_prof_resp,
                           dbms_lob.substr(name_prof_req, 1000, 1) name_prof_req,
                           dbms_lob.substr(desc_exam, 1000, 1) desc_exam,
                           flg_imaging_status,
                           cre.flg_status,
                           flg_status_desc,
                           flg_status_icon,
                           dt_target,
                           dt_target_tstz,
                           dt_admission_tstz,
                           epis_duration,
                           epis_duration_desc,
                           rank_acuity,
                           acuity,
                           ce.xml_header,
                           ce.flg_status ce_flg_status,
                           pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz
                      FROM crisis_epis ce,
                           TABLE(pk_exams_external_api_db.tf_cm_imaging_episode_detail(i_lang,
                                                                                       l_prof,
                                                                                       ce.id_episode,
                                                                                       ce.id_schedule)) cre
                     WHERE ce.id_software = l_prof.software
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND
                           cre.id_episode = ce.id_episode) OR
                           (ce.episode_type = g_epis_type_sch AND cre.id_schedule = ce.id_schedule))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))) t
             ORDER BY pat_name_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ITECH',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ITECH',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_itech;

    FUNCTION get_exams
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_EXAMS';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_EXAMS - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.id_episode,
                   t.id_schedule,
                   t.origin,
                   t.origin_desc,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.photo,
                   t.num_clin_record,
                   t.name_prof_resp,
                   t.name_prof_req,
                   t.desc_exam, --t.exam_desc,
                   t.flg_exam_status,
                   t.flg_status,
                   t.flg_status_desc,
                   t.flg_status_icon,
                   t.dt_target,
                   t.dt_target_tstz,
                   t.dt_admission_tstz date_admission_tstz,
                   t.epis_duration,
                   t.epis_duration_desc,
                   t.rank_acuity,
                   t.acuity,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette, --t.silhouette,
                   t.xml_header,
                   t.ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL
                              AND ce.id_patient = t.id_patient
                              AND ce.id_schedule = t.id_schedule
                              AND ce.id_software = l_prof.software
                              AND nvl(ce.id_episode, -1) = nvl(t.id_episode, -1)) report_list
              FROM (SELECT ce.id_patient,
                           ce.id_episode,
                           ce.id_schedule,
                           ce.id_crisis_machine,
                           origin,
                           origin_desc,
                           pat_name,
                           pat_name_sort,
                           pat_age,
                           pat_gender,
                           NULL photo,
                           num_clin_record,
                           name_prof_resp,
                           dbms_lob.substr(name_prof_req, 1000, 1) name_prof_req,
                           dbms_lob.substr(desc_exam, 1000, 1) desc_exam, --exam_desc,
                           flg_exam_status,
                           cre.flg_status,
                           flg_status_desc,
                           flg_status_icon,
                           dt_target,
                           dt_target_tstz,
                           dt_admission_tstz,
                           epis_duration,
                           epis_duration_desc,
                           rank_acuity,
                           acuity,
                           ce.xml_header,
                           ce.flg_status ce_flg_status,
                           pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz
                      FROM crisis_epis ce,
                           TABLE(pk_exams_external_api_db.tf_cm_exams_episode_detail(i_lang,
                                                                                     l_prof,
                                                                                     ce.id_episode,
                                                                                     ce.id_schedule)) cre
                     WHERE ce.id_software = l_prof.software
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND
                           cre.id_episode = ce.id_episode) OR
                           (ce.episode_type = g_epis_type_sch AND cre.id_schedule = ce.id_schedule))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))) t
             ORDER BY pat_name_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAMS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAMS',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_exams;

    FUNCTION get_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        o_select         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_days_search     crisis_machine.interval_search%TYPE;
        l_id_professional NUMBER(24) := pk_sysconfig.get_config(i_code_cf => 'CRISIS_MACHINE_USER',
                                                                i_prof    => profissional(0, i_institution, i_software));
    
        l_prof profissional := profissional(l_id_professional, i_institution, i_software);
    
        l_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET_DIET';
        g_sysdate_tstz := current_timestamp;
    
        g_error       := 'GET_DIET - GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
    
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --Query that will retriev the grid for the software
        g_error := 'Open cursor o_select';
        OPEN o_select FOR
            SELECT t.id_episode,
                   t.id_schedule,
                   t.origin,
                   t.origin_desc,
                   t.pat_name,
                   t.pat_name_sort,
                   t.pat_age,
                   t.pat_gender,
                   t.photo,
                   t.num_clin_record,
                   t.diagnosis_desc,
                   t.service_desc,
                   t.room_desc,
                   t.bed_desc,
                   t.name_prof_resp,
                   t.name_prof_req,
                   t.reason_req,
                   t.dt_target,
                   t.dt_target_tstz,
                   t.dt_next_followup,
                   t.dt_next_followup_tstz,
                   t.flg_request_type,
                   t.flg_status,
                   t.flg_status_desc,
                   t.flg_status_icon,
                   t.desc_status,
                   t.id_type_appointment,
                   t.flg_type_appointment_desc,
                   t.rank_acuity,
                   t.acuity,
                   get_silhouette(i_lang, pk_hea_prv_pat.get_silhouette(l_prof, t.id_patient)) silhouette,
                   t.xml_header,
                   t.ce_flg_status,
                   CURSOR (SELECT ce.cm_report_name, ce.id_report cm_report_id
                             FROM crisis_epis ce
                            WHERE ce.id_crisis_machine = t.id_crisis_machine
                              AND ce.cm_report_name IS NOT NULL
                              AND ce.id_patient = t.id_patient
                              AND ce.id_schedule = t.id_schedule
                              AND ce.id_software = l_prof.software
                              AND nvl(ce.id_episode, -1) = nvl(t.id_episode, -1)) report_list
              FROM (SELECT ce.id_patient,
                           ce.id_episode,
                           ce.id_schedule,
                           ce.id_crisis_machine,
                           origin,
                           origin_desc,
                           pat_name,
                           pat_name_sort,
                           pat_age,
                           pat_gender,
                           NULL photo,
                           num_clin_record,
                           diagnosis_desc,
                           service_desc,
                           room_desc,
                           bed_desc,
                           name_prof_resp,
                           name_prof_req,
                           reason_req,
                           dt_target,
                           dt_target_tstz,
                           dt_next_followup,
                           dt_next_followup_tstz,
                           flg_request_type,
                           cre.flg_status,
                           flg_status_desc,
                           flg_status_icon,
                           desc_status,
                           id_type_appointment,
                           flg_type_appointment_desc,
                           rank_acuity,
                           acuity,
                           ce.xml_header,
                           ce.flg_status ce_flg_status,
                           pk_date_utils.date_send_tsz(i_lang, ce.date_last_generated_tstz, l_prof) date_last_generated_tstz
                      FROM crisis_epis ce,
                           TABLE(pk_diet_api_db.tf_cm_diet_episode_detail(i_lang, l_prof, ce.id_episode, ce.id_schedule)) cre
                     WHERE ce.id_software = l_prof.software
                       AND ce.id_crisis_machine = i_crisis_machine
                       AND ((ce.episode_type <> g_epis_type_sch AND ce.id_episode IS NOT NULL AND
                           cre.id_episode = ce.id_episode) OR
                           (ce.episode_type = g_epis_type_sch AND cre.id_schedule = ce.id_schedule))
                       AND (ce.date_last_generated_tstz > g_sysdate_tstz - l_days_search OR
                           (ce.date_last_generated_tstz IS NULL AND ce.flg_status = 'W'))) t
             ORDER BY pat_name_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIET',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIET',
                                              o_error);
            pk_types.open_my_cursor(o_select);
            RETURN FALSE;
    END get_diet;

    FUNCTION generate_print_tool
    (
        i_lang             IN language.id_language%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_software         IN software.id_software%TYPE,
        i_application_name IN crisis_soft_details.aplication_name%TYPE,
        i_crisis_machine   IN crisis_machine.id_crisis_machine%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_select pk_types.cursor_type;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GENERATE_PRINT_TOOL';
        OPEN l_select FOR
            SELECT pk_sysdomain.get_domain('CRISIS_EPIS.FLG_REPORT_TYPE', t.flg_report_type, i_lang) desc_message,
                   t.flg_report_type,
                   NULL cm_report_id,
                   convert_tbl_to_cursor(i_lang,
                                         CAST(COLLECT(nvl(to_char(t.flg_report_type), '<NULL>')) AS table_varchar),
                                         CAST(COLLECT(nvl(to_char(t.cm_report_name), '<NULL>')) AS table_varchar),
                                         CAST(COLLECT(nvl(to_char(t.id_report), '<NULL>')) AS table_varchar),
                                         CAST(COLLECT(nvl(to_char(pk_translation.get_translation(i_lang,
                                                                                                 'REPORTS.CODE_REPORTS.' ||
                                                                                                 t.id_report)),
                                                          '<NULL>')) AS table_varchar)) report_list
              FROM (SELECT cmd.id_software,
                           ce.flg_report_type,
                           ce.id_report,
                           pk_translation.get_translation(i_lang, 'REPORTS.CODE_REPORTS.' || ce.id_report) desc_report,
                           CASE
                                WHEN ce.flg_report_type = 'G' THEN
                                 ce.cm_report_name
                                ELSE
                                 NULL
                            END cm_report_name
                      FROM crisis_machine_det cmd
                     INNER JOIN crisis_epis ce
                        ON ce.id_crisis_machine = cmd.id_crisis_machine
                       AND ce.id_software = cmd.id_software
                       AND ce.cm_report_name IS NOT NULL
                     WHERE cmd.id_crisis_machine = i_crisis_machine
                       AND cmd.id_institution = i_institution
                       AND cmd.id_software = i_software
                       AND EXISTS (SELECT 1
                              FROM (SELECT rptd.id_reports,
                                           rank() over(PARTITION BY rptd.id_reports ORDER BY rpt.id_institution DESC) rec_rank
                                      FROM rep_profile_template_det rptd
                                     INNER JOIN rep_profile_template rpt
                                        ON rpt.id_rep_profile_template = rptd.id_rep_profile_template
                                     INNER JOIN rep_prof_templ_access rpta
                                        ON rpta.id_rep_profile_template = rpt.id_rep_profile_template
                                     INNER JOIN reports r
                                        ON r.id_reports = rptd.id_reports
                                     WHERE rptd.flg_area_report = 'R'
                                       AND rpt.id_institution IN (0, i_institution)
                                       AND rpt.id_software = i_software
                                       AND nvl(rptd.flg_available, 'Y') = 'Y'
                                       AND nvl(r.flg_available, 'Y') = 'Y'
                                       AND rptd.id_rep_profile_template IN
                                           (90, 91, 92, 93, 94, 95, 103, 104, 105, 107, 108)) t1
                             WHERE t1.rec_rank = 1
                               AND t1.id_reports = ce.id_report)) t
             GROUP BY t.flg_report_type
             ORDER BY t.flg_report_type;
    
        g_error := 'WRITE AND CRYPT XML';
        IF NOT write_and_crypt(i_lang,
                               NULL,
                               NULL,
                               i_crisis_machine,
                               NULL,
                               NULL,
                               l_select,
                               lower(i_crisis_machine || g_separator || g_modules || g_separator || i_application_name ||
                                     g_separator || 'xml' || g_separator || 'print_tool'),
                               l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_PRINT_TOOL',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_PRINT_TOOL',
                                              o_error);
            RETURN FALSE;
    END generate_print_tool;

    FUNCTION generate_xml_details
    (
        i_lang             IN language.id_language%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_software         IN software.id_software%TYPE,
        i_application_name IN crisis_soft_details.aplication_name%TYPE,
        i_crisis_machine   IN crisis_machine.id_crisis_machine%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := i_application_name || '-GENERATE_PRINT_TOOL';
        IF NOT generate_print_tool(i_lang, i_institution, i_software, i_application_name, i_crisis_machine, l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_DETAILS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_DETAILS',
                                              o_error);
            RETURN FALSE;
    END generate_xml_details;

    FUNCTION generate_xml_files
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_generate_all   IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_found_application BOOLEAN;
    
        l_select pk_types.cursor_type;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Arrays initilization';
        g_file_count.delete();
    
        g_error := 'GENERATE_XML_FILES - SET INITIAL XML';
        IF NOT set_initial_xml(i_lang, i_crisis_machine, i_generate_all, l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
        IF i_generate_all
        THEN
            FOR rec IN (SELECT cm.id_crisis_machine,
                               cm.id_language,
                               cmd.id_institution,
                               csd.id_software,
                               csd.aplication_name,
                               csd.id_deepnav,
                               csd.package_name,
                               csd.id_aplication,
                               cm.pwd_enc_cri_machine
                          FROM crisis_machine cm
                         INNER JOIN crisis_machine_det cmd
                            ON cmd.id_crisis_machine = cm.id_crisis_machine
                         INNER JOIN crisis_soft_details csd
                            ON csd.id_software = cmd.id_software
                         WHERE cm.id_crisis_machine = i_crisis_machine)
            LOOP
                l_found_application := FALSE;
            
                IF upper(rec.id_aplication) = 'OUTP'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_OUTP_PP_CARE - OUTP';
                    IF NOT get_outp_pp_care(rec.id_language,
                                            i_crisis_machine,
                                            rec.id_institution,
                                            rec.id_software,
                                            l_select,
                                            l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --@TODO join condition with OUTP since it's the same
                ELSIF upper(rec.id_aplication) = 'PP'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_OUTP_PP_CARE - PP';
                    IF NOT get_outp_pp_care(rec.id_language,
                                            i_crisis_machine,
                                            rec.id_institution,
                                            rec.id_software,
                                            l_select,
                                            l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --@TODO join condition with OUTP since it's the same
                ELSIF upper(rec.id_aplication) = 'CARE'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_OUTP_PP_CARE - CARE';
                    IF NOT get_outp_pp_care(rec.id_language,
                                            i_crisis_machine,
                                            rec.id_institution,
                                            rec.id_software,
                                            l_select,
                                            l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSIF upper(rec.id_aplication) = 'EDIS'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_EDIS';
                    IF NOT get_edis(rec.id_language,
                                    i_crisis_machine,
                                    rec.id_institution,
                                    rec.id_software,
                                    l_select,
                                    l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSIF upper(rec.id_aplication) = 'ORIS'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_ORIS';
                    IF NOT get_oris(rec.id_language,
                                    i_crisis_machine,
                                    rec.id_institution,
                                    rec.id_software,
                                    l_select,
                                    l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSIF upper(rec.id_aplication) = 'INP'
                THEN
                    l_found_application := TRUE;
                
                    -- GS 2010/12/15 - Unused development at this time, TODO in a future release.
                    /*                g_error := rec.aplication_name || '-GENERATE_PRINT_TOOL';
                    IF NOT generate_print_tool(rec.id_language
                                              ,rec.id_institution
                                              ,rec.id_software
                                              ,i_crisis_machine
                                              ,l_error)
                    THEN
                        RAISE g_exception;
                    END IF;*/
                
                    g_error := 'GET_INP';
                    IF NOT get_inp(rec.id_language,
                                   i_crisis_machine,
                                   rec.id_institution,
                                   rec.id_software,
                                   l_select,
                                   l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSIF upper(rec.id_aplication) = 'REHAB'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_REHAB';
                    IF NOT get_rehab(rec.id_language,
                                     i_crisis_machine,
                                     rec.id_institution,
                                     rec.id_software,
                                     l_select,
                                     l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSIF upper(rec.id_aplication) = 'ITECH'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_ITECH';
                    IF NOT get_itech(rec.id_language,
                                     i_crisis_machine,
                                     rec.id_institution,
                                     rec.id_software,
                                     l_select,
                                     l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSIF upper(rec.id_aplication) = 'EXAMS'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_EXAMS';
                    IF NOT get_exams(rec.id_language,
                                     i_crisis_machine,
                                     rec.id_institution,
                                     rec.id_software,
                                     l_select,
                                     l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSIF upper(rec.id_aplication) = 'DIETITIAN'
                THEN
                    l_found_application := TRUE;
                    g_error             := 'GET_DIET';
                    IF NOT get_diet(rec.id_language,
                                    i_crisis_machine,
                                    rec.id_institution,
                                    rec.id_software,
                                    l_select,
                                    l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END IF; --upper(rec.id_aplication) = '____'
            
                IF l_found_application
                THEN
                    g_error := 'CALL function generate_xml_details';
                    IF NOT generate_xml_details(rec.id_language,
                                                rec.id_institution,
                                                rec.id_software,
                                                rec.aplication_name,
                                                rec.id_crisis_machine,
                                                l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'WRITE AND CRYPT XML';
                    IF NOT write_and_crypt(i_lang,
                                           rec.id_software,
                                           rec.aplication_name,
                                           rec.id_crisis_machine,
                                           rec.id_deepnav,
                                           rec.package_name,
                                           l_select,
                                           NULL,
                                           l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_FILES',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_FILES',
                                              o_error);
            RETURN FALSE;
    END generate_xml_files;

    FUNCTION generate_xml_files_cur
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_generate_all   IN BOOLEAN DEFAULT TRUE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GENERATE_XML_FILES_CUR - call function generate_xml_files for id_crisis_machine:' ||
                   i_crisis_machine;
        IF NOT generate_xml_files(i_lang, i_crisis_machine, i_generate_all, l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT *
              FROM cm_cursor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_FILES_CUR',
                                              l_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GENERATE_XML_FILES_CUR' || '/ ' || g_error || chr(10) || l_error.ora_sqlerrm;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GENERATE_XML_FILES_CUR',
                                              l_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GENERATE_XML_FILES_CUR' || '/ ' || g_error || chr(10) || SQLERRM;
            RETURN FALSE;
    END generate_xml_files_cur;

    FUNCTION set_rsync
    (
        i_lang              IN language.id_language%TYPE,
        i_crisis_log        IN crisis_log.id_crisis_log%TYPE,
        i_crisis_machine    IN crisis_log.id_crisis_machine%TYPE,
        i_rsync_file        IN crisis_log.log_command%TYPE,
        i_result            IN crisis_log.flg_status%TYPE,
        i_rep_generated     IN crisis_log.reports_generated%TYPE,
        i_rep_not_generated IN crisis_log.reports_not_generated%TYPE,
        i_dt_upd_start      IN TIMESTAMP WITH TIME ZONE,
        i_dt_rep_cleanup    IN TIMESTAMP WITH TIME ZONE,
        i_dt_xml_gen        IN TIMESTAMP WITH TIME ZONE,
        i_dt_sta_upd        IN TIMESTAMP WITH TIME ZONE,
        i_dt_rep_upd        IN TIMESTAMP WITH TIME ZONE,
        i_dt_upd_end        IN TIMESTAMP WITH TIME ZONE,
        i_cm_adress         IN crisis_log.crisis_machine_address%TYPE DEFAULT NULL,
        o_error             OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SET_RSYNC';
        MERGE INTO crisis_log cl
        USING (SELECT i_crisis_log            id_crisis_log,
                      i_rsync_file            log_command,
                      i_result                flg_status,
                      i_crisis_machine        id_crisis_machine,
                      g_flg_rsync             flg_type,
                      i_rep_generated         reports_generated,
                      i_rep_not_generated     reports_not_generated,
                      i_dt_upd_start          dt_upd_start_tstz,
                      i_dt_rep_cleanup        dt_rep_cleanup_tstz,
                      i_dt_xml_gen            dt_xml_gen_tstz,
                      i_dt_sta_upd            dt_sta_upd_tstz,
                      i_dt_rep_upd            dt_rep_upd_tstz,
                      i_dt_upd_end            dt_upd_end_tstz,
                      pk_alertlog.get_call_id callid,
                      i_cm_adress             crisis_machine_address
                 FROM dual) t
        ON (cl.id_crisis_log = t.id_crisis_log)
        WHEN MATCHED THEN
            UPDATE
               SET cl.log_command            = cl.log_command || chr(10) || t.log_command,
                   cl.flg_status             = decode(cl.flg_status, g_cl_flg_status_e, cl.flg_status, t.flg_status),
                   cl.flg_type               = nvl(cl.flg_type, t.flg_type),
                   cl.reports_generated      = nvl(cl.reports_generated, t.reports_generated),
                   cl.reports_not_generated  = nvl(cl.reports_not_generated, t.reports_not_generated),
                   cl.dt_upd_start_tstz      = nvl(cl.dt_upd_start_tstz, t.dt_upd_start_tstz),
                   cl.dt_rep_cleanup_tstz    = nvl(cl.dt_rep_cleanup_tstz, t.dt_rep_cleanup_tstz),
                   cl.dt_xml_gen_tstz        = nvl(cl.dt_xml_gen_tstz, t.dt_xml_gen_tstz),
                   cl.dt_sta_upd_tstz        = nvl(cl.dt_sta_upd_tstz, t.dt_sta_upd_tstz),
                   cl.dt_rep_upd_tstz        = nvl(cl.dt_rep_upd_tstz, t.dt_rep_upd_tstz),
                   cl.dt_upd_end_tstz        = nvl(cl.dt_upd_end_tstz, t.dt_upd_end_tstz),
                   cl.crisis_machine_address = nvl(cl.crisis_machine_address, t.crisis_machine_address)
        WHEN NOT MATCHED THEN
            INSERT
                (id_crisis_log,
                 log_command,
                 flg_status,
                 id_crisis_machine,
                 flg_type,
                 reports_generated,
                 reports_not_generated,
                 dt_upd_start_tstz,
                 dt_rep_cleanup_tstz,
                 dt_xml_gen_tstz,
                 dt_sta_upd_tstz,
                 dt_rep_upd_tstz,
                 dt_upd_end_tstz,
                 crisis_machine_address)
            VALUES
                (t.id_crisis_log,
                 t.log_command,
                 t.flg_status,
                 t.id_crisis_machine,
                 t.flg_type,
                 t.reports_generated,
                 t.reports_not_generated,
                 t.dt_upd_start_tstz,
                 t.dt_rep_cleanup_tstz,
                 t.dt_xml_gen_tstz,
                 t.dt_sta_upd_tstz,
                 t.dt_rep_upd_tstz,
                 t.dt_upd_end_tstz,
                 t.crisis_machine_address);
    
        pk_alertlog.log_info('Ended RSYNC with ' || pk_alertlog.get_call_id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' || 'SET_RSYNC' || '/ ' ||
                       g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(o_error);
            RETURN FALSE;
    END set_rsync;

    FUNCTION get_crisis_machine_clone(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE) RETURN table_varchar IS
    
        tbl_cm_address table_varchar;
    
        k_na CONSTANT VARCHAR2(0010 CHAR) := 'N/A';
    
    BEGIN
    
        SELECT coalesce(cm.crisis_machine_address, k_na) mac_add
          BULK COLLECT
          INTO tbl_cm_address
          FROM crisis_machine cm
         WHERE cm.id_crisis_machine = i_crisis_machine
           AND cm.flg_available = pk_alert_constant.g_yes;
    
        IF tbl_cm_address.count > 0
        THEN
            tbl_cm_address := pk_string_utils.str_split(tbl_cm_address(1), '|');
        END IF;
    
        RETURN tbl_cm_address;
    
    END get_crisis_machine_clone;

    --ToDo - in this function when we have parameterization errors (diferent institution for the same CM) the query can return innacurate records
    FUNCTION get_crisis_machine_details
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_details        OUT pk_types.cursor_type,
        o_cm_log         OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_CURSOR C_CM_DET #3 -> ' || i_crisis_machine;
        OPEN o_details FOR
            WITH cmdet AS
             (SELECT cmd.id_crisis_machine, cmd.id_institution, 0 id_software
                FROM crisis_machine_det cmd
               WHERE cmd.id_crisis_machine = i_crisis_machine
               GROUP BY cmd.id_crisis_machine, cmd.id_institution)
            SELECT g_cm_dir_gen || i_crisis_machine || g_separator gen_dir,
                   g_cm_dir_upd || i_crisis_machine || g_separator upd_dir,
                   cmdet.id_institution,
                   cmdet.id_software,
                   cm.id_language,
                   pk_sysconfig.get_config('CRISIS_MACHINE_USER',
                                           profissional(0, cmdet.id_institution, cmdet.id_software)) id_prof,
                   cm.pwd_enc_cri_machine,
                   cm.act_interval,
                   (extract(DAY FROM(cm.interval_search)) + extract(hour FROM(cm.interval_search)) / 24 +
                   extract(minute FROM(cm.interval_search)) / 24 / 60 +
                   extract(SECOND FROM(cm.interval_search)) / 24 / 60 / 60) interval_search,
                   pk_sysconfig.get_config('CM_TOUCH_CLIENT', profissional(0, cmdet.id_institution, cmdet.id_software)) cm_touch_client,
                   pk_sysconfig.get_config('CM_AUTO_DISABLE_UI_SYNC',
                                           profissional(0, cmdet.id_institution, cmdet.id_software)) auto_disable_ui_sync
              FROM crisis_machine cm
             INNER JOIN cmdet
                ON cmdet.id_crisis_machine = cm.id_crisis_machine
             WHERE cm.id_crisis_machine = i_crisis_machine
               AND cm.flg_available = pk_alert_constant.g_yes;
    
        g_error := 'GET_CURSOR O_CM_LOG WITH SEQ_CRISIS_LOG #4 -> ' || i_crisis_machine;
        OPEN o_cm_log FOR
            SELECT cma.column_value cm_address, seq_crisis_log.nextval id_crisis_log
              FROM TABLE(pk_crisis_machine.get_crisis_machine_clone(i_crisis_machine => i_crisis_machine)) cma;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_CRISIS_MACHINE_DETAILS' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(o_error);
            RETURN FALSE;
    END get_crisis_machine_details;

    FUNCTION get_crisis_inst(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE) RETURN NUMBER IS
    
        l_inst crisis_machine_det.id_institution%TYPE;
    
    BEGIN
    
        g_error := 'GET_CRISIS_INST';
        SELECT cmd.id_institution
          INTO l_inst
          FROM crisis_machine_det cmd
         WHERE cmd.id_crisis_machine = i_crisis_machine
           AND rownum < 2;
    
        RETURN l_inst;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('GET_CRISIS INST: ' || SQLERRM);
            RETURN NULL;
    END get_crisis_inst;

    --Delete LOGS
    --Delete EPISODE

    FUNCTION delete_episodes_and_logs
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_days_search crisis_machine.interval_search%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error       := 'GET_DAYS_SEARCH';
        l_days_search := get_crisis_interval_search(i_lang, i_crisis_machine, l_error);
        IF l_error IS NOT NULL
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'DELETE LOGS WITH INTERVAL OF : ' || l_days_search;
        pk_alertlog.log_info(g_error);
        IF l_days_search IS NOT NULL
        THEN
            DELETE FROM crisis_log cl
             WHERE cl.id_crisis_machine = i_crisis_machine
                  --Delete all records leaving a 10 minutes bkp
               AND cl.dt_upd_start_tstz < (current_timestamp - l_days_search - numtodsinterval(10, 'minute'));
        
            DELETE FROM crisis_epis ce
             WHERE ce.id_crisis_machine = i_crisis_machine
               AND ce.flg_status <> g_flg_status_in_progress
                  --Delete all records leaving a 10 minutes bkp
               AND ce.date_last_generated_tstz < (current_timestamp - l_days_search - numtodsinterval(10, 'minute'));
        
            DELETE FROM crisis_epis ce
             WHERE ce.id_crisis_machine = i_crisis_machine
               AND ce.flg_status <> g_flg_status_in_progress
               AND EXISTS (SELECT 1
                      FROM episode epis
                     WHERE epis.id_episode = ce.id_episode
                       AND epis.flg_status = pk_alert_constant.g_epis_status_inactive)
               AND EXISTS
             (SELECT 1
                      FROM crisis_machine_det cmd
                     WHERE cmd.id_crisis_machine = ce.id_crisis_machine
                       AND cmd.id_software = ce.id_software
                       AND pk_sysconfig.get_config('CM_GET_INACTIVE_EPIS', cmd.id_institution, cmd.id_software) =
                           pk_alert_constant.g_no);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_EPISODES_AND_LOGS',
                                              l_error);
        
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'DELETE_EPISODES_AND_LOGS' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_EPISODES_AND_LOGS',
                                              l_error);
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'DELETE_EPISODES_AND_LOGS' || '/ ' || g_error || ' / ' || l_error.err_desc;
            RETURN FALSE;
    END delete_episodes_and_logs;

    FUNCTION get_file_sync_setup
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_cm_setup       OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CM_SETUP CURSOR';
        OPEN o_cm_setup FOR
            SELECT g_cm_dir_upd cm_dir_upd,
                   g_cm_dir_stage cm_dir_stage,
                   g_cm_targetfolder targetfolder,
                   g_cm_keys_path || i_crisis_machine private_key_file,
                   to_char(cm.ssh_local_port_fwd) local_port,
                   to_char(cm.jfs_remote_port) jfs_remote_port,
                   cm.crisis_machine_address,
                   to_char(nvl(cm.ssh_remote_port, g_default_ssh_port)) ssh_remote_port,
                   g_tunnelremotehost tunnelremotehost,
                   g_rsync_server_user cwrsync_server_user,
                   cm.flg_upd_ui flg_upd_ui
              FROM crisis_machine cm
             WHERE cm.id_crisis_machine = i_crisis_machine;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_FILE_SYNC_SETUP' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(o_error);
            pk_types.open_my_cursor(o_cm_setup);
            RETURN FALSE;
    END get_file_sync_setup;

    FUNCTION delete_old_files
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_epis2delete    OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_epis2delete FOR
            SELECT ce.cm_report_name
              FROM crisis_epis ce
             WHERE ce.id_crisis_machine = i_crisis_machine
               AND ce.cm_report_name IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'DELETE_OLD_FILES' || '/ ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(o_error);
            RETURN FALSE;
    END delete_old_files;

    /** 
    * Gets reports list for a specific institution/software
    *
    * @param      i_lang                  Language
    * @param      i_prof                  Profissional
    * @param      i_rep_profile_template  Rep_profile_template ID
    * @param      i_flg_area_report       rep_profile_template_det.flg_area_report
    * @param      o_reports               cursor with reports list
    * @param      o_error                 error
    *
    * @return     boolean
    *
    * @author     Gustavo Serrano
    * @since      2011/05/27
    * @version    2.6.1.2
    */
    FUNCTION get_reports_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN professional.id_professional%TYPE,
        i_inst                 IN institution.id_institution%TYPE,
        i_soft                 IN software.id_software%TYPE,
        i_rep_profile_template IN table_number,
        i_flg_area_report      IN rep_profile_template_det.flg_area_report%TYPE,
        o_reports              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Call  CURSOR O_REPORTS';
        IF NOT pk_print_tool.get_reports_list(i_lang                 => i_lang,
                                              i_prof                 => profissional(id          => i_prof,
                                                                                     institution => i_inst,
                                                                                     software    => i_soft),
                                              i_rep_profile_template => i_rep_profile_template,
                                              i_flg_area_report      => i_flg_area_report,
                                              o_reports              => o_reports,
                                              o_error                => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_types.open_my_cursor(i_cursor => o_reports);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_types.open_my_cursor(i_cursor => o_reports);
            RETURN FALSE;
    END get_reports_list;

    FUNCTION convert_tbl_to_cursor
    (
        i_lang                IN language.id_language%TYPE,
        i_flg_report_type_tbl IN table_varchar,
        i_report_name_tbl     IN table_varchar,
        i_report_id_tbl       IN table_varchar,
        i_report_desc_tbl     IN table_varchar
    ) RETURN pk_types.cursor_type IS
    
        l_cur_out pk_types.cursor_type;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Convert table to cursor';
        OPEN l_cur_out FOR
            SELECT /*+ opt_estimate(table a rows=1) opt_estimate(table b rows=2) opt_estimate(table c rows=3) opt_estimate(table d rows=4) */
             decode(a.column_value, '<NULL>', NULL, a.column_value) AS flg_report_type,
             decode(b.column_value, '<NULL>', NULL, b.column_value) AS cm_report_name,
             decode(c.column_value, '<NULL>', NULL, c.column_value) AS cm_report_id,
             decode(d.column_value, '<NULL>', NULL, d.column_value) AS desc_message
              FROM (SELECT rownum rown, column_value
                      FROM TABLE(i_flg_report_type_tbl)) a
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(i_report_name_tbl)) b
                ON a.rown = b.rown
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(i_report_id_tbl)) c
                ON a.rown = c.rown
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(i_report_desc_tbl)) d
                ON a.rown = d.rown
             GROUP BY a.column_value, b.column_value, c.column_value, d.column_value
             ORDER BY d.column_value;
    
        RETURN l_cur_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CONVERT_TBL_TO_CURSOR',
                                              l_error);
            pk_types.open_my_cursor(l_cur_out);
            RETURN l_cur_out;
    END convert_tbl_to_cursor;

    FUNCTION get_admission_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    
        l_adm_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_adm_date_str VARCHAR2(4000);
    
    BEGIN
        IF NOT pk_hea_prv_epis.get_admission_date_report(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_episode   => i_id_episode,
                                                         i_id_schedule  => i_id_schedule,
                                                         o_adm_date     => l_adm_date,
                                                         o_adm_date_str => l_adm_date_str)
        THEN
            l_adm_date := NULL;
        END IF;
    
        IF l_adm_date IS NOT NULL
        THEN
            RETURN pk_date_utils.dt_hour_chr_short_tsz(i_lang, l_adm_date, i_prof);
        ELSE
            RETURN '---';
        END IF;
    
    END get_admission_date;

    FUNCTION get_triage_end_date
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_dt_end_tstz epis_triage.dt_end_tstz%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Fetch dt_end_tstz from epis_triage';
        SELECT dt_end_tstz
          INTO l_dt_end_tstz
          FROM (SELECT et.dt_end_tstz, rank() over(ORDER BY et.dt_end_tstz DESC) rnk
                  FROM epis_triage et
                 WHERE et.dt_end_tstz IS NOT NULL
                   AND et.id_episode = i_episode)
         WHERE rnk = 1;
    
        RETURN l_dt_end_tstz;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TRIAGE_END_DATE',
                                              l_error);
            RETURN NULL;
    END get_triage_end_date;

    FUNCTION get_silhouette
    (
        i_lang       IN language.id_language%TYPE,
        i_silhouette IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Get silhouette';
        RETURN g_silhouette_lst(i_silhouette);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SILHOUETTE',
                                              l_error);
            RETURN NULL;
    END get_silhouette;

    FUNCTION get_epis_type_by_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN NUMBER IS
    
        l_epis_type epis_type_soft_inst.id_epis_type%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Fetch id_epis_type from epis_type_soft_inst';
        SELECT id_epis_type
          INTO l_epis_type
          FROM (SELECT etsi.id_epis_type, rank() over(ORDER BY etsi.id_institution DESC, etsi.id_software DESC) rn
                  FROM epis_type_soft_inst etsi
                 WHERE etsi.id_software IN (i_software, 0)
                   AND etsi.id_institution IN (i_institution, 0))
         WHERE rn = 1;
    
        RETURN l_epis_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_TYPE_BY_INST_SOFT',
                                              l_error);
            RETURN NULL;
    END get_epis_type_by_inst_soft;

    PROCEDURE disable_flg_upd_ui(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE) IS
    
    BEGIN
    
        UPDATE crisis_machine cm
           SET cm.flg_upd_ui = pk_alert_constant.g_no
         WHERE cm.id_crisis_machine = i_crisis_machine;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(1,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'DISABLE_FLG_UPD_UI',
                                                  l_error);
            END;
    END disable_flg_upd_ui;

    PROCEDURE set_crisis_log
    (
        i_crisis_log     IN VARCHAR2,
        i_crisis_machine IN NUMBER,
        i_log            IN VARCHAR2
    ) IS
    
    BEGIN
        pk_alertlog.log_debug(text            => i_log,
                              object_name     => g_package_name,
                              sub_object_name => i_crisis_machine || '|' || i_crisis_log,
                              owner           => g_package_owner);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(2,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_CRISIS_LOG',
                                                  l_error);
            END;
    END set_crisis_log;

    /** 
    * get lock for a specific control name
    *
    * @param      i_control_name          control name
    * @param      i_server_name           server name    
    * @param      i_minimum_interval      minimum interval in minutes between last execution to get lock
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */
    FUNCTION control_get_lock
    (
        i_control_name     IN crisis_control.control_name%TYPE,
        i_server_name      IN crisis_control.server_name%TYPE,
        i_minimum_interval IN NUMBER,
        o_error            OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_crisis_control crisis_control%ROWTYPE;
    
        l_tolerance NUMBER := (2 / 60); --2 seconds tolerance
        no_lock     EXCEPTION;
        PRAGMA EXCEPTION_INIT(no_lock, -00054);
    
    BEGIN
    
        g_error := 'CONTROL_GET_LOCK';
        BEGIN
            SELECT *
              INTO l_crisis_control
              FROM crisis_control
             WHERE control_name = i_control_name
               FOR UPDATE NOWAIT;
        
            IF i_minimum_interval IS NOT NULL
               AND l_crisis_control.begin_execution_time IS NOT NULL
               AND (((SYSDATE - CAST(l_crisis_control.begin_execution_time AS DATE)) * 60 * 24) <
               (i_minimum_interval - l_tolerance))
            THEN
                o_error := 'Minimum interval between executions wasn''t reached';
                RETURN FALSE;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                INSERT INTO crisis_control
                    (control_name)
                VALUES
                    (i_control_name);
            
                COMMIT;
            
                SELECT *
                  INTO l_crisis_control
                  FROM crisis_control
                 WHERE control_name = i_control_name
                   FOR UPDATE NOWAIT;
        END;
    
        UPDATE crisis_control
           SET begin_execution_time = SYSDATE, server_name = i_server_name
         WHERE control_name = i_control_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_lock THEN
            o_error := 'Another job already has the lock';
            RETURN FALSE;
        WHEN OTHERS THEN
            o_error := 'Couldn''t get lock';
            RETURN FALSE;
    END control_get_lock;

    /** 
    * release lock for a specific control name
    *
    * @param      i_control_name          control name
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */
    FUNCTION control_release_lock
    (
        i_control_name IN crisis_control.control_name%TYPE,
        o_error        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        UPDATE crisis_control
           SET end_execution_time = SYSDATE
         WHERE control_name = i_control_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CONTROL_RELEASE_LOCK',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'CONTROL_RELEASE_LOCK' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END control_release_lock;

    /** 
    * Update status of crisis_epis records which are in error 
    * or in_progress too much time
    *
    * @param      i_lang             language
    * @param      i_crisis_machine   crisis machine
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION update_status
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_retry_rep_generation_sc     sys_config.value%TYPE;
        l_retry_rep_generation        VARCHAR2(1);
        l_in_progress_maximum_time_sc sys_config.value%TYPE;
        l_in_progress_maximum_time    NUMBER := 60; --60 minutes by default
        l_institution                 institution.id_institution%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error       := 'RESET_IN_PROGRESS';
        l_institution := get_crisis_inst(i_crisis_machine);
    
        g_error                       := 'GET SYS_CONFIG CM_MAXIMUM_TIME_IN_PROGRESS';
        l_in_progress_maximum_time_sc := pk_sysconfig.get_config('CM_MAXIMUM_TIME_IN_PROGRESS', l_institution, 0);
    
        IF l_in_progress_maximum_time_sc IS NOT NULL
        THEN
            l_in_progress_maximum_time := to_number(l_in_progress_maximum_time_sc);
        END IF;
    
        FOR rec IN (SELECT ce.*
                      FROM crisis_epis ce
                     WHERE ce.flg_status IN (g_flg_status_error, g_flg_status_in_progress))
        LOOP
            BEGIN
                IF rec.flg_status = g_flg_status_error
                THEN
                    l_retry_rep_generation_sc := pk_sysconfig.get_config('CM_RETRY_REP_GENERATION',
                                                                         l_institution,
                                                                         rec.id_software);
                    l_retry_rep_generation    := nvl(l_retry_rep_generation_sc, pk_alert_constant.g_yes);
                
                    IF l_retry_rep_generation = pk_alert_constant.g_yes
                    THEN
                        UPDATE crisis_epis
                           SET flg_status = g_flg_status_retry
                         WHERE id_crisis_epis = rec.id_crisis_epis;
                    END IF;
                
                ELSIF rec.flg_status = g_flg_status_in_progress
                      AND (((SYSDATE - CAST(rec.update_time AS DATE)) * 60 * 24) > l_in_progress_maximum_time)
                THEN
                    UPDATE crisis_epis
                       SET flg_status = g_flg_status_waiting
                     WHERE id_crisis_epis = rec.id_crisis_epis;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_IN_PROGRESS',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'RESET_IN_PROGRESS' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END update_status;

    /** 
    * get next crisis_epis to process and change flg_status to "in process"
    *
    * @param      i_crisis_machine   crisis machine
    * @param      i_date             date
    * @param      i_token            varchar    
    * @param      o_next_id          next id_crisis_epis to process
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_next_crisis_epis
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_date           IN TIMESTAMP WITH TIME ZONE,
        i_token          IN crisis_epis.token%TYPE,
        o_next_id        OUT crisis_epis.id_crisis_epis%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_cnt_waiting NUMBER;
        l_crisis_epis crisis_epis%ROWTYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error   := 'GET_NEXT_CRISIS_EPIS';
        o_next_id := NULL;
    
        --between the min() and the for update, other job could get the lock
        --in this case try again
        WHILE TRUE
        LOOP
            SELECT COUNT(*)
              INTO l_cnt_waiting
              FROM crisis_epis
             WHERE id_crisis_machine = i_crisis_machine
               AND flg_status = g_flg_status_waiting;
        
            IF l_cnt_waiting > 0
            THEN
            
                BEGIN
                    SELECT *
                      INTO l_crisis_epis
                      FROM crisis_epis
                     WHERE flg_status = g_flg_status_waiting -- to ensure it was not altered after the min()
                       AND id_crisis_epis = (SELECT MIN(ce.id_crisis_epis)
                                               FROM crisis_epis ce
                                              WHERE ce.id_crisis_machine = i_crisis_machine
                                                AND ce.flg_status = g_flg_status_waiting)
                       FOR UPDATE;
                
                    UPDATE crisis_epis
                       SET flg_status = g_flg_status_in_progress, date_last_generated_tstz = i_date, token = i_token
                     WHERE id_crisis_epis = l_crisis_epis.id_crisis_epis;
                
                    o_next_id := l_crisis_epis.id_crisis_epis;
                
                    EXIT;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --other job already got the lock
                        NULL;
                END;
            ELSE
                EXIT;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CRISIS_EPIS',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_NEXT_CRISIS_EPIS' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END get_next_crisis_epis;

    /** 
    * returns a crisis_epis record
    *
    * @param      i_id_crisis_epis   id_crisis_epis
    * @param      o_crisis_epis      crisis_epis_record
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_crisis_epis
    (
        i_id_crisis_epis IN crisis_epis.id_crisis_epis%TYPE,
        o_crisis_epis    OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET_CRISIS_EPIS';
        OPEN o_crisis_epis FOR
            SELECT ce.id_crisis_epis,
                   ce.flg_report_type,
                   ce.id_report,
                   ce.episode_type ep,
                   ce.id_episode,
                   ce.id_patient,
                   ce.id_software,
                   ce.cm_report_path path_crisis_machine,
                   decode(ce.flg_show_demographic_data, pk_alert_constant.g_yes, 1, pk_alert_constant.g_no, 0, 0) flg_show_demographic_data,
                   ce.id_schedule
              FROM crisis_epis ce
             WHERE ce.id_crisis_epis = i_id_crisis_epis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CRISIS_EPIS',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_CRISIS_EPIS' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END get_crisis_epis;

    /** 
    * returns a list of crisis_epis records which have reports
    *
    * @param      i_id_crisis_machine   id_crisis_machine
    * @param      o_crisis_epis         crisis_epis_record
    * @param      o_error               error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_reports_to_update
    (
        i_id_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_crisis_epis       OUT pk_types.cursor_type,
        o_error             OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET_CRISIS_EPIS_WITH_REPORTS';
        OPEN o_crisis_epis FOR
            SELECT ce.cm_report_path, ce.cm_report_name
              FROM crisis_epis ce
             WHERE ce.id_crisis_machine = i_id_crisis_machine
               AND ce.cm_report_name IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CRISIS_EPIS_WITH_REPORTS',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_CRISIS_EPIS_WITH_REPORTS' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END get_reports_to_update;

    /** 
    * returns the number of crisis_epis with status=waiting for a id_crisis_machine
    *
    * @param      i_crisis_machine   crisis machine  
    * @param      o_count          
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_waiting_count
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_count          OUT NUMBER,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET_WAITING_COUNT';
        SELECT COUNT(*)
          INTO o_count
          FROM crisis_epis
         WHERE id_crisis_machine = i_crisis_machine
           AND flg_status = g_flg_status_waiting;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WAITING_COUNT',
                                              l_error);
        
            o_error := pk_message.get_message(2, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                       'GET_WAITING_COUNT' || '/ ' || g_error || ' / ' || l_error.err_desc;
        
            RETURN FALSE;
    END get_waiting_count;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i); -- Initialize log
    pk_alertlog.who_am_i(g_package_owner, g_package_name);

    --g_win_copy_dir      := pk_sysconfig.get_config('WIN_COPY_DIR', 0, 0);
    g_cm_dir_gen   := pk_sysconfig.get_config('CM_DIR_GEN', 0, 0);
    g_cm_dir_upd   := pk_sysconfig.get_config('CM_DIR_UPD', 0, 0);
    g_cm_dir_stage := pk_sysconfig.get_config('CM_DIR_STAGE', 0, 0);
    --g_crontab_file_name := pk_sysconfig.get_config('CRONTAB_FILE_NAME', 0, 0);
    g_cm_job_update_class      := pk_sysconfig.get_config('CM_JOB_UPDATE_CLASS', 0, 0);
    g_cm_job_generate_class    := pk_sysconfig.get_config('CM_JOB_GENERATE_CLASS', 0, 0);
    g_cm_job_generate_interval := pk_sysconfig.get_config('CM_JOB_GENERATE_INTERVAL', 0, 0);
    g_separator                := pk_sysconfig.get_config('SEPARATOR', 0, 0);
    g_cm_keys_path             := pk_sysconfig.get_config('CM_KEYS_PATH', 0, 0);
    g_cm_targetfolder          := pk_sysconfig.get_config('CM_TARGETFOLDER', 0, 0);
    g_tunnelremotehost         := pk_sysconfig.get_config('CM_TUNNELREMOTEHOST', 0, 0);
    g_rsync_server_user        := pk_sysconfig.get_config('CM_RSYNC_SERVER_USER', 0, 0);

    g_silhouette_lst('SilhouetteUndeterminedSex') := 'SilhouetteU';
    g_silhouette_lst('SilhouetteMale') := 'SilhouetteM';
    g_silhouette_lst('SilhouetteFemale') := 'SilhouetteF';
    g_silhouette_lst('SilhouetteMaleChild') := 'SilhouetteCM';
    g_silhouette_lst('SilhouetteFemaleChild') := 'SilhouetteCF';
    g_silhouette_lst('SilhouetteInfant') := 'SilhouetteB';

END pk_crisis_machine;
/
