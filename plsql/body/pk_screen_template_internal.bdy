/*-- Last Change Revision: $Rev: 2027699 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_screen_template_internal IS
    /******************************************************************************
       NAME:       PK_SCREEN_TEMPLATE
       PURPOSE:    SUPPORT SCREEN TEMPLATE BUILDING AND CONFIGURATION
       NOTES:    USED IN THE CONTEXT OF PATIENT IDENTIFICATION
    
       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        23-jan-2007  LG
    ******************************************************************************/
    -- This package was create because java has problems with INDEX BY VARCHAR2 data types and pk_screen_template uses it
    -- in function GET_SCREEN_TEMPLATE_METADATA.
    -- This function must be in package spec because is called from pk_patient 
    -- The founded solution  was to create an internal package which is not generated by java.

    /**
    GLOBAL VARIABLES
    */
    g_error              VARCHAR2(2000);
    g_not_found          BOOLEAN;
    g_id_institution_all institution.id_institution%TYPE := 0;
    g_id_software_all    software.id_software%TYPE := 0;

    /**
    * Gets xml screen template to patient id screen
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CONTEXT the screen context
    * @param   O_XML_TEMPLATE the xml code representing the template
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   30-08-2006
    */
    FUNCTION get_screen_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_context      IN VARCHAR2,
        o_xml_template OUT sys_screen_template.xml_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_xml_template IS
            SELECT sst.xml_template
              FROM sys_screen_template sst
              JOIN screen_template st
                ON sst.id_sys_screen_template = st.id_sys_screen_template
             WHERE st.id_institution IN (i_prof.institution, g_id_institution_all)
               AND st.id_software IN (i_prof.software, g_id_software_all)
               AND st.context = i_context
             ORDER BY st.id_institution DESC, st.id_software DESC;
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN c_xml_template;
        FETCH c_xml_template
            INTO o_xml_template;
        g_not_found := c_xml_template%NOTFOUND;
        CLOSE c_xml_template;
        IF g_not_found
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SCREEN_TEMPLATE_INTERNAL',
                                              'GET_SCREEN_TEMPLATE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SCREEN_TEMPLATE_INTERNAL',
                                              'GET_SCREEN_TEMPLATE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_screen_template;

    /**
    * Gets xml screen template to patient id screen as a DOMDocument
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CONTEXT the screen context
    * @param   I_PARSER the parser to parse the document
    * @param   O_XML_DOCUMENT the xml DOM DOCUMENT representing the xml screen template
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   30-10-2006
    */
    FUNCTION get_screen_template_dom
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_context      IN VARCHAR2,
        i_parser       IN xmlparser.parser,
        o_xml_document OUT xmldom.domdocument,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_xml_template sys_screen_template.xml_template%TYPE;
    
    BEGIN
        g_error := 'EXECUTING GET_SCREEN_TEMPLATE';
        IF (NOT get_screen_template(i_lang, i_prof, i_context, l_xml_template, o_error))
        THEN
            RETURN FALSE;
        END IF;
        -- parse xml
        g_error := 'PARSE XML';
        xmlparser.parsebuffer(i_parser, l_xml_template);
        -- get dom
        g_error        := 'GET DOM';
        o_xml_document := xmlparser.getdocument(i_parser);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'GET_SCREEN_TEMPLATE_DOM',
                                                     o_error);
    END get_screen_template_dom;

    /**
    * Gets xml screen template metadada to patient id screen
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CONTEXT the screen context
    * @param   O_SCREEN_METADATA the metadata obtained from the xml.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   30-10-2006
    */
    FUNCTION get_screen_template_metadata
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_context         IN VARCHAR2,
        o_screen_metadata OUT screen_metadata_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_parser                   xmlparser.parser;
        l_xml_document             xmldom.domdocument;
        l_line_field_node_list     xmldom.domnodelist;
        l_screen_metadata          screen_metadata_type;
        l_length                   NUMBER;
        l_length2                  NUMBER;
        l_dom_node                 xmldom.domnode;
        l_dom_named_node_map       xmldom.domnamednodemap;
        l_attribute_name           VARCHAR2(100);
        l_attribute_val            VARCHAR2(100);
        l_column_metadata          column_metadata_type;
        l_table_name               VARCHAR2(50);
        l_column_name              VARCHAR2(50);
        l_point_separator_position NUMBER;
        l_key                      VARCHAR2(100);
    BEGIN
        g_error  := 'CREATE PARSER';
        l_parser := xmlparser.newparser;
    
        g_error := 'GET_SCREEN_TEMPLATE_DOM';
        IF (NOT get_screen_template_dom(i_lang, i_prof, i_context, l_parser, l_xml_document, o_error))
        THEN
            RETURN FALSE;
        END IF;
        g_error                := 'BUILD METADATA';
        l_line_field_node_list := xmldom.getelementsbytagname(l_xml_document, 'lineField');
        -- go througth all elements
        l_length := xmldom.getlength(l_line_field_node_list);
        FOR j IN 0 .. l_length - 1
        LOOP
            -- initialize column metadata
            l_column_metadata := NULL;
            l_key             := NULL;
            l_dom_node        := xmldom.item(l_line_field_node_list, j);
            -- get all atributes in lineField element
            l_dom_named_node_map := xmldom.getattributes(l_dom_node);
            -- loop through attributes
            IF (NOT xmldom.isnull(l_dom_named_node_map))
            THEN
                -- default values to some attributes
                l_column_metadata.mandatory := FALSE;
                l_column_metadata.readonly  := FALSE;
                l_column_metadata.visible   := TRUE;
            
                l_length2 := xmldom.getlength(l_dom_named_node_map);
                FOR i IN 0 .. l_length2 - 1
                LOOP
                    l_dom_node       := xmldom.item(l_dom_named_node_map, i);
                    l_attribute_name := upper(xmldom.getnodename(l_dom_node));
                    l_attribute_val  := upper(xmldom.getnodevalue(l_dom_node));
                    -- check if attribute is metadata
                    CASE l_attribute_name
                        WHEN 'DATATYPE' THEN
                            l_column_metadata.column_type := l_attribute_val;
                        WHEN 'PROPERTY' THEN
                            -- set table name and column name metadata properties
                            l_key                         := l_attribute_val;
                            l_point_separator_position    := instr(l_attribute_val, '.');
                            l_table_name                  := substr(l_attribute_val, 1, l_point_separator_position - 1); -- calc table name
                            l_column_metadata.table_name  := l_table_name;
                            l_column_name                 := substr(l_attribute_val, l_point_separator_position + 1); -- calc column name
                            l_column_metadata.column_name := l_column_name;
                        WHEN 'DESCRIPTIONPROPERTY' THEN
                            -- set ref_table and ref_table_desc_colimn metadata properties
                            l_point_separator_position              := instr(l_attribute_val, '.');
                            l_table_name                            := substr(l_attribute_val,
                                                                              1,
                                                                              l_point_separator_position - 1); -- calc table name
                            l_column_metadata.ref_table             := l_table_name;
                            l_column_name                           := substr(l_attribute_val,
                                                                              l_point_separator_position + 1); -- calc column name
                            l_column_metadata.ref_table_desc_column := l_column_name;
                        WHEN 'MANDATORY' THEN
                            l_column_metadata.mandatory := (l_attribute_val = 'YES');
                        WHEN 'READONLY' THEN
                            l_column_metadata.readonly := (l_attribute_val = 'YES');
                        WHEN 'DOMAIN' THEN
                            l_column_metadata.domain := l_attribute_val;
                        WHEN 'FLGTYPE' THEN
                            l_column_metadata.health_plan_flg_type := l_attribute_val;
                        WHEN 'KEY' THEN
                            l_column_metadata.field_name := l_attribute_val;
                        WHEN 'VISIBLE' THEN
                            l_column_metadata.visible := (l_attribute_val = 'YES');
                        ELSE
                            -- attribute to ignore, because it doesn't represent metadata.
                            NULL;
                    END CASE;
                END LOOP;
                -- todo validate l_key is not null
                l_screen_metadata(l_key) := l_column_metadata;
            END IF;
        
        END LOOP;
    
        o_screen_metadata := l_screen_metadata;
    
        -- free document and parser
        g_error := 'FREE DOCUMENT';
        xmldom.freedocument(l_xml_document);
        g_error := 'FREE PARSER';
        xmlparser.freeparser(l_parser);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'GET_SCREEN_TEMPLATE_METADATA',
                                                     o_error);
    END get_screen_template_metadata;

    /**
    * Prints metadata extracted from xml screen template to patient id screen.
    * Metadata is printed with DBMS_OUTPUT.PUT_LINE
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CONTEXT the screen context
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   31-10-2006
    */

    FUNCTION print_screen_template_metadata
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_screen_metadata screen_metadata_type;
        l_index           VARCHAR2(100);
    BEGIN
        IF (NOT get_screen_template_metadata(i_lang, i_prof, i_context, l_screen_metadata, o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'PRINT METADATA';
        l_index := l_screen_metadata.first;
        dbms_output.put_line('comp =' || l_screen_metadata.count);
        WHILE (l_index IS NOT NULL)
        LOOP
            dbms_output.put_line('TABLE_NAME = ' || l_screen_metadata(l_index).table_name);
            dbms_output.put_line('COLUMN_NAME = ' || l_screen_metadata(l_index).column_name);
            dbms_output.put_line('COLUMN_TYPE = ' || l_screen_metadata(l_index).column_type);
            dbms_output.put_line('REF_TABLE = ' || l_screen_metadata(l_index).ref_table);
            dbms_output.put_line('REF_TABLE_DESC_COLUMN = ' || l_screen_metadata(l_index).ref_table_desc_column);
            IF (l_screen_metadata(l_index).mandatory)
            THEN
                dbms_output.put_line('MANDATORY = YES');
            ELSE
                dbms_output.put_line('MANDATORY = NO');
            END IF;
            IF (l_screen_metadata(l_index).readonly)
            THEN
                dbms_output.put_line('READONLY = YES');
            ELSE
                dbms_output.put_line('READONLY = NO');
            END IF;
            IF (l_screen_metadata(l_index).visible)
            THEN
                dbms_output.put_line('VISIBLE = YES');
            ELSE
                dbms_output.put_line('VISIBLE = NO');
            END IF;
            l_index := l_screen_metadata.next(l_index);
            dbms_output.put_line(' ');
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'PRINT_SCREEN_TEMPLATE_METADATA',
                                                     o_error);
    END print_screen_template_metadata;

    /**
    * Creates a convertion expression to convert a value represented in varchar2 to the corresponding table data type.
    * The convertion expression migth be used in SQL and PL/SQL dynamic statements.
    *
    * @param   I_VALUE  The varchar2 value to convert
    * @param   I_TABLE_METADATA Metadata about tables
    * @param   I_METADATA_KEY The key expression used to fectch the column metadata from the I_TABLE_METADATA
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_CONVERTION_EXP The created convertion expression
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION varchar_to_data_type
    (
        i_value           IN VARCHAR2,
        i_screen_metadata IN screen_metadata_type,
        i_metadata_key    IN VARCHAR2,
        i_lang            language.id_language%TYPE,
        o_convertion_exp  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        internal_exception EXCEPTION;
        l_column_metadata column_metadata_type;
    BEGIN
        l_column_metadata := i_screen_metadata(i_metadata_key); -- A NO_DATA_FOUND EXCEPTION IS THROWN IF NO COLLECTION ELEMENT IS FOUND
        IF (i_value IS NULL)
        THEN
            o_convertion_exp := 'NULL';
            RETURN TRUE;
        END IF;
        CASE l_column_metadata.column_type
            WHEN 'CHAR' THEN
                -- LG 2007-May-23, no caso de o valor ter o carcater ' � necess�rio substituir por ''
                o_convertion_exp := '''' || REPLACE(i_value, '''', '''''') || '''';
            WHEN 'DATE' THEN
                -- all dates must have the DDMMYYYY value format
                o_convertion_exp := 'TO_DATE(''' || i_value || ''', ''' || g_date_convert_pattern || ''')';
            WHEN 'NUMBER' THEN
                o_convertion_exp := 'TO_NUMBER(''' || i_value || ''')';
                -- add more whens here to treat other data types
            ELSE
                -- it means that this function must be changed in order to incorporate a new data type
                g_error := 'NO CONVERTION DEFINED TO DATA COLUMN ' || i_metadata_key || ' WITH DATA TYPE ' ||
                           l_column_metadata.column_type;
                RAISE internal_exception;
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- it means the column name is not known in the table
            g_error := 'INVALID COLUMN NAME : ' || i_metadata_key;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'VARCHAR_TO_DATA_TYPE',
                                                     o_error);
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'VARCHAR_TO_DATA_TYPE',
                                                     o_error);
    END varchar_to_data_type;

    /**
    * Validate mandatory fields
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param I_SCREEN_METADATA The screen metadata
    * @param   I_KEYS array with keys about which info is available to the patient
    * @param   I_VALUES array with which info is available to the patient
    * @param   O_FLG_SHOW  =Y to show a message, otherwise = N
    * @param   O_MSG_TITLE  the message title, when O_FLG_SHOW = Y
    * @param   O_MSG_TEXT  the message text , when O_FLG_SHOW = Y
    * @param   O_BUTTON the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   02-11-2006
    */
    FUNCTION validate_screen_fields
    (
        i_lang            language.id_language%TYPE,
        i_prof            IN profissional,
        i_screen_metadata IN screen_metadata_type,
        i_keys            IN table_varchar,
        i_values          IN table_varchar,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg_text        OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_column_metadata column_metadata_type;
        l_msg             VARCHAR2(400);
        l_param_name      VARCHAR2(200);
        l_params          table_varchar;
        l_formated_msg    VARCHAR2(400);
    BEGIN
        g_error := 'KEYS LOOP';
        FOR i IN 1 .. i_keys.count
        LOOP
            g_error := 'VALIDATE ' || i_keys(i);
            -- Loop sobre o array de chaves
            IF i_screen_metadata.exists(i_keys(i))
            THEN
                l_column_metadata := i_screen_metadata(i_keys(i));
                -- readOnly = true overrides mandatory value
                IF (l_column_metadata.readonly = FALSE AND l_column_metadata.mandatory AND i_values(i) IS NULL)
                THEN
                    IF (l_msg IS NULL)
                    THEN
                        g_error := 'GET MANDATORY FIELD MESSAGE';
                        l_msg   := pk_message.get_message(i_lang, i_prof, 'SCREEN_TEMPLATE.T001');
                    END IF;
                    g_error      := 'GET FIELD NAME';
                    l_param_name := pk_message.get_message(i_lang, i_prof, l_column_metadata.field_name);
                    l_params     := table_varchar(l_param_name);
                    g_error      := 'FORMAT FIELD';
                    IF NOT pk_message.format(i_lang, l_msg, l_params, l_formated_msg, o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    o_msg_text := o_msg_text || chr(10) || l_formated_msg;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'AFTER CALCULATE O_MSG_TEXT';
        IF (o_msg_text IS NOT NULL)
        THEN
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'SCREEN_TEMPLATE.T002');
            o_button    := 'R';
            o_flg_show  := 'Y';
        ELSE
            o_flg_show := 'N';
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SCREEN_TEMPLATE_INTERNAL',
                                                     'VALIDATE_SCREEN_FIELDS',
                                                     o_error);
    END validate_screen_fields;

BEGIN
    g_date_convert_pattern := 'YYYYMMDD';

END pk_screen_template_internal;
/
