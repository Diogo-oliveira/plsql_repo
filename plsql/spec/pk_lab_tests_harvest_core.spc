/*-- Last Change Revision: $Rev: 2028775 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_harvest_core IS

    /*
    * Creates a pending harvest
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_episode            Episode id
    * @param     i_analysis_req       Lab tests' order id
    * @param     i_analysis_req_det   Lab tests' order detail id 
    * @param     i_body_location      Body part id
    * @param     i_laterality         Laterality
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION create_harvest_pending
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN harvest.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_body_location    IN harvest.id_body_part%TYPE,
        i_laterality       IN harvest.flg_laterality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_harvest_suspended
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Collects the given lab tests
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_body_location               Body part id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Local of collection
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipient id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_flg_rep_collection          Flag that indicates if the user is collecting again
    * @param     i_rep_coll_reason             Repeat collection reason
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number, --5
        i_analysis_req_det          IN table_table_number,
        i_body_location             IN table_number,
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --15
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE, --20
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        i_revised_by                IN professional.id_professional%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Collects the given lab tests
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_body_location               Body part id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Local of collection
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_flg_rep_collection          Flag that indicates if the user is collecting again
    * @param     i_rep_coll_reason             Repeat collection reason
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number, --5
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE, --10
        i_collection_room           IN VARCHAR2,
        i_lab                       IN analysis_room.id_room%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE, --15
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE, --20
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        i_revised_by                IN professional.id_professional%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest_history
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_analysis_harvest IN analysis_harvest.id_analysis_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Edit harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_body_location               Body location id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition id
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipient id
    * @param     i_num_recipient               Number of recipient
    * @param     i_collect_time                Collection time    
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number, --5
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar, --15
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Combine the given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN table_number, --5
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE, --10
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --15
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
        o_harvest                   OUT harvest.id_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Repeats a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_visit                       Visit id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_body_location               Body location id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Local of collection
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id    
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_rep_coll_reason             Repeat collection reason
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_repeat
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_visit                     IN visit.id_visit%TYPE,
        i_episode                   IN episode.id_episode%TYPE, --5
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number,
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE, --10
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE, --15
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --20
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Divides a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_flg_divide                  Flag that indicates if the lab test harvest is to be divided or not: Y - Yes; N - No
    * @param     i_collection_method           Collection method
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_divide
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_harvest          IN table_table_number, --5
        i_flg_divide                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number, --10
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar, --15
        i_notes                     IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Divides a given lab tests' harvest
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_patient                     Patient id
    * @param     i_episode                     Episode id
    * @param     i_harvest                     Harvest id
    * @param     i_analysis_harvest            Analysis harvest id
    * @param     i_analysis_req_det            Lab tests' order detail id 
    * @param     i_flg_divide                  Flag that indicates if the lab test harvest is to be divided or not: Y - Yes; N - No
    * @param     i_flg_collect                 Flag that indicates if the lab test is to be collected or not: Y - Yes; N - No
    * @param     i_body_location               Body part id
    * @param     i_laterality                  Laterality
    * @param     i_collection_method           Collection method
    * @param     i_specimen_condition          Specimen condition
    * @param     i_collection_room             Collection room id
    * @param     i_lab                         Laboratory id
    * @param     i_exec_institution            Institution id
    * @param     i_sample_recipient            Sample recipients id
    * @param     i_num_recipient               Number of recipients
    * @param     i_collected_by                Collected by
    * @param     i_collection_time             Collection time
    * @param     i_collection_amount           Collection amount
    * @param     i_collection_transportation   Transportation mode
    * @param     i_notes                       Harvest notes
    * @param     i_flg_orig_harvest            Flag that indicates the collection origin: A - Alert; I - Interfaces
    * @param     o_harvest                     Harvest id
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION set_harvest_divide_and_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE, --5
        i_analysis_harvest          IN table_table_number,
        i_analysis_req_det          IN table_table_number,
        i_flg_divide                IN table_varchar,
        i_flg_collect               IN table_varchar,
        i_body_location             IN table_number, --10
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --15
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --20
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_harvest                   OUT table_number, --25
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_harvest_questionnaire
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN table_number,
        i_questionnaire    IN table_table_number,
        i_response         IN table_table_varchar,
        i_notes            IN table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Rejects a given lab tests' harvest
    *
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_patient              Patient id
    * @param     i_episode              Episode id
    * @param     i_harvest              Harvest id
    * @param     i_cancel_reason        Rejection reason id
    * @param     i_cancel_notes         Rejection notes
    * @param     i_specimen_condition   Specimen condition
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.4
    * @since     2014/05/12
    */

    FUNCTION set_harvest_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_harvest            IN table_number,
        i_cancel_reason      IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes       IN harvest.notes_cancel%TYPE,
        i_specimen_condition IN harvest.id_specimen_condition%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN table_number,
        i_status           IN table_varchar,
        i_collected_by     IN table_number DEFAULT NULL,
        i_collection_time  IN table_varchar DEFAULT NULL,
        i_flg_orig_harvest IN harvest.flg_orig_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a given lab tests' harvest
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_patient         Patient id
    * @param     i_episode         Episode id
    * @param     i_harvest         Harvest id
    * @param     i_cancel_reason   Cancel reason id
    * @param     i_cancel_notes    Cancellation Notes
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5.1
    * @since     2011/01/17
    */

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_movement_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_preview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        i_flg_report               IN VARCHAR2 DEFAULT 'N',
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_lab_test_harvest OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_to_collect
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN table_number,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_laboratory
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the EPL code for a given harvest to be sent to the printer
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_harvest             Harvest id
    * @param     o_printer             Printer
    * @param     o_codification_type   Barcode type: EPL; ZPL
    * @param     o_barcode             Barcode
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/07/24
    */

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_harvest           IN table_number,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for specimen collection method
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.4
    * @since     2014/05/06
    */

    FUNCTION get_harvest_method_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for specimen transportation
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/09/23
    */

    FUNCTION get_harvest_transport_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of options for collection repeating 
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     o_list         Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    José Castro
    * @version   2.6.0.5
    * @since     2011/01/17
    */

    FUNCTION get_harvest_reason_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_lt_movement
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION tf_harvest_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_harvest_listview;

    FUNCTION tf_harvest_listview_base
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_harvest_listview_base;

    /*
    * Returns a table with the common sample recipients configured for each harvest  
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_harvest      Harvest id
    
    * @return    type
    *
    * @author    Teresa Coutinho
    * @version   2.6.4.1
    * @since     2014/07/01
    */

    FUNCTION tf_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN table_number
    ) RETURN t_tbl_harvest_sample_recipient;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_lab_tests_harvest_core;
/
