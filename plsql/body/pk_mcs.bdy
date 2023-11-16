/*-- Last Change Revision: $Rev: 2027346 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_mcs IS

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
    FUNCTION get_translation_column(i_lang IN language.id_language%TYPE) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'TRANSLATION_' || to_char(i_lang);
    END get_translation_column;

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
    ) RETURN VARCHAR2 IS
        l_domain_map mcs_domain_map.flg_domain_trg%TYPE;
    
    BEGIN
        SELECT dm.flg_domain_trg
          INTO l_domain_map
          FROM mcs_domain_map dm
         WHERE dm.id_mcs_source = i_source
           AND dm.code_mcs_domain_map = i_domain_code
           AND dm.flg_domain_src = i_domain_flag;
    
        RETURN l_domain_map;
    END get_domain_map;

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
    ) RETURN VARCHAR2 IS
        l_domain_map_source mcs_domain_map.flg_domain_src%TYPE;
    
    BEGIN
        SELECT dm.flg_domain_src
          INTO l_domain_map_source
          FROM mcs_domain_map dm
         WHERE dm.id_mcs_source = i_source
           AND dm.code_mcs_domain_map = i_domain_code
           AND dm.flg_domain_trg = i_domain_trg_flag;
    
        RETURN l_domain_map_source;
    END get_domain_map_source;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysdomain.get_domain(i_domain_code, get_domain_map(i_source, i_domain_flag, i_domain_code), i_lang);
    END get_domain_map_desc;

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
    ) RETURN VARCHAR2 IS
        l_input  VARCHAR2(4000);
        l_output VARCHAR2(4000);
        l_aux    table_varchar;
    BEGIN
        l_input := TRIM(i_text);
        IF l_input IS NOT NULL
        THEN
            l_aux := pk_utils.str_split_l(i_list => l_input);
            IF l_aux.count > 1
            THEN
                FOR i IN 1 .. l_aux.count - 1
                LOOP
                    IF l_aux(i) <> ' '
                    THEN
                        l_output := l_output || TRIM(l_aux(i)) || ' ' || i_operator || ' ';
                    END IF;
                END LOOP;
                l_output := l_output || l_aux(l_aux.count);
            ELSE
                l_output := l_input;
            END IF;
        END IF;
        RETURN '(' || l_output || ') AND id_mcs_source:' || to_char(i_source);
    END get_criteria_text;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_relationship_type mcs_relationship.relationship_type%TYPE;
    BEGIN
        -- validation of required concept status filter
        IF i_concept_status NOT IN (g_dmap_concept_status_all, g_dmap_concept_status_a, g_dmap_concept_status_i)
        THEN
            -- invalid concept status  
            g_error := 'invalid i_concept_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSE
            -- get relationship type concept
            l_relationship_type := get_domain_map_source(i_source, i_relationship_type, g_dmap_relationship_type);
        
            g_error := 'open o_concepts cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts FOR
                SELECT /*+ opt_estimate(table concepts rows=1) */
                 concepts.id_concept AS concept_id,
                 c.id_mcs_concept AS concept_id_child,
                 get_domain_map(i_source, c.concept_status, g_dmap_concept_status) AS concept_status
                  FROM (SELECT column_value AS id_concept
                          FROM TABLE(i_concepts)) concepts
                  JOIN mcs_relationship r
                    ON r.id_mcs_source = i_source
                   AND r.id_mcs_concept_2 = concepts.id_concept
                   AND r.relationship_type = l_relationship_type
                  JOIN mcs_concept c
                    ON c.id_mcs_source = r.id_mcs_source
                   AND c.id_mcs_concept = r.id_mcs_concept_1
                 WHERE (i_concept_status = g_dmap_concept_status_all OR
                       get_domain_map(i_source, c.concept_status, g_dmap_concept_status) = i_concept_status)
                 ORDER BY concept_id;
        
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
                                              'GET_CHILD_CONCEPTS',
                                              o_error);
            pk_types.open_my_cursor(o_concepts);
            RETURN FALSE;
        
    END get_child_concepts;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_relationship_type mcs_relationship.relationship_type%TYPE;
    
    BEGIN
        -- validation of required concept status filter
        IF i_concept_status NOT IN (g_dmap_concept_status_all, g_dmap_concept_status_a, g_dmap_concept_status_i)
        THEN
            -- invalid concept status  
            g_error := 'invalid i_concept_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSE
            -- get relationship type concept
            l_relationship_type := get_domain_map_source(i_source, i_relationship_type, g_dmap_relationship_type);
        
            g_error := 'open o_concepts cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts FOR
                SELECT /*+ opt_estimate(table concepts rows=1) */
                 concepts.id_concept AS concept_id,
                 c.id_mcs_concept AS concept_id_child,
                 get_domain_map(i_source, c.concept_status, g_dmap_concept_status) AS concept_status
                  FROM (SELECT column_value AS id_concept
                          FROM TABLE(i_concepts)) concepts
                  JOIN mcs_relationship r
                    ON r.id_mcs_source = i_source
                   AND r.id_mcs_concept_1 = concepts.id_concept
                   AND r.relationship_type = l_relationship_type
                  JOIN mcs_concept c
                    ON c.id_mcs_source = r.id_mcs_source
                   AND c.id_mcs_concept = r.id_mcs_concept_2
                 WHERE (i_concept_status = g_dmap_concept_status_all OR
                       get_domain_map(i_source, c.concept_status, g_dmap_concept_status) = i_concept_status)
                 ORDER BY concept_id;
        
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
                                              'GET_PARENT_CONCEPTS',
                                              o_error);
            pk_types.open_my_cursor(o_concepts);
            RETURN FALSE;
        
    END get_parent_concepts;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_relationship_type mcs_relationship.relationship_type%TYPE;
    
    BEGIN
        -- validation of required concept status filter
        IF i_concept_status NOT IN (g_dmap_concept_status_all, g_dmap_concept_status_a, g_dmap_concept_status_i)
        THEN
            -- invalid concept status  
            g_error := 'invalid i_concept_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSE
            -- get relationship type concept
            l_relationship_type := get_domain_map_source(i_source, i_relationship_type, g_dmap_relationship_type);
        
            g_error := 'open o_concepts cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts FOR
                SELECT /*+ opt_estimate(table concepts rows=1) */
                 concepts.id_concept AS concept_id,
                 g_hierarchy_child AS hierarchy_flag,
                 c.id_mcs_concept AS concept_id_child,
                 get_domain_map(i_source, c.concept_status, g_dmap_concept_status) AS concept_status
                  FROM (SELECT column_value AS id_concept
                          FROM TABLE(i_concepts)) concepts
                  JOIN mcs_relationship r
                    ON r.id_mcs_source = i_source
                   AND r.id_mcs_concept_2 = concepts.id_concept
                   AND r.relationship_type = l_relationship_type
                  JOIN mcs_concept c
                    ON c.id_mcs_source = r.id_mcs_source
                   AND c.id_mcs_concept = r.id_mcs_concept_1
                 WHERE (i_concept_status = g_dmap_concept_status_all OR
                       get_domain_map(i_source, c.concept_status, g_dmap_concept_status) = i_concept_status)
                UNION ALL
                SELECT /*+ opt_estimate(table concepts rows=1) */
                 concepts.id_concept AS concept_id,
                 g_hierarchy_parent AS hierarchy_flag,
                 c.id_mcs_concept AS concept_id_child,
                 get_domain_map(i_source, c.concept_status, g_dmap_concept_status) AS concept_status
                  FROM (SELECT column_value AS id_concept
                          FROM TABLE(i_concepts)) concepts
                  JOIN mcs_relationship r
                    ON r.id_mcs_source = i_source
                   AND r.id_mcs_concept_1 = concepts.id_concept
                   AND r.relationship_type = l_relationship_type
                  JOIN mcs_concept c
                    ON c.id_mcs_source = r.id_mcs_source
                   AND c.id_mcs_concept = r.id_mcs_concept_2
                 WHERE (i_concept_status = g_dmap_concept_status_all OR
                       get_domain_map(i_source, c.concept_status, g_dmap_concept_status) = i_concept_status)
                 ORDER BY hierarchy_flag, concept_id;
        
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
                                              'GET_CONCEPTS_HIERARCHY',
                                              o_error);
            pk_types.open_my_cursor(o_concepts);
            RETURN FALSE;
        
    END get_concepts_hierarchy;

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
    ) RETURN BOOLEAN IS
        l_sql VARCHAR2(4000);
        l_exception EXCEPTION;
    
    BEGIN
        -- validation of required description filter
        IF i_description_status NOT IN
           (g_dmap_description_status_all, g_dmap_description_status_a, g_dmap_description_status_i)
        THEN
            -- invalid description status  
            g_error := 'invalid i_description_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSE
            -- fetch data from database    
            g_error := 'build sql instruction';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_sql := 'SELECT id_mcs_concept AS concept_id, id_mcs_description AS description_id, ' ||
                     'pk_mcs.get_domain_map(:id_source, d.description_status, :dmap_description_status) AS description_status, ' ||
                     'pk_mcs.get_domain_map(:id_source, d.description_type, :dmap_description_type) AS description_type, ' ||
                     get_translation_column(i_lang) ||
                     ' AS term FROM mcs_description d WHERE d.id_mcs_source = :id_source ' ||
                     'AND d.id_mcs_concept IN (SELECT /*+opt_estimate(table c rows=1)*/ column_value FROM TABLE(:id_concepts) c) ' ||
                     'AND (:description_status = :dmap_description_status_all OR pk_mcs.get_domain_map(:id_source, d.description_status, :dmap_description_status) = :description_status) ' ||
                     'ORDER BY id_mcs_concept, decode(description_type, :dmap_description_type_p, 3, :dmap_description_type_f, 2, :dmap_description_type_s, 1, 0) desc';
        
            g_error := 'open o_concepts_desc cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts_desc FOR l_sql
                USING i_source, g_dmap_description_status, i_source, g_dmap_description_type, i_source, i_concepts, i_description_status, g_dmap_description_status_all, i_source, g_dmap_description_status, i_description_status, g_dmap_description_type_p, g_dmap_description_type_f, g_dmap_description_type_s;
        
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
                                              'GET_CONCEPT_DESCRIPTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_concepts_desc);
            RETURN FALSE;
        
    END get_concepts_descriptions;

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
    ) RETURN VARCHAR2 IS
        l_concept_desc_list pk_types.cursor_type;
        l_error             t_error_out;
        l_exception EXCEPTION;
        l_concept_id         mcs_concept.id_mcs_concept%TYPE;
        l_description_id     mcs_description.id_mcs_description%TYPE;
        l_description_status mcs_domain_map.flg_domain_trg%TYPE;
        l_description_type   mcs_domain_map.flg_domain_trg%TYPE;
        l_concept_desc       mcs_concept.concept_description%TYPE;
    
    BEGIN
        -- get all descriptions for given concept
        IF NOT get_concepts_descriptions(i_lang,
                                         i_source,
                                         table_varchar(i_concept),
                                         g_dmap_description_status_a,
                                         l_concept_desc_list,
                                         l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- the 1st record contains the most suitable description for the given source/concept
        g_error := 'get 1st record from cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FETCH l_concept_desc_list
            INTO l_concept_id, l_description_id, l_description_status, l_description_type, l_concept_desc;
        CLOSE l_concept_desc_list;
    
        RETURN l_concept_desc;
    
    END get_concept_description;

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
    ) RETURN BOOLEAN IS
        l_sql VARCHAR2(4000);
        l_exception EXCEPTION;
    
    BEGIN
        -- validation of required status filters    
        IF i_description_status NOT IN
           (g_dmap_description_status_all, g_dmap_description_status_a, g_dmap_description_status_i)
        THEN
            -- invalid description status  
            g_error := 'invalid i_description_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSIF i_concept_status NOT IN (g_dmap_concept_status_all, g_dmap_concept_status_a, g_dmap_concept_status_i)
        THEN
            -- invalid concept status  
            g_error := 'invalid i_concept_status';
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        
        ELSIF TRIM(i_text_filter) IS NULL
        THEN
            -- empty text filter (no data to return)
            g_error := 'open empty o_concepts cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts FOR
                SELECT NULL AS concept_id,
                       NULL AS description_id,
                       NULL AS concept_status,
                       NULL AS description_status,
                       NULL AS description_type,
                       NULL AS term,
                       NULL AS score_pct
                  FROM dual
                 WHERE 0 = 1;
        
        ELSE
            -- fetch data from database        
            g_error := 'build sql instruction';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            l_sql := 'SELECT * FROM (SELECT /*+ ordered use_nl(d c) */ c.id_mcs_concept AS concept_id, d.id_mcs_description AS description_id, ' ||
                     'pk_mcs.get_domain_map(:id_source, c.concept_status, :dmap_concept_status) AS concept_status, ' ||
                     'pk_mcs.get_domain_map(:id_source, d.description_status, :dmap_description_status) AS description_status, ' ||
                     'pk_mcs.get_domain_map(:id_source, d.description_type, :dmap_description_type) AS description_type, ' ||
                     'decode(:highlight, :boolean, lhighlight(1), ' || get_translation_column(i_lang) ||
                     ') AS term, trunc(lscore(1) * 100,1) AS score_pct FROM mcs_description d ' ||
                     'JOIN mcs_concept c ON c.id_mcs_source = d.id_mcs_source AND c.id_mcs_concept = d.id_mcs_concept ' ||
                     'WHERE lcontains(' || get_translation_column(i_lang) ||
                     ', pk_mcs.get_criteria_text(:id_source,:text_filter,:operator), 1) > 0 ' ||
                     'AND (:concept_status = :dmap_concept_status_all OR pk_mcs.get_domain_map(:id_source, concept_status, :dmap_concept_status) = :concept_status) ' ||
                     'AND (:description_status = :dmap_description_status_all OR pk_mcs.get_domain_map(:id_source, description_status, :dmap_description_status) = :description_status) ' ||
                     'ORDER BY score_pct DESC, description_type, term) WHERE (:rows_limit = 0 OR rownum <= :rows_limit)';
        
            g_error := 'open o_concepts cursor';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_concepts FOR l_sql
                USING i_source, g_dmap_concept_status, i_source, g_dmap_description_status, i_source, g_dmap_description_type, i_highlight, pk_alert_constant.g_yes, i_source, i_text_filter, i_operator, i_concept_status, g_dmap_concept_status_all, i_source, g_dmap_concept_status, i_concept_status, i_description_status, g_dmap_description_status_all, i_source, g_dmap_description_status, i_description_status, i_rows_limit, i_rows_limit;
        
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
                                              'GET_CONCEPTS_BY_DESC',
                                              o_error);
            pk_types.open_my_cursor(o_concepts);
            RETURN FALSE;
        
    END get_concepts_by_desc;

    /********************************************************************************************
    * get concept laterality from a given source/concept
    *
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
    ) RETURN VARCHAR2 IS
        l_laterality_relationship mcs_concept.id_mcs_concept%TYPE;
        l_laterality_concept      mcs_concept.id_mcs_concept%TYPE;
    BEGIN
        -- get "laterality" relationship concept for given source
        l_laterality_relationship := get_domain_map_source(i_source, 'LATERALITY', g_dmap_relationship_type);
    
        -- get "laterality" concept from given concept/source
        SELECT r.id_mcs_concept_2
          INTO l_laterality_concept
          FROM mcs_relationship r
          JOIN mcs_concept c
            ON c.id_mcs_source = r.id_mcs_source
           AND c.id_mcs_concept = r.id_mcs_concept_2
           AND get_domain_map(i_source, c.concept_status, g_dmap_concept_status) = g_dmap_concept_status_a
         WHERE r.id_mcs_concept_1 = i_concept
           AND r.relationship_type = l_laterality_relationship
           AND r.id_mcs_source = i_source;
    
        RETURN l_laterality_concept;
    
    EXCEPTION
        -- if laterality records not found, then return null
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_concept_laterality;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_mcs;
/
