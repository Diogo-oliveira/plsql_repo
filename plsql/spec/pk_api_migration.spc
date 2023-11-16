/*-- Last Change Revision: $Rev: 2028475 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_migration IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 25-08-2009 15:48:45
    -- Purpose : API for migrations purpose

    /*******************************************************************************************************************************************
    * Name:                           EPIS_INFO_UPDATE
    * Description:                    Function that updates EPIS_INFO with information from diferent areas
    * 
    * @param i_lang                   Language
    * @param i_area                   Area (EPISODE/EXAM/ANALYSIS/TRIAGE/MOVEMENT/PRESCRIPTION/SCHEDULE/DISCHARGE/DRUG/SCHEDULE_ORIS/BED)
    * @param i_episode_list           List of episodes to update
    * @param i_limit                  Limit for BULK COLLECT
    * @param i_commit_data            BOOLEAN that indicates if the function does commit.
    *                                 If FALSE the commit must be processed by the calling function
    * 
    * @param out O_desc_ERROR         Returns a string with the description of the error
    *          
    * @return                         Return FALSE if an error occours, otherwise return TRUE. 
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2009/08/26
    *******************************************************************************************************************************************/
    FUNCTION epis_info_update
    (
        i_lang        IN language.id_language%TYPE,
        i_area        IN VARCHAR2,
        i_episode_lis IN table_number,
        i_limit       IN NUMBER DEFAULT 1000,
        i_commit_data IN BOOLEAN DEFAULT FALSE,
        o_desc_error  OUT VARCHAR2
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_error         VARCHAR2(200);
    g_exception EXCEPTION;
END pk_api_migration;
/
