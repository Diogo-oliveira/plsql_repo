CREATE OR REPLACE PACKAGE BODY pk_wl_aux AS

    k_package_owner VARCHAR2(0050 CHAR);
    k_package_name  VARCHAR2(0050 CHAR);

    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    --k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    k_pendente       CONSTANT VARCHAR2(0050 CHAR) := 'P';
    k_voice          CONSTANT VARCHAR2(0050 CHAR) := 'V';
    k_bip            CONSTANT VARCHAR2(0050 CHAR) := 'B';
    k_none           CONSTANT VARCHAR2(0050 CHAR) := 'N';
    k_wavfile_prefix CONSTANT VARCHAR2(0050 CHAR) := 'CALL_';
    k_wavfile_sufix  CONSTANT VARCHAR2(0050 CHAR) := '000.WAV';
    k_t_status       CONSTANT VARCHAR2(0050 CHAR) := 'T';

    k_wl_wav_bip_name  CONSTANT VARCHAR2(0050 CHAR) := 'WL_WAV_BIP_NAME';
    k_wl_titulo        CONSTANT VARCHAR2(0050 CHAR) := 'WL_TITULO';
    k_msg_hours_kiosk  CONSTANT VARCHAR2(0100 CHAR) := 'MSG_HOURS_KIOSK';
    k_tempo_espera_lim CONSTANT NUMBER := 120;
    /*
    k_wl_id_sonho     CONSTANT VARCHAR2(0050 CHAR) := 'WL_ID_SONHO';
    k_med_msg_01      CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_01';
    k_med_msg_02      CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_02';
    k_med_msg_tit_01 CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_TIT_01';
    k_med_msg_tit_02 CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_TIT_02';
    k_med_msg_tit_03 CONSTANT VARCHAR2(0050 CHAR) := 'MED_MSG_TIT_03';
    k_sp CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    */

    --*********************************************************
    FUNCTION get_id_machine_by_name(i_name IN VARCHAR2) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_wl_machine
          BULK COLLECT
          INTO tbl_id
          FROM wl_machine
         WHERE machine_name = i_name;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_machine_by_name;

    --*********************************************************
    FUNCTION get_wl_queue
    (
        i_prof          IN profissional,
        i_id_wl_machine IN NUMBER
    ) RETURN table_number IS
        tbl_queues table_number;
        --l_return   NUMBER;
    BEGIN
    
        SELECT DISTINCT wmpq.id_wl_queue
          BULK COLLECT
          INTO tbl_queues
          FROM wl_mach_prof_queue wmpq
         WHERE wmpq.id_professional = i_prof.id
           AND wmpq.id_wl_machine = i_id_wl_machine;
    
        RETURN tbl_queues;
    
    END get_wl_queue;

    --*************************************************
    FUNCTION priority_q_allocated(i_id_mach IN NUMBER) RETURN table_number IS
        tbl_id table_number;
    BEGIN
    
        select qm.id_wl_queue
          BULK COLLECT
          INTO tbl_id
        from wl_q_machine qm
          JOIN wl_machine m
            ON m.id_wl_machine = qm.id_wl_machine
          JOIN wl_queue q
            ON q.id_wl_queue = qm.id_wl_queue
        where qm.id_wl_machine = i_id_mach
           AND q.flg_type_queue = 'A'
           AND m.flg_mach_type = 'P';
    
        RETURN tbl_id;
    
    END priority_q_allocated;

    --********************************************************
    PROCEDURE ins_wl_q_machine
    (
        i_id_mach   IN NUMBER,
        i_id_queues IN table_number
    ) IS
    BEGIN
    
        FORALL i IN 1 .. i_id_queues.count
            INSERT INTO wl_q_machine
                (id_wl_machine, id_wl_queue)
            VALUES
                (i_id_mach, i_id_queues(i));
    
    END ins_wl_q_machine;

    --******************************************
    PROCEDURE del_wl_q_machine(i_id_mach IN NUMBER) IS
    BEGIN
    
        DELETE wl_q_machine
         WHERE id_wl_machine = i_id_mach;
    
    END del_wl_q_machine;

    PROCEDURE del_wl_q_machine(i_mach_name IN VARCHAR2) IS
        l_id_mach NUMBER;
    BEGIN
    
        l_id_mach := get_id_machine_by_name(i_name => i_mach_name);
        del_wl_q_machine(i_id_mach => l_id_mach);
    
    END del_wl_q_machine;

    PROCEDURE inicialize IS
    BEGIN
      -- Log initialization.
      pk_alertlog.who_am_i(k_package_owner, k_package_name);
      pk_alertlog.log_init(k_package_name);
    
    END inicialize;

    --*********************************************************
    /*
    FUNCTION get_queue_color(i_color IN VARCHAR2) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
        tbl_code_color table_varchar := table_varchar('WL_COLOR_QUEUE_BLUE',
                                                      'WL_COLOR_QUEUE_DARK_BLUE',
                                                      'WL_COLOR_QUEUE_DARK_YELLOW',
                                                      'WL_COLOR_QUEUE_GREEN',
                                                      'WL_COLOR_QUEUE_LIGHT_BLUE',
                                                      'WL_COLOR_QUEUE_LIGHT_GREEN',
                                                      'WL_COLOR_QUEUE_LIGHT_VIOLET',
                                                      'WL_COLOR_QUEUE_ORANGE',
                                                      'WL_COLOR_QUEUE_RED',
                                                      'WL_COLOR_QUEUE_VIOLET');
    
        tbl_ux_color table_varchar := table_varchar(pk_alert_constant.g_wr_col_blue,
                                                    pk_alert_constant.g_wr_col_drk_blue,
                                                    pk_alert_constant.g_wr_col_drk_yell,
                                                    pk_alert_constant.g_wr_col_gren,
                                                    pk_alert_constant.g_wr_col_lgh_blue,
                                                    pk_alert_constant.g_wr_col_lgh_gren,
                                                    pk_alert_constant.g_wr_col_lgh_vlt,
                                                    pk_alert_constant.g_wr_col_orange,
                                                    pk_alert_constant.g_wr_col_red,
                                                    pk_alert_constant.g_wr_col_violet);
    
    BEGIN
    
        l_return := i_color;
    
        <<lup_thru_code_colors>>
        FOR i IN 1 .. tbl_code_color.count
        LOOP
        
            IF i_color = tbl_code_color(i)
            THEN
                l_return := tbl_ux_color(i);
                EXIT lup_thru_code_colors;
            END IF;
        
        END LOOP lup_thru_code_colors;
    
        RETURN l_return;
    
    END get_queue_color;
    */

    --************************************************
    FUNCTION get_people_ahead
    (
        i_id_wl_queue IN NUMBER,
        i_prof        IN profissional
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
    
        l_return := get_avg_waiting_time(i_mode        => k_calc_total_patient,
                                         i_prof        => i_prof,
                                         i_id_wl_queue => i_id_wl_queue);
    
        RETURN l_return;
    
    END get_people_ahead;

    --***************************************************************************
    FUNCTION get_row_episode(i_id_episode IN NUMBER) RETURN episode%ROWTYPE IS
        xepis episode%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xepis
          FROM episode
         WHERE id_episode = i_id_episode;
    
        RETURN xepis;
    
    END get_row_episode;

    --***************************************************************************
    FUNCTION get_row_epis_info(i_id_episode IN NUMBER) RETURN epis_info%ROWTYPE IS
        xinfo epis_info%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xinfo
          FROM epis_info
         WHERE id_episode = i_id_episode;
    
        RETURN xinfo;
    
    END get_row_epis_info;

    --***************************************************************************
    FUNCTION get_row_visit(i_id_visit IN NUMBER) RETURN visit%ROWTYPE IS
        xvis visit%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xvis
          FROM visit
         WHERE id_visit = i_id_visit;
    
        RETURN xvis;
    
    END get_row_visit;

    --****************************************************************************
    FUNCTION get_wl_row_by_ticket
    (
        i_char_queue   IN VARCHAR2,
        i_number_queue IN NUMBER
    ) RETURN NUMBER IS
        tbl_wl   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_wl_waiting_line
          BULK COLLECT
          INTO tbl_wl
          FROM wl_waiting_line
         WHERE char_queue = i_char_queue
           AND number_queue = i_number_queue
         ORDER BY dt_begin_tstz DESC;
    
        IF tbl_wl.count > 0
        THEN
            l_return := tbl_wl(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_row_by_ticket;

    --**********************************************
    PROCEDURE ins_wl_waiting_line
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_char_queue        IN VARCHAR2,
        i_number_queue      IN NUMBER,
        i_id_wl_queue       IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER,
        i_id_wl_line_parent IN NUMBER
    ) IS
        l_rows table_varchar := table_varchar();
        l_error t_error_out;
    BEGIN
    
        ts_wl_waiting_line.ins(id_wl_waiting_line_in        => ts_wl_waiting_line.next_key,
                               char_queue_in                => i_char_queue,
                               number_queue_in              => i_number_queue,
                               id_wl_queue_in               => i_id_wl_queue,
                               id_episode_in                => i_id_episode,
                               id_patient_in                => i_id_patient,
                               id_wl_waiting_line_parent_in => i_id_wl_line_parent,
                               flg_wl_status_in             => pk_alert_constant.g_wr_wl_status_e,
                               dt_begin_tstz_in             => current_timestamp,
                               rows_out                     => l_rows);
    
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, l_error);
    
    END ins_wl_waiting_line;

    --*********************************************
    FUNCTION get_med_queue
    (
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2
    ) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT q.id_wl_queue
          BULK COLLECT
          INTO tbl_id
          FROM wl_queue q
          JOIN wl_machine m
            ON m.id_wl_queue_group = q.id_wl_queue_group
         WHERE m.machine_name = i_mach_name
           AND q.flg_type_queue = pk_alert_constant.g_wr_wq_type_d;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        ELSE
            -- fallback sql: id fisrst is not successfull because of bad config
            -- do this one
            SELECT wq.id_wl_queue
              BULK COLLECT
              INTO tbl_id
              FROM software_dept sd
              JOIN dept d
                ON d.id_dept = sd.id_dept
              JOIN department dp
                ON dp.id_dept = d.id_dept
              JOIN room r
                ON r.id_department = dp.id_department
              JOIN prof_room pr
                ON pr.id_room = r.id_room
              JOIN wl_queue wq
                ON wq.id_department = dp.id_department
             WHERE sd.id_software = i_prof.software
               AND pr.id_professional = i_prof.id
               AND dp.flg_available = k_yes
               AND r.flg_available = k_yes
               AND r.flg_wl = k_yes
               AND pr.flg_pref = k_yes
               AND dp.id_institution = i_prof.institution
               AND wq.flg_type_queue = pk_alert_constant.g_wr_wq_type_d;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        IF l_return IS NULL
        THEN
            RAISE no_data_found;
        END IF;
    
        RETURN l_return;
    
    END get_med_queue;

    --************************************************************
    PROCEDURE get_next_ticket
    (
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER
    ) IS
    
    BEGIN
    
        UPDATE wl_queue
           SET num_queue =
               (num_queue + 1)
         WHERE id_wl_queue = i_id_wl_queue
        RETURNING(num_queue), char_queue INTO o_number, o_char;
    
    END get_next_ticket;

    --*********************************************
    PROCEDURE get_ticket_info
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_code              OUT VARCHAR2
    ) IS
    
        l_codification_type VARCHAR2(4000);
        l_printer           VARCHAR2(4000);
        l_code              VARCHAR2(4000);
    
        t_data t_tbl_barcode_type_cfg := t_tbl_barcode_type_cfg();
        k_code CONSTANT VARCHAR2(0200 CHAR) := 'BARCODE_WL_TICKET_NUMBER';
    
    BEGIN
    
        t_data := pk_barcode.get_barcode_cfg_base(i_lang, i_prof, k_code);
    
        IF t_data.count > 0
        THEN
            l_codification_type := t_data(1).cfg_type;
            l_printer           := t_data(1).cfg_printer;
            l_code              := t_data(1).cfg_value;
        END IF;
    
        o_codification_type := l_codification_type;
        o_printer           := l_printer;
        o_code              := l_code;
    
    END get_ticket_info;

    --*********************************************************
    PROCEDURE update_adt
    (
        i_id_episode    IN NUMBER,
        i_ticket_number IN VARCHAR2
    ) IS
        tbl_id table_number;
    BEGIN
    
        SELECT id_admission_adt
          BULK COLLECT
          INTO tbl_id
          FROM admission_adt aa
          JOIN episode_adt ea
            ON aa.id_episode_adt = ea.id_episode_adt
         WHERE ea.id_episode = i_id_episode;
    
        IF tbl_id.count > 0
        THEN
            IF i_ticket_number IS NOT NULL
            THEN
                UPDATE admission_adt
                   SET ticket_number = i_ticket_number
                 WHERE id_admission_adt = tbl_id(1);
            END IF;
        END IF;
    
    END update_adt;

    --************************************
    FUNCTION get_dept_of_prof(i_prof IN profissional) RETURN table_number IS
        tbl_dept table_number;
    BEGIN
    
        SELECT DISTINCT dp.id_dept
          BULK COLLECT
          INTO tbl_dept
          FROM prof_room pr
          JOIN room r
            ON r.id_room = pr.id_room
          JOIN department d
            ON d.id_department = r.id_department
          JOIN dept dp
            ON dp.id_dept = d.id_dept
          JOIN software_dept sd
            ON sd.id_dept = dp.id_dept
         WHERE d.id_institution = i_prof.institution
           AND sd.id_software = i_prof.software
           AND pr.id_professional = i_prof.id
           AND r.flg_wl = k_yes;
    
        RETURN tbl_dept;
    
    END get_dept_of_prof;

    --******************************
    FUNCTION get_id_software RETURN NUMBER IS
        xid_software NUMBER;
    BEGIN
    
        SELECT id_software
          INTO xid_software
          FROM software
         WHERE intern_name = 'WL';
    
        RETURN xid_software;
    
    END get_id_software;

    --**************************************
    FUNCTION count_kiosk_department
    (
        i_prof         IN profissional,
        i_machine_name IN VARCHAR2
    ) RETURN NUMBER IS
        l_count NUMBER;
        k_mach_type_kiosk CONSTANT VARCHAR2(0001 CHAR) := 'K';
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM wl_machine m
          JOIN room r
            ON r.id_room = m.id_room
          JOIN department d
            ON d.id_department = r.id_department
          JOIN room r2
            ON r2.id_department = r.id_department
          JOIN wl_machine m2
            ON m2.id_room = r2.id_room
         WHERE m.machine_name = upper(i_machine_name)
           AND m2.flg_mach_type = k_mach_type_kiosk
           AND d.id_institution = i_prof.institution;
    
        RETURN l_count;
    
    END count_kiosk_department;

    --***************************************
    FUNCTION get_max_tickets_shown(i_id_machine IN NUMBER) RETURN NUMBER IS
        l_return NUMBER := 3;
        tbl_num  table_number;
    BEGIN
    
        SELECT max_ticket_shown
          BULK COLLECT
          INTO tbl_num
          FROM wl_machine
         WHERE id_wl_machine = i_id_machine;
    
        IF tbl_num.count > 0
        THEN
            l_return := coalesce(tbl_num(1), l_return);
        END IF;
    
        RETURN l_return;
    
    END get_max_tickets_shown;

    --*********************************************
    FUNCTION get_dept_from_machine(i_id_machine IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT d. id_department
          BULK COLLECT
          INTO tbl_id
          FROM department d
          JOIN room r
            ON r.id_department = d.id_department
          JOIN wl_machine m
            ON m.id_room = r.id_room
         WHERE m.id_wl_machine = i_id_machine;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_dept_from_machine;

    ---***********************************
    FUNCTION get_wl_line_row_1(i_id_queues IN table_number) RETURN wl_waiting_line%ROWTYPE IS
        l_row wl_waiting_line%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO l_row
          FROM (SELECT w.*
                  FROM wl_waiting_line w
                 INNER JOIN wl_queue wq
                    ON wq.id_wl_queue = w.id_wl_queue
                 WHERE w.id_wl_queue IN (SELECT *
                                           FROM TABLE(i_id_queues))
                   AND w.flg_wl_status = pk_alert_constant.g_wr_wl_status_e
                   AND trunc(w.dt_begin_tstz) = trunc(w.dt_begin_tstz)
                 ORDER BY wq.flg_priority DESC, w.dt_begin_tstz ASC)
         WHERE rownum = 1;
    
        RETURN l_row;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_row := NULL;
            RETURN l_row;
    END get_wl_line_row_1;

    ---***********************************
    FUNCTION get_wl_line_row_2(i_id_queues IN table_number) RETURN wl_waiting_line%ROWTYPE IS
        l_row wl_waiting_line%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO l_row
          FROM (SELECT w.*
                  FROM wl_waiting_line w
                 WHERE w.id_wl_queue IN (SELECT *
                                           FROM TABLE(i_id_queues))
                   AND w.flg_wl_status = pk_alert_constant.g_wr_wl_status_e
                   AND trunc(w.dt_begin_tstz) = trunc(w.dt_begin_tstz)
                 ORDER BY w.dt_begin_tstz ASC)
         WHERE rownum = 1;
    
        RETURN l_row;
    
    EXCEPTION
        WHEN no_data_found THEN
            l_row := NULL;
            RETURN l_row;
    END get_wl_line_row_2;

    --**************************************
    FUNCTION get_wl_line_row
    (
        i_flg_prior IN NUMBER,
        i_id_queues IN table_number
    ) RETURN wl_waiting_line%ROWTYPE IS
        l_row wl_waiting_line%ROWTYPE;
    BEGIN
    
        IF i_flg_prior = 1
        THEN
            l_row := get_wl_line_row_1(i_id_queues);
        ELSE
            l_row := get_wl_line_row_2(i_id_queues);
        END IF;
    
        RETURN l_row;
    
    END get_wl_line_row;

    --*****************************************
    PROCEDURE set_wl_line_executed
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_wl_waiting_line IN NUMBER
    ) IS
        l_rows  table_varchar;
        o_error t_error_out;
    BEGIN
    
        ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_id_wl_waiting_line,
                               dt_call_tstz_in       => current_timestamp,
                               dt_call_tstz_nin      => FALSE,
                               flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                               flg_wl_status_nin     => FALSE,
                               id_prof_call_in       => i_prof.id,
                               rows_out              => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
    
    END set_wl_line_executed;

    --*************************************************
    FUNCTION get_wl_by_episode(i_id_episode IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT wl.id_wl_waiting_line
          BULK COLLECT
          INTO tbl_id
          FROM wl_waiting_line wl
         WHERE wl.id_episode = i_id_episode
        -- can have only one row if workflow starts on adm
        ---AND wl.id_wl_waiting_line_parent IS NOT NULL
         ORDER BY wl.dt_begin_tstz DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_by_episode;

    --***********************************************
    FUNCTION get_mach_by_id_wl
    (
        i_prof  IN profissional,
        i_id_wl IN NUMBER
    ) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT wm.id_wl_machine
          BULK COLLECT
          INTO tbl_id
          FROM prof_room pr
          JOIN wl_machine wm
            ON wm.id_room = pr.id_room
          JOIN room r
            ON r.id_room = wm.id_room
          JOIN wl_queue wq
            ON wq.id_department = r.id_department
           AND wq.id_wl_queue_group = wm.id_wl_queue_group
          JOIN wl_waiting_line wwl
            ON wwl.id_wl_queue = wq.id_wl_queue
         WHERE pr.id_professional = i_prof.id
           AND pr.flg_pref = k_yes
           AND wwl.id_wl_waiting_line = i_id_wl;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_mach_by_id_wl;

    --***********************************************
    FUNCTION get_mach_by_room(i_id_room IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        IF i_id_room IS NOT NULL
        THEN
        
            -- !! BWARE 2 machines in same room
            SELECT m.id_wl_machine
              BULK COLLECT
              INTO tbl_id
              FROM wl_machine m
             WHERE m.id_room = i_id_room
               AND m.flg_mach_type = 'P';
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_mach_by_room;

    PROCEDURE get_pat_info
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_wl      IN NUMBER,
        o_nome_pat   OUT VARCHAR2,
        o_sexo_pat   OUT VARCHAR2,
        o_flg_status OUT VARCHAR2
    ) IS
    BEGIN
        SELECT pk_adt.get_patient_name_to_sort(i_lang, i_prof, pa.id_patient, pk_adt.g_false),
               pk_patient.get_gender(i_lang, pa.gender),
               nvl(wl.flg_wl_status, pk_alert_constant.g_wr_wl_status_e)
          INTO o_nome_pat, o_sexo_pat, o_flg_status
          FROM wl_waiting_line wl
          JOIN episode e
            ON e.id_episode = wl.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
          JOIN patient pa
            ON pa.id_patient = v.id_patient
         WHERE wl.id_wl_waiting_line = i_id_wl;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_nome_pat   := NULL;
            o_sexo_pat   := NULL;
            o_flg_status := NULL;
        
    END get_pat_info;

    --*********************************************
    FUNCTION get_ticket_from_wl(i_id_wl IN NUMBER) RETURN VARCHAR2 IS
        tbl_nome table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT x.char_queue || x.number_queue
          BULK COLLECT
          INTO tbl_nome
          FROM wl_waiting_line x
         WHERE x.id_wl_waiting_line = i_id_wl;
    
        IF tbl_nome.count > 0
        THEN
            l_return := tbl_nome(1);
        END IF;
    
        RETURN l_return;
    
    END get_ticket_from_wl;

    --*******************************************
    PROCEDURE upd_wl_waiting_line(i_id_wl IN NUMBER) IS
        l_rows  table_varchar := table_varchar();
        --l_error t_error_out;
    BEGIN
    
        ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_id_wl,
                               dt_call_tstz_in       => current_timestamp,
                               dt_call_tstz_nin      => FALSE,
                               flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                               flg_wl_status_nin     => FALSE,
                               rows_out              => l_rows);
    
        --t_data_gov_mnt.process_update(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, l_error);
    
    END upd_wl_waiting_line;

    --*****************************************
    PROCEDURE ins_wl_call_queue
    (
        i_prof          IN profissional,
        i_message       IN VARCHAR2,
        i_machine       IN VARCHAR2,
        i_machine_dest  IN VARCHAR2,
        i_id_wl         IN NUMBER,
        i_flg_audio     IN VARCHAR2,
        i_beep          IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        o_id_call_queue OUT NUMBER,
        io_sound_file   IN OUT VARCHAR2
    ) IS
        l_row wl_call_queue%ROWTYPE;
    BEGIN
    
        l_row.id_call_queue      := seq_wl_call_queue.nextval;
        l_row.message            := i_message;
        l_row.id_wl_machine      := i_machine;
        l_row.id_wl_machine_dest := i_machine_dest;
        l_row.id_wl_waiting_line := i_id_wl;
        l_row.flg_status         := k_pendente;
        l_row.id_professional    := i_prof.id;
        --l_row.flg_type           := 'M';
        l_row.flg_type := i_flg_type;
    
        CASE i_flg_audio
            WHEN k_voice THEN
                IF io_sound_file IS NOT NULL
                THEN
                    l_row.sound_file := io_sound_file;
                ELSE
                    l_row.sound_file := k_wavfile_prefix || l_row.id_call_queue || k_wavfile_sufix;
                END IF;
                l_row.dt_gen_sound_file_tstz := NULL;
            
            WHEN k_bip THEN
                l_row.sound_file             := i_beep;
                l_row.dt_gen_sound_file_tstz := current_timestamp;
            
            WHEN k_none THEN
                l_row.sound_file             := NULL;
                l_row.dt_gen_sound_file_tstz := current_timestamp;
            
            ELSE
                l_row.sound_file             := NULL;
                l_row.dt_gen_sound_file_tstz := NULL;
        END CASE;
    
        INSERT INTO wl_call_queue
            (id_call_queue,
             message,
             id_wl_machine,
             id_wl_machine_dest,
             id_wl_waiting_line,
             flg_status,
             sound_file,
             id_professional,
             dt_gen_sound_file_tstz,
             flg_type)
        VALUES
            (l_row.id_call_queue,
             l_row.message,
             l_row.id_wl_machine,
             l_row.id_wl_machine_dest,
             l_row.id_wl_waiting_line,
             l_row.flg_status,
             l_row.sound_file,
             l_row.id_professional,
             l_row.dt_gen_sound_file_tstz,
             l_row.flg_type);
    
        o_id_call_queue := l_row.id_call_queue;
        io_sound_file   := l_row.sound_file;
    
    END ins_wl_call_queue;

    FUNCTION format
    (
        i_msg    IN VARCHAR2,
        i_params IN table_varchar
    ) RETURN VARCHAR2 IS
        l_msg VARCHAR2(4000);
    BEGIN
    
        l_msg := i_msg;
        FOR i IN 1 .. i_params.count
        LOOP
            l_msg := REPLACE(l_msg, '@' || i, i_params(i));
        END LOOP;
    
        RETURN l_msg;
    
    END format;

    --***************************************************************************
    FUNCTION get_prof_default_language(i_id_prof IN profissional) RETURN NUMBER IS
        tbl_lang table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT pp.id_language
          BULK COLLECT
          INTO tbl_lang
          FROM prof_preferences pp
         WHERE pp.id_professional = i_id_prof.id
           AND pp.id_institution = i_id_prof.institution
           AND rownum = 1;
    
        IF tbl_lang.count > 0
        THEN
            l_return := tbl_lang(1);
        ELSE
            l_return := 0;
        END IF;
    
        RETURN l_return;
    
    END get_prof_default_language;

    --********************************************************
    FUNCTION get_lang
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_lang NUMBER;
    BEGIN
    
        IF i_lang IS NOT NULL
           OR i_lang != 0
        THEN
            l_lang := i_lang;
        ELSE
            l_lang := pk_wl_aux.get_prof_default_language(i_prof);
        END IF;
    
        RETURN l_lang;
    
    END get_lang;

    --*************************************************************
    FUNCTION get_room_of_mach(i_id_machine IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id_room
          BULK COLLECT
          INTO tbl_id
          FROM wl_machine
         WHERE id_wl_machine = i_id_machine;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_room_of_mach;

    --************************************
    FUNCTION get_institution(i_id_department IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT d.id_institution
          BULK COLLECT
          INTO tbl_id
          FROM department d
         WHERE d.id_department = i_id_department;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_institution;

    --***************************************************
    FUNCTION get_inst_from_mach(i_id_machine IN NUMBER) RETURN NUMBER IS
        l_return        NUMBER := 0;
        --l_id_room       NUMBER;
        --l_id_department NUMBER;
        --
        tbl_id table_number;
    BEGIN
    
        IF i_id_machine IS NOT NULL
        THEN
        
            SELECT qg.id_institution
              BULK COLLECT
              INTO tbl_id
              FROM wl_machine m
              JOIN wl_queue_group qg
                ON qg.id_wl_queue_group = m.id_wl_queue_group
             WHERE m.id_wl_machine = i_id_machine;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_inst_from_mach;

    FUNCTION get_inst_from_queue(i_id_wl_queue IN NUMBER) RETURN NUMBER IS
        l_return NUMBER := 0;
        --l_id_room       NUMBER;
        --l_id_department NUMBER;
        --
        tbl_id table_number;
    BEGIN
            
        IF i_id_wl_queue IS NOT NULL
        THEN
            
            SELECT qg.id_institution
              BULK COLLECT
              INTO tbl_id
              FROM wl_queue m
              JOIN wl_queue_group qg
                ON qg.id_wl_queue_group = m.id_wl_queue_group
             WHERE m.id_wl_queue = i_id_wl_queue;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_inst_from_queue;

    --********************************************
    FUNCTION get_pat_by_episode(i_id_episode IN NUMBER) RETURN NUMBER IS
    
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
        
        SELECT v.id_patient
          BULK COLLECT
          INTO tbl_id
          FROM episode e
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE e.id_episode = i_id_episode;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        END IF;
    
        RETURN l_return;
    
    END get_pat_by_episode;

    --******************************************************
    FUNCTION get_color(i_id_queue IN NUMBER) RETURN VARCHAR2 IS
        tbl_color table_varchar;
        l_return  VARCHAR2(0100 CHAR);
    BEGIN
    
        SELECT q.color
          BULK COLLECT
          INTO tbl_color
          FROM wl_queue q
         WHERE q.id_wl_queue = i_id_queue;
    
        IF tbl_color.count > 0
        THEN
            l_return := tbl_color(1);
        END IF;
    
        RETURN l_return;
    
    END get_color;

    --****************************
    FUNCTION get_desc_room
    (
        i_lang    IN NUMBER,
        i_machine IN VARCHAR2
    ) RETURN VARCHAR2 IS
        tbl_name table_varchar;
        tbl_desc table_varchar;
        l_name   VARCHAR2(4000);
    BEGIN
    
        SELECT r.code_room, r.desc_room
          BULK COLLECT
          INTO tbl_name, tbl_desc
          FROM wl_machine m
          JOIN room r
            ON r.id_room = m.id_room
         WHERE m.id_wl_machine = i_machine;
    
        IF tbl_name.count > 0
        THEN
            l_name := pk_translation.get_translation(i_lang, tbl_name(1));
        
            IF l_name IS NULL
            THEN
                l_name := tbl_desc(1);
            END IF;
        
        END IF;
    
        RETURN l_name;
    
    END get_desc_room;

    --**********************************
    FUNCTION get_flg_audio(i_id_mach IN NUMBER) RETURN VARCHAR2 IS
        tbl_flg  table_varchar;
        l_return VARCHAR2(0100 CHAR);
    BEGIN
    
        SELECT flg_audio_active
          BULK COLLECT
          INTO tbl_flg
          FROM wl_machine
         WHERE id_wl_machine = i_id_mach;
    
        IF tbl_flg.count > 0
        THEN
            l_return := tbl_flg(1);
        END IF;
    
        RETURN l_return;
    
    END get_flg_audio;

    --******************************************
    FUNCTION get_waiting_line_row(i_id_wl IN NUMBER) RETURN wl_waiting_line%ROWTYPE IS
        xrow wl_waiting_line%ROWTYPE;
    BEGIN
    
        SELECT w.*
          INTO xrow
          FROM wl_waiting_line w
         WHERE id_wl_waiting_line = i_id_wl;
    
        RETURN xrow;
    
    END get_waiting_line_row;

    --********************************************
    FUNCTION get_message_desc_machine
    (
        i_lang       IN NUMBER,
        i_id_machine IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return  VARCHAR2(4000);
        l_code    VARCHAR2(4000);
        l_id_room NUMBER;
    
    BEGIN
    
        SELECT mac.cod_desc_machine_visual, mac.id_room
          INTO l_code, l_id_room
          FROM wl_machine mac
         WHERE id_wl_machine = i_id_machine;
    
        l_return := get_desc_room(i_lang, i_id_machine);
    
            IF l_return IS NULL
            THEN
            l_return := pk_translation.get_translation(i_lang, l_code);
        END IF;
    
        RETURN l_return;
    
    END get_message_desc_machine;

    --****************************************
    FUNCTION get_url_photo
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        IF i_prof.id != 0
        THEN
            l_return := pk_patphoto.get_pat_photo(i_lang, i_prof, i_id_patient, NULL, NULL);
        ELSE
            l_return := pk_wlpatient.get_pat_pub_foto(i_id_patient, i_prof);
        END IF;
    
        RETURN l_return;
    
    END get_url_photo;

    --*************************************
    FUNCTION get_tit_pat_visual
    (
        i_lang       IN NUMBER,
        i_tit_mens   IN NUMBER,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_gender VARCHAR2(0100 CHAR);
        l_code   VARCHAR2(0200 CHAR);
    BEGIN
    
        IF i_tit_mens = 1
        THEN
            l_gender := get_pat_gender(i_id_patient);
        
            IF l_gender = 'M'
            THEN
                l_code := 'MED_MSG_TIT_01';
            ELSE
                l_code := 'MED_MSG_TIT_02';
            END IF;
        
            l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code);
        
        END IF;
    
        RETURN l_return;
    
    END get_tit_pat_visual;

    --**********************************
    FUNCTION get_wl_waiting_line
    (
        i_char_num      IN VARCHAR2,
        i_ticket_number IN NUMBER
    ) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_wl_waiting_line
          BULK COLLECT
          INTO tbl_id
          FROM wl_waiting_line x
         WHERE x.char_queue = i_char_num
           AND x.number_queue = i_ticket_number
         ORDER BY x.dt_begin_tstz DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_wl_waiting_line;

    --***********************************
    FUNCTION get_department(i_id_room IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT r.id_department
          BULK COLLECT
          INTO tbl_id
          FROM room r
         WHERE r.id_room = i_id_room;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_department;

    --*****************************************
    FUNCTION get_pat_gender(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    
        tbl_gender table_varchar;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        SELECT gender
          BULK COLLECT
          INTO tbl_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        IF tbl_gender.count > 0
        THEN
            l_return := tbl_gender(1);
        END IF;
    
        RETURN l_return;
    
    END get_pat_gender;

    FUNCTION get_allocated_queues(i_id_wl_machine IN NUMBER) RETURN table_number IS
        tbl_queue table_number;
    BEGIN
    
        SELECT id_wl_queue
          BULK COLLECT
          INTO tbl_queue
          FROM wl_q_machine
         WHERE id_wl_machine = i_id_wl_machine;
    
        RETURN tbl_queue;
    
    END get_allocated_queues;

    --*************************************
    PROCEDURE get_color_triage
    (
        i_id_episode IN NUMBER,
        o_color      OUT VARCHAR2,
        o_text       OUT VARCHAR2
    ) IS
    
        tbl_color           table_varchar;
        tbl_text            table_varchar;
        l_triage_color      VARCHAR2(4000);
        l_triage_color_text VARCHAR2(4000);
    
    BEGIN
    
        l_triage_color      := NULL;
        l_triage_color_text := NULL;
    
        IF i_id_episode IS NOT NULL
        THEN
        
            SELECT ei.triage_acuity, ei.triage_color_text
              BULK COLLECT
              INTO tbl_color, tbl_text
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF tbl_color.count > 0
            THEN
                l_triage_color      := tbl_color(1);
                l_triage_color_text := tbl_text(1);
            END IF;
        
        END IF;
    
        o_color := l_triage_color;
        o_text  := l_triage_color_text;
    
    END get_color_triage;

    FUNCTION set_audio
    (
        i_audio_active IN VARCHAR2,
        i_sound_file   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_audio_active IN (k_voice, k_bip)
        THEN
            l_return := i_sound_file;
        END IF;
    
        RETURN l_return;
    
    END set_audio;

    PROCEDURE upd_queue_as_processed(i_id_call_queue IN NUMBER) IS
    BEGIN
    
        UPDATE wl_call_queue
           SET flg_status = k_t_status
         WHERE id_call_queue = i_id_call_queue;
    
    END upd_queue_as_processed;

    PROCEDURE upd_call_state
    (
        i_flg_status IN VARCHAR2,
        i_wl         IN NUMBER
    ) IS
        l_rows table_varchar := table_varchar();
    BEGIN
    
        IF i_flg_status IN (pk_alert_constant.g_wr_wl_status_h, pk_alert_constant.g_wr_wl_status_n)
        THEN
            ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_wl,
                                   dt_call_tstz_in       => current_timestamp,
                                   dt_call_tstz_nin      => FALSE,
                                   rows_out              => l_rows);
        
        ELSE
            ts_wl_waiting_line.upd(id_wl_waiting_line_in => i_wl,
                                   dt_call_tstz_in       => current_timestamp,
                                   dt_call_tstz_nin      => FALSE,
                                   flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                                   flg_wl_status_nin     => FALSE,
                                   rows_out              => l_rows);
        END IF;
    
    END upd_call_state;

    --*******************************************************
    PROCEDURE get_color_triage
    (
        i_id_episode IN NUMBER,
        o_color      OUT VARCHAR2,
        o_color_text OUT VARCHAR2
    ) IS
    
        tbl_color table_varchar;
        tbl_text  table_varchar;
        l_color   VARCHAR2(4000);
        l_text    VARCHAR2(4000);
    
    BEGIN
    
        l_color := NULL;
        l_text  := NULL;
    
        IF i_id_episode IS NOT NULL
        THEN
        
            SELECT ei.triage_acuity, ei.triage_color_text
              BULK COLLECT
              INTO tbl_color, tbl_text
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF tbl_color.count > 0
            THEN
                l_color := tbl_color(1);
                l_text  := tbl_text(1);
            END IF;
        
        END IF;
    
        o_color      := l_color;
        o_color_text := l_text;
    
    END get_color_triage;

    FUNCTION process_call
    (
        i_lang               IN NUMBER,
        i_id_waiting_line    IN NUMBER,
        i_id_call_queue      IN NUMBER,
        i_id_mach            IN NUMBER,
        i_label_room         IN VARCHAR2,
        i_message            IN VARCHAR2,
        i_sound_file         IN VARCHAR2,
        i_flg_type           IN VARCHAR2,
        i_id_wl_machine_dest IN VARCHAR2
    ) RETURN t_rec_wl_plasma IS
        tbl_return     t_rec_wl_plasma := t_rec_wl_plasma(message_audio      => NULL,
                                                          message_sound_file => NULL,
                                                          flg_type           => NULL,
                                                          id_call_queue      => NULL,
                                                          color              => NULL,
                                                          char_queue         => NULL,
                                                          number_queue       => NULL,
                                                          desc_machine       => NULL,
                                                          triage_color       => NULL,
                                                          triage_color_text  => NULL,
                                                          titulo             => NULL,
                                                          label_name         => NULL,
                                                          label_room         => NULL,
                                                          nome               => NULL,
                                                          url_photo          => NULL);
        l_audio_active VARCHAR2(4000);
    
        xwle wl_waiting_line%ROWTYPE;
    
        --l_id_institution     NUMBER;
        l_prof               profissional;
        l_name               VARCHAR2(4000);
        l_flg_name_or_number VARCHAR2(0200 CHAR);
        l_titulo_mens        VARCHAR2(4000);
        l_wav_bip            VARCHAR2(4000);
        l_url_photo          VARCHAR2(4000);
        l_tit_pat_visual     VARCHAR2(4000);
        l_color              VARCHAR2(4000);
        l_text               VARCHAR2(4000);
    
        k_grey  CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_icon_light_grey;
        k_black CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_color_black;
    
        --***************************************
        PROCEDURE init_tbl_return IS
        BEGIN
            tbl_return.triage_color      := k_grey;
            tbl_return.triage_color_text := k_black;
            tbl_return.titulo            := NULL;
            tbl_return.label_name        := NULL;
            tbl_return.nome              := NULL;
            tbl_return.url_photo         := NULL;
        END init_tbl_return;
    
        --*******************************************
        PROCEDURE l_set_sys_configs IS
        BEGIN
        
            l_wav_bip            := pk_sysconfig.get_config(i_code_cf => k_wl_wav_bip_name, i_prof => l_prof);
            l_titulo_mens        := pk_sysconfig.get_config(i_code_cf => k_wl_titulo, i_prof => l_prof);
            l_flg_name_or_number := pk_sysconfig.get_config(i_code_cf => 'WL_CALL_BY_NAME_OR_NUMBER', i_prof => l_prof);
        
        END l_set_sys_configs;
    
        --*****************************************
        PROCEDURE set_common_info IS
        BEGIN
        
            tbl_return.message_audio      := i_message;
            tbl_return.message_sound_file := pk_wl_aux.set_audio(l_audio_active, i_sound_file);
            tbl_return.flg_type           := i_flg_type;
            tbl_return.id_call_queue      := i_id_call_queue;
            tbl_return.char_queue         := xwle.char_queue;
            tbl_return.number_queue       := xwle.number_queue;
            tbl_return.label_room         := i_label_room;
        
        END set_common_info;
    
        --************************************
        PROCEDURE set_name_n_photo IS
        BEGIN
        
            IF l_flg_name_or_number LIKE '%NAME%'
            THEN
                --l_url_photo      := pk_wl_aux.get_url_photo(i_lang, l_prof, xwle.id_patient);
                l_tit_pat_visual := pk_wl_aux.get_tit_pat_visual(i_lang, l_titulo_mens, xwle.id_patient);
                l_name           := pk_adt.get_patient_name_to_sort(i_lang, l_prof, xwle.id_patient, pk_adt.g_false);
            ELSE
                l_url_photo      := NULL;
                l_tit_pat_visual := NULL;
                l_name           := pk_adt.get_ticket_number(i_lang, l_prof, xwle.id_episode);
            END IF;
        
        END set_name_n_photo;
    
        --**************************************
        PROCEDURE set_med_info_only IS
        BEGIN
        
            --l_set_profissional_type();
            l_set_sys_configs();
        
            set_name_n_photo();
        
            get_color_triage(i_id_episode => xwle.id_episode, o_color => l_color, o_color_text => l_text);
        
            tbl_return.triage_color      := l_color;
            tbl_return.triage_color_text := l_text;
            tbl_return.titulo            := l_tit_pat_visual;
            tbl_return.label_name        := NULL;
            tbl_return.nome              := l_name;
            tbl_return.color             := get_med_queue_color(i_id_wl_machine_dest, l_prof.institution);
            tbl_return.url_photo         := l_url_photo;
        
            tbl_return.desc_machine := pk_wl_aux.get_desc_room(i_lang, i_id_wl_machine_dest);
        
        END set_med_info_only;
    
        --***************************************
        PROCEDURE set_adm_info_only IS
        BEGIN
        
            init_tbl_return();
            tbl_return.color        := get_color(xwle.id_wl_queue);
            tbl_return.desc_machine := pk_wl_aux.get_message_desc_machine(i_lang, i_id_wl_machine_dest);
        
        END set_adm_info_only;
    
        --********************************************
        PROCEDURE set_specific_info(i_flg_type IN VARCHAR2) IS
            k_workflow_adm CONSTANT VARCHAR2(0010 CHAR) := 'A';
            k_workflow_med CONSTANT VARCHAR2(0010 CHAR) := 'M';
        BEGIN
        
            CASE i_flg_type
                WHEN k_workflow_adm THEN
                    set_adm_info_only();
                WHEN k_workflow_med THEN
                    set_med_info_only();
                ELSE
                    tbl_return := NULL;
            END CASE;
        
        END set_specific_info;
    
        --*******************************************
        PROCEDURE set_l_prof IS
            k_wl_software CONSTANT NUMBER := 0;
        BEGIN
        
            IF nvl(l_prof.institution, 0) = 0
            THEN
                l_prof := profissional(0, pk_wl_aux.get_inst_from_mach(i_id_mach), k_wl_software);
            END IF;
        
        END set_l_prof;
    
    BEGIN
    
        set_l_prof();
    
        l_audio_active := pk_wl_aux.get_flg_audio(i_id_mach);
    
        xwle            := pk_wl_aux.get_waiting_line_row(i_id_waiting_line);
        xwle.id_patient := pk_wl_aux.get_pat_by_episode(xwle.id_episode);
    
        pk_wl_aux.upd_queue_as_processed(i_id_call_queue);
    
        pk_wl_aux.upd_call_state(i_flg_status => xwle.flg_wl_status, i_wl => i_id_waiting_line);
    
        set_common_info();
    
        set_specific_info(i_flg_type);
    
        RETURN tbl_return;
    
    END process_call;

    FUNCTION get_count_waiting_people
    (
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM wl_waiting_line wl
          JOIN wl_queue q
            ON q.id_wl_queue = wl.id_wl_queue
          JOIN wl_queue_group qg
            ON qg.id_wl_queue_group = q.id_wl_queue_group
         WHERE wl.flg_wl_status = 'E'
           AND q.flg_type_queue = 'A'
           AND wl.id_wl_queue = i_id_wl_queue
           AND qg.id_institution = i_prof.institution;
    
        RETURN l_count;
    
    END get_count_waiting_people;

    --*******************************************************
    FUNCTION get_time_1_method
    (
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER
    ) RETURN NUMBER IS
        l_sample NUMBER := 0;
        tbl_time  table_number;
        l_return  NUMBER;
    BEGIN
    
        l_sample := pk_sysconfig.get_config('WL_STAT_SAMPLE_SIZE', i_prof);
    
        SELECT AVG((xday * 24) + (xhour * 60) + xminute) avg_time
          BULK COLLECT
          INTO tbl_time
          FROM (SELECT x1.id_wl_queue,
                       extract(DAY FROM x1.xtempo) xday,
                       extract(hour FROM x1.xtempo) xhour,
                       extract(minute FROM x1.xtempo) xminute
                  FROM (SELECT wl.id_wl_queue, (wl.dt_call_tstz - wl.dt_begin_tstz) xtempo
                          FROM wl_waiting_line wl
                          JOIN wl_queue q
                            ON q.id_wl_queue = wl.id_wl_queue
                          JOIN wl_queue_group qg
                            ON qg.id_wl_queue_group = q.id_wl_queue_group
                         WHERE qg.id_institution = i_prof.institution
                           AND q.id_wl_queue = i_id_wl_queue
                           AND wl.dt_call_tstz >= current_timestamp - numtodsinterval(l_sample, 'HOUR')
                           AND q.flg_type_queue = 'A') x1)
         GROUP BY id_wl_queue;
    
        IF tbl_time.count > 0
        THEN
                l_return := tbl_time(1);
        END IF;
    
        RETURN l_return;
    
    END get_time_1_method;

    --*****************************************************
    FUNCTION get_time_2_method
    (
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER
    ) RETURN NUMBER IS
        l_sample NUMBER := 0;
        tbl_time table_number;
        l_return NUMBER;
    BEGIN
    
        -- While no ticket is called, estimate time should be:
        --(current date and time - date and time of first ticket)
        l_sample := pk_sysconfig.get_config('WL_STAT_SAMPLE_SIZE', i_prof);
    
        SELECT ((x2.xday * 24) + (x2.xhour * 60) + x2.xminute)
          BULK COLLECT
          INTO tbl_time
          FROM (SELECT extract(DAY FROM x1.xtempo) xday,
                       extract(hour FROM x1.xtempo) xhour,
                       extract(minute FROM x1.xtempo) xminute
                  FROM (SELECT (current_timestamp - wl.dt_begin_tstz) xtempo
                          FROM wl_waiting_line wl
                          JOIN wl_queue q
                            ON q.id_wl_queue = wl.id_wl_queue
                          JOIN wl_queue_group qg
                            ON qg.id_wl_queue_group = q.id_wl_queue_group
                         WHERE q.flg_type_queue = 'A'
                           AND qg.id_institution = i_prof.institution
                           AND q.id_wl_queue = i_id_wl_queue
                           AND wl.flg_wl_status = 'E'
                           AND wl.dt_begin_tstz >= current_timestamp - numtodsinterval(l_sample, 'HOUR')
                           AND rownum > 0
                         ORDER BY wl.dt_begin_tstz) x1) x2;
    
        IF tbl_time.count > 0
        THEN
            l_return := tbl_time(1);
        END IF;
    
        RETURN l_return;
    
    END get_time_2_method;

    FUNCTION get_avg_waiting_time
    (
        i_mode        IN VARCHAR2,
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER
    ) RETURN NUMBER IS
        --l_sample  NUMBER := 0;
        --tbl_time  table_number;
        --tbl_total table_number;
        l_return  NUMBER;
    BEGIN
    
        IF i_mode = k_calc_avg_waiting_time
        THEN
        
            --l_sample := pk_sysconfig.get_config('WL_STAT_SAMPLE_SIZE', i_prof);
        
            l_return := get_time_1_method(i_prof, i_id_wl_queue);
        
            IF nvl(l_return, 0) = 0
            THEN
                l_return := get_time_2_method(i_prof, i_id_wl_queue);
                IF nvl(l_return, 0) = 0
                THEN
                l_return := 0;
            END IF;
            END IF;
        
        ELSE
            l_return := get_count_waiting_people(i_prof => i_prof, i_id_wl_queue => i_id_wl_queue);
        END IF;
    
        RETURN l_return;
    
    END get_avg_waiting_time;

    FUNCTION format_avg_waiting_time
    (
        i_lang   IN NUMBER,
        i_people IN NUMBER,
        i_time   IN NUMBER,
        i_msg    in varchar2 default null
    ) RETURN VARCHAR2 IS
        l_msg   VARCHAR2(4000);
        l_total NUMBER;
        --l_total_v VARCHAR2(4000);
        l_tempo_v VARCHAR2(4000);
        l_unit_1  VARCHAR2(4000);
        l_unit_3  VARCHAR2(4000);
        --l_error   VARCHAR2(4000);
        xhours VARCHAR2(4000);
        k_msg_ticket_time constant varchar2(0200 char) := 'WL_MSG_TICKET';
    BEGIN
    
        -- get texts
        --l_error := 'GET MESSAGE 1';
        xhours := pk_message.get_message(i_lang, k_msg_hours_kiosk);
        l_unit_1 := pk_translation.get_translation(i_lang, 'TIME_UNIT.CODE_TIME_UNIT.1');
        l_unit_3 := pk_translation.get_translation(i_lang, 'TIME_UNIT.CODE_TIME_UNIT.3');

        /*    
        IF nvl(i_time,0) = 0 
        THEN
            l_msg  := pk_message.get_message(i_lang, 'INFO_GET_TICKET');
            --l_msg := pk_message.get_message(i_lang, k_msg_ticket_time);
        ELSE
            l_msg := pk_message.get_message(i_lang, k_msg_ticket_time);
            l_msg := l_msg || chr(32) || l_unit_3;
        end if;
        */
    
        l_msg := pk_message.get_message(i_lang, k_msg_ticket_time);
        l_msg := l_msg;
    
        -- REPLACE SPECIAL SPOTS WITH MEANINGFUL INFO
        l_msg := REPLACE(l_msg, '#01', to_char(i_people));
    
        IF i_people = 0
        THEN
            l_msg := REPLACE(l_msg, '#02', 0);
        ELSE
            --l_total := i_time * i_people;
            l_total := i_time;
        
            IF l_total > k_tempo_espera_lim
            THEN
                l_tempo_v := to_char(trunc(l_total / 60)) || chr(32) || xhours;
                l_tempo_v := l_tempo_v || chr(32) || to_char(MOD(l_total, 60), '00');
            ELSE
                l_tempo_v := l_total;
            END IF;
        
            l_msg := REPLACE(l_msg, '#02', (l_tempo_v || chr(32) || l_unit_3));
        
            IF l_total = 1
            THEN
                l_msg    := REPLACE((l_msg), l_unit_3, l_unit_1);
            END IF;
        
        END IF;
    
        RETURN l_msg;
    
    END format_avg_waiting_time;

    FUNCTION get_mach_queue_type(i_id_mach IN NUMBER) RETURN VARCHAR2 IS
        tbl_type table_varchar;
        l_return varchar2(0100 char);
    begin

        select flg_type_queue
          BULK COLLECT
          INTO tbl_type
        from wl_machine
        where id_wl_machine = i_id_mach;

        IF tbl_type.count > 0
        THEN
            l_return := tbl_type(1);
        end if;

        return l_return;

    end get_mach_queue_type;

    --****************************************
    FUNCTION get_tbl_queue_admin
    (
        i_lang          IN NUMBER,
        i_id_prof       IN profissional,
        i_id_wl_machine IN NUMBER
    ) RETURN t_tbl_wl_queue_admin IS
        tbl_return    t_tbl_wl_queue_admin;
        l_queue_types table_varchar := table_varchar();
    
    BEGIN
    
        l_queue_types := table_varchar('A', 'C');
    
        SELECT t_rec_wl_queue_admin(id_wl_queue      => t.id_wl_queue,
                                    inter_name_queue => pk_translation.get_translation(i_lang, t.code_name_queue),
                                    char_queue       => t.char_queue,
                                    num_queue        => t.num_queue,
                                    flg_visible      => t.flg_visible,
                                    flg_type_queue   => t.flg_type_queue,
                                    flg_priority     => t.flg_priority,
                                    foreground_color => t.foreground_color,
                                    color            => t.color,
                                    code_msg         => pk_translation.get_translation(i_lang, t.code_msg),
                                    total_ahead      => pk_wl_aux.get_people_ahead(t.id_wl_queue, i_id_prof),
                                    flg_allocated    => t.flg_allocated)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT --sys_connect_by_path(xtmp.id_wl_queue, '|') xpath,
                 connect_by_isleaf isleaf,
                 xtmp.id_wl_queue,
                 xtmp.id_parent,
                 xtmp.code_name_queue,
                 xtmp.char_queue,
                 xtmp.num_queue,
                 xtmp.flg_visible,
                 xtmp.flg_type_queue,
                 xtmp.flg_priority,
                 xtmp.foreground_color,
                 xtmp.color,
                 xtmp.code_msg,
                 CASE
                      WHEN id_wl_queue_check IS NULL THEN
                       'N'
                      ELSE
                       'Y'
                  END flg_allocated
                  FROM (SELECT q.*, qm.id_wl_queue id_wl_queue_check, qm.order_rank
                          FROM wl_queue q
                          JOIN department d
                            ON d.id_department = q.id_department
                          JOIN wl_queue_group qg
                            ON qg.id_institution = d.id_institution
                          LEFT JOIN (SELECT qq.*
                                      FROM wl_q_machine qq
                                      JOIN wl_machine m
                                        ON m.id_wl_machine = qq.id_wl_machine
                                     WHERE qq.id_wl_machine = i_id_wl_machine
                                       AND m.flg_mach_type = k_mach_user) qm
                            ON qm.id_wl_queue = q.id_wl_queue
                         WHERE qg.id_institution = i_id_prof.institution
                           AND q.flg_visible = k_yes
                           AND d.flg_available = k_yes
                           AND q.flg_type_queue IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                     column_value
                                                      FROM TABLE(l_queue_types) t)) xtmp
                CONNECT BY PRIOR xtmp.id_wl_queue = xtmp.id_parent
                 START WITH xtmp.id_parent IS NULL
                 ORDER SIBLINGS BY xtmp.order_rank) t
         WHERE t.isleaf = 1;
    
        RETURN tbl_return;
    
    END get_tbl_queue_admin;

    --****************************************
    FUNCTION get_tbl_queue_base
    (
        i_lang          IN NUMBER,
        i_id_prof       IN profissional,
        i_id_wl_machine IN NUMBER
    ) RETURN t_tbl_wl_queue_admin IS
        tbl_return    t_tbl_wl_queue_admin;
        l_queue_types table_varchar := table_varchar();
    
    BEGIN
    
        l_queue_types := table_varchar('A', 'C');
    
        SELECT t_rec_wl_queue_admin(id_wl_queue      => t.id_wl_queue,
                                    inter_name_queue => pk_translation.get_translation(i_lang, t.code_name_queue),
                                    char_queue       => t.char_queue,
                                    num_queue        => t.num_queue,
                                    flg_visible      => t.flg_visible,
                                    flg_type_queue   => t.flg_type_queue,
                                    flg_priority     => t.flg_priority,
                                    foreground_color => t.foreground_color,
                                    color            => t.color,
                                    code_msg         => pk_translation.get_translation(i_lang, t.code_msg),
                                    total_ahead      => pk_wl_aux.get_people_ahead(t.id_wl_queue, i_id_prof),
                                    flg_allocated    => t.flg_allocated)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT --sys_connect_by_path(xtmp.id_wl_queue, '|') xpath,
                 connect_by_isleaf isleaf,
                 xtmp.id_wl_queue,
                 xtmp.id_parent,
                 xtmp.code_name_queue,
                 xtmp.char_queue,
                 xtmp.num_queue,
                 xtmp.flg_visible,
                 xtmp.flg_type_queue,
                 xtmp.flg_priority,
                 xtmp.foreground_color,
                 xtmp.color,
                 xtmp.code_msg,
                 CASE
                      WHEN id_wl_queue_check IS NULL THEN
                       'N'
                      ELSE
                       'Y'
                  END flg_allocated
                  FROM (SELECT q.*, qm.id_wl_queue id_wl_queue_check, qm.order_rank
                          FROM wl_queue q
                          JOIN department d
                            ON d.id_department = q.id_department
                          JOIN wl_queue_group qg
                            ON qg.id_institution = d.id_institution
                          LEFT JOIN (SELECT qq.*
                                      FROM wl_q_machine qq
                                      JOIN wl_machine m
                                        ON m.id_wl_machine = qq.id_wl_machine
                                     WHERE qq.id_wl_machine = i_id_wl_machine
                                       AND m.flg_mach_type = k_mach_user) qm
                            ON qm.id_wl_queue = q.id_wl_queue
                         WHERE qg.id_institution = i_id_prof.institution
                           AND q.flg_visible = k_yes
                           AND d.flg_available = k_yes
                           AND q.flg_type_queue IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                     column_value
                                                      FROM TABLE(l_queue_types) t)) xtmp
                CONNECT BY PRIOR xtmp.id_wl_queue = xtmp.id_parent
                 START WITH xtmp.id_parent IS NULL
                 ORDER SIBLINGS BY xtmp.order_rank) t
         WHERE t.isleaf = 1;
    
        RETURN tbl_return;
    
    END get_tbl_queue_base;

    FUNCTION get_parent_color(i_wl_parent IN NUMBER) RETURN VARCHAR2 IS
        tbl_color table_varchar;
        l_return  VARCHAR2(4000);
    BEGIN
    
        SELECT pk_wl_aux.get_color(wl.id_wl_queue) color
          BULK COLLECT
          INTO tbl_color
          FROM wl_waiting_line wl
         WHERE wl.id_wl_waiting_line = i_wl_parent;
    
        IF tbl_color.count > 0
        THEN
            l_return := tbl_color(1);
        END IF;
    
        RETURN l_return;
    
    END get_parent_color;

    FUNCTION get_med_queue_color
    (
        i_id_mach     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2 IS
        l_id_queue_group NUMBER;
        k_system_queue CONSTANT VARCHAR2(0010 CHAR) := 'D';
        tbl_color table_varchar;
        l_return  VARCHAR2(0200 CHAR);
    BEGIN
    
        l_id_queue_group := get_queue_group_by_mach(i_id_mach);
    
        SELECT q.color
          BULK COLLECT
          INTO tbl_color
          FROM wl_queue q
          JOIN wl_queue_group qg
            ON qg.id_wl_queue_group = q.id_wl_queue_group
         WHERE q.id_wl_queue_group = l_id_queue_group
           AND q.flg_type_queue = k_system_queue
           AND qg.id_institution = i_institution;
    
        IF tbl_color.count > 0
        THEN
            l_return := tbl_color(1);
        END IF;
    
        RETURN l_return;
    
    END get_med_queue_color;

    FUNCTION get_queue_group_by_mach(i_id_mach IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        IF i_id_mach IS NOT NULL
        THEN
        
            SELECT id_wl_queue_group
              BULK COLLECT
              INTO tbl_id
              FROM wl_machine
             WHERE id_wl_machine = i_id_mach;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_queue_group_by_mach;

BEGIN

    inicialize();

END pk_wl_aux;
/
