/*-- Last Change Revision: $Rev: 2028858 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:21 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_percentile IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 21/09/2017 21-09-2017 1424:41:16 14:41726r
    -- Purpose : Packege to handle percentile calculation and management

    g_graph_year  CONSTANT graphic.flg_x_axis_type%TYPE := 'Y';
    g_graph_month CONSTANT graphic.flg_x_axis_type%TYPE := 'M';

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION set_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode            IN vital_sign_read.id_episode%TYPE DEFAULT NULL,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION set_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_vs_value           IN vital_sign_read.value%TYPE,
        i_vs_id_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_vs_dt_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_id_percentile_vs   OUT vital_sign.id_vital_sign%TYPE,
        o_high_percentile    OUT graphic_line.line_value%TYPE,
        o_low_percentile     OUT graphic_line.line_value%TYPE,
        o_nearest_percentile OUT graphic_line.line_value%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION cancel_percentile_vs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN vital_sign_read.id_episode%TYPE DEFAULT NULL,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION cancel_percentile_vs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign    IN vital_sign.id_vital_sign%TYPE,
        i_vs_dt_read       IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel     IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_relation_percentile_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_vital_sign     IN vital_sign.id_vital_sign%TYPE,
        o_id_vital_sign_rel OUT vital_sign.id_vital_sign%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    * returns the appropriate graphic for the patient and specific vital sign
    ***************************************************************************************/
    FUNCTION get_percentile_graphic
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_id_vital_sign         IN vital_sign.id_vital_sign%TYPE,
        i_vs_dt_read            IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_id_graphic            OUT graphic.id_graphic%TYPE,
        o_graph_id_unit_measure OUT graphic.id_unit_measure%TYPE,
        o_pat_age               OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION calculate_percentile
    (
        i_lang               IN language.id_language%TYPE,
        i_id_graphic         IN graphic.id_graphic%TYPE,
        i_input_x_value      IN graphic_line_point.point_value_x%TYPE,
        i_input_y_value      IN graphic_line_point.point_value_y%TYPE,
        o_high_percentile    OUT graphic_line.line_value%TYPE,
        o_low_percentile     OUT graphic_line.line_value%TYPE,
        o_nearest_percentile OUT graphic_line.line_value%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    
    /***************************************************************************************
    ***************************************************************************************/
    FUNCTION get_percentile_vs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_view      IN vs_soft_inst.flg_view%TYPE,
        o_percentile_vs OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN; 

END pk_percentile;
/
