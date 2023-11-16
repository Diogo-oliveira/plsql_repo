/*-- Last Change Revision: $Rev: 2028711 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hand_off_mcdts AS

    -- Public type declarations
    --monit
    TYPE t_rec_monit IS RECORD(
        flg_status      monitorizations_ea.flg_status%TYPE,
        desc_vital_sign VARCHAR2(1000 CHAR));

    TYPE t_coll_tab_monit IS TABLE OF t_rec_monit;

    --lab
    TYPE t_rec_lab IS RECORD(
        flg_status    lab_tests_ea.flg_status_det%TYPE,
        flg_referral  lab_tests_ea.flg_referral%TYPE,
        desc_analysis VARCHAR2(1000 CHAR),
        desc_dep      VARCHAR2(1000 CHAR));

    TYPE t_coll_tab_lab IS TABLE OF t_rec_lab;

    --i_oe
    TYPE t_rec_i_oe IS RECORD(
        flg_type   exams_ea.flg_type%TYPE,
        flg_status exam_req_det .flg_status%TYPE,
        desc_exam  VARCHAR2(1000 CHAR));

    TYPE t_coll_tab_i_oe IS TABLE OF t_rec_i_oe;

    /**********************************************************************************************
    * return image and other exams records (replaces de views)
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_status             flg status to filter
    * @param i_flg_type               flg to change between image and other exams
    *
    * @return                         pipelined records
    *
    * @author                         Rui Spratley
    * @version                        1.0
    * @since                          03/09/2010
    **********************************************************************************************/

    FUNCTION get_i_oe_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2,
        i_flg_type   IN VARCHAR2
    ) RETURN t_coll_tab_i_oe
        PIPELINED;

    /**********************************************************************************************
    * return lab records (replaces de views)
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_status             flg status to filter
    *
    * @return                         pipelined records
    *
    * @author                         Rui Spratley
    * @version                        1.0
    * @since                          02/09/2010
    **********************************************************************************************/

    FUNCTION get_lab_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_lab
        PIPELINED;

    /**********************************************************************************************
    * return monitorization records (replaces de views)
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_status             flg status to filter
    *
    * @return                         pipelined records
    *
    * @author                         Rui Spratley
    * @version                        1.0
    * @since                          01/09/2010
    **********************************************************************************************/

    FUNCTION get_monit_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_monit
        PIPELINED;

    /**********************************************************************************************
    * return procedures information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_hand_off               cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_proc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * return lab tests information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_lab
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * return exams information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_image_exams_on_hold                on hold
    * @param o_image_exams_last_24h               last 24 hours
    * @param o_image_exams_in_progress            in progress
    * @param o_image_exams_to_be_done             to be done
    * @param o_other_exams_on_hold                on hold
    * @param o_other_exams_last_24h               last 24 hours
    * @param o_other_exams_in_progress            in progress
    * @param o_other_exams_to_be_done             to be done
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_exam
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        o_image_exams_on_hold     OUT pk_types.cursor_type,
        o_image_exams_last_24h    OUT pk_types.cursor_type,
        o_image_exams_in_progress OUT pk_types.cursor_type,
        o_image_exams_to_be_done  OUT pk_types.cursor_type,
        o_other_exams_on_hold     OUT pk_types.cursor_type,
        o_other_exams_last_24h    OUT pk_types.cursor_type,
        o_other_exams_in_progress OUT pk_types.cursor_type,
        o_other_exams_to_be_done  OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * return medication information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_med
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * return monitorization information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_hand_off               cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Rui Spratley
    * @version                        1.0
    * @since                          01/09/2010
    **********************************************************************************************/

    FUNCTION get_h_off_rep_monit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --############################################################################################## --
    --GLOBALS
    --############################################################################################## --
    --
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    g_error        VARCHAR2(4000);

    --Global variables
    g_flg_status_c    CONSTANT VARCHAR2(1) := 'C';
    g_flg_status_d    CONSTANT VARCHAR2(1) := 'D';
    g_flg_status_a    CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_f    CONSTANT VARCHAR2(1) := 'F';
    g_flg_status_i    CONSTANT VARCHAR2(1) := 'I';
    g_flg_status_e    CONSTANT VARCHAR2(1) := 'E';
    g_flg_status_r    CONSTANT VARCHAR2(1) := 'R';
    g_flg_status_z    CONSTANT VARCHAR2(1) := 'Z';
    g_flg_status_s    CONSTANT VARCHAR2(1) := 'S';
    g_flg_status_l    CONSTANT VARCHAR2(1) := 'L';
    g_flg_status_pa   CONSTANT VARCHAR2(2) := 'PA';
    g_flg_status_ex   CONSTANT VARCHAR2(2) := 'EX';
    g_flg_status_p    CONSTANT VARCHAR2(1) := 'P';
    g_flg_status_x    CONSTANT VARCHAR2(1) := 'X';
    g_flg_status_y    CONSTANT VARCHAR2(1) := 'Y';
    g_flg_status_xo   CONSTANT VARCHAR2(2) := 'XO';
    g_flg_status_sos  CONSTANT VARCHAR2(3) := 'SOS';
    g_flg_status_h    CONSTANT VARCHAR2(1) := 'H';
    g_flg_status_sosh CONSTANT VARCHAR2(4) := 'SOSH';
    g_flg_status_ch   CONSTANT VARCHAR2(2) := 'CH';
    g_flg_status_m    CONSTANT VARCHAR2(1) := 'M';
    g_flg_status_next CONSTANT VARCHAR2(4) := 'NEXT';
    g_flg_status_b    CONSTANT VARCHAR2(1) := 'B';
    g_flg_status_o    CONSTANT VARCHAR2(1) := 'O';
    g_flg_status_n    CONSTANT VARCHAR2(1) := 'N';

    g_flg_time_n CONSTANT VARCHAR2(1) := 'N';
    g_flg_time_r CONSTANT VARCHAR2(1) := 'R';

    g_flg_free_text_y CONSTANT VARCHAR2(1) := 'Y';

    flg_referral_d CONSTANT VARCHAR2(1) := 'D';
    flg_referral_s CONSTANT VARCHAR2(1) := 'S';

    g_flg_status_hold       CONSTANT VARCHAR2(1) := 'H';
    g_flg_status_progress   CONSTANT VARCHAR2(1) := 'P';
    g_flg_status_last_24h   CONSTANT VARCHAR2(1) := 'D';
    g_flg_status_to_be_done CONSTANT VARCHAR2(1) := 'T';

    g_dt_compare_g CONSTANT VARCHAR2(1) := 'G';
    g_monit        CONSTANT VARCHAR2(2) := 'MN';
    g_anl_det      CONSTANT VARCHAR2(2) := 'AD';
    g_exm_req      CONSTANT VARCHAR2(2) := 'ER';

    g_image   CONSTANT VARCHAR2(1) := 'I';
    g_oth_exm CONSTANT VARCHAR2(1) := 'E';

    g_available CONSTANT VARCHAR2(1) := 'Y';

    g_complete_descriptive CONSTANT NUMBER(1) := 3;

    g_subject_local  CONSTANT VARCHAR2(30) := 'LOCAL';
    g_subject_soro   CONSTANT VARCHAR2(30) := 'SORO';
    g_prev_message   CONSTANT VARCHAR2(30) := 'GET_NAME';
    g_adv_inp_screen CONSTANT VARCHAR2(30) := 'N';

--

END pk_hand_off_mcdts;
/
