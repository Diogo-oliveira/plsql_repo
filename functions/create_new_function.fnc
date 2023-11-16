CREATE OR REPLACE FUNCTION create_new_function
(
    package_name  IN VARCHAR2 DEFAULT NULL,
    owner_name    IN VARCHAR2 DEFAULT NULL,
    function_name IN VARCHAR2 DEFAULT NULL,
    function_desc IN VARCHAR2 DEFAULT NULL,
    
    return_type    IN VARCHAR2 DEFAULT NULL,
    return_desc    IN VARCHAR2 DEFAULT NULL,
    exception_desc VARCHAR2 DEFAULT NULL,
    
    parameter1      IN VARCHAR2 DEFAULT NULL,
    parameter1_type IN VARCHAR2 DEFAULT NULL,
    io_type1        IN VARCHAR2 DEFAULT NULL,
    parameter1_desc IN VARCHAR2 DEFAULT NULL,
    value1_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter2      IN VARCHAR2 DEFAULT NULL,
    parameter2_type IN VARCHAR2 DEFAULT NULL,
    io_type2        IN VARCHAR2 DEFAULT NULL,
    parameter2_desc IN VARCHAR2 DEFAULT NULL,
    value2_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter3      IN VARCHAR2 DEFAULT NULL,
    parameter3_type IN VARCHAR2 DEFAULT NULL,
    io_type3        IN VARCHAR2 DEFAULT NULL,
    parameter3_desc IN VARCHAR2 DEFAULT NULL,
    value3_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter4      IN VARCHAR2 DEFAULT NULL,
    parameter4_type IN VARCHAR2 DEFAULT NULL,
    io_type4        IN VARCHAR2 DEFAULT NULL,
    parameter4_desc IN VARCHAR2 DEFAULT NULL,
    value4_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter5      IN VARCHAR2 DEFAULT NULL,
    parameter5_type IN VARCHAR2 DEFAULT NULL,
    io_type5        IN VARCHAR2 DEFAULT NULL,
    parameter5_desc IN VARCHAR2 DEFAULT NULL,
    value5_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter6      IN VARCHAR2 DEFAULT NULL,
    parameter6_type IN VARCHAR2 DEFAULT NULL,
    io_type6        IN VARCHAR2 DEFAULT NULL,
    parameter6_desc IN VARCHAR2 DEFAULT NULL,
    value6_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter7      IN VARCHAR2 DEFAULT NULL,
    parameter7_type IN VARCHAR2 DEFAULT NULL,
    io_type7        IN VARCHAR2 DEFAULT NULL,
    parameter7_desc IN VARCHAR2 DEFAULT NULL,
    value7_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter8      IN VARCHAR2 DEFAULT NULL,
    parameter8_type IN VARCHAR2 DEFAULT NULL,
    io_type8        IN VARCHAR2 DEFAULT NULL,
    parameter8_desc IN VARCHAR2 DEFAULT NULL,
    value8_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter9      IN VARCHAR2 DEFAULT NULL,
    parameter9_type IN VARCHAR2 DEFAULT NULL,
    io_type9        IN VARCHAR2 DEFAULT NULL,
    parameter9_desc IN VARCHAR2 DEFAULT NULL,
    value9_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter10      IN VARCHAR2 DEFAULT NULL,
    parameter10_type IN VARCHAR2 DEFAULT NULL,
    io_type10        IN VARCHAR2 DEFAULT NULL,
    parameter10_desc IN VARCHAR2 DEFAULT NULL,
    value10_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter11      IN VARCHAR2 DEFAULT NULL,
    parameter11_type IN VARCHAR2 DEFAULT NULL,
    io_type11        IN VARCHAR2 DEFAULT NULL,
    parameter11_desc IN VARCHAR2 DEFAULT NULL,
    value11_desc     IN VARCHAR2 DEFAULT NULL,
    
    parameter12      IN VARCHAR2 DEFAULT NULL,
    parameter12_type IN VARCHAR2 DEFAULT NULL,
    io_type12        IN VARCHAR2 DEFAULT NULL,
    parameter12_desc IN VARCHAR2 DEFAULT NULL,
    value12_desc     IN VARCHAR2 DEFAULT NULL,
    
    i_return IN VARCHAR2
) RETURN VARCHAR2 IS
    l_return VARCHAR2(32000);
    l_line   VARCHAR2(4000);
    FUNCTION build_parameter_function
    (
        i_return       IN VARCHAR2 DEFAULT NULL,
        parameter      IN VARCHAR2 DEFAULT NULL,
        io_type        IN VARCHAR2 DEFAULT NULL,
        parameter_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF parameter IS NOT NULL
        THEN
            l_return := REPLACE(l_return, '#$#!!', ',' || chr(10));
            l_return := i_return || upper(parameter) || ' ' || io_type || ' ' || parameter_type || '#$#!!';
        END IF;
        RETURN l_return;
    END;
    FUNCTION build_comment_function
    (
        i_return       IN VARCHAR2 DEFAULT NULL,
        parameter      IN VARCHAR2 DEFAULT NULL,
        parameter_desc IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_line VARCHAR2(4000);
    BEGIN
        IF parameter IS NOT NULL
        THEN
            IF length(parameter) < 25
            THEN
                l_line := l_line || /* chr(10) ||*/
                          '* @param ' || upper(parameter) || lpad(' ', 25 - length(parameter)) || parameter_desc;
                l_line := l_line || lpad(' ', 139 - (length(l_line))) || '*';
            
                l_return := l_return || chr(10) || l_line;
            ELSE
                l_line := l_line || /* chr(10) ||*/
                          '* @param ' || upper(parameter) || parameter_desc;
                l_line := l_line || lpad(' ', 139 - (length(l_line))) || '*';
            
                l_return := l_return || chr(10) || l_line;
            END IF;
        END IF;
        RETURN l_return;
    END;
    FUNCTION build_comment_value
    (
        i_return       IN VARCHAR2 DEFAULT NULL,
        parameter      IN VARCHAR2 DEFAULT NULL,
        parameter_desc IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_line VARCHAR2(4000);
    BEGIN
        IF parameter_desc IS NOT NULL
        THEN
            IF length(parameter_desc) < 250
            THEN
                l_line := l_line || /* chr(10) ||*/
                          '* @value ' || upper(parameter) || lpad(' ', 25 - length(parameter)) || parameter_desc;
                l_line := l_line || lpad(' ', 139 - (length(l_line))) || '*';
            
                l_return := l_return || chr(10) || l_line;
            ELSE
                l_line := l_line || /* chr(10) ||*/
                          '* @value ' || upper(parameter) || parameter_desc;
                l_line := l_line || lpad(' ', 139 - (length(l_line))) || '*';
            
                l_return := l_return || chr(10) || l_line;
            END IF;
        END IF;
        RETURN l_return;
    END;
BEGIN
    l_return := '/*******************************************************************************************************************************************';

    -- l_line   := '* Nome : ' || lpad(' ', 34 - (length('* Nome : '))) || function_name;
    --   l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    --   l_return := l_return || chr(10) || l_line;

    -- l_line   := '* Descrição:  ' || function_desc;
    -- l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    -- l_return := l_return || chr(10) || l_line;
    l_line   := '*' || function_name || ' ' || function_desc;
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '*';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_return := build_comment_function(l_return, parameter1, parameter1_desc);
    l_return := build_comment_function(l_return, parameter2, parameter2_desc);
    l_return := build_comment_function(l_return, parameter3, parameter3_desc);
    l_return := build_comment_function(l_return, parameter4, parameter4_desc);
    l_return := build_comment_function(l_return, parameter5, parameter5_desc);
    l_return := build_comment_function(l_return, parameter6, parameter6_desc);
    l_return := build_comment_function(l_return, parameter7, parameter7_desc);
    l_return := build_comment_function(l_return, parameter8, parameter8_desc);
    l_return := build_comment_function(l_return, parameter9, parameter9_desc);
    l_return := build_comment_function(l_return, parameter10, parameter10_desc);
    l_return := build_comment_function(l_return, parameter11, parameter11_desc);
    l_return := build_comment_function(l_return, parameter12, parameter12_desc);

    l_line   := '*';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_return := build_comment_value(l_return, parameter1, value1_desc);
    l_return := build_comment_value(l_return, parameter2, value2_desc);
    l_return := build_comment_value(l_return, parameter3, value3_desc);
    l_return := build_comment_value(l_return, parameter4, value4_desc);
    l_return := build_comment_value(l_return, parameter5, value5_desc);
    l_return := build_comment_value(l_return, parameter6, value6_desc);
    l_return := build_comment_value(l_return, parameter7, value7_desc);
    l_return := build_comment_value(l_return, parameter8, value8_desc);
    l_return := build_comment_value(l_return, parameter9, value9_desc);
    l_return := build_comment_value(l_return, parameter10, value10_desc);
    l_return := build_comment_value(l_return, parameter11, value11_desc);
    l_return := build_comment_value(l_return, parameter12, value12_desc);

    l_line   := '*';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := NULL;
    l_line   := l_line || '* @return ' || lpad(' ', 34 - length('* @return ')) || return_desc;
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '*';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := NULL;
    l_line   := l_line || '* @raises ' || lpad(' ', 34 - length('* @raises ')) || exception_desc;
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '*';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '* @author  ' || lpad(' ', 34 - (length('* @author  '))) || owner_name;
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '* @version  ' || lpad(' ', 34 - (length('* version  '))) || '1.0';
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_line   := '* @since  ' || lpad(' ', 34 - (length('* @since  '))) || to_char(SYSDATE, 'yyyy/mm/dd');
    l_line   := l_line || lpad(' ', 139 - (length(l_line))) || '*';
    l_return := l_return || chr(10) || l_line;

    l_return := l_return || chr(10) ||
                '*******************************************************************************************************************************************/';

    l_return := l_return || chr(10);
    l_return := l_return || 'FUNCTION ' || function_name || '(';
    l_return := build_parameter_function(l_return, parameter1, io_type1, parameter1_type);
    l_return := build_parameter_function(l_return, parameter2, io_type2, parameter2_type);
    l_return := build_parameter_function(l_return, parameter3, io_type3, parameter3_type);
    l_return := build_parameter_function(l_return, parameter4, io_type4, parameter4_type);
    l_return := build_parameter_function(l_return, parameter5, io_type5, parameter5_type);
    l_return := build_parameter_function(l_return, parameter6, io_type6, parameter6_type);
    l_return := build_parameter_function(l_return, parameter7, io_type7, parameter7_type);
    l_return := build_parameter_function(l_return, parameter8, io_type8, parameter8_type);
    l_return := build_parameter_function(l_return, parameter9, io_type9, parameter9_type);
    l_return := build_parameter_function(l_return, parameter10, io_type10, parameter10_type);
    l_return := build_parameter_function(l_return, parameter11, io_type11, parameter11_type);
    l_return := build_parameter_function(l_return, parameter12, io_type12, parameter12_type);
    l_return := REPLACE(l_return, '#$#!!', ')');
    l_return := l_return || chr(10) || 'RETURN ' || return_type || ' IS ' || chr(10) || 'L_RETURN ' || return_type || ';' ||
                chr(10) || '   g_error VARCHAR2(4000); ' || chr(10) || 'BEGIN' || chr(10) || ' log_this( ''' ||
                package_name || ''',''' || function_name || ''',''Mark 1'');' || chr(10) || '--' || chr(10) || '--' ||
                chr(10) || 'RETURN L_RETURN;' || chr(10) || ' EXCEPTION ' || chr(10) ||
                ' WHEN OTHERS THEN o_error := pk_message.get_message(i_lang, '' common_m001 '') || chr(10) || ''' ||
                package_name || ' . ' || function_name || ' / '' || g_error || '' / '' || SQLERRM;
    -- pk_types.open_my_cursor(O_LOCAL_CURSOR);
    --RETURN FALSE;
END ' || upper(function_name) || ';';
    RETURN(l_return);
END create_new_function;
/
