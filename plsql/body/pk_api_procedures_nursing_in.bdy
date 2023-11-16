/*-- Last Change Revision: $Rev: 1204489 $*/
/*-- Last Change by: $Author: nuno.neves $*/
/*-- Date of last change: $Date: 2012-01-12 14:14:20 +0000 (qui, 12 jan 2012) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_procedures_nursing_in IS

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_procedures_nursing_in;
/
