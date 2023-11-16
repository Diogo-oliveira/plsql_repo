/*-- Last Change Revision: $Rev: 2027338 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_mapping_sets IS

    -- ############################################################################################ --
    -- ### API FUNCTIONS AND PROCEDURES ########################################################### --
    -- ############################################################################################ --

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_map_concept        mapping concept id
    * @param i_mcs_source         standard id on medical classification system data model (used to get concept descriptions)     
    * @param o_error              error structure and message
    *
    * @return                     string with the pre or post-coordinated expression of the concept
    *
    * @author                     Tiago Silva
    * @since                      2011/03/11
    ********************************************************************************************/
    FUNCTION get_concept_coordination_expr
    (
        i_lang        IN language.id_language%TYPE,
        i_map_concept IN xmap_concept.id_map_concept%TYPE,
        i_mcs_source  IN mcs_source.id_mcs_source%TYPE
    ) RETURN VARCHAR2 IS
    
        -- variables used to fetch a mapped concept
        l_level              NUMBER(6);
        l_id_mapping_targets VARCHAR2(1000 CHAR);
        l_concept_order      xmap_concept.concept_order%TYPE;
        l_flg_cav            xmap_concept.concept_type%TYPE;
        l_concept_group      xmap_concept.concept_group%TYPE;
    
        -- auxiliary parsing variables
        l_parsed_concept   VARCHAR2(1000 CHAR);
        l_last_cav         VARCHAR2(1 CHAR);
        l_last_group       NUMBER(6);
        l_last_level       NUMBER(6);
        l_open_parenthesis NUMBER(6);
        l_group_limit      VARCHAR2(30 CHAR);
        l_comma            VARCHAR2(1 CHAR);
        l_join_limit       VARCHAR2(1 CHAR);
        l_index            NUMBER(6);
        l_index_level      NUMBER(6);
        l_loop             NUMBER(6);
        l_changed_group    VARCHAR2(1 CHAR);
        l_pos_last_concept NUMBER(6);
    
        l_stack_group table_number;
        l_stack_level table_number;
    
        -- cursor that returns the concepts that compose the mapping
        c_mapping_concepts pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'Parse the SNOMED Mapping';
    
        l_parsed_concept   := '';
        l_last_cav         := '';
        l_last_group       := 0;
        l_last_level       := -1;
        l_open_parenthesis := 0;
        l_group_limit      := '';
        l_comma            := '';
        l_join_limit       := '';
        l_index            := 0;
        l_index_level      := 0;
        l_loop             := 0;
        l_changed_group    := '';
        l_pos_last_concept := 0;
    
        g_error := 'create the array that simulates the group stack';
    
        -- create the array that simulates the group stack
        l_stack_group := table_number();
    
        g_error := 'create the array that simulates the level stack';
    
        -- create the array that simulates the level stack
        l_stack_level := table_number();
    
        -- get mapping concepts
        g_error := 'get mapping concepts';
    
        OPEN c_mapping_concepts FOR
            SELECT LEVEL,
                   xmt.map_target_code ||
                   nvl2(i_mcs_source,
                        '|' || pk_mcs.get_concept_description(i_lang, i_mcs_source, xmt.map_target_code) || '|',
                        NULL) AS mapping_targets,
                   xmc.concept_order AS concept_order,
                   xmc.concept_type AS flg_cav,
                   nvl(xmc.concept_group, 0) AS concept_group
              FROM xmap_concept xmc
             INNER JOIN xmap_target xmt
                ON xmc.id_map_target = xmt.id_map_target
            CONNECT BY PRIOR xmc.id_map_concept = xmc.id_map_concept_parent
             START WITH xmc.id_map_concept = i_map_concept;
    
        g_error := 'first fetch on the cursor';
    
        FETCH c_mapping_concepts
            INTO l_level, l_id_mapping_targets, l_concept_order, l_flg_cav, l_concept_group;
    
        g_error := 'starting the cursor reading loop';
    
        WHILE c_mapping_concepts%FOUND
        LOOP
        
            g_error := 'process the element';
        
            IF l_last_cav = ''
            THEN
                g_error := 'initialize the first concept';
                -- initialize the string on the first concept;
                -- note: even if two "C" concepts are joined
                --       in the beginning, there will be no
                --       "(...)" surrounding them;
                l_parsed_concept := l_id_mapping_targets;
                l_last_cav       := l_flg_cav;
                l_last_group     := l_concept_group;
                l_last_level     := l_level;
            ELSE
                IF (l_flg_cav = l_last_cav)
                THEN
                    g_error := 'components of the same kind';
                    -- components of the same kind; use "+" to join them;
                    l_parsed_concept := l_parsed_concept || '+' || l_id_mapping_targets;
                    -- joined expressions, when of "V" kind, are surrounded by "(...)";
                    IF l_flg_cav = 'V'
                    THEN
                        l_parsed_concept := substr(l_parsed_concept, 1, l_pos_last_concept - 1) || '(' ||
                                            substr(l_parsed_concept, l_pos_last_concept) || ')';
                    END IF;
                ELSE
                    g_error := 'components of different kind';
                    -- check for group change;
                    -- very important notice: since the last group é updated to the current group before the testing
                    --                        made when changing from "V" to "A", implying that the comparison between
                    --                        the last and the current would always be equal, there is the need to
                    --                        keep the result from the comparison in a flag, which will be tested
                    --                        below;
                    IF l_concept_group <> l_last_group
                    THEN
                        g_error := 'group change';
                        --l_changed_group := 'Y';
                        l_group_limit := '';
                        -- close the previous group (is if exists) only if the level was kept or
                        -- has returned to an upper level in the structure;
                        IF (l_last_group <> 0 AND l_level <= l_last_level)
                        THEN
                            -- if the group is closed it is as if it was back on
                            -- the last group, so it must be signaled as if no
                            -- change has occurred;
                            l_changed_group := 'N';
                            g_error         := 'close the group';
                            l_group_limit   := '}';
                        
                            IF (l_open_parenthesis > 0)
                            THEN
                                g_error            := 'close the joined expression';
                                l_group_limit      := l_group_limit || ')';
                                l_open_parenthesis := l_open_parenthesis - 1;
                            END IF;
                            -- remove the closed group from the stack;
                            -- if there are any more groups in the stack,
                            -- the most recent one must be considered as
                            -- the last one;
                            g_error := 'remove the group from the stack';
                            l_stack_group.delete(l_index);
                            l_index := l_index - 1;
                            IF l_index > 0
                            THEN
                                l_last_group := l_stack_group(l_index);
                            ELSE
                                l_last_group := 0;
                            END IF;
                        
                            -- remove the last level from the stack;
                            -- if there are any more levels in the stack,
                            -- the most recent one must be considered as
                            -- the last one;
                            g_error := 'remove the level from the stack';
                            l_stack_level.delete(l_index_level);
                            l_index_level := l_index_level - 1;
                            IF l_index_level > 0
                            THEN
                                l_last_level := l_stack_level(l_index_level);
                            ELSE
                                l_last_level := 0;
                            END IF;
                        
                        END IF;
                        -- open a new group;
                        IF (l_concept_group <> 0 AND l_level > l_last_level)
                        THEN
                            -- the group changed and must be signaled as such;
                            l_changed_group := 'Y';
                        
                            g_error := 'close a join before opening a new group';
                            IF (l_open_parenthesis > 0)
                            THEN
                                l_group_limit      := l_group_limit || ')';
                                l_open_parenthesis := l_open_parenthesis - 1;
                            END IF;
                            g_error       := 'open a new group';
                            l_group_limit := l_group_limit || '{';
                            -- register in the stack the creation of an open group;
                            l_index := l_index + 1;
                            l_stack_group.extend;
                            l_stack_group(l_index) := l_concept_group;
                            l_last_group := l_concept_group;
                        
                            -- register in the stack the creation of level;
                            l_index_level := l_index_level + 1;
                            l_stack_level.extend;
                            l_stack_level(l_index_level) := l_level;
                            l_last_level := l_level;
                        END IF;
                    ELSE
                        g_error         := 'no group was changed';
                        l_changed_group := 'N';
                    END IF;
                    -- change of component; test the sequence of the change;
                    g_error := 'test the sequence of the component change';
                    IF l_last_cav = 'C'
                    THEN
                        g_error          := 'last component was C';
                        l_parsed_concept := l_parsed_concept || ':';
                    END IF;
                
                    IF l_last_cav = 'A'
                    THEN
                        g_error := 'last component was A';
                        IF l_flg_cav = 'C'
                        THEN
                            g_error            := 'last component was A and new one is C';
                            l_join_limit       := '(';
                            l_open_parenthesis := l_open_parenthesis + 1;
                        END IF;
                        l_parsed_concept := l_parsed_concept || '=' || l_join_limit;
                    END IF;
                
                    IF l_last_cav = 'V'
                    THEN
                        g_error := 'last component was V';
                        -- it is not possible that a "V" follows an "A";
                        -- the next test is a redundant one;
                        IF l_flg_cav = 'A'
                        THEN
                            g_error := 'last component was V and new one is A';
                            IF (l_changed_group = 'N' /*AND l_concept_group <> ''*/
                               )
                            THEN
                                --l_parsed_concept := l_parsed_concept || ',';
                                l_comma := ',';
                            END IF;
                        END IF;
                    END IF;
                
                    g_error := 'compose the parsed concept';
                    -- keep the position of the next concept to be written;
                    -- it will be needed in case joined values occur, since
                    -- there will be the need to go back on the string and
                    -- insert a "("; the position of that insertion is the
                    -- same where the previous concept was;
                    -- in order to do so, the composition of the string must
                    -- be separated, to isolate the new concept;                    
                    l_parsed_concept   := l_parsed_concept || l_group_limit || l_comma;
                    l_pos_last_concept := length(l_parsed_concept) + 1;
                    l_parsed_concept   := l_parsed_concept || l_id_mapping_targets;
                
                END IF;
            
                l_last_cav := l_flg_cav;
                --l_last_level  := l_level;
                l_group_limit := '';
                l_join_limit  := '';
                l_comma       := '';
            
            END IF;
        
            g_error := 'fetch the next element in the cursor';
            FETCH c_mapping_concepts
                INTO l_level, l_id_mapping_targets, l_concept_order, l_flg_cav, l_concept_group;
        
        END LOOP;
        -- close the string. se there are any groups or joins left open;
        -- very important notice: it is assumed that there may be more than one
        --                        open join and that they are gathered and come
        --                        before an open group; it is also assumed that
        --                        only one group may be still be opened after the
        --                        last element on the mapping is read; 
        g_error := 'close the string: joined expressions';
        FOR l_loop IN 1 .. l_open_parenthesis
        LOOP
            l_parsed_concept := l_parsed_concept || ')';
        END LOOP;
    
        g_error := 'close the string: group';
        IF l_index > 0
        THEN
            l_parsed_concept := l_parsed_concept || '}';
        END IF;
    
        RETURN l_parsed_concept;
    END get_concept_coordination_expr;

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept descriptions)
    * @param o_target_concepts    cursor with all target concepts
    * @param o_error              error structure and message
    *
    * @return                     true or false on success or error
    *
    * @author                     Tiago Silva
    * @since                      2011/03/11
    ********************************************************************************************/
    FUNCTION get_mapping_concepts
    (
        i_lang            IN language.id_language%TYPE,
        i_source_concept  IN VARCHAR2,
        i_source_map_set  IN xmap_set.id_map_set%TYPE,
        i_target_map_set  IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src  IN mcs_source.id_mcs_source%TYPE DEFAULT NULL,
        o_target_concepts OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get mapping concepts';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get target concepts
        OPEN o_target_concepts FOR
            SELECT trg_xms.map_set_name AS target_map_set_name,
                   trg_xms.map_set_version AS target_map_set_version,
                   get_concept_coordination_expr(i_lang, xmr.id_target_map_concept, i_target_mcs_src) AS target_coordination_expr,
                   xmr.id_source_map_concept,
                   xmr.id_target_map_concept,
                   xmr.id_target_map_set,
                   xmr.map_category,
                   xmr.map_option,
                   xmr.map_priority,
                   xmr.map_quality,
                   xmr.map_creation_date,
                   xmr.map_enable_date
              FROM xmap_relationship xmr
             INNER JOIN xmap_set trg_xms
                ON xmr.id_target_map_set = trg_xms.id_map_set
             WHERE xmr.id_source_map_set = i_source_map_set
               AND xmr.id_target_map_set = nvl(i_target_map_set, xmr.id_target_map_set)
               AND xmr.map_status = g_xmr_active
               AND xmr.source_coordinated_expr = TRIM(i_source_concept);
    
        RETURN TRUE;
    EXCEPTION
        -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MAPPING_CONCEPTS',
                                              o_error);
        
            pk_types.open_my_cursor(o_target_concepts);
            RETURN FALSE;
        
    END get_mapping_concepts;

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_source_concept     list of strings string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept descriptions)
    * @param o_target_concepts    cursor with all target concepts
    * @param o_error              error structure and message
    *
    * @return                     true or false on success or error
    *
    * @author                     Sofia Mendes
    * @since                      2011/03/11
    ********************************************************************************************/
    FUNCTION tf_get_mapping_concepts
    (
        i_lang           IN language.id_language%TYPE,
        i_source_concept IN table_varchar,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src IN mcs_source.id_mcs_source%TYPE DEFAULT NULL
    ) RETURN t_table_mapping_conc IS
    
        CURSOR c_map_conc IS
            SELECT xmr.source_coordinated_expr source_coordinated_expr,
                   xmr.target_coordinated_expr,
                   pk_mcs.get_concept_description(i_lang, i_target_mcs_src, xmr.target_coordinated_expr) target_map_concept_desc,
                   xmr.map_priority
              FROM xmap_relationship xmr
             INNER JOIN xmap_set trg_xms
                ON xmr.id_target_map_set = trg_xms.id_map_set
             INNER JOIN (SELECT /*+opt_estimate(table,sc,scale_rows=0.1)*/
                          TRIM(column_value) source_concept
                           FROM TABLE(i_source_concept) sc) tsc
                ON tsc.source_concept = xmr.source_coordinated_expr
             WHERE xmr.id_source_map_set = i_source_map_set
               AND xmr.id_target_map_set = nvl(i_target_map_set, xmr.id_target_map_set)
               AND xmr.map_status = g_xmr_active
             ORDER BY xmr.map_priority;
    
        TYPE c_map_conc_tp IS TABLE OF c_map_conc%ROWTYPE;
        l_error t_error_out;
    
        l_table_mapping_conc        c_map_conc_tp := c_map_conc_tp();
        l_table_mapping_conc_struct t_table_mapping_conc := t_table_mapping_conc();
    
    BEGIN
        g_error := 'get mapping concepts';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_map_conc;
        LOOP
            g_error := 'FETCH MAPPING CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_map_conc BULK COLLECT
                INTO l_table_mapping_conc LIMIT 1000;
        
            FOR i IN 1 .. l_table_mapping_conc.count
            LOOP
                l_table_mapping_conc_struct.extend;
                l_table_mapping_conc_struct(l_table_mapping_conc_struct.last) := t_rec_mapping_conc(l_table_mapping_conc(i)
                                                                                                    .source_coordinated_expr,
                                                                                                    l_table_mapping_conc(i)
                                                                                                    .target_coordinated_expr,
                                                                                                    l_table_mapping_conc(i)
                                                                                                    .target_map_concept_desc,
                                                                                                    l_table_mapping_conc(i)
                                                                                                    .map_priority);
            END LOOP;
            EXIT WHEN c_map_conc%NOTFOUND;
        
        END LOOP;
    
        RETURN l_table_mapping_conc_struct;
    EXCEPTION
        -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_MAPPING_CONCEPTS',
                                              l_error);
        
            RETURN NULL;
    END tf_get_mapping_concepts;

	/********************************************************************************************
    * check if a given cross mapping is available for a software and institution
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_recurr_option  list of order recurrence option ids
    * @param       o_order_recurr_time    array of order recurrence times
    * @param       o_error                error structure for exception handling
    *
    * @return      varchar2               'Y' - cross mapping is available; 'N' - cross mapping is not available
    *
    * @author                             Tiago Silva
    * @since                              03-JUN-2011
    ********************************************************************************************/
    FUNCTION check_xmap_avail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN xmap_concept.id_map_concept%TYPE,
        i_target_concept IN xmap_concept.id_map_concept%TYPE,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE
    ) RETURN VARCHAR2 IS
        -- get institution market
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        l_count_results PLS_INTEGER;
    BEGIN
    
        g_error := 'get cross mapping availability';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT COUNT(1)
          INTO l_count_results
          FROM (SELECT first_value(xrmsi.flg_available) over(ORDER BY xrmsi.id_institution DESC, xrmsi.id_market DESC, xrmsi.id_software DESC) AS flg_available
                  FROM xmap_relationship_msi xrmsi
                 WHERE xrmsi.id_source_map_concept IN (g_xmc_all, i_source_concept)
                   AND xrmsi.id_target_map_concept IN (g_xmc_all, i_target_concept)
                   AND xrmsi.id_source_map_set IN (g_xms_all, i_source_map_set)
                   AND xrmsi.id_target_map_set IN (g_xms_all, i_target_map_set)
                   AND xrmsi.id_market IN (l_id_market, pk_alert_constant.g_id_market_all)
                   AND xrmsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND xrmsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all))
         WHERE flg_available = pk_alert_constant.g_yes;
    
        -- check result
        IF (l_count_results = 0)
        THEN
            -- not available
            RETURN pk_alert_constant.g_no;
        ELSE
            -- available
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    END check_xmap_avail;


    /********************************************************************************************
    * get concept code with given a source and a target mapping sets
    *
    * @param i_lang               preferred language id
    * @param i_prof               professional structure
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    *
    * @return                     target map concept code
    *
    * @author                     Carlos Loureiro
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_mapping_concept
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN VARCHAR2,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE
    ) RETURN VARCHAR2 IS
        l_code VARCHAR2(1000 CHAR);
        CURSOR c_target_concept IS
            SELECT xmt.map_target_code
              FROM xmap_relationship xmr
              JOIN xmap_set trg_xms
                ON xmr.id_target_map_set = trg_xms.id_map_set
              JOIN xmap_concept xmc
                ON xmc.id_map_concept = xmr.id_target_map_concept
              JOIN xmap_target xmt
                ON xmc.id_map_target = xmt.id_map_target
             WHERE xmr.id_source_map_set = i_source_map_set
               AND xmr.id_target_map_set = nvl(i_target_map_set, xmr.id_target_map_set)
               AND xmr.map_status = g_xmr_active
               AND xmr.source_coordinated_expr = TRIM(i_source_concept)
               AND check_xmap_avail(i_lang,
                                    i_prof,
                                    xmr.id_source_map_concept,
                                    xmr.id_target_map_concept,
                                    xmr.id_source_map_set,
                                    xmr.id_target_map_set) = pk_alert_constant.g_yes;
    
    BEGIN
        g_error := 'get target concept code';
        pk_alertlog.log_debug(g_error, g_package_name);
        -- get target concept description
        OPEN c_target_concept;
        FETCH c_target_concept
            INTO l_code;
        CLOSE c_target_concept;
        RETURN l_code;
    END get_mapping_concept;

    /********************************************************************************************
    * get concept description with given a source and a target mapping sets
    *
    * @param i_lang               preferred language id
    * @param i_prof               professional structure
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept description)
    *
    * @return                     target map concept description
    *
    * @author                     Carlos Loureiro
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_mapping_concept_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN VARCHAR2,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src IN mcs_source.id_mcs_source%TYPE
    ) RETURN VARCHAR2 IS
        l_code_description VARCHAR2(1000 CHAR);
        CURSOR c_target_concept IS
            SELECT pk_mcs.get_concept_description(i_lang, i_target_mcs_src, xmt.map_target_code)
              FROM xmap_relationship xmr
              JOIN xmap_set trg_xms
                ON xmr.id_target_map_set = trg_xms.id_map_set
              JOIN xmap_concept xmc
                ON xmc.id_map_concept = xmr.id_target_map_concept
              JOIN xmap_target xmt
                ON xmc.id_map_target = xmt.id_map_target
             WHERE xmr.id_source_map_set = i_source_map_set
               AND xmr.id_target_map_set = nvl(i_target_map_set, xmr.id_target_map_set)
               AND xmr.map_status = g_xmr_active
               AND xmr.source_coordinated_expr = TRIM(i_source_concept)
               AND check_xmap_avail(i_lang,
                                    i_prof,
                                    xmr.id_source_map_concept,
                                    xmr.id_target_map_concept,
                                    xmr.id_source_map_set,
                                    xmr.id_target_map_set) = pk_alert_constant.g_yes;
    BEGIN
        g_error := 'get target concept description';
        pk_alertlog.log_debug(g_error, g_package_name);
        -- get target concept description
        OPEN c_target_concept;
        FETCH c_target_concept
            INTO l_code_description;
        CLOSE c_target_concept;
        RETURN l_code_description;
    END get_mapping_concept_desc;

---------------------------------------------------------------------------------------------------------------------------

BEGIN

    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_mapping_sets;
/
