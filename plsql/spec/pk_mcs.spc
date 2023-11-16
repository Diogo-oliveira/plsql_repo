/*-- Last Change Revision: $Rev: 2028792 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_mcs IS

    -- Medical Classification System (MCS) database package

    /********************************************************************************************
    * get translation column based in required language id
    *
    * @param       i_lang                    language id
    *
    * @return      varchar2                  translation column name
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/25
    ********************************************************************************************/
    FUNCTION get_translation_column(i_lang IN language.id_language%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * get concept/description/relation domain map flag from a given source
    *
    * @param       i_source                  standard source id
    * @param       i_domain_flag             concept/description/relation status/type flag
    * @param       i_domain_code             concept/description/relation domain code
    *
    * @return      varchar2                  concept/description/relationship domain map flag
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/25
    ********************************************************************************************/
    FUNCTION get_domain_map
    (
        i_source      IN mcs_source.id_mcs_source%TYPE,
        i_domain_flag IN VARCHAR2,
        i_domain_code IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get concept/description/relation domain map source flag from a given content source
    *
    * @param       i_source                  standard source id
    * @param       i_domain_trg_flag         concept/description/relation status/type target flag
    * @param       i_domain_code             concept/description/relation domain code
    *
    * @return      varchar2                  concept/description/relationship domain map source flag
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/28
    ********************************************************************************************/
    FUNCTION get_domain_map_source
    (
        i_source          IN mcs_source.id_mcs_source%TYPE,
        i_domain_trg_flag IN VARCHAR2,
        i_domain_code     IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get concept/description/relation domain map description flag from a given source
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_domain_flag             concept/description/relation status/type flag
    * @param       i_domain_code             concept/description/relation domain code
    *
    * @return      varchar2                  concept/description/relationship domain map flag description
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/25
    ********************************************************************************************/
    FUNCTION get_domain_map_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_source      IN mcs_source.id_mcs_source%TYPE,
        i_domain_flag IN VARCHAR2,
        i_domain_code IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get criteria text for lucene lcontains function use
    *
    * @param       i_source                  source where the criteria text condition is applied
    * @param       i_text                    text to use in criteria text condition build
    * @param       i_operator                operator to be used between words
    *
    * @return      varchar2                  lcontaints text condition
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/26
    ********************************************************************************************/
    FUNCTION get_criteria_text
    (
        i_source   IN mcs_source.id_mcs_source%TYPE,
        i_text     IN VARCHAR2,
        i_operator IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get all child concepts from a given source/concepts
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concepts                array of concepts id/code
    * @param       i_concept_status          required concepts status
    * @param       i_relationship_type       relationship_type
    * @param       o_concepts                cursor with all child concepts
    * @param       o_error                   error structure and message
    *
    * @value       i_concept_status          {*} '*' All concepts, including outdated records
    *                                        {*} 'A' Only "available for use" concepts  
    *                                        {*} 'I' Only "inactive" concepts  
    *                                        {*} DEF When not specified, i_concept_status = 'A'
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/28
    ********************************************************************************************/
    FUNCTION get_child_concepts
    (
        i_lang              IN language.id_language%TYPE,
        i_source            IN mcs_source.id_mcs_source%TYPE,
        i_concepts          IN table_varchar,
        i_concept_status    IN VARCHAR2 DEFAULT 'A',
        i_relationship_type IN VARCHAR2 DEFAULT 'IS_A',
        o_concepts          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all parent concepts from a given source/concepts
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concepts                array of concepts id/code
    * @param       i_concept_status          required concepts status
    * @param       i_relationship_type       relationship_type
    * @param       o_concepts                cursor with all parent concepts
    * @param       o_error                   error structure and message
    *
    * @value       i_concept_status          {*} '*' All concepts, including outdated records
    *                                        {*} 'A' Only "available for use" concepts  
    *                                        {*} 'I' Only "inactive" concepts  
    *                                        {*} DEF When not specified, i_concept_status = 'A'
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/28
    ********************************************************************************************/
    FUNCTION get_parent_concepts
    (
        i_lang              IN language.id_language%TYPE,
        i_source            IN mcs_source.id_mcs_source%TYPE,
        i_concepts          IN table_varchar,
        i_concept_status    IN VARCHAR2 DEFAULT 'A',
        i_relationship_type IN VARCHAR2 DEFAULT 'IS_A',
        o_concepts          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get parent and child concepts from a given source/concepts
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concepts                array of concepts id/code
    * @param       i_concept_status          required concepts status
    * @param       i_relationship_type       relationship_type
    * @param       o_concepts                cursor with all parent and child concepts
    * @param       o_error                   error structure and message
    *
    * @value       i_concept_status          {*} '*' All concepts, including outdated records
    *                                        {*} 'A' Only "available for use" concepts  
    *                                        {*} 'I' Only "inactive" concepts  
    *                                        {*} DEF When not specified, i_concept_status = 'A'
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/29
    ********************************************************************************************/
    FUNCTION get_concepts_hierarchy
    (
        i_lang              IN language.id_language%TYPE,
        i_source            IN mcs_source.id_mcs_source%TYPE,
        i_concepts          IN table_varchar,
        i_concept_status    IN VARCHAR2 DEFAULT 'A',
        i_relationship_type IN VARCHAR2 DEFAULT 'IS_A',
        o_concepts          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all concepts descriptions from a given source/concepts
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concepts                array of concepts id/code
    * @param       i_description_status      required concepts description status
    * @param       o_concepts_desc           cursor with all available concept descriptions
    * @param       o_error                   error structure and message
    *
    * @value       i_description_status      {*} '*' All concept descriptions, including outdated records
    *                                        {*} 'A' Only "available for use" concept descriptions  
    *                                        {*} 'I' Only "inactive" concept descriptions 
    *                                        {*} DEF When not specified, i_description_status = 'A'
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/15
    ********************************************************************************************/
    FUNCTION get_concepts_descriptions
    (
        i_lang               IN language.id_language%TYPE,
        i_source             IN mcs_source.id_mcs_source%TYPE,
        i_concepts           IN table_varchar,
        i_description_status IN VARCHAR2 DEFAULT 'A',
        o_concepts_desc      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get concept description from a given source/concept
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concept                 concept id/code
    *
    * @return      varchar2                  returns description for given source/concept
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/02/09
    ********************************************************************************************/
    FUNCTION get_concept_description
    (
        i_lang    IN language.id_language%TYPE,
        i_source  IN mcs_source.id_mcs_source%TYPE,
        i_concept IN mcs_concept.id_mcs_concept%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get all concepts based in given search filter
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_text_filter             search text filter
    * @param       i_concept_status          required concept status
    * @param       i_description_status      required description status
    * @param       i_rows_limit              limit for o_concepts cursor rows returned by this function 
    * @param       i_operator                operator used between terms used in text filter
    * @param       i_highlight               highlight keywords used in text search
    * @param       o_concepts                cursor with all available concepts/descriptions
    * @param       o_error                   error structure and message
    *
    * @value       i_concept_status          {*} '*' All concepts, including outdated records
    *                                        {*} 'A' Only "available for use" concepts   
    *                                        {*} 'I' Only "inactive" concepts 
    *                                        {*} DEF When not specified, i_concept_status = 'A'
    *
    * @value       i_description_status      {*} '*' All descriptions, including outdated records
    *                                        {*} 'A' Only "available for use" descriptions   
    *                                        {*} 'I' Only "inactive" descriptions 
    *                                        {*} DEF When not specified, i_description_status = 'A'
    *
    * @value       i_operator                {*} 'AND' AND operator used between terms of text filter
    *                                        {*} 'OR'  OR operator used between terms of text filter    
    *                                        {*} DEF When not specified, i_operator = 'AND'
    *
    * @value       i_rows_limit              {*} 0 Returns all available records
    *                                        {*} >X Returns a number of X limited rows    
    *                                        {*} DEF When not specified, i_rows_limit = 0
    *
    * @value       i_highlight               {*} 'Y' keywords used in text search are highlighted
    *                                        {*} 'N' keywords used in text search are displayed with no format    
    *                                        {*} DEF When not specified, i_highlight = 'N'
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/01/27
    ********************************************************************************************/
    FUNCTION get_concepts_by_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_source             IN mcs_source.id_mcs_source%TYPE,
        i_text_filter        IN VARCHAR2,
        i_concept_status     IN VARCHAR2 DEFAULT 'A',
        i_description_status IN VARCHAR2 DEFAULT 'A',
        i_rows_limit         IN NUMBER DEFAULT 0,
        i_operator           IN VARCHAR2 DEFAULT 'AND',
        i_highlight          IN VARCHAR2 DEFAULT 'N',
        o_concepts           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get concept laterality from a given source/concept
    *
    * @param       i_lang                    language id
    * @param       i_source                  standard source id
    * @param       i_concept                 concept id/code
    *
    * @return      varchar2                  returns laterality concept from a given source/concept
    *                                        null if not found
    *
    * @author                                Carlos Loureiro
    * @since                                 17-JUL-2012
    ********************************************************************************************/
    FUNCTION get_concept_laterality
    (
        i_source  IN mcs_source.id_mcs_source%TYPE,
        i_concept IN mcs_concept.id_mcs_concept%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- parent/child indicators
    g_hierarchy_parent CONSTANT VARCHAR2(1) := 'P';
    g_hierarchy_child  CONSTANT VARCHAR2(1) := 'C';

    -- domain map codes
    g_dmap_concept_status     CONSTANT mcs_domain_map.code_mcs_domain_map%TYPE := 'MCS_CONCEPT_CONCEPT_STATUS';
    g_dmap_description_status CONSTANT mcs_domain_map.code_mcs_domain_map%TYPE := 'MCS_DESCRIPTION_DESCRIPTION_STATUS';
    g_dmap_description_type   CONSTANT mcs_domain_map.code_mcs_domain_map%TYPE := 'MCS_DESCRIPTION_DESCRIPTION_TYPE';
    g_dmap_relationship_type  CONSTANT mcs_domain_map.code_mcs_domain_map%TYPE := 'MCS_RELATIONSHIP_RELATIONSHIP_TYPE';

    -- domain map values
    g_dmap_description_status_a   CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'A'; -- active term
    g_dmap_description_status_i   CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'I'; -- inactive term
    g_dmap_description_status_all CONSTANT mcs_domain_map.flg_domain_trg%TYPE := '*'; -- active or inactive term

    g_dmap_concept_status_a   CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'A'; -- active concept
    g_dmap_concept_status_i   CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'I'; -- inactive concept
    g_dmap_concept_status_all CONSTANT mcs_domain_map.flg_domain_trg%TYPE := '*'; -- active or inactive concept

    g_dmap_description_type_p CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'P'; -- preferred term
    g_dmap_description_type_f CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'F'; -- full specified term
    g_dmap_description_type_s CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'S'; -- synonym term
    g_dmap_description_type_u CONSTANT mcs_domain_map.flg_domain_trg%TYPE := 'U'; -- unspecified term

    -- general error descriptions
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_mcs;
/
