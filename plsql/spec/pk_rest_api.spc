/*-- Last Change Revision: $Rev: 1974510 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2020-12-17 09:31:59 +0000 (qui, 17 dez 2020) $*/

CREATE OR REPLACE PACKAGE pk_rest_api IS

    -- Author  : MIGUEL.MONTEIRO
    -- Created : 29/07/2020 11:31:20
    -- Purpose : The purpose of this package is to create a API to make REST calls to ALERT applications.

    /*
    * Function to make internal REST request to ALERT applications. This function should only be called for the 
    * the first Request to decide which Host to call due to the 2 phase commit.
    * 
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param i_application_context Sysconfig value for the application context
    * @param i_application_port    Sysconfig value for the application port
    * @param o_transaction         The transaction ID returned by the web server that is needed for further requests.
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     31-07-2020
    */
    FUNCTION gettransactionid
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_application_context IN VARCHAR2,
        i_application_port    IN VARCHAR2,
        o_transaction         OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Function to make internal REST request to ALERT applications after getting the transactionID
    * 
    *
    * @param i_hosts              The available hosts
    * @param i_transaction        The transaction id
    * @param i_service            The application REST service desired to call
    * @param i_http_method        HTTP Method to use (GET, POST, PUT, DELETE)
    * @param i_content_type       Content_Type Header (application/json)
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param l_body               Body to use in REST 
    * @param o_status             EnterpriseServiceResponseDto status returned (Success, Failure)
    * @param o_data               EnterpriseServiceResponseDto data returned
    * @param o_error              EnterpriseServiceResponseDto error retuned
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     31-07-2020
    */
    FUNCTION make_internal_rest_request
    (
        i_host_transaction IN VARCHAR2,
        i_service          IN VARCHAR2,
        i_http_method      IN VARCHAR2,
        i_content_type     IN VARCHAR2 DEFAULT NULL,
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_body             IN CLOB DEFAULT NULL,
        o_status           OUT VARCHAR2,
        o_data             OUT json_element_t,
        o_error            OUT json_array_t
    ) RETURN BOOLEAN;

    /*
    * Function to make internal REST request to ALERT applications without 2 phase commit.
    * 
    *
    * @param i_application_context The application REST Context
    * @param i_application_port    The application REST Port
    * @param i_service            The application REST service desired to call
    * @param i_http_method        HTTP Method to use (GET, POST, PUT, DELETE)
    * @param i_content_type       Content_Type Header (application/json)
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param l_body               Body to use in REST 
    * @param o_status             EnterpriseServiceResponseDto status returned (Success, Failure)
    * @param o_data               EnterpriseServiceResponseDto data returned
    * @param o_error              EnterpriseServiceResponseDto error retuned
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     04-11-2020
    */
    FUNCTION make_internal_rest_request
    (
        i_application_context IN VARCHAR2,
        i_application_port    IN VARCHAR2,
        i_service             IN VARCHAR2,
        i_http_method         IN VARCHAR2,
        i_content_type        IN VARCHAR2 DEFAULT NULL,
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_body                IN CLOB DEFAULT NULL,
        o_status              OUT VARCHAR2,
        o_data                OUT json_element_t,
        o_error               OUT json_array_t
    ) RETURN BOOLEAN;

    /*
    * Function to convert TIMESTAMP WITH LOCAL TIME ZONE to VARCHAR2
    * 
    *
    * @param i_timestamp          The timestamp to be covnerted
    *
    *
    *  @return                    Timestamp as varchar2 
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     02-09-2020
    */
    FUNCTION convert_timestamp(i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR2;

    /*
    * Function to begin the transaction on the web server with the transaction id previously received.
    * 
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param i_transaction        The transaction ID returned by the web server previously
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     04-11-2020
    */
    FUNCTION begintransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Function to commit the transaction on the web server with the transaction id previously received.
    * 
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param i_transaction        The transaction ID returned by the web server previously
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     04-11-2020
    */
    FUNCTION committransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Function to rollback the transaction on the web server with the transaction id previously received.
    * 
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional ID/Institution ID/Software ID
    * @param i_transaction        The transaction ID returned by the web server previously
    *
    *  @return                    true when success message is sent    / false when none of the available hosts responds or has internal server error
    *
    *  @author                    Miguel Monteiro
    *  @version                   2.8.2.0
    *  @since                     04-11-2020
    */
    FUNCTION rollbacktransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(4000);

END pk_rest_api;
/
