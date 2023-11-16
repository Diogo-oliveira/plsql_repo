/*-- Last Change Revision: $Rev: 2028665 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_temp_args IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 11/19/2013 10:28:07 PM
    -- Purpose : Handle temporary arguments to be used in views

    -- Public constant declarations

    -- Public function and procedure declarations
    PROCEDURE clean_table(i_namespace IN VARCHAR2);

    PROCEDURE reset_namespace(i_namespace IN VARCHAR2);

    FUNCTION is_namespace_already_init(i_namespace IN VARCHAR2) RETURN BOOLEAN;

    PROCEDURE reset_attribute
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    );

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN VARCHAR2,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN table_varchar,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE add_argument
    (
        i_namespace       IN VARCHAR2,
        i_attribute       IN VARCHAR2,
        i_value           IN table_number,
        i_reset_attribute IN BOOLEAN DEFAULT TRUE
    );

    FUNCTION get_argument
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    ) RETURN v_edis_temp_args.attr_value%TYPE;

    FUNCTION get_arguments
    (
        i_namespace IN VARCHAR2,
        i_attribute IN VARCHAR2
    ) RETURN table_varchar;

END pk_edis_temp_args;
/
