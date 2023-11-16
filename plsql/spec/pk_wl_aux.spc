CREATE OR REPLACE PACKAGE pk_wl_aux AS

    k_calc_total_patient    CONSTANT VARCHAR2(0050 CHAR) := 'CALC_TOTAL_PATIENT';
    k_calc_avg_waiting_time CONSTANT VARCHAR2(0050 CHAR) := 'CALC_AVG_WAITING_TIME';

    k_mach_kiosk   CONSTANT VARCHAR2(0020 CHAR) := 'K';
    k_mach_monitor CONSTANT VARCHAR2(0020 CHAR) := 'M';
    k_mach_user    CONSTANT VARCHAR2(0020 CHAR) := 'P';

    FUNCTION get_wl_queue
    (
        i_prof          IN profissional,
        i_id_wl_machine IN NUMBER
    ) RETURN table_number;

    --*********************************************************
    --FUNCTION get_queue_color(i_color IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_row_episode(i_id_episode IN NUMBER) RETURN episode%ROWTYPE;

    --***************************************************************************
    FUNCTION get_row_epis_info(i_id_episode IN NUMBER) RETURN epis_info%ROWTYPE;

    --***************************************************************************
    FUNCTION get_row_visit(i_id_visit IN NUMBER) RETURN visit%ROWTYPE;

    --***************************************************************************
    FUNCTION get_wl_row_by_ticket
    (
        i_char_queue   IN VARCHAR2,
        i_number_queue IN NUMBER
    ) RETURN NUMBER;

    --************************************************************
    PROCEDURE get_next_ticket
    (
        i_id_wl_queue IN NUMBER,
        o_char        OUT VARCHAR2,
        o_number      OUT NUMBER
    );

    --***************************************************************
    FUNCTION get_med_queue
    (
        i_prof      IN profissional,
        i_mach_name IN VARCHAR2
    ) RETURN NUMBER;

    --****************************************************************
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
    );

    --*********************************************
    PROCEDURE get_ticket_info
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        o_codification_type OUT VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_code              OUT VARCHAR2
    );

    --*********************************************************
    PROCEDURE update_adt
    (
        i_id_episode    IN NUMBER,
        i_ticket_number IN VARCHAR2
    );

    --*********************************************************
    FUNCTION get_dept_of_prof(i_prof IN profissional) RETURN table_number;

    --********************************************************
    FUNCTION get_id_software RETURN NUMBER;

    --********************************************************
    FUNCTION count_kiosk_department
    (
        i_prof         IN profissional,
        i_machine_name IN VARCHAR2
    ) RETURN NUMBER;

    --***************************************
    FUNCTION get_max_tickets_shown(i_id_machine IN NUMBER) RETURN NUMBER;

    --***************************************
    FUNCTION get_dept_from_machine(i_id_machine IN NUMBER) RETURN NUMBER;

    --***************************************
    FUNCTION priority_q_allocated(i_id_mach IN NUMBER) RETURN table_number;

    --***************************************
    FUNCTION get_wl_line_row
    (
        i_flg_prior IN NUMBER,
        i_id_queues IN table_number
    ) RETURN wl_waiting_line%ROWTYPE;

    --***************************************
    PROCEDURE set_wl_line_executed
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_wl_waiting_line IN NUMBER
    );

    --******************************************
    FUNCTION get_wl_by_episode(i_id_episode IN NUMBER) RETURN NUMBER;

    --******************************************
    FUNCTION get_mach_by_id_wl
    (
        i_prof  IN profissional,
        i_id_wl IN NUMBER
    ) RETURN NUMBER;

    --******************************************
    FUNCTION get_mach_by_room(i_id_room IN NUMBER) RETURN NUMBER;

    --*******************************************

    --**********************************************
    PROCEDURE get_pat_info
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_wl      IN NUMBER,
        o_nome_pat   OUT VARCHAR2,
        o_sexo_pat   OUT VARCHAR2,
        o_flg_status OUT VARCHAR2
    );

    --***********************************************
    FUNCTION get_ticket_from_wl(i_id_wl IN NUMBER) RETURN VARCHAR2;

    --***********************************************
    PROCEDURE upd_wl_waiting_line(i_id_wl IN NUMBER);

    --***********************************************
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
    );

    --************************************************
    FUNCTION get_people_ahead
    (
        i_id_wl_queue IN NUMBER,
        i_prof        IN profissional
    ) RETURN NUMBER;

    --**************************************************
    FUNCTION format
    (
        i_msg    IN VARCHAR2,
        i_params IN table_varchar
    ) RETURN VARCHAR2;

    --***************************************************************************
    FUNCTION get_prof_default_language(i_id_prof IN profissional) RETURN NUMBER;

    --********************************************************
    FUNCTION get_lang
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN NUMBER;

    --*************************************************************
    FUNCTION get_room_of_mach(i_id_machine IN NUMBER) RETURN NUMBER;

    --***************************************************
    FUNCTION get_inst_from_mach(i_id_machine IN NUMBER) RETURN NUMBER;

    --********************************************
    FUNCTION get_pat_by_episode(i_id_episode IN NUMBER) RETURN NUMBER;

    --******************************************************
    FUNCTION get_color(i_id_queue IN NUMBER) RETURN VARCHAR2;

    --****************************
    FUNCTION get_desc_room
    (
        i_lang    IN NUMBER,
        i_machine IN VARCHAR2
    ) RETURN VARCHAR2;

    --**********************************
    FUNCTION get_flg_audio(i_id_mach IN NUMBER) RETURN VARCHAR2;

    --******************************************
    FUNCTION get_waiting_line_row(i_id_wl IN NUMBER) RETURN wl_waiting_line%ROWTYPE;

    --********************************************
    FUNCTION get_message_desc_machine
    (
        i_lang       IN NUMBER,
        i_id_machine IN NUMBER
    ) RETURN VARCHAR2;

    --*************************************
    FUNCTION get_tit_pat_visual
    (
        i_lang       IN NUMBER,
        i_tit_mens   IN NUMBER,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2;

    --****************************************
    FUNCTION get_url_photo
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2;

    --************************************
    FUNCTION get_institution(i_id_department IN NUMBER) RETURN NUMBER;

    --**********************************
    FUNCTION get_wl_waiting_line
    (
        i_char_num      IN VARCHAR2,
        i_ticket_number IN NUMBER
    ) RETURN NUMBER;

    --***********************************
    FUNCTION get_department(i_id_room IN NUMBER) RETURN NUMBER;

    --*****************************************
    FUNCTION get_pat_gender(i_id_patient IN NUMBER) RETURN VARCHAR2;

    PROCEDURE ins_wl_q_machine
    (
        i_id_mach   IN NUMBER,
        i_id_queues IN table_number
    );

    PROCEDURE del_wl_q_machine(i_id_mach IN NUMBER);
    PROCEDURE del_wl_q_machine(i_mach_name IN VARCHAR2);
    FUNCTION get_allocated_queues(i_id_wl_machine IN NUMBER) RETURN table_number;
    PROCEDURE upd_queue_as_processed(i_id_call_queue IN NUMBER);

    FUNCTION set_audio
    (
        i_audio_active IN VARCHAR2,
        i_sound_file   IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE get_color_triage
    (
        i_id_episode IN NUMBER,
        o_color      OUT VARCHAR2,
        o_text       OUT VARCHAR2
    );

    PROCEDURE upd_call_state
    (
        i_flg_status IN VARCHAR2,
        i_wl         IN NUMBER
    );

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
    ) RETURN t_rec_wl_plasma;

    FUNCTION format_avg_waiting_time
    (
        i_lang   IN NUMBER,
        i_people IN NUMBER,
        i_time   IN NUMBER,
        i_msg    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_avg_waiting_time
    (
        i_mode        IN VARCHAR2,
        i_prof        IN profissional,
        i_id_wl_queue IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_inst_from_queue(i_id_wl_queue IN NUMBER) RETURN NUMBER;

    FUNCTION get_mach_queue_type(i_id_mach IN NUMBER) RETURN VARCHAR2;

    --*********************************************************
    FUNCTION get_id_machine_by_name(i_name IN VARCHAR2) RETURN NUMBER;

    --****************************************
    FUNCTION get_tbl_queue_admin
    (
        i_lang          IN NUMBER,
        i_id_prof       IN profissional,
        i_id_wl_machine IN NUMBER
    ) RETURN t_tbl_wl_queue_admin;

    FUNCTION get_parent_color(i_wl_parent IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_med_queue_color
    (
        i_id_mach     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_queue_group_by_mach(i_id_mach IN NUMBER) RETURN NUMBER;

END pk_wl_aux;
/
