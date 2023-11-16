/*-- Last Change Revision: $Rev: 2028944 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_scales_formulas IS

    -- Author  : SOFIA.MENDES
    -- Created : 7/6/2011 8:21:36 AM
    -- Purpose : This package will handle the logic of the scales formulas calculation to obtain the scales scores.

    -- Public type declarations    
    TYPE t_rec_compl_scores IS RECORD(
        description       VARCHAR2(4000),
        id_scales_formula scales_formula.id_scales_formula%TYPE,
        score_value       VARCHAR2(200),
        rank              scales_formula.rank%TYPE);

    TYPE t_tab_compl_scores IS TABLE OF t_rec_compl_scores;

    -- Public constant declarations     

    /********************************************************************************************
    *  Round a decimal number in order to it do not have more than 5 characters (including the dot)
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_number           Input number    
    *
    * @return                  Formated number
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION round_number
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_number IN NUMBER
    ) RETURN VARCHAR2;
    
    /********************************************************************************************
    *  Get the score_calculation_formulas (of a scales group, a scale,  
    *  a group of elements regarding an id_documentation or a ist of doc_elements)
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_id_scales_group  Scales group id 
    * @param i_id_scales        Scales id
    * @param i_id_documentation Documentation id (groups of elements in a template)
    * @param i_doc_element      Documentation element ID
    *
    * @return                          formulas info
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_formulas
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_scales_group  IN scales_group.id_scales_group%TYPE,
        i_id_scales        IN scales.id_scales%TYPE,
        i_id_documentation IN scales_group_rel.id_documentation%TYPE,
        i_id_doc_element   IN doc_element.id_doc_element%TYPE
    ) RETURN t_tab_score_formulas;

    /********************************************************************************************
    *  Executes the calcution of the formula, and returns the score value.
    *
    * @param i_lang             Language identifier
    * @param i_prof             Professional
    * @param i_scales_formula   Formula with all replaced values. Ready to be done the mathematics calculation    
    * @param o_error            score value
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           29-Jun-2011
    **********************************************************************************************/
    FUNCTION get_exec_formula
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_scales_formula IN scales_formula.formula%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_doc_elements             Doc elements Ids
    * @param i_values                   Values inserted by the user for each doc_element
    * @param i_flg_score_type           'P' - partial score; T - total score.
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_main_scores              Main scores results
    * @param o_descs                    Scales decritions and complementary formulas results.
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_main_scores           OUT pk_types.cursor_type,
        o_descs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the groups associated to a scale, or associated to the scales associated to a doc_area.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID        
    * @param i_scales                  Scales ID
    * @param o_groups                  Groups info
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_groups
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_scales   IN scales.id_scales%TYPE,
        o_groups   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

     /********************************************************************************************
    *  Calculates the nr of questions that had been answered by the user based on the selected 
    *  doc_elements
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_scores                  Scores info        
    * @param o_nr_questions            Nr of answered questions
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Jul-2011
    **********************************************************************************************/
    FUNCTION get_nr_answered_questions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_scores                IN t_tab_score_values,
        o_nr_questions OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    
    /********************************************************************************************
    *  Calculates the element that has the greater score. Returns the score of that element.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_scores                  Scores info        
    * @param o_max_score               Maximun score
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           05-Sep-2011
    **********************************************************************************************/
    FUNCTION get_max_score
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_scores    IN t_tab_score_values,
        o_max_score OUT scales_doc_value.value%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get the score (total or partial) considering the id_epis_documentation.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_error                    Error
    *
    * @return                          Scores
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_calculated_scores
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_nr_answered_questions IN PLS_INTEGER
    ) RETURN t_tab_score_formulas;
    
    /********************************************************************************************
    *  Get the scores of the elements associated to an doc_area, the groups and the scale.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID    
    * @param o_score                   New documentation ID
    * @param o_groups                  Groups info
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_score           OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
        

    -- Public variable declarations
    g_exception EXCEPTION;

END pk_scales_formulas;

-- Function and procedure implementations
/
